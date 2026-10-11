
/// Represents a row in the public.profiles table.
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
  final String role;
  final String? facilityId;
  final DateTime? createdAt;

  bool get isDriver => role == roleDriver;
  bool get isOperator => role == roleOperator;
  bool get isAuthority => role == roleAuthority;

  String get firstName {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    return parts.isEmpty ? 'User' : parts.first;
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return (
      parts.first[0] + parts.last[0]
    ).toUpperCase();
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? '',
      phone: map['phone'] as String?,
      role: (map['role'] as String?) ?? roleDriver,
      facilityId: map['facility_id'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(
              map['created_at'] as String,
            ).toLocal(),
    );
  }

  /// Editable profile fields only.
  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'phone': phone,
    };
  }

  AppUser copyWith({
    String? fullName,
    String? phone,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role,
      facilityId: facilityId,
      createdAt: createdAt,
    );
  }
}
