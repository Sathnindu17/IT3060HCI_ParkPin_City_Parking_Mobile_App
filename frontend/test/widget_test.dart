import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkpin/core/utils/validators.dart';
import 'package:parkpin/shared/widgets/primary_button.dart';

void main() {
  testWidgets('PrimaryButton shows its label and reacts to taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PrimaryButton(label: 'Log in', onPressed: () => taps++)),
    ));
    expect(find.text('Log in'), findsOneWidget);
    await tester.tap(find.text('Log in'));
    expect(taps, 1);
  });

  test('Validators', () {
    expect(Validators.email('operator@parkpin.lk'), isNull);
    expect(Validators.email('bad-email'), isNotNull);
    expect(Validators.password('12345'), isNotNull);
    expect(Validators.numberInRange('50', 0, 100), isNull);
    expect(Validators.numberInRange('150', 0, 100), isNotNull);
  });
}
