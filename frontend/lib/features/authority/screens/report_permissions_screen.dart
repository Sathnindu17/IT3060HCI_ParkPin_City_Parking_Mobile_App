import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportPermissionsScreen extends StatefulWidget {
  const ReportPermissionsScreen({super.key});

  @override
  State<ReportPermissionsScreen> createState() =>
      _ReportPermissionsScreenState();
}

class _ReportPermissionsScreenState extends State<ReportPermissionsScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  static const List<Map<String, dynamic>> _permissionDefs = [
    {
      'key': 'illegal_parking',
      'title': 'Illegal Parking Reports',
      'description': 'Create and edit illegal parking violation reports',
      'icon': Icons.warning_amber_rounded,
    },
    {
      'key': 'legal_zone_edits',
      'title': 'Legal Zone Edits',
      'description': 'Add, modify, or delete verified legal parking zones',
      'icon': Icons.location_city,
    },
    {
      'key': 'occupancy_reports',
      'title': 'Occupancy Reports',
      'description': 'View and export live occupancy analytics',
      'icon': Icons.analytics_outlined,
    },
    {
      'key': 'driver_advisories',
      'title': 'Driver Advisories',
      'description': 'Publish alerts visible to drivers in the mobile app',
      'icon': Icons.campaign_outlined,
    },
    {
      'key': 'facility_updates',
      'title': 'Facility Updates',
      'description': 'Update facility capacity, rates, and amenities',
      'icon': Icons.edit_note,
    },
    {
      'key': 'enforcement_logs',
      'title': 'Enforcement Logs',
      'description': 'Mark reports as enforced and log officer actions',
      'icon': Icons.gavel,
    },
  ];

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
            id, full_name,
            authority_profiles(report_permissions)
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

  // ✅ UPDATED: writes to authority_profiles
  Future<void> _togglePermission(
      Map<String, dynamic>? current, String key, bool value) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showSnack('❌ You must be logged in', Colors.red);
      return;
    }

    // Extract from nested authority_profiles
    final authorityData = (current?['authority_profiles'] as Map?) ?? {};
    final permissionsMap = (authorityData['report_permissions'] as Map?) ?? {};
    final updated = Map<String, dynamic>.from(permissionsMap);
    updated[key] = value;

    // Optimistic UI
    setState(() {
      _profileFuture = _profileFuture.then((profile) {
        final auth = Map<String, dynamic>.from(
            (profile['authority_profiles'] as Map?) ?? {});
        auth['report_permissions'] = updated;
        profile['authority_profiles'] = auth;
        return profile;
      });
    });

    try {
      // ✅ Update authority_profiles table
      await Supabase.instance.client
          .from('authority_profiles')
          .update({'report_permissions': updated}).eq('id', userId);
      _showSnack(
        value ? '✅ ${_labelFor(key)} enabled' : '🚫 ${_labelFor(key)} disabled',
        value ? Colors.green : Colors.orange,
      );
    } catch (e) {
      _showSnack('❌ Failed: $e', Colors.red);
      _refresh();
    }
  }

  String _labelFor(String key) {
    final def = _permissionDefs.firstWhere(
      (d) => d['key'] == key,
      orElse: () => {'title': key},
    );
    return def['title'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Report permissions',
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
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final profile = snapshot.data ?? {};
          // ✅ Extract permissions from nested authority_profiles
          final authorityData = (profile['authority_profiles'] as Map?) ?? {};
          final permissions =
              (authorityData['report_permissions'] as Map?) ?? {};

          final enabledCount = _permissionDefs
              .where((d) => permissions[d['key']] == true)
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reporting permissions',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5C))),
                const SizedBox(height: 6),
                const Text(
                    'Control which report types you can create and manage.',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                            child: const Icon(Icons.shield_outlined,
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
                            child: Text(
                              '$enabledCount / ${_permissionDefs.length} enabled',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Active permissions',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text('$enabledCount of ${_permissionDefs.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Toggle permissions below',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _sectionHeader('PERMISSIONS'),
                const SizedBox(height: 12),
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
                      children: _buildPermissionTiles(profile),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF1A3B5C).withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline,
                          color: Color(0xFF1A3B5C), size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('About permissions',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3B5C))),
                            SizedBox(height: 4),
                            Text(
                              'Changes take effect immediately. Some permissions may require admin approval to re-enable once disabled.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF1A3B5C)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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

  Widget _sectionHeader(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.5));

  List<Widget> _buildPermissionTiles(Map<String, dynamic> profile) {
    // ✅ Extract from nested authority_profiles
    final authorityData = (profile['authority_profiles'] as Map?) ?? {};
    final permissions = (authorityData['report_permissions'] as Map?) ?? {};

    final List<Widget> tiles = [];

    for (int i = 0; i < _permissionDefs.length; i++) {
      final def = _permissionDefs[i];
      final key = def['key'] as String;
      final title = def['title'] as String;
      final description = def['description'] as String;
      final icon = def['icon'] as IconData;
      final enabled = permissions[key] == true;

      tiles.add(
        SwitchListTile(
          value: enabled,
          activeColor: const Color(0xFF1A3B5C),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          secondary: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFFE8EDF2)
                  : const Color(0xFFF0F3F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: enabled
                  ? const Color(0xFF1A3B5C)
                  : Colors.grey.shade500,
              size: 22,
            ),
          ),
          title: Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? const Color(0xFF1A3B5C)
                      : Colors.grey.shade700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(description,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          onChanged: (value) => _togglePermission(profile, key, value),
        ),
      );

      if (i < _permissionDefs.length - 1) {
        tiles.add(const Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: Color(0xFFF0F3F7)));
      }
    }

    return tiles;
  }
}