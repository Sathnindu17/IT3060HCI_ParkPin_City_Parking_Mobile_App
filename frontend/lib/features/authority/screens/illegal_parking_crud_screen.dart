import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IllegalParkingCrudScreen extends StatefulWidget {
  const IllegalParkingCrudScreen({super.key});

  @override
  State<IllegalParkingCrudScreen> createState() =>
      _IllegalParkingCrudScreenState();
}

class _IllegalParkingCrudScreenState extends State<IllegalParkingCrudScreen> {
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

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ============================================
  // CREATE
  // ============================================
  Future<void> _createReport() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _CreateReportDialog(),
    );
    if (result == null) return;

    try {
      await Supabase.instance.client.from('illegal_parking_reports').insert({
        'area': result['area'],
        'description': result['description'],
        'severity': result['severity'],
        'status': 'open',
        'reported_by': Supabase.instance.client.auth.currentUser?.id,
      });
      _showSnack('✅ Report created', Colors.green);
      _refresh();
    } catch (e) {
      _showSnack('❌ $e', Colors.red);
    }
  }

  // ============================================
  // UPDATE — status
  // ============================================
  Future<void> _updateStatus(dynamic id, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('illegal_parking_reports')
          .update({
            'status': newStatus,
            if (newStatus != 'open')
              'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      _showSnack('✅ Status updated to $newStatus', Colors.green);
      _refresh();
    } catch (e) {
      _showSnack('❌ $e', Colors.red);
    }
  }

  // ============================================
  // UPDATE — severity
  // ============================================
  Future<void> _updateSeverity(dynamic id, String newSeverity) async {
    try {
      await Supabase.instance.client
          .from('illegal_parking_reports')
          .update({'severity': newSeverity})
          .eq('id', id);
      _showSnack('✅ Severity updated to $newSeverity', Colors.green);
      _refresh();
    } catch (e) {
      _showSnack('❌ $e', Colors.red);
    }
  }

  // ============================================
  // DELETE
  // ============================================
  Future<void> _deleteReport(dynamic id) async {
    try {
      await Supabase.instance.client
          .from('illegal_parking_reports')
          .delete()
          .eq('id', id);
      _showSnack('✅ Report deleted', Colors.green);
      _refresh();
    } catch (e) {
      _showSnack('❌ $e', Colors.red);
    }
  }

  // Bottom sheet for individual report actions
  void _showReportActions(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                report['area'] ?? 'Report',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Mark as Resolved'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(report['id'], 'resolved');
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel, color: Color(0xFF1A3B5C)),
              title: const Text('Mark as Enforced'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(report['id'], 'enforced');
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.orange),
              title: const Text('Increase Severity'),
              onTap: () {
                Navigator.pop(context);
                final current = report['severity'] ?? 'med';
                final next = current == 'low'
                    ? 'med'
                    : (current == 'med' ? 'high' : 'high');
                _updateSeverity(report['id'], next);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.arrow_downward, color: Color(0xFF1A3B5C)),
              title: const Text('Decrease Severity'),
              onTap: () {
                Navigator.pop(context);
                final current = report['severity'] ?? 'med';
                final next = current == 'high'
                    ? 'med'
                    : (current == 'med' ? 'low' : 'low');
                _updateSeverity(report['id'], next);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Report',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteReport(report['id']);
              },
            ),
            const SizedBox(height: 8),
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
        title: FutureBuilder<List<Map<String, dynamic>>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            final count = snapshot.data?.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Illegal parking reports',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('$count reports · tap to manage',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReport,
        backgroundColor: const Color(0xFFEAA22F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Report',
            style: TextStyle(color: Colors.white)),
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
                  Text('No reports. Tap + to add one.',
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Dismissible(
                  key: Key(report['id'].toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.delete, color: Colors.white, size: 32),
                  ),
                  onDismissed: (_) => _deleteReport(report['id']),
                  child: GestureDetector(
                    onTap: () => _showReportActions(report),
                    child: _ReportItem(
                      location: report['area'] ?? 'Unknown',
                      time:
                          '${_formatTime(report['created_at'] as String?)} · ${report['description'] ?? ''}',
                      severity: report['severity'] ?? 'med',
                      status: report['status'] ?? 'open',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ============================================
// CREATE Dialog
// ============================================
class _CreateReportDialog extends StatefulWidget {
  const _CreateReportDialog();

  @override
  State<_CreateReportDialog> createState() => _CreateReportDialogState();
}

class _CreateReportDialogState extends State<_CreateReportDialog> {
  final _areaController = TextEditingController();
  final _descController = TextEditingController();
  String _severity = 'med';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Illegal Parking Report'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Area / Location *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _severity,
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'med', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged: (v) => setState(() => _severity = v ?? 'med'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAA22F)),
          onPressed: () {
            if (_areaController.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'area': _areaController.text.trim(),
              'description': _descController.text.trim(),
              'severity': _severity,
            });
          },
          child: const Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ============================================
// Report Item
// ============================================
class _ReportItem extends StatelessWidget {
  final String location;
  final String time;
  final String severity;
  final String status;

  const _ReportItem({
    required this.location,
    required this.time,
    required this.severity,
    required this.status,
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

    Color statusBg, statusFg;
    switch (status.toLowerCase()) {
      case 'resolved':
        statusBg = Colors.green.shade50;
        statusFg = Colors.green.shade700;
        break;
      case 'enforced':
        statusBg = Colors.purple.shade50;
        statusFg = Colors.purple.shade700;
        break;
      default:
        statusBg = Colors.blue.shade50;
        statusFg = Colors.blue.shade700;
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusFg),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        severity.toLowerCase(),
                        style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}