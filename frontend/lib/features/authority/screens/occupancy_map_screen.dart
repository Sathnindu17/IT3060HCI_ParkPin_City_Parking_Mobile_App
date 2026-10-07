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
  Map<String, dynamic>? _selectedFacility;

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

  // Derive congestion from available / total
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
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title + Congestion badge
            Row(
              children: [
                Expanded(
                  child: Text(facility['name'] ?? 'Unknown',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _colorFor(congestion).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(congestion.toUpperCase(),
                      style: TextStyle(
                          color: _colorFor(congestion),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bays status
            Row(
              children: [
                _sheetStat('Available', '$available',
                    const Color(0xFF2E7D32)),
                const SizedBox(width: 12),
                _sheetStat('Occupied', '${total - available}',
                    const Color(0xFFD32F2F)),
                const SizedBox(width: 12),
                _sheetStat('Total', '$total',
                    const Color(0xFF1A3B5C)),
              ],
            ),
            const SizedBox(height: 16),
            // Coordinates
            Row(
              children: [
                const Icon(Icons.location_on,
                    color: Colors.grey, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${(facility['latitude'] as num?)?.toStringAsFixed(4) ?? '-'}, '
                  '${(facility['longitude'] as num?)?.toStringAsFixed(4) ?? '-'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sheetStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
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
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            return const Center(child: Text('No facilities found.'));
          }

          final facilities = snapshot.data!;

          // Sort by congestion (high first)
          final sorted = List<Map<String, dynamic>>.from(facilities)
            ..sort((a, b) {
              const order = {'high': 0, 'med': 1, 'low': 2};
              return (order[_calculateCongestion(a)] ?? 3)
                  .compareTo(order[_calculateCongestion(b)] ?? 3);
            });

          // Build markers for the map
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
                onTap: () {
                  setState(() => _selectedFacility = f);
                  _showFacilitySheet(f);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _colorFor(congestion),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color:
                              _colorFor(congestion).withOpacity(0.5),
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

          // Default center: first facility or Colombo
          final center = facilities.isNotEmpty &&
                  facilities.first['latitude'] != null
              ? LatLng(
                  (facilities.first['latitude'] as num).toDouble(),
                  (facilities.first['longitude'] as num).toDouble())
              : const LatLng(6.9271, 79.8612);

          return Column(
            children: [
              // ---------- MAP ----------
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
                    // Attribution required by OpenStreetMap
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

              // ---------- LIST ----------
              Expanded(
                flex: 4,
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
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final facility = sorted[index];
                        return _CongestionListItem(
                          zone: facility['name'] ?? 'Unknown',
                          severity: _calculateCongestion(facility),
                          available: (facility['available_bays'] as num?)
                                  ?.toInt() ??
                              0,
                          total:
                              (facility['total_bays'] as num?)?.toInt() ?? 0,
                          onTap: () {
                            _showFacilitySheet(facility);
                          },
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
}

// ============================================
// List item widget
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(severity,
                  style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}