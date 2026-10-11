/// Row from `bays`.
class Bay {
  const Bay({
    required this.id,
    required this.facilityId,
    required this.label,
    required this.type,
    required this.status,
    this.level,
    this.updatedAt,
  });

  static const String available = 'available';
  static const String occupied = 'occupied';
  static const String reserved = 'reserved';

  final String id;
  final String facilityId;
  final String label; // e.g. B3
  final String? level; // e.g. L1
  final String type; // standard | ev
  final String status; // available | occupied | reserved
  final DateTime? updatedAt;

  bool get isAvailable => status == available;
  bool get isEv => type == 'ev';
  String get display => level == null ? label : '$label · $level';

  factory Bay.fromMap(Map<String, dynamic> m) => Bay(
        id: m['id'] as String,
        facilityId: m['facility_id'] as String,
        label: (m['label'] as String?) ?? '',
        level: m['level'] as String?,
        type: (m['type'] as String?) ?? 'standard',
        status: (m['status'] as String?) ?? available,
        updatedAt: m['updated_at'] == null ? null : DateTime.parse(m['updated_at'] as String).toLocal(),
      );

  Map<String, dynamic> toMap() => {
        'facility_id': facilityId,
        'label': label,
        'level': level,
        'type': type,
        'status': status,
      };

  /// Sorts by level, then by the number inside the label (B2 before B10).
  static int compare(Bay a, Bay b) {
    final l = (a.level ?? '').compareTo(b.level ?? '');
    if (l != 0) return l;
    final na = int.tryParse(a.label.replaceAll(RegExp(r'[^0-9]'), ''));
    final nb = int.tryParse(b.label.replaceAll(RegExp(r'[^0-9]'), ''));
    if (na != null && nb != null && na != nb) return na.compareTo(nb);
    return a.label.compareTo(b.label);
  }
}
