import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'account_role_screen.dart';
import 'assigned_region_screen.dart';
import 'report_permissions_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _profileFuture = Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
    } else {
      _profileFuture = Future.value({});
    }
  }

  Future<void> _refresh() async {
    setState(() => _fetchProfile());
    await _profileFuture;
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out',
                style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _goTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Profile',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data ?? {};

          // ✅ FIXED: Explicit String casts to avoid dynamic type inference issue
          final String fullName =
              (profile['full_name'] ?? 'Unknown Officer').toString();
          final String role =
              (profile['role'] ?? 'authority').toString();
          final String phone =
              (profile['phone'] ?? 'Not set').toString();
          final String region =
              (profile['assigned_region'] ?? 'Colombo').toString();

          // Generate initials safely
          final initials = fullName
              .split(' ')
              .where((e) => e.isNotEmpty)
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF1A3B5C),
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(fullName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    '${role[0].toUpperCase()}${role.substring(1)} Officer — $region',
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 30),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        _tile(
                          'Account & role',
                          trailingIcon: Icons.chevron_right,
                          onTap: () => _goTo(const AccountRoleScreen()),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _tile(
                          'Assigned region',
                          trailingText: region,
                          onTap: () => _goTo(const AssignedRegionScreen()),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _tile(
                          'Phone',
                          trailingText: phone,
                          onTap: () => _goTo(const AccountRoleScreen()),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _tile(
                          'Report permissions',
                          trailingIcon: Icons.chevron_right,
                          onTap: () =>
                              _goTo(const ReportPermissionsScreen()),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _tile(
                          'Notification settings',
                          trailingIcon: Icons.chevron_right,
                          onTap: () =>
                              _goTo(const NotificationSettingsScreen()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Color(0xFFD32F2F)),
                  label: const Text('Log out',
                      style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tile(
    String title, {
    IconData? trailingIcon,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(fontSize: 15, color: Colors.black87)),
      trailing: trailingText != null
          ? Text(trailingText, style: const TextStyle(color: Colors.grey))
          : Icon(trailingIcon ?? Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}