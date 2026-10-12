import 'package:flutter/widgets.dart';

import 'screens/driver_integrated_screen.dart';

class DriverActiveRoutes {
  DriverActiveRoutes._();

  static const String dashboard = '/driver/account';
  static const String bookings = '/driver/bookings';
  static const String receipts = '/driver/receipts';
  static const String profile = '/driver/profile';

  static Map<String, WidgetBuilder> get routes => {
        dashboard: (_) => const DriverIntegratedScreen(
              initialIndex: 0,
            ),
        bookings: (_) => const DriverIntegratedScreen(
              initialIndex: 1,
            ),
        receipts: (_) => const DriverIntegratedScreen(
              initialIndex: 2,
            ),
        profile: (_) => const DriverIntegratedScreen(
              initialIndex: 3,
            ),
      };
}