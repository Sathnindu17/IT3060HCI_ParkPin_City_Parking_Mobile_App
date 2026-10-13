import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../driver_search/screens/driver_search_map_screen.dart';
import '../../driver_search_booking/screens/d05_driver_login_screen.dart';
import '../../driver_search_booking/screens/d10_driver_home_screen.dart';
import '../widgets/parking_ui.dart';
import 'booking_history_screen.dart';
import 'driver_receipts_screen.dart';
import 'notifications_screen.dart';
import 'profile_privacy_screen.dart';

class DriverIntegratedScreen extends StatefulWidget {
  final int initialIndex;

  const DriverIntegratedScreen({
    super.key,
    this.initialIndex = 1,
  }) : assert(initialIndex >= 0 && initialIndex <= 3);

  @override
  State<DriverIntegratedScreen> createState() =>
      _DriverIntegratedScreenState();
}

class _DriverIntegratedScreenState
    extends State<DriverIntegratedScreen> {
  late int _index;
  late Future<bool> _driverCheck;

  Route<dynamic>? _screenRoute;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _driverCheck = _checkDriver();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenRoute = ModalRoute.of(context);
  }

  Future<bool> _checkDriver() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in as a driver.');
    }

    final profile = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (client.auth.currentUser?.id != user.id) {
      throw StateError('Your account changed. Please sign in again.');
    }

    if (profile?['role'] != 'driver') {
      throw StateError('This section requires a driver account.');
    }

    return true;
  }

  void _selectTab(int index) {
    if (!mounted || index < 0 || index > 3) return;

    final screenRoute = _screenRoute;

    if (screenRoute != null) {
      Navigator.of(context).popUntil(
        (route) => identical(route, screenRoute),
      );
    }

    if (!mounted) return;

    setState(() {
      _index = index;
      _revision++;
    });
  }

  void _openLogin() {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => const D05DriverLoginScreen(),
      ),
      (_) => false,
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          preview: false,
          onNavigate: _selectTab,
        ),
      ),
    );

    if (!mounted) return;

    setState(() => _revision++);
  }

  void _findParking() {
    // Close receipt/recovery routes above this driver screen.
    _selectTab(1);

    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const DriverSearchMapScreen(),
          ),
        )
        .then((_) {
      if (!mounted) return;

      setState(() => _revision++);
    });
  }

  Widget _currentPage() {
    switch (_index) {
      case 0:
        return D10DriverHomeScreen(
          onOpenBookings: () => _selectTab(1),
        );

      case 1:
        return BookingHistoryScreen(
          key: ValueKey('history-$_revision'),
          preview: false,
          onNavigate: _selectTab,
          onFindAnotherParking: _findParking,
        );

      case 2:
        return DriverReceiptsScreen(
          key: ValueKey('receipts-$_revision'),
          onNavigate: _selectTab,
        );

      case 3:
        return ProfilePrivacyScreen(
          key: ValueKey('profile-$_revision'),
          onNavigate: _selectTab,
          onLoggedOut: _openLogin,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _accessProblem(Object? error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver account'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error?.toString().replaceFirst('Bad state: ', '') ??
                    'Unable to verify your driver account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _driverCheck = _checkDriver();
                  });
                },
                child: const Text('Try again'),
              ),
              TextButton(
                onPressed: _openLogin,
                child: const Text('Return to driver login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _driverCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data != true) {
          return _accessProblem(snapshot.error);
        }

        return Scaffold(
          body: _currentPage(),

          // The other pages already provide their own bottom navigation.
          bottomNavigationBar: _index == 0
              ? BottomNavigationBar(
                  currentIndex: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: ParkingStyle.navy,
                  unselectedItemColor: ParkingStyle.muted,
                  onTap: _selectTab,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_month_outlined),
                      label: 'Bookings',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.receipt_long_outlined),
                      label: 'Receipts',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      label: 'Profile',
                    ),
                  ],
                )
              : null,

          floatingActionButton: FloatingActionButton(
            heroTag: 'driver-notifications',
            tooltip: 'Notifications',
            backgroundColor: ParkingStyle.orange,
            foregroundColor: ParkingStyle.navy,
            onPressed: _openNotifications,
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}