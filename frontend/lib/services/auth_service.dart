
import 'package:parkpin/core/constants/db_tables.dart';
import 'package:parkpin/models/app_user.dart';
import 'package:parkpin/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared authentication service for ParkPin.
///
/// Used by:
/// - Driver
/// - Car Park Operator
/// - Traffic Authority
///
/// Uses the existing Supabase client and public.profiles table.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _db => SupabaseService.client;

  // ============================================================
  // CURRENT AUTHENTICATED USER
  // ============================================================

  User? get currentUser => _db.auth.currentUser;

  String? get currentEmail => currentUser?.email;

  bool get isLoggedIn => currentUser != null;

  // ============================================================
  // D06 - DRIVER SIGNUP
  // ============================================================

  /// Registers a new driver using Supabase Authentication.
  ///
  /// The existing database trigger:
  /// on_auth_user_created
  ///
  /// automatically creates the matching public.profiles row.
  ///
  /// The profiles.role column defaults to 'driver'.
  Future<AuthResponse> signUpDriver({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String vehicleNumber,
  }) async {
    final name = fullName.trim();
    final mobile = phone.trim();
    final emailAddress = email.trim().toLowerCase();
    final vehicle = vehicleNumber.trim().toUpperCase();

    if (name.isEmpty) {
      throw const AppException(
        'Please enter your full name.',
      );
    }

    if (mobile.isEmpty) {
      throw const AppException(
        'Please enter your mobile number.',
      );
    }

    if (emailAddress.isEmpty) {
      throw const AppException(
        'Please enter your email address.',
      );
    }

    if (password.length < 6) {
      throw const AppException(
        'Password must contain at least 6 characters.',
      );
    }

    if (vehicle.isEmpty) {
      throw const AppException(
        'Please enter your vehicle number.',
      );
    }

    final response = await _db.auth.signUp(
      email: emailAddress,
      password: password,
      data: {
        'full_name': name,
        'phone': mobile,
        'vehicle_number': vehicle,
      },
    );

    if (response.user == null) {
      throw const AppException(
        'Account creation failed. Please try again.',
      );
    }

    return response;
  }

  // ============================================================
  // D05 - SHARED SIGN IN
  // ============================================================

  /// Signs in any valid ParkPin user and loads their profile.
  Future<AppUser> signIn(
    String email,
    String password,
  ) async {
    final response = await _db.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw const AppException(
        'Login failed. Please try again.',
      );
    }

    try {
      return await getProfile(user.id);
    } catch (_) {
      // Avoid leaving an authenticated session without
      // a usable application profile.
      await _db.auth.signOut();
      rethrow;
    }
  }

  // ============================================================
  // D05 - DRIVER-ONLY SIGN IN
  // ============================================================

  /// Only users with profiles.role = 'driver' can
  /// successfully complete driver login.
  Future<AppUser> signInDriver(
    String email,
    String password,
  ) async {
    final profile = await signIn(
      email,
      password,
    );

    if (!profile.isDriver) {
      await signOut();

      throw const AppException(
        'This account is not registered as a driver.',
      );
    }

    return profile;
  }

  // ============================================================
  // GET USER PROFILE
  // ============================================================

  /// Retrieves the user's profile from public.profiles.
  Future<AppUser> getProfile(String userId) async {
    final row = await _db
        .from(DbTables.profiles)
        .select()
        .eq('id', userId)
        .single();

    return AppUser.fromMap(row);
  }

  // ============================================================
  // GET CURRENT USER PROFILE
  // ============================================================

  /// Returns null when no user is signed in.
  Future<AppUser?> currentProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    return getProfile(user.id);
  }

  // ============================================================
  // CHECK CURRENT DRIVER
  // ============================================================

  /// Useful for protecting the D10 Driver Home screen.
  Future<AppUser?> currentDriverProfile() async {
    final profile = await currentProfile();

    if (profile == null || !profile.isDriver) {
      return null;
    }

    return profile;
  }

  // ============================================================
  // D07 - FORGOT PASSWORD
  // ============================================================

  /// Sends a password recovery email.
  ///
  /// For an OTP-based recovery flow, the Supabase
  /// Reset Password email template must contain:
  ///
  /// {{ .Token }}
  Future<void> resetPassword(String email) async {
    final emailAddress = email.trim().toLowerCase();

    if (emailAddress.isEmpty) {
      throw const AppException(
        'Please enter your email address.',
      );
    }

    await _db.auth.resetPasswordForEmail(
      emailAddress,
    );
  }

  // ============================================================
  // D08 - VERIFY PASSWORD RECOVERY OTP
  // ============================================================

  /// Verifies the OTP issued by resetPasswordForEmail.
  ///
  /// On success, Supabase establishes a recovery session.
  Future<void> verifyRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    final code = otp.trim();

    if (code.isEmpty) {
      throw const AppException(
        'Please enter your verification code.',
      );
    }

    final response = await _db.auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: code,
      type: OtpType.recovery,
    );

    if (response.session == null) {
      throw const AppException(
        'Verification failed. Please request a new code.',
      );
    }
  }

  // ============================================================
  // D09 - UPDATE PASSWORD
  // ============================================================

  /// Updates the password for the authenticated user.
  ///
  /// The D09 screen should only be reached after
  /// successful D08 recovery OTP verification.
  Future<void> updatePassword(String newPassword) async {
    if (!isLoggedIn) {
      throw const AppException(
        'Verify your recovery code before changing the password.',
      );
    }

    if (newPassword.length < 6) {
      throw const AppException(
        'Password must contain at least 6 characters.',
      );
    }

    await _db.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }

  // ============================================================
  // AUTHENTICATION STATE CHANGES
  // ============================================================

  Stream<AuthState> get authStateChanges {
    return _db.auth.onAuthStateChange;
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    await _db.auth.signOut();
  }
}
