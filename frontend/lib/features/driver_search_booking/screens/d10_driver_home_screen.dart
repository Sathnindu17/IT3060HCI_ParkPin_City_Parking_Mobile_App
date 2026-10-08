import 'package:flutter/material.dart';
import 'package:parkpin/features/driver_search/screens/driver_search_map_screen.dart';
import 'package:parkpin/features/driver_search_booking/screens/d05_driver_login_screen.dart';
import 'package:parkpin/services/auth_service.dart';
import 'package:parkpin/services/supabase_service.dart';

class D10DriverHomeScreen extends StatefulWidget {
  const D10DriverHomeScreen({super.key});

  @override
  State<D10DriverHomeScreen> createState() => _D10DriverHomeScreenState();
}

class _D10DriverHomeScreenState extends State<D10DriverHomeScreen> {
  static const navy = Color(0xFF173F78);
  static const orange = Color(0xFFFFA51F);
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const D05DriverLoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(SupabaseService.friendlyError(error)),
      ));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _openMap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DriverSearchMapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('ParkPin'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: _signingOut ? null : _signOut,
            icon: _signingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 18),
            const Text(
              'Welcome to ParkPin!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: navy),
            ),
            const SizedBox(height: 8),
            const Text('Find and reserve a parking space near you.'),
            const SizedBox(height: 28),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const Icon(Icons.local_parking_rounded, size: 60, color: navy),
                    const SizedBox(height: 16),
                    const Text(
                      'Find Available Parking',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'View parking facilities and available spaces on the map.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _openMap,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Find Parking'),
                        style: FilledButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: const Color(0xFF172033),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
