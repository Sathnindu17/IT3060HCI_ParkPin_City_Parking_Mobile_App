import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Displays a QR only when a saved booking has a linked paid payment record.
/// The QR encodes bookings.booking_code, verified against Supabase by O08.
class DriverBookingConfirmationScreen extends StatefulWidget {
  const DriverBookingConfirmationScreen({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  State<DriverBookingConfirmationScreen> createState() =>
      _DriverBookingConfirmationScreenState();
}

class _DriverBookingConfirmationScreenState
    extends State<DriverBookingConfirmationScreen> {
  static const Color _navy = Color(0xFF1E3D70);

  late Future<Map<String, dynamic>> _bookingFuture;
  bool _creatingPdf = false;

  @override
  void initState() {
    super.initState();
    _bookingFuture = _loadBooking();
  }

  Future<Map<String, dynamic>> _loadBooking() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Please log in again.');

    final booking = await client
        .from('bookings')
        .select(
          'id,driver_id,booking_code,status,start_time,end_time,'
          'bay_id,vehicle_number,'
          'facility:parking_facilities(name),'
          'bay:bays(label,level)',
        )
        .eq('id', widget.bookingId)
        .eq('driver_id', user.id)
        .single();

    final payment = await client
        .from('payments')
        .select(
          'id,method,status,type,total,is_demo,parking_fee,reservation_fee',
        )
        .eq('booking_id', widget.bookingId)
        .eq('driver_id', user.id)
        .eq('type', 'booking')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return <String, dynamic>{
      ...Map<String, dynamic>.from(booking),
      'payment': payment,
    };
  }

  void _retry() => setState(() => _bookingFuture = _loadBooking());

  String _localDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Not available';
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _display(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  bool _canUseQr(Map<String, dynamic> booking, Map<String, dynamic>? payment) {
    final status = booking['status']?.toString() ?? '';
    final validBooking =
        status == 'reserved' || status == 'active' || status == 'completed';
    final paid = payment?['status'] == 'paid';
    final code = booking['booking_code']?.toString().trim() ?? '';
    return validBooking && paid && code.isNotEmpty;
  }

  Widget _detail(String title, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 106,
              child: Text(title, style: const TextStyle(color: Colors.black54)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  pw.Widget _pdfDetail(String title, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 125,
              child: pw.Text(
                title,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
              ),
            ),
          ],
        ),
      );

  Future<Uint8List> _buildPdf(
    Map<String, dynamic> booking,
    Map<String, dynamic> payment,
  ) async {
    final facility = booking['facility'] as Map<String, dynamic>?;
    final bay = booking['bay'] as Map<String, dynamic>?;
    final code = _display(booking['booking_code']);
    final total = num.tryParse('${payment['total'] ?? 0}') ?? 0;
    final parkingFee = num.tryParse('${payment['parking_fee'] ?? 0}') ?? 0;
    final reservationFee =
        num.tryParse('${payment['reservation_fee'] ?? 0}') ?? 0;
    final isDemo = payment['is_demo'] == true;

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(18),
              color: PdfColor.fromInt(0xFF1E3D70),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ParkPin',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Parking Booking Confirmation',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              isDemo
                  ? 'SIMULATED PAYMENT - No money charged'
                  : 'Booking and payment confirmation',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: isDemo ? PdfColors.deepOrange : PdfColors.green700,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Booking details',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            _pdfDetail('Booking code', code),
            _pdfDetail('Parking facility', _display(facility?['name'])),
            _pdfDetail('Bay', _display(bay?['label'])),
            _pdfDetail('Level', _display(bay?['level'])),
            _pdfDetail('Vehicle number', _display(booking['vehicle_number'])),
            _pdfDetail('Booking status', _display(booking['status'])),
            _pdfDetail('Arrival', _localDate(booking['start_time'])),
            _pdfDetail('Departure', _localDate(booking['end_time'])),
            _pdfDetail('Payment method', _display(payment['method'])),
            _pdfDetail('Parking fee', 'LKR ${parkingFee.toStringAsFixed(2)}'),
            _pdfDetail(
              'Reservation fee',
              'LKR ${reservationFee.toStringAsFixed(2)}',
            ),
            pw.Divider(),
            _pdfDetail('Total amount', 'LKR ${total.toStringAsFixed(2)}'),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'YOUR PARKING QR PASS',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E3D70),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: code,
                    width: 155,
                    height: 155,
                    drawText: false,
                  ),
                  pw.SizedBox(height: 7),
                  pw.Text(
                    code,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.Text(
              'Present this QR code or booking code to the parking operator. '
              'The operator must verify the booking against Supabase before check-in. '
              'This PDF is not proof of payment outside the ParkPin system.',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  Future<void> _downloadPdf() async {
    if (_creatingPdf) return;
    setState(() => _creatingPdf = true);

    try {
      // Re-check against Supabase immediately before issuing a downloadable pass.
      final booking = await _loadBooking();
      final paymentData = booking['payment'];
      final payment = paymentData is Map<String, dynamic>
          ? paymentData
          : null;

      if (!_canUseQr(booking, payment) || payment == null) {
        throw StateError(
          'A confirmed booking with a paid payment is required to download a QR pass.',
        );
      }

      final pdfBytes = await _buildPdf(booking, payment);
      final code = _display(booking['booking_code']);
      final safeCode = code.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final filename = 'ParkPin_Booking_$safeCode.pdf';

      // Chrome/Web: downloads the PDF. Android: opens the system share sheet
      // where the driver can save it to Files/Drive or share it.
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to create booking PDF: $error')),
      );
    } finally {
      if (mounted) setState(() => _creatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Booking confirmation'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _bookingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unable to load your booking: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: _retry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final payment = data['payment'] as Map<String, dynamic>?;
          final status = data['status']?.toString() ?? '';
          final validBooking =
              status == 'reserved' || status == 'active' || status == 'completed';
          final hasPayment = payment?['status'] == 'paid';
          final canShowQr = _canUseQr(data, payment);
          final demo = payment?['is_demo'] == true;
          final code = data['booking_code']?.toString() ?? '';
          final facility = data['facility'] as Map<String, dynamic>?;
          final bay = data['bay'] as Map<String, dynamic>?;
          final amount = num.tryParse('${payment?['total'] ?? 0}') ?? 0;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Icon(
                canShowQr ? Icons.check_circle_rounded : Icons.info_outline,
                color: canShowQr ? Colors.green : Colors.deepOrange,
                size: 72,
              ),
              const SizedBox(height: 8),
              Text(
                canShowQr ? 'Booking confirmed' : 'Booking needs attention',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                demo
                    ? 'SIMULATED PAYMENT — No money charged'
                    : 'Booking and payment information',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.deepOrange),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      _detail('Booking code', code.isEmpty ? '-' : code),
                      _detail('Parking', facility?['name']?.toString() ?? '-'),
                      _detail('Bay', bay?['label']?.toString() ?? '-'),
                      _detail('Level', bay?['level']?.toString() ?? 'Ground'),
                      _detail('Vehicle', data['vehicle_number']?.toString() ?? '-'),
                      _detail('Status', status),
                      _detail('Arrival', _localDate(data['start_time'])),
                      _detail('Departure', _localDate(data['end_time'])),
                      _detail('Method', payment?['method']?.toString() ?? '-'),
                      _detail('Amount', 'Rs ${amount.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (canShowQr) ...[
                const Text(
                  'YOUR PARKING QR PASS',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: _navy),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: code,
                      version: QrVersions.auto,
                      size: 210,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _creatingPdf ? null : _downloadPdf,
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: _creatingPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    _creatingPdf
                        ? 'Preparing PDF...'
                        : kIsWeb
                            ? 'Download PDF with QR'
                            : 'Save / Share PDF with QR',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Show this QR or booking code to the parking operator. '
                  'The operator must verify it against Supabase before check-in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'A QR pass and downloadable PDF are available only when '
                    'a valid booking and a matching paid payment record exist.',
                    textAlign: TextAlign.center,
                  ),
                ),
                OutlinedButton(
                  onPressed: _retry,
                  child: const Text('Refresh'),
                ),
              ],
              if (validBooking && hasPayment && code.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'The booking code is missing. Please refresh or contact support.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
