import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../widgets/parking_ui.dart';

class ParkingReceipt {
  final String reference;
  final String facilityName;
  final String bayLabel;
  final DateTime paidAt;
  final int durationMinutes;

  // Store money as cents to avoid floating-point rounding errors.
  final int parkingFeeCents;
  final int reservationFeeCents;
  final int extensionFeeCents;

  final String paymentMethod;
  final String? cardLastFour;

  const ParkingReceipt({
    required this.reference,
    required this.facilityName,
    required this.bayLabel,
    required this.paidAt,
    required this.durationMinutes,
    required this.parkingFeeCents,
    required this.reservationFeeCents,
    this.extensionFeeCents = 0,
    this.paymentMethod = 'Card',
    this.cardLastFour,
  });

  int get totalCents =>
      parkingFeeCents +
      reservationFeeCents +
      extensionFeeCents;

  String get durationLabel {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours h';

    return '$hours h $minutes min';
  }

  String get paymentLabel {
    if (paymentMethod.toLowerCase() == 'card' &&
        cardLastFour != null) {
      return 'Card ending $cardLastFour';
    }

    return paymentMethod;
  }

  static ParkingReceipt sample() {
    return ParkingReceipt(
      reference: 'PP-DEMO-1209',
      facilityName: 'One Galle Face Mall',
      bayLabel: 'B-12',
      paidAt: DateTime(2026, 9, 12, 16),
      durationMinutes: 120,
      parkingFeeCents: 20000,
      reservationFeeCents: 5000,
      cardLastFour: '4417',
    );
  }

  static List<ParkingReceipt> sampleHistory() {
    return [
      ParkingReceipt(
        reference: 'PP-DEMO-2808',
        facilityName: 'Liberty Plaza',
        bayLabel: 'B-5',
        paidAt: DateTime(2026, 8, 28, 14),
        durationMinutes: 60,
        parkingFeeCents: 10000,
        reservationFeeCents: 5000,
        cardLastFour: '4417',
      ),
      ParkingReceipt(
        reference: 'PP-DEMO-1508',
        facilityName: 'Crescat',
        bayLabel: 'B-8',
        paidAt: DateTime(2026, 8, 15, 12),
        durationMinutes: 120,
        parkingFeeCents: 13000,
        reservationFeeCents: 5000,
        cardLastFour: '4417',
      ),
    ];
  }
}

class ReceiptScreen extends StatefulWidget {
  final ParkingReceipt? receipt;
  final List<ParkingReceipt> pastReceipts;

  // Sample mode remains clearly labelled on screen and in the PDF.
  final bool preview;

  // Connect these destinations when integrating the group navigation.
  final ValueChanged<int>? onNavigate;

  const ReceiptScreen({
    super.key,
    this.receipt,
    this.pastReceipts = const [],
    this.preview = true,
    this.onNavigate,
  }) : assert(preview || receipt != null);

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late final ParkingReceipt _receipt;
  late final List<ParkingReceipt> _pastReceipts;

  bool _downloading = false;
  String? _downloadError;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();

    _receipt = widget.receipt ?? ParkingReceipt.sample();

    _pastReceipts = widget.receipt == null && widget.preview
        ? ParkingReceipt.sampleHistory()
        : widget.pastReceipts;
  }

  String _money(int cents) {
    final amount = cents / 100;

    return cents % 100 == 0
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  String _date(DateTime value, {bool includeYear = true}) {
    final local = value.toLocal();

    return '${local.day} ${_months[local.month - 1]}'
        '${includeYear ? ' ${local.year}' : ''}';
  }

  Future<void> _downloadReceipt() async {
    if (_downloading) return;

    setState(() {
      _downloading = true;
      _downloadError = null;
    });

    try {
      final document = pw.Document();

      pw.Widget line(
        String label,
        String value, {
        bool bold = false,
      }) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 9),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  label,
                  style: pw.TextStyle(
                    fontWeight: bold
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                  ),
                ),
              ),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontWeight: bold
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }

      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (_) => [
            if (widget.preview)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 18),
                child: pw.Text(
                  'SAMPLE RECEIPT - NOT A REAL PAYMENT',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            pw.Text(
              'ParkPin',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1D3D70'),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Parking payment receipt',
              style: const pw.TextStyle(fontSize: 15),
            ),
            pw.SizedBox(height: 24),
            line('Receipt reference', _receipt.reference),
            line('Payment date', _date(_receipt.paidAt)),
            line('Parking facility', _receipt.facilityName),
            line('Bay', _receipt.bayLabel),
            line('Duration', _receipt.durationLabel),
            line('Payment method', _receipt.paymentLabel),
            pw.SizedBox(height: 14),
            pw.Divider(),
            line(
              'Parking fee',
              'Rs ${_money(_receipt.parkingFeeCents)}',
            ),
            line(
              'Reservation fee',
              'Rs ${_money(_receipt.reservationFeeCents)}',
            ),
            if (_receipt.extensionFeeCents > 0)
              line(
                'Extension fees',
                'Rs ${_money(_receipt.extensionFeeCents)}',
              ),
            pw.Divider(),
            line(
              'Total paid',
              'Rs ${_money(_receipt.totalCents)}',
              bold: true,
            ),
            pw.SizedBox(height: 28),
            pw.Text(
              widget.preview
                  ? 'Generated from sample data for the ParkPin '
                      'assignment preview.'
                  : 'Thank you for parking with ParkPin.',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ),
      );

      final safeReference = _receipt.reference.replaceAll(
        RegExp(r'[^A-Za-z0-9_-]'),
        '_',
      );

      await Printing.sharePdf(
        bytes: await document.save(),
        filename: 'ParkPin_Receipt_$safeReference.pdf',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _downloadError =
            'Could not export the receipt. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  void _openPastReceipt(ParkingReceipt receipt) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptScreen(
          receipt: receipt,
          preview: widget.preview,
        ),
      ),
    );
  }

  void _navigate(int index) {
    if (index == 2) return;

    final callback = widget.onNavigate;

    if (callback != null) {
      callback(index);
      return;
    }

    const destinations = [
      'Home',
      'Bookings',
      'Receipts',
      'Profile',
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${destinations[index]} will be connected '
          'during navigation integration.',
        ),
      ),
    );
  }

  Widget _priceRow(
    String label,
    int cents, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ParkingStyle.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ParkingStyle.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Rs ${_money(cents)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ParkingStyle.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ParkingStyle.navy,
            Color(0xFF2B5087),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: ParkingStyle.orange,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F6ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFF16864B),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Paid',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16864B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'TOTAL PAID',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD7E1F1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rs ${_money(_receipt.totalCents)}',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Color(0xFFD7E1F1),
              ),
              const SizedBox(width: 8),
              Text(
                _date(_receipt.paidAt),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFD7E1F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pastBooking(ParkingReceipt receipt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openPastReceipt(receipt),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_outlined,
                    color: ParkingStyle.navy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.facilityName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ParkingStyle.text,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _date(receipt.paidAt, includeYear: false),
                        style: const TextStyle(
                          fontSize: 12,
                          color: ParkingStyle.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rs ${_money(receipt.totalCents)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ParkingStyle.navy,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ParkingStyle.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParkingStyle.background,
      appBar: AppBar(
        backgroundColor: ParkingStyle.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        title: const Text(
          'Receipt',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _paymentSummary(),
              const SizedBox(height: 20),
              ParkingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ParkingInfoRow(
                      icon: Icons.local_parking_rounded,
                      title: _receipt.facilityName,
                      subtitle:
                          'Bay ${_receipt.bayLabel} · '
                          '${_receipt.durationLabel}',
                    ),
                    const SizedBox(height: 18),
                    const Divider(
                      height: 1,
                      color: Color(0xFFE8EDF5),
                    ),
                    _priceRow(
                      'Parking fee',
                      _receipt.parkingFeeCents,
                      subtitle: _receipt.durationLabel,
                    ),
                    _priceRow(
                      'Reservation hold',
                      _receipt.reservationFeeCents,
                    ),
                    if (_receipt.extensionFeeCents > 0)
                      _priceRow(
                        'Extension fees',
                        _receipt.extensionFeeCents,
                      ),
                    const Divider(
                      height: 1,
                      color: Color(0xFFE8EDF5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.credit_card_rounded,
                          color: ParkingStyle.navy,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _receipt.paymentLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              color: ParkingStyle.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Reference: ${_receipt.reference}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: ParkingStyle.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      _downloading ? null : _downloadReceipt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ParkingStyle.orange,
                    foregroundColor: ParkingStyle.text,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ParkingStyle.navy,
                          ),
                        )
                      : const Icon(
                          Icons.download_rounded,
                          size: 21,
                        ),
                  label: Text(
                    _downloading
                        ? 'Preparing receipt...'
                        : 'Download receipt',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (_downloadError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _downloadError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (widget.preview)
                const Center(child: ParkingPreviewLabel()),
              const SizedBox(height: 28),
              const Text(
                'Past bookings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ParkingStyle.navy,
                ),
              ),
              const SizedBox(height: 14),
              if (_pastReceipts.isEmpty)
                const ParkingCard(
                  child: ParkingInfoRow(
                    icon: Icons.history_rounded,
                    title: 'No other receipts',
                    subtitle:
                        'Your previous booking receipts '
                        'will appear here.',
                  ),
                )
              else
                ..._pastReceipts.map(_pastBooking),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE8EDF5)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: 2,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: ParkingStyle.navy,
          unselectedItemColor: const Color(0xFF9AA7BC),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          onTap: _navigate,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Receipts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}