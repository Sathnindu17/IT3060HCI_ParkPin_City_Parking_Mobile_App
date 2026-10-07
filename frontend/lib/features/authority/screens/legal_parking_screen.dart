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
    _fetchFacilities();
  }

  void _fetchFacilities() {
    _facilitiesFuture = Supabase.instance.client
        .from('authority_legal_parking')
        .select();
  }

  Future<void> _refresh() async {
    setState(() => _fetchFacilities());
    await _facilitiesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Legal parking coverage',
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _facilitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorView('${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _emptyView();
          }

          final facilities = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Verified coverage',
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
                      child: Text('${facilities.length} facilities',
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
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: facilities.length,
                    itemBuilder: (context, index) {
                      final facility = facilities[index];
                      final available =
                          (facility['available_bays'] as num?)?.toInt() ?? 0;
                      final total =
                          (facility['total_bays'] as num?)?.toInt() ?? 0;
                      return _FacilityCard(
                        name: facility['name'] ?? 'Unknown Facility',
                        freeSpaces: available,
                        totalBays: total,
                        lat: (facility['latitude'] as num?)?.toDouble(),
                        lng: (facility['longitude'] as num?)?.toDouble(),
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

  Widget _errorView(String error) {
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
            const Text('Failed to load facilities',
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

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: Color(0xFFE8EDF2), shape: BoxShape.circle),
              child: const Icon(Icons.location_off,
                  color: Color(0xFF1A3B5C), size: 48),
            ),
            const SizedBox(height: 20),
            const Text('No verified facilities',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3B5C))),
            const SizedBox(height: 6),
            const Text('Legal parking coverage will appear here.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Facility Card
// ============================================
class _FacilityCard extends StatelessWidget {
  final String name;
  final int freeSpaces;
  final int totalBays;
  final double? lat;
  final double? lng;

  const _FacilityCard({
    required this.name,
    required this.freeSpaces,
    required this.totalBays,
    this.lat,
    this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final occupancyRate =
        totalBays == 0 ? 0.0 : (totalBays - freeSpaces) / totalBays;
    final isBusy = occupancyRate >= 0.8;
    final isModerate = occupancyRate >= 0.5 && occupancyRate < 0.8;

    Color badgeBg, badgeFg;
    if (isBusy) {
      badgeBg = const Color(0xFFFFEBEE);
      badgeFg = const Color(0xFFD32F2F);
    } else if (isModerate) {
      badgeBg = const Color(0xFFFFF3E0);
      badgeFg = const Color(0xFFF57C00);
    } else {
      badgeBg = const Color(0xFFE8F5E9);
      badgeFg = const Color(0xFF2E7D32);
    }

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
                child: const Icon(Icons.verified,
                    color: Color(0xFF2E7D32), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3B5C))),
                    const SizedBox(height: 2),
                    const Text('Verified legal facility',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('$freeSpaces free',
                    style: TextStyle(
                        color: badgeFg,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Capacity progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: occupancyRate.clamp(0, 1),
              minHeight: 6,
              backgroundColor: const Color(0xFFF0F3F7),
              valueColor: AlwaysStoppedAnimation<Color>(badgeFg),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_parking,
                      color: Colors.grey, size: 14),
                  const SizedBox(width: 4),
                  Text('${totalBays - freeSpaces} / $totalBays occupied',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
              if (lat != null && lng != null)
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.grey, size: 12),
                    const SizedBox(width: 2),
                    Text(
                        '${lat!.toStringAsFixed(3)}, ${lng!.toStringAsFixed(3)}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}