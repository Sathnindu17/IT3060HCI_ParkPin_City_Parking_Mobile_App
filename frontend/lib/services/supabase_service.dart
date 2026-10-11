import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase service for the ParkPin application.
///
/// Provides:
/// - Access to the initialized Supabase client
/// - Initialization status for the splash screen
/// - User-friendly error messages
class SupabaseService {
  SupabaseService._();

  // ============================================
  // SUPABASE CLIENT
  // ============================================

  /// Returns the initialized Supabase client.
  ///
  /// Supabase.initialize() must be called in main.dart
  /// before the ParkPin application starts.
  static SupabaseClient get client {
    return Supabase.instance.client;
  }

  // ============================================
  // SUPABASE INITIALIZATION STATUS
  // ============================================

  /// Returns true if Supabase has been initialized.
  ///
  /// This is used by the D01 Splash Screen.
  /// It does not test network connectivity.
  static bool get ready {
    try {
      final supabaseClient = Supabase.instance.client;
      return supabaseClient.auth.currentSession != null ||
          Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  // ============================================
  // ERROR HANDLING
  // ============================================

  /// Converts exceptions into user-friendly messages.
  static String friendlyError(Object error) {
    // Custom ParkPin errors
    if (error is AppException) {
      return error.message;
    }

    // Supabase authentication errors
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      if (message.contains('invalid login') ||
          message.contains('invalid credentials')) {
        return 'Incorrect email or password.';
      }

      if (message.contains('email not confirmed')) {
        return 'Please verify your email address.';
      }

      if (message.contains('user already registered')) {
        return 'This email address is already registered.';
      }

      return error.message;
    }

    // Supabase database errors
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505':
          return 'That item already exists or is already taken.';

        case '23514':
          return 'A value is outside the allowed range.';

        case '23503':
          return 'The related record could not be found.';

        case '42501':
          return 'You do not have permission to perform this action.';

        default:
          return error.message;
      }
    }

    // Network errors
    final message = error.toString();

    if (message.contains('SocketException') ||
        message.contains('Failed host lookup') ||
        message.contains('ClientException: Failed to fetch')) {
      return 'No internet connection. Check your network and try again.';
    }

    // Default error
    return 'Something went wrong. Please try again.';
  }
}

// ============================================
// CUSTOM APPLICATION EXCEPTION
// ============================================

/// Represents an error with a message suitable for display.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
