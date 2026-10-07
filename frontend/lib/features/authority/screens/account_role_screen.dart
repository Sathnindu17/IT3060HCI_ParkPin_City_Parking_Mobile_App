import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountRoleScreen extends StatefulWidget {
  const AccountRoleScreen({super.key});

  @override
  State<AccountRoleScreen> createState() => _AccountRoleScreenState();
}

class _AccountRoleScreenState extends State<AccountRoleScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // ✅ UPDATED: Join authority_profiles
  void _fetchProfile() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _profileFuture = Supabase.instance.client
          .from('profiles')
          .select('''
            id, full_name, role, phone, created_at, notification_settings,
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

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ✅ Only updates profiles table (name/phone live there)
  Future<void> _editProfile(Map<String, dynamic> profile) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditProfileDialog(profile: profile),
    );
    if (result == null) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client
          .from('profiles')
          .update(result)
          .eq('id', userId);
      _showSnack('✅ Profile updated', Colors.green);
      _refresh();
    } catch (e) {
      _showSnack('❌ $e', Colors.red);
    }
  }

  Future<void> _changePassword() async {
    final newPassword = await showDialog<String>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (newPassword == null || newPassword.isEmpty) return;

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _showSnack('✅ Password updated successfully', Colors.green);
    } on AuthException catch (e) {
      _showSnack('❌ ${e.message}', Colors.red);
    } catch (e) {
      _showSnack('❌ $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Account & role',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
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
          if (snapshot.hasError) {
            return _buildError('${snapshot.error}');
          }

          final profile = snapshot.data ?? {};
          final email =
              Supabase.instance.client.auth.currentUser?.email ?? 'N/A';
          final String fullName =
              (profile['full_name'] ?? 'Unknown Officer').toString();
          final String role =
              (profile['role'] ?? 'authority').toString();
          final String phone =
              (profile['phone'] ?? 'Not set').toString();
          final createdAt = profile['created_at'] != null
              ? DateTime.parse(profile['created_at'].toString())
                  .toLocal()
                  .toString()
                  .substring(0, 10)
              : 'N/A';

          // ✅ Extract region from nested authority_profiles
          final authorityData = (profile['authority_profiles'] as Map?) ?? {};
          final String region =
              (authorityData['assigned_region'] ?? 'Colombo').toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A3B5C), Color(0xFF2E5A8C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.badge_outlined,
                                color: Colors.white, size: 22),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('VERIFIED',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('CURRENT ROLE',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text(
                        '${role[0].toUpperCase()}${role.substring(1)} Officer',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('$region Municipality',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _sectionHeader('ACCOUNT DETAILS'),
                const SizedBox(height: 12),
                Container(
                  decoration: _cardDecoration(),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        _infoTile(Icons.person_outline, 'Full Name',
                            fullName),
                        _divider(),
                        _infoTile(Icons.email_outlined, 'Email', email),
                        _divider(),
                        _infoTile(
                            Icons.phone_outlined, 'Phone', phone),
                        _divider(),
                        _infoTile(Icons.calendar_today_outlined,
                            'Member since', createdAt),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _sectionHeader('SECURITY'),
                const SizedBox(height: 12),
                Container(
                  decoration: _cardDecoration(),
                  child: Material(
                    color: Colors.transparent,
                    child: _actionTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: _changePassword,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _editProfile(profile),
                    icon: const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 20),
                    label: const Text('Edit Profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAA22F),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline,
                  color: Color(0xFFD32F2F), size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Failed to load profile',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAA22F),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12)),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4))
      ],
    );
  }

  Widget _sectionHeader(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.5));
  }

  Widget _divider() => const Divider(
      height: 1, indent: 72, endIndent: 16, color: Color(0xFFF0F3F7));

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1A3B5C),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: const Color(0xFFF57C00), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3B5C))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Edit Profile Dialog
// ============================================
class _EditProfileDialog extends StatefulWidget {
  final Map<String, dynamic> profile;
  const _EditProfileDialog({required this.profile});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.profile['full_name'] ?? '');
    _phoneController =
        TextEditingController(text: widget.profile['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Profile',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF1A3B5C))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAA22F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10)),
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Name is required'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            Navigator.pop(context, {
              'full_name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
            });
          },
          child: const Text('Save',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ============================================
// Change Password Dialog
// ============================================
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: const Text('Change Password',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF1A3B5C))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAA22F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10)),
          onPressed: () {
            final pwd = _passwordController.text;
            final confirm = _confirmController.text;

            if (pwd.length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Password must be at least 6 characters'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            if (pwd != confirm) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Passwords do not match'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            Navigator.pop(context, pwd);
          },
          child: const Text('Update',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}