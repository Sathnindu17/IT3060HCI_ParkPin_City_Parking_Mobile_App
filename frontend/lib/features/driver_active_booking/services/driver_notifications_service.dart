import 'package:supabase_flutter/supabase_flutter.dart';

enum ParkingNotificationType {
  reminder,
  booking,
  offer,
  payment,
  system,
}

class ParkingNotification {
  final String id;
  final String title;
  final String message;
  final String details;
  final DateTime createdAt;
  final ParkingNotificationType type;
  final bool isRead;
  final String? bookingId;

  const ParkingNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.details,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.bookingId,
  });

  factory ParkingNotification.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'system';

    final type = switch (typeName) {
      'reminder' => ParkingNotificationType.reminder,
      'booking' => ParkingNotificationType.booking,
      'payment' => ParkingNotificationType.payment,
      'offer' => ParkingNotificationType.offer,
      _ => ParkingNotificationType.system,
    };

    final message = json['message'] as String? ?? '';

    return ParkingNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Notification',
      message: message,
      details: message,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      type: type,
      isRead: json['is_read'] as bool? ?? false,
      bookingId: json['booking_id'] as String?,
    );
  }

  ParkingNotification copyWith({bool? isRead}) {
    return ParkingNotification(
      id: id,
      title: title,
      message: message,
      details: details,
      createdAt: createdAt,
      type: type,
      isRead: isRead ?? this.isRead,
      bookingId: bookingId,
    );
  }

  static List<ParkingNotification> samples() {
    final now = DateTime.now();

    return [
      ParkingNotification(
        id: 'demo-reminder',
        title: '15 minutes left',
        message: 'Tap to view your parking reminder',
        details:
            'This is a design sample. Scheduled parking reminders '
            'are not enabled by this preview.',
        createdAt: now,
        type: ParkingNotificationType.reminder,
      ),
      ParkingNotification(
        id: 'demo-booking',
        title: 'Parking extended',
        message: 'One Galle Face · Bay B3',
        details:
            'This sample shows how a parking extension message '
            'will appear in your notifications.',
        createdAt: now.subtract(const Duration(hours: 2)),
        type: ParkingNotificationType.booking,
      ),
      ParkingNotification(
        id: 'demo-offer',
        title: 'Off-peak offer',
        message: 'Sample promotional message',
        details:
            'This is a design sample and does not represent '
            'an available parking discount.',
        createdAt: now.subtract(const Duration(days: 1)),
        type: ParkingNotificationType.offer,
        isRead: true,
      ),
    ];
  }
}

class DriverNotificationsService {
  final SupabaseClient _client;

  DriverNotificationsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _driverId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in to view your notifications.');
    }

    return user.id;
  }

  Stream<List<ParkingNotification>> watch() {
    final driverId = _driverId;

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', driverId)
        .order('created_at', ascending: false)
        .map((rows) {
          if (_client.auth.currentUser?.id != driverId) {
            throw StateError(
              'Your account changed. Reopen notifications.',
            );
          }

          return rows.map(ParkingNotification.fromJson).toList();
        });
  }

  Future<void> markRead(String notificationId) async {
    final driverId = _driverId;

    final rows = await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', driverId)
        .select('id');

    if (rows.isEmpty) {
      throw StateError('Notification not found.');
    }
  }

  Future<void> markAllRead() async {
    final driverId = _driverId;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', driverId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    final driverId = _driverId;

    final rows = await _client
        .from('notifications')
        .delete()
        .eq('id', notificationId)
        .eq('user_id', driverId)
        .select('id');

    if (rows.isEmpty) {
      throw StateError('Notification not found.');
    }
  }
}