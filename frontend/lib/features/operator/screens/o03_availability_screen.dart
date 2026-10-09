import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/core/utils/validators.dart';
import 'package:parkpin/features/operator/services/operator_service.dart';
import 'package:parkpin/features/operator/widgets/operator_ui.dart';
import 'package:parkpin/models/bay.dart';
import 'package:parkpin/services/supabase_service.dart';

/// O03 – Publish availability (Figma "Operator · Publish availability").
/// Tap a bay to mark it free/occupied, then "Update availability" publishes the
/// changes to drivers in real time. Long-press a bay to edit or delete it,
/// "+" adds a new bay.
class OperatorAvailabilityScreen extends StatefulWidget {
  const OperatorAvailabilityScreen({super.key});

  @override
  State<OperatorAvailabilityScreen> createState() => _OperatorAvailabilityScreenState();
}

class _OperatorAvailabilityScreenState extends State<OperatorAvailabilityScreen> {
  final _svc = OperatorService.instance;

  List<Bay> _bays = [];
  bool _ready = false;
  String? _error;
  int _levelIndex = 0;
  bool _saving = false;

  /// Changes not yet published: bayId → new status.
  final Map<String, String> _pending = {};
  StreamSubscription<List<Bay>>? _sub;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      await _svc.ensureLoaded();
      await _sub?.cancel();
      _sub = _svc.watchBays().listen(
        (bays) => setState(() {
          _bays = bays;
          _ready = true;
          // Forget local edits that the database already matches,
          // and edits for bays that were deleted or got reserved meanwhile.
          _pending.removeWhere((id, status) {
            final bay = bays.where((b) => b.id == id).firstOrNull;
            return bay == null || bay.status == status || bay.status == Bay.reserved;
          });
        }),
        onError: (Object e) => setState(() => _error = SupabaseService.friendlyError(e)),
      );
    } catch (e) {
      if (mounted) setState(() => _error = SupabaseService.friendlyError(e));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<String> get _levels {
    final set = _bays.map((b) => b.level ?? 'Other').toSet().toList()..sort();
    return set.isEmpty ? ['L1'] : set;
  }

  String _statusOf(Bay b) => _pending[b.id] ?? b.status;

  void _toggle(Bay b) {
    if (b.status == Bay.reserved) {
      showOpSnack(context, 'Bay ${b.label} is held for a booking. Manage it from Bookings.');
      return;
    }
    final next = _statusOf(b) == Bay.available ? Bay.occupied : Bay.available;
    tapFeedback();
    setState(() {
      if (next == b.status) {
        _pending.remove(b.id);
      } else {
        _pending[b.id] = next;
      }
    });
  }

  Future<void> _publish() async {
    setState(() => _saving = true);
    try {
      final changes = Map<String, String>.from(_pending);
      await _svc.setBayStatuses(changes);
      if (!mounted) return;
      setState(() => _pending.clear());
      showOpSnack(context, '${changes.length} bay${changes.length == 1 ? '' : 's'} updated · drivers see it now');
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editBay([Bay? bay]) async {
    final level = _levels[_levelIndex.clamp(0, _levels.length - 1)];
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => _BaySheet(bay: bay, defaultLevel: level, existing: _bays),
    );
    if (result != null && mounted) showOpSnack(context, result);
  }

  Future<bool> _confirmLeave() async {
    if (_pending.isEmpty) return true;
    return confirmDialog(context, 'Discard changes?',
        'You changed ${_pending.length} bay(s) but did not tap "Update availability".',
        confirm: 'Discard', danger: true);
  }

  /// Marks every bay on the level free or occupied (held bays are left alone).
  /// Useful at opening/closing time or after a manual walk-round.
  void _setLevel(List<Bay> bays, String status) {
    tapFeedback();
    setState(() {
      for (final b in bays) {
        if (b.status == Bay.reserved) continue;
        if (b.status == status) {
          _pending.remove(b.id);
        } else {
          _pending[b.id] = status;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final levels = _levels;
    final idx = _levelIndex.clamp(0, levels.length - 1);
    final current = _bays.where((b) => (b.level ?? 'Other') == levels[idx]).toList();
    final free = _bays.where((b) => _statusOf(b) == Bay.available).length;
    final levelFree = current.where((b) => _statusOf(b) == Bay.available).length;
    final levelHeld = current.where((b) => b.status == Bay.reserved).length;
    final levelOccupied = current.length - levelFree - levelHeld;

    return PopScope(
      canPop: _pending.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmLeave()) {
          _pending.clear();
          nav.pop();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            OperatorHeader(
              title: 'Publish availability',
              subtitle: '$free free · ${_bays.length} bays',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LiveBadge(),
                  HeaderAction(icon: Icons.add, tooltip: 'Add bay', onTap: () => _editBay()),
                ],
              ),
            ),
            Expanded(
              child: _error != null
                  ? OpError(message: _error!, onRetry: _start)
                  : !_ready
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                          children: [
                            OpSegmented(
                              options: levels,
                              selected: idx,
                              onChanged: (i) => setState(() => _levelIndex = i),
                            ),
                            const SizedBox(height: 14),
                            if (current.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    StatusChip('$levelFree free', tone: ChipTone.success),
                                    const SizedBox(width: 6),
                                    StatusChip('$levelOccupied occupied'),
                                    if (levelHeld > 0) ...[
                                      const SizedBox(width: 6),
                                      StatusChip('$levelHeld held', tone: ChipTone.warning),
                                    ],
                                    const Spacer(),
                                    PopupMenuButton<String>(
                                      tooltip: 'Set whole level',
                                      onSelected: (v) => _setLevel(current, v),
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                            value: Bay.available, child: Text('Mark all ${levels[idx]} free')),
                                        PopupMenuItem(
                                            value: Bay.occupied, child: Text('Mark all ${levels[idx]} occupied')),
                                      ],
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Whole level',
                                                style: TextStyle(fontSize: 13, color: AppColors.primary)),
                                            Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (current.isEmpty)
                              const OpEmpty(
                                icon: Icons.local_parking,
                                message: 'No bays on this level yet.\nTap + to add one.',
                              )
                            else
                              OpCard(
                                padding: const EdgeInsets.all(12),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: current.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    mainAxisExtent: 64,
                                  ),
                                  itemBuilder: (_, i) {
                                    final b = current[i];
                                    return _BayTile(
                                      bay: b,
                                      status: _statusOf(b),
                                      changed: _pending.containsKey(b.id),
                                      onTap: () => _toggle(b),
                                      onLongPress: () => _editBay(b),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 16),
                            const Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _Legend(fill: AppColors.occupied, label: 'occupied'),
                                _Legend(outline: AppColors.success, label: 'free · tap to toggle'),
                                _Legend(fill: AppColors.warningBg, outline: AppColors.accent, label: 'held for booking'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text('Long-press a bay to rename or delete it.',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          ],
                        ),
            ),
            OpActionBar(children: [
              if (_pending.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_pending.length} change${_pending.length == 1 ? '' : 's'} not published yet',
                        style: const TextStyle(fontSize: 13, color: AppColors.warning),
                      ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : () => setState(_pending.clear),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text('Undo all', style: TextStyle(fontSize: 13.5)),
                    ),
                  ],
                ),
              OpButton(
                label: _pending.isEmpty
                    ? 'Update availability'
                    : 'Update availability (${_pending.length})',
                loading: _saving,
                onPressed: _pending.isEmpty ? null : _publish,
              ),
            ]),
          ],
        ),
        bottomNavigationBar: const OperatorBottomNav(currentIndex: 0),
      ),
    );
  }
}

