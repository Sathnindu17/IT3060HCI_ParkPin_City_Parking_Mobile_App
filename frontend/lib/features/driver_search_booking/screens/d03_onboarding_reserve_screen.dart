import 'package:flutter/material.dart';

import 'd04_onboarding_navigate_pay_screen.dart';

class D03OnboardingReserveScreen extends StatelessWidget {
  const D03OnboardingReserveScreen({super.key});

  static const Color backgroundColor = Color(0xFFFFF6E8);
  static const Color orange = Color(0xFFFFA51F);
  static const Color blue = Color(0xFF285E98);
  static const Color green = Color(0xFF19B879);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Later: navigate to D05 Login
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

              const _ReservationIllustration(),

              const SizedBox(height: 34),

              const Text(
                'Reserve before you arrive',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C2533),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Lock a guaranteed bay in advance so it\'s waiting when you get there.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.black45,
                ),
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _indicator(false),
                  _indicator(true),
                  _indicator(false),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const D04OnboardingNavigatePayScreen(),
                      ),
                    );
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
                    'Next',
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

  static Widget _indicator(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? orange : const Color(0xFFD4D4D4),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _ReservationIllustration extends StatelessWidget {
  const _ReservationIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 105,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFC568),
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 20,
                  decoration: const BoxDecoration(
                    color: D03OnboardingReserveScreen.orange,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(9),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: D03OnboardingReserveScreen.green,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: D03OnboardingReserveScreen.green,
                          size: 20,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCE3EA),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            width: 25,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7EBEF),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 4,
            top: 3,
            child: Container(
              width: 25,
              height: 25,
              decoration: const BoxDecoration(
                color: D03OnboardingReserveScreen.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}