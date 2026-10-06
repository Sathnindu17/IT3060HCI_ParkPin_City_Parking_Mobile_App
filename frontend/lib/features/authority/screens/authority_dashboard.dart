import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'occupancy_map_screen.dart';
import 'illegal_parking_screen.dart';
import 'demand_reports_screen.dart';
import 'profile_screen.dart';
import 'legal_parking_screen.dart';
import 'peak_hour_screen.dart';

class AuthorityDashboard extends StatefulWidget {
  const AuthorityDashboard({super.key});

  @override
  State<AuthorityDashboard> createState() => _AuthorityDashboardState();
}

class _AuthorityDashboardState extends State<AuthorityDashboard> {
  late Future<Map<String, dynamic>> _statsFuture;
  int _currentIndex = 0;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _setupRealtime();
  }

  @override
  void dispose() {
    // Clean up the realtime subscription
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _fetchStats() {
    _statsFuture = Supabase.instance.client
        .from('authority_dashboard_stats')
        .select()
        .single();
  }

  void _setupRealtime() {
    // Listen for changes in illegal reports to auto-refresh stats
    _realtimeChannel = Supabase.instance.client
        .channel('dashboard_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'illegal_parking_reports',
          callback: (payload) {
            if (mounted) {
              setState(() => _fetchStats());
            }
          },
        )
        .subscribe();
  }

  Future<void> _refreshStats() async {
    setState(() => _fetchStats());
    await _statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('City parking',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Colombo - live overview',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshStats,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(), // Has its own FutureBuilder
          const OccupancyMapScreen(),
          const DemandReportsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF1A3B5C),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
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
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Failed to load stats',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshStats,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAA22F),
                    ),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        final double occRate =
            (stats['occupancy_percentage'] as num?)?.toDouble() ?? 0.0;
        final int alerts = stats['open_alerts'] as int? ?? 0;
        final int fullLots = stats['full_lots'] as int? ?? 0;
        const int hotspots = 3; // Placeholder until you add a hotspots view

        return RefreshIndicator(
          onRefresh: _refreshStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildRadialChartCard(occRate / 100.0),
                const SizedBox(height: 16),
                _buildStatCards(hotspots, alerts, fullLots),
                const SizedBox(height: 16),
                _buildActionList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadialChartCard(double occupancyRate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        value: occupancyRate * 100,
                        color: const Color(0xFFD32F2F),
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: ((1 - occupancyRate) * 100).clamp(0, 100).toDouble(),
                        color: Colors.grey.shade300,
                        radius: 20,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(occupancyRate * 100).toInt()}%',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const Text('occupied',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('city-centre occupancy now',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatCards(int hotspots, int alerts, int fullLots) {
    return Row(
      children: [
        _statCard('$hotspots', 'hotspots'),
        const SizedBox(width: 12),
        _statCard('$alerts', 'alerts'),
        const SizedBox(width: 12),
        _statCard('$fullLots', 'full lots'),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            _actionTile(
              icon: Icons.location_on,
              title: 'Occupancy map',
              destination: const OccupancyMapScreen(),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _actionTile(
              icon: Icons.warning_amber_rounded,
              title: 'Illegal parking alerts',
              destination: const IllegalParkingScreen(),
              onReturn: _refreshStats,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _actionTile(
              icon: Icons.verified,
              title: 'Legal parking coverage',
              destination: const LegalParkingScreen(),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _actionTile(
              icon: Icons.timeline,
              title: 'Peak-hour analysis',
              destination: const PeakHourScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required Widget destination,
    VoidCallback? onReturn,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A3B5C)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
        // When we come back, refresh stats
        if (onReturn != null) onReturn();
      },
    );
  }
}