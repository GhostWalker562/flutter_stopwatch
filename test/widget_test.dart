import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stopwatch/main.dart';

void main() {
  testWidgets(
    'Stopwatch start and stop after delay',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({}); //set values here

      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Tap start
      await tester.tap(find.text('Start'));
      await tester.pump();
      // Wait
      await tester.pump(const Duration(milliseconds: 50));
      // Tap stop
      await tester.tap(find.text('Stop'));
      await tester.pump();

      // We find two widgets because there is one for the display and one for laps.
      expect(find.text('00:00.50'), findsNWidgets(2));
    },
  );

  testWidgets(
    'Stopwatch lap twice',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({}); //set values here

      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Tap start
      await tester.tap(find.text('Start'));
      await tester.pump();
      // Wait and tap lap 1
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('lapResetButton')));
      await tester.pump();
      // Wait and tap lap 2
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byKey(const ValueKey('lapResetButton')));
      await tester.pump();
      // Tap stop after a delay
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('Stop'));
      await tester.pump();

      // Find lap 1
      expect(find.text('00:01.00'), findsOneWidget);
      expect(find.text('Lap 1'), findsOneWidget);
      // Find lap 2
      expect(find.text('00:02.00'), findsOneWidget);
      expect(find.text('Lap 2'), findsOneWidget);
      // Find primary time
      expect(find.text('00:03.00'), findsOneWidget);
      expect(find.text('Lap 3'), findsOneWidget);
    },
  );
}
