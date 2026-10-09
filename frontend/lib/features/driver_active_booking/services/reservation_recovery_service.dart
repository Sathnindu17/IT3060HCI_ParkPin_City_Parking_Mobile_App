import 'package:supabase_flutter/supabase_flutter.dart';

class RecoveryBay {
  final String id;
  final String label;
  final String level;

  const RecoveryBay({
    required this.id,
    required this.label,
    required this.level,
  });

  factory RecoveryBay.fromJson(Map<String, dynamic> json) {
    return RecoveryBay(
      id: json['id'] as String,
      label: json['label'] as String,
      level: json['level'] as String? ?? 'Not specified',
    );
  }
}

class ReservationRecovery {
  final String bookingId;
  final String bookingCode;
  final String facilityName;
  final String unavailableBayId;
  final String unavailableBayLabel;
  final List<RecoveryBay> alternatives;

  const ReservationRecovery({
    required this.bookingId,
    required this.bookingCode,
    required this.facilityName,
    required this.unavailableBayId,
    required this.unavailableBayLabel,
    required this.alternatives,
  });

  factory ReservationRecovery.fromJson(Map<String, dynamic> json) {
    final alternatives = json['alternatives'] as List<dynamic>? ?? [];

    return ReservationRecovery(
      bookingId: json['booking_id'] as String,
      bookingCode: json['booking_code'] as String,
      facilityName: json['facility_name'] as String,
      unavailableBayId: json['unavailable_bay_id'] as String,
      unavailableBayLabel: json['unavailable_bay_label'] as String,
      alternatives: alternatives.map((item) {
        return RecoveryBay.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList(),
    );
  }
}

class ReservationRecoveryService {
  final SupabaseClient _client;

  ReservationRecoveryService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  void _requireSignIn() {
    if (_client.auth.currentUser == null) {
      throw StateError('Please sign in to recover your reservation.');
    }
  }

  Future<ReservationRecovery> load(String bookingId) async {
    _requireSignIn();

    final data = await _client.rpc(
      'driver_recovery_options',
      params: {'p_booking_id': bookingId},
    );

    return ReservationRecovery.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<void> accept({
    required ReservationRecovery recovery,
    required RecoveryBay bay,
  }) async {
    _requireSignIn();

    await _client.rpc(
      'driver_accept_recovery_bay',
      params: {
        'p_booking_id': recovery.bookingId,
        'p_expected_bay_id': recovery.unavailableBayId,
        'p_new_bay_id': bay.id,
      },
    );
  }
}