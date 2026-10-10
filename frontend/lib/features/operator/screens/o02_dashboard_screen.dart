import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/features/operator/operator_routes.dart';
import 'package:parkpin/features/operator/services/operator_service.dart';
import 'package:parkpin/features/operator/widgets/operator_ui.dart';
import 'package:parkpin/models/app_notification.dart';
import 'package:parkpin/models/bay.dart';
import 'package:parkpin/models/booking.dart';
import 'package:parkpin/services/supabase_service.dart';

/// O02 – Operator dashboard (Figma "Operator · Dashboard").
/// Live bay counts (Realtime), today's bookings and money collected.
class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() => _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  final _svc = OperatorService.instance;

  bool _ready = false;
  String? _error;
  List<Bay> _bays = [];
  int _bookingsToday = 0;
  List<Booking> _bookings = [];
  double _collectedToday = 0;
  int _unread = 0;
  DateTime? _syncedAt;

  StreamSubscription<List<Bay>>? _baySub;
  StreamSubscription<void>? _bookingSub;
  StreamSubscription<List<AppNotification>>? _notifSub;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _start();
    // Refreshes the "synced x min ago" text.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      await _svc.ensureLoaded();
      _cancelStreams();
      _baySub = _svc.watchBays().listen(
        (bays) => setState(() {
          _bays = bays;
          _syncedAt = DateTime.now();
        }),
        onError: (Object e) => setState(() => _error = SupabaseService.friendlyError(e)),
      );
      _bookingSub = _svc.watchBookingChanges().listen((_) => _loadCounts());
      _notifSub = _svc.watchNotifications().listen(
            (list) => setState(() => _unread = list.where((n) => !n.isRead).length),
            onError: (_) {},
          );
      await _loadCounts();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = SupabaseService.friendlyError(e));
    }
  }

  Future<void> _loadCounts() async {
    try {
      final bookings = await _svc.getBookings();
      final payments = await _svc.getPayments(since: startOfToday());
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _bookingsToday = bookings
            .where((b) => isToday(b.startTime) && b.status != Booking.cancelled)
            .length;
        _collectedToday = payments.where((p) => p.isPaid).fold(0.0, (sum, p) => sum + p.total);
        _syncedAt = DateTime.now();
      });
    } catch (_) {
      // Counts are secondary; the live bay ring keeps working.
    }
  }

  void _cancelStreams() {
    _baySub?.cancel();
    _bookingSub?.cancel();
    _notifSub?.cancel();
  }

  @override
  void dispose() {
    _cancelStreams();
    _clock?.cancel();
    super.dispose();
  }

  String get _syncedText {
    if (_syncedAt == null) return 'Connecting…';
    final mins = DateTime.now().difference(_syncedAt!).inMinutes;
    return mins < 1 ? 'Live · synced just now' : 'Live · synced $mins min ago';
  }

  void _open(String route) => Navigator.of(context).pushNamed(route);

  Future<void> _openBooking(Booking b) async {
    await Navigator.of(context).pushNamed(OperatorRoutes.bookingDetail, arguments: b.id);
    _loadCounts();
  }

  /// Things the operator should act on now (shown only when they exist).
  List<Widget> _attentionItems() {
    final items = <Widget>[];
    final pending = _bookings.where((b) => b.status == Booking.reserved).toList();
    final needBay = pending.where((b) => !b.hasBay).length;
    final lateCount = pending.where((b) => isLate(b)).length;
    final total = _bays.length;
    final free = _bays.where((b) => b.isAvailable).length;

    if (needBay > 0) {
      items.add(OpNotice(
        icon: Icons.local_parking,
        text: '$needBay booking${needBay == 1 ? '' : 's'} still need a bay',
        onTap: () => _open(OperatorRoutes.bookings),
      ));
    }
    if (lateCount > 0) {
      items.add(OpNotice(
        icon: Icons.schedule,
        tone: ChipTone.danger,
        text: '$lateCount driver${lateCount == 1 ? ' is' : 's are'} over $lateGraceMinutes min late – check in or mark no-show',
        onTap: () => _open(OperatorRoutes.bookings),
      ));
    }
    if (total > 0 && free / total < 0.15) {
      items.add(OpNotice(
        icon: Icons.warning_amber_rounded,
        text: free == 0 ? 'Car park is full' : 'Only $free bay${free == 1 ? '' : 's'} left – update availability',
        onTap: () => _open(OperatorRoutes.availability),
      ));
    }
    return items;
  }

  /// Next pending arrivals today, soonest first (late ones included).
  List<Booking> get _nextArrivals {
    final list = _bookings
        .where((b) => b.status == Booking.reserved && isToday(b.startTime))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return list.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _svc.profile;
    final facility = _svc.facility;
    final attention = _attentionItems();
    final arrivals = _nextArrivals;
    return Scaffold(
      body: Column(
        children: [
          OperatorHeader(
            showBack: false,
            title: facility?.name ?? 'Car park',
            subtitle: 'Operator · ${profile?.firstName ?? ''}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BellButton(unread: _unread, onTap: () => _open(OperatorRoutes.notifications)),
                const SizedBox(width: 6),
                Semantics(
                  button: true,
                  label: 'Profile',
                  child: GestureDetector(
                    onTap: () => _open(OperatorRoutes.profile),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Text(profile?.initials ?? '',
                          style: const TextStyle(
                              fontSize: 13.5, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
              ],
            ),
            bottom: LiveBadge(text: _syncedText),
          ),
          Expanded(
            child: _error != null
                ? OpError(message: _error!, onRetry: _start)
                : !_ready
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadCounts,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          children: [
                            _HeroCard(bays: _bays),
                            const SizedBox(height: 16),
                            if (attention.isNotEmpty) ...[
                              const SectionLabel('Needs attention'),
                              for (final item in attention) ...[item, const SizedBox(height: 8)],
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: _Metric(
                                    icon: Icons.event_note_outlined,
                                    value: '$_bookingsToday',
                                    label: 'bookings today',
                                    onTap: () => _open(OperatorRoutes.bookings),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _Metric(
                                    icon: Icons.payments_outlined,
                                    value: rs(_collectedToday),
                                    label: 'collected today',
                                    onTap: () => _open(OperatorRoutes.payments),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            const SectionLabel('Quick actions'),
                            Row(
                              children: [
                                Expanded(
                                  child: _Tile(
                                    icon: Icons.grid_view_rounded,
                                    label: 'Publish availability',
                                    onTap: () => _open(OperatorRoutes.availability),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _Tile(
                                    icon: Icons.event_available_outlined,
                                    label: 'Manage bookings',
                                    onTap: () => _open(OperatorRoutes.bookings),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _Tile(
                                    icon: Icons.qr_code_scanner,
                                    label: 'Gate check',
                                    onTap: () => _open(OperatorRoutes.gate),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _Tile(
                                    icon: Icons.sell_outlined,
                                    label: 'Off-peak pricing',
                                    onTap: () => _open(OperatorRoutes.pricing),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            SectionLabel(
                              'Next arrivals',
                              action: 'See all',
                              onAction: () => _open(OperatorRoutes.bookings),
                            ),
                            if (arrivals.isEmpty)
                              const OpCard(
                                child: Text('No more arrivals booked for today.',
                                    style: TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
                              )
                            else
                              OpCard(
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
                                child: Column(
                                  children: [
                                    for (final b in arrivals)
                                      _ArrivalRow(
                                        booking: b,
                                        last: b == arrivals.last,
                                        onTap: () => _openBooking(b),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const OperatorBottomNav(currentIndex: 0),
    );
  }
}

class _ArrivalRow extends StatelessWidget {
  const _ArrivalRow({required this.booking, required this.last, required this.onTap});
  final Booking booking;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final overdue = isLate(b);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: OpStyle.tileBg, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(hhmm(b.startTime),
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.bayLabel == null ? 'No bay yet' : 'Bay ${b.bayDisplay}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: OpStyle.ink)),
                  Text(
                    [b.driverName ?? 'Driver', if (b.vehicleNumber != null) b.vehicleNumber!].join(' · '),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            StatusChip(arrivalLabel(b.startTime), tone: overdue ? ChipTone.danger : ChipTone.neutral),
          ],
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.onTap});
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        backgroundColor: AppColors.accent,
        textColor: AppColors.onAccent,
        child: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
      ),
    );
  }
}

/// Ring with free bays + occupancy per level.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.bays});
  final List<Bay> bays;

  @override
  Widget build(BuildContext context) {
    final total = bays.length;
    final free = bays.where((b) => b.isAvailable).length;
    final occupiedPct = total == 0 ? 0 : ((total - free) * 100 / total).round();

    // Occupancy per level (L1, L2 …)
    final levels = <String, List<Bay>>{};
    for (final b in bays) {
      levels.putIfAbsent(b.level ?? 'Other', () => []).add(b);
    }
    final levelNames = levels.keys.toList()..sort();

    return OpHeroCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeroCaption('Live occupancy', icon: Icons.local_parking),
          const SizedBox(height: 14),
          Row(
            children: [
              Semantics(
                label: '$free of $total bays free',
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: CustomPaint(
                    painter: _RingPainter(total == 0 ? 0 : (total - free) / total),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$free',
                              style: const TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, height: 1.05)),
                          Text('free',
                              style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$occupiedPct% occupied',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('of $total bays',
                        style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.8))),
                    for (final name in levelNames) ...[
                      const SizedBox(height: 9),
                      _LevelBar(name: name, bays: levels[name]!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.name, required this.bays});
  final String name;
  final List<Bay> bays;

  @override
  Widget build(BuildContext context) {
    final used = bays.where((b) => !b.isAvailable).length;
    final ratio = bays.isEmpty ? 0.0 : used / bays.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
            Text('${(ratio * 100).round()}%',
                style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85))),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.occupied);
  final double occupied; // 0–1

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fg = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, 2 * math.pi, false, bg);
    if (occupied > 0) canvas.drawArc(r, -math.pi / 2, 2 * math.pi * occupied, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.occupied != occupied;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label, required this.onTap});
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OpCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          OpIconBadge(icon: icon, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: OpStyle.ink)),
                ),
                Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OpCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      onTap: onTap,
      child: Column(
        children: [
          OpIconBadge(icon: icon, size: 48),
          const SizedBox(height: 10),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: OpStyle.ink)),
        ],
      ),
    );
  }
}
