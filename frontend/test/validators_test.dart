import 'package:flutter_test/flutter_test.dart';
import 'package:parkpin/core/utils/validators.dart';

/// Unit tests for the shared form validators (O01, O03, O06, O10).
void main() {
  group('required', () {
    test('null is rejected', () => expect(Validators.required(null, 'Name'), 'Name is required'));
    test('blank is rejected', () => expect(Validators.required('   ', 'Level'), 'Level is required'));
    test('default field name', () => expect(Validators.required(''), 'This field is required'));
    test('text is accepted', () => expect(Validators.required('L1', 'Level'), isNull));
  });

  group('email (O01)', () {
    test('empty', () => expect(Validators.email(''), 'Enter your email'));
    test('null', () => expect(Validators.email(null), 'Enter your email'));
    test('missing @', () => expect(Validators.email('operator.parkpin.lk'), isNotNull));
    test('missing domain dot', () => expect(Validators.email('op@parkpin'), isNotNull));
    test('contains space', () => expect(Validators.email('op @parkpin.lk'), isNotNull));
    test('valid', () => expect(Validators.email('op@parkpin.lk'), isNull));
    test('surrounding spaces are trimmed', () => expect(Validators.email('  op@parkpin.lk  '), isNull));
  });

  group('password (O01)', () {
    test('empty', () => expect(Validators.password(''), 'Enter your password'));
    test('null', () => expect(Validators.password(null), 'Enter your password'));
    test('5 chars too short', () => expect(Validators.password('12345'), 'Password must be at least 6 characters'));
    test('6 chars ok', () => expect(Validators.password('123456'), isNull));
  });

  group('numberInRange (O06 rate 10–1000)', () {
    String? rate(String? v) => Validators.numberInRange(v, 10, 1000, 'Rate');
    test('empty', () => expect(rate(''), 'Rate must be a number'));
    test('null', () => expect(rate(null), 'Rate must be a number'));
    test('letters', () => expect(rate('abc'), 'Rate must be a number'));
    test('below min', () => expect(rate('9'), 'Rate must be between 10 and 1000'));
    test('above max', () => expect(rate('1001'), 'Rate must be between 10 and 1000'));
    test('negative', () => expect(rate('-50'), isNotNull));
    test('min edge', () => expect(rate('10'), isNull));
    test('max edge', () => expect(rate('1000'), isNull));
    test('decimal', () => expect(rate('150.50'), isNull));
    test('padded', () => expect(rate(' 200 '), isNull));
  });

  group('numberInRange (O06 reservation fee 0–100)', () {
    String? fee(String v) => Validators.numberInRange(v, 0, 100, 'Reservation fee');
    test('zero allowed', () => expect(fee('0'), isNull));
    test('101 rejected', () => expect(fee('101'), isNotNull));
  });

  group('numberInRange (O06 discount 0–90)', () {
    String? discount(String v) => Validators.numberInRange(v, 0, 90, 'Discount');
    test('30 ok', () => expect(discount('30'), isNull));
    test('91 rejected', () => expect(discount('91'), isNotNull));
  });

  group('phone (O10, optional)', () {
    test('empty is allowed', () => expect(Validators.phone(''), isNull));
    test('null is allowed', () => expect(Validators.phone(null), isNull));
    test('local mobile', () => expect(Validators.phone('077 123 4567'), isNull));
    test('international', () => expect(Validators.phone('+94 77 123 4567'), isNull));
    test('too short', () => expect(Validators.phone('12345'), 'Enter a valid phone number'));
    test('too long', () => expect(Validators.phone('1234567890123'), 'Enter a valid phone number'));
    test('letters rejected', () => expect(Validators.phone('abc123456789'), 'Enter a valid phone number'));
    test('brackets and dashes ok', () => expect(Validators.phone('(077) 123-4567'), isNull));
  });
}
