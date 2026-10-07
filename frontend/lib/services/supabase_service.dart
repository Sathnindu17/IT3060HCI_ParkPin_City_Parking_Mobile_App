import 'package:supabase_flutter/supabase_flutter.dart';

/// Single place to reach the Supabase client.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Turns any error into a short message that is safe to show to users.
  static String friendlyError(Object e) {
    if (e is AppException) return e.message;
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login')) return 'Incorrect email or password.';
      return e.message;
    }
    if (e is PostgrestException) {
      if (e.code == '23505') return 'That item already exists or is already taken.';
      if (e.code == '23514') return 'A value is outside the allowed range.';
      if (e.code == '42501') return 'You do not have permission to do that.';
      return e.message;
    }
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'No internet connection. Check your network and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

/// Error with a message written for the user.
class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}
