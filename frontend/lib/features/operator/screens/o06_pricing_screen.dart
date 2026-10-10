import 'package:flutter/material.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/core/utils/validators.dart';
import 'package:parkpin/features/operator/services/operator_service.dart';
import 'package:parkpin/features/operator/widgets/operator_ui.dart';
import 'package:parkpin/services/supabase_service.dart';

/// O06 – Off-peak pricing (Figma "Operator · Off-peak pricing").
/// Standard hourly rate, reservation fee (max Rs 100 – NFR4), a weekday
/// off-peak window and discount. The off-peak rate is previewed live.
class OperatorPricingScreen extends StatefulWidget {
  const OperatorPricingScreen({super.key});

  @override
  State<OperatorPricingScreen> createState() => _OperatorPricingScreenState();
}

class _OperatorPricingScreenState extends State<OperatorPricingScreen> {
  final _svc = OperatorService.instance;
  final _formKey = GlobalKey<FormState>();
  final _rate = TextEditingController();
  final _fee = TextEditingController();
  final _discount = TextEditingController();

  int _startHour = 10;
  int _endHour = 15;
  bool _promote = true;
  Set<int> _days = {1, 2, 3, 4, 5}; // 0 = Sunday … 6 = Saturday
  bool _ready = false;

  // Shown Monday first; values match the database (0 = Sunday).
  static const _dayChips = [(1, 'Mon'), (2, 'Tue'), (3, 'Wed'), (4, 'Thu'), (5, 'Fri'), (6, 'Sat'), (0, 'Sun')];
  static const _discountPresets = [10, 20, 30, 50];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await _svc.ensureLoaded();
      final f = await _svc.getFacility(refresh: true);
      final rule = await _svc.getOffPeakRule();
      if (!mounted) return;
      setState(() {
        _rate.text = f.ratePerHour.toStringAsFixed(0);
        _fee.text = f.reservationFee.toStringAsFixed(0);
        if (rule != null) {
          _startHour = rule.startHour;
          _endHour = rule.endHour;
          _promote = rule.isActive;
          _days = rule.days.toSet();
          _discount.text = '${OperatorService.discountFrom(f.ratePerHour, rule.ratePerHour)}';
        } else {
          _discount.text = '30';
        }
        _ready = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = SupabaseService.friendlyError(e));
    }
  }

  @override
  void dispose() {
    _rate.dispose();
    _fee.dispose();
    _discount.dispose();
    super.dispose();
  }

  /// Off-peak price per hour, or null while the inputs are incomplete.
  double? get _offPeakValue {
    final rate = double.tryParse(_rate.text.trim());
    final disc = int.tryParse(_discount.text.trim());
    if (rate == null || disc == null || disc < 0 || disc > 90) return null;
    return OperatorService.offPeakRate(rate, disc);
  }

  /// "Mon–Fri", "Every day", "Sat, Sun" …
  String get _daysText {
    if (_days.length == 7) return 'every day';
    if (_days.length == 5 && _days.containsAll([1, 2, 3, 4, 5])) return 'Mon–Fri';
    if (_days.length == 2 && _days.containsAll([0, 6])) return 'weekends';
    return _dayChips.where((d) => _days.contains(d.$1)).map((d) => d.$2).join(', ');
  }

  /// What a typical 2-hour stay costs, so the operator sees the effect.
  String? get _example {
    final rate = double.tryParse(_rate.text.trim());
    final disc = int.tryParse(_discount.text.trim());
    if (rate == null || disc == null || disc < 0 || disc > 90) return null;
    final normal = rate * 2;
    final off = OperatorService.offPeakRate(rate, disc) * 2;
    return 'A 2-hour stay: ${rs(normal)} → ${rs(off)} (driver saves ${rs(normal - off)})';
  }

  Future<void> _pickHour(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start ? _startHour : _endHour, minute: 0),
      helpText: start ? 'Off-peak starts' : 'Off-peak ends',
      initialEntryMode: TimePickerEntryMode.dialOnly,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startHour = picked.hour;
      } else {
        _endHour = picked.hour;
      }
    });
    if (picked.minute != 0 && mounted) showOpSnack(context, 'Off-peak windows use whole hours.');
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_startHour >= _endHour) {
      showOpSnack(context, 'The off-peak start must be before the end time.', error: true);
      return;
    }
    if (_days.isEmpty) {
      showOpSnack(context, 'Pick at least one day for off-peak pricing.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await _svc.saveOffPeak(
        standardRate: double.parse(_rate.text.trim()),
        reservationFee: double.parse(_fee.text.trim()),
        startHour: _startHour,
        endHour: _endHour,
        discountPercent: int.parse(_discount.text.trim()),
        promote: _promote,
        days: _days.toList()..sort(),
      );
      if (mounted) showOpSnack(context, 'Pricing saved · drivers see the new rates');
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final example = _example;
    return Scaffold(
      body: Column(
        children: [
          const OperatorHeader(title: 'Off-peak pricing', subtitle: 'Fill quiet weekday hours'),
          Expanded(
            child: _error != null
                ? OpError(message: _error!, onRetry: _load)
                : !_ready
                    ? const Center(child: CircularProgressIndicator())
                    : Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                          children: [
                            const OpPageIntro(
                              title: 'Fill quiet hours',
                              subtitle: 'Lower the price when the car park is usually empty.',
                            ),
                            OpHeroCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const HeroCaption('Off-peak rate', icon: Icons.sell_outlined),
                                  const SizedBox(height: 12),
                                  Text(
                                    _offPeakValue == null ? 'Rs –' : '${rs(_offPeakValue!)} /hr',
                                    style: const TextStyle(
                                        fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      HeroPill('${hourLabel(_startHour)}–${hourLabel(_endHour)} · $_daysText'),
                                      HeroPill(_promote ? 'Shown to drivers' : 'Paused'),
                                    ],
                                  ),
                                  if (example != null) ...[
                                    const SizedBox(height: 12),
                                    Text(example,
                                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            const SectionLabel('Prices'),
                            OpField(
                              label: 'Standard rate (Rs/hr)',
                              controller: _rate,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              validator: (v) => Validators.numberInRange(v, 10, 1000, 'Rate'),
                            ),
                            const SizedBox(height: 12),
                            OpField(
                              label: 'Reservation fee (Rs, max 100)',
                              controller: _fee,
                              keyboardType: TextInputType.number,
                              validator: (v) => Validators.numberInRange(v, 0, 100, 'Reservation fee'),
                            ),
                            const SizedBox(height: 22),
                            const SectionLabel('Off-peak window'),
                            Row(
                              children: [
                                Expanded(
                                  child: _TimeBox(
                                    label: 'Starts',
                                    value: hourLabel(_startHour),
                                    onTap: () => _pickHour(true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _TimeBox(
                                    label: 'Ends',
                                    value: hourLabel(_endHour),
                                    onTap: () => _pickHour(false),
                                  ),
                                ),
                              ],
                            ),
                            if (_startHour >= _endHour)
                              const Padding(
                                padding: EdgeInsets.only(top: 4, left: 4),
                                child: Text('Start must be before end',
                                    style: TextStyle(fontSize: 12.5, color: AppColors.danger)),
                              ),
                            const SizedBox(height: 14),
                            const Text('Days',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: OpStyle.ink)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final d in _dayChips)
                                  FilterChip(
                                    label: Text(d.$2, style: const TextStyle(fontSize: 13)),
                                    selected: _days.contains(d.$1),
                                    showCheckmark: false,
                                    visualDensity: VisualDensity.compact,
                                    selectedColor: AppColors.primary,
                                    backgroundColor: Colors.white,
                                    labelStyle: TextStyle(
                                      color: _days.contains(d.$1) ? Colors.white : AppColors.textMuted,
                                    ),
                                    side: const BorderSide(color: AppColors.border),
                                    onSelected: (picked) => setState(() {
                                      if (picked) {
                                        _days.add(d.$1);
                                      } else {
                                        _days.remove(d.$1);
                                      }
                                    }),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            OpField(
                              label: 'Off-peak discount (%)',
                              controller: _discount,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              validator: (v) => int.tryParse((v ?? '').trim()) == null && num.tryParse((v ?? '').trim()) != null
                                  ? 'Discount must be a whole number'
                                  : Validators.numberInRange(v, 0, 90, 'Discount'),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                for (final p in _discountPresets) ...[
                                  ActionChip(
                                    label: Text('$p%', style: const TextStyle(fontSize: 13)),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: _discount.text.trim() == '$p' ? AppColors.successBg : Colors.white,
                                    side: const BorderSide(color: AppColors.border),
                                    onPressed: () => setState(() => _discount.text = '$p'),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            OpCard(
                              padding: const EdgeInsets.fromLTRB(13, 6, 6, 6),
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _promote,
                                onChanged: (v) => setState(() => _promote = v),
                                activeTrackColor: AppColors.success,
                                title: const Text('Promote empty bays',
                                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                                subtitle: const Text('Off-peak rate is shown to nearby drivers',
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
          if (_ready)
            OpActionBar(safeBottom: true, children: [
              OpButton(label: 'Save pricing', loading: _saving, onPressed: _save),
            ]),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Off-peak $label at $value',
      child: OpCard(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: OpStyle.ink)),
                ],
              ),
            ),
            const Icon(Icons.access_time, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
