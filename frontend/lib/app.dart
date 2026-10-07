import 'package:flutter/material.dart';
import 'package:parkpin/core/routes/app_routes.dart';
import 'package:parkpin/core/theme/app_theme.dart';
import 'package:parkpin/shared/screens/coming_soon_screen.dart';

class ParkPinApp extends StatelessWidget {
  const ParkPinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkPin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onUnknownRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => ComingSoonScreen(routeName: settings.name ?? ''),
      ),
    );
  }
}
