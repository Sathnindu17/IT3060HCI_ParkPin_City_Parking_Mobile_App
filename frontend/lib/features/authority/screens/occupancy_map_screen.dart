import 'package:flutter/material.dart';

class OccupancyMapScreen extends StatelessWidget {
  const OccupancyMapScreen({super.key});

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
            Text('Occupancy map', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Congestion hotspots', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // --- Mock Map Section ---
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE6F2), // Light blue map background
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Stack(
                children: [
                  // Mock roads
                  Positioned(top: 40, left: 0, right: 0, child: Container(height: 20, color: Colors.white.withOpacity(0.6))),
                  Positioned(top: 120, left: 0, right: 0, child: Container(height: 20, color: Colors.white.withOpacity(0.6))),
                  Positioned(top: 0, bottom: 0, left: 100, child: Container(width: 20, color: Colors.white.withOpacity(0.6))),
                  Positioned(top: 0, bottom: 0, left: 250, child: Container(width: 20, color: Colors.white.withOpacity(0.6))),
                  
                  // Mock hotspot markers
                  const Positioned(top: 50, left: 120, child: _MapMarker(color: Color(0xFFD32F2F))), // Red (High)
                  const Positioned(top: 140, left: 260, child: _MapMarker(color: Color(0xFFD32F2F))), // Red (High)
                  const Positioned(top: 80, left: 300, child: _MapMarker(color: Color(0xFFF57C00))), // Orange (Med)
                ],
              ),
            ),
          ),
          
          // --- List Section ---
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: ListView(
                padding: const EdgeInsets.only(top: 20),
                children: const [
                  _CongestionListItem(zone: 'Galle Rd', severity: 'high'),
                  _CongestionListItem(zone: 'Kollupitiya', severity: 'high'),
                  _CongestionListItem(zone: 'Fort', severity: 'med'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for map markers
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
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, spreadRadius: 2)],
      ),
    );
  }
}

// Helper widget for the list items
class _CongestionListItem extends StatelessWidget {
  final String zone;
  final String severity;
  const _CongestionListItem({required this.zone, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color badgeTextColor;

    if (severity == 'high') {
      badgeColor = const Color(0xFFFFEBEE); // Light Red
      badgeTextColor = const Color(0xFFD32F2F); // Dark Red
    } else {
      badgeColor = const Color(0xFFFFF3E0); // Light Orange
      badgeTextColor = const Color(0xFFF57C00); // Dark Orange
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
          Text(zone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
            child: Text(
              severity,
              style: TextStyle(color: badgeTextColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}