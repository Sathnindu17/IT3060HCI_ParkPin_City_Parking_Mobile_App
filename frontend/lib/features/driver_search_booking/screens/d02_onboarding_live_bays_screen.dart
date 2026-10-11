import 'package:flutter/material.dart';

import 'd03_onboarding_reserve_screen.dart';
import 'd05_driver_login_screen.dart';

/// ParkPin onboarding 1 of 3.
/// Illustration is sample content, not a live parking reservation.
class D02OnboardingLiveBaysScreen extends StatelessWidget {
  const D02OnboardingLiveBaysScreen({super.key});

  static const Color navy = Color(0xFF173F78);
  static const Color orange = Color(0xFFFFA51F);
  static const Color ink = Color(0xFF152B48);
  static const Color muted = Color(0xFF71839B);
  static const Color green = Color(0xFF16A579);
  static const Color canvas = Color(0xFFF3F8FF);

  void _skip(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const D05DriverLoginScreen()),
      (route) => false,
    );
  }

  void _next(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const D03OnboardingReserveScreen()),
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
                              color: i == 0
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
                        '01 / 03',
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
                              color: const Color(0xFFE4F1FF),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Text(
                              'DISCOVER PARKING',
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
                            'Find parking.\nSkip the searching.',
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
                              'Check nearby bays at a glance and choose a space with confidence.',
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
                            child: _AvailabilityArtwork(),
                          ),
                          const SizedBox(height: 14),
                          const _AvailabilityFeature(),
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
                    'Explore smarter parking',
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


class _AvailabilityArtwork extends StatelessWidget {
  const _AvailabilityArtwork();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 4,
          child: Container(
            width: 265,
            height: 265,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE1EEFF),
            ),
          ),
        ),
        Positioned(
          left: 8,
          right: 8,
          top: 13,
          bottom: 29,
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1E355D92),
                  blurRadius: 27,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 37,
                      height: 37,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FE),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.local_parking_rounded,
                        color: D02OnboardingLiveBaysScreen.navy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'City Centre Parking',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: D02OnboardingLiveBaysScreen.ink,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Ground floor · Sample availability',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: D02OnboardingLiveBaysScreen.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F8F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '● LIVE',
                        style: TextStyle(
                          color: D02OnboardingLiveBaysScreen.green,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: _Bay('A-01', false)),
                    SizedBox(width: 7),
                    Expanded(child: _Bay('A-02', true)),
                    SizedBox(width: 7),
                    Expanded(child: _Bay('A-03', true)),
                    SizedBox(width: 7),
                    Expanded(child: _Bay('A-04', false)),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(child: _Bay('B-01', true)),
                    SizedBox(width: 7),
                    Expanded(child: _Bay('B-02', false)),
                    SizedBox(width: 7),
                    Expanded(child: _Bay('B-03', true)),
                    SizedBox(width: 7),
                    Expanded(child: _Bay('B-04', true)),
                  ],
                ),
                const Spacer(),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, size: 8, color: Color(0xFF16A579)),
                    SizedBox(width: 5),
                    Text('Available', style: TextStyle(fontSize: 10, color: Color(0xFF7A8CA2))),
                    SizedBox(width: 15),
                    Icon(Icons.circle, size: 8, color: Color(0xFF90A6C8)),
                    SizedBox(width: 5),
                    Text('Occupied', style: TextStyle(fontSize: 10, color: Color(0xFF7A8CA2))),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 36,
          right: 36,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: D02OnboardingLiveBaysScreen.navy,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Color(0x29173F78), blurRadius: 13, offset: Offset(0, 6)),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF6FEBBE), size: 21),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '5 spaces ready for you',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white70),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bay extends StatelessWidget {
  const _Bay(this.label, this.available);
  final String label;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: available ? const Color(0xFFE9FAF3) : const Color(0xFFEAF0F8),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: available ? const Color(0xFF78D8B2) : const Color(0xFFD5E0EF),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            available ? Icons.check_circle_outline_rounded : Icons.directions_car_rounded,
            size: 19,
            color: available ? D02OnboardingLiveBaysScreen.green : const Color(0xFF8099BD),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: available ? const Color(0xFF168760) : const Color(0xFF7086A4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityFeature extends StatelessWidget {
  const _AvailabilityFeature();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.radar_rounded, size: 17, color: D02OnboardingLiveBaysScreen.green),
        SizedBox(width: 7),
        Text(
          'Less searching. More moving.',
          style: TextStyle(
            color: D02OnboardingLiveBaysScreen.navy,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

