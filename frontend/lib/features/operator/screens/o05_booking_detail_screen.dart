import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/features/operator/services/operator_service.dart';
import 'package:parkpin/features/operator/widgets/operator_ui.dart';
import 'package:parkpin/models/bay.dart';
import 'package:parkpin/models/booking.dart';
import 'package:parkpin/services/supabase_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// O05 – Booking detail & bay assignment (Figma "Operator · O05 Booking Detail").
/// Hold or reassign the bay, check the driver out, mark a no-show, or message
/// the driver.
class OperatorBookingDetailScreen extends StatefulWidget {
  const OperatorBookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<OperatorBookingDetailScreen> createState() => _OperatorBookingDetailScreenState();
}

class _OperatorBookingDetailScreenState extends State<OperatorBookingDetailScreen> {
  final _svc = OperatorService.instance;
  Booking? _b;
  String? _error;
  bool _busy = false;
  String? _phone; // driver's phone (if they added one)
  double? _paid; // total paid for this booking

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await _svc.ensureLoaded();
      final b = await _svc.getBooking(widget.bookingId);
      if (mounted) setState(() => _b = b);
      _loadExtras(b);
    } catch (e) {
      if (mounted) setState(() => _error = SupabaseService.friendlyError(e));
    }
  }

  /// Phone and payment are extras – the screen still works if they fail.
  Future<void> _loadExtras(Booking b) async {
    try {
      final results = await Future.wait([
        _svc.getDriverPhone(b.driverId),
        _svc.getBookingPaidTotal(b.id),
      ]);
      if (!mounted) return;
      setState(() {
        _phone = results[0] as String?;
        _paid = results[1] as double;
      });
    } catch (_) {}
  }

  Future<void> _callDriver() async {
    final uri = Uri(scheme: 'tel', path: _phone);
    final ok = await launchUrl(uri);
    if (!ok && mounted) showOpSnack(context, 'Could not open the phone app.', error: true);
  }

  /// Runs an action, shows its result and reloads the booking.
  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final msg = await action();
      await _load();
      if (mounted) showOpSnack(context, msg);
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _hold() => _run(() async {
        final label = await _svc.confirmAndHold(_b!);
        return 'Bay $label held · driver notified';
      });

  Future<void> _reassign() async {
    List<Bay> free;
    try {
      free = await _svc.getFreeBays();
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
      return;
    }
    if (!mounted) return;
    if (free.isEmpty) {
      showOpSnack(context, 'No free bays right now. Free a bay on Publish availability first.', error: true);
      return;
    }
    final bay = await showModalBottomSheet<Bay>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => _BayPicker(free: free, current: _b!.bayLabel),
    );
    if (bay == null) return;
    await _run(() async {
      await _svc.assignBay(_b!.id, bay.id);
      await _svc.notify(_b!.driverId, 'Your bay changed', 'Please park in bay ${bay.display} instead.',
          type: 'booking');
      return 'Moved to bay ${bay.display} · driver notified';
    });
  }

  Future<void> _checkOut() async {
    final ok = await confirmDialog(context, 'Check out driver?', 'The bay will be freed for other drivers.',
        confirm: 'Check out');
    if (ok) {
      await _run(() async {
        await _svc.checkOut(_b!);
        return 'Checked out · bay freed';
      });
    }
  }

  Future<void> _noShow() async {
    final ok = await confirmDialog(context, 'Mark as no-show?',
        'The booking will be released and the bay freed. The driver is notified.',
        confirm: 'Mark no-show', danger: true);
    if (ok) {
      await _run(() async {
        await _svc.markNoShow(_b!);
        return 'Marked as no-show · bay freed';
      });
    }
  }

  Future<void> _message() async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Message driver', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Common messages staff send – one tap fills the box.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final quick in const [
                  'Your bay is ready.',
                  'We are holding your bay for 15 more minutes.',
                  'Please use the north entrance.',
                  'Please move to the bay shown in the app.',
                ])
                  ActionChip(
                    label: Text(quick, style: const TextStyle(fontSize: 12.5)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () => ctrl.text = quick,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(hintText: 'Or type your own message'),
            ),
          ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Send')),
        ],
      ),
    );
    ctrl.dispose();
    if (text == null || text.trim().isEmpty) return;
    await _run(() async {
      await _svc.messageDriver(_b!, text);
      return 'Message sent to ${_b!.driverName ?? 'driver'}';
    });
  }

  String _subtitle(Booking b) => switch (b.status) {
        Booking.reserved => b.hasBay ? 'Pending · bay held' : 'Pending · hold or reassign',
        Booking.active => 'Checked in · driver is parked',
        _ => 'Finished',
      };

  String _statusText(Booking b) => switch (b.status) {
        Booking.reserved => b.hasBay ? 'Held' : 'Waiting for a bay',
        Booking.active => 'Checked in',
        Booking.completed => 'Completed',
        Booking.cancelled => 'Cancelled by driver',
        Booking.expired => 'No-show',
        _ => b.status,
      };

  @override
  Widget build(BuildContext context) {
    final b = _b;
    final when = b == null
        ? ''
        : '${DateFormat('d MMM, h:mm a').format(b.startTime)} – ${DateFormat('h:mm a').format(b.endTime)}';

    return Scaffold(
      body: Column(
        children: [
          OperatorHeader(
            title: 'Booking detail',
            subtitle: b == null ? null : _subtitle(b),
            trailing: b != null && b.isLive
                ? HeaderAction(icon: Icons.chat_bubble_outline, tooltip: 'Message driver', onTap: _message)
                : null,
          ),
          Expanded(
            child: _error != null
                ? OpError(message: _error!, onRetry: _load)
                : b == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                        children: [
                          _StatusTimeline(booking: b),
                          const SizedBox(height: 14),
                          if (isLate(b)) ...[
                            OpNotice(
                              icon: Icons.schedule,
                              tone: ChipTone.danger,
                              text: 'Driver is ${arrivalLabel(b.startTime)}. Call them, or mark as no-show '
                                  'to free the bay.',
                            ),
                            const SizedBox(height: 10),
                          ] else if (b.status == Booking.reserved && isToday(b.startTime)) ...[
                            OpNotice(
                              icon: Icons.directions_car_outlined,
                              tone: ChipTone.success,
                              text: 'Arrives ${arrivalLabel(b.startTime)}',
                            ),
                            const SizedBox(height: 10),
                          ],
                          OpCard(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const OpIconBadge(letter: 'P', size: 50),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(b.driverName ?? 'Driver', style: OpStyle.cardTitle),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${b.bayDisplay} · ${b.vehicleNumber ?? 'No vehicle'}',
                                            style: OpStyle.muted,
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusChip(bookingStatus(b).$1, tone: bookingStatus(b).$2),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                InfoRow('Driver', b.driverName ?? '—'),
                                InfoRow('Vehicle', b.vehicleNumber ?? '—'),
                                InfoRow('Reserved bay', b.bayDisplay),
                                InfoRow('Arrival', when),
                                InfoRow('Booking code', b.bookingCode),
                                InfoRow('Paid', _paid == null ? '…' : (_paid! > 0 ? rs(_paid!) : 'Not paid')),
                                InfoRow('Status', _statusText(b), last: true),
                              ],
                            ),
                          ),
                          if (_phone != null && b.isLive) ...[
                            const SizedBox(height: 10),
                            OpCard(
                              onTap: _callDriver,
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  const OpIconBadge(
                                    icon: Icons.call_outlined,
                                    size: 40,
                                    background: AppColors.successBg,
                                    color: AppColors.successDark,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text('Call ${b.driverName ?? 'driver'}',
                                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                                  ),
                                  Text(_phone!, style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
          ),
          if (b != null && b.isLive)
            OpActionBar(safeBottom: true, children: [
              if (b.status == Booking.reserved)
                OpButton(
                  label: b.hasBay ? 'Confirm & notify driver' : 'Confirm & hold bay',
                  loading: _busy,
                  onPressed: _hold,
                )
              else
                OpButton(label: 'Check out', loading: _busy, onPressed: _checkOut),
              OpButton(label: 'Reassign bay', outlined: true, onPressed: _busy ? null : _reassign),
              if (b.status == Booking.reserved)
                TextButton(
                  onPressed: _busy ? null : _noShow,
                  child: const Text('Mark as no-show', style: TextStyle(color: AppColors.danger, fontSize: 14)),
                ),
            ]),
        ],
      ),
    );
  }
}

/// Booked → Bay held → Checked in → Completed, so staff see where a booking is.
class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.booking});
  final Booking booking;

  static const _steps = ['Booked', 'Bay held', 'Checked in', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final b = booking;
    if (b.status == Booking.cancelled || b.status == Booking.expired) {
      return OpNotice(
        icon: Icons.block,
        tone: ChipTone.danger,
        text: b.status == Booking.cancelled
            ? 'Cancelled by the driver – the bay was released.'
            : 'No-show – the booking expired and the bay was released.',
      );
    }
    final reached = switch (b.status) {
      Booking.completed => 3,
      Booking.active => 2,
      _ => b.hasBay ? 1 : 0,
    };
    return Semantics(
      label: 'Booking progress: ${_steps[reached]}',
      child: OpCard(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
        child: Row(
          children: [
            for (var i = 0; i < _steps.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= reached ? AppColors.primary : Colors.white,
                        border: Border.all(color: i <= reached ? AppColors.primary : AppColors.occupied, width: 1.5),
                      ),
                      child: i < reached
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : i == reached
                              ? Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                                )
                              : null,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _steps[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: i == reached ? FontWeight.w600 : FontWeight.w400,
                        color: i <= reached ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BayPicker extends StatelessWidget {
  const _BayPicker({required this.free, this.current});
  final List<Bay> free;
  final String? current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a free bay', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            if (current != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Currently bay $current',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
              ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final bay in free)
                      ActionChip(
                        avatar: bay.isEv ? const Icon(Icons.ev_station, size: 16) : null,
                        label: Text(bay.display),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.success),
                        onPressed: () => Navigator.pop(context, bay),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
