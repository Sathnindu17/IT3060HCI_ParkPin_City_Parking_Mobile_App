import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DemandReportsScreen extends StatefulWidget {
  const DemandReportsScreen({super.key});

  @override
  State<DemandReportsScreen> createState() => _DemandReportsScreenState();
}

class _DemandReportsScreenState extends State<DemandReportsScreen> {
  late Future<_DemandData> _dataFuture;

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
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
    // Fire all three queries in parallel
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

    // Build a day_num → count map (day_num is 1=Mon … 7=Sun)
    final Map<int, int> dayCounts = {};
    for (final row in demandRows) {
      final int day = (row['day_num'] as num).toInt();
      final int count = (row['booking_count'] as num).toInt();
      dayCounts[day] = count;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Demand reports',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text('Last 30 days',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('${snapshot.error}',
                        textAlign: TextAlign.center),
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

          final data = snapshot.data!;
          final List<int> counts = List.generate(
              7, (i) => data.dayCounts[i + 1] ?? 0);
          final int total = counts.fold<int>(0, (a, b) => a + b);

          // Empty state
          if (total == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.bar_chart, color: Colors.grey, size: 64),
                    SizedBox(height: 16),
                    Text('No booking data available',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text(
                      'Demand reports will appear once bookings are made.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Normalize to 100 for bar heights
          final int maxCount = counts.reduce((a, b) => a > b ? a : b);
          final List<double> normalized = counts
              .map((c) => maxCount == 0 ? 0.0 : (c / maxCount) * 100)
              .toList();

          // Find the busiest days (top 2) for highlighting + label
          final List<int> sortedIdx = List.generate(7, (i) => i)
            ..sort((a, b) => counts[b].compareTo(counts[a]));
          final Set<int> peakIdx = {sortedIdx[0], sortedIdx[1]};
          final String peakLabel =
              'peaks ${_dayLabels[sortedIdx[0]]}–${_dayLabels[sortedIdx[1]]}';

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBarChartCard(counts, normalized, peakIdx, peakLabel,
                      total),
                  const SizedBox(height: 16),
                  _buildSummaryCards(data),
                ],
              ),
            ),
          );
        },
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
              color: Colors.black.withOpacity(0.05),
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
                      color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$total bookings',
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
                    color: Colors.grey.shade200,
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Mon \u2192 Sun \u00b7 $peakLabel',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
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
            padding: const EdgeInsets.all(20),
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
            child: Column(
              children: [
                Text('${data.avgOccupancy.toInt()}%',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                const Text('avg occupancy',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              children: [
                Text(data.busiestZone,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                const Text('busiest zone',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
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