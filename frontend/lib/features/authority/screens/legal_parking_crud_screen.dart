import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LegalParkingCrudScreen extends StatefulWidget {
  const LegalParkingCrudScreen({super.key});

  @override
  State<LegalParkingCrudScreen> createState() =>
      _LegalParkingCrudScreenState();
}

class _LegalParkingCrudScreenState
    extends State<LegalParkingCrudScreen> {
  late Future<List<Map<String, dynamic>>> _zonesFuture;

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

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

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

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
      _snack('✅ Zone created', Colors.green);
      _refresh();
    } catch (e) {
      _snack('❌ $e', Colors.red);
    }
  }

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
      _snack('✅ Zone updated', Colors.green);
      _refresh();
    } catch (e) {
      _snack('❌ $e', Colors.red);
    }
  }

  Future<void> _deleteZone(dynamic id) async {
    try {
      await Supabase.instance.client
          .from('legal_parking_zones')
          .delete()
          .eq('id', id);
      _snack('✅ Zone deleted', Colors.green);
      _refresh();
    } catch (e) {
      _snack('❌ $e', Colors.red);
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
        title: const Text('Legal parking zones',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createZone,
        backgroundColor: const Color(0xFFEAA22F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Zone',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _zonesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE8EDF2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.location_off,
                        color: Colors.grey, size: 48),
                  ),
                  const SizedBox(height: 20),
                  const Text('No zones yet',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3B5C))),
                  const SizedBox(height: 6),
                  const Text('Tap + to add your first zone',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey)),
                ],
              ),
            );
          }

          final zones = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Verified zones',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3B5C))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${zones.length} zones',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: zones.length,
                    itemBuilder: (context, i) {
                      final z = zones[i];
                      return Dismissible(
                        key: Key(z['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.only(right: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete,
                              color: Colors.white, size: 28),
                        ),
                        onDismissed: (_) => _deleteZone(z['id']),
                        child: GestureDetector(
                          onTap: () => _updateZone(z),
                          child: _ZoneCard(zone: z),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final Map<String, dynamic> zone;
  const _ZoneCard({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_parking,
                    color: Color(0xFF2E7D32), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone['name'] ?? 'Unnamed',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3B5C))),
                    const SizedBox(height: 2),
                    Text(zone['area'] ?? 'No area specified',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${zone['capacity'] ?? 0} bays',
                    style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if ((zone['notes'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes,
                      color: Colors.grey, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(zone['notes'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ZoneDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _ZoneDialog({this.existing});
  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  late TextEditingController _nameController;
  late TextEditingController _areaController;
  late TextEditingController _capController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?['name'] ?? '');
    _areaController =
        TextEditingController(text: widget.existing?['area'] ?? '');
    _capController = TextEditingController(
        text: (widget.existing?['capacity'] ?? 0).toString());
    _notesController =
        TextEditingController(text: widget.existing?['notes'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: Text(isEdit ? 'Edit Zone' : 'New Zone',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF1A3B5C))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Zone Name *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _areaController,
              decoration: InputDecoration(
                labelText: 'Area',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _capController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Capacity (bays)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes',
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
            child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEAA22F),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Zone name is required'),
                    backgroundColor: Colors.orange),
              );
              return;
            }
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'area': _areaController.text.trim(),
              'capacity': int.tryParse(_capController.text) ?? 0,
              'notes': _notesController.text.trim(),
            });
          },
          child: Text(isEdit ? 'Update' : 'Create',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}