import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parkpin/app.dart';
import 'package:parkpin/core/utils/validators.dart';
import 'package:parkpin/shared/widgets/primary_button.dart';

void main() {
  // ============================================
  // TEST 1: PRIMARY BUTTON
  // ============================================

  testWidgets('PrimaryButton shows its label and reacts to taps', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(label: 'Log in', onPressed: () => taps++),
        ),
      ),
    );

    expect(find.text('Log in'), findsOneWidget);

    await tester.tap(find.text('Log in'));

    expect(taps, 1);
  });

  // ============================================
  // TEST 2: D01 SPLASH -> ROLE SELECTION
  // ============================================

  testWidgets('D01 splash shows the logo, then opens Role Selection', (
    tester,
  ) async {
    // Supabase is not initialized in tests, so mute the splash notice.
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {};

    // Step 1: Launch the ParkPin application.
    await tester.pumpWidget(const ParkPinApp());

    // Step 2: Verify D01 splash screen content.
    expect(find.text('ParkPin'), findsOneWidget);

    expect(find.text('Find & reserve city parking'), findsOneWidget);

    // Step 3: Allow image preloading to finish or time out.
    // The splash screen has an 800ms image-loading timeout.
    await tester.pump(const Duration(milliseconds: 1000));

    // Step 4: Process the next frame so the splash screen
    // can begin its animation and navigation timer.
    await tester.pump();
    await tester.pump();

    // Step 5: Advance beyond the 3.5-second splash timer.
    await tester.pump(const Duration(seconds: 4));

    // Step 6: Complete the navigation transition.
    await tester.pumpAndSettle();
    // Flutter requires debugPrint restored before the test ends.
    debugPrint = originalDebugPrint;

    // Step 7: Verify Role Selection has appeared.
    expect(find.text('Welcome to ParkPin'), findsOneWidget);

    // Verify that the Driver role is available.
    expect(find.text('Driver'), findsOneWidget);

    // Verify the other team roles are available.
    expect(find.text('Car-park Operator'), findsOneWidget);

    expect(find.text('Traffic Authority'), findsOneWidget);
  });

  // ============================================
  // TEST 3: FORM VALIDATORS
  // ============================================

  test('Validators', () {
    expect(Validators.email('operator@parkpin.lk'), isNull);

    expect(Validators.email('bad-email'), isNotNull);

    expect(Validators.password('12345'), isNotNull);

    expect(Validators.numberInRange('50', 0, 100), isNull);

    expect(Validators.numberInRange('150', 0, 100), isNotNull);
  });
}
