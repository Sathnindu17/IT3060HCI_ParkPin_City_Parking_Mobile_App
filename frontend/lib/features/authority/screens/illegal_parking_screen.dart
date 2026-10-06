import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IllegalParkingScreen extends StatefulWidget {
  const IllegalParkingScreen({super.key});

  @override
  State<IllegalParkingScreen> createState() => _IllegalParkingScreenState();
}

class _IllegalParkingScreenState extends State<IllegalParkingScreen> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  void _fetchReports() {
    _reportsFuture = Supabase.instance.client
        .from('illegal_parking_reports')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false);
  }

  // Helper method to format the timestamp
  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        iconTheme: const IconThemeData(color: Colors.white),
        title: FutureBuilder<List<Map<String, dynamic>>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            int count = 0;
            if (snapshot.hasData) {
              count = snapshot.data!.length;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Illegal parking', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('$count active reports', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // List of Reports
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No active reports found.'));
                }

                final reports = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final String timeStr = _formatTime(report['created_at']);
                    final String desc = report['description'] ?? 'Violation';
                    
                    return _ReportItem(
                      location: report['area'] ?? 'Unknown Area',
                      time: '$timeStr - $desc',
                      severity: report['severity'] ?? 'med',
                    );
                  },
                );
              },
            ),
          ),
          
          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  // Update all open reports to 'enforced'
                  try {
                    await Supabase.instance.client
                        .from('illegal_parking_reports')
                        .update({
                          'status': 'enforced',
                          'resolved_at': DateTime.now().toIso8601String(),
                        })
                        .eq('status', 'open');

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enforcement prioritised! All open reports updated.')),
                      );
                      // Refresh the list to show empty state
                      setState(() {
                        _fetchReports();
                      });
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating reports: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAA22F), // Yellow
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Prioritise enforcement',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for each report item
class _ReportItem extends StatelessWidget {
  final String location;
  final String time;
  final String severity;

  const _ReportItem({
    required this.location,
    required this.time,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    // Determine icon and badge colors based on severity
    IconData icon;
    Color iconColor;
    Color badgeBgColor;
    Color badgeTextColor;

    switch (severity.toLowerCase()) {
      case 'high':
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFD32F2F); // Red
        badgeBgColor = const Color(0xFFFFEBEE);
        badgeTextColor = const Color(0xFFD32F2F);
        break;
      case 'med':
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFF57C00); // Orange
        badgeBgColor = const Color(0xFFFFF3E0);
        badgeTextColor = const Color(0xFFF57C00);
        break;
      default: // low
        icon = Icons.info_outline;
        iconColor = Colors.grey;
        badgeBgColor = Colors.grey.shade200;
        badgeTextColor = Colors.grey.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity Icon
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          
          // Location and Time Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          
          // Severity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(20)),
            child: Text(
              severity.toLowerCase(),
              style: TextStyle(color: badgeTextColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}