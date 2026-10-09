import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/active_booking_service.dart';
import '../widgets/parking_ui.dart';
import 'extend_parking_screen.dart';

class ActiveBookingScreen extends StatefulWidget {
  final String? bookingId;

  const ActiveBookingScreen({
    super.key,
    this.bookingId,
  });

  @override
  State<ActiveBookingScreen> createState() =>
      _ActiveBookingScreenState();
}

class _ActiveBookingScreenState extends State<ActiveBookingScreen>
    with WidgetsBindingObserver {
  ActiveBookingService? _service;
  ActiveBooking? _booking;
  Timer? _timer;

  DateTime _now = DateTime.now();

  bool _loading = true;
  bool _busy = false;
  String? _error;

  bool get _preview => widget.bookingId == null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    if (!_preview) {
      _service = ActiveBookingService();
    }

    _load();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() => _now = DateTime.now());
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_preview &&
        !_busy &&
        !_loading) {
      _load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  String _errorMessage(Object error) {
    if (error is PostgrestException) return error.message;
    if (error is AuthException) return error.message;
    if (error is StateError) return error.message.toString();

    return 'Unable to connect. Check your connection and try again.';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ActiveBooking booking;

      if (_preview) {
        final now = DateTime.now();

        booking = ActiveBooking(
          id: 'design-preview',
          facilityName: 'One Galle Face',
          bayLabel: 'B-12',
          status: 'active',
          startTime: now.subtract(
            const Duration(minutes: 73),
          ),
          endTime: now.add(
            const Duration(minutes: 47),
          ),
          ratePerHour: 100,
        );
      } else {
        booking = await _service!.open(widget.bookingId!);
      }

      if (!mounted) return;

      setState(() {
        _booking = booking;
        _now = DateTime.now();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _errorMessage(error);
        _loading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _extend() async {
    if (_busy || _booking == null) return;

    final currentBooking = _booking!;

    setState(() => _busy = true);

    try {
      final confirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ExtendParkingScreen(
            booking: currentBooking,
            preview: _preview,
            onConfirm: (minutes) async {
              final ActiveBooking updated;

              if (_preview) {
                updated = currentBooking.withExtraMinutes(minutes);
              } else {
                updated = await _service!.extend(
                  currentBooking,
                  minutes: minutes,
                );
              }

              if (!mounted) return;

              setState(() {
                _booking = updated;
                _now = DateTime.now();
              });
            },
          ),
        ),
      );

      if (!mounted || confirmed != true) return;

      _showMessage(
        _preview
            ? 'Preview updated. No database changes.'
            : 'Parking extended successfully.',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _finish() async {
    if (_busy || _booking == null) return;

    if (_preview) {
      _showMessage(
        'Design preview only. Sign in to end a real booking.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End parking?'),
        content: const Text(
          'Your booking will be completed and the bay released. '
          'Your booking and payment records will be retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    try {
      await _service!.finish(_booking!.id);

      if (!mounted) return;

      _showMessage('Parking completed successfully.');

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        await _load();
      }
    } catch (error) {
      if (mounted) {
        _showMessage(_errorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _timeLabel(Duration remaining) {
    final minutes = (remaining.inSeconds / 60).ceil();
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${remainder.toString().padLeft(2, '0')}';
  }

  String _clockTime(DateTime value) {
    return TimeOfDay.fromDateTime(
      value.toLocal(),
    ).format(context);
  }

  Widget _timeDetail(String label, DateTime value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              color: ParkingStyle.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _clockTime(value),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ParkingStyle.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: ParkingStyle.navy,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unable to load this booking.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _load,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingContent(ActiveBooking booking) {
    final remaining = booking.remainingAt(_now);

    String reminder =
        'A reminder appears here 15 minutes before your time ends.';

    if (!booking.isActive) {
      reminder = 'This booking is ${booking.status}.';
    } else if (remaining == Duration.zero) {
      reminder =
          'Your parking time has ended. Please end your session.';
    } else if (remaining <= const Duration(minutes: 15)) {
      reminder =
          '15 minutes or less remaining. Extend if you need more time.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ParkingCard(
            child: ParkingInfoRow(
              icon: Icons.local_parking_rounded,
              title: booking.facilityName,
              subtitle:
                  'Bay ${booking.bayLabel} · '
                  '${booking.status.toUpperCase()}',
            ),
          ),
          const SizedBox(height: 22),
          ParkingCard(
            child: Column(
              children: [
                const Text(
                  'YOUR PARKING TIME',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                    color: ParkingStyle.muted,
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  label: '${_timeLabel(remaining)} remaining',
                  child: SizedBox(
                    width: 190,
                    height: 190,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: booking.progressAt(_now),
                            strokeWidth: 12,
                            backgroundColor:
                                const Color(0xFFEDF0F6),
                            color: ParkingStyle.orange,
                          ),
                        ),
                        Container(
                          width: 152,
                          height: 152,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFD),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 23,
                              color: ParkingStyle.navy,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _timeLabel(remaining),
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: ParkingStyle.navy,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'hours : minutes left',
                              style: TextStyle(
                                fontSize: 11,
                                color: ParkingStyle.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                const Divider(
                  color: Color(0xFFEDF0F6),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _timeDetail(
                      'START TIME',
                      booking.startTime,
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      color: const Color(0xFFE8EDF5),
                    ),
                    _timeDetail(
                      'ENDS AT',
                      booking.endTime,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ParkingCard(
            color: const Color(0xFFFFF5E4),
            padding: const EdgeInsets.all(16),
            child: ParkingInfoRow(
              icon: Icons.notifications_active_outlined,
              title: 'Parking reminder',
              subtitle: reminder,
            ),
          ),
          if (_preview) const ParkingPreviewLabel(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;

    final canExtend = booking != null &&
        booking.isActive &&
        booking.remainingAt(_now) > Duration.zero &&
        !_busy &&
        !_loading;

    final canFinish = booking != null &&
        booking.isActive &&
        !_busy &&
        !_loading;

    return Scaffold(
      backgroundColor: ParkingStyle.background,
      appBar: AppBar(
        backgroundColor: ParkingStyle.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        title: const Text(
          'Active booking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _busy
              ? null
              : () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (!_preview)
            IconButton(
              tooltip: 'Refresh',
              onPressed: _busy || _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView()
                : booking == null
                    ? const Center(
                        child: Text('No booking available.'),
                      )
                    : _bookingContent(booking),
      ),
      bottomNavigationBar:
          booking == null || _loading || _error != null
              ? null
              : ParkingFooter(
                  primaryLabel:
                      'Extend parking · Rs '
                      '${booking.extensionFee.toStringAsFixed(2)} / 30 min',
                  onPrimary: canExtend ? _extend : null,
                  secondaryLabel: 'End & exit',
                  onSecondary: canFinish ? _finish : null,
                  busy: _busy,
                ),
    );
  }
}