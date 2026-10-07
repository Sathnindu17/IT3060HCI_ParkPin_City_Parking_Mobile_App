import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PeakHourScreen extends StatefulWidget {
  const PeakHourScreen({super.key});

  @override
  State<PeakHourScreen> createState() => _PeakHourScreenState();
}

class _PeakHourScreenState extends State<PeakHourScreen> {
  late Future<List<Map<String, dynamic>>> _dataFuture;

  static const List<String> _bucketLabels = [
    '8a',
    '10a',
    '12p',
    '2p',
    '4p',
    '6p',
  ];

  static const List<List<int>> _bucketRanges = [
    [6, 9],
    [9, 11],
    [11, 13],
    [13, 15],
    [15, 17],
    [17, 19],
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _dataFuture = Supabase.instance.client
        .from('authority_peak_hours')
        .select()
        .order('hour_of_day', ascending: true);
  }

  Future<void> _refresh() async {
    setState(() => _fetchData());
    await _dataFuture;
  }

  Map<String, dynamic> _processData(List<Map<String, dynamic>> raw) {
    final Map<int, int> hourCounts = {};
    for (final row in raw) {
      final hour = (row['hour_of_day'] as num?)?.toInt() ?? 0;
      final count = (row['booking_count'] as num?)?.toInt() ?? 0;
      hourCounts[hour] = count;
    }

    final List<int> bucketCounts = [];
    for (final range in _bucketRanges) {
      int sum = 0;
      for (int h = range[0]; h < range[1]; h++) {
        sum += hourCounts[h] ?? 0;
      }
      bucketCounts.add(sum);
    }

    int peakIndex = 0;
    int peakValue = 0;
    for (int i = 0; i < bucketCounts.length; i++) {
      if (bucketCounts[i] > peakValue) {
        peakValue = bucketCounts[i];
        peakIndex = i;
      }
    }

    final int maxCount = bucketCounts.isEmpty
        ? 1
        : bucketCounts.reduce((a, b) => a > b ? a : b);
    final List<double> normalised = bucketCounts
        .map((c) => maxCount == 0 ? 0.0 : (c / maxCount) * 100.0)
        .toList();

    return {
      'counts': bucketCounts,
      'normalised': normalised,
      'peakIndex': peakIndex,
      'peakValue': peakValue,
      'total': bucketCounts.fold<int>(0, (a, b) => a + b),
    };
  }

  String _peakWindowLabel(int peakIndex) {
    const labels = [
      '6 AM – 9 AM',
      '9 AM – 11 AM',
      '11 AM – 1 PM',
      '1 PM – 3 PM',
      '3 PM – 5 PM',
      '5 PM – 7 PM'
    ];
    return labels[peakIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3B5C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Peak-hour analysis',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorView('${snapshot.error}');
          }

          final raw = snapshot.data ?? [];
          final processed = _processData(raw);
          final List<int> counts = processed['counts'];
          final List<double> normalised = processed['normalised'];
          final int peakIndex = processed['peakIndex'];
          final int peakValue = processed['peakValue'];
          final int total = processed['total'];

          if (total == 0) {
            return _emptyView();
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hourly analysis',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3B5C))),
                  const SizedBox(height: 6),
                  const Text(
                      'Average occupancy across the day.',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 24),
                  _buildBarChartCard(counts, normalised, peakIndex),
                  const SizedBox(height: 20),
                  _sectionHeader('PEAK WINDOW'),
                  const SizedBox(height: 12),
                  _buildPeakWindowCard(peakIndex, peakValue),
                  const SizedBox(height: 20),
                  _sectionHeader('SUMMARY'),
                  const SizedBox(height: 12),
                  _buildSummaryCard(total),
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
            const Text('Failed to load analysis',
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
            const Text('No peak-hour data',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3B5C))),
            const SizedBox(height: 6),
            const Text(
                'Analysis will appear once bookings are made.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(
      List<int> counts, List<double> normalised, int peakIndex) {
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
          const Text('Avg occupancy by hour',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3B5C))),
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
                        if (idx < 0 || idx >= _bucketLabels.length) {
                          return const SizedBox.shrink();
                        }
                        final isPeak = idx == peakIndex;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _bucketLabels[idx],
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
                barGroups: List.generate(normalised.length, (i) {
                  final isPeak = i == peakIndex;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: normalised[i],
                        color: isPeak
                            ? const Color(0xFF1A3B5C)
                            : const Color(0xFFDCE6F2),
                        width: 22,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakWindowCard(int peakIndex, int peakValue) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.access_time,
                color: Color(0xFFF57C00), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_peakWindowLabel(peakIndex),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5C))),
                const SizedBox(height: 4),
                Text(
                  peakValue > 0
                      ? 'Route officers here · $peakValue bookings'
                      : 'Route officers here',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('PEAK',
                style: TextStyle(
                    color: Color(0xFFF57C00),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int total) {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDF2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_available_outlined,
                      color: Color(0xFF1A3B5C), size: 18),
                ),
                const SizedBox(height: 12),
                Text('$total',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5C))),
                const SizedBox(height: 2),
                const Text('Total bookings',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
              width: 1, height: 60, color: const Color(0xFFF0F3F7)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.schedule,
                      color: Color(0xFF2E7D32), size: 18),
                ),
                const SizedBox(height: 12),
                Text('${_bucketLabels.length}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5C))),
                const SizedBox(height: 2),
                const Text('Time slots',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}