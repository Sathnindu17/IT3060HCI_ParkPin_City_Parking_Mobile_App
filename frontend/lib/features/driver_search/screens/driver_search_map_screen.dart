import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:geolocator/geolocator.dart';

import 'package:latlong2/latlong.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../driver_active_booking/widgets/parking_ui.dart';

import '../models/parking_map_facility.dart';

import '../services/parking_map_service.dart';

import '../../driver_search_booking/screens/driver_filter_sort_screen.dart';

import '../../driver_search_booking/screens/driver_space_details_screen.dart';

class DriverSearchMapScreen extends StatefulWidget {
  final ValueChanged<ParkingMapFacility>? onReserve;

  final ValueChanged<int>? onNavigate;

  const DriverSearchMapScreen({super.key, this.onReserve, this.onNavigate});

  @override
  State<DriverSearchMapScreen> createState() => _DriverSearchMapScreenState();
}

class _DriverSearchMapScreenState extends State<DriverSearchMapScreen> {
  static const _colombo = LatLng(6.9271, 79.8612);

  final _service = ParkingMapService();

  final _mapController = MapController();

  final _searchController = TextEditingController();

  final _distance = const Distance();

  StreamSubscription<List<Map<String, dynamic>>>? _baySubscription;

  List<ParkingMapFacility> _facilities = [];

  Map<String, int> _availableCounts = {};

  LatLng? _userPosition;

  String? _selectedId;

  String? _error;

  bool _loading = true;

  bool _locating = false;

  bool _availabilityReady = false;

  bool _availableOnly = false;

  bool _mapReady = false;

  int _loadGeneration = 0;

  ParkingFilters _currentFilters = const ParkingFilters();

  bool _filtersApplied = false;

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  void dispose() {
    _loadGeneration++;

    _baySubscription?.cancel();

    _searchController.dispose();

    _mapController.dispose();

    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  String _errorMessage(Object error) {
    if (error is PostgrestException) {
      return error.message;
    }

    if (error is StateError) {
      return error.message.toString();
    }

    return 'Could not load parking data. Check your connection and retry.';
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;

    setState(() {
      _loading = true;

      _availabilityReady = false;

      _error = null;
    });

    try {
      await _baySubscription?.cancel();

      if (!mounted || generation != _loadGeneration) {
        return;
      }

      _baySubscription = null;

      final facilities = await _service.loadDemoFacilities();

      if (!mounted || generation != _loadGeneration) {
        return;
      }

      if (facilities.isEmpty) {
        setState(() {
          _facilities = [];

          _availableCounts = {};

          _loading = false;

          _error = 'No demo locations found. Run the 0007 SQL seed first.';
        });

        return;
      }

      setState(() {
        _facilities = facilities;

        _availableCounts = {};
      });

      _baySubscription = _service
          .watchBays(facilities.map((facility) => facility.id).toList())
          .listen(
            (rows) {
              if (!mounted || generation != _loadGeneration) {
                return;
              }

              final counts = <String, int>{
                for (final facility in facilities) facility.id: 0,
              };

              for (final row in rows) {
                if (row['status'] == 'available') {
                  final facilityId = row['facility_id'] as String;

                  counts[facilityId] = (counts[facilityId] ?? 0) + 1;
                }
              }

              setState(() {
                _availableCounts = counts;

                _loading = false;

                _availabilityReady = true;

                _error = null;
              });
            },

            onError: (Object error) {
              if (!mounted || generation != _loadGeneration) {
                return;
              }

              setState(() {
                _loading = false;

                _availabilityReady = false;

                _error = _errorMessage(error);
              });
            },
          );
    } catch (error) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }

      setState(() {
        _loading = false;

        _availabilityReady = false;

        _error = _errorMessage(error);
      });
    }
  }

  int _freeCount(ParkingMapFacility facility) {
    return _availableCounts[facility.id] ?? 0;
  }

  double _distanceKm(ParkingMapFacility facility) {
    return _distance(_userPosition ?? _colombo, facility.position) / 1000;
  }

  List<ParkingMapFacility> get _visibleFacilities {
    final query = _searchController.text.trim().toLowerCase();

    final results = _facilities.where((facility) {
      final matchesSearch = '${facility.name} ${facility.address}'
          .toLowerCase()
          .contains(query);

      final matchesAvailability =
          !_availableOnly || (_availabilityReady && _freeCount(facility) > 0);

      final matchesDistance =
          !_filtersApplied ||
          (_currentFilters.maxDistanceKm == 0 ||
              _distanceKm(facility) <= _currentFilters.maxDistanceKm);

      return matchesSearch &&
          matchesAvailability &&
          matchesDistance &&
          (!_filtersApplied ||
              !_currentFilters.availableOnly ||
              (_availabilityReady && _freeCount(facility) > 0));
    }).toList();

    results.sort((first, second) {
      if (_filtersApplied) {
        switch (_currentFilters.sortBy) {
          case 'Cheapest':
            return first.ratePerHour.compareTo(second.ratePerHour);

          case 'Most spaces':
            return _freeCount(second).compareTo(_freeCount(first));
        }
      }

      return _distanceKm(first).compareTo(_distanceKm(second));
    });

    return results;
  }

  ParkingMapFacility? get _selectedFacility {
    final visible = _visibleFacilities;

    if (visible.isEmpty) {
      return null;
    }

    for (final facility in visible) {
      if (facility.id == _selectedId) {
        return facility;
      }
    }

    return visible.first;
  }

  void _select(ParkingMapFacility facility) {
    setState(() {
      _selectedId = facility.id;
    });

    if (_mapReady) {
      _mapController.move(facility.position, 15);
    }
  }

  Future<void> _findMyLocation() async {
    setState(() {
      _locating = true;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on location services and try again.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw StateError(
          'Location permission was denied. You can still browse the map.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw StateError(
          'Location permission is blocked. Enable it in browser or device settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,

          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) {
        return;
      }

      final point = LatLng(position.latitude, position.longitude);

      setState(() {
        _userPosition = point;
      });

      if (_mapReady) {
        _mapController.move(point, 14);
      }
    } catch (error) {
      if (mounted) {
        _message(
          error is StateError
              ? error.message.toString()
              : 'Could not get your location. You can still browse Colombo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  Future<void> _openDirections(ParkingMapFacility facility) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',

      'destination':
          '${facility.position.latitude},${facility.position.longitude}',

      'travelmode': 'driving',

      if (_userPosition != null)
        'origin': '${_userPosition!.latitude},${_userPosition!.longitude}',
    });

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        _message('Could not open directions.');
      }
    } catch (_) {
      if (mounted) {
        _message('Could not open directions.');
      }
    }
  }

  Future<void> _openFilterScreen() async {
    final result = await Navigator.of(context).push<ParkingFilters>(
      MaterialPageRoute(
        builder: (_) => DriverFilterSortScreen(initialFilters: _currentFilters),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _currentFilters = result;

      _filtersApplied = true;
    });

    if (result.amenities.isNotEmpty) {
      _message(
        'Distance and sorting applied. Amenity filtering awaits facility data.',
      );
    }
  }

  Future<void> _openSpaceDetails(ParkingMapFacility facility) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DriverSpaceDetailsScreen(
          facility: facility,

          filters: _currentFilters,
        ),
      ),
    );
  }

  void _navigate(int index) {
    if (index == 0) {
      return;
    }

    final callback = widget.onNavigate;

    if (callback != null) {
      callback(index);

      return;
    }

    _message('Connect this navigation item to your group’s app routes.');
  }

  Color _availabilityColor(ParkingMapFacility facility) {
    if (!_availabilityReady) {
      return ParkingStyle.muted;
    }

    final count = _freeCount(facility);

    if (count == 0) {
      return const Color(0xFFD94A4A);
    }

    if (count <= 5) {
      return const Color(0xFFE49A15);
    }

    return const Color(0xFF22A66A);
  }

  Widget _availabilityBadge(ParkingMapFacility facility) {
    final color = _availabilityColor(facility);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: color.withAlpha(24),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        !_availabilityReady
            ? 'Unknown'
            : _freeCount(facility) == 0
            ? 'Full'
            : '${_freeCount(facility)} free',

        style: TextStyle(
          color: color,

          fontSize: 11,

          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _map(List<ParkingMapFacility> facilities) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,

          options: MapOptions(
            initialCenter: _colombo,

            initialZoom: 12,

            minZoom: 5,

            maxZoom: 19,

            onMapReady: () {
              _mapReady = true;
            },
          ),

          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

              userAgentPackageName: 'parkpin.hci.group.we46',

              maxNativeZoom: 19,
            ),

            MarkerLayer(
              markers: [
                for (final facility in facilities)
                  Marker(
                    point: facility.position,

                    width: 58,

                    height: 42,

                    child: GestureDetector(
                      onTap: () => _select(facility),

                      child: Tooltip(
                        message: facility.name,

                        child: Container(
                          alignment: Alignment.center,

                          decoration: BoxDecoration(
                            color: _availabilityColor(facility),

                            borderRadius: BorderRadius.circular(15),

                            border: Border.all(
                              color: _selectedFacility?.id == facility.id
                                  ? ParkingStyle.navy
                                  : Colors.white,

                              width: 3,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(35),

                                blurRadius: 8,

                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),

                          child: Text(
                            !_availabilityReady
                                ? '…'
                                : _freeCount(facility) == 0
                                ? 'Full'
                                : '${_freeCount(facility)}',

                            style: const TextStyle(
                              color: Colors.white,

                              fontWeight: FontWeight.w800,

                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_userPosition != null)
                  Marker(
                    point: _userPosition!,

                    width: 28,

                    height: 28,

                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2979FF),

                        shape: BoxShape.circle,

                        border: Border.all(color: Colors.white, width: 4),
                      ),
                    ),
                  ),
              ],
            ),

            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',

                  onTap: () {
                    launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        Positioned(
          top: 12,

          left: 12,

          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(12),
            ),

            child: const Text(
              'Demo parking locations',

              style: TextStyle(
                color: ParkingStyle.navy,

                fontSize: 11,

                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        Positioned(
          top: 12,

          right: 12,

          child: Material(
            color: Colors.white,

            borderRadius: BorderRadius.circular(14),

            elevation: 2,

            child: IconButton(
              tooltip: 'Use my location',

              onPressed: _locating ? null : _findMyLocation,

              icon: _locating
                  ? const SizedBox(
                      width: 20,

                      height: 20,

                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.my_location_rounded,

                      color: ParkingStyle.navy,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _facilityCard(ParkingMapFacility facility) {
    final selected = _selectedFacility?.id == facility.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Material(
        color: selected ? const Color(0xFFEEF3FA) : Colors.white,

        borderRadius: BorderRadius.circular(18),

        child: InkWell(
          onTap: () => _select(facility),

          borderRadius: BorderRadius.circular(18),

          child: Container(
            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),

              border: Border.all(
                color: selected ? ParkingStyle.navy : const Color(0xFFE1E8F3),
              ),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_parking_rounded,

                      color: ParkingStyle.navy,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        facility.name,

                        style: const TextStyle(
                          color: ParkingStyle.navy,

                          fontSize: 14,

                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    _availabilityBadge(facility),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  facility.address,

                  style: const TextStyle(
                    color: ParkingStyle.muted,

                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_distanceKm(facility).toStringAsFixed(1)} km'
                        ' · Rs ${facility.ratePerHour.toStringAsFixed(0)}/hr',

                        style: const TextStyle(
                          color: ParkingStyle.text,

                          fontSize: 12,

                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    TextButton.icon(
                      onPressed: () => _openDirections(facility),

                      icon: const Icon(Icons.directions_outlined, size: 17),

                      label: const Text(
                        'Directions',

                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facilities = _visibleFacilities;

    final selected = _selectedFacility;

    final canReserve =
        selected != null && _availabilityReady && _freeCount(selected) > 0;

    return Scaffold(
      backgroundColor: ParkingStyle.background,

      appBar: AppBar(
        backgroundColor: ParkingStyle.navy,

        foregroundColor: Colors.white,

        title: const Row(
          children: [
            Icon(Icons.map_outlined, size: 22),

            SizedBox(width: 9),

            Text('Find parking', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),

        actions: [
          IconButton(
            onPressed: _openFilterScreen,

            tooltip: 'Filter and sort',

            icon: const Icon(Icons.tune_rounded),
          ),

          IconButton(
            onPressed: _loading ? null : _load,

            tooltip: 'Reload parking data',

            icon: const Icon(Icons.refresh_rounded),
          ),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),

          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),

            child: TextField(
              controller: _searchController,

              onChanged: (_) => setState(() {}),

              decoration: InputDecoration(
                hintText: 'Search parking or area',

                prefixIcon: const Icon(Icons.search_rounded),

                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {});
                        },

                        icon: const Icon(Icons.close_rounded),
                      ),

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),

                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final mapHeight = (constraints.maxHeight * 0.42)
              .clamp(120.0, 320.0)
              .toDouble();

          return Column(
            children: [
              SizedBox(height: mapHeight, child: _map(facilities)),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Nearby parking (${facilities.length})',

                            style: const TextStyle(
                              color: ParkingStyle.navy,

                              fontSize: 17,

                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        FilterChip(
                          label: const Text(
                            'Available',

                            style: TextStyle(fontSize: 11),
                          ),

                          selected: _availableOnly,

                          onSelected: (value) {
                            setState(() {
                              _availableOnly = value;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _userPosition == null
                          ? 'Straight-line distances from Colombo centre.'
                          : 'Straight-line distances from your captured location.',

                      style: const TextStyle(
                        color: ParkingStyle.muted,

                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_error != null)
                      ParkingCard(
                        color: const Color(0xFFFFEEEE),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              _error!,

                              style: const TextStyle(color: Color(0xFFB3261E)),
                            ),

                            TextButton(
                              onPressed: _loading ? null : _load,

                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),

                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(24),

                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (facilities.isEmpty && _error == null)
                      const ParkingCard(
                        child: Text(
                          'No matching parking locations. Try another area.',

                          style: TextStyle(color: ParkingStyle.muted),
                        ),
                      )
                    else
                      ...facilities.map(_facilityCard),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Container(
            color: Colors.white,

            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),

            child: SizedBox(
              width: double.infinity,

              height: 50,

              child: ElevatedButton(
                onPressed: canReserve
                    ? () => _openSpaceDetails(selected)
                    : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor: ParkingStyle.orange,

                  foregroundColor: ParkingStyle.navy,

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                child: Text(
                  !_availabilityReady
                      ? 'Waiting for availability'
                      : selected == null
                      ? 'Select a parking location'
                      : _freeCount(selected) == 0
                      ? 'Selected parking is full'
                      : 'Reserve a bay',

                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),

          BottomNavigationBar(
            currentIndex: 0,

            onTap: _navigate,

            type: BottomNavigationBarType.fixed,

            selectedItemColor: ParkingStyle.navy,

            unselectedItemColor: ParkingStyle.muted,

            selectedFontSize: 11,

            unselectedFontSize: 11,

            backgroundColor: Colors.white,

            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),

                label: 'Home',
              ),

              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),

                label: 'Bookings',
              ),

              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),

                label: 'Receipts',
              ),

              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),

                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
