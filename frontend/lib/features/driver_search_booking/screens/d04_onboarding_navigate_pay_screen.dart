import 'package:flutter/material.dart';

import 'd05_driver_login_screen.dart';

/// ParkPin onboarding 3 of 3.
/// Illustration is sample content, not a live parking reservation.
class D04OnboardingNavigatePayScreen extends StatelessWidget {
  const D04OnboardingNavigatePayScreen({super.key});

  static const Color navy = Color(0xFF173F78);
  static const Color orange = Color(0xFFFFA51F);
  static const Color ink = Color(0xFF152B48);
  static const Color muted = Color(0xFF71839B);
  static const Color green = Color(0xFF16A579);
  static const Color canvas = Color(0xFFF0F9F5);

  void _skip(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const D05DriverLoginScreen()),
      (route) => false,
    );
  }

  void _next(BuildContext context) {
    _skip(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, size) {
            final compact = size.maxHeight < 740;
            return Padding(
              padding: const EdgeInsets.fromLTRB(23, 9, 23, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 37,
                        width: 37,
                        decoration: BoxDecoration(
                          color: navy,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_parking_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        'ParkPin',
                        style: TextStyle(
                          color: navy,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _skip(context),
                        style: TextButton.styleFrom(
                          foregroundColor: muted,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (int i = 0; i < 3; i++) ...[
                        Expanded(
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: i == 2
                                  ? orange
                                  : const Color(0xFFD8E2ED),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        if (i != 2) const SizedBox(width: 7),
                      ],
                      const SizedBox(width: 13),
                      const Text(
                        '03 / 03',
                        style: TextStyle(
                          color: muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          SizedBox(height: compact ? 17 : 27),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCF5E9),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Text(
                              'NAVIGATE WITH EASE',
                              style: TextStyle(
                                color: green,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your parking trip.\nMade effortless.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              letterSpacing: -1.2,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 11),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Follow the route to your chosen bay and enjoy a straightforward checkout.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: muted,
                                fontSize: 13.5,
                                height: 1.48,
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 18 : 24),
                          const SizedBox(
                            height: 294,
                            child: _RouteArtwork(),
                          ),
                          const SizedBox(height: 14),
                          const _RouteFeature(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _next(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: ink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded, size: 21),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Your journey starts here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


class _RouteArtwork extends StatelessWidget {
  const _RouteArtwork();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 4,
          child: Container(
            width: 263,
            height: 263,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDDF4E8)),
          ),
        ),
        Positioned(
          top: 15,
          left: 17,
          right: 17,
          bottom: 34,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFFEDF4F5)),
              child: Stack(
                children: [
                  const Positioned(top: 15, left: 13, child: _MapBlock(80, 52)),
                  const Positioned(top: 17, right: 13, child: _MapBlock(80, 52)),
                  const Positioned(bottom: 15, left: 13, child: _MapBlock(78, 48)),
                  const Positioned(bottom: 15, right: 13, child: _MapBlock(82, 52)),
                  const Positioned(left: 106, top: 0, bottom: 0, child: ColoredBox(color: Colors.white, child: SizedBox(width: 36))),
                  const Positioned(left: 0, right: 0, top: 83, child: ColoredBox(color: Colors.white, child: SizedBox(height: 35))),
                  const Positioned(left: 123, top: 30, child: _DottedRoute()),
                  Positioned(
                    left: 95,
                    top: 79,
                    child: Container(
                      width: 58,
                      height: 45,
                      decoration: BoxDecoration(
                        color: D04OnboardingNavigatePayScreen.navy,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 23),
                    ),
                  ),
                  const Positioned(
                    right: 36,
                    top: 25,
                    child: Icon(Icons.location_on_rounded, color: D04OnboardingNavigatePayScreen.orange, size: 40),
                  ),
                  Positioned(
                    right: 33,
                    bottom: 30,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD7F5E7)),
                      child: const Icon(Icons.check_rounded, color: D04OnboardingNavigatePayScreen.green, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 1,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 15, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Color(0x24173F78), blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFFE4F0FF),
                  child: Icon(Icons.navigation_rounded, color: D04OnboardingNavigatePayScreen.navy, size: 20),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your route', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: D04OnboardingNavigatePayScreen.ink)),
                    SizedBox(height: 2),
                    Text('Parking made simple', style: TextStyle(fontSize: 9.5, color: D04OnboardingNavigatePayScreen.muted)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 1,
          bottom: 23,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
            decoration: BoxDecoration(
              color: D04OnboardingNavigatePayScreen.navy,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x2B173F78), blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.credit_card_rounded, size: 19, color: D04OnboardingNavigatePayScreen.orange),
                SizedBox(width: 6),
                Text('Easy checkout', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapBlock extends StatelessWidget {
  const _MapBlock(this.width, this.height);
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: const Color(0xFFDCE8E4), borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _DottedRoute extends StatelessWidget {
  const _DottedRoute();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Container(
            width: 4,
            height: 7,
            decoration: BoxDecoration(
              color: D04OnboardingNavigatePayScreen.green,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteFeature extends StatelessWidget {
  const _RouteFeature();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.route_rounded, size: 17, color: D04OnboardingNavigatePayScreen.green),
        SizedBox(width: 7),
        Text('Navigate easily · Pay simply', style: TextStyle(fontSize: 12, color: D04OnboardingNavigatePayScreen.navy, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
