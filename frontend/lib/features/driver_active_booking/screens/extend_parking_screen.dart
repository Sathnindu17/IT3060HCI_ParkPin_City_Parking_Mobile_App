import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/active_booking_service.dart';
import '../widgets/parking_ui.dart';

class ExtendParkingScreen extends StatefulWidget {
  final ActiveBooking booking;
  final bool preview;
  final Future<void> Function(int minutes) onConfirm;

  const ExtendParkingScreen({
    super.key,
    required this.booking,
    required this.preview,
    required this.onConfirm,
  });

  @override
  State<ExtendParkingScreen> createState() =>
      _ExtendParkingScreenState();
}

class _ExtendParkingScreenState
    extends State<ExtendParkingScreen> {
  int _minutes = 30;
  bool _saving = false;
  String? _error;

  double get _fee =>
      widget.booking.extensionFeeFor(_minutes);

  DateTime get _newEndTime =>
      widget.booking.endTime.add(
        Duration(minutes: _minutes),
      );

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _formatMoney(double amount) {
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  Future<void> _confirm() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onConfirm(_minutes);

      if (!mounted) return;

      setState(() => _saving = false);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;

        if (error is PostgrestException) {
          _error = error.message;
        } else if (error is StateError) {
          _error = error.message.toString();
        } else {
          _error =
              'Unable to extend parking. Please try again.';
        }
      });
    }
  }

  Widget _timeOption(int minutes, String label) {
    final selected = _minutes == minutes;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: ParkingStyle.navy,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      side: BorderSide(
        color: selected
            ? ParkingStyle.navy
            : const Color(0xFFDCE4F0),
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected
            ? Colors.white
            : ParkingStyle.navy,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onSelected: _saving
          ? null
          : (_) {
              setState(() {
                _minutes = minutes;
                _error = null;
              });
            },
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: ParkingStyle.muted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 18 : 14,
              fontWeight: FontWeight.w700,
              color: ParkingStyle.navy,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: ParkingStyle.background,
        appBar: AppBar(
          backgroundColor: ParkingStyle.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 72,
          title: const Text(
            'Extend parking',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _saving
                ? null
                : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ParkingCard(
                  child: ParkingInfoRow(
                    icon: Icons.local_parking_rounded,
                    title: widget.booking.facilityName,
                    subtitle:
                        'Bay ${widget.booking.bayLabel} · '
                        'Currently ends at '
                        '${_formatTime(widget.booking.endTime)}',
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Need a little longer?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ParkingStyle.navy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose how much extra time you need.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: ParkingStyle.muted,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _timeOption(30, '+30 min'),
                    _timeOption(60, '+1 hour'),
                    _timeOption(120, '+2 hours'),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ParkingStyle.navy,
                        Color(0xFF2B5087),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.more_time_rounded,
                            color: ParkingStyle.orange,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'EXTENSION SUMMARY',
                              style: TextStyle(
                                color: Color(0xFFD7E1F1),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Additional parking',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFD7E1F1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rs ${_formatMoney(_fee)}',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+$_minutes minutes of parking',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ParkingCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      _summaryRow(
                        'Current end time',
                        _formatTime(widget.booking.endTime),
                      ),
                      const Divider(
                        height: 1,
                        color: Color(0xFFEDF0F6),
                      ),
                      _summaryRow(
                        'New end time',
                        _formatTime(_newEndTime),
                        highlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const ParkingCard(
                  color: Color(0xFFFFF5E4),
                  padding: EdgeInsets.all(16),
                  child: ParkingInfoRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Reminder adjusted',
                    subtitle:
                        'Your on-screen reminder follows the new end '
                        'time and appears 15 minutes before it ends.',
                  ),
                ),
                if (widget.preview)
                  const Center(
                    child: ParkingPreviewLabel(),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: ParkingFooter(
          primaryLabel:
              'Confirm extension · Rs ${_formatMoney(_fee)}',
          onPrimary: _confirm,
          busy: _saving,
        ),
      ),
    );
  }
}