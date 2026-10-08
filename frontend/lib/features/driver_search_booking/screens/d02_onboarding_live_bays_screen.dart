import 'package:flutter/material.dart';

import 'd03_onboarding_reserve_screen.dart';

class D02OnboardingLiveBaysScreen extends StatelessWidget {
  const D02OnboardingLiveBaysScreen({super.key});

  static const Color backgroundColor = Color(0xFFEAF3FF);
  static const Color primaryBlue = Color(0xFF285E98);
  static const Color orange = Color(0xFFFFA51F);
  static const Color green = Color(0xFF14B86E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              // Skip
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

              // Parking bays illustration
              const _LiveBaysIllustration(),

              const SizedBox(height: 34),

              const Text(
                'See free bays in real time',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C2533),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'No more circling the block. Check live availability before you leave home.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.black45,
                ),
              ),

              const Spacer(),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _indicator(true),
                  _indicator(false),
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
                            const D03OnboardingReserveScreen(),
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
        color: active ? orange : const Color(0xFFC6D4E5),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _LiveBaysIllustration extends StatelessWidget {
  const _LiveBaysIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 125,
              height: 72,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final isFree = index == 3;

                  return Container(
                    decoration: BoxDecoration(
                      color: isFree
                          ? Colors.white
                          : index % 3 == 0
                              ? const Color(0xFF285E98)
                              : const Color(0xFF86A8D1),
                      borderRadius: BorderRadius.circular(3),
                      border: isFree
                          ? Border.all(
                              color: D02OnboardingLiveBaysScreen.green,
                              width: 2,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),

          Positioned(
            right: 9,
            top: 2,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: D02OnboardingLiveBaysScreen.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}