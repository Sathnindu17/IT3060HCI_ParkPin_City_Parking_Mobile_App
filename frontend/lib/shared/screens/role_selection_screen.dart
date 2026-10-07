import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/core/routes/app_routes.dart';

/// Start screen – choose Driver, Car-park Operator or Traffic Authority
/// (Figma frame "Role Selection").
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, top + 48, 24, 48),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, Color(0xFF2B5596)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 18),
                  const Text('Welcome to ParkPin',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('Choose how you\'ll use the app',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: const [
                      _RoleCard(
                        icon: Icons.directions_car_outlined,
                        iconBg: Color(0xFFE6EDF8),
                        iconColor: AppColors.primary,
                        title: 'Driver',
                        subtitle: 'Find, reserve & pay for parking',
                        route: AppRoutes.driverEntry,
                      ),
                      SizedBox(height: 12),
                      _RoleCard(
                        icon: Icons.local_parking,
                        iconBg: AppColors.warningBg,
                        iconColor: Color(0xFFB7791F),
                        title: 'Car-park Operator',
                        subtitle: 'Manage bays, bookings & gate',
                        route: AppRoutes.operatorEntry,
                      ),
                      SizedBox(height: 12),
                      _RoleCard(
                        icon: Icons.verified_user_outlined,
                        iconBg: Color(0xFFE3F4F1),
                        iconColor: Color(0xFF0F766E),
                        title: 'Traffic Authority',
                        subtitle: 'Monitor occupancy & enforcement',
                        route: AppRoutes.authorityEntry,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'You can switch roles anytime from Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
