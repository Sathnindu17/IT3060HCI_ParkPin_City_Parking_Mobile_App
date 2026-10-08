import 'package:latlong2/latlong.dart';

class ParkingMapFacility {
  final String id;
  final String name;
  final String address;
  final LatLng position;
  final double ratePerHour;
  final double reservationFee;

  const ParkingMapFacility({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    required this.ratePerHour,
    required this.reservationFee,
  });

  factory ParkingMapFacility.fromJson(Map<String, dynamic> json) {
    return ParkingMapFacility(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      position: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      ratePerHour: (json['rate_per_hour'] as num).toDouble(),
      reservationFee: (json['reservation_fee'] as num).toDouble(),
    );
  }
}