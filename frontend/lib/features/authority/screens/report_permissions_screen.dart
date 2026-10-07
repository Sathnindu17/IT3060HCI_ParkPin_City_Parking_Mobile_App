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

  // The permission definitions — key, title, description, icon
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

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ============================================
  // UPDATE — toggle a permission
  // ============================================
  Future<void> _togglePermission(
      Map<String, dynamic> current, String key, bool value) async {
    // Build the updated permissions map
    final updated = Map<String, dynamic>.from(
        (current['report_permissions'] as Map?) ?? {});

    updated[key] = value;

    // Optimistic UI: update local state immediately
    setState(() {
      _profileFuture = _profileFuture.then((profile) {
        profile['report_permissions'] = updated;
        return profile;
      });
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client
          .from('profiles')
          .update({'report_permissions': updated}).eq('id', userId);

      _showSnack(
        value
            ? '✅ ${_labelFor(key)} enabled'
            : '🚫 ${_labelFor(key)} disabled',
        value ? Colors.green : Colors.orange,
      );
    } catch (e) {
      // Rollback on failure
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Report permissions',
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
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final profile = snapshot.data ?? {};
          final permissions =
              (profile['report_permissions'] as Map?) ?? {};

          // Count how many are enabled
          final enabledCount = _permissionDefs
              .where((d) => permissions[d['key']] == true)
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Header card ----
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A3B5C), Color(0xFF2E5A8C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
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
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined,
                                color: Colors.white, size: 24),
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Reporting Permissions',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text(
                        'Control which report types you can create and manage',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ---- Permission toggles ----
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('PERMISSIONS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2)),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                      children: _buildPermissionTiles(permissions),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ---- Info card ----
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF1A3B5C).withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: Color(0xFF1A3B5C), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
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
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildPermissionTiles(Map<dynamic, dynamic> permissions) {
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
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFF1A3B5C).withOpacity(0.10)
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color:
                  enabled ? const Color(0xFF1A3B5C) : Colors.grey.shade600,
              size: 20,
            ),
          ),
          title: Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(description,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          onChanged: (value) =>
              _togglePermission(permissions.cast<String, dynamic>(), key, value),
        ),
      );

      // Add a divider between tiles
      if (i < _permissionDefs.length - 1) {
        tiles.add(const Divider(height: 1, indent: 60, endIndent: 16));
      }
    }

    return tiles;
  }
}