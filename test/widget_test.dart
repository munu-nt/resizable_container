// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter_test/flutter_test.dart';
import 'package:resizable_container/home_page.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app bar title is present.
    expect(find.text('Resizable Tiles'), findsOneWidget);

    // Pump a few frames to let animations progress without waiting for them to complete
    // (pumpAndSettle times out on continuous animations like entry animations)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
