import 'package:flutter/widgets.dart';
import 'package:parkpin/features/authority/authority_routes.dart';
import 'package:parkpin/features/driver_active_booking/driver_active_routes.dart';
import 'package:parkpin/features/driver_search_booking/driver_search_routes.dart';
import 'package:parkpin/features/operator/operator_routes.dart';
import 'package:parkpin/shared/screens/role_selection_screen.dart';

/// App routes. Each member registers their own screens in their feature's
/// *_routes.dart file, so nobody has to edit this file (no merge conflicts).
class AppRoutes {
  AppRoutes._();

  // ── Shared ──
  static const String roleSelection = '/';

  // ── Entry route of each role (opened from Role Selection) ──
  static const String driverEntry = '/driver/login'; //      Member 1 – Wijesekara S
  static const String operatorEntry = '/operator/login'; //  Member 2 – Marasinghe M M W K
  static const String authorityEntry = '/authority/login'; // Member 3 – Ekanayaka E M K S

  static Map<String, WidgetBuilder> get routes => {
        roleSelection: (_) => const RoleSelectionScreen(),
        ...DriverSearchRoutes.routes, //  D01–D13
        ...DriverActiveRoutes.routes, //  D14–D22
        ...OperatorRoutes.routes, //      O01–O10
        ...AuthorityRoutes.routes, //     A01–A08
      };
}
