/// Row from `payments` (simulated payments – no real gateway).
class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.driverId,
    required this.parkingFee,
    required this.reservationFee,
    required this.total,
    required this.method,
    required this.status,
    required this.type,
    required this.createdAt,
    this.facilityId,
  });

  final String id;
  final String bookingId;
  final String driverId;
  final String? facilityId;
  final double parkingFee;
  final double reservationFee;
  final double total;
  final String method; // card | wallet
  final String status; // paid | refunded
  final String type; // booking | extension
  final DateTime createdAt; // local time

  bool get isPaid => status == 'paid';

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
        id: m['id'] as String,
        bookingId: m['booking_id'] as String,
        driverId: m['driver_id'] as String,
        facilityId: m['facility_id'] as String?,
        parkingFee: (m['parking_fee'] as num?)?.toDouble() ?? 0,
        reservationFee: (m['reservation_fee'] as num?)?.toDouble() ?? 0,
        total: (m['total'] as num?)?.toDouble() ?? 0,
        method: (m['method'] as String?) ?? 'card',
        status: (m['status'] as String?) ?? 'paid',
        type: (m['type'] as String?) ?? 'booking',
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );

  Map<String, dynamic> toMap() => {
        'booking_id': bookingId,
        'driver_id': driverId,
        'facility_id': facilityId,
        'parking_fee': parkingFee,
        'reservation_fee': reservationFee,
        'total': total,
        'method': method,
        'status': status,
        'type': type,
      };
}
