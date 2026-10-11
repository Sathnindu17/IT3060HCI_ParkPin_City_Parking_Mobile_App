import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'occupancy_map_screen.dart';
import 'illegal_parking_screen.dart';
import 'illegal_parking_crud_screen.dart';
import 'demand_reports_screen.dart';
import 'profile_screen.dart';
import 'legal_parking_screen.dart';
import 'legal_parking_crud_screen.dart';
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
    _fetchHotspots();
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

  late Future<int> _hotspotsFuture;

void _fetchHotspots() {
  _hotspotsFuture = Supabase.instance.client
      .from('authority_hotspot_count')
      .select()
      .single()
      .then((row) => (row['hotspots'] as num?)?.toInt() ?? 0);
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(
            statsFuture: _statsFuture,
            onRefresh: _refreshStats,
          ),
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
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// ============================================
// Dashboard Tab
// ============================================
class _DashboardTab extends StatelessWidget {
  final Future<Map<String, dynamic>> statsFuture;
  final Future<void> Function() onRefresh;

  const _DashboardTab({
    required this.statsFuture,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('City parking',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text('Colombo · Live overview',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
  IconButton(
    icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
    onPressed: onRefresh,
  ),
],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final stats = snapshot.data ?? {};
          final double occRate =
              (stats['occupancy_percentage'] as num?)?.toDouble() ?? 0.0;
          final int alerts = stats['open_alerts'] as int? ?? 0;
          final int fullLots = stats['full_lots'] as int? ?? 0;
          final int hotspots = stats['hotspots'] as int? ?? 0;

          return RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live overview',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5C)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Real-time status of city parking facilities.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  _buildRadialChartCard(occRate / 100.0),
                  const SizedBox(height: 16),
                  _buildStatCards(hotspots, alerts, fullLots),
                  const SizedBox(height: 28),
                  _buildSectionHeader('VIEWS', 'Read-only insights'),
                  const SizedBox(height: 12),
                  _buildViewSection(context),
                  const SizedBox(height: 28),
                  _buildSectionHeader('MANAGE', 'Full CRUD operations'),
                  const SizedBox(height: 12),
                  _buildCrudSection(context, onRefresh),
                  const SizedBox(height: 30),
                  const Center(
                    child: Text(
                      'ParkPin Authority · v1.0',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: Color(0xFFD32F2F), size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Failed to load stats',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAA22F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Uses Flexible to prevent overflow
  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.5)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
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
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 55,
                    sections: [
                      PieChartSectionData(
                        value: occupancyRate * 100,
                        color: const Color(0xFFD32F2F),
                        radius: 18,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: ((1 - occupancyRate) * 100)
                            .clamp(0, 100)
                            .toDouble(),
                        color: const Color(0xFFE8EDF2),
                        radius: 18,
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
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3B5C)),
                    ),
                    const Text('occupied',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDF2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('City-centre occupancy now',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1A3B5C),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(int hotspots, int alerts, int fullLots) {
    return Row(
      children: [
        _statCard('$hotspots', 'Hotspots', Icons.local_fire_department,
            const Color(0xFFD32F2F)),
        const SizedBox(width: 12),
        _statCard('$alerts', 'Alerts', Icons.warning_amber_rounded,
            const Color(0xFFF57C00)),
        const SizedBox(width: 12),
        _statCard('$fullLots', 'Full lots', Icons.car_crash,
            const Color(0xFF1A3B5C)),
      ],
    );
  }

  Widget _statCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3B5C))),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSection(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            _actionTile(
              context: context,
              icon: Icons.location_on_outlined,
              title: 'Occupancy map',
              subtitle: 'Live congestion hotspots on map',
              destination: const OccupancyMapScreen(),
            ),
            _divider(),
            _actionTile(
              context: context,
              icon: Icons.warning_amber_rounded,
              title: 'Illegal parking alerts',
              subtitle: 'Read-only view of open alerts',
              destination: const IllegalParkingScreen(),
            ),
            _divider(),
            _actionTile(
              context: context,
              icon: Icons.verified_outlined,
              title: 'Legal parking coverage',
              subtitle: 'Verified facilities list',
              destination: const LegalParkingScreen(),
            ),
            _divider(),
            _actionTile(
              context: context,
              icon: Icons.timeline_outlined,
              title: 'Peak-hour analysis',
              subtitle: 'Average occupancy by hour',
              destination: const PeakHourScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrudSection(
      BuildContext context, Future<void> Function() onRefresh) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            _actionTile(
              context: context,
              icon: Icons.report_problem_outlined,
              title: 'Illegal parking reports',
              subtitle: 'Create, edit, resolve & delete',
              destination: const IllegalParkingCrudScreen(),
              onReturn: onRefresh,
              isCrud: true,
            ),
            _divider(),
            _actionTile(
              context: context,
              icon: Icons.location_city_outlined,
              title: 'Legal parking zones',
              subtitle: 'Create, edit & delete verified zones',
              destination: const LegalParkingCrudScreen(),
              onReturn: onRefresh,
              isCrud: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, indent: 72, endIndent: 16, color: Color(0xFFF0F3F7));

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget destination,
    String? subtitle,
    VoidCallback? onReturn,
    bool isCrud = false,
  }) {
    final accentColor =
        isCrud ? const Color(0xFFEAA22F) : const Color(0xFF1A3B5C);
    return InkWell(
      onTap: () async {
        await Navigator.push(
            context, MaterialPageRoute(builder: (_) => destination));
        if (onReturn != null) onReturn();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A3B5C)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                      ),
                      if (isCrud)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('MANAGE',
                              style: TextStyle(
                                  color: Color(0xFFF57C00),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
                        ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}