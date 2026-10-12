import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkpin/core/routes/app_routes.dart';
import 'package:parkpin/services/supabase_service.dart';

/// D01 – ParkPin Splash Screen.
///
/// Displays the ParkPin logo, app name and tagline.
/// Automatically navigates to Role Selection after 3.5 seconds.
///
/// Users can tap anywhere to skip the splash screen.
///
/// The initial background and logo are designed to match
/// the native Android launch screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ============================================
  // COLORS
  // ============================================

  static const Color _gradientTop = Color(0xFF2A568F);
  static const Color _gradientBottom = Color(0xFF14315B);
  static const Color _launchBackground = Color(0xFF1F4375);

  // ============================================
  // SETTINGS
  // ============================================

  static const double _pinSize = 282.0;

  static const Duration _totalDuration = Duration(milliseconds: 3500);

  // ============================================
  // IMAGES
  // ============================================

  static const AssetImage _pinImage = AssetImage(
    'assets/icons/app_icon_foreground.png',
  );

  static const AssetImage _gridImage = AssetImage(
    'assets/images/splash_bg.png',
  );

  // ============================================
  // ANIMATION
  // ============================================

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _reveal,
    curve: Curves.easeOut,
  );

  Timer? _leave;

  bool _imagesRequested = false;
  bool _imagesReady = false;
  bool _started = false;
  bool _left = false;

  // ============================================
  // START SPLASH ANIMATION
  // ============================================

  void _startWhenVisible(Size size) {
    if (_started || !_imagesReady || size.isEmpty) {
      return;
    }

    _started = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _reveal.forward();

      _leave = Timer(_totalDuration, _goNext);
    });
  }

  // ============================================
  // INITIALIZE SCREEN
  // ============================================

  @override
  void initState() {
    super.initState();

    // Prevent displaying the first Flutter frame
    // before the splash images are loaded.
    WidgetsBinding.instance.deferFirstFrame();
  }

  // ============================================
  // PRELOAD SPLASH IMAGES
  // ============================================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_imagesRequested) {
      _imagesRequested = true;

      Future.wait([
            precacheImage(_pinImage, context),
            precacheImage(_gridImage, context),
          ])
          .timeout(const Duration(milliseconds: 800), onTimeout: () => const [])
          .whenComplete(() {
            WidgetsBinding.instance.allowFirstFrame();

            if (mounted) {
              setState(() {
                _imagesReady = true;
              });
            }
          });
    }

    // Support reduced-motion accessibility settings.
    if (MediaQuery.of(context).disableAnimations) {
      _reveal.value = 1;
    }
  }

  // ============================================
  // NAVIGATE TO ROLE SELECTION
  // ============================================

  void _goNext() {
    if (_left || !mounted) {
      return;
    }

    _left = true;

    // SupabaseService.ready returns a bool.
    // It must not be awaited.
    //
    // Supabase initialization is performed in main.dart.
    if (!SupabaseService.ready) {
      debugPrint('ParkPin: Supabase is not initialized yet.');
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: AppRoutes.roleSelection),
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, _, _) =>
            AppRoutes.routes[AppRoutes.roleSelection]!(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  // ============================================
  // DISPOSE
  // ============================================

  @override
  void dispose() {
    _leave?.cancel();
    _reveal.dispose();

    super.dispose();
  }

  // ============================================
  // BUILD UI
  // ============================================

  @override
  Widget build(BuildContext context) {
    _startWhenVisible(MediaQuery.sizeOf(context));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _launchBackground,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _goNext,
          child: Semantics(
            label: 'ParkPin. Find and reserve city parking',
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ====================================
                // BACKGROUND GRADIENT AND CITY GRID
                // ====================================

                FadeTransition(
                  opacity: _fade,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_gradientTop, _gradientBottom],
                      ),
                    ),
                    child: Image(
                      image: _gridImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),

                // ====================================
                // PARKPIN LOGO
                // ====================================
                Center(
                  child: Image(
                    image: _pinImage,
                    width: _pinSize,
                    height: _pinSize,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.location_on,
                        size: 76,
                        color: Colors.white,
                      );
                    },
                  ),
                ),

                // ====================================
                // PARKPIN NAME AND TAGLINE
                // ====================================
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 232),
                    child: FadeTransition(
                      opacity: _fade,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ParkPin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 13),

                          Text(
                            'Find & reserve city parking',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
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
        ),
      ),
    );
  }
}
