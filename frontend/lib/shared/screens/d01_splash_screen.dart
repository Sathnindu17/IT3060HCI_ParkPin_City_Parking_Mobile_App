import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/core/routes/app_routes.dart';

/// D01 – Splash. Covers two Figma frames, which are the start and end of one
/// Smart Animate:
///   • "Driver · Splash (intro)" – background only (logo + text at opacity 0)
///   • "Driver · Splash"         – logo, name and tagline faded in
/// Then the app moves on to Role Selection. Tap anywhere to skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _gradientTop = Color(0xFF2A568F);
  static const _gradientBottom = Color(0xFF14315B);

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);

  Timer? _startLogo;
  Timer? _leave;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    // State 1 = "Splash (intro)": background only.
    // State 2 = "Splash": logo + name fade in (opacity 0 → 1, as in Figma).
    _startLogo = Timer(const Duration(milliseconds: 350), _anim.forward);
    _leave = Timer(const Duration(milliseconds: 2400), _goNext);
  }

  void _goNext() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacementNamed(AppRoutes.roleSelection);
  }

  @override
  void dispose() {
    _startLogo?.cancel();
    _leave?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the "remove animations" accessibility setting.
    if (MediaQuery.of(context).disableAnimations) _anim.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _goNext,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_gradientTop, _gradientBottom],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // City-grid artwork exported from the Figma frame (splash-bg).
                Image.asset(
                  'assets/images/splash_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Semantics(
                      label: 'ParkPin. Find and reserve city parking',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.location_on_outlined, size: 42, color: AppColors.primary),
                          ),
                          const SizedBox(height: 13),
                          const Text(
                            'ParkPin',
                            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 13),
                          Text(
                            'Find & reserve city parking',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
