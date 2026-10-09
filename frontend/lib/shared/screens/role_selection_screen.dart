import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/core/routes/app_routes.dart';

/// Start screen – choose Driver, Car-park Operator or Traffic Authority
/// (Figma frame "Role Selection").
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const _ink = Color(0xFF14284B);
  static const _navyLight = Color(0xFF2E5A99);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, top + 40, 24, 54),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, _navyLight],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.location_on, color: AppColors.primary, size: 34),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Welcome to ParkPin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find, reserve and manage city-centre parking.\nChoose how you\'ll use the app.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Role cards ──
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'I am a…',
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: _ink),
                        ),
                      ),
                      _RoleCard(
                        icon: Icons.directions_car_filled_outlined,
                        iconBg: Color(0xFFE6EDF8),
                        iconColor: AppColors.primary,
                        title: 'Driver',
                        subtitle: 'Find, reserve & pay for parking',
                        route: AppRoutes.driverEntry,
                      ),
                      SizedBox(height: 14),
                      _RoleCard(
                        icon: Icons.local_parking_rounded,
                        iconBg: AppColors.warningBg,
                        iconColor: Color(0xFFB7791F),
                        title: 'Car-park Operator',
                        subtitle: 'Manage bays, bookings & gate',
                        route: AppRoutes.operatorEntry,
                      ),
                      SizedBox(height: 14),
                      _RoleCard(
                        icon: Icons.verified_user_outlined,
                        iconBg: Color(0xFFE3F4F1),
                        iconColor: Color(0xFF0F766E),
                        title: 'Traffic Authority',
                        subtitle: 'Monitor occupancy & enforcement',
                        route: AppRoutes.authorityEntry,
                      ),
                      SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.textMuted),
                          SizedBox(width: 6),
                          Text(
                            'You can switch roles anytime from Profile',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14284B).withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pushNamed(route);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(color: Color(0xFFEEF2F9), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
