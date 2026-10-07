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

  Future<void> _refresh() async {
    setState(() => _fetchReports());
    await _reportsFuture;
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '--:--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
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
            final count = snapshot.data?.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Illegal parking alerts',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('$count active reports',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 64),
                  SizedBox(height: 16),
                  Text('No active reports.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final reports = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return _ReportItem(
                  location: report['area'] ?? 'Unknown',
                  time:
                      '${_formatTime(report['created_at'] as String?)} - ${report['description'] ?? ''}',
                  severity: report['severity'] ?? 'med',
                );
              },
            ),
          );
        },
      ),
    );
  }
}

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
    IconData icon;
    Color iconColor, badgeBgColor, badgeTextColor;
    switch (severity.toLowerCase()) {
      case 'high':
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFD32F2F);
        badgeBgColor = const Color(0xFFFFEBEE);
        badgeTextColor = const Color(0xFFD32F2F);
        break;
      case 'med':
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFF57C00);
        badgeBgColor = const Color(0xFFFFF3E0);
        badgeTextColor = const Color(0xFFF57C00);
        break;
      default:
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(time,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: badgeBgColor, borderRadius: BorderRadius.circular(20)),
            child: Text(severity.toLowerCase(),
                style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}