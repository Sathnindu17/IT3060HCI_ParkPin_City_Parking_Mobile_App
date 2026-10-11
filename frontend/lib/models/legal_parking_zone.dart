/// Row from `legal_parking_zones` (authority).
class LegalParkingZone {
  const LegalParkingZone({
    required this.id,
    required this.name,
    this.area,
    this.latitude,
    this.longitude,
    this.capacity = 0,
    this.notes,
    this.createdBy,
  });

  final String id;
  final String name;
  final String? area;
  final double? latitude;
  final double? longitude;
  final int capacity;
  final String? notes;
  final String? createdBy;

  factory LegalParkingZone.fromMap(Map<String, dynamic> m) => LegalParkingZone(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? '',
        area: m['area'] as String?,
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        capacity: (m['capacity'] as num?)?.toInt() ?? 0,
        notes: m['notes'] as String?,
        createdBy: m['created_by'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'area': area,
        'latitude': latitude,
        'longitude': longitude,
        'capacity': capacity,
        'notes': notes,
        'created_by': createdBy,
      };
}
