import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
        .from('authority_legal_parking')
        .select();
  }

  Future<void> _refresh() async {
    setState(() => _fetchFacilities());
    await _facilitiesFuture;
  }

  String _calculateCongestion(Map<String, dynamic> facility) {
    final int total = (facility['total_bays'] as num?)?.toInt() ?? 0;
    final int available = (facility['available_bays'] as num?)?.toInt() ?? 0;
    if (total == 0) return 'low';
    final double rate = available / total;
    if (rate < 0.2) return 'high';
    if (rate < 0.5) return 'med';
    return 'low';
  }

  Color _colorFor(String congestion) {
    switch (congestion) {
      case 'high':
        return const Color(0xFFD32F2F);
      case 'med':
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  void _showFacilitySheet(Map<String, dynamic> facility) {
    final congestion = _calculateCongestion(facility);
    final available = (facility['available_bays'] as num?)?.toInt() ?? 0;
    final total = (facility['total_bays'] as num?)?.toInt() ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _colorFor(congestion).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on,
                      color: _colorFor(congestion), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(facility['name'] ?? 'Unknown',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3B5C))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _colorFor(congestion).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(congestion.toUpperCase(),
                            style: TextStyle(
                                color: _colorFor(congestion),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _sheetStat('Available', '$available',
                    const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
                const SizedBox(width: 10),
                _sheetStat('Occupied', '${total - available}',
                    const Color(0xFFD32F2F), const Color(0xFFFFEBEE)),
                const SizedBox(width: 10),
                _sheetStat('Total', '$total',
                    const Color(0xFF1A3B5C), const Color(0xFFE8EDF2)),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location,
                      color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${(facility['latitude'] as num?)?.toStringAsFixed(4) ?? '-'}, '
                    '${(facility['longitude'] as num?)?.toStringAsFixed(4) ?? '-'}',
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sheetStat(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Occupancy map',
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
          final sorted = List<Map<String, dynamic>>.from(facilities)
            ..sort((a, b) {
              const order = {'high': 0, 'med': 1, 'low': 2};
              return (order[_calculateCongestion(a)] ?? 3)
                  .compareTo(order[_calculateCongestion(b)] ?? 3);
            });

          final markers = facilities
              .where((f) =>
                  f['latitude'] != null && f['longitude'] != null)
              .map((f) {
            final congestion = _calculateCongestion(f);
            return Marker(
              point: LatLng(
                (f['latitude'] as num).toDouble(),
                (f['longitude'] as num).toDouble(),
              ),
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () => _showFacilitySheet(f),
                child: Container(
                  decoration: BoxDecoration(
                    color: _colorFor(congestion),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: _colorFor(congestion).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.local_parking,
                      color: Colors.white, size: 20),
                ),
              ),
            );
          }).toList();

          final center = facilities.isNotEmpty &&
                  facilities.first['latitude'] != null
              ? LatLng(
                  (facilities.first['latitude'] as num).toDouble(),
                  (facilities.first['longitude'] as num).toDouble())
              : const LatLng(6.9271, 79.8612);

          return Column(
            children: [
              // -------- MAP --------
              Expanded(
                flex: 5,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 12.5,
                    minZoom: 5,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.we46.parkpin',
                    ),
                    MarkerLayer(markers: markers),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // -------- LIST --------
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Hotspots',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3B5C))),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EDF2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${sorted.length} zones',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1A3B5C),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.only(bottom: 16),
                            itemCount: sorted.length,
                            itemBuilder: (context, index) {
                              final facility = sorted[index];
                              return _CongestionListItem(
                                zone: facility['name'] ?? 'Unknown',
                                severity: _calculateCongestion(facility),
                                available: (facility['available_bays']
                                            as num?)
                                        ?.toInt() ??
                                    0,
                                total: (facility['total_bays'] as num?)
                                        ?.toInt() ??
                                    0,
                                onTap: () => _showFacilitySheet(facility),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
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
            const Text('Failed to load map data',
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
              child: const Icon(Icons.map_outlined,
                  color: Color(0xFF1A3B5C), size: 48),
            ),
            const SizedBox(height: 20),
            const Text('No facilities on map',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3B5C))),
            const SizedBox(height: 6),
            const Text('Facility coordinates are needed to plot hotspots.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ============================================
// List Item Widget
// ============================================
class _CongestionListItem extends StatelessWidget {
  final String zone;
  final String severity;
  final int available;
  final int total;
  final VoidCallback? onTap;

  const _CongestionListItem({
    required this.zone,
    required this.severity,
    required this.available,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color badgeTextColor;
    Color iconBg;
    switch (severity) {
      case 'high':
        badgeColor = const Color(0xFFFFEBEE);
        badgeTextColor = const Color(0xFFD32F2F);
        iconBg = const Color(0xFFFFEBEE);
        break;
      case 'med':
        badgeColor = const Color(0xFFFFF3E0);
        badgeTextColor = const Color(0xFFF57C00);
        iconBg = const Color(0xFFFFF3E0);
        break;
      default:
        badgeColor = const Color(0xFFE8F5E9);
        badgeTextColor = const Color(0xFF2E7D32);
        iconBg = const Color(0xFFE8F5E9);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_parking,
                  color: badgeTextColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3B5C))),
                  const SizedBox(height: 2),
                  Text('$available of $total bays free',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(severity.toUpperCase(),
                  style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}