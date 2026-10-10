import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/features/operator/services/operator_service.dart';
import 'package:parkpin/features/operator/widgets/operator_ui.dart';
import 'package:parkpin/models/booking.dart';
import 'package:parkpin/services/supabase_service.dart';

/// O08 – Gate check (Figma "Operator · Gate check").
/// Scan the driver's QR or type the booking code, then admit (check in) or
/// check out. Manual entry is the fallback when the camera is not available
/// (e.g. on the emulator – documented deviation).
class OperatorGateCheckScreen extends StatefulWidget {
  const OperatorGateCheckScreen({super.key});

  @override
  State<OperatorGateCheckScreen> createState() => _OperatorGateCheckScreenState();
}

enum _Verdict { valid, early, inside, invalid, notFound, admitted }

/// One line in the "Recent at this gate" log.
typedef _GateEvent = ({DateTime at, String code, String text, ChipTone tone});

class _OperatorGateCheckScreenState extends State<OperatorGateCheckScreen> {
  final _svc = OperatorService.instance;
  final _code = TextEditingController();

  Booking? _booking;
  _Verdict? _verdict;
  String? _admittedBay;
  bool _checking = false;
  bool _acting = false;

  /// Kept while the app is open, so staff can look back at the last cars.
  static final List<_GateEvent> _log = [];

  void _logEvent(String code, String text, ChipTone tone) {
    _log.insert(0, (at: DateTime.now(), code: code, text: text, tone: tone));
    if (_log.length > 8) _log.removeLast();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _ScannerPage()),
    );
    if (raw == null || !mounted) return;
    _code.text = extractBookingCode(raw);
    await _check();
  }

  Future<void> _check() async {
    FocusScope.of(context).unfocus();
    final code = extractBookingCode(_code.text);
    if (code.isEmpty) {
      showOpSnack(context, 'Scan the QR or type the booking code first.', error: true);
      return;
    }
    _code.text = code;
    setState(() {
      _checking = true;
      _verdict = null;
      _booking = null;
    });
    try {
      await _svc.ensureLoaded();
      final b = await _svc.findByCode(code);
      if (!mounted) return;
      final _Verdict verdict;
      if (b == null) {
        verdict = _Verdict.notFound;
      } else if (b.status == Booking.active) {
        verdict = _Verdict.inside;
      } else if (b.status == Booking.reserved) {
        verdict = isToday(b.startTime) ? _Verdict.valid : _Verdict.early;
      } else {
        verdict = _Verdict.invalid;
      }
      // Different vibration for "OK" and "problem" so staff notice without looking.
      if (verdict == _Verdict.notFound || verdict == _Verdict.invalid) {
        HapticFeedback.heavyImpact();
        _logEvent(code, verdict == _Verdict.notFound ? 'Not found' : 'Refused · ${bookingStatus(b!).$1}',
            ChipTone.danger);
      } else {
        HapticFeedback.lightImpact();
      }
      setState(() {
        _booking = b;
        _verdict = verdict;
      });
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _admit() async {
    setState(() => _acting = true);
    try {
      final bay = await _svc.admit(_booking!);
      _logEvent(_booking!.bookingCode, 'Admitted · bay $bay', ChipTone.success);
      if (!mounted) return;
      setState(() {
        _admittedBay = bay;
        _verdict = _Verdict.admitted;
      });
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _checkOut() async {
    setState(() => _acting = true);
    try {
      await _svc.checkOut(_booking!);
      _logEvent(_booking!.bookingCode, 'Checked out · bay ${_booking!.bayLabel ?? '-'} freed', ChipTone.neutral);
      if (!mounted) return;
      showOpSnack(context, 'Checked out · bay ${_booking!.bayLabel ?? ''} is free again');
      _reset();
    } catch (e) {
      if (mounted) showOpSnack(context, SupabaseService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  void _reset() {
    setState(() {
      _code.clear();
      _booking = null;
      _verdict = null;
      _admittedBay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OperatorHeader(title: 'Gate check', subtitle: 'Scan booking to admit'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
              children: [
                const OpPageIntro(
                  title: 'Check drivers in and out',
                  subtitle: 'Scan the QR on the driver\'s phone, or type the booking code.',
                ),
                Semantics(
                  button: true,
                  label: 'Open camera to scan booking QR',
                  child: Material(
                    color: AppColors.scanner,
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _scan,
                      child: SizedBox(
                        height: 170,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.accent, width: 2.5),
                              ),
                              child: Icon(Icons.qr_code_scanner, size: 40, color: Colors.white.withValues(alpha: 0.9)),
                            ),
                            const SizedBox(height: 14),
                            const Text('Tap to scan QR',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(height: 3),
                            Text('Camera opens full screen',
                                style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Or enter booking code',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: OpStyle.ink)),
                const SizedBox(height: 7),
                TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _check(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                  decoration: opInputDecoration(
                    hint: 'PP-8A41C2 or just 8A41C2',
                    prefixIcon: Icons.confirmation_number_outlined,
                    suffix: _checking
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : IconButton(
                            tooltip: 'Check code',
                            onPressed: _check,
                            icon: const Icon(Icons.arrow_forward, size: 22, color: AppColors.primary),
                          ),
                  ),
                ),
                if (_verdict != null) ...[
                  const SizedBox(height: 16),
                  _ResultCard(verdict: _verdict!, booking: _booking, code: _code.text, admittedBay: _admittedBay),
                ],
                if (_log.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const SectionLabel('Recent at this gate'),
                  OpCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      children: [
                        for (var i = 0; i < _log.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              border: i == _log.length - 1
                                  ? null
                                  : const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 52,
                                  child: Text(hhmm(_log[i].at),
                                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                                ),
                                Expanded(
                                  child: Text(_log[i].code,
                                      style: const TextStyle(
                                          fontSize: 14.5, fontWeight: FontWeight.w700, color: OpStyle.ink)),
                                ),
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: StatusChip(_log[i].text, tone: _log[i].tone),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          OpActionBar(children: [
            switch (_verdict) {
              _Verdict.valid || _Verdict.early => OpButton(
                  label: _verdict == _Verdict.early ? 'Admit anyway & assign bay' : 'Admit & assign bay',
                  loading: _acting,
                  onPressed: _admit,
                ),
              _Verdict.inside => OpButton(label: 'Check out', loading: _acting, onPressed: _checkOut),
              null => OpButton(label: 'Check booking', loading: _checking, onPressed: _check),
              _ => OpButton(label: 'Next driver', outlined: true, onPressed: _reset),
            },
          ]),
        ],
      ),
      bottomNavigationBar: const OperatorBottomNav(currentIndex: 2),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.verdict, required this.booking, required this.code, this.admittedBay});
  final _Verdict verdict;
  final Booking? booking;
  final String code;
  final String? admittedBay;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final window = b == null ? '' : '${hhmm(b.startTime)}–${hhmm(b.endTime)}';
    final who = b == null ? '' : '${b.driverName ?? 'Driver'} · $window';
    final bay = b?.bayLabel == null ? 'bay assigned at gate' : 'Bay ${b!.bayDisplay}';

    final (IconData icon, Color fg, Color bg, String title, String sub) = switch (verdict) {
      _Verdict.valid => (Icons.check_circle_outline, AppColors.successDark, AppColors.successBg, 'Valid · $bay', who),
      _Verdict.early => (
          Icons.event_outlined,
          AppColors.warning,
          AppColors.warningBg,
          'Booked for ${DateFormat('d MMM').format(b!.startTime)} · $bay',
          '$who · not today',
        ),
      _Verdict.inside => (Icons.local_parking, AppColors.warning, AppColors.warningBg, 'Already inside · $bay', who),
      _Verdict.admitted => (
          Icons.check_circle,
          AppColors.successDark,
          AppColors.successBg,
          'Admitted · park in bay $admittedBay',
          'Driver notified · gate log saved',
        ),
      _Verdict.notFound => (
          Icons.cancel_outlined,
          AppColors.danger,
          AppColors.dangerBg,
          'No booking found',
          'Code $code is not a booking at this car park',
        ),
      _Verdict.invalid => (
          Icons.block,
          AppColors.danger,
          AppColors.dangerBg,
          'Not valid · ${bookingStatus(b!).$1}',
          who,
        ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: fg, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: fg)),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(sub, style: TextStyle(fontSize: 13.5, color: fg)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen camera that returns the first QR it reads.
class _ScannerPage extends StatefulWidget {
  const _ScannerPage();

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final value = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (value == null || value.isEmpty) return;
    _done = true;
    Navigator.of(context).pop(value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    tooltip: 'Close scanner',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Point at the QR on the driver\'s phone.\nNo camera? Close this and type the code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
