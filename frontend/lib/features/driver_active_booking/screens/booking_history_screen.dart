import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/booking_history_service.dart';
import '../widgets/parking_ui.dart';
import 'active_booking_screen.dart';
import 'receipt_screen.dart';
import 'reservation_recovery_screen.dart';

export '../services/booking_history_service.dart'
    show HistoryBooking, HistoryBookingStatus;

class BookingHistoryScreen extends StatefulWidget {
  final List<HistoryBooking>? bookings;
  final bool preview;
  final bool initialShowUpcoming;
  final ValueChanged<HistoryBooking>? onOpenBooking;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onFindAnotherParking;

  const BookingHistoryScreen({
    super.key,
    this.bookings,
    this.preview = true,
    this.initialShowUpcoming = true,
    this.onOpenBooking,
    this.onNavigate,
    this.onFindAnotherParking,
  });

  @override
  State<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  BookingHistoryService? _service;
  final _search = TextEditingController();

  List<HistoryBooking> _bookings = [];

  bool _loading = true;
  bool _busy = false;
  bool _showUpcoming = true;
  bool _showHidden = false;
  bool _samplesLoaded = false;

  String? _error;
  int _loadVersion = 0;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();

    _showUpcoming = widget.initialShowUpcoming;

    if (!widget.preview) {
      _service = BookingHistoryService();
    }

    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _errorMessage(Object error) {
    if (error is PostgrestException) return error.message;
    if (error is AuthException) return error.message;
    if (error is StateError) return error.message.toString();

    return 'Could not complete this action. Please try again.';
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _load() async {
    if (!mounted) return;

    final version = ++_loadVersion;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<HistoryBooking> result;

      if (widget.preview) {
        result = _samplesLoaded
            ? _bookings
            : widget.bookings ?? HistoryBooking.samples();

        _samplesLoaded = true;
      } else {
        result = await _service!.loadHistory();
      }

      if (!mounted || version != _loadVersion) return;

      setState(() => _bookings = List.of(result));
    } catch (error) {
      if (!mounted || version != _loadVersion) return;

      setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted && version == _loadVersion) {
        setState(() => _loading = false);
      }
    }
  }

  List<HistoryBooking> get _visible {
    final query = _search.text.trim().toLowerCase();

    final result = _bookings.where((booking) {
      if (_showHidden) {
        if (!booking.hiddenFromHistory) return false;
      } else {
        if (booking.hiddenFromHistory) return false;
        if (booking.isUpcoming != _showUpcoming) return false;
      }

      final text = [
        booking.facilityName,
        booking.bayLabel,
        booking.reference,
        booking.statusLabel,
      ].join(' ').toLowerCase();

      return query.isEmpty || text.contains(query);
    }).toList();

    result.sort(
      (a, b) => !_showHidden && _showUpcoming
          ? a.startTime.compareTo(b.startTime)
          : b.startTime.compareTo(a.startTime),
    );

    return result;
  }

  String _money(int cents) => (cents / 100).toStringAsFixed(2);

  String _date(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';

    return '${local.day} ${_months[local.month - 1]} '
        '${local.year} · $hour:$minute $period';
  }

  String _duration(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    if (hours == 0) return '$remainder min';
    if (remainder == 0) return '$hours h';

    return '$hours h $remainder min';
  }

  Future<void> _setHidden(
    HistoryBooking booking,
    bool hidden,
  ) async {
    if (_busy || _loading || booking.isUpcoming) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          hidden ? 'Hide this booking?' : 'Restore this booking?',
        ),
        content: Text(
          hidden
              ? 'It will move to Hidden bookings. Your receipt and '
                  'payment records remain saved.'
              : 'It will return to your Past bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(hidden ? 'Hide booking' : 'Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    try {
      if (!widget.preview) {
        await _service!.setHidden(booking.id, hidden);
      }

      if (!mounted) return;

      setState(() {
        _bookings = _bookings.map((entry) {
          return entry.id == booking.id
              ? entry.withVisibility(hidden)
              : entry;
        }).toList();
      });

      _message(
        hidden ? 'Booking moved to Hidden bookings.' : 'Booking restored.',
      );
    } catch (error) {
      _message(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openReceipt(HistoryBooking booking) async {
    final receipt = booking.receipt;

    if (receipt == null || _busy || _loading) return;

    setState(() => _busy = true);

    try {
      if (!widget.preview) {
        await _service!.markReceiptViewed(booking.id);
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptScreen(
            receipt: receipt,
            preview: widget.preview,
            onNavigate: widget.onNavigate,
          ),
        ),
      );

      if (mounted && !widget.preview) await _load();
    } catch (error) {
      _message(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openBooking(HistoryBooking booking) async {
    if (_busy || _loading) return;

    final callback = widget.onOpenBooking;

    if (callback != null) {
      callback(booking);
      return;
    }

    if (!booking.isUpcoming) {
      _details(booking);
      return;
    }

    if (widget.preview &&
        booking.status == HistoryBookingStatus.reserved) {
      _message(
        'This sample reservation does not start a real parking session.',
      );
      _details(booking);
      return;
    }

    setState(() => _busy = true);

    try {
      if (!widget.preview) {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;

        if (user == null) {
          throw StateError('Please sign in to open your booking.');
        }

        final data = await client
            .from('bookings')
            .select('status, bay:bays(is_out_of_service)')
            .eq('id', booking.id)
            .eq('driver_id', user.id)
            .single();

        if (!mounted) return;

        if (client.auth.currentUser?.id != user.id) {
          throw StateError('Your account changed. Reopen your bookings.');
        }

        final status = data['status'] as String;
        final bay = data['bay'] as Map<String, dynamic>?;

        if (status != 'reserved' && status != 'active') {
          _message('This booking is now $status.');
          await _load();
          return;
        }

        if (status == 'reserved') {
          if (bay == null) {
            throw StateError(
              'This reservation has no assigned bay. '
              'Please contact the parking operator.',
            );
          }

          if (bay['is_out_of_service'] == true) {
            final recovered = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => ReservationRecoveryScreen(
                  bookingId: booking.id,
                  onFindAnotherParking: widget.onFindAnotherParking,
                ),
              ),
            );

            if (!mounted) return;

            await _load();

            if (recovered == true) {
              _message(
                'Alternative bay assigned. '
                'Open the reservation again when you are ready to start.',
              );
            }

            return;
          }

          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Start parking?'),
              content: const Text(
                'Confirm that you have arrived and are ready '
                'to use your reserved bay.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Start parking'),
                ),
              ],
            ),
          );

          if (confirmed != true || !mounted) return;
        }
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ActiveBookingScreen(
            bookingId: widget.preview ? null : booking.id,
          ),
        ),
      );

      if (mounted && !widget.preview) await _load();
    } catch (error) {
      _message(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _details(HistoryBooking booking) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: ParkingStyle.background,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                booking.facilityName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ParkingStyle.navy,
                ),
              ),
              const SizedBox(height: 18),
              ParkingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reference: ${booking.reference}'),
                    const SizedBox(height: 12),
                    Text('Bay: ${booking.bayLabel}'),
                    const SizedBox(height: 12),
                    Text('Status: ${booking.statusLabel}'),
                    const SizedBox(height: 12),
                    Text('Starts: ${_date(booking.startTime)}'),
                    const SizedBox(height: 12),
                    Text(
                      'Booked duration: '
                      '${_duration(booking.durationMinutes)}',
                    ),
                    const SizedBox(height: 12),
                    Text('Paid: Rs ${_money(booking.totalCents)}'),
                    if (booking.completedAt != null) ...[
                      const SizedBox(height: 12),
                      Text('Ended: ${_date(booking.completedAt!)}'),
                    ],
                    if (booking.receiptViewedAt != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Receipt first viewed: '
                        '${_date(booking.receiptViewedAt!)}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(int index) {
    if (_busy || _loading || index == 1) return;

    final callback = widget.onNavigate;

    if (callback != null) {
      callback(index);
      return;
    }

    if (index == 2) {
      final receipts =
          _bookings.where((entry) => entry.receipt != null).toList();

      receipts.sort(
        (a, b) => b.receipt!.paidAt.compareTo(a.receipt!.paidAt),
      );

      if (receipts.isEmpty) {
        _message('No final receipts yet.');
      } else {
        _openReceipt(receipts.first);
      }

      return;
    }

    _message('This destination will use the main app navigation.');
  }

  Widget _tab(bool upcoming, String label, int count) {
    final selected = !_showHidden && _showUpcoming == upcoming;

    return Expanded(
      child: Material(
        color: selected ? ParkingStyle.navy : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _busy || _loading
              ? null
              : () {
                  setState(() {
                    _showHidden = false;
                    _showUpcoming = upcoming;
                  });
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              '$label ($count)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : ParkingStyle.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(HistoryBooking booking) {
    final statusColor = booking.isUpcoming
        ? ParkingStyle.navy
        : booking.status == HistoryBookingStatus.completed
            ? const Color(0xFF16864B)
            : const Color(0xFFB45309);

    final actionLabel = switch (booking.status) {
      HistoryBookingStatus.reserved => 'Open reservation',
      HistoryBookingStatus.active => 'Open active booking',
      _ => 'Booking details',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ParkingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ParkingInfoRow(
              icon: Icons.local_parking_rounded,
              title: booking.facilityName,
              subtitle: 'Bay ${booking.bayLabel}',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (booking.hiddenFromHistory)
                  const Chip(
                    label: Text('Hidden'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _date(booking.startTime),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: ParkingStyle.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Booked: ${_duration(booking.durationMinutes)}',
              style: const TextStyle(color: ParkingStyle.muted),
            ),
            const SizedBox(height: 8),
            Text(
              booking.reference,
              style: const TextStyle(
                color: ParkingStyle.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFE8EDF5)),
            Text(
              'Paid: Rs ${_money(booking.totalCents)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ParkingStyle.navy,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy || _loading
                    ? null
                    : () => _openBooking(booking),
                child: Text(actionLabel),
              ),
            ),
            if (booking.isUpcoming) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _busy || _loading
                      ? null
                      : () => _details(booking),
                  child: const Text('View details'),
                ),
              ),
            ],
            if (booking.receipt != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy || _loading
                      ? null
                      : () => _openReceipt(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ParkingStyle.orange,
                    foregroundColor: ParkingStyle.navy,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(
                    booking.receiptViewedAt == null
                        ? 'View receipt'
                        : 'View receipt again',
                  ),
                ),
              ),
            ],
            if (!booking.isUpcoming) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _busy || _loading
                      ? null
                      : () => _setHidden(
                            booking,
                            !booking.hiddenFromHistory,
                          ),
                  icon: Icon(
                    booking.hiddenFromHistory
                        ? Icons.restore_rounded
                        : Icons.visibility_off_outlined,
                  ),
                  label: Text(
                    booking.hiddenFromHistory
                        ? 'Restore booking'
                        : 'Hide from history',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcomingCount = _bookings
        .where((entry) => !entry.hiddenFromHistory && entry.isUpcoming)
        .length;

    final pastCount = _bookings
        .where((entry) => !entry.hiddenFromHistory && !entry.isUpcoming)
        .length;

    final hiddenCount =
        _bookings.where((entry) => entry.hiddenFromHistory).length;

    final visible = _visible;

    return Scaffold(
      backgroundColor: ParkingStyle.background,
      appBar: AppBar(
        backgroundColor: ParkingStyle.navy,
        foregroundColor: Colors.white,
        toolbarHeight: 72,
        title: const Text('Your bookings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading || _busy ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: RefreshIndicator(
              onRefresh: () async {
                if (!_busy && !_loading) await _load();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Your parking history',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: ParkingStyle.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'View bookings, open receipts and manage your history.',
                    style: TextStyle(
                      color: ParkingStyle.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0F8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        _tab(true, 'Upcoming', upcomingCount),
                        const SizedBox(width: 4),
                        _tab(false, 'Past', pastCount),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _busy || _loading
                          ? null
                          : () {
                              setState(() {
                                _showHidden = !_showHidden;
                              });
                            },
                      icon: Icon(
                        _showHidden
                            ? Icons.arrow_back_rounded
                            : Icons.archive_outlined,
                      ),
                      label: Text(
                        _showHidden
                            ? 'Back to bookings'
                            : 'Hidden bookings ($hiddenCount)',
                      ),
                    ),
                  ),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search parking, bay or reference',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(
                        color: ParkingStyle.orange,
                      ),
                    ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: ParkingStyle.orange,
                        ),
                      ),
                    )
                  else if (_error != null)
                    ParkingCard(
                      child: Column(
                        children: [
                          const Text(
                            'Could not load history',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _load,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      _showHidden
                          ? 'Hidden bookings'
                          : _showUpcoming
                              ? 'Upcoming parking'
                              : 'Past parking',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: ParkingStyle.navy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (visible.isEmpty)
                      ParkingCard(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.event_note_rounded,
                              size: 48,
                              color: ParkingStyle.muted,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No bookings found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: ParkingStyle.navy,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _showHidden
                                  ? 'Bookings you hide will appear here.'
                                  : 'Try the other tab or change your search.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: ParkingStyle.muted,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...visible.map(_card),
                  ],
                  if (widget.preview)
                    const Center(child: ParkingPreviewLabel()),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ParkingStyle.navy,
        unselectedItemColor: ParkingStyle.muted,
        backgroundColor: Colors.white,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: _navigate,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
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
    );
  }
}