import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/driver_notifications_service.dart';
import '../widgets/parking_ui.dart';

export '../services/driver_notifications_service.dart'
    show ParkingNotification, ParkingNotificationType;

class NotificationsScreen extends StatefulWidget {
  final bool preview;
  final ValueChanged<int>? onNavigate;

  const NotificationsScreen({
    super.key,
    this.preview = true,
    this.onNavigate,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<ParkingNotification> _samples = [];
  DriverNotificationsService? _service;
  Stream<List<ParkingNotification>>? _stream;
  StreamSubscription<AuthState>? _authSubscription;

  bool _busy = false;
  String? _sessionError;
  String? _driverId;

  @override
  void initState() {
    super.initState();

    if (widget.preview) {
      _samples = ParkingNotification.samples();
      return;
    }

    _service = DriverNotificationsService();
    _connect();

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final userId = event.session?.user.id;

      if (!mounted || userId == _driverId) return;

      setState(_connect);
    });
  }

  void _connect() {
    _driverId = Supabase.instance.client.auth.currentUser?.id;
    _sessionError = null;

    if (_driverId == null) {
      _stream = null;
      _sessionError = 'Please sign in to view your notifications.';
      return;
    }

    try {
      _stream = _service!.watch();
    } catch (error) {
      _stream = null;
      _sessionError = _errorMessage(error);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  String _errorMessage(Object error) {
    if (error is PostgrestException) return error.message;
    if (error is AuthException) return error.message;
    if (error is StateError) return error.message.toString();

    return 'Could not complete this action. Please try again.';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _reload() {
    if (widget.preview) return;

    setState(_connect);
  }

  Future<bool> _perform(Future<void> Function() action) async {
    if (_busy) return false;

    setState(() => _busy = true);

    try {
      await action();

      if (!mounted) return false;

      if (!widget.preview) _reload();

      return true;
    } catch (error) {
      _showMessage(_errorMessage(error));
      return false;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _markAllRead() async {
    final success = await _perform(() async {
      if (widget.preview) {
        setState(() {
          _samples =
              _samples.map((item) => item.copyWith(isRead: true)).toList();
        });
      } else {
        await _service!.markAllRead();
      }
    });

    if (success) _showMessage('Notifications marked as read.');
  }

  Future<void> _openNotification(ParkingNotification notification) async {
    if (_busy) return;

    if (!notification.isRead) {
      final success = await _perform(() async {
        if (widget.preview) {
          setState(() {
            _samples = _samples.map((item) {
              return item.id == notification.id
                  ? item.copyWith(isRead: true)
                  : item;
            }).toList();
          });
        } else {
          await _service!.markRead(notification.id);
        }
      });

      if (!success) return;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE4EF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _typeIcon(notification.type, size: 58),
                const SizedBox(height: 20),
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: ParkingStyle.navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  notification.details,
                  style: const TextStyle(
                    color: ParkingStyle.text,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Received: ${notification.createdAt.toLocal().toString().split('.').first}',
                  style: const TextStyle(
                    color: ParkingStyle.muted,
                    fontSize: 12,
                  ),
                ),
                if (widget.preview) const ParkingPreviewLabel(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ParkingStyle.orange,
                      foregroundColor: ParkingStyle.navy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteNotification(
    ParkingNotification notification,
  ) async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete notification?'),
          content: const Text(
            'This removes this message from your notifications. '
            'Your booking and payment records remain saved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final success = await _perform(() async {
      if (widget.preview) {
        setState(() {
          _samples.removeWhere((item) => item.id == notification.id);
        });
      } else {
        await _service!.deleteNotification(notification.id);
      }
    });

    if (success) _showMessage('Notification deleted.');
  }

  String _relativeTime(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';

    return '${difference.inDays}d';
  }

  Widget _typeIcon(
    ParkingNotificationType type, {
    double size = 46,
  }) {
    final icon = switch (type) {
      ParkingNotificationType.reminder =>
        Icons.notifications_active_outlined,
      ParkingNotificationType.booking => Icons.calendar_month_outlined,
      ParkingNotificationType.offer => Icons.local_offer_outlined,
      ParkingNotificationType.payment => Icons.receipt_long_outlined,
      ParkingNotificationType.system => Icons.info_outline_rounded,
    };

    final background = switch (type) {
      ParkingNotificationType.reminder => const Color(0xFFFFEBC8),
      ParkingNotificationType.offer => const Color(0xFFE5F3EC),
      _ => const Color(0xFFE8EFFA),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        icon,
        color: ParkingStyle.navy,
        size: size * 0.52,
      ),
    );
  }

  Widget _summaryCard(int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ParkingStyle.navy, Color(0xFF31598E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(24),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: ParkingStyle.orange,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stay up to date',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  unreadCount == 0
                      ? 'You are all caught up.'
                      : '$unreadCount unread notifications',
                  style: TextStyle(
                    color: Colors.white.withAlpha(205),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(ParkingNotification notification) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ParkingCard(
        padding: EdgeInsets.zero,
        color:
            notification.isRead ? Colors.white : const Color(0xFFF9FBFF),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: _busy ? null : () => _openNotification(notification),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _typeIcon(notification.type),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            color: ParkingStyle.text,
                            fontSize: 15,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.message,
                          style: const TextStyle(
                            color: ParkingStyle.muted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (!notification.isRead) ...[
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: ParkingStyle.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              notification.isRead ? 'Read' : 'Unread',
                              style: const TextStyle(
                                color: ParkingStyle.muted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _relativeTime(notification.createdAt),
                              style: const TextStyle(
                                color: ParkingStyle.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete notification',
                    onPressed:
                        _busy ? null : () => _deleteNotification(notification),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: ParkingStyle.muted,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(List<ParkingNotification> notifications) {
    final unreadCount = notifications.where((item) => !item.isRead).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _summaryCard(unreadCount),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent updates',
                style: TextStyle(
                  color: ParkingStyle.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed:
                  _busy || unreadCount == 0 ? null : _markAllRead,
              child: const Text('Mark all read'),
            ),
          ],
        ),
        if (_busy) ...[
          const LinearProgressIndicator(color: ParkingStyle.orange),
          const SizedBox(height: 12),
        ],
        if (notifications.isEmpty)
          const ParkingCard(
            child: Column(
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 48,
                  color: ParkingStyle.muted,
                ),
                SizedBox(height: 14),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    color: ParkingStyle.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your parking updates will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ParkingStyle.muted),
                ),
              ],
            ),
          )
        else
          ...notifications.map(_notificationCard),
        if (widget.preview) const ParkingPreviewLabel(),
      ],
    );
  }

  Widget _errorPanel(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ParkingCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: ParkingStyle.muted,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _reload,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(int index) {
    final callback = widget.onNavigate;

    if (callback != null) {
      callback(index);
      return;
    }

    _showMessage('This navigation will be connected during app integration.');
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (widget.preview) {
      body = _content(_samples);
    } else if (_sessionError != null) {
      body = _errorPanel(_sessionError!);
    } else {
      body = StreamBuilder<List<ParkingNotification>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorPanel(_errorMessage(snapshot.error!));
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: ParkingStyle.orange,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: _content(snapshot.data!),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: ParkingStyle.background,
      appBar: AppBar(
        backgroundColor: ParkingStyle.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 72,
        title: const Text('Notifications'),
        actions: [
          if (!widget.preview)
            IconButton(
              tooltip: 'Refresh',
              onPressed: _busy ? null : _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _navigate,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: ParkingStyle.navy,
        unselectedItemColor: ParkingStyle.muted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
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