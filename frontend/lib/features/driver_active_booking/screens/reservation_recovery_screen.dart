import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/reservation_recovery_service.dart';
import '../widgets/parking_ui.dart';

class ReservationRecoveryScreen extends StatefulWidget {
  final String? bookingId;

  final String unavailableBayLabel;
  final String alternativeBayLabel;

  final Future<void> Function()? onAcceptAlternative;
  final VoidCallback? onFindAnotherParking;

  const ReservationRecoveryScreen({
    super.key,
    this.bookingId,
    this.unavailableBayLabel = 'B3',
    this.alternativeBayLabel = 'B4',
    this.onAcceptAlternative,
    this.onFindAnotherParking,
  });

  @override
  State<ReservationRecoveryScreen> createState() =>
      _ReservationRecoveryScreenState();
}

class _ReservationRecoveryScreenState
    extends State<ReservationRecoveryScreen> {
  ReservationRecoveryService? _service;
  ReservationRecovery? _recovery;
  RecoveryBay? _selectedBay;

  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _connected => widget.bookingId != null;

  bool get _preview =>
      !_connected &&
      widget.onAcceptAlternative == null &&
      widget.onFindAnotherParking == null;

  String get _oldLabel =>
      _recovery?.unavailableBayLabel ?? widget.unavailableBayLabel;

  String get _alternativeLabel =>
      _selectedBay?.label ?? widget.alternativeBayLabel;

  @override
  void initState() {
    super.initState();

    if (_connected) {
      _service = ReservationRecoveryService();
      _load();
    }
  }

  String _errorMessage(Object error) {
    if (error is PostgrestException) return error.message;
    if (error is AuthException) return error.message;
    if (error is StateError) return error.message.toString();

    return 'Could not complete this action. Please try again.';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _load() async {
    if (!_connected || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
      _recovery = null;
      _selectedBay = null;
    });

    try {
      final recovery = await _service!.load(widget.bookingId!);

      if (!mounted) return;

      setState(() {
        _recovery = recovery;
        _selectedBay = recovery.alternatives.isEmpty
            ? null
            : recovery.alternatives.first;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _acceptAlternative() async {
    if (_saving || _loading) return;

    if (_connected &&
        (_recovery == null || _selectedBay == null)) {
      _showMessage('No alternative bay is currently available.');
      return;
    }

    if (!_connected && widget.onAcceptAlternative == null) {
      _showMessage(
        'Design preview only. No parking bay has been reassigned.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_connected) {
        await _service!.accept(
          recovery: _recovery!,
          bay: _selectedBay!,
        );
      } else {
        await widget.onAcceptAlternative!();
      }

      if (!mounted) return;

      setState(() => _saving = false);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = _errorMessage(error);
      });
    }
  }

  void _findAnotherParking() {
    if (_saving || _loading) return;

    final callback = widget.onFindAnotherParking;

    if (callback != null) {
      callback();
      return;
    }

    _showMessage(
      'Parking search will be connected during integration. '
      'Your reservation has not been cancelled.',
    );
  }

  Widget _alternativeCard() {
    final recovery = _recovery;

    final noAlternative =
        _connected && recovery != null && recovery.alternatives.isEmpty;

    if (noAlternative) {
      return const ParkingCard(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: ParkingStyle.muted,
            ),
            SizedBox(height: 14),
            Text(
              'No matching bay available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ParkingStyle.navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Refresh to check again or look for another parking facility.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ParkingStyle.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F6ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB7DFC6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ALTERNATIVE FOUND',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: Color(0xFF16864B),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.local_parking_rounded,
                  color: Color(0xFF16864B),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bay $_alternativeLabel',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17623B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _connected
                          ? '${_selectedBay?.level ?? ''} · same price'
                          : 'Same level · same price',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF39855A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_connected) ...[
            const SizedBox(height: 16),
            const Text(
              'Availability is checked again when you accept.',
              style: TextStyle(
                color: Color(0xFF39855A),
                fontSize: 12,
              ),
            ),
          ],
          if (recovery != null && recovery.alternatives.length > 1) ...[
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _selectedBay?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Choose alternative bay',
                border: OutlineInputBorder(),
              ),
              items: recovery.alternatives.map((bay) {
                return DropdownMenuItem<String>(
                  value: bay.id,
                  child: Text('Bay ${bay.label} · ${bay.level}'),
                );
              }).toList(),
              onChanged: _saving
                  ? null
                  : (id) {
                      if (id == null) return;

                      setState(() {
                        _selectedBay = recovery.alternatives.firstWhere(
                          (bay) => bay.id == id,
                        );
                      });
                    },
            ),
          ],
        ],
      ),
    );
  }

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0D7),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFE5B4),
                width: 8,
              ),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFDC8B12),
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Bay unavailable',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: ParkingStyle.navy,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Bay $_oldLabel can no longer be used.\n'
          'Choose an available alternative below.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: ParkingStyle.muted,
          ),
        ),
        if (_recovery != null) ...[
          const SizedBox(height: 12),
          Text(
            '${_recovery!.facilityName}\n${_recovery!.bookingCode}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ParkingStyle.navy,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 30),
        _alternativeCard(),
        const SizedBox(height: 18),
        const ParkingCard(
          padding: EdgeInsets.all(18),
          child: ParkingInfoRow(
            icon: Icons.swap_horiz_rounded,
            title: 'Keep your parking plans',
            subtitle:
                'Accepting changes only your bay. '
                'Your reservation times and price stay the same.',
          ),
        ),
        if (_preview) const ParkingPreviewLabel(),
        if (_error != null) ...[
          const SizedBox(height: 18),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          if (_connected)
            TextButton(
              onPressed: _saving ? null : _load,
              child: const Text('Refresh alternatives'),
            ),
        ],
      ],
    );
  }

  Widget _loadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ParkingCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: ParkingStyle.navy,
                size: 42,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Could not load this reservation.',
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _load,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showFooter =
        !_loading && (!_connected || _recovery != null);

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: ParkingStyle.background,
        appBar: AppBar(
          backgroundColor: ParkingStyle.background,
          foregroundColor: ParkingStyle.navy,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Reservation recovery',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _saving
                ? null
                : () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actions: [
            if (_connected)
              IconButton(
                tooltip: 'Refresh alternatives',
                onPressed: _saving || _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ParkingStyle.orange,
                      ),
                    )
                  : _connected && _recovery == null
                      ? _loadError()
                      : _content(),
            ),
          ),
        ),
        bottomNavigationBar: showFooter
            ? ParkingFooter(
                primaryLabel: _connected && _selectedBay == null
                    ? 'No alternative available'
                    : 'Accept Bay $_alternativeLabel',
                onPrimary: _acceptAlternative,
                secondaryLabel: 'Find another parking',
                onSecondary: _findAnotherParking,
                footnote: 'No extra reservation charge',
                busy: _saving,
              )
            : null,
      ),
    );
  }
}