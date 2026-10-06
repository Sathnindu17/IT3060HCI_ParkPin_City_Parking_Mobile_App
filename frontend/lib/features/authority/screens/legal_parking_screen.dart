import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LegalParkingScreen extends StatefulWidget {
  const LegalParkingScreen({super.key});

  @override
  State<LegalParkingScreen> createState() => _LegalParkingScreenState();
}

class _LegalParkingScreenState extends State<LegalParkingScreen> {
  late Future<List<Map<String, dynamic>>> _facilitiesFuture;

  @override
  void initState() {
    super.initState();
    // Fetch data from the database view we created earlier
    _facilitiesFuture = Supabase.instance.client
        .from('authority_legal_parking')
        .select();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Legal parking coverage', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Verified facilities to guide drivers to', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Mock Map (Kept static for now - will need Google Maps API key to make dynamic)
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE6F2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Stack(
                children: [
                  Positioned(top: 60, left: 0, right: 0, child: Container(height: 15, color: Colors.white.withOpacity(0.6))),
                  Positioned(top: 140, left: 0, right: 0, child: Container(height: 15, color: Colors.white.withOpacity(0.6))),
                  const Positioned(top: 80, left: 80, child: _GreenMarker()),
                  const Positioned(top: 160, left: 220, child: _GreenMarker()),
                ],
              ),
            ),
          ),
          
          // List of facilities (NOW DYNAMIC FROM SUPABASE)
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _facilitiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No legal parking facilities found.'));
                  }

                  final facilities = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 20),
                    itemCount: facilities.length,
                    itemBuilder: (context, index) {
                      final facility = facilities[index];
                      return _FacilityItem(
                        name: facility['name'] ?? 'Unknown Facility',
                        freeSpaces: facility['available_bays'] ?? 0,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreenMarker extends StatelessWidget {
  const _GreenMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.4), blurRadius: 6, spreadRadius: 2)],
      ),
    );
  }
}

class _FacilityItem extends StatelessWidget {
  final String name;
  final int freeSpaces;
  const _FacilityItem({required this.name, required this.freeSpaces});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                const Text('Verified legal facility', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
            child: Text('$freeSpaces free', style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}