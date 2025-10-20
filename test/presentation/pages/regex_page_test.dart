import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/presentation/pages/regex_page.dart';

void main() {
  Future<void> _pumpRegexPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RegexPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('RegexPage validation messaging', () {
    testWidgets('shows duplicate quantifier error', (tester) async {
      await _pumpRegexPage(tester);

      final regexField = find.byType(TextField).first;
      await tester.enterText(regexField, 'a**');
      await tester.pumpAndSettle();

      expect(
        find.text('Consecutive quantifiers are not allowed'),
        findsOneWidget,
      );
    });

    testWidgets('shows trailing union error', (tester) async {
      await _pumpRegexPage(tester);

      final regexField = find.byType(TextField).first;
      await tester.enterText(regexField, 'a|');
      await tester.pumpAndSettle();

      expect(
        find.text('Union operator cannot be at ends'),
        findsOneWidget,
      );
    });

    testWidgets('shows pointer details for leading union', (tester) async {
      await _pumpRegexPage(tester);

      final regexField = find.byType(TextField).first;
      await tester.enterText(regexField, '|a');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Union operator cannot be at ends at position 1'),
        findsOneWidget,
      );
      expect(
        find.textContaining('^'),
        findsOneWidget,
      );
    });
  });
}