class _BayTile extends StatelessWidget {
  const _BayTile({
    required this.bay,
    required this.status,
    required this.changed,
    required this.onTap,
    required this.onLongPress,
  });

  final Bay bay;
  final String status;
  final bool changed;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color? outline) = switch (status) {
      Bay.available => (Colors.white, AppColors.success),
      Bay.reserved => (AppColors.warningBg, AppColors.accent),
      _ => (AppColors.occupied, null),
    };
    final word = switch (status) {
      Bay.available => 'free',
      Bay.reserved => 'held',
      _ => 'occupied',
    };
    return Semantics(
      button: true,
      label: 'Bay ${bay.label}, $word${changed ? ', not published yet' : ''}',
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: outline == null ? BorderSide.none : BorderSide(color: outline, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(bay.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: status == Bay.occupied ? AppColors.primary : AppColors.textPrimary,
                        )),
                    if (bay.isEv) const Icon(Icons.ev_station, size: 12, color: AppColors.successDark),
                  ],
                ),
              ),
              if (changed)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({this.fill = Colors.white, this.outline, required this.label});
  final Color fill;
  final Color? outline;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
            border: outline == null ? null : Border.all(color: outline!, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
      ],
    );
  }
}

/// Add / edit / delete a bay. Pops with a message to show.
class _BaySheet extends StatefulWidget {
  const _BaySheet({this.bay, required this.defaultLevel, required this.existing});
  final Bay? bay;
  final String defaultLevel;
  final List<Bay> existing;

  @override
  State<_BaySheet> createState() => _BaySheetState();
}

class _BaySheetState extends State<_BaySheet> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.bay?.label ?? '');
  late final _level = TextEditingController(text: widget.bay?.level ?? widget.defaultLevel);
  late bool _ev = widget.bay?.isEv ?? false;
  bool _busy = false;

  bool get _isNew => widget.bay == null;

  String? _validateLabel(String? v) {
    final req = Validators.required(v, 'Bay label');
    if (req != null) return req;
    final clean = v!.trim().toUpperCase();
    if (clean.length > 8) return 'Keep the label short, e.g. B12';
    final taken = widget.existing.any((b) => b.label.toUpperCase() == clean && b.id != widget.bay?.id);
    return taken ? 'Bay $clean already exists' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final svc = OperatorService.instance;
    try {
      final type = _ev ? 'ev' : 'standard';
      if (_isNew) {
        await svc.addBay(label: _label.text, level: _level.text, type: type);
      } else {
        await svc.updateBay(widget.bay!.id, label: _label.text, level: _level.text, type: type);
      }
      if (mounted) Navigator.pop(context, _isNew ? 'Bay ${_label.text.trim().toUpperCase()} added' : 'Bay updated');
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final bay = widget.bay!;
    final ok = await confirmDialog(context, 'Delete bay ${bay.label}?',
        'Drivers will no longer see this bay. This cannot be undone.',
        confirm: 'Delete', danger: true);
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await OperatorService.instance.deleteBay(bay);
      if (mounted) Navigator.pop(context, 'Bay ${bay.label} deleted');
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_isNew ? 'Add bay' : 'Edit bay ${widget.bay!.label}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: OpField(
                      label: 'Bay label',
                      hint: 'B13',
                      controller: _label,
                      textCapitalization: TextCapitalization.characters,
                      validator: _validateLabel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OpField(
                      label: 'Level',
                      hint: 'L1',
                      controller: _level,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => Validators.required(v, 'Level'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _ev,
                onChanged: (v) => setState(() => _ev = v),
                activeTrackColor: AppColors.success,
                title: const Text('EV charging bay', style: TextStyle(fontSize: 14.5)),
              ),
              const SizedBox(height: 8),
              OpButton(label: _isNew ? 'Add bay' : 'Save changes', loading: _busy, onPressed: _save),
              if (!_isNew) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _busy ? null : _delete,
                  child: const Text('Delete bay', style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
