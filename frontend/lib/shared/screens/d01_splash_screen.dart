import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkpin/core/routes/app_routes.dart';
import 'package:parkpin/services/supabase_service.dart';

/// D01 – Splash ("Driver · Splash" Figma frame): logo, name and tagline on the
/// city-grid background. Then the app moves on to Role Selection. Tap anywhere
/// to skip.
///
/// Android always shows its own launch screen (brand blue + pin) while the app
/// loads. This screen starts identical to it – same colour, same pin, same size
/// and position – so the hand-off is invisible. The pin then stays put while the
/// gradient, city grid, name and tagline fade in around it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _gradientTop = Color(0xFF2A568F);
  static const _gradientBottom = Color(0xFF14315B);

  // Must match @color/splash_background in android/app/src/main/res/values/colors.xml.
  static const _launchBackground = Color(0xFF1F4375);

  // Size at which this PNG's pin matches the one Android draws on its launch
  // screen (measured on the emulator: pin ~117dp tall, centred). The pin sits
  // in the middle of the PNG, so centring it keeps it in the same place.
  static const _pinSize = 282.0;

  // How long the splash stays on screen before Role Selection.
  static const _totalDuration = Duration(milliseconds: 3500);

  static const _pinImage = AssetImage('assets/icons/app_icon_foreground.png');
  static const _gridImage = AssetImage('assets/images/splash_bg.png');

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _fade = CurvedAnimation(parent: _reveal, curve: Curves.easeOut);

  Timer? _leave;
  bool _imagesRequested = false;
  bool _imagesReady = false;
  bool _started = false;
  bool _left = false;

  // Start the fade and the timer only once this screen is on the display. On a
  // slow start (e.g. a debug build) Flutter builds its first frames before the
  // window has a size, while Android's launch screen is still showing; starting
  // earlier would let the timer run out behind it and skip straight to Role
  // Selection.
  void _startWhenVisible(Size size) {
    if (_started || !_imagesReady || size.isEmpty) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reveal.forward();
      _leave = Timer(_totalDuration, _goNext);
    });
  }

  @override
  void initState() {
    super.initState();
    // Hold the first frame until the images are decoded (see
    // didChangeDependencies). Otherwise the first frame is drawn without the
    // pin and it pops in a moment later – a visible jump from Android's launch
    // screen, which already shows the pin.
    WidgetsBinding.instance.deferFirstFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesRequested) {
      _imagesRequested = true;
      // Never hold the splash for long: if decoding is slow or fails, carry on
      // after a short wait instead of hanging on Android's launch screen.
      Future.wait([
        precacheImage(_pinImage, context),
        precacheImage(_gridImage, context),
      ]).timeout(const Duration(milliseconds: 800), onTimeout: () => const []).whenComplete(() {
        WidgetsBinding.instance.allowFirstFrame();
        if (mounted) setState(() => _imagesReady = true);
      });
    }
    // Respect the "remove animations" accessibility setting.
    if (MediaQuery.of(context).disableAnimations) _reveal.value = 1;
  }

  Future<void> _goNext() async {
    if (_left || !mounted) return;
    _left = true;
    // Supabase is started in main without blocking the first frame; make sure
    // it is ready before the rest of the app can use it.
    try {
      await SupabaseService.ready;
    } catch (_) {
      // Network or config problems surface later, where the user can retry.
    }
    if (!mounted) return;
    // Cross-fade into Role Selection instead of the default zoom transition.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: AppRoutes.roleSelection),
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, _, _) => AppRoutes.routes[AppRoutes.roleSelection]!(context),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _leave?.cancel();
    _reveal.dispose();
    super.dispose();
  }

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
                // Gradient + city-grid artwork (splash-bg) fade in over the
                // launch-screen colour.
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
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                // App icon pin, exactly where Android's launch screen drew it.
                Center(
                  child: Image(
                    image: _pinImage,
                    width: _pinSize,
                    height: _pinSize,
                    errorBuilder: (_, _, _) => const Icon(Icons.location_on, size: 76, color: Colors.white),
                  ),
                ),
                // Name and tagline, just under the pin. The pin's tip is ~69dp
                // below the centre; top padding 232 pushes this ~66dp-tall
                // block's centre down 116dp, so its top sits ~14dp under the tip.
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
