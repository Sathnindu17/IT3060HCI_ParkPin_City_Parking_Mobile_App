import 'package:flutter/widgets.dart';
import 'package:parkpin/core/routes/app_routes.dart';
import 'package:parkpin/features/operator/screens/o01_login_screen.dart';
import 'package:parkpin/features/operator/screens/o02_dashboard_screen.dart';
import 'package:parkpin/features/operator/screens/o03_availability_screen.dart';
import 'package:parkpin/features/operator/screens/o04_bookings_screen.dart';
import 'package:parkpin/features/operator/screens/o05_booking_detail_screen.dart';
import 'package:parkpin/features/operator/screens/o06_pricing_screen.dart';
import 'package:parkpin/features/operator/screens/o07_payments_screen.dart';
import 'package:parkpin/features/operator/screens/o08_gate_check_screen.dart';
import 'package:parkpin/features/operator/screens/o09_notifications_screen.dart';
import 'package:parkpin/features/operator/screens/o10_profile_screen.dart';

/// Member 2 – Car-park operator (O01–O10).
class OperatorRoutes {
  OperatorRoutes._();

  static const String login = AppRoutes.operatorEntry; //         O01
  static const String dashboard = '/operator'; //                  O02
  static const String availability = '/operator/availability'; //  O03
  static const String bookings = '/operator/bookings'; //          O04
  static const String bookingDetail = '/operator/booking'; //      O05 (argument: booking id)
  static const String pricing = '/operator/pricing'; //            O06
  static const String payments = '/operator/payments'; //          O07
  static const String gate = '/operator/gate'; //                  O08
  static const String notifications = '/operator/notifications'; // O09
  static const String profile = '/operator/profile'; //            O10

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const OperatorLoginScreen(),
        dashboard: (_) => const OperatorDashboardScreen(),
        availability: (_) => const OperatorAvailabilityScreen(),
        bookings: (_) => const OperatorBookingsScreen(),
        bookingDetail: (context) => OperatorBookingDetailScreen(
              bookingId: ModalRoute.of(context)!.settings.arguments! as String,
            ),
        pricing: (_) => const OperatorPricingScreen(),
        payments: (_) => const OperatorPaymentsScreen(),
        gate: (_) => const OperatorGateCheckScreen(),
        notifications: (_) => const OperatorNotificationsScreen(),
        profile: (_) => const OperatorProfileScreen(),
      };
}
