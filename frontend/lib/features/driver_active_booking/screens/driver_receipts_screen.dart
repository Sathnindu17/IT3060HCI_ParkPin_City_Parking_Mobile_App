import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/booking_history_service.dart';
import '../widgets/parking_ui.dart';
import 'receipt_screen.dart';

class DriverReceiptsScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const DriverReceiptsScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<DriverReceiptsScreen> createState() =>
      _DriverReceiptsScreenState();
}

class _DriverReceiptsScreenState
    extends State<DriverReceiptsScreen> {
  final _service = BookingHistoryService();

  List<HistoryBooking> _items = [];

  bool _loading = true;
  bool _opening = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _errorMessage(Object error) {
    if (error is PostgrestException) {
      return error.message;
    }

    if (error is AuthException) {
      return error.message;
    }

    if (error is StateError) {
      return error.message.toString();
    }

    return 'Could not complete this action. Please try again.';
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final history = await _service.loadHistory();

      final receipts = history
          .where((booking) => booking.receipt != null)
          .toList();

      receipts.sort(
        (a, b) =>
            b.receipt!.paidAt.compareTo(a.receipt!.paidAt),
      );

      if (!mounted) return;

      setState(() {
        _items = receipts;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _errorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openReceipt(HistoryBooking booking) async {
    if (_opening || _loading) return;

    final receipt = booking.receipt;

    if (receipt == null) return;

    setState(() {
      _opening = true;
    });

    try {
      await _service.markReceiptViewed(booking.id);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptScreen(
            receipt: receipt,
            preview: false,
            onNavigate: widget.onNavigate,
          ),
        ),
      );

      if (mounted) {
        await _load();
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_errorMessage(error)),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _money(int cents) {
    return 'Rs ${(cents / 100).toStringAsFixed(2)}';
  }

  void _navigate(int index) {
    if (_opening || index == 2) return;

    widget.onNavigate(index);
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ParkingStyle.navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 36,
            color: ParkingStyle.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your parking receipts',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'View your completed parking payments '
            'and export a receipt as PDF.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_items.length} '
            '${_items.length == 1 ? 'receipt' : 'receipts'}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: ParkingStyle.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptCard(HistoryBooking booking) {
    final receipt = booking.receipt!;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE8EDF5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _opening
            ? null
            : () {
                _openReceipt(booking);
              },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ParkingStyle.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: ParkingStyle.navy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.facilityName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ParkingStyle.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      booking.reference,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParkingStyle.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatDate(receipt.paidAt)}'
                      ' · Bay ${receipt.bayLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParkingStyle.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _money(receipt.totalCents),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: ParkingStyle.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      receipt.paymentLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParkingStyle.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: ParkingStyle.navy,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const ParkingCard(
      padding: EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 58,
            color: ParkingStyle.muted,
          ),
          SizedBox(height: 18),
          Text(
            'No receipts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ParkingStyle.navy,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Complete a paid parking session '
            'to create your final receipt.',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.5,
              color: ParkingStyle.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ParkingCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: ParkingStyle.muted,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load receipts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ParkingStyle.navy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _load,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return RefreshIndicator(
      onRefresh: _load,
      color: ParkingStyle.orange,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _header(),
          const SizedBox(height: 24),
          if (_opening)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(
                color: ParkingStyle.orange,
              ),
            ),
          if (_items.isEmpty)
            _emptyState()
          else
            ..._items.map(_receiptCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParkingStyle.background,
      appBar: AppBar(
        title: const Text(
          'Receipts',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: ParkingStyle.navy,
          ),
        ),
        backgroundColor: ParkingStyle.background,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh receipts',
            onPressed:
                _loading || _opening ? null : _load,
            icon: const Icon(
              Icons.refresh_rounded,
              color: ParkingStyle.navy,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: ParkingStyle.orange,
                ),
              )
            : _error != null
                ? _errorState()
                : _content(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: ParkingStyle.navy,
        unselectedItemColor: ParkingStyle.muted,
        onTap: _navigate,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Receipts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}