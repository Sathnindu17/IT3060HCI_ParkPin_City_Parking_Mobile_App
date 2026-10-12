/// Row from `pricing_rules` (e.g. the operator's off-peak rate).
class PricingRule {
  const PricingRule({
    required this.id,
    required this.facilityId,
    required this.label,
    required this.ratePerHour,
    required this.startHour,
    required this.endHour,
    this.days = const [0, 1, 2, 3, 4, 5, 6],
    this.isOffPeak = false,
    this.isActive = true,
  });

  final String id;
  final String facilityId;
  final String label;
  final double ratePerHour;
  final int startHour; // 0–23
  final int endHour; // 0–23
  final List<int> days; // 0 = Sunday
  final bool isOffPeak;
  final bool isActive;

  factory PricingRule.fromMap(Map<String, dynamic> m) => PricingRule(
        id: m['id'] as String,
        facilityId: m['facility_id'] as String,
        label: (m['label'] as String?) ?? '',
        ratePerHour: (m['rate_per_hour'] as num?)?.toDouble() ?? 0,
        startHour: (m['start_hour'] as num?)?.toInt() ?? 0,
        endHour: (m['end_hour'] as num?)?.toInt() ?? 0,
        days: (m['days'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const [0, 1, 2, 3, 4, 5, 6],
        isOffPeak: (m['is_off_peak'] as bool?) ?? false,
        isActive: (m['is_active'] as bool?) ?? true,
      );

  Map<String, dynamic> toMap() => {
        'facility_id': facilityId,
        'label': label,
        'rate_per_hour': ratePerHour,
        'start_hour': startHour,
        'end_hour': endHour,
        'days': days,
        'is_off_peak': isOffPeak,
        'is_active': isActive,
      };
}
