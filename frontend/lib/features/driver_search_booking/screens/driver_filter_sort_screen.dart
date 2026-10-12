
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParkingFilters {
  const ParkingFilters({
    this.maxPrice = 300,
    this.maxDistanceKm = 3,
    this.amenities = const {},
    this.sortBy = 'Nearest',
    this.vehicleType = 'Car',
    this.durationHours = 2,
    this.availableOnly = true,
  });

  // Kept for compatibility with existing map-screen code.
  // Price is no longer selected by the driver.
  final double maxPrice;

  final double maxDistanceKm;
  final Set<String> amenities;
  final String sortBy;
  final String vehicleType;
  final int durationHours;
  final bool availableOnly;
}

class DriverFilterSortScreen extends StatefulWidget {
  const DriverFilterSortScreen({
    super.key,
    this.initialFilters = const ParkingFilters(),
  });

  final ParkingFilters initialFilters;

  @override
  State<DriverFilterSortScreen> createState() =>
      _DriverFilterSortScreenState();
}

class _DriverFilterSortScreenState
    extends State<DriverFilterSortScreen> {
  static const Color navy = Color(0xFF1E3D70);
  static const Color orange = Color(0xFFFFA51F);
  static const Color background = Color(0xFFF4F6FB);

  final SupabaseClient _supabase = Supabase.instance.client;

  late String _vehicle;
  late int _duration;
  late double _distance;
  late Set<String> _amenities;
  late String _sort;
  late bool _availableOnly;

  bool _loading = false;
  bool _savedPreferencesExist = false;

  @override
  void initState() {
    super.initState();

    _vehicle = widget.initialFilters.vehicleType;
    _duration = widget.initialFilters.durationHours;
    _distance = widget.initialFilters.maxDistanceKm;
    _amenities = {...widget.initialFilters.amenities};
    _sort = widget.initialFilters.sortBy;
    _availableOnly = widget.initialFilters.availableOnly;

    _loadPreferences();
  }

  String? get _userId => _supabase.auth.currentUser?.id;

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  ParkingFilters get _currentFilters => ParkingFilters(
        maxPrice: widget.initialFilters.maxPrice,
        maxDistanceKm: _distance,
        amenities: {..._amenities},
        sortBy: _sort,
        vehicleType: _vehicle,
        durationHours: _duration,
        availableOnly: _availableOnly,
      );

  Map<String, dynamic> _databaseValues(String userId) {
    return {
      'user_id': userId,
      'vehicle_type': _vehicle,
      'duration_hours': _duration,
      'max_distance_km': _distance.toInt(),
      'amenities': _amenities.toList(),
      'available_only': _availableOnly,
      'sort_by': _sort,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // READ: Retrieve saved preferences from Supabase.
  Future<void> _loadPreferences() async {
    final userId = _userId;

    if (userId == null) return;

    setState(() => _loading = true);

    try {
      final row = await _supabase
          .from('driver_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (row != null) {
        final storedAmenities =
            (row['amenities'] as List<dynamic>?) ?? [];

        setState(() {
          _vehicle = row['vehicle_type'] as String? ?? 'Car';
          _duration =
              (row['duration_hours'] as num?)?.toInt() ?? 2;
          _distance =
              (row['max_distance_km'] as num?)?.toDouble() ?? 3;
          _amenities = storedAmenities
              .map((item) => item.toString())
              .toSet();
          _availableOnly =
              row['available_only'] as bool? ?? true;
          _sort = row['sort_by'] as String? ?? 'Nearest';
          _savedPreferencesExist = true;
        });
      } else {
        setState(() => _savedPreferencesExist = false);
      }
    } catch (error) {
      _message('Could not load preferences: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // CREATE / UPDATE: Insert new preferences or update the
  // existing row using the user_id primary key.
  Future<void> _savePreferences() async {
    final userId = _userId;

    if (userId == null) {
      _message('Please log in before saving preferences.');
      return;
    }

    setState(() => _loading = true);

    try {
      await _supabase.from('driver_preferences').upsert(
            _databaseValues(userId),
            onConflict: 'user_id',
          );

      if (!mounted) return;

      setState(() => _savedPreferencesExist = true);

      _message('Parking preferences saved successfully.');
    } catch (error) {
      _message('Failed to save preferences: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // DELETE: Remove the logged-in driver's saved preferences.
  Future<void> _deletePreferences() async {
    final userId = _userId;

    if (userId == null) {
      _message('Please log in first.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete saved preferences?'),
        content: const Text(
          'Your saved filter settings will be removed '
          'from the database.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);

    try {
      await _supabase
          .from('driver_preferences')
          .delete()
          .eq('user_id', userId);

      if (!mounted) return;

      setState(() {
        _savedPreferencesExist = false;
        _resetValues();
      });

      _message('Saved preferences deleted.');
    } catch (error) {
      _message('Failed to delete preferences: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetValues() {
    _vehicle = 'Car';
    _duration = 2;
    _distance = 3;
    _amenities = {};
    _availableOnly = true;
    _sort = 'Nearest';
  }

  void _resetFilters() {
    setState(_resetValues);
  }

  void _applyFilters() {
    Navigator.pop(context, _currentFilters);
  }

  Widget _heading(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: navy,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _chip(
    String title,
    bool selected,
    VoidCallback onTap,
  ) {
    return ChoiceChip(
      label: Text(title),
      selected: selected,
      showCheckmark: false,
      selectedColor: navy,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? navy : const Color(0xFFD5DEED),
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : navy,
        fontSize: 12,
      ),
      onSelected: _loading ? null : (_) => onTap(),
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE0E6F0),
        ),
      ),
      child: child,
    );
  }

  Widget _saveButton() {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _savePreferences,
      icon: const Icon(Icons.save_outlined, size: 18),
      label: Text(
        _savedPreferencesExist
            ? 'Update saved preferences'
            : 'Save preferences',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        side: const BorderSide(color: navy),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Filter & sort',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 19,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _resetFilters,
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_loading)
              const LinearProgressIndicator(
                color: orange,
                minHeight: 3,
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  20,
                ),
                children: [
                  _heading('Vehicle type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: ['Car', 'Bike', 'Van']
                        .map(
                          (type) => _chip(
                            type,
                            _vehicle == type,
                            () => setState(
                              () => _vehicle = type,
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  _heading('Parking duration'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [1, 2, 4, 8]
                        .map(
                          (hours) => _chip(
                            '$hours ${hours == 1 ? 'hr' : 'hrs'}',
                            _duration == hours,
                            () => setState(
                              () => _duration = hours,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  _sectionCard(
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.calculate_outlined,
                          color: navy,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Parking price is calculated '
                            'automatically using the facility '
                            'hourly rate and your selected '
                            '$_duration-hour duration.',
                            style: const TextStyle(
                              color: Color(0xFF536783),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _heading('Maximum distance'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [1.0, 3.0, 5.0, 0.0]
                        .map(
                          (distance) => _chip(
                            distance == 0
                                ? 'Any distance'
                                : '< ${distance.toInt()} km',
                            _distance == distance,
                            () => setState(
                              () => _distance = distance,
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  _heading('Parking amenities'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      'Covered',
                      'EV',
                      'CCTV',
                      'Accessible',
                    ].map((amenity) {
                      final selected =
                          _amenities.contains(amenity);

                      return _chip(
                        amenity,
                        selected,
                        () => setState(() {
                          if (selected) {
                            _amenities.remove(amenity);
                          } else {
                            _amenities.add(amenity);
                          }
                        }),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),
                  _sectionCard(
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Available spaces only',
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Hide parking facilities '
                        'with no free spaces',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _availableOnly,
                      activeTrackColor: navy,
                      onChanged: _loading
                          ? null
                          : (value) => setState(
                                () => _availableOnly = value,
                              ),
                    ),
                  ),

                  _heading('Sort results by'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      'Nearest',
                      'Cheapest',
                      'Most spaces',
                    ]
                        .map(
                          (option) => _chip(
                            option,
                            _sort == option,
                            () => setState(
                              () => _sort = option,
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 24),
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.storage_outlined,
                              color: navy,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Saved preferences',
                              style: TextStyle(
                                color: navy,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _savedPreferencesExist
                              ? 'Your preferences are saved '
                                  'in Supabase.'
                              : 'No saved preferences yet.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _saveButton(),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed:
                                  _loading ? null : _loadPreferences,
                              icon: const Icon(
                                Icons.download_outlined,
                                size: 17,
                              ),
                              label: const Text('Load'),
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  _loading ||
                                          !_savedPreferencesExist
                                      ? null
                                      : _deletePreferences,
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 17,
                              ),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply filters',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
