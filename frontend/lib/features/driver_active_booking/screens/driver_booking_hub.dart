import 'package:flutter/material.dart';

import '../widgets/parking_ui.dart';
import 'booking_history_screen.dart';
import 'driver_receipts_screen.dart';
import 'notifications_screen.dart';
import 'profile_privacy_screen.dart';

class DriverBookingHub extends StatefulWidget {
  // The group can supply these screens during integration.
  final WidgetBuilder? sharedHomeBuilder;
  final WidgetBuilder? parkingSearchBuilder;
  final WidgetBuilder? vehiclesBuilder;
  final WidgetBuilder? paymentMethodsBuilder;

  const DriverBookingHub({
    super.key,
    this.sharedHomeBuilder,
    this.parkingSearchBuilder,
    this.vehiclesBuilder,
    this.paymentMethodsBuilder,
  });

  @override
  State<DriverBookingHub> createState() =>
      _DriverBookingHubState();
}

class _DriverBookingHubState extends State<DriverBookingHub> {
  int _index = 0;
  int _revision = 0;

  void _navigate(int index) {
    if (!mounted || index < 0 || index > 3) return;

    // Close any receipt or notification route above this dashboard.
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );

    setState(() {
      _index = index;
      _revision++;
    });
  }

  Future<void> _openExternalScreen(
    WidgetBuilder builder,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: builder,
      ),
    );

    if (!mounted) return;

    setState(() {
      _revision++;
    });
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          preview: false,
          onNavigate: _navigate,
        ),
      ),
    );
  }

  VoidCallback? get _findParkingAction {
    final builder = widget.parkingSearchBuilder;

    if (builder == null) return null;

    return () {
      _openExternalScreen(builder);
    };
  }

  VoidCallback? get _vehiclesAction {
    final builder = widget.vehiclesBuilder;

    if (builder == null) return null;

    return () {
      _openExternalScreen(builder);
    };
  }

  VoidCallback? get _paymentMethodsAction {
    final builder = widget.paymentMethodsBuilder;

    if (builder == null) return null;

    return () {
      _openExternalScreen(builder);
    };
  }

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            ParkingStyle.navy,
            Color(0xFF31598E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(24),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_parking_rounded,
              size: 34,
              color: ParkingStyle.orange,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your parking,\nin one place',
            style: TextStyle(
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Manage your reservation, extend your active '
            'session and access your parking receipts.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => _navigate(1),
              style: FilledButton.styleFrom(
                backgroundColor: ParkingStyle.orange,
                foregroundColor: ParkingStyle.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.calendar_today_outlined,
              ),
              label: const Text(
                'Open my bookings',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE8EDF5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ParkingStyle.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: ParkingStyle.navy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ParkingStyle.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: ParkingStyle.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: ParkingStyle.navy,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeScreen() {
    return Scaffold(
      backgroundColor: ParkingStyle.background,
      appBar: AppBar(
        backgroundColor: ParkingStyle.background,
        elevation: 0,
        title: const Text(
          'My parking',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: ParkingStyle.navy,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: _openNotifications,
            icon: const Icon(
              Icons.notifications_outlined,
              color: ParkingStyle.navy,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _welcomeCard(),
            const SizedBox(height: 26),
            const Text(
              'Manage your parking',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: ParkingStyle.navy,
              ),
            ),
            const SizedBox(height: 16),
            _actionCard(
              icon: Icons.calendar_today_outlined,
              title: 'Bookings & active parking',
              subtitle:
                  'Open a reservation or manage your active session',
              onTap: () => _navigate(1),
            ),
            _actionCard(
              icon: Icons.receipt_long_outlined,
              title: 'Receipts',
              subtitle: 'View final receipts and export PDFs',
              onTap: () => _navigate(2),
            ),
            _actionCard(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Read your latest parking updates',
              onTap: _openNotifications,
            ),
            _actionCard(
              icon: Icons.person_outline_rounded,
              title: 'Profile & privacy',
              subtitle:
                  'Manage your account and notification preferences',
              onTap: () => _navigate(3),
            ),
            if (widget.sharedHomeBuilder != null)
              _actionCard(
                icon: Icons.home_outlined,
                title: 'ParkPin Home',
                subtitle: 'Open the main driver home',
                onTap: () {
                  _openExternalScreen(
                    widget.sharedHomeBuilder!,
                  );
                },
              ),
            if (widget.parkingSearchBuilder != null)
              _actionCard(
                icon: Icons.map_outlined,
                title: 'Find parking',
                subtitle: 'Search available parking locations',
                onTap: () {
                  _openExternalScreen(
                    widget.parkingSearchBuilder!,
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: ParkingStyle.navy,
        unselectedItemColor: ParkingStyle.muted,
        onTap: _navigate,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_index) {
      case 1:
        return BookingHistoryScreen(
          key: ValueKey('bookings-$_revision'),
          preview: false,
          onNavigate: _navigate,
          onFindAnotherParking: _findParkingAction,
        );

      case 2:
        return DriverReceiptsScreen(
          key: ValueKey('receipts-$_revision'),
          onNavigate: _navigate,
        );

      case 3:
        return ProfilePrivacyScreen(
          key: ValueKey('profile-$_revision'),
          onNavigate: _navigate,
          onOpenVehicles: _vehiclesAction,
          onOpenPaymentMethods: _paymentMethodsAction,
        );

      default:
        return _homeScreen();
    }
  }
}