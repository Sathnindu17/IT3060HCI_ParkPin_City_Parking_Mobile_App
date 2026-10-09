import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/features/operator/services/operator_service.dart';
import 'package:parkpin/features/operator/widgets/operator_ui.dart';
import 'package:parkpin/models/app_notification.dart';
import 'package:parkpin/services/supabase_service.dart';

/// O09 – Notifications (Figma "Operator · O09 Notifications").
/// Live list; tap to mark read, swipe left to delete, "mark all read" in header.
class OperatorNotificationsScreen extends StatefulWidget {
  const OperatorNotificationsScreen({super.key});

  @override
  State<OperatorNotificationsScreen> createState() => _OperatorNotificationsScreenState();
}

class _OperatorNotificationsScreenState extends State<OperatorNotificationsScreen> {
  final _svc = OperatorService.instance;
  List<AppNotification>? _items;
  String? _error;
  StreamSubscription<List<AppNotification>>? _sub;
  final Set<String> _hidden = {}; // deleted, waiting for the Undo window to pass
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      await _svc.ensureLoaded();
      await _sub?.cancel();
      _sub = _svc.watchNotifications().listen(
        (list) => setState(() => _items = list),
        onError: (Object e) => setState(() => _error = SupabaseService.friendlyError(e)),
      );
    } catch (e) {
      if (mounted) setState(() => _error = SupabaseService.friendlyError(e));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _safe(Future<void> Function() action, [String? done]) async {
    try {
      await action();
      if (done != null && mounted) showOpSnack(context, done);
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
    }
  }

  /// Hides the item at once and only deletes it if the user does not tap Undo.
  void _delete(AppNotification n) {
    setState(() => _hidden.add(n.id));
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger
        .showSnackBar(SnackBar(
          content: const Text('Notification deleted'),
          backgroundColor: AppColors.textPrimary,
          action: SnackBarAction(label: 'Undo', textColor: AppColors.accent, onPressed: () {}),
        ))
        .closed
        .then((reason) async {
      if (reason == SnackBarClosedReason.action) {
        if (mounted) setState(() => _hidden.remove(n.id));
        return;
      }
      try {
        await _svc.deleteNotification(n.id);
      } catch (e) {
        if (mounted) {
          setState(() => _hidden.remove(n.id));
          showOpSnack(context, SupabaseService.friendlyError(e), error: true);
        }
      }
    });
  }

  /// "Today" / "Earlier" group with its own card.
  List<Widget> _group(String title, List<AppNotification> list) {
    if (list.isEmpty) return const [];
    return [
      SectionLabel(title),
      OpCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < list.length; i++)
              Dismissible(
                key: ValueKey(list[i].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppColors.dangerBg,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 18),
                  child: const Icon(Icons.delete_outline, color: AppColors.danger),
                ),
                onDismissed: (_) => _delete(list[i]),
                child: _NotificationRow(
                  n: list[i],
                  icon: _icon(list[i]),
                  last: i == list.length - 1,
                  onTap: list[i].isRead ? null : () => _safe(() => _svc.markRead(list[i].id)),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 14),
    ];
  }

  IconData _icon(AppNotification n) {
    final t = n.title.toLowerCase();
    if (t.contains('gate') || t.contains('scan')) return Icons.qr_code_scanner;
    if (t.contains('availability') || t.contains('full')) return Icons.warning_amber_rounded;
    return switch (n.type) {
      'booking' => Icons.event_outlined,
      'payment' => Icons.credit_card,
      'reminder' => Icons.alarm,
      _ => Icons.notifications_none,
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = _items?.where((n) => !_hidden.contains(n.id)).toList();
    final unread = items?.where((n) => !n.isRead).length ?? 0;
    final shown = (items ?? []).where((n) => !_unreadOnly || !n.isRead).toList();
    final today = shown.where((n) => isToday(n.createdAt)).toList();
    final earlier = shown.where((n) => !isToday(n.createdAt)).toList();
    return Scaffold(
      body: Column(
        children: [
          OperatorHeader(
            title: 'Notifications',
            subtitle: unread == 0 ? null : '$unread unread',
            trailing: unread == 0
                ? null
                : HeaderAction(
                    icon: Icons.done_all,
                    tooltip: 'Mark all as read',
                    onTap: () => _safe(_svc.markAllRead, 'All marked as read'),
                  ),
          ),
          Expanded(
            child: _error != null
                ? OpError(message: _error!, onRetry: _start)
                : items == null
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? const OpEmpty(
                            icon: Icons.notifications_off_outlined,
                            message: 'You\'re all caught up.\nNew bookings and gate scans show up here.',
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                            children: [
                              OpSegmented(
                                options: ['All', 'Unread ($unread)'],
                                selected: _unreadOnly ? 1 : 0,
                                onChanged: (i) => setState(() => _unreadOnly = i == 1),
                              ),
                              const SizedBox(height: 18),
                              if (shown.isEmpty)
                                const OpEmpty(icon: Icons.mark_email_read_outlined, message: 'No unread notifications.')
                              else ...[
                                ..._group('Today', today),
                                ..._group('Earlier', earlier),
                                const Text('Tap to mark as read · swipe left to delete',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                              ],
                            ],
                          ),
          ),
        ],
      ),
      bottomNavigationBar: const OperatorBottomNav(currentIndex: -1),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.n, required this.icon, required this.last, this.onTap});
  final AppNotification n;
  final IconData icon;
  final bool last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: n.isRead ? null : 'Unread',
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: n.isRead ? Colors.white : const Color(0xFFF1F5FC),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: last ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OpIconBadge(icon: icon, size: 42, background: n.isRead ? OpStyle.tileBg : Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title,
                          style: TextStyle(
                              fontSize: 15,
                              color: OpStyle.ink,
                              fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(n.message,
                          style: const TextStyle(fontSize: 13.5, height: 1.35, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(timeAgo(n.createdAt), style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    if (!n.isRead) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
