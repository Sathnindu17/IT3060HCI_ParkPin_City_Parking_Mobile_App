import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../driver_search/models/parking_map_facility.dart';
import '../services/payhere_payment_service.dart';
import 'driver_booking_confirmation_screen.dart';
import 'driver_demo_payment_screen.dart';

class DriverPaymentPreviewScreen extends StatefulWidget {
  const DriverPaymentPreviewScreen({
    super.key,
    required this.facility,
    required this.bay,
    required this.arrival,
    required this.hours,
    required this.vehicle,
  });

  final ParkingMapFacility facility;
  final Map<String, dynamic> bay;
  final DateTime arrival;
  final int hours;
  final String vehicle;

  @override
  State<DriverPaymentPreviewScreen> createState() =>
      _DriverPaymentPreviewScreenState();
}

class _DriverPaymentPreviewScreenState
    extends State<DriverPaymentPreviewScreen> {
  static const Color _navy = Color(0xFF1E3D70);
  static const Color _orange = Color(0xFFFFA51F);

  final TextEditingController _plateController = TextEditingController();
  late final PayHerePaymentService _service =
      PayHerePaymentService(Supabase.instance.client);

  PayHereCheckout? _checkout;
  bool _busy = false;
  String? _message;
  bool _gatewayOpened = false;

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  void _openDemoPayment() {
    if (_busy || _checkout != null) return;
    final bayId = widget.bay['id']?.toString() ?? '';
    if (bayId.isEmpty) {
      setState(() => _message = 'Select a valid parking bay first.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverDemoPaymentScreen(
          facilityId: widget.facility.id,
          facilityName: widget.facility.name,
          bayId: bayId,
          bayLabel: widget.bay['label']?.toString() ?? '-',
          arrival: widget.arrival,
          hours: widget.hours,
          parkingFee: widget.facility.ratePerHour * widget.hours,
          reservationFee: widget.facility.reservationFee,
          vehicleNumber: _plateController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _createCheckout() async {
    if (_busy || _checkout != null) return;
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final checkout = await _service.createCheckout(
        facilityId: widget.facility.id,
        bayId: widget.bay['id']?.toString() ?? '',
        arrival: widget.arrival,
        hours: widget.hours,
        vehicleType: widget.vehicle,
        vehicleNumber: _plateController.text,
      );

      if (!mounted) return;
      setState(() {
        _checkout = checkout;
        _message = 'Checkout prepared for Rs '
            '${checkout.amount.toStringAsFixed(2)}. '
            'Tap Open PayHere Sandbox to continue.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Separate user tap is intentional: Chrome often blocks windows opened
  /// after an awaited network request. This works on Flutter Web and Android.
  Future<void> _openPayHere() async {
    final checkout = _checkout;
    if (checkout == null || _busy) return;
    try {
      // Supabase rewrites GET responses containing HTML to text/plain.
      // On Flutter Web, display the PayHere form from a real HTML page
      // hosted by Flutter rather than navigating to the raw Edge Function.
      final paymentUrl = kIsWeb
          ? Uri.parse('${Uri.base.origin}/payhere_checkout.html').replace(
              queryParameters: {
                'source': checkout.checkoutUrl.toString(),
              },
            )
          : checkout.checkoutUrl;
      final launched = await launchUrl(
        paymentUrl,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched) {
        throw StateError('The browser could not open the payment page.');
      }
      if (!mounted) return;
      setState(() {
        _gatewayOpened = true;
        _message = 'Finish the test payment in PayHere. Then return '
            'to ParkPin and tap Check payment status.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Unable to open PayHere: $error');
    }
  }

  Future<void> _checkPayment() async {
    final checkout = _checkout;
    if (checkout == null || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final attempt = await _service.getAttempt(checkout.attemptId);
      if (!mounted) return;
      final state = (attempt['state'] ?? '').toString();
      final bookingId = attempt['booking_id']?.toString();
      if (state == 'paid' && bookingId != null && bookingId.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) =>
                DriverBookingConfirmationScreen(bookingId: bookingId),
          ),
        );
        return;
      }

      String description;
      switch (state) {
        case 'pending':
          description = 'Payment has not been verified yet. Wait briefly '
              'and check again. Returning from PayHere does not confirm payment.';
          break;
        case 'failed':
          description = 'PayHere marked this payment as failed. No booking '
              'has been confirmed.';
          break;
        case 'cancelled':
          description = 'Payment was cancelled. No booking was confirmed.';
          break;
        case 'conflict':
          description = 'Payment needs manual review: the bay was no longer '
              'available or the checkout expired. Contact the project '
              'administrator to reconcile the sandbox transaction.';
          break;
        case 'paid':
          description = 'Payment was recorded but there is no linked booking. '
              'Contact the project administrator; do not retry payment.';
          break;
        default:
          description = 'Checkout status: $state. Booking is not confirmed.';
      }
      setState(() => _message = description);
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Could not check payment status: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _priceRow(String label, double price, {bool total = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: total ? FontWeight.bold : null)),
          Text(
            'Rs ${price.toStringAsFixed(2)}',
            style: TextStyle(
              color: _navy,
              fontWeight: total ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parkingFee = widget.facility.ratePerHour * widget.hours;
    final estimatedTotal = parkingFee + widget.facility.reservationFee;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Payment review'),
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
                    Text(
                      widget.facility.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Bay: ${widget.bay['label'] ?? '-'} · '
                        '${widget.bay['level'] ?? 'Ground'}'),
                    Text('Vehicle type: ${widget.vehicle}'),
                    Text('Arrival: ${widget.arrival.toLocal()}'),
                    Text('Duration: ${widget.hours} hours'),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          _priceRow('Parking', parkingFee),
                          _priceRow('Reservation fee',
                              widget.facility.reservationFee),
                          const Divider(),
                          _priceRow('Estimated total', estimatedTotal,
                              total: true),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _plateController,
                      enabled: !_busy && _checkout == null,
                      maxLength: 24,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle registration (optional)',
                        hintText: 'e.g. WP CAB-1234',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'UNIVERSITY DEMO: Simulated card/wallet completes a test booking '
                          'in Supabase without transferring money. PayHere Sandbox '
                          'is a separate, optional checkout and requires verified '
                          'payment before confirmation.',
                        ),
                      ),
                    ),
                    if (_checkout != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Server checkout amount: '
                        'Rs ${_checkout!.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _message!,
                        style: const TextStyle(color: _navy),
                      ),
                    ],
                  ],
                ),
              ),
              if (_busy) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              // University demo payment works without PayHere credentials.
              if (_checkout == null) ...[
                ElevatedButton.icon(
                  onPressed: _busy ? null : _openDemoPayment,
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Simulated card / wallet (no real charge)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: _navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'OPTIONAL: PayHere Sandbox is separate. Use the simulated '
                  'option above for the university demo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 6),
              ],
              if (_checkout == null)
                OutlinedButton(
                  onPressed: _busy ? null : _createCheckout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Continue to PayHere Sandbox'),
                )
              else ...[
                ElevatedButton(
                  onPressed: _busy ? null : _openPayHere,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: _navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_gatewayOpened
                      ? 'Reopen PayHere Sandbox'
                      : 'Open PayHere Sandbox'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _checkPayment,
                  child: const Text('Check payment status'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
