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

  // ✅ UPDATED: Join authority_profiles
  void _fetchProfile() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _profileFuture = Supabase.instance.client
          .from('profiles')
          .select('''
            id, full_name,
            authority_profiles(assigned_region)
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
      // ✅ UPDATE authority_profiles, not profiles
      await Supabase.instance.client
          .from('authority_profiles')
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
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Assigned region',
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
          // ✅ Extract region from nested authority_profiles
          final authorityData = (profile['authority_profiles'] as Map?) ?? {};
          final region =
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
                            child: const Icon(Icons.location_city,
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
                                Icon(Icons.check_circle,
                                    color: Colors.white, size: 12),
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
                      const SizedBox(height: 20),
                      const Text('ASSIGNED REGION',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text(region,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Municipal Council Jurisdiction',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _sectionHeader('REGION OVERVIEW'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statCard(
                      Icons.local_parking,
                      'Facilities',
                      _facilitiesForRegion(region).toString(),
                      const Color(0xFF1A3B5C),
                      const Color(0xFFE8EDF2),
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      Icons.warning_amber_rounded,
                      'Alerts',
                      _alertsForRegion(region).toString(),
                      const Color(0xFFD32F2F),
                      const Color(0xFFFFEBEE),
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      Icons.map_outlined,
                      'Area km²',
                      _areaForRegion(region).toString(),
                      const Color(0xFF2E7D32),
                      const Color(0xFFE8F5E9),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _sectionHeader('DETAILS'),
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
                      children: [
                        _infoTile(Icons.location_on_outlined, 'Region',
                            region),
                        _divider(),
                        _infoTile(Icons.flag_outlined, 'Country',
                            'Sri Lanka'),
                        _divider(),
                        _infoTile(Icons.business_outlined, 'Authority',
                            '$region Municipal Council'),
                        _divider(),
                        _infoTile(Icons.schedule, 'Timezone',
                            'GMT +5:30'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _changeRegion(region),
                    icon: const Icon(Icons.swap_horiz,
                        color: Colors.white, size: 20),
                    label: const Text('Change Assigned Region',
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
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Region changes require admin approval',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
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

  Widget _statCard(
      IconData icon, String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3B5C))),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: const Text('Select Assigned Region',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF1A3B5C))),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.regions.length,
          itemBuilder: (_, index) {
            final region = widget.regions[index];
            final isSelected = region == _selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => setState(() => _selected = region),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE8EDF2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1A3B5C)
                          : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(region,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: const Color(0xFF1A3B5C))),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: Color(0xFF1A3B5C), size: 20),
                    ],
                  ),
                ),
              ),
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
              backgroundColor: const Color(0xFFEAA22F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10)),
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Save',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}