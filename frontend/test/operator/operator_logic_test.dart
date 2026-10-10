import 'package:flutter_test/flutter_test.dart';
import 'package:parkpin/features/operator/services/operator_service.dart';
import 'package:parkpin/features/operator/widgets/operator_ui.dart';
import 'package:parkpin/models/bay.dart';
import 'package:parkpin/models/booking.dart';

/// Unit tests for the operator feature (traceability: TC-O03, TC-O04, TC-O06, TC-O08).
void main() {
  Bay bay(String label, String level, [String status = Bay.available]) =>
      Bay(id: label, facilityId: 'f', label: label, level: level, type: 'standard', status: status);

  Booking booking({String status = Booking.reserved, String? bayId}) => Booking.fromMap({
        'id': 'b1',
        'driver_id': 'd1',
        'facility_id': 'f',
        'bay_id': bayId,
        'start_time': DateTime.now().toUtc().toIso8601String(),
        'end_time': DateTime.now().add(const Duration(hours: 2)).toUtc().toIso8601String(),
        'status': status,
        'booking_code': 'PP-DEMO01',
        'profiles': {'full_name': 'Kavindu M.'},
        'bays': bayId == null ? null : {'label': 'B3', 'level': 'L1'},
      });

  group('TC-O06 off-peak pricing', () {
    test('30% off Rs 100 is Rs 70', () => expect(OperatorService.offPeakRate(100, 30), 70));
    test('0% keeps the standard rate', () => expect(OperatorService.offPeakRate(120, 0), 120));
    test('discount is recovered from saved rates', () => expect(OperatorService.discountFrom(100, 70), 30));
    test('zero standard rate gives 0% (no divide by zero)', () => expect(OperatorService.discountFrom(0, 50), 0));
  });

  group('TC-O03 bay ordering', () {
    test('sorts by level then number (B2 before B10)', () {
      final list = [bay('B10', 'L1'), bay('B2', 'L1'), bay('B1', 'L2')]..sort(Bay.compare);
      expect(list.map((b) => b.label), ['B2', 'B10', 'B1']);
    });
  });

  group('TC-O04 booking status labels', () {
    test('reserved without bay needs a bay', () => expect(bookingStatus(booking()).$1, 'needs bay'));
    test('reserved with bay is on hold', () => expect(bookingStatus(booking(bayId: 'x')).$1, 'hold'));
    test('active is checked in', () => expect(bookingStatus(booking(status: Booking.active, bayId: 'x')).$1, 'checked in'));
    test('expired shows no-show', () => expect(bookingStatus(booking(status: Booking.expired)).$1, 'no-show'));
    test('joined driver and bay are read', () {
      final b = booking(bayId: 'x');
      expect(b.driverName, 'Kavindu M.');
      expect(b.bayDisplay, 'B3 · L1');
    });
  });

  group('TC-O08 gate code entry', () {
    test('lower-case typed code is normalised', () => expect(extractBookingCode(' pp-demo01 '), 'PP-DEMO01'));
    test('code is pulled out of a longer QR payload', () => expect(extractBookingCode('parkpin://booking/PP-8A41C2'), 'PP-8A41C2'));
    test('short code without PP- gets the prefix', () => expect(extractBookingCode('demo03'), 'PP-DEMO03'));
    test('empty input stays empty', () => expect(extractBookingCode('  '), ''));
  });

  group('TC-O02 arrival times', () {
    final now = DateTime(2026, 10, 9, 14, 0);
    test('upcoming in minutes', () => expect(arrivalLabel(DateTime(2026, 10, 9, 14, 20), now), 'in 20 min'));
    test('upcoming in hours', () => expect(arrivalLabel(DateTime(2026, 10, 9, 16, 5), now), 'in 2 h 5 min'));
    test('right now', () => expect(arrivalLabel(DateTime(2026, 10, 9, 14, 1), now), 'now'));
    test('late', () => expect(arrivalLabel(DateTime(2026, 10, 9, 13, 40), now), '20 min late'));
    test('late only after the grace period', () {
      Booking at(DateTime t) => Booking.fromMap({
            'id': 'x',
            'driver_id': 'd',
            'facility_id': 'f',
            'start_time': t.toUtc().toIso8601String(),
            'end_time': t.add(const Duration(hours: 2)).toUtc().toIso8601String(),
            'status': Booking.reserved,
            'booking_code': 'PP-X',
          });
      expect(isLate(at(DateTime(2026, 10, 9, 13, 50)), now), isFalse); // 10 min
      expect(isLate(at(DateTime(2026, 10, 9, 13, 40)), now), isTrue); // 20 min
    });
  });

  test('money format', () => expect(rs(9050), 'Rs 9,050'));
}
