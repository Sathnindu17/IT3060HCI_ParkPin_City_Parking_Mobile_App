import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignedRegionScreen extends StatefulWidget {
  const AssignedRegionScreen({super.key});

  @override
  State<AssignedRegionScreen> createState() => _AssignedRegionScreenState();
}

class _AssignedRegionScreenState extends State<AssignedRegionScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  static const List<String> _availableRegions = [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Galle',
    'Jaffna',
    'Negombo',
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

  Future<void> _changeRegion(String current) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => _RegionPickerDialog(
        current: current,
        regions: _availableRegions,
      ),
    );
    if (selected == null || selected == current) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client
          .from('profiles')
          .update({'assigned_region': selected})
          .eq('id', userId);
      _showSnack('✅ Assigned region updated to $selected', Colors.green);
      _refresh();
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Assigned region',
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
          final region = (profile['assigned_region'] ?? 'Colombo').toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Hero Card ----
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                            child: const Icon(Icons.location_city,
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
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('ACTIVE',
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
                      const SizedBox(height: 16),
                      const Text('Assigned Region',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Text(region,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Municipal Council Jurisdiction',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ---- Region Stats ----
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('REGION OVERVIEW',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2)),
                ),
                Row(
                  children: [
                    _statCard(
                      Icons.local_parking,
                      'Facilities',
                      _facilitiesForRegion(region).toString(),
                      const Color(0xFF1A3B5C),
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      Icons.warning_amber_rounded,
                      'Alerts',
                      _alertsForRegion(region).toString(),
                      const Color(0xFFD32F2F),
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      Icons.map_outlined,
                      'Area km²',
                      _areaForRegion(region).toString(),
                      const Color(0xFF2E7D32),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ---- Region Details ----
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('DETAILS',
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
                      children: [
                        _infoTile(Icons.location_on_outlined, 'Region',
                            region),
                        const Divider(
                            height: 1, indent: 60, endIndent: 16),
                        _infoTile(Icons.flag_outlined, 'Country',
                            'Sri Lanka'),
                        const Divider(
                            height: 1, indent: 60, endIndent: 16),
                        _infoTile(Icons.business_outlined, 'Authority',
                            '$region Municipal Council'),
                        const Divider(
                            height: 1, indent: 60, endIndent: 16),
                        // ✅ FIXED: was Icons.time_to_commit_outlined
                        _infoTile(Icons.schedule, 'Timezone',
                            'GMT +5:30'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ---- Change Region Button ----
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _changeRegion(region),
                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                    label: const Text('Change Assigned Region',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAA22F),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Region changes require admin approval',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _statCard(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A3B5C)),
      title: Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500)),
    );
  }

  int _facilitiesForRegion(String region) {
    switch (region) {
      case 'Colombo':
        return 42;
      case 'Gampaha':
        return 27;
      case 'Kandy':
        return 19;
      case 'Galle':
        return 14;
      default:
        return 10;
    }
  }

  int _alertsForRegion(String region) {
    switch (region) {
      case 'Colombo':
        return 7;
      case 'Gampaha':
        return 4;
      case 'Kandy':
        return 3;
      default:
        return 2;
    }
  }

  int _areaForRegion(String region) {
    switch (region) {
      case 'Colombo':
        return 37;
      case 'Gampaha':
        return 1387;
      case 'Kandy':
        return 1940;
      case 'Galle':
        return 1652;
      default:
        return 500;
    }
  }
}

// ============================================
// Region Picker Dialog
// ============================================
class _RegionPickerDialog extends StatefulWidget {
  final String current;
  final List<String> regions;

  const _RegionPickerDialog({required this.current, required this.regions});

  @override
  State<_RegionPickerDialog> createState() => _RegionPickerDialogState();
}

class _RegionPickerDialogState extends State<_RegionPickerDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Assigned Region'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.regions.length,
          itemBuilder: (_, index) {
            final region = widget.regions[index];
            final isSelected = region == _selected;
            return RadioListTile<String>(
              value: region,
              groupValue: _selected,
              activeColor: const Color(0xFF1A3B5C),
              title: Text(region,
                  style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal)),
              onChanged: (v) => setState(() => _selected = v ?? _selected),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAA22F)),
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Save',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}