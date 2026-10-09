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

  // ✅ NEW: Check if the same area was reported in the last 5 minutes
  Future<bool> _hasDuplicateReport(String area) async {
    try {
      final fiveMinutesAgo = DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 5))
          .toIso8601String();
      final existing = await Supabase.instance.client
          .from('illegal_parking_reports')
          .select('id')
          .ilike('area', area)
          .gte('created_at', fiveMinutesAgo)
          .limit(1);
      return existing.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _createReport() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _CreateReportDialog(),
    );
    if (result == null) return;

    // ✅ NEW: Duplicate prevention check
    final isDuplicate = await _hasDuplicateReport(result['area']!);
    if (isDuplicate) {
      _showSnack(
        '⚠️ A report for "${result['area']}" already exists (within 5 min)',
        Colors.orange,
      );
      return;
    }

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
      _showSnack('✅ Status updated', Colors.green);
      _refresh();
    } catch (e) {
      _showSnack('❌ $e', Colors.red);
    }
  }

  Future<void> _updateSeverity(dynamic id, String newSeverity) async {
    try {
      await Supabase.instance.client
          .from('illegal_parking_reports')
          .update({'severity': newSeverity})
          .eq('id', id);
      _showSnack('✅ Severity updated', Colors.green);
      _refresh();
    } catch (e) {
      _showSnack('❌ $e', Colors.red);
    }
  }

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

  void _showReportActions(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.report_problem,
                        color: Color(0xFFF57C00), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report['area'] ?? 'Report',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3B5C))),
                        const SizedBox(height: 2),
                        Text(report['description'] ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F3F7)),
            _sheetAction(Icons.check_circle, 'Mark as Resolved', Colors.green,
                () {
              Navigator.pop(context);
              _updateStatus(report['id'], 'resolved');
            }),
            _sheetAction(Icons.gavel, 'Mark as Enforced',
                const Color(0xFF1A3B5C), () {
              Navigator.pop(context);
              _updateStatus(report['id'], 'enforced');
            }),
            _sheetAction(Icons.arrow_upward, 'Increase Severity', Colors.orange,
                () {
              Navigator.pop(context);
              final c = report['severity'] ?? 'med';
              _updateSeverity(report['id'], c == 'low' ? 'med' : 'high');
            }),
            _sheetAction(Icons.arrow_downward, 'Decrease Severity',
                const Color(0xFF1A3B5C), () {
              Navigator.pop(context);
              final c = report['severity'] ?? 'med';
              _updateSeverity(report['id'], c == 'high' ? 'med' : 'low');
            }),
            const Divider(height: 1, color: Color(0xFFF0F3F7)),
            _sheetAction(Icons.delete_outline, 'Delete Report', Colors.red, () {
              Navigator.pop(context);
              _deleteReport(report['id']);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Illegal parking reports',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refresh),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReport,
        backgroundColor: const Color(0xFFEAA22F),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Report',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorView('${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _emptyView();
          }

          final reports = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('All reports',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3B5C))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EDF2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${reports.length} total',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1A3B5C),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: reports.length,
                    itemBuilder: (context, i) {
                      final r = reports[i];
                      return Dismissible(
                        key: Key(r['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.only(right: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete,
                              color: Colors.white, size: 28),
                        ),
                        onDismissed: (_) => _deleteReport(r['id']),
                        child: GestureDetector(
                          onTap: () => _showReportActions(r),
                          child: _ReportCard(
                            report: r,
                            time:
                                '${_formatTime(r['created_at'] as String?)} · ${r['description'] ?? ''}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _errorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline,
                  color: Color(0xFFD32F2F), size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Failed to load',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAA22F),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12)),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline,
                color: Color(0xFF2E7D32), size: 48),
          ),
          const SizedBox(height: 20),
          const Text('No reports yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3B5C))),
          const SizedBox(height: 6),
          const Text('Tap + to add your first report',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final String time;
  const _ReportCard({required this.report, required this.time});

  @override
  Widget build(BuildContext context) {
    final severity = (report['severity'] ?? 'med').toString().toLowerCase();
    final status = (report['status'] ?? 'open').toString().toLowerCase();

    Color sevBg, sevFg;
    IconData icon;
    switch (severity) {
      case 'high':
        icon = Icons.warning_amber_rounded;
        sevBg = const Color(0xFFFFEBEE);
        sevFg = const Color(0xFFD32F2F);
        break;
      case 'med':
        icon = Icons.warning_amber_rounded;
        sevBg = const Color(0xFFFFF3E0);
        sevFg = const Color(0xFFF57C00);
        break;
      default:
        icon = Icons.info_outline;
        sevBg = const Color(0xFFE8EDF2);
        sevFg = Colors.grey.shade700;
    }

    Color stBg, stFg;
    switch (status) {
      case 'resolved':
        stBg = const Color(0xFFE8F5E9);
        stFg = const Color(0xFF2E7D32);
        break;
      case 'enforced':
        stBg = const Color(0xFFEDE7F6);
        stFg = const Color(0xFF5E35B1);
        break;
      default:
        stBg = const Color(0xFFE3F2FD);
        stFg = const Color(0xFF1976D2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sevBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: sevFg, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report['area'] ?? 'Unknown',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3B5C))),
                    const SizedBox(height: 2),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sevBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(severity,
                    style: TextStyle(
                        color: sevFg,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status.toUpperCase(),
                    style: TextStyle(
                        color: stFg,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// CREATE Dialog (with validations)
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: const Text('New Report',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF1A3B5C))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _areaController,
              decoration: InputDecoration(
                labelText: 'Area / Location *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descController,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _severity,
              decoration: InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
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
            child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEAA22F),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 10),
          ),
          onPressed: () {
            // ✅ Validation 1: Area required
            final area = _areaController.text.trim();
            if (area.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Area / Location is required'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            // ✅ Validation 2: Minimum length
            if (area.length < 3) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Area must be at least 3 characters'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            // ✅ Validation 3: Description length
            final desc = _descController.text.trim();
            if (desc.length > 500) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Description cannot exceed 500 characters'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            Navigator.pop(context, {
              'area': area,
              'description': desc,
              'severity': _severity,
            });
          },
          child: const Text('Create',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}