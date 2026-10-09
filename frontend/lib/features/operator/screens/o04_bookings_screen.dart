import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/features/operator/operator_routes.dart';
import 'package:parkpin/features/operator/services/operator_service.dart';
import 'package:parkpin/features/operator/widgets/operator_ui.dart';
import 'package:parkpin/models/booking.dart';
import 'package:parkpin/services/supabase_service.dart';

/// O04 – Bookings (Figma "Operator · Bookings").
/// Pending = reserved, not arrived yet · Confirmed = checked in at the gate ·
/// Done = completed, cancelled or no-show. The list refreshes live.
class OperatorBookingsScreen extends StatefulWidget {
  const OperatorBookingsScreen({super.key});

  @override
  State<OperatorBookingsScreen> createState() => _OperatorBookingsScreenState();
}

class _OperatorBookingsScreenState extends State<OperatorBookingsScreen> {
  final _svc = OperatorService.instance;

  List<Booking> _all = [];
  bool _ready = false;
  String? _error;
  int _tab = 0;
  bool _holding = false;
  StreamSubscription<void>? _sub;
  final _search = TextEditingController();
  String _query = '';
  Timer? _clock; // keeps "in 20 min" / "late" labels current

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      await _svc.ensureLoaded();
      await _load();
      await _sub?.cancel();
      _sub = _svc.watchBookingChanges().listen((_) => _load(), onError: (_) {});
    } catch (e) {
      if (mounted) setState(() => _error = SupabaseService.friendlyError(e));
    }
  }

  Future<void> _load() async {
    try {
      final list = await _svc.getBookings();
      if (mounted) {
        setState(() {
          _all = list;
          _ready = true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && !_ready) setState(() => _error = SupabaseService.friendlyError(e));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _clock?.cancel();
    _search.dispose();
    super.dispose();
  }

  List<Booking> get _pending => _all.where((b) => b.status == Booking.reserved).toList();
  List<Booking> get _confirmed => _all.where((b) => b.status == Booking.active).toList();
  List<Booking> get _done => _all.where((b) => !b.isLive).toList().reversed.toList(); // newest first

  int get _upcomingToday => _pending.where((b) => isToday(b.startTime)).length;
  int get _needBay => _pending.where((b) => !b.hasBay).length;

  Future<void> _holdAll() async {
    setState(() => _holding = true);
    try {
      final n = await _svc.holdPendingBays(_pending);
      await _load();
      if (!mounted) return;
      final left = _needBay;
      showOpSnack(
        context,
        left > 0 ? 'Held $n bay(s). $left booking(s) still need a bay – the car park is full.' : 'Held $n bay(s) · drivers notified',
        error: left > 0,
      );
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _holding = false);
    }
  }

  /// Matches booking code, vehicle number, driver name or bay label.
  List<Booking> _filter(List<Booking> list) {
    final q = _query.trim().toUpperCase();
    if (q.isEmpty) return list;
    return list.where((b) {
      return b.bookingCode.toUpperCase().contains(q) ||
          (b.vehicleNumber ?? '').toUpperCase().replaceAll(' ', '').contains(q.replaceAll(' ', '')) ||
          (b.driverName ?? '').toUpperCase().contains(q) ||
          (b.bayLabel ?? '').toUpperCase() == q;
    }).toList();
  }

  Future<void> _openDetail(Booking b) async {
    await Navigator.of(context).pushNamed(OperatorRoutes.bookingDetail, arguments: b.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final lists = [_pending, _confirmed, _done];
    final current = _filter(lists[_tab]);
    final empty = [
      'No pending bookings.\nNew reservations appear here instantly.',
      'No drivers checked in right now.',
      'No finished bookings in the last 30 days.',
    ][_tab];

    return Scaffold(
      body: Column(
        children: [
          OperatorHeader(
            title: 'Bookings',
            subtitle: '$_upcomingToday upcoming today',
          ),
          Expanded(
            child: _error != null
                ? OpError(message: _error!, onRetry: _start)
                : !_ready
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                          children: [
                            const OpPageIntro(
                              title: 'Manage bookings',
                              subtitle: 'Hold bays, check drivers in and release no-shows.',
                            ),
                            OpSegmented(
                              options: [
                                'Pending (${_pending.length})',
                                'Confirmed (${_confirmed.length})',
                                'Done',
                              ],
                              selected: _tab,
                              onChanged: (i) => setState(() => _tab = i),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _search,
                              onChanged: (v) => setState(() => _query = v),
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(fontSize: 15.5),
                              decoration: opInputDecoration(
                                hint: 'Search code, vehicle, driver or bay',
                                prefixIcon: Icons.search,
                                suffix: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear search',
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: () => setState(() {
                                          _search.clear();
                                          _query = '';
                                        }),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SectionLabel(
                              ['Waiting to arrive', 'Parked now', 'Finished'][_tab],
                              action: '${current.length} booking${current.length == 1 ? '' : 's'}',
                            ),
                            if (current.isEmpty)
                              OpEmpty(
                                icon: _query.isEmpty ? Icons.event_busy_outlined : Icons.search_off,
                                message: _query.isEmpty ? empty : 'No bookings match "$_query".',
                              )
                            else
                              OpCard(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Column(
                                  children: [
                                    for (var i = 0; i < current.length; i++)
                                      _BookingRow(
                                        booking: current[i],
                                        last: i == current.length - 1,
                                        onTap: () => _openDetail(current[i]),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
          if (_tab == 0 && _ready)
            OpActionBar(children: [
              OpButton(
                label: _needBay == 0 ? 'All pending bays held' : 'Confirm & hold bays ($_needBay)',
                loading: _holding,
                onPressed: _needBay == 0 ? null : _holdAll,
              ),
            ]),
        ],
      ),
      bottomNavigationBar: const OperatorBottomNav(currentIndex: 1),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking, required this.last, required this.onTap});
  final Booking booking;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = bookingStatus(booking);
    final day = isToday(booking.startTime)
        ? ''
        : '${booking.startTime.day}/${booking.startTime.month} ';
    final bay = booking.bayLabel == null ? 'No bay yet' : 'Bay ${booking.bayLabel}';
    final iconColor = booking.status == Booking.active
        ? AppColors.success
        : isLate(booking)
            ? AppColors.danger
            : AppColors.primary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        child: Row(
          children: [
            OpIconBadge(
              letter: booking.bayLabel == null ? null : 'P',
              icon: Icons.schedule,
              color: iconColor,
              background: iconColor.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$day${hhmm(booking.startTime)} · $bay',
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: OpStyle.ink)),
                  const SizedBox(height: 2),
                  Text(
                    [booking.driverName ?? 'Driver', if (booking.vehicleNumber != null) booking.vehicleNumber!]
                        .join(' · '),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                  if (booking.status == Booking.reserved && isToday(booking.startTime)) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Arrives ${arrivalLabel(booking.startTime)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isLate(booking) ? AppColors.danger : AppColors.successDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            StatusChip(label, tone: tone),
          ],
        ),
      ),
    );
  }
}
