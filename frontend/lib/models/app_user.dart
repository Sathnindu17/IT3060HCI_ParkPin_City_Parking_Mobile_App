/// Row from `profiles` (one per signed-in user).
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
    this.facilityId,
    this.createdAt,
  });

  static const String roleDriver = 'driver';
  static const String roleOperator = 'operator';
  static const String roleAuthority = 'authority';

  final String id;
  final String fullName;
  final String? phone;
  final String role; // driver | operator | authority
  final String? facilityId; // operators only
  final DateTime? createdAt;

  bool get isDriver => role == roleDriver;
  bool get isOperator => role == roleOperator;
  bool get isAuthority => role == roleAuthority;

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'User' : parts.first;
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        fullName: (m['full_name'] as String?) ?? '',
        phone: m['phone'] as String?,
        role: (m['role'] as String?) ?? roleDriver,
        facilityId: m['facility_id'] as String?,
        createdAt: m['created_at'] == null ? null : DateTime.parse(m['created_at'] as String).toLocal(),
      );

  /// Only the columns a user is allowed to change (see RLS 0003).
  Map<String, dynamic> toMap() => {'full_name': fullName, 'phone': phone};

  AppUser copyWith({String? fullName, String? phone}) => AppUser(
        id: id,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        role: role,
        facilityId: facilityId,
        createdAt: createdAt,
      );
}
