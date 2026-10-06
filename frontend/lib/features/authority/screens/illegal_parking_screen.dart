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
      final dateTime = DateTime.parse(isoString).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '--:--';
    }
  }

  Future<void> _resolveSingleReport(dynamic reportId) async {
    try {
      await Supabase.instance.client
          .from('illegal_parking_reports')
          .update({
            'status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Report marked as resolved'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _fetchReports());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _prioritiseAll() async {
    try {
      await Supabase.instance.client
          .from('illegal_parking_reports')
          .update({
            'status': 'enforced',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('status', 'open');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Enforcement prioritised! All reports updated.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _fetchReports());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
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
                const Text('Illegal parking',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text('$count active reports',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _reportsFuture,
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
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 64),
                        SizedBox(height: 16),
                        Text('All clear! No active reports.',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                      final timeStr = _formatTime(report['created_at'] as String?);
                      final desc = report['description'] ?? 'Violation';

                      return Dismissible(
                        key: Key(report['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.only(right: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 32),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Mark as resolved?'),
                              content: Text(
                                  'Resolve report at ${report['area']}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Resolve',
                                      style: TextStyle(color: Colors.green)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => _resolveSingleReport(report['id']),
                        child: _ReportItem(
                          location: report['area'] ?? 'Unknown Area',
                          time: '$timeStr - $desc',
                          severity: report['severity'] ?? 'med',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _prioritiseAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAA22F),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Prioritise enforcement',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
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
    Color iconColor;
    Color badgeBgColor;
    Color badgeTextColor;

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
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: badgeBgColor, borderRadius: BorderRadius.circular(20)),
            child: Text(
              severity.toLowerCase(),
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