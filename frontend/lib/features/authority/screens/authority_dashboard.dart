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

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() {
    // Fetch stats from the Supabase view we created
    _statsFuture = Supabase.instance.client
        .from('authority_dashboard_stats')
        .select()
        .single();
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
            Text('City parking', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Colombo - live overview', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      // The FutureBuilder fetches the data before rendering the UI
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading stats: ${snapshot.error}'));
          }

          // Safely extract data from the view
          final stats = snapshot.data ?? {};
          final double occRate = (stats['occupancy_percentage'] as num?)?.toDouble() ?? 0.0;
          final int alerts = stats['open_alerts'] as int? ?? 0;
          final int fullLots = stats['full_lots'] as int? ?? 0;
          
          // Hotspots is not directly in the DB schema yet, so we mock it
          const int hotspots = 3; 

          return IndexedStack(
            index: _currentIndex,
            children: [
              // Tab 0: Dashboard Content
              _buildDashboardTab(occRate / 100.0, hotspots, alerts, fullLots),
              
              // Tab 1: Occupancy Map
              const OccupancyMapScreen(),
              
              // Tab 2: Demand Reports
              const DemandReportsScreen(),
              
              // Tab 3: Profile
              const ProfileScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
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

  // Extracted the Dashboard body into its own method (Now takes dynamic values)
  Widget _buildDashboardTab(double occupancyRate, int hotspots, int alerts, int fullLots) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildRadialChartCard(occupancyRate),
          const SizedBox(height: 16),
          _buildStatCards(hotspots, alerts, fullLots),
          const SizedBox(height: 16),
          _buildActionList(),
        ],
      ),
    );
  }

  Widget _buildRadialChartCard(double occupancyRate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                        value: (1 - occupancyRate) * 100,
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
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text('occupied', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('city-centre occupancy now', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // 1. Occupancy Map
            ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFF1A3B5C)),
              title: const Text('Occupancy map'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OccupancyMapScreen()),
                );
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            
            // 2. Illegal Parking
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Color(0xFF1A3B5C)),
              title: const Text('Illegal parking alerts'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IllegalParkingScreen()),
                );
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // 3. Legal Parking
            ListTile(
              leading: const Icon(Icons.verified, color: Color(0xFF1A3B5C)),
              title: const Text('Legal parking coverage'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LegalParkingScreen()),
                );
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // 4. Peak Hour Analysis
            ListTile(
              leading: const Icon(Icons.timeline, color: Color(0xFF1A3B5C)),
              title: const Text('Peak-hour analysis'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PeakHourScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}