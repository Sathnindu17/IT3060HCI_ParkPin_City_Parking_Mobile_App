import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/driver_active_booking/screens/driver_booking_hub.dart';
import 'features/driver_active_booking/screens/driver_sign_in_screen.dart';
import 'features/driver_active_booking/widgets/parking_ui.dart';

class ParkPinApp extends StatelessWidget {
  const ParkPinApp({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final userId = client.auth.currentSession?.user.id;

        return MaterialApp(
          // Changing accounts resets the navigation stack.
          key: ValueKey(userId),
          debugShowCheckedModeBanner: false,
          title: 'ParkPin',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: ParkingStyle.navy,
            ),
            scaffoldBackgroundColor: ParkingStyle.background,
          ),
          home: userId == null
              ? const DriverSignInScreen()
              : DriverRoleGate(
                  key: ValueKey(userId),
                ),
        );
      },
    );
  }
}

class DriverRoleGate extends StatefulWidget {
  const DriverRoleGate({super.key});

  @override
  State<DriverRoleGate> createState() => _DriverRoleGateState();
}

class _DriverRoleGateState extends State<DriverRoleGate> {
  late Future<bool> _roleFuture;

  bool _signingOut = false;
  String? _signOutError;

  @override
  void initState() {
    super.initState();
    _roleFuture = _loadRole();
  }

  Future<bool> _loadRole() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) return false;

    final profile = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      throw StateError(
        'Your account has no profile. '
        'Ask your project administrator to check it.',
      );
    }

    return profile['role'] == 'driver';
  }

  void _retry() {
    if (_signingOut) return;

    setState(() {
      _signOutError = null;
      _roleFuture = _loadRole();
    });
  }

  Future<void> _signOut() async {
    if (_signingOut) return;

    setState(() {
      _signingOut = true;
      _signOutError = null;
    });

    try {
      await Supabase.instance.client.auth.signOut(
        scope: SignOutScope.local,
      );

      // ParkPinApp automatically returns to the login screen.
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _signOutError =
            'Could not sign out. Check your connection and retry.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _signingOut = false;
        });
      }
    }
  }

  String _profileError(Object? error) {
    if (error is StateError) {
      return error.message.toString();
    }

    return 'Could not load your driver profile. '
        'Check your connection and try again.';
  }

  Widget _accountMessage({
    required String message,
    required bool canRetry,
  }) {
    return Scaffold(
      backgroundColor: ParkingStyle.background,
      appBar: AppBar(
        title: const Text('Driver account'),
        backgroundColor: ParkingStyle.background,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ParkingCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 56,
                      color: ParkingStyle.navy,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        height: 1.5,
                        color: ParkingStyle.text,
                      ),
                    ),
                    if (_signOutError != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _signOutError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (canRetry)
                      FilledButton(
                        onPressed: _signingOut ? null : _retry,
                        child: const Text('Try again'),
                      ),
                    TextButton(
                      onPressed: _signingOut ? null : _signOut,
                      child: Text(
                        _signingOut ? 'Signing out…' : 'Sign out',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: ParkingStyle.background,
            body: Center(
              child: CircularProgressIndicator(
                color: ParkingStyle.orange,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _accountMessage(
            message: _profileError(snapshot.error),
            canRetry: true,
          );
        }

        if (snapshot.data != true) {
          return _accountMessage(
            message:
                'Sign in with a driver account '
                'to access your parking bookings.',
            canRetry: false,
          );
        }

        return const DriverBookingHub();
      },
    );
  }
}