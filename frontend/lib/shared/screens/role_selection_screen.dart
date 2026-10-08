import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/core/routes/app_routes.dart';

import 'package:parkpin/features/driver_search_booking/screens/d02_onboarding_live_bays_screen.dart';

/// Start screen – choose Driver, Car-park Operator or Traffic Authority.
/// Figma frame: "Role Selection"
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            // ============================================================
            // TOP BLUE SECTION
            // ============================================================
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                24,
                top + 48,
                24,
                48,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary,
                    Color(0xFF2B5596),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ParkPin icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Welcome to ParkPin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Choose how you\'ll use the app',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // ============================================================
            // ROLE SELECTION SECTION
            // ============================================================
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    22,
                    16,
                    16,
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // ==================================================
                      // DRIVER
                      // ==================================================
                      _RoleCard(
                        icon: Icons.directions_car_outlined,
                        iconBg: const Color(0xFFE6EDF8),
                        iconColor: AppColors.primary,
                        title: 'Driver',
                        subtitle: 'Find, reserve & pay for parking',

                        // Driver -> D02 Onboarding
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const D02OnboardingLiveBaysScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // CAR-PARK OPERATOR
                      // ==================================================
                      _RoleCard(
                        icon: Icons.local_parking,
                        iconBg: AppColors.warningBg,
                        iconColor: const Color(0xFFB7791F),
                        title: 'Car-park Operator',
                        subtitle: 'Manage bays, bookings & gate',
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.operatorEntry,
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // TRAFFIC AUTHORITY
                      // ==================================================
                      _RoleCard(
                        icon: Icons.verified_user_outlined,
                        iconBg: const Color(0xFFE3F4F1),
                        iconColor: const Color(0xFF0F766E),
                        title: 'Traffic Authority',
                        subtitle: 'Monitor occupancy & enforcement',
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.authorityEntry,
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'You can switch roles anytime from Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// ROLE CARD WIDGET
// ======================================================================

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  /// Function that runs when the role card is clicked.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Role icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              // Role title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}