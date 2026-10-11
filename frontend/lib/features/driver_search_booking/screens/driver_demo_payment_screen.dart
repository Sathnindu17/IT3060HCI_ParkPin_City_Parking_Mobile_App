import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/demo_payment_service.dart';
import 'driver_booking_confirmation_screen.dart';

/// Test payment selection. Does NOT collect/store card information.
class DriverDemoPaymentScreen extends StatefulWidget {
  const DriverDemoPaymentScreen({
    super.key,
    required this.facilityId,
    required this.facilityName,
    required this.bayId,
    required this.bayLabel,
    required this.arrival,
    required this.hours,
    required this.parkingFee,
    required this.reservationFee,
    required this.vehicleNumber,
  });

  final String facilityId;
  final String facilityName;
  final String bayId;
  final String bayLabel;
  final DateTime arrival;
  final int hours;
  final double parkingFee;
  final double reservationFee;
  final String vehicleNumber;

  @override
  State<DriverDemoPaymentScreen> createState() =>
      _DriverDemoPaymentScreenState();
}

class _DriverDemoPaymentScreenState extends State<DriverDemoPaymentScreen> {
  static const _navy = Color(0xFF1E3D70);
  static const _orange = Color(0xFFFFA51F);

  String _method = 'card';
  bool _busy = false;
  String? _error;
  final DemoPaymentService _service = DemoPaymentService();

  Widget _methodTile(String method, IconData icon, String title, String note) {
    final selected = _method == method;
    return Card(
      color: selected ? const Color(0xFFFFF4DE) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? _orange : const Color(0xFFE5E8EF),
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        enabled: !_busy,
        leading: Icon(icon, color: _navy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(note),
        trailing: Icon(selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? _navy : Colors.grey),
        onTap: _busy ? null : () => setState(() => _method = method),
      ),
    );
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final result = await _service.confirm(
        facilityId: widget.facilityId,
        bayId: widget.bayId,
        arrival: widget.arrival,
        hours: widget.hours,
        paymentMethod: _method,
        vehicleNumber: widget.vehicleNumber,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Demo payment completed'),
          content: Text(
            'SIMULATION ONLY — No money was charged.\n\n'
            'Test amount: Rs ${result.amount.toStringAsFixed(2)}\n'
            'Booking code: ${result.bookingCode}\n\n'
            'A simulated payment and reservation have been saved to Supabase.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('View booking & QR'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DriverBookingConfirmationScreen(
            bookingId: result.bookingId,
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimate = widget.parkingFee + widget.reservationFee;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Select demo payment'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const Card(
                      color: Color(0xFFFFF4DE),
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'SIMULATION ONLY — This is NOT the PayHere gateway. '
                          'No real money is charged. Do not enter real card details.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.facilityName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('Bay: ${widget.bayLabel}'),
                    Text('Arrival: ${widget.arrival.toLocal()}'),
                    Text('Duration: ${widget.hours} hour(s)'),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _price('Parking estimate', widget.parkingFee),
                            _price('Reservation fee', widget.reservationFee),
                            const Divider(),
                            _price('Total estimate', estimate, bold: true),
                            const SizedBox(height: 8),
                            const Text(
                              'Final demo amount is recalculated by Supabase.',
                              style: TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Choose a simulated payment method',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _methodTile('card', Icons.credit_card, 'Demo card',
                        'Illustration: •••• 4242 — no card details required'),
                    _methodTile('wallet', Icons.account_balance_wallet_outlined,
                        'Demo wallet', 'Simulated wallet payment — no funds deducted'),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              if (_busy) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _confirm,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Complete simulated payment'),
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: _navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _price(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          ),
          Text('Rs ${amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}
