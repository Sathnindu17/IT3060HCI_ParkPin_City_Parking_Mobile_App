import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OccupancyMapScreen extends StatefulWidget {
  const OccupancyMapScreen({super.key});

  @override
  State<OccupancyMapScreen> createState() => _OccupancyMapScreenState();
}

class _OccupancyMapScreenState extends State<OccupancyMapScreen> {
  late Future<List<Map<String, dynamic>>> _facilitiesFuture;

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
  }

  void _fetchFacilities() {
    _facilitiesFuture = Supabase.instance.client
        .from('authority_legal_parking') // Reuse the view (has available_bays)
        .select();
  }

  Future<void> _refresh() async {
    setState(() => _fetchFacilities());
    await _facilitiesFuture;
  }

  /// Derive congestion level from available / total bays
  String _calculateCongestion(Map<String, dynamic> facility) {
    final int total = (facility['total_bays'] as num?)?.toInt() ?? 0;
    final int available = (facility['available_bays'] as num?)?.toInt() ?? 0;

    if (total == 0) return 'low';

    final double availabilityRate = available / total;

    if (availabilityRate < 0.2) return 'high';
    if (availabilityRate < 0.5) return 'med';
    return 'low';
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
            Text('Occupancy map',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text('Congestion hotspots',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
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
            return const Center(child: Text('No facilities found.'));
          }

          final facilities = snapshot.data!;

          // Sort: high congestion first, then med, then low
          final sorted = List<Map<String, dynamic>>.from(facilities)
            ..sort((a, b) {
              const order = {'high': 0, 'med': 1, 'low': 2};
              return (order[_calculateCongestion(a)] ?? 3)
                  .compareTo(order[_calculateCongestion(b)] ?? 3);
            });

          return Column(
            children: [
              // ====== MOCK MAP ======
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE6F2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Mock roads
                      Positioned(
                          top: 40,
                          left: 0,
                          right: 0,
                          child: Container(
                              height: 20,
                              color: Colors.white.withOpacity(0.6))),
                      Positioned(
                          top: 120,
                          left: 0,
                          right: 0,
                          child: Container(
                              height: 20,
                              color: Colors.white.withOpacity(0.6))),
                      Positioned(
                          top: 0,
                          bottom: 0,
                          left: 100,
                          child: Container(
                              width: 20,
                              color: Colors.white.withOpacity(0.6))),
                      Positioned(
                          top: 0,
                          bottom: 0,
                          left: 250,
                          child: Container(
                              width: 20,
                              color: Colors.white.withOpacity(0.6))),

                      // Dynamic markers based on the actual data
                      ..._buildMapMarkers(sorted),
                    ],
                  ),
                ),
              ),

              // ====== LIST ======
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24)),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 20),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final facility = sorted[index];
                        final congestion = _calculateCongestion(facility);
                        final available =
                            (facility['available_bays'] as num?)?.toInt() ?? 0;
                        final total =
                            (facility['total_bays'] as num?)?.toInt() ?? 0;

                        return _CongestionListItem(
                          zone: facility['name'] ?? 'Unknown',
                          severity: congestion,
                          available: available,
                          total: total,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Position markers on the mock map dynamically
  List<Widget> _buildMapMarkers(List<Map<String, dynamic>> facilities) {
    // Fixed positions on the mock map (in a real app, use lat/lng projection)
    const positions = [
      Offset(120, 50),
      Offset(260, 140),
      Offset(300, 80),
      Offset(180, 200),
      Offset(70, 150),
    ];

    return facilities.take(positions.length).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final facility = entry.value;
      final congestion = _calculateCongestion(facility);

      Color color;
      switch (congestion) {
        case 'high':
          color = const Color(0xFFD32F2F);
          break;
        case 'med':
          color = const Color(0xFFF57C00);
          break;
        default:
          color = const Color(0xFF2E7D32);
      }

      return Positioned(
        top: positions[index].dy,
        left: positions[index].dx,
        child: _MapMarker(color: color),
      );
    }).toList();
  }
}

// ===== Helper Widgets =====

class _MapMarker extends StatelessWidget {
  final Color color;
  const _MapMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 6,
              spreadRadius: 2)
        ],
      ),
    );
  }
}

class _CongestionListItem extends StatelessWidget {
  final String zone;
  final String severity;
  final int available;
  final int total;

  const _CongestionListItem({
    required this.zone,
    required this.severity,
    required this.available,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color badgeTextColor;

    switch (severity) {
      case 'high':
        badgeColor = const Color(0xFFFFEBEE);
        badgeTextColor = const Color(0xFFD32F2F);
        break;
      case 'med':
        badgeColor = const Color(0xFFFFF3E0);
        badgeTextColor = const Color(0xFFF57C00);
        break;
      default:
        badgeColor = const Color(0xFFE8F5E9);
        badgeTextColor = const Color(0xFF2E7D32);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text('$available / $total bays free',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: badgeColor, borderRadius: BorderRadius.circular(20)),
            child: Text(
              severity,
              style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}