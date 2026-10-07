/// Row from `parking_facilities`.
class ParkingFacility {
  const ParkingFacility({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.ratePerHour,
    required this.reservationFee,
    required this.totalBays,
    this.address,
    this.amenities = const [],
    this.isVerifiedLegal = true,
    this.operatorId,
  });

  final String id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final double ratePerHour;
  final double reservationFee; // 0–100 (NFR4)
  final int totalBays;
  final List<String> amenities;
  final bool isVerifiedLegal;
  final String? operatorId;

  factory ParkingFacility.fromMap(Map<String, dynamic> m) => ParkingFacility(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? '',
        address: m['address'] as String?,
        latitude: (m['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (m['longitude'] as num?)?.toDouble() ?? 0,
        ratePerHour: (m['rate_per_hour'] as num?)?.toDouble() ?? 0,
        reservationFee: (m['reservation_fee'] as num?)?.toDouble() ?? 0,
        totalBays: (m['total_bays'] as num?)?.toInt() ?? 0,
        amenities: (m['amenities'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        isVerifiedLegal: (m['is_verified_legal'] as bool?) ?? true,
        operatorId: m['operator_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'rate_per_hour': ratePerHour,
        'reservation_fee': reservationFee,
        'total_bays': totalBays,
        'amenities': amenities,
      };
}
