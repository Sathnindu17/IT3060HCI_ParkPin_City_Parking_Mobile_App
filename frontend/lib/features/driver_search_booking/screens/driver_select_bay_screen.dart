import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../driver_search/models/parking_map_facility.dart';
import 'driver_payment_preview_screen.dart';

class DriverSelectBayScreen extends StatefulWidget {
  const DriverSelectBayScreen({super.key, required this.facility, required this.vehicle, required this.hours, required this.arrival});
  final ParkingMapFacility facility;
  final String vehicle;
  final int hours;
  final DateTime arrival;
  @override
  State<DriverSelectBayScreen> createState() => _DriverSelectBayScreenState();
}
class _DriverSelectBayScreenState extends State<DriverSelectBayScreen> {
  static const navy = Color(0xFF1E3D70);
  static const orange = Color(0xFFFFA51F);
  List<Map<String, dynamic>> bays = [];
  String? selectedId;
  String? level;
  String? error;
  bool loading = true;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final rows = await Supabase.instance.client.from('bays').select('id,facility_id,label,level,type,status').eq('facility_id', widget.facility.id).order('label');
      if (!mounted) return;
      setState(() { bays = List<Map<String,dynamic>>.from(rows); selectedId = null; final levels = bays.map((b) => (b['level'] as String?) ?? 'Ground').toSet(); level = levels.isEmpty ? null : levels.first; });
    } catch (e) { if (mounted) setState(() => error = 'Could not load bays: $e'); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    final levels = bays.map((b) => (b['level'] as String?) ?? 'Ground').toSet().toList()..sort();
    final visible = bays.where((b) => ((b['level'] as String?) ?? 'Ground') == level).toList();
    final selected = bays.where((b) => b['id'] == selectedId).toList();
    return Scaffold(backgroundColor: const Color(0xFFF4F6FB), appBar: AppBar(title: const Text('Select your bay'), backgroundColor: navy, foregroundColor: Colors.white, actions: [IconButton(onPressed: loading ? null : load, icon: const Icon(Icons.refresh))]), body: SafeArea(child: Column(children: [
      if (loading) const LinearProgressIndicator(),
      if (error != null) Padding(padding: const EdgeInsets.all(16), child: Text(error!, style: const TextStyle(color: Colors.red))),
      if (!loading && error == null) Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.facility.name, style: const TextStyle(fontWeight: FontWeight.bold, color: navy)),
        const SizedBox(height: 12),
        if (bays.isEmpty) const Text('No bays found for this parking facility.'),
        Wrap(spacing: 8, children: [for (final l in levels) ChoiceChip(label: Text(l), selected: level == l, onSelected: (_) => setState(() { level = l; selectedId = null; }))]),
        const SizedBox(height: 12),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: visible.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1.6, crossAxisSpacing: 8, mainAxisSpacing: 8), itemBuilder: (context, i) {
          final bay = visible[i]; final available = bay['status'] == 'available'; final chosen = bay['id'] == selectedId;
          return OutlinedButton(style: OutlinedButton.styleFrom(backgroundColor: chosen ? orange : available ? Colors.white : const Color(0xFFCBD5E1), foregroundColor: navy, padding: EdgeInsets.zero), onPressed: available ? () => setState(() => selectedId = bay['id'] as String) : null, child: Text(bay['label'].toString()));
        }),
        const SizedBox(height: 16), Text(selected.isEmpty ? 'No bay selected' : 'Selected: ${selected.first['label']} · ${selected.first['level'] ?? 'Ground'}'),
        const SizedBox(height: 10), const Text('White: available   Grey: unavailable   Orange: selected', style: TextStyle(fontSize: 12)),
      ])) else const Expanded(child: Center(child: CircularProgressIndicator())),
      Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, height: 52, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: orange, foregroundColor: navy), onPressed: selected.isEmpty || loading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverPaymentPreviewScreen(facility: widget.facility, bay: selected.first, arrival: widget.arrival, hours: widget.hours, vehicle: widget.vehicle))), child: const Text('Continue to payment review')))),
    ])));
  }
}
