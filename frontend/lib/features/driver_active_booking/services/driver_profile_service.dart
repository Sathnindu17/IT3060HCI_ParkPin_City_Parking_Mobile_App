import 'package:supabase_flutter/supabase_flutter.dart';

class DriverProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;

  const DriverProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
  });

  String get displayName {
    return fullName.trim().isEmpty ? 'Driver' : fullName.trim();
  }

  String get initials {
    final words = displayName
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'D';

    return words
        .take(2)
        .map((word) => word.substring(0, 1).toUpperCase())
        .join();
  }
}

class DriverPreferences {
  final bool locationEnabled;
  final bool bookingUpdates;

  const DriverPreferences({
    this.locationEnabled = false,
    this.bookingUpdates = true,
  });

  factory DriverPreferences.fromJson(Map<String, dynamic> json) {
    return DriverPreferences(
      locationEnabled: json['location_enabled'] as bool? ?? false,
      bookingUpdates: json['booking_updates'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location_enabled': locationEnabled,
      'booking_updates': bookingUpdates,
    };
  }
}

class DriverAccount {
  final DriverProfile profile;
  final DriverPreferences preferences;

  const DriverAccount({
    required this.profile,
    required this.preferences,
  });
}

class DriverProfileService {
  final SupabaseClient _client;

  DriverProfileService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  User get _user {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in to manage your profile.');
    }

    return user;
  }

  void _checkSession(String expectedUserId) {
    if (_client.auth.currentUser?.id != expectedUserId) {
      throw StateError('Your account changed. Please reopen your profile.');
    }
  }

  Future<DriverAccount> load() async {
    final user = _user;

    final profileJson = await _client
        .from('profiles')
        .select('id, full_name, phone, role')
        .eq('id', user.id)
        .single();

    if (profileJson['role'] != 'driver') {
      throw StateError('Please sign in with a driver account.');
    }

    // Create defaults only if this account has no preference record.
    // Existing preferences are preserved.
    await _client.from('driver_preferences').upsert(
      {'user_id': user.id},
      onConflict: 'user_id',
      ignoreDuplicates: true,
    );

    final preferencesJson = await _client
        .from('driver_preferences')
        .select('location_enabled, booking_updates')
        .eq('user_id', user.id)
        .single();

    _checkSession(user.id);

    return DriverAccount(
      profile: DriverProfile(
        id: profileJson['id'] as String,
        fullName: profileJson['full_name'] as String? ?? '',
        email: user.email ?? '',
        phone: profileJson['phone'] as String? ?? '',
        role: profileJson['role'] as String,
      ),
      preferences: DriverPreferences.fromJson(preferencesJson),
    );
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = _user;
    final cleanName = fullName.trim();
    final cleanPhone = phone.trim();

    if (cleanName.isEmpty || cleanName.length > 100) {
      throw StateError('Enter a name between 1 and 100 characters.');
    }

    if (cleanPhone.isNotEmpty &&
        !RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(cleanPhone)) {
      throw StateError('Enter a valid phone number, or leave it empty.');
    }

    final rows = await _client
        .from('profiles')
        .update({
          'full_name': cleanName,
          'phone': cleanPhone,
        })
        .eq('id', user.id)
        .select('id');

    _checkSession(user.id);

    if (rows.isEmpty) {
      throw StateError('Profile not found.');
    }
  }

  Future<void> savePreferences(DriverPreferences preferences) async {
    final user = _user;

    final rows = await _client
        .from('driver_preferences')
        .update(preferences.toJson())
        .eq('user_id', user.id)
        .select('user_id');

    _checkSession(user.id);

    if (rows.isEmpty) {
      throw StateError('Preferences not found. Refresh your profile.');
    }
  }

  Future<void> changePassword(String password) async {
    final userId = _user.id;

    if (password.length < 8) {
      throw StateError('Use a password with at least 8 characters.');
    }

    await _client.auth.updateUser(
      UserAttributes(password: password),
    );

    _checkSession(userId);
  }

  Future<void> signOut() async {
    await _client.auth.signOut(scope: SignOutScope.local);
  }
}