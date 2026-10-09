import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkpin/app.dart';
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

  testWidgets('D01 splash shows the logo, then opens Role Selection', (tester) async {
    await tester.pumpWidget(const ParkPinApp());
    expect(find.text('ParkPin'), findsOneWidget);
    expect(find.text('Find & reserve city parking'), findsOneWidget);
    // The splash waits (at most 0.8 s) for its images, then shows for 3.5 s.
    // Pump in steps so the timer it starts after becoming visible can run.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to ParkPin'), findsOneWidget);
  });

  test('Validators', () {
    expect(Validators.email('operator@parkpin.lk'), isNull);
    expect(Validators.email('bad-email'), isNotNull);
    expect(Validators.password('12345'), isNotNull);
    expect(Validators.numberInRange('50', 0, 100), isNull);
    expect(Validators.numberInRange('150', 0, 100), isNotNull);
  });
}
