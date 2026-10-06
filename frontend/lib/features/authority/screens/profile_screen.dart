import 'package:flutter/material.dart';
import 'login_screen.dart'; // To navigate back to login on logout

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Profile Header ---
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFF1A3B5C),
              child: Text(
                'WM',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Wijerathna M.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            const Text(
              'Traffic Officer — Colombo',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // --- Settings List ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    _buildListTile(
                      title: 'Account & role',
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildListTile(
                      title: 'Assigned region',
                      trailing: const Text('Colombo', style: TextStyle(color: Colors.grey)),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildListTile(
                      title: 'Report permissions',
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildListTile(
                      title: 'Notification settings',
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Log Out Button ---
            TextButton.icon(
              onPressed: () {
                // Mock logout - navigate back to login screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false, // Clear all previous routes
                );
              },
              icon: const Icon(Icons.logout, color: Color(0xFFD32F2F)),
              label: const Text(
                'Log out',
                style: TextStyle(color: Color(0xFFD32F2F), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for the list tiles
  Widget _buildListTile({
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}