// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures to the widget, read text, and verify that the values of widget
// properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mushaf_app/main.dart';

void main() {
  testWidgets('Mushaf app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MushafApp());

    // Verify that the app loads with Mushaf title
    expect(find.text('Mushaf'), findsOneWidget);
  });
}