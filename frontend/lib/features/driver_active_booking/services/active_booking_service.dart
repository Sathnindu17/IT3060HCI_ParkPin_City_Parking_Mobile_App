import 'package:supabase_flutter/supabase_flutter.dart';

class ActiveBooking {
  final String id;
  final String facilityName;
  final String bayLabel;
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final double ratePerHour;

  const ActiveBooking({
    required this.id,
    required this.facilityName,
    required this.bayLabel,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.ratePerHour,
  });

  factory ActiveBooking.fromJson(Map<String, dynamic> json) {
    final facility = json['facility'] as Map<String, dynamic>?;
    final bay = json['bay'] as Map<String, dynamic>?;

    return ActiveBooking(
      id: json['id'] as String,
      facilityName:
          facility?['name'] as String? ?? 'Parking facility',
      bayLabel: bay?['label'] as String? ?? 'Not assigned',
      status: json['status'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      ratePerHour:
          (facility?['rate_per_hour'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get isActive => status == 'active';

  double get extensionFee => extensionFeeFor(30);

  double extensionFeeFor(int minutes) {
    return (ratePerHour * minutes / 60 * 100).round() / 100;
  }

  Duration remainingAt(DateTime now) {
    final remaining = endTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double progressAt(DateTime now) {
    final total = endTime.difference(startTime).inMilliseconds;

    if (total <= 0) return 0;

    return (remainingAt(now).inMilliseconds / total)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  ActiveBooking withExtraMinutes(int minutes) {
    return ActiveBooking(
      id: id,
      facilityName: facilityName,
      bayLabel: bayLabel,
      status: status,
      startTime: startTime,
      endTime: endTime.add(Duration(minutes: minutes)),
      ratePerHour: ratePerHour,
    );
  }
}

class ActiveBookingService {
  final SupabaseClient _client;

  ActiveBookingService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<ActiveBooking> load(String bookingId) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in to view your booking.');
    }

    final data = await _client
        .from('bookings')
        .select(
          'id, status, start_time, end_time, '
          'facility:parking_facilities(name, rate_per_hour), '
          'bay:bays(label)',
        )
        .eq('id', bookingId)
        .eq('driver_id', user.id)
        .single();

    return ActiveBooking.fromJson(data);
  }

  Future<ActiveBooking> open(String bookingId) async {
    await _client.rpc(
      'driver_start_booking',
      params: {'p_booking_id': bookingId},
    );

    return load(bookingId);
  }

  Future<ActiveBooking> extend(
    ActiveBooking booking, {
    int minutes = 30,
  }) async {
    if (![30, 60, 120].contains(minutes)) {
      throw StateError('Choose 30 minutes, 1 hour or 2 hours.');
    }

    await _client.rpc(
      'driver_extend_booking_minutes',
      params: {
        'p_booking_id': booking.id,
        'p_minutes': minutes,
        'p_expected_end_time':
            booking.endTime.toUtc().toIso8601String(),
        'p_expected_fee':
            booking.extensionFeeFor(minutes).toStringAsFixed(2),
      },
    );

    return load(booking.id);
  }

  Future<void> finish(String bookingId) async {
    await _client.rpc(
      'driver_finish_booking',
      params: {'p_booking_id': bookingId},
    );
  }
}