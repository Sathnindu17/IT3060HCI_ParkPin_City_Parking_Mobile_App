import 'package:flutter/widgets.dart';
import 'package:parkpin/features/authority/screens/login_screen.dart';
import 'package:parkpin/features/authority/screens/authority_dashboard.dart';

/// Member 3 – Traffic authority (A01–A08).
/// Registers the entry route and any screens that need direct deep-linking.
class AuthorityRoutes {
  AuthorityRoutes._();

  /// Authority entry route (must match AppRoutes.authorityEntry)
  static const String authorityEntry = '/authority/login';
  static const String authorityDashboard = '/authority/dashboard';

  static Map<String, WidgetBuilder> get routes => {
        authorityEntry: (_) => const LoginScreen(),
        authorityDashboard: (_) => const AuthorityDashboard(),
      };
}