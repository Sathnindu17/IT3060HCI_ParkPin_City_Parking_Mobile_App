import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/receipt_screen.dart';

enum HistoryBookingStatus {
  reserved,
  active,
  completed,
  cancelled,
  expired,
}

class HistoryBooking {
  final String id;
  final String reference;
  final String facilityName;
  final String bayLabel;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int totalCents;
  final HistoryBookingStatus _storedStatus;
  final ParkingReceipt? receipt;
  final DateTime? completedAt;
  final DateTime? receiptViewedAt;
  final bool hiddenFromHistory;

  const HistoryBooking({
    required this.id,
    required this.reference,
    required this.facilityName,
    required this.bayLabel,
    required this.startTime,
    required this.durationMinutes,
    required this.totalCents,
    required HistoryBookingStatus status,
    this.endTime,
    this.receipt,
    this.completedAt,
    this.receiptViewedAt,
    this.hiddenFromHistory = false,
  }) : _storedStatus = status;

  DateTime get effectiveEndTime =>
      endTime ?? startTime.add(Duration(minutes: durationMinutes));

  HistoryBookingStatus get status {
    // Prevent an elapsed reservation being opened from a stale list.
    if (_storedStatus == HistoryBookingStatus.reserved &&
        !DateTime.now().isBefore(effectiveEndTime)) {
      return HistoryBookingStatus.expired;
    }

    return _storedStatus;
  }

  bool get isUpcoming =>
      status == HistoryBookingStatus.reserved ||
      status == HistoryBookingStatus.active;

  String get statusLabel {
    switch (status) {
      case HistoryBookingStatus.reserved:
        return 'Reserved';
      case HistoryBookingStatus.active:
        return 'Active';
      case HistoryBookingStatus.completed:
        return 'Completed';
      case HistoryBookingStatus.cancelled:
        return 'Cancelled';
      case HistoryBookingStatus.expired:
        return 'Reservation ended';
    }
  }

  HistoryBooking withVisibility(bool hidden) {
    return HistoryBooking(
      id: id,
      reference: reference,
      facilityName: facilityName,
      bayLabel: bayLabel,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      totalCents: totalCents,
      status: _storedStatus,
      receipt: receipt,
      completedAt: completedAt,
      receiptViewedAt: receiptViewedAt,
      hiddenFromHistory: hidden,
    );
  }

  // Retained for compatibility with existing development code.
  // The real dashboard does not use this method.
  static List<HistoryBooking> samples() {
    return [
      HistoryBooking(
        id: 'demo-upcoming',
        reference: 'PP-DEMO-UPCOMING',
        facilityName: 'One Galle Face Mall',
        bayLabel: 'B-12',
        startTime: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 60,
        totalCents: 15000,
        status: HistoryBookingStatus.reserved,
      ),
      ...[
        ParkingReceipt.sample(),
        ...ParkingReceipt.sampleHistory(),
      ].map(
        (receipt) => HistoryBooking(
          id: receipt.reference,
          reference: receipt.reference,
          facilityName: receipt.facilityName,
          bayLabel: receipt.bayLabel,
          startTime: receipt.paidAt,
          durationMinutes: receipt.durationMinutes,
          totalCents: receipt.totalCents,
          status: HistoryBookingStatus.completed,
          receipt: receipt,
        ),
      ),
    ];
  }
}

class BookingHistoryService {
  final SupabaseClient _client;

  BookingHistoryService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String _requireUser() {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in to manage your bookings.');
    }

