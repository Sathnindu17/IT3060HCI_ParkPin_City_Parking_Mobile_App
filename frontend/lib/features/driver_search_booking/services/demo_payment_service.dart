import 'package:supabase_flutter/supabase_flutter.dart';

class DemoBookingResult {
  const DemoBookingResult({
    required this.bookingId,
    required this.bookingCode,
    required this.amount,
  });

  final String bookingId;
  final String bookingCode;
  final double amount;
}

/// Demo-only RPC. No PayHere, no merchant secrets, no card data is transmitted.
class DemoPaymentService {
  DemoPaymentService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<DemoBookingResult> confirm({
    required String facilityId,
    required String bayId,
    required DateTime arrival,
    required int hours,
    required String paymentMethod,
    String? vehicleNumber,
  }) async {
    if (_client.auth.currentUser == null) {
      throw StateError('Please log in as a driver to complete a demo booking.');
    }

    final response = await _client.rpc(
      'parkpin_confirm_demo_booking',
      params: <String, dynamic>{
        'p_facility_id': facilityId,
        'p_bay_id': bayId,
        'p_start_time': arrival.toUtc().toIso8601String(),
        'p_hours': hours,
        'p_method': paymentMethod,
        'p_vehicle_number': vehicleNumber?.trim() ?? '',
      },
    );

    if (response is! Map) {
      throw StateError('The server did not return a valid demo booking.');
    }
    final data = Map<String, dynamic>.from(response);
    final id = data['booking_id']?.toString() ?? '';
    final code = data['booking_code']?.toString() ?? '';
    final amount = num.tryParse('${data['amount']}')?.toDouble();
    if (id.isEmpty || code.isEmpty || amount == null) {
      throw StateError('The server did not confirm the demo booking.');
    }
    if (data['is_demo'] != true) {
      throw StateError('This transaction was not marked as a simulation.');
    }
    return DemoBookingResult(bookingId: id, bookingCode: code, amount: amount);
  }
}
