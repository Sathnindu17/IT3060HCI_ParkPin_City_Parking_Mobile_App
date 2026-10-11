import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows a QR only for a saved booking that has a linked payment row.
/// QR content = bookings.booking_code, which the operator must look up in O08.
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
        .select('id,method,status,type,total,is_demo,parking_fee,reservation_fee')
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
                    Text('Unable to load your booking: ${snapshot.error}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    OutlinedButton(onPressed: _retry, child: const Text('Retry')),
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
          final canShowQr = validBooking && hasPayment;
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
                demo ? 'SIMULATED PAYMENT — No money charged'
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
              if (canShowQr && code.isNotEmpty) ...[
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
                      data: code, // O08 must search bookings.booking_code
                      version: QrVersions.auto,
                      size: 210,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(code,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: _navy, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking code copied')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy booking code'),
                ),
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
                    'A QR pass is shown only when a valid booking and a '
                    'matching paid payment record exist.',
                    textAlign: TextAlign.center,
                  ),
                ),
                OutlinedButton(onPressed: _retry, child: const Text('Refresh')),
              ],
            ],
          );
        },
      ),
    );
  }
}