    return user.id;
  }

  static const _columns = '''
    id,
    booking_code,
    status,
    start_time,
    end_time,
    completed_at,
    hidden_from_history,
    facility:parking_facilities(name),
    bay:bays(label),
    payments(driver_id,total,status),
    final_receipt:driver_booking_receipts(
      reference,
      facility_name,
      bay_label,
      paid_at,
      duration_minutes,
      parking_fee_cents,
      reservation_fee_cents,
      extension_fee_cents,
      total_cents,
      payment_method,
      viewed_at
    )
  ''';

  Future<List<HistoryBooking>> loadHistory() async {
    final driverId = _requireUser();

    // Persist expiration before loading history.
    await _client.rpc('driver_expire_own_reservations');

    if (_client.auth.currentUser?.id != driverId) {
      throw StateError('Your account changed. Please reload.');
    }

    final rows = <Map<String, dynamic>>[];

    const pageSize = 200;
    var offset = 0;

    while (true) {
      final page = await _client
          .from('bookings')
          .select(_columns)
          .eq('driver_id', driverId)
          .order('start_time', ascending: false)
          .order('id')
          .range(offset, offset + pageSize - 1);

      rows.addAll(page);

      if (page.length < pageSize) break;

      offset += pageSize;
    }

    if (_client.auth.currentUser?.id != driverId) {
      throw StateError('Your account changed. Please reload.');
    }

    return rows.map((row) => _fromJson(row, driverId)).toList();
  }

  Future<void> setHidden(String bookingId, bool hidden) async {
    _requireUser();

    // An elapsed reservation must be terminal in the database
    // before the history-visibility function can hide it.
    await _client.rpc('driver_expire_own_reservations');

    await _client.rpc(
      'driver_set_booking_history_visibility',
      params: {
        'p_booking_id': bookingId,
        'p_hidden': hidden,
      },
    );
  }

  Future<void> markReceiptViewed(String bookingId) async {
    _requireUser();

    await _client.rpc(
      'driver_mark_receipt_viewed',
      params: {'p_booking_id': bookingId},
    );
  }

  int _integer(dynamic value) {
    return value is num
        ? value.toInt()
        : int.parse(value.toString());
  }

  int _cents(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.parse(value.toString());

    return (amount * 100).round();
  }

  Map<String, dynamic>? _receiptMap(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is List && value.isNotEmpty) {
      return Map<String, dynamic>.from(value.first as Map);
    }

    return null;
  }

  HistoryBooking _fromJson(
    Map<String, dynamic> row,
    String driverId,
  ) {
    final facility = row['facility'] as Map<String, dynamic>?;
    final bay = row['bay'] as Map<String, dynamic>?;

    final start = DateTime.parse(row['start_time'] as String);
    final end = DateTime.parse(row['end_time'] as String);

    final status = HistoryBookingStatus.values.firstWhere(
      (value) => value.name == row['status'],
    );

    final payments = row['payments'] as List<dynamic>? ?? [];

    var totalCents = 0;

    for (final value in payments) {
      final payment = Map<String, dynamic>.from(value as Map);

      if (payment['driver_id'] == driverId &&
          payment['status'] == 'paid') {
        totalCents += _cents(payment['total']);
      }
    }

    final snapshot = _receiptMap(row['final_receipt']);

    ParkingReceipt? receipt;
    DateTime? viewedAt;

    if (snapshot != null) {
      receipt = ParkingReceipt(
        reference: snapshot['reference'] as String,
        facilityName: snapshot['facility_name'] as String,
        bayLabel: snapshot['bay_label'] as String,
        paidAt: DateTime.parse(snapshot['paid_at'] as String),
        durationMinutes: _integer(snapshot['duration_minutes']),
        parkingFeeCents: _integer(snapshot['parking_fee_cents']),
        reservationFeeCents:
            _integer(snapshot['reservation_fee_cents']),
        extensionFeeCents: _integer(snapshot['extension_fee_cents']),
        paymentMethod: snapshot['payment_method'] as String,
      );

      if (receipt.totalCents != _integer(snapshot['total_cents'])) {
        throw StateError('Receipt amounts do not match.');
      }

      totalCents = receipt.totalCents;

      if (snapshot['viewed_at'] != null) {
        viewedAt = DateTime.parse(snapshot['viewed_at'] as String);
      }
    }

    return HistoryBooking(
      id: row['id'] as String,
      reference: row['booking_code'] as String,
      facilityName: receipt?.facilityName ??
          facility?['name'] as String? ??
          'Parking facility',
      bayLabel: receipt?.bayLabel ??
          bay?['label'] as String? ??
          'Not assigned',
      startTime: start,
      endTime: end,
      durationMinutes: receipt?.durationMinutes ??
          end.difference(start).inMinutes,
      totalCents: totalCents,
      status: status,
      receipt: receipt,
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at'] as String),
      receiptViewedAt: viewedAt,
      hiddenFromHistory: row['hidden_from_history'] == true,
    );
  }
}