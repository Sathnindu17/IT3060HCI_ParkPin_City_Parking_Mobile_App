import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/report_exporter.dart';

class DemandReportsScreen extends StatefulWidget {
  const DemandReportsScreen({super.key});

  @override
  State<DemandReportsScreen> createState() => _DemandReportsScreenState();
}

class _DemandReportsScreenState extends State<DemandReportsScreen> {
  late Future<_DemandData> _dataFuture;
  bool _isExporting = false;

  static const List<String> _dayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _dataFuture = _loadAll();
  }

  Future<_DemandData> _loadAll() async {
    final results = await Future.wait<dynamic>([
      Supabase.instance.client.from('authority_demand_by_day').select(),
      Supabase.instance.client
          .from('authority_busiest_zone')
          .select()
          .maybeSingle(),
      Supabase.instance.client
          .from('authority_dashboard_stats')
          .select()
          .single(),
    ]);

    final demandRows = results[0] as List<dynamic>;
    final busiest = results[1] as Map<String, dynamic>?;
    final stats = results[2] as Map<String, dynamic>;

    final Map<int, int> dayCounts = {};
    for (final row in demandRows) {
      final r = row as Map<String, dynamic>;
      final int? day = (r['day_num'] as num?)?.toInt();
      final int? count = (r['booking_count'] as num?)?.toInt();
      if (day != null && count != null) {
        dayCounts[day] = count;
      }
    }

    return _DemandData(
      dayCounts: dayCounts,
      busiestZone: busiest?['zone_name']?.toString() ?? 'No data yet',
      avgOccupancy:
          (stats['occupancy_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<void> _refresh() async {
    setState(() => _fetchData());
    await _dataFuture;
  }

  // ============================================
  // EXPORT PDF
  // ============================================
  Future<void> _exportReport(_DemandData data) async {
    setState(() => _isExporting = true);
    try {
      final List<int> counts =
          List.generate(7, (i) => data.dayCounts[i + 1] ?? 0);
      final int total = counts.fold<int>(0, (a, b) => a + b);

      await ReportExporter.exportDemandReport(
        dayCounts: data.dayCounts,
        dayLabels: _dayLabels,
        total: total,
        busiestZone: data.busiestZone,
        avgOccupancy: data.avgOccupancy,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Report downloaded'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _handleExportTap() {
    _dataFuture.then((data) {
      final hasData = data.dayCounts.values.any((v) => v > 0);
      if (hasData) {
        _exportReport(data);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Demand reports',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          // ---- Export button ----
          IconButton(
            tooltip: 'Export PDF',
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: _isExporting ? null : _handleExportTap,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<_DemandData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildError('${snapshot.error}');
          }

          final data = snapshot.data!;
          final List<int> counts =
              List.generate(7, (i) => data.dayCounts[i + 1] ?? 0);
          final int total = counts.fold<int>(0, (a, b) => a + b);

          if (total == 0) {
            return _buildEmpty();
          }

          final int maxCount = counts.reduce((a, b) => a > b ? a : b);
          final List<double> normalized = counts
              .map((c) => maxCount == 0 ? 0.0 : (c / maxCount) * 100)
              .toList();

          final List<int> sortedIdx = List.generate(7, (i) => i)
            ..sort((a, b) => counts[b].compareTo(counts[a]));
          final Set<int> peakIdx = {sortedIdx[0], sortedIdx[1]};
          final String peakLabel =
              'Peaks ${_dayLabels[sortedIdx[0]]}–${_dayLabels[sortedIdx[1]]}';

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Header Row with Export CTA ----
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Weekly demand',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3B5C))),
                            SizedBox(height: 6),
                            Text('Booking patterns across the last 30 days.',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                      // Export pill button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isExporting ? null : _handleExportTap,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAA22F),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFEAA22F)
                                        .withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isExporting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.download_outlined,
                                        color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                const Text('PDF',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildBarChartCard(
                      counts, normalized, peakIdx, peakLabel, total),
                  const SizedBox(height: 20),
                  _sectionHeader('SUMMARY'),
                  const SizedBox(height: 12),
                  _buildSummaryCards(data),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text('ParkPin Authority · v1.0',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey)),
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

  Widget _sectionHeader(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.5));

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
                  color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline,
                  color: Color(0xFFD32F2F), size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Failed to load reports',
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

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: Color(0xFFE8EDF2), shape: BoxShape.circle),
              child: const Icon(Icons.bar_chart,
                  color: Color(0xFF1A3B5C), size: 48),
            ),
            const SizedBox(height: 20),
            const Text('No booking data yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3B5C))),
            const SizedBox(height: 6),
            const Text(
              'Demand reports will appear once bookings are made.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(
    List<int> counts,
    List<double> normalized,
    Set<int> peakIdx,
    String peakLabel,
    int total,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Occupancy by day',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3B5C))),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDF2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$total total',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5C))),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final count = counts[group.x];
                      return BarTooltipItem(
                        '$count bookings',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        final isPeak = peakIdx.contains(idx);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _dayLabels[idx],
                            style: TextStyle(
                              color: isPeak
                                  ? const Color(0xFF1A3B5C)
                                  : Colors.grey,
                              fontSize: 11,
                              fontWeight: isPeak
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFFF0F3F7),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final isPeak = peakIdx.contains(i);
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: normalized[i],
                        color: isPeak
                            ? const Color(0xFF1A3B5C)
                            : const Color(0xFFDCE6F2),
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDF2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Mon \u2192 Sun · $peakLabel',
                style: const TextStyle(
                    color: Color(0xFF1A3B5C),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(_DemandData data) {
    return Row(
      children: [
        Expanded(
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
                    color: const Color(0xFFE8EDF2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.analytics_outlined,
                      color: Color(0xFF1A3B5C), size: 18),
                ),
                const SizedBox(height: 12),
                Text('${data.avgOccupancy.toInt()}%',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5C))),
                const SizedBox(height: 2),
                const Text('Avg occupancy',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
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
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_fire_department,
                      color: Color(0xFFF57C00), size: 18),
                ),
                const SizedBox(height: 12),
                Text(data.busiestZone,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5C))),
                const SizedBox(height: 2),
                const Text('Busiest zone',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DemandData {
  final Map<int, int> dayCounts;
  final String busiestZone;
  final double avgOccupancy;

  _DemandData({
    required this.dayCounts,
    required this.busiestZone,
    required this.avgOccupancy,
  });
}