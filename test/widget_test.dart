// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/app.dart';

void main() {
  testWidgets('App shell renders tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const JFlutterApp());

    // Title and the three tabs should be present
    expect(find.text('JFlutter'), findsOneWidget);
    expect(find.text('AFD'), findsOneWidget);
    expect(find.text('AFN'), findsOneWidget);
    expect(find.text('GR'), findsOneWidget);
  });
}
