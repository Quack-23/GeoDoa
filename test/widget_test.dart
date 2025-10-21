// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:doa_maps/main.dart';

void main() {
  testWidgets('Doa Geofencing app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoaMapsApp());

    // Verify that our app loads with the correct title.
    expect(find.text('Doa Geofencing'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Maps'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
