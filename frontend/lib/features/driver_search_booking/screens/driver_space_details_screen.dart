import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../driver_search/models/parking_map_facility.dart';
import 'driver_filter_sort_screen.dart';
import 'driver_reserve_screen.dart';

/// Pre-payment facility details. No booking or payment is created here.
class DriverSpaceDetailsScreen extends StatefulWidget {
  const DriverSpaceDetailsScreen({
    super.key,
    required this.facility,
    required this.filters,
  });

  final ParkingMapFacility facility;
  final ParkingFilters filters;

  @override
  State<DriverSpaceDetailsScreen> createState() =>
      _DriverSpaceDetailsScreenState();
}

class _DriverSpaceDetailsScreenState extends State<DriverSpaceDetailsScreen> {
  static const Color _navy = Color(0xFF1E3D70);
  static const Color _orange = Color(0xFFFFA51F);
  static const Color _background = Color(0xFFF4F6FB);
  static const Color _muted = Color(0xFF64748B);

  late int _hours;
  late String _vehicle;
  int? _availableBays;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hours = [1, 2, 4, 8].contains(widget.filters.durationHours)
        ? widget.filters.durationHours
        : 2;
    _vehicle = ['Car', 'Bike', 'Van'].contains(widget.filters.vehicleType)
        ? widget.filters.vehicleType
        : 'Car';
    _refreshAvailability();
  }

  Future<void> _refreshAvailability() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _availableBays = null;
    });
    try {
      final rows = await Supabase.instance.client
          .from('bays')
          .select('id')
          .eq('facility_id', widget.facility.id)
          .eq('status', 'available');
      if (!mounted) return;
      setState(() => _availableBays = rows.length);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Live bay availability could not be loaded. Try refreshing.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _panel(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0E6F0)),
        ),
        child: child,
      );

  Widget _heading(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                color: _navy, fontSize: 15, fontWeight: FontWeight.w800)),
      );

  Widget _choice(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: _navy,
        backgroundColor: Colors.white,
        side: BorderSide(
            color: selected ? _navy : const Color(0xFFD5DEED)),
        labelStyle: TextStyle(color: selected ? Colors.white : _navy),
        onSelected: (_) => onTap(),
      );

  Widget _priceRow(String title, double amount, {bool prominent = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontWeight: prominent ? FontWeight.bold : FontWeight.normal,
                      fontSize: prominent ? 15 : 13)),
            ),
            Text('Rs ${amount.toStringAsFixed(2)}',
                style: TextStyle(
                    color: _navy,
                    fontSize: prominent ? 17 : 13,
                    fontWeight:
                        prominent ? FontWeight.w800 : FontWeight.w600)),
          ],
        ),
      );

  void _showReview() {
    final facility = widget.facility;
    final parking = facility.ratePerHour * _hours;
    final total = parking + facility.reservationFee;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Review your parking estimate',
                  style: TextStyle(
                      fontSize: 19, color: _navy, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(facility.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('$_vehicle  •  $_hours ${_hours == 1 ? 'hour' : 'hours'}',
                  style: const TextStyle(color: _muted)),
              const SizedBox(height: 12),
              _priceRow('Parking', parking),
              _priceRow('Reservation fee', facility.reservationFee),
              const Divider(),
              _priceRow('Estimated total', total, prominent: true),
              const SizedBox(height: 12),
              const Text(
                'This is an estimate. No bay has been reserved and no '
                'payment has been started. Final pricing and availability '
                'must be confirmed by the booking backend.',
                style: TextStyle(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => DriverReserveScreen(facility: facility, vehicle: _vehicle, hours: _hours)));
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Continue to reservation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facility = widget.facility;
    final parkingCost = facility.ratePerHour * _hours;
    final total = parkingCost + facility.reservationFee;
    final hasBays = !_loading && _error == null && (_availableBays ?? 0) > 0;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Space details'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh bay availability',
            onPressed: _loading ? null : _refreshAvailability,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _panel(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFEDF3FF),
                          child: Icon(Icons.local_parking, color: _navy),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(facility.name,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _navy)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            color: _navy, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(facility.address)),
                      ]),
                      const SizedBox(height: 12),
                      if (_loading)
                        const LinearProgressIndicator()
                      else if (_error != null)
                        Text(_error!,
                            style: const TextStyle(color: Colors.red))
                      else
                        Chip(
                          avatar: Icon(
                              hasBays ? Icons.check_circle : Icons.info_outline,
                              color: hasBays
                                  ? const Color(0xFF16834A)
                                  : Colors.deepOrange,
                              size: 18),
                          label: Text('$_availableBays free bays'),
                          backgroundColor: hasBays
                              ? const Color(0xFFEAF8EF)
                              : const Color(0xFFFFF1E6),
                        ),
                    ],
                  )),
                  const SizedBox(height: 20),
                  _heading('Vehicle type'),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    for (final type in ['Car', 'Bike', 'Van'])
                      _choice(type, _vehicle == type,
                          () => setState(() => _vehicle = type)),
                  ]),
                  const SizedBox(height: 18),
                  _heading('Parking duration'),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    for (final hours in [1, 2, 4, 8])
                      _choice('$hours ${hours == 1 ? 'hour' : 'hours'}',
                          _hours == hours,
                          () => setState(() => _hours = hours)),
                  ]),
                  const SizedBox(height: 20),
                  _heading('Estimated price'),
                  _panel(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _priceRow('Facility hourly rate', facility.ratePerHour),
                      _priceRow('Parking ($_hours hours)', parkingCost),
                      _priceRow('Reservation fee', facility.reservationFee),
                      const Divider(height: 28),
                      _priceRow('Estimated total', total, prominent: true),
                      const SizedBox(height: 10),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: _navy, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Estimate = facility hourly rate × duration + '
                              'reservation fee. Vehicle-specific, off-peak, '
                              'tax and other rules are not applied yet.',
                              style: TextStyle(fontSize: 12, color: _muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
                  const SizedBox(height: 16),
                  _panel(const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline, color: _navy),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pre-payment preview: no booking is created. '
                          'Connect secure server-side booking and pricing '
                          'validation before enabling payment.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated total',
                          style: TextStyle(color: _muted)),
                      Text('Rs ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _navy)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: hasBays ? _showReview : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: _navy,
                        disabledBackgroundColor: const Color(0xFFFFD58D),
                        disabledForegroundColor: _navy,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        hasBays
                            ? 'Continue to reservation'
                            : _loading
                                ? 'Checking availability...'
                                : 'No confirmed available bays',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
