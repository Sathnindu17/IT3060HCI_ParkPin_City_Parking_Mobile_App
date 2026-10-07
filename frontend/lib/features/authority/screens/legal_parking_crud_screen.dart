import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LegalParkingCrudScreen extends StatefulWidget {
  const LegalParkingCrudScreen({super.key});

  @override
  State<LegalParkingCrudScreen> createState() =>
      _LegalParkingCrudScreenState();
}

class _LegalParkingCrudScreenState extends State<LegalParkingCrudScreen> {
  late Future<List<Map<String, dynamic>>> _zonesFuture;

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

  // ============================================
  // READ — Fetch all zones
  // ============================================
  void _fetchZones() {
    _zonesFuture = Supabase.instance.client
        .from('legal_parking_zones')
        .select()
        .order('created_at', ascending: false);
  }

  Future<void> _refresh() async {
    setState(() => _fetchZones());
    await _zonesFuture;
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ============================================
  // CREATE — Add a new zone
  // ============================================
  Future<void> _createZone() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _ZoneDialog(),
    );
    if (result == null) return;

    try {
      await Supabase.instance.client.from('legal_parking_zones').insert({
        ...result,
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      });
      _showSnack('✅ Zone created', Colors.green);
      _refresh();
    } catch (e) {
      _showSnack('❌ $e', Colors.red);
    }
  }

  // ============================================
  // UPDATE — Edit existing zone
  // ============================================
  Future<void> _updateZone(Map<String, dynamic> zone) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ZoneDialog(existing: zone),
    );
    if (result == null) return;

    try {
      await Supabase.instance.client
          .from('legal_parking_zones')
          .update(result)
          .eq('id', zone['id']);
      _showSnack('✅ Zone updated', Colors.green);
      _refresh();
    } catch (e) {
      _showSnack('❌ $e', Colors.red);
    }
  }

  // ============================================
  // DELETE — Remove a zone
  // ============================================
  Future<void> _deleteZone(dynamic id) async {
    try {
      await Supabase.instance.client
          .from('legal_parking_zones')
          .delete()
          .eq('id', id);
      _showSnack('✅ Zone deleted', Colors.green);
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
        title: FutureBuilder<List<Map<String, dynamic>>>(
          future: _zonesFuture,
          builder: (context, snapshot) {
            final count = snapshot.data?.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Legal parking zones',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('$count zones · tap to manage',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createZone,
        backgroundColor: const Color(0xFFEAA22F),
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('New Zone', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _zonesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('${snapshot.error}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEAA22F)),
                      child: const Text('Retry',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, color: Colors.grey, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No legal parking zones yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final zones = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: zones.length,
              itemBuilder: (context, index) {
                final zone = zones[index];
                return Dismissible(
                  key: Key(zone['id'].toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete,
                        color: Colors.white, size: 32),
                  ),
                  onDismissed: (_) => _deleteZone(zone['id']),
                  child: GestureDetector(
                    onTap: () => _updateZone(zone),
                    child: _ZoneItem(zone: zone),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ============================================
// Zone Dialog — Used for BOTH create & update
// ============================================
class _ZoneDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _ZoneDialog({this.existing});

  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  late TextEditingController _nameController;
  late TextEditingController _areaController;
  late TextEditingController _capacityController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?['name'] ?? '');
    _areaController =
        TextEditingController(text: widget.existing?['area'] ?? '');
    _capacityController = TextEditingController(
        text: (widget.existing?['capacity'] ?? 0).toString());
    _notesController =
        TextEditingController(text: widget.existing?['notes'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Zone' : 'New Legal Parking Zone'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Zone Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Area',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capacity (bays)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
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
              backgroundColor: const Color(0xFFEAA22F)),
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Zone name is required'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'area': _areaController.text.trim(),
              'capacity': int.tryParse(_capacityController.text) ?? 0,
              'notes': _notesController.text.trim(),
            });
          },
          child: Text(isEdit ? 'Update' : 'Create',
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ============================================
// Zone Item — List tile
// ============================================
class _ZoneItem extends StatelessWidget {
  final Map<String, dynamic> zone;
  const _ZoneItem({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.local_parking,
                color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone['name'] ?? 'Unnamed',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(zone['area'] ?? 'No area',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey)),
                if ((zone['notes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(zone['notes'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${zone['capacity'] ?? 0} bays',
                style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}