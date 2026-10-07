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

  // ✅ UPDATED: Join authority_profiles via FK
  void _fetchProfile() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _profileFuture = Supabase.instance.client
          .from('profiles')
          .select('''
            id, full_name, role, phone, notification_settings,
            authority_profiles(assigned_region, report_permissions)
          ''')
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Profile',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data ?? {};
          final String fullName =
              (profile['full_name'] ?? 'Unknown Officer').toString();
          final String role =
              (profile['role'] ?? 'authority').toString();
          final String phone =
              (profile['phone'] ?? 'Not set').toString();

          // ✅ Extract region from nested authority_profiles
          final authorityData = (profile['authority_profiles'] as Map?) ?? {};
          final String region =
              (authorityData['assigned_region'] ?? 'Colombo').toString();

          final initials = fullName
              .split(' ')
              .where((e) => e.isNotEmpty)
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: CircleAvatar(
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
                ),
                const SizedBox(height: 16),
                Text(fullName,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5C))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDF2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${role[0].toUpperCase()}${role.substring(1)} Officer · $region',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1A3B5C),
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        _tile(
                          icon: Icons.badge_outlined,
                          title: 'Account & role',
                          trailingText: null,
                          onTap: () => _goTo(const AccountRoleScreen()),
                        ),
                        _divider(),
                        _tile(
                          icon: Icons.location_on_outlined,
                          title: 'Assigned region',
                          trailingText: region,
                          onTap: () => _goTo(const AssignedRegionScreen()),
                        ),
                        _divider(),
                        _tile(
                          icon: Icons.phone_outlined,
                          title: 'Phone',
                          trailingText: phone,
                          onTap: () => _goTo(const AccountRoleScreen()),
                        ),
                        _divider(),
                        _tile(
                          icon: Icons.shield_outlined,
                          title: 'Report permissions',
                          trailingText: null,
                          onTap: () =>
                              _goTo(const ReportPermissionsScreen()),
                        ),
                        _divider(),
                        _tile(
                          icon: Icons.notifications_outlined,
                          title: 'Notification settings',
                          trailingText: null,
                          onTap: () =>
                              _goTo(const NotificationSettingsScreen()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout,
                        color: Color(0xFFD32F2F), size: 20),
                    label: const Text('Log out',
                        style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFD32F2F), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text('ParkPin Authority · v1.0',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, indent: 72, endIndent: 16, color: Color(0xFFF0F3F7));

  Widget _tile({
    required IconData icon,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDF2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1A3B5C), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A3B5C))),
            ),
            if (trailingText != null)
              Text(trailingText,
                  style: const TextStyle(fontSize: 13, color: Colors.grey))
            else
              const Icon(Icons.chevron_right,
                  color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}