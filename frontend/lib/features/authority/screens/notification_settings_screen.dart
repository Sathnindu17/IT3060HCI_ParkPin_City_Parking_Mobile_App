import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  static const List<Map<String, dynamic>> _alertsGroup = [
    {
      'key': 'illegal_alerts',
      'title': 'Illegal parking alerts',
      'description': 'Get notified when a new violation is reported',
      'icon': Icons.warning_amber_rounded,
    },
    {
      'key': 'booking_updates',
      'title': 'Booking updates',
      'description': 'Driver reservations, cancellations, and extensions',
      'icon': Icons.event_available_outlined,
    },
    {
      'key': 'payment_receipts',
      'title': 'Payment receipts',
      'description': 'Receive confirmation when payments complete',
      'icon': Icons.receipt_long_outlined,
    },
  ];

  static const List<Map<String, dynamic>> _reportsGroup = [
    {
      'key': 'daily_summary',
      'title': 'Daily summary',
      'description': 'End-of-day digest of city parking activity',
      'icon': Icons.today_outlined,
    },
    {
      'key': 'weekly_report',
      'title': 'Weekly report',
      'description': 'Detailed analytics report every Monday morning',
      'icon': Icons.calendar_view_week_outlined,
    },
  ];

  static const List<Map<String, dynamic>> _styleGroup = [
    {
      'key': 'sound',
      'title': 'Sound',
      'description': 'Play a sound when a notification arrives',
      'icon': Icons.volume_up_outlined,
    },
    {
      'key': 'vibration',
      'title': 'Vibration',
      'description': 'Vibrate device for important alerts',
      'icon': Icons.vibration,
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

  // ✅ FIXED: null-safe + auth guard
  Future<void> _toggle(
      Map<dynamic, dynamic>? current, String key, bool value) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showSnack('❌ You must be logged in', Colors.red);
      return;
    }

    final settingsMap = (current ?? {});
    final updated = Map<String, dynamic>.from(settingsMap);
    updated[key] = value;

    setState(() {
      _profileFuture = _profileFuture.then((profile) {
        profile['notification_settings'] = updated;
        return profile;
      });
    });

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'notification_settings': updated}).eq('id', userId);
      _showSnack(
        value ? '✅ Enabled' : '🔕 Disabled',
        value ? Colors.green : Colors.orange,
      );
    } catch (e) {
      _showSnack('❌ Failed: $e', Colors.red);
      _refresh();
    }
  }

  // ✅ FIXED: null-safe + auth guard
  Future<void> _toggleMaster(
      Map<dynamic, dynamic>? current, bool value) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showSnack('❌ You must be logged in', Colors.red);
      return;
    }

    final settingsMap = (current ?? {});
    final updated = Map<String, dynamic>.from(settingsMap);

    for (final def in [..._alertsGroup, ..._reportsGroup, ..._styleGroup]) {
      updated[def['key']] = value;
    }
    updated['push_enabled'] = value;

    setState(() {
      _profileFuture = _profileFuture.then((profile) {
        profile['notification_settings'] = updated;
        return profile;
      });
    });

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'notification_settings': updated}).eq('id', userId);
      _showSnack(
        value ? '✅ All notifications enabled' : '🔕 All notifications muted',
        value ? Colors.green : Colors.orange,
      );
    } catch (e) {
      _showSnack('❌ Failed: $e', Colors.red);
      _refresh();
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
        title: const Text('Notification settings',
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
          final settings =
              (profile['notification_settings'] as Map?) ?? {};
          final masterEnabled = settings['push_enabled'] != false;

          final allDefs = [
            ..._alertsGroup,
            ..._reportsGroup,
            ..._styleGroup
          ];
          final enabledCount =
              allDefs.where((d) => settings[d['key']] == true).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notifications',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5C))),
                const SizedBox(height: 6),
                const Text('Control how and when ParkPin alerts reach you.',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: masterEnabled
                          ? const [Color(0xFF1A3B5C), Color(0xFF2E5A8C)]
                          : [Colors.grey.shade600, Colors.grey.shade700],
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
                            child: Icon(
                              masterEnabled
                                  ? Icons.notifications_active
                                  : Icons.notifications_off,
                              color: Colors.white,
                              size: 22,
                            ),
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
                              '$enabledCount / ${allDefs.length} on',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Push notifications',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        masterEnabled
                            ? 'You will receive alerts and reports'
                            : 'All notifications are muted',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Switch(
                            value: masterEnabled,
                            activeColor: const Color(0xFFEAA22F),
                            activeTrackColor: Colors.white,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor:
                                Colors.white.withOpacity(0.3),
                            onChanged: (v) => _toggleMaster(settings, v),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            masterEnabled ? 'Enabled' : 'Muted',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _sectionHeader('ALERTS'),
                const SizedBox(height: 12),
                _buildGroup(_alertsGroup, settings, masterEnabled),
                const SizedBox(height: 24),
                _sectionHeader('REPORTS & DIGESTS'),
                const SizedBox(height: 12),
                _buildGroup(_reportsGroup, settings, masterEnabled),
                const SizedBox(height: 24),
                _sectionHeader('STYLE'),
                const SizedBox(height: 12),
                _buildGroup(_styleGroup, settings, masterEnabled),
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
                            Text('Notification delivery',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3B5C))),
                            SizedBox(height: 4),
                            Text(
                              'Notifications are delivered through the ParkPin mobile app. Email delivery is not currently supported.',
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

  Widget _buildGroup(List<Map<String, dynamic>> defs,
      Map<dynamic, dynamic> settings, bool masterEnabled) {
    return Container(
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
            for (int i = 0; i < defs.length; i++) ...[
              _buildTile(defs[i], settings, masterEnabled),
              if (i < defs.length - 1)
                const Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                    color: Color(0xFFF0F3F7)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> def,
      Map<dynamic, dynamic> settings, bool masterEnabled) {
    final key = def['key'] as String;
    final title = def['title'] as String;
    final description = def['description'] as String;
    final icon = def['icon'] as IconData;
    final enabled = settings[key] == true;

    return SwitchListTile(
      value: enabled && masterEnabled,
      activeColor: const Color(0xFF1A3B5C),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      secondary: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled && masterEnabled
              ? const Color(0xFFE8EDF2)
              : const Color(0xFFF0F3F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled && masterEnabled
              ? const Color(0xFF1A3B5C)
              : Colors.grey.shade500,
          size: 22,
        ),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: masterEnabled
                  ? const Color(0xFF1A3B5C)
                  : Colors.grey)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(description,
            style: TextStyle(
                fontSize: 12,
                color: masterEnabled ? Colors.grey : Colors.grey.shade400)),
      ),
      onChanged: masterEnabled
          ? (value) => _toggle(settings, key, value)
          : null,
    );
  }
}