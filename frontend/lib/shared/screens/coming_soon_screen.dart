import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/core/routes/app_routes.dart';

/// Shown for routes a team member has not added yet
/// (used by onUnknownRoute in app.dart, so the app never crashes on a missing screen).
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.routeName});
  final String routeName;

  static const _ink = Color(0xFF14284B);
  static const _navyLight = Color(0xFF2E5A99);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final canPop = Navigator.of(context).canPop();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(8, top + 8, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, _navyLight],
                ),
              ),
              child: Row(
                children: [
                  if (canPop)
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    )
                  else
                    const SizedBox(width: 16),
                  const Text(
                    'ParkPin',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: _ink.withValues(alpha: 0.07),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(color: AppColors.warningBg, shape: BoxShape.circle),
                          child: const Icon(Icons.construction_rounded, size: 38, color: Color(0xFFB7791F)),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Coming soon',
                          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: _ink),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This part of ParkPin is still being built by another team member. '
                          'Please check back after the next update.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.5, color: AppColors.textMuted, height: 1.45),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            routeName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.onAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.roleSelection,
                              (_) => false,
                            ),
                            icon: const Icon(Icons.home_rounded),
                            label: const Text('Back to roles'),
                          ),
                        ),
                      ],
                    ),
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
