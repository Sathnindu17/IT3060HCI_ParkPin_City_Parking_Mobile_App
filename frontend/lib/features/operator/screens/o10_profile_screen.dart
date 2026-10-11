import 'package:flutter/material.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/core/routes/app_routes.dart';
import 'package:parkpin/core/utils/validators.dart';
import 'package:parkpin/features/operator/operator_routes.dart';
import 'package:parkpin/features/operator/services/operator_service.dart';
import 'package:parkpin/features/operator/widgets/operator_ui.dart';
import 'package:parkpin/services/supabase_service.dart';

/// O10 – Profile, car-park settings & gate integration
/// (Figma "Operator · O10 Profile & Gate Integration").
class OperatorProfileScreen extends StatefulWidget {
  const OperatorProfileScreen({super.key});

  @override
  State<OperatorProfileScreen> createState() => _OperatorProfileScreenState();
}

class _OperatorProfileScreenState extends State<OperatorProfileScreen> {
  final _svc = OperatorService.instance;
  bool _ready = false;
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
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = SupabaseService.friendlyError(e));
    }
  }

  Future<void> _sheet(Widget child) async {
    final msg = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => child,
    );
    if (!mounted) return;
    setState(() {}); // show updated name / facility
    if (msg != null) showOpSnack(context, msg);
  }

  void _staffAccess() {
    final p = _svc.profile!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Staff access', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoRow('Signed in as', _svc.email ?? '—'),
            InfoRow('Role', 'Car-park operator'),
            InfoRow('Car park', _svc.facility?.name ?? '—', last: true),
            const SizedBox(height: 10),
            Text(
              'Roles are set by the ParkPin admin team. ${p.firstName} can manage bays, bookings, pricing '
              'and the gate for this car park only.',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  void _gateSetup() {
    final f = _svc.facility!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gate / ticketing setup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const InfoRow('Entry check', 'QR scan or booking code'),
            const InfoRow('Ticketing', 'Cashless (in-app)'),
            InfoRow('Reservation fee', rs(f.reservationFee)),
            InfoRow('Standard rate', '${rs(f.ratePerHour)}/hr', last: true),
            const SizedBox(height: 10),
            const Text(
              'Barrier hardware integration is outside this prototype. Staff verify each driver on the '
              'Gate check screen.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamed(OperatorRoutes.pricing);
            },
            child: const Text('Edit pricing'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(context, 'Log out?', 'You will need to sign in again to manage this car park.',
        confirm: 'Log out', danger: true);
    if (!ok) return;
    try {
      await _svc.signOut();
    } catch (_) {
      // Signing out locally still works when offline.
    }
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.roleSelection, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final p = _svc.profile;
    final f = _svc.facility;
    return Scaffold(
      body: Column(
        children: [
          const OperatorHeader(title: 'Profile'),
          Expanded(
            child: _error != null
                ? OpError(message: _error!, onRetry: _load)
                : !_ready || p == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        children: [
                          OpHeroCard(
                            child: Row(
                              children: [
                                Semantics(
                                  button: true,
                                  label: 'Edit my details',
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => _sheet(const _ProfileSheet()),
                                    child: CircleAvatar(
                                      radius: 34,
                                      backgroundColor: Colors.white,
                                      child: Text(p.initials,
                                          style: const TextStyle(
                                              fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.fullName.isEmpty ? 'Operator' : p.fullName,
                                          style: const TextStyle(
                                              fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                                      const SizedBox(height: 3),
                                      Text('Operator · ${f?.name ?? ''}',
                                          style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.85))),
                                      const SizedBox(height: 10),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => _sheet(const _ProfileSheet()),
                                        child: const HeroPill('Edit my details'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (f != null) ...[
                            OpCard(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  _Stat(value: '${f.totalBays}', label: 'bays'),
                                  const _StatDivider(),
                                  _Stat(value: rs(f.ratePerHour), label: 'per hour'),
                                  const _StatDivider(),
                                  _Stat(value: rs(f.reservationFee), label: 'reservation fee'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            const SectionLabel('Settings'),
                          ],
                          OpCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Column(
                              children: [
                                _MenuRow('Car park details', icon: Icons.local_parking, onTap: () => _sheet(const _FacilitySheet())),
                                _MenuRow('Staff access', icon: Icons.badge_outlined, onTap: _staffAccess),
                                _MenuRow('Gate / ticketing setup', icon: Icons.confirmation_number_outlined, onTap: _gateSetup),
                                _MenuRow('QR / code verification', icon: Icons.qr_code_scanner,
                                    onTap: () => Navigator.of(context).pushNamed(OperatorRoutes.gate)),
                                _MenuRow('Payments & records', icon: Icons.receipt_long_outlined,
                                    onTap: () => Navigator.of(context).pushNamed(OperatorRoutes.payments)),
                                _MenuRow('Notifications', icon: Icons.notifications_none,
                                    onTap: () => Navigator.of(context).pushNamed(OperatorRoutes.notifications)),
                                _MenuRow('Log out', icon: Icons.logout, danger: true, last: true, onTap: _logout),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const OperatorBottomNav(currentIndex: 3),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: OpStyle.ink)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(width: 0.5, height: 28, color: AppColors.border);
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.label, {required this.onTap, required this.icon, this.danger = false, this.last = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        child: Row(
          children: [
            OpIconBadge(
              icon: icon,
              size: 40,
              background: danger ? AppColors.dangerBg : OpStyle.tileBg,
              color: danger ? AppColors.danger : AppColors.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: danger ? AppColors.danger : OpStyle.ink)),
            ),
            if (!danger) const Icon(Icons.chevron_right, size: 22, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Edit the operator's own name and phone (profiles U).
class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final _svc = OperatorService.instance;
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: _svc.profile?.fullName ?? '');
  late final _phone = TextEditingController(text: _svc.profile?.phone ?? '');
  bool _busy = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await _svc.updateProfile(fullName: _name.text, phone: _phone.text.trim().isEmpty ? null : _phone.text);
      if (mounted) Navigator.pop(context, 'Your details were saved');
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'My details',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OpField(
              label: 'Full name',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.required(v, 'Name'),
            ),
            const SizedBox(height: 10),
            OpField(
              label: 'Phone (optional)',
              controller: _phone,
              hint: '077 123 4567',
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 14),
            OpButton(label: 'Save', loading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

/// Edit car-park name and address (parking_facilities U).
class _FacilitySheet extends StatefulWidget {
  const _FacilitySheet();

  @override
  State<_FacilitySheet> createState() => _FacilitySheetState();
}

class _FacilitySheetState extends State<_FacilitySheet> {
  final _svc = OperatorService.instance;
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: _svc.facility?.name ?? '');
  late final _address = TextEditingController(text: _svc.facility?.address ?? '');
  bool _busy = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await _svc.updateFacility(name: _name.text, address: _address.text);
      if (mounted) Navigator.pop(context, 'Car park details saved');
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = _svc.facility;
    return _SheetFrame(
      title: 'Car park details',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OpField(
              label: 'Car park name',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.required(v, 'Car park name'),
            ),
            const SizedBox(height: 10),
            OpField(
              label: 'Address',
              controller: _address,
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.required(v, 'Address'),
            ),
            if (f != null) ...[
              const SizedBox(height: 10),
              Text(
                '${f.totalBays} bays · ${f.amenities.isEmpty ? 'no amenities listed' : f.amenities.join(', ')}'
                '${f.isVerifiedLegal ? ' · verified legal car park' : ''}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 14),
            OpButton(label: 'Save', loading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
