
import 'package:flutter/material.dart';
import 'package:parkpin/core/routes/app_routes.dart';
import 'package:parkpin/core/theme/app_theme.dart';

class ParkPinApp extends StatelessWidget {
  const ParkPinApp({super.key});

  static const Color navyBlue = Color(0xFF173F78);
  static const Color orange = Color(0xFFFFA51F);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkPin - Smart Parking',
      debugShowCheckedModeBanner: false,

      // Existing ParkPin application theme
      theme: AppTheme.light,

      // Keep the original team navigation
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,

      // Display a friendly page for unknown routes
      onUnknownRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) {
            return Scaffold(
              backgroundColor: const Color(0xFFF4F6FA),

              appBar: AppBar(
                title: const Text('ParkPin'),
                centerTitle: true,
                backgroundColor: navyBlue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),

              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: navyBlue.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_off_outlined,
                            size: 54,
                            color: navyBlue,
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Page Not Available',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: navyBlue,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'The requested page could not be found. '
                          'Please return to ParkPin and try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Route: ${settings.name ?? "Unknown"}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamedAndRemoveUntil(
                                AppRoutes.splash,
                                (Route<dynamic> route) => false,
                              );
                            },
                            icon: const Icon(Icons.home_outlined),
                            label: const Text(
                              'Back to ParkPin',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                              foregroundColor: navyBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
