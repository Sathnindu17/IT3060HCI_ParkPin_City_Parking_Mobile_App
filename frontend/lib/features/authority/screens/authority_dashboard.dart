import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'occupancy_map_screen.dart';
import 'illegal_parking_screen.dart';         // Read-only
import 'illegal_parking_crud_screen.dart';   // CRUD (NEW)
import 'demand_reports_screen.dart';
import 'profile_screen.dart';
import 'legal_parking_screen.dart';           // Read-only
import 'legal_parking_crud_screen.dart';     // CRUD (NEW)
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
    _realtimeChannel = Supabase.instance.client
        .channel('dashboard_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'illegal_parking_reports',
          callback: (payload) {
            if (mounted) setState(() => _fetchStats());
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'legal_parking_zones',
          callback: (payload) {
            if (mounted) setState(() => _fetchStats());
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
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
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
          _buildDashboardTab(),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Reports'),
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
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Failed to load stats',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshStats,
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

        final stats = snapshot.data ?? {};
        final double occRate =
            (stats['occupancy_percentage'] as num?)?.toDouble() ?? 0.0;
        final int alerts = stats['open_alerts'] as int? ?? 0;
        final int fullLots = stats['full_lots'] as int? ?? 0;
        const int hotspots = 3;

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
                _buildViewSection(),
                const SizedBox(height: 16),
                _buildCrudSection(),
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
                        value: ((1 - occupancyRate) * 100)
                            .clamp(0, 100)
                            .toDouble(),
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
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ============================================
  // VIEW-ONLY SECTION
  // ============================================
  Widget _buildViewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('VIEWS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2)),
        ),
        Container(
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
                  subtitle: 'Live congestion hotspots on map',
                  destination: const OccupancyMapScreen(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _actionTile(
                  icon: Icons.warning_amber_rounded,
                  title: 'Illegal parking alerts',
                  subtitle: 'Read-only view of open alerts',
                  destination: const IllegalParkingScreen(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _actionTile(
                  icon: Icons.verified,
                  title: 'Legal parking coverage',
                  subtitle: 'Read-only verified facilities list',
                  destination: const LegalParkingScreen(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _actionTile(
                  icon: Icons.timeline,
                  title: 'Peak-hour analysis',
                  subtitle: 'Average occupancy by hour',
                  destination: const PeakHourScreen(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // CRUD SECTION
  // ============================================
  Widget _buildCrudSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('MANAGE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2)),
        ),
        Container(
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
                  icon: Icons.report_problem,
                  title: 'Illegal parking reports',
                  subtitle: 'Create, edit, resolve & delete reports',
                  destination: const IllegalParkingCrudScreen(),
                  onReturn: _refreshStats,
                  isCrud: true,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _actionTile(
                  icon: Icons.location_city,
                  title: 'Legal parking zones',
                  subtitle: 'Create, edit & delete verified zones',
                  destination: const LegalParkingCrudScreen(),
                  onReturn: _refreshStats,
                  isCrud: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required Widget destination,
    String? subtitle,
    VoidCallback? onReturn,
    bool isCrud = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isCrud
              ? const Color(0xFFEAA22F).withOpacity(0.15)
              : const Color(0xFF1A3B5C).withOpacity(0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isCrud ? const Color(0xFFEAA22F) : const Color(0xFF1A3B5C),
          size: 22,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (isCrud)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEAA22F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'MANAGE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
        if (onReturn != null) onReturn();
      },
    );
  }
}