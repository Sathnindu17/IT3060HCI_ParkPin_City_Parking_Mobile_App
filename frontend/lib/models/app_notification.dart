/// Row from `notifications`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.bookingId,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // booking | reminder | payment | system
  final bool isRead;
  final DateTime createdAt; // local time
  final String? bookingId; // set when the notification is about one booking

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        title: (m['title'] as String?) ?? '',
        message: (m['message'] as String?) ?? '',
        type: (m['type'] as String?) ?? 'system',
        isRead: (m['is_read'] as bool?) ?? false,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        bookingId: m['booking_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': isRead,
      };
}
