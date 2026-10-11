import 'package:flutter/material.dart';

import 'd04_onboarding_navigate_pay_screen.dart';
import 'd05_driver_login_screen.dart';

/// ParkPin onboarding 2 of 3.
/// Illustration is sample content, not a live parking reservation.
class D03OnboardingReserveScreen extends StatelessWidget {
  const D03OnboardingReserveScreen({super.key});

  static const Color navy = Color(0xFF173F78);
  static const Color orange = Color(0xFFFFA51F);
  static const Color ink = Color(0xFF152B48);
  static const Color muted = Color(0xFF71839B);
  static const Color green = Color(0xFF16A579);
  static const Color canvas = Color(0xFFFFF8EE);

  void _skip(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const D05DriverLoginScreen()),
      (route) => false,
    );
  }

  void _next(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const D04OnboardingNavigatePayScreen()),
    );
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
                              color: i == 1
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
                        '02 / 03',
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
                              color: const Color(0xFFFFEAD0),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Text(
                              'RESERVE YOUR SPACE',
                              style: TextStyle(
                                color: navy,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your bay.\nReady when you are.',
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
                              'Pick your arrival time and reserve a parking bay before you set off.',
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
                            child: _ReservationArtwork(),
                          ),
                          const SizedBox(height: 14),
                          const _ReservationFeature(),
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
                            'Next',
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
                    'Your space, your schedule',
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


class _ReservationArtwork extends StatelessWidget {
  const _ReservationArtwork();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 2,
          child: Container(
            height: 272,
            width: 272,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEBCB),
            ),
          ),
        ),
        Positioned(
          top: 15,
          left: 16,
          right: 16,
          bottom: 31,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x24A37B43), blurRadius: 25, offset: Offset(0, 13)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: const BoxDecoration(
                    color: D03OnboardingReserveScreen.navy,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.confirmation_number_rounded, color: D03OnboardingReserveScreen.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'YOUR PARKING PASS',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                        ),
                      ),
                      Icon(Icons.more_horiz_rounded, color: Colors.white70),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 19, color: D03OnboardingReserveScreen.orange),
                            SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'City Centre Parking',
                                style: TextStyle(color: D03OnboardingReserveScreen.ink, fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Expanded(child: _PassInfo(Icons.local_parking_rounded, 'YOUR BAY', 'A-02')),
                            SizedBox(height: 46, child: VerticalDivider(color: Color(0xFFE7ECF3))),
                            Expanded(child: _PassInfo(Icons.access_time_rounded, 'ARRIVAL', '10:30 AM')),
                          ],
                        ),
                        const Spacer(),
                        const Divider(height: 1, color: Color(0xFFE9EDF3)),
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 18, color: D03OnboardingReserveScreen.green),
                            SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                'Ready before you arrive',
                                style: TextStyle(fontSize: 11, color: Color(0xFF60748F), fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 3,
          left: 49,
          right: 49,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE7FAF0),
              border: Border.all(color: const Color(0xFFA7E8C9)),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x19986A31), blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: D03OnboardingReserveScreen.green, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Bay reservation ready!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF16845D), fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PassInfo extends StatelessWidget {
  const _PassInfo(this.icon, this.title, this.value);
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: D03OnboardingReserveScreen.navy, size: 23),
        const SizedBox(height: 3),
        Text(title, style: const TextStyle(color: Color(0xFF91A0B2), fontSize: 9, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: D03OnboardingReserveScreen.ink, fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ReservationFeature extends StatelessWidget {
  const _ReservationFeature();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.event_available_rounded, size: 17, color: D03OnboardingReserveScreen.green),
        SizedBox(width: 7),
        Text(
          'Plan ahead. Arrive relaxed.',
          style: TextStyle(color: D03OnboardingReserveScreen.navy, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ],
    );
  }
}

