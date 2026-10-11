/// Row from `illegal_parking_reports` (authority).
class IllegalParkingReport {
  const IllegalParkingReport({
    required this.id,
    required this.area,
    required this.status,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.description,
    this.vehicleNumber,
    this.reportedBy,
    this.resolvedAt,
  });

  final String id;
  final String area;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? vehicleNumber;
  final String status; // open | in_progress | resolved
  final String? reportedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  factory IllegalParkingReport.fromMap(Map<String, dynamic> m) => IllegalParkingReport(
        id: m['id'] as String,
        area: (m['area'] as String?) ?? '',
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        description: m['description'] as String?,
        vehicleNumber: m['vehicle_number'] as String?,
        status: (m['status'] as String?) ?? 'open',
        reportedBy: m['reported_by'] as String?,
        resolvedAt: m['resolved_at'] == null ? null : DateTime.parse(m['resolved_at'] as String).toLocal(),
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );

  Map<String, dynamic> toMap() => {
        'area': area,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'vehicle_number': vehicleNumber,
        'status': status,
        'reported_by': reportedBy,
        'resolved_at': resolvedAt?.toUtc().toIso8601String(),
      };
}
