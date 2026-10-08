import 'package:flutter/material.dart';
import 'package:parkpin/features/driver_search_booking/screens/d05_driver_login_screen.dart';

class D04OnboardingNavigatePayScreen extends StatelessWidget {
  const D04OnboardingNavigatePayScreen({super.key});

  static const Color backgroundColor = Color(0xFFEAF8EF);
  static const Color orange = Color(0xFFFFA51F);
  static const Color blue = Color(0xFF285E98);
  static const Color green = Color(0xFF1BB874);

  // ============================================================
  // NAVIGATE TO D05 DRIVER LOGIN
  // ============================================================
  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const D05DriverLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              // ==================================================
              // SKIP BUTTON
              // ==================================================
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _goToLogin(context);
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ==================================================
              // ILLUSTRATION
              // ==================================================
              const _NavigationIllustration(),

              const SizedBox(height: 34),

              // ==================================================
              // TITLE
              // ==================================================
              const Text(
                'Navigate & pay cashless',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C2533),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // DESCRIPTION
              // ==================================================
              const Text(
                'Turn-by-turn to your bay, then pay in-app. '
                'No cash, no tickets.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.black45,
                ),
              ),

              const Spacer(),

              // ==================================================
              // PAGE INDICATORS
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _indicator(false),
                  _indicator(false),
                  _indicator(true),
                ],
              ),

              const SizedBox(height: 24),

              // ==================================================
              // GET STARTED BUTTON
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _goToLogin(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Get started',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAGE INDICATOR
  // ============================================================
  static Widget _indicator(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? orange : const Color(0xFFC8D8CF),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// ============================================================
// NAVIGATION ILLUSTRATION
// ============================================================
class _NavigationIllustration extends StatelessWidget {
  const _NavigationIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 135,
      height: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          // Horizontal road
          Positioned(
            left: 8,
            right: 8,
            top: 18,
            child: Container(
              height: 5,
              color: const Color(0xFFDDE7F1),
            ),
          ),

          // Vertical road
          Positioned(
            left: 35,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              color: const Color(0xFFDDE7F1),
            ),
          ),

          // Location pin
          const Positioned(
            right: 22,
            top: 8,
            child: Icon(
              Icons.location_on,
              color: D04OnboardingNavigatePayScreen.orange,
              size: 32,
            ),
          ),

          // Green location point
          Positioned(
            left: 25,
            bottom: 15,
            child: Container(
              width: 13,
              height: 13,
              decoration: const BoxDecoration(
                color: D04OnboardingNavigatePayScreen.green,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Blue road
          Positioned(
            left: 10,
            bottom: 2,
            child: Container(
              width: 55,
              height: 9,
              decoration: BoxDecoration(
                color: D04OnboardingNavigatePayScreen.blue,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Grey road
          Positioned(
            right: 7,
            bottom: 2,
            child: Container(
              width: 36,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8EE),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}