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

  // Six time-bucket labels matching the UI design
  static const List<String> _bucketLabels = [
    '8a',
    '10a',
    '12p',
    '2p',
    '4p',
    '6p',
  ];

  // Corresponding hour ranges for each bucket
  static const List<List<int>> _bucketRanges = [
    [6, 9],   // 8a   → hours 6-8
    [9, 11],  // 10a  → hours 9-10
    [11, 13], // 12p  → hours 11-12
    [13, 15], // 2p   → hours 13-14
    [15, 17], // 4p   → hours 15-16
    [17, 19], // 6p   → hours 17-18
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

  /// Buckets the raw hourly counts into 6 time slots.
  /// Returns a list of (label, count) tuples and the peak slot.
  Map<String, dynamic> _processData(List<Map<String, dynamic>> raw) {
    // Build a map: hour → count
    final Map<int, int> hourCounts = {};
    for (final row in raw) {
      final hour = (row['hour_of_day'] as num?)?.toInt() ?? 0;
      final count = (row['booking_count'] as num?)?.toInt() ?? 0;
      hourCounts[hour] = count;
    }

    // Sum into buckets
    final List<int> bucketCounts = [];
    for (final range in _bucketRanges) {
      int sum = 0;
      for (int h = range[0]; h < range[1]; h++) {
        sum += hourCounts[h] ?? 0;
      }
      bucketCounts.add(sum);
    }

    // Find peak bucket
    int peakIndex = 0;
    int peakValue = 0;
    for (int i = 0; i < bucketCounts.length; i++) {
      if (bucketCounts[i] > peakValue) {
        peakValue = bucketCounts[i];
        peakIndex = i;
      }
    }

    // Normalise to 0-100 for bar heights
    final int maxCount =
        bucketCounts.isEmpty ? 1 : bucketCounts.reduce((a, b) => a > b ? a : b);
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
    // Return a readable range label based on the bucket index
    const labels = ['6 AM – 9 AM', '9 AM – 11 AM', '11 AM – 1 PM',
                    '1 PM – 3 PM', '3 PM – 5 PM', '5 PM – 7 PM'];
    return labels[peakIndex];
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
            Text('Peak-hour analysis',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text('Avg occupancy by hour',
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
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

          final raw = snapshot.data ?? [];
          final processed = _processData(raw);
          final List<int> counts = processed['counts'];
          final List<double> normalised = processed['normalised'];
          final int peakIndex = processed['peakIndex'];
          final int peakValue = processed['peakValue'];
          final int total = processed['total'];

          // If there is no data at all
          if (total == 0) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart,
                        color: Colors.grey, size: 64),
                    SizedBox(height: 16),
                    Text('No booking data available',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text(
                      'Peak-hour analysis will appear once bookings are made.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ---- Bar Chart Card ----
                  _buildBarChartCard(
                      counts, normalised, peakIndex),
                  const SizedBox(height: 16),

                  // ---- Peak Window Card ----
                  _buildPeakWindowCard(peakIndex, peakValue),
                  const SizedBox(height: 16),

                  // ---- Summary Card ----
                  _buildSummaryCard(total),
                ],
              ),
            ),
          );
        },
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Avg occupancy by hour',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 20),
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
                        '${count} bookings',
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
                              fontSize: 12,
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
                        borderRadius: BorderRadius.circular(4),
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD), shape: BoxShape.circle),
            child: const Icon(Icons.access_time,
                color: Color(0xFF1A3B5C), size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Peak window · ${_peakWindowLabel(peakIndex)}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(
                  peakValue > 0
                      ? 'route officers here first · $peakValue bookings'
                      : 'route officers here first',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('$total',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5C))),
                const SizedBox(height: 4),
                const Text('Total bookings',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: Column(
              children: [
                Text('${_bucketLabels.length}',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3B5C))),
                const SizedBox(height: 4),
                const Text('Time slots',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}