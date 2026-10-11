import 'package:supabase_flutter/supabase_flutter.dart';

/// A server-generated checkout. Amounts and payment hashes are NEVER generated
/// or trusted in Flutter; the Supabase Edge Function calculates those values.
class PayHereCheckout {
  const PayHereCheckout({
    required this.attemptId,
    required this.checkoutUrl,
    required this.amount,
  });

  final String attemptId;
  final Uri checkoutUrl;
  final double amount;
}

class PayHerePaymentService {
  PayHerePaymentService(this.client);

  final SupabaseClient client;

  Future<PayHereCheckout> createCheckout({
    required String facilityId,
    required String bayId,
    required DateTime arrival,
    required int hours,
    required String vehicleType,
    String? vehicleNumber,
  }) async {
    if (client.auth.currentSession == null) {
      throw StateError('Please sign in again before making a reservation.');
    }
    if (facilityId.isEmpty || bayId.isEmpty || hours < 1 || hours > 24) {
      throw ArgumentError('Missing parking details or invalid duration.');
    }

    try {
      final response = await client.functions.invoke(
        'parkpin-payhere-checkout',
        body: <String, dynamic>{
          'facility_id': facilityId,
          'bay_id': bayId,
          'start_time': arrival.toUtc().toIso8601String(),
          'duration_hours': hours,
          'vehicle_type': vehicleType,
          'vehicle_number': vehicleNumber?.trim() ?? '',
        },
      );

      if (response.status != 200) {
        throw StateError('Checkout rejected (${response.status}): ${response.data}');
      }
      if (response.data is! Map) {
        throw const FormatException('Checkout returned an unexpected response.');
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      final attemptId = data['attempt_id']?.toString() ?? '';
      final rawUrl = data['checkout_url']?.toString() ?? '';
      final url = Uri.tryParse(rawUrl);
      final amount = num.tryParse(data['amount'].toString())?.toDouble();

      if (attemptId.isEmpty || url == null || url.scheme != 'https' ||
          !url.host.endsWith('.supabase.co') ||
          amount == null || !amount.isFinite || amount <= 0) {
        throw const FormatException('Checkout details are incomplete or invalid.');
      }
      return PayHereCheckout(
        attemptId: attemptId,
        checkoutUrl: url,
        amount: amount,
      );
    } catch (error) {
      final text = error.toString();
      if (text.contains('FunctionsFetchException') ||
          text.contains('Failed to fetch') ||
          text.contains('XMLHttpRequest error')) {
        throw StateError(
          'Cannot reach the checkout function. Check Supabase Edge Function '
          'deployment and browser CORS/preflight response.',
        );
      }
      if (text.contains('parkpin_checkout_attempts') ||
          text.contains('PGRST205') ||
          text.contains('PGRST116')) {
        throw StateError(
          'The PayHere checkout database is not ready. Ask the team to '
          'review and apply the approved SQL migration.',
        );
      }
      rethrow;
    }
  }

  /// Read-only lookup. Drivers need SELECT RLS permission for their own attempt.
  Future<Map<String, dynamic>> getAttempt(String attemptId) async {
    if (client.auth.currentSession == null) {
      throw StateError('Your login has expired. Please sign in again.');
    }
    final data = await client
        .from('parkpin_checkout_attempts')
        .select('id,state,booking_id,amount,expires_at,payhere_payment_id')
        .eq('id', attemptId)
        .single();
    return Map<String, dynamic>.from(data);
  }
}
