import 'package:parkpin/core/constants/db_tables.dart';
import 'package:parkpin/models/app_user.dart';
import 'package:parkpin/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sign in / sign out and the signed-in user's profile (shared by all roles).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _db => SupabaseService.client;

  User? get currentUser => _db.auth.currentUser;
  String? get currentEmail => _db.auth.currentUser?.email;

  Future<AppUser> signIn(String email, String password) async {
    final res = await _db.auth.signInWithPassword(email: email.trim(), password: password);
    final user = res.user;
    if (user == null) throw const AppException('Login failed. Please try again.');
    return getProfile(user.id);
  }

  Future<AppUser> getProfile(String userId) async {
    final row = await _db.from(DbTables.profiles).select().eq('id', userId).single();
    return AppUser.fromMap(row);
  }

  /// Profile of the user that is already signed in (session saved on the phone).
  Future<AppUser?> currentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return getProfile(user.id);
  }

  Future<void> signOut() => _db.auth.signOut();
}
