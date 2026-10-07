import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportExporter {
  // ============================================
  // Demand Report (weekly bookings)
  // ============================================
  static Future<void> exportDemandReport({
    required Map<int, int> dayCounts,
    required List<String> dayLabels,
    required int total,
    required String busiestZone,
    required double avgOccupancy,
  }) async {
    final doc = pw.Document();

    final generatedAt = DateTime.now()
        .toLocal()
        .toString()
        .substring(0, 19);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // ---- Header ----
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1A3B5C'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ParkPin Authority',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Weekly Demand Report',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 13)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#EAA22F'),
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text('30 DAYS',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ---- Meta ----
          pw.Text('Generated: $generatedAt',
              style: const pw.TextStyle(
                  color: PdfColors.grey700, fontSize: 10)),
          pw.SizedBox(height: 24),

          // ---- Summary Box ----
          pw.Header(
              level: 1,
              child: pw.Text('Summary',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F5F7FA'),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _stat('Total Bookings', '$total'),
                _stat('Avg Occupancy', '${avgOccupancy.toInt()}%'),
                _stat('Busiest Zone', busiestZone),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // ---- Data Table ----
          pw.Header(
              level: 1,
              child: pw.Text('Bookings by Day',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Day', 'Bookings', 'Share'],
            data: List.generate(7, (i) {
              final day = i + 1;
              final count = dayCounts[day] ?? 0;
              final share = total == 0
                  ? '0%'
                  : '${((count / total) * 100).toStringAsFixed(1)}%';
              return [dayLabels[i], '$count', share];
            }),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 11),
            headerDecoration:
                pw.BoxDecoration(color: PdfColor.fromHex('#1A3B5C')),
            cellStyle:
                const pw.TextStyle(fontSize: 11, color: PdfColors.black),
            cellHeight: 26,
            border: pw.TableBorder.all(
                color: PdfColor.fromHex('#E8EDF2'), width: 0.5),
          ),
          pw.SizedBox(height: 30),

          // ---- Footer ----
          pw.Divider(color: PdfColor.fromHex('#E8EDF2')),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'ParkPin Authority · City Monitoring Portal · Confidential',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await _downloadPdf(bytes, 'parkpin_demand_report');
  }

  // ============================================
  // Peak Hour Report
  // ============================================
  static Future<void> exportPeakHourReport({
    required List<int> bucketCounts,
    required List<String> bucketLabels,
    required int peakIndex,
    required String peakWindow,
    required int total,
  }) async {
    final doc = pw.Document();

    final generatedAt = DateTime.now()
        .toLocal()
        .toString()
        .substring(0, 19);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // ---- Header ----
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1A3B5C'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ParkPin Authority',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Peak-Hour Analysis Report',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 13)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#EAA22F'),
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text('HOURLY',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Text('Generated: $generatedAt',
              style: const pw.TextStyle(
                  color: PdfColors.grey700, fontSize: 10)),
          pw.SizedBox(height: 24),

          // ---- Summary ----
          pw.Header(
              level: 1,
              child: pw.Text('Summary',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F5F7FA'),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _stat('Total Bookings', '$total'),
                _stat('Peak Window', peakWindow),
                _stat('Time Slots', '${bucketLabels.length}'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // ---- Data Table ----
          pw.Header(
              level: 1,
              child: pw.Text('Bookings by Time Slot',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Time Slot', 'Bookings', 'Status'],
            data: List.generate(bucketLabels.length, (i) {
              final isPeak = i == peakIndex;
              return [
                bucketLabels[i],
                '${bucketCounts[i]}',
                isPeak ? 'PEAK' : '—',
              ];
            }),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 11),
            headerDecoration:
                pw.BoxDecoration(color: PdfColor.fromHex('#1A3B5C')),
            cellStyle:
                const pw.TextStyle(fontSize: 11, color: PdfColors.black),
            cellHeight: 26,
            border: pw.TableBorder.all(
                color: PdfColor.fromHex('#E8EDF2'), width: 0.5),
          ),
          pw.SizedBox(height: 30),

          pw.Divider(color: PdfColor.fromHex('#E8EDF2')),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'ParkPin Authority · City Monitoring Portal · Confidential',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await _downloadPdf(bytes, 'parkpin_peak_hour_report');
  }

  // ============================================
  // Helpers
  // ============================================
  static pw.Widget _stat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A3B5C'))),
        pw.SizedBox(height: 2),
        pw.Text(label,
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey600)),
      ],
    );
  }

  /// Downloads via the printing package.
  /// On web, this triggers a browser download.
  /// On mobile, this opens the share sheet.
  static Future<void> _downloadPdf(Uint8List bytes, String name) async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    await Printing.sharePdf(
        bytes: bytes, filename: '${name}_$timestamp.pdf');
  }
}