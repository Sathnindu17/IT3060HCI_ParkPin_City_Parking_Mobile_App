import 'package:flutter/material.dart';

import '../widgets/parking_ui.dart';

class BookingHistoryEmptyScreen extends StatefulWidget {
  final bool preview;
  final VoidCallback? onFindParking;
  final ValueChanged<int>? onNavigate;

  const BookingHistoryEmptyScreen({
    super.key,
    this.preview = true,
    this.onFindParking,
    this.onNavigate,
  });

  @override
  State<BookingHistoryEmptyScreen> createState() =>
      _BookingHistoryEmptyScreenState();
}

class _BookingHistoryEmptyScreenState
    extends State<BookingHistoryEmptyScreen> {
  bool _showUpcoming = true;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _findParking() {
    final callback = widget.onFindParking;

    if (callback != null) {
      callback();
      return;
    }

    _showMessage(
      widget.preview
          ? 'Preview: Find parking will open your parking search screen.'
          : 'Parking search has not been connected yet.',
    );
  }

  void _navigate(int index) {
    if (index == 1) {
      return;
    }

    final callback = widget.onNavigate;

    if (callback != null) {
      callback(index);
      return;
    }

    const pageNames = [
      'Home',
      'Bookings',
      'Receipts',
      'Profile',
    ];

    _showMessage(
      '${pageNames[index]} navigation will be connected when the app screens are integrated.',
    );
  }

  Widget _tab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? ParkingStyle.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : ParkingStyle.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyIllustration() {
    return SizedBox(
      width: 180,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 158,
            height: 158,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEEF3FA),
            ),
          ),
          Positioned(
            top: 18,
            right: 16,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE5B5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 13,
            bottom: 27,
            child: Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                color: Color(0xFFC7D6EB),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0xFFDDE6F3),
              ),
              boxShadow: [
                BoxShadow(
                  color: ParkingStyle.navy.withAlpha(15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 66,
              color: ParkingStyle.navy,
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ParkingStyle.orange,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ParkingStyle.background,
                  width: 4,
                ),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: ParkingStyle.navy,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _emptyIllustration(),
        const SizedBox(height: 22),
        Text(
          _showUpcoming ? 'No bookings yet' : 'No past bookings yet',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ParkingStyle.text,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 290),
          child: Text(
            _showUpcoming
                ? 'Your reserved parking bays will appear here once you book.'
                : 'Your completed parking sessions will appear here after your visit.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ParkingStyle.muted,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 26),
        ParkingCard(
          color: const Color(0xFFFFF7E9),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9C2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_parking_rounded,
                  color: ParkingStyle.navy,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan your next stop',
                      style: TextStyle(
                        color: ParkingStyle.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Find a parking location and reserve a bay before you arrive.',
                      style: TextStyle(
                        color: ParkingStyle.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.preview) const ParkingPreviewLabel(),
      ],
    );
  }

  Widget _findParkingButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _findParking,
          style: ElevatedButton.styleFrom(
            backgroundColor: ParkingStyle.orange,
            foregroundColor: ParkingStyle.navy,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded, size: 23),
              SizedBox(width: 10),
              Text(
                'Find parking',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded, size: 21),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParkingStyle.background,
      appBar: AppBar(
        backgroundColor: ParkingStyle.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 72,
        title: const Text(
          'Your bookings',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE8EDF5),
                  ),
                ),
                child: Row(
                  children: [
                    _tab(
                      label: 'Upcoming',
                      selected: _showUpcoming,
                      onTap: () {
                        setState(() => _showUpcoming = true);
                      },
                    ),
                    const SizedBox(width: 6),
                    _tab(
                      label: 'Past',
                      selected: !_showUpcoming,
                      onTap: () {
                        setState(() => _showUpcoming = false);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minimumHeight = constraints.maxHeight > 48
                      ? constraints.maxHeight - 48
                      : 0.0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: minimumHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 380,
                          ),
                          child: _emptyContent(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _findParkingButton(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color(0xFFE8EDF5),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          onTap: _navigate,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: ParkingStyle.navy,
          unselectedItemColor: ParkingStyle.muted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_month_rounded),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Receipts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}