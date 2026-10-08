import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../driver_active_booking/widgets/parking_ui.dart';
import '../models/parking_map_facility.dart';
import '../services/parking_route_service.dart';

class DriverNavigationScreen extends StatefulWidget {
  final ParkingMapFacility facility;

  // Supply a bay label only when there is an actual selected booking bay.
  final String? bayLabel;

  // Your friend's booking flow can supply the real arrival action.
  final Future<void> Function()? onArrived;

  const DriverNavigationScreen({
    super.key,
    required this.facility,
    this.bayLabel,
    this.onArrived,
  });

  @override
  State<DriverNavigationScreen> createState() =>
      _DriverNavigationScreenState();
}

class _DriverNavigationScreenState
    extends State<DriverNavigationScreen> {
  final _mapController = MapController();
  final _routeService = ParkingRouteService();

  LatLng _origin = const LatLng(6.9271, 79.8612);

  ParkingRoadRoute? _route;
  String? _error;

  bool _loading = true;
  bool _locating = false;
  bool _arriving = false;
  bool _usingDeviceLocation = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _routeService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _fitRoute() {
    if (!_mapReady || _route == null) {
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([
          ..._route!.points,
          _origin,
          widget.facility.position,
        ]),
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  void _scheduleFit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fitRoute();
      }
    });
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _error = null;
      _route = null;
    });

    try {
      final route = await _routeService.loadRoute(
        origin: _origin,
        destination: widget.facility.position,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _route = route;
      });

      _scheduleFit();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is StateError
              ? error.message.toString()
              : 'Could not calculate the route. Check your connection and retry.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on location services first.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw StateError(
          'Location permission was denied. The demo starting point is still available.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw StateError(
          'Enable location permission in your browser or device settings.',
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

      setState(() {
        _origin = LatLng(position.latitude, position.longitude);
        _usingDeviceLocation = true;
      });

      await _loadRoute();
    } catch (error) {
      if (mounted) {
        _message(
          error is StateError
              ? error.message.toString()
              : 'Could not capture your location. Please try again.',
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

  Future<void> _openNavigation() async {
    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'destination':
            '${widget.facility.position.latitude},'
            '${widget.facility.position.longitude}',
        'travelmode': 'driving',

        // Without device location, Google Maps can choose the user's
        // actual starting point instead of our Colombo demo origin.
        if (_usingDeviceLocation)
          'origin': '${_origin.latitude},${_origin.longitude}',
      },
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _message('Could not open navigation.');
      }
    } catch (_) {
      if (mounted) {
        _message('Could not open navigation.');
      }
    }
  }

  Future<void> _confirmArrival() async {
    if (widget.onArrived == null) {
      _message(
        'Arrival preview: connect this button to the booked parking session. '
        'No booking has been changed.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Arrived and parked?'),
          content: Text(
            'Confirm that you have parked at ${widget.facility.name}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _arriving = true;
    });

    try {
      await widget.onArrived!();

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        _message('Could not confirm arrival. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _arriving = false;
        });
      }
    }
  }

  String _stepDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Widget _routeBanner() {
    final steps = _route?.steps ?? [];
    final firstStep = steps.isEmpty ? null : steps.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ParkingStyle.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.route_rounded,
            color: ParkingStyle.orange,
            size: 31,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loading
                      ? 'Calculating your route'
                      : firstStep?.instruction ?? 'Route overview',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  firstStep == null || firstStep.road.isEmpty
                      ? 'To ${widget.facility.name}'
                      : 'Via ${firstStep.road}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(205),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointMarker({
    required LatLng point,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 23,
      ),
    );
  }

  Widget _routeMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 285,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.facility.position,
            initialZoom: 13,
            minZoom: 3,
            maxZoom: 19,
            onMapReady: () {
              _mapReady = true;
              _scheduleFit();
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'parkpin.hci.group.we46',
              maxNativeZoom: 19,
            ),
            if (_route != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _route!.points,
                    strokeWidth: 6,
                    color: ParkingStyle.navy,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _origin,
                  width: 42,
                  height: 42,
                  child: _pointMarker(
                    point: _origin,
                    color: const Color(0xFF22A66A),
                    icon: Icons.my_location_rounded,
                  ),
                ),
                Marker(
                  point: widget.facility.position,
                  width: 44,
                  height: 44,
                  child: _pointMarker(
                    point: widget.facility.position,
                    color: ParkingStyle.orange,
                    icon: Icons.local_parking_rounded,
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
      ),
    );
  }

  Widget _routeSummary() {
    return ParkingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _route == null
                ? 'Route details'
                : '${_route!.durationLabel} · ${_route!.distanceLabel}',
            style: const TextStyle(
              color: ParkingStyle.navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.facility.name,
            style: const TextStyle(
              color: ParkingStyle.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.bayLabel == null
                ? 'Destination: demo parking location'
                : 'Reserved bay: ${widget.bayLabel}',
            style: const TextStyle(
              color: ParkingStyle.muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.trip_origin_rounded,
                color: Color(0xFF22A66A),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _usingDeviceLocation
                      ? 'Start: captured device location'
                      : 'Start: Colombo centre (demo)',
                  style: const TextStyle(
                    color: ParkingStyle.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Estimated driving time; no live traffic. '
            'The in-app map does not track your progress along the route.',
            style: TextStyle(
              color: ParkingStyle.muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepsCard() {
    final steps = _route?.steps ?? [];

    return ParkingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route steps',
            style: TextStyle(
              color: ParkingStyle.navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < steps.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: const Color(0xFFEEF3FA),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: ParkingStyle.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[index].instruction,
                          style: const TextStyle(
                            color: ParkingStyle.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (steps[index].road.isNotEmpty)
                          Text(
                            steps[index].road,
                            style: const TextStyle(
                              color: ParkingStyle.muted,
                              fontSize: 12,
                            ),
                          ),
                        if (steps[index].distanceMeters > 0)
                          Text(
                            'Continue for '
                            '${_stepDistance(steps[index].distanceMeters)}',
                            style: const TextStyle(
                              color: ParkingStyle.muted,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _locating || _arriving;

    return PopScope(
      canPop: !_arriving,
      child: Scaffold(
        backgroundColor: ParkingStyle.background,
        appBar: AppBar(
          backgroundColor: ParkingStyle.navy,
          foregroundColor: Colors.white,
          title: const Text(
            'Navigation',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: 'Use my location',
              onPressed: busy ? null : _useMyLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
            IconButton(
              tooltip: 'Recalculate route',
              onPressed: busy ? null : _loadRoute,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _routeBanner(),
                const SizedBox(height: 14),
                _routeMap(),
                const SizedBox(height: 14),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (_error != null) ...[
                  ParkingCard(
                    color: const Color(0xFFFFEEEE),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFB3261E),
                          ),
                        ),
                        TextButton(
                          onPressed: busy ? null : _loadRoute,
                          child: const Text('Retry route'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _routeSummary(),
                const SizedBox(height: 14),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _arriving ? null : _openNavigation,
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Open navigation in Google Maps'),
                  ),
                ),
                const SizedBox(height: 14),
                if (_route != null) _stepsCard(),
                const SizedBox(height: 16),
                const Text(
                  'Road routing: OSRM · Demo parking destination',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ParkingStyle.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _arriving ? null : _confirmArrival,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ParkingStyle.orange,
                    foregroundColor: ParkingStyle.navy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _arriving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Arrived & parked',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}