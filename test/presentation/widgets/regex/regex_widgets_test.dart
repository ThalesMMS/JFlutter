import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/presentation/widgets/regex/regex_conversion_actions.dart';
import 'package:jflutter/presentation/widgets/regex/regex_equivalence_section.dart';
import 'package:jflutter/presentation/widgets/regex/regex_help_card.dart';
import 'package:jflutter/presentation/widgets/regex/regex_input_form.dart';
import 'package:jflutter/presentation/widgets/regex/regex_test_section.dart';

void main() {
  group('RegexInputForm', () {
    testWidgets('shows validation feedback and triggers callbacks',
        (tester) async {
      bool validateCalled = false;
      String? latestChange;
      final controller = TextEditingController(text: 'a*');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegexInputForm(
              controller: controller,
              isValid: false,
              validationMessage: 'Invalid regular expression',
              onChanged: (value) => latestChange = value,
              onValidate: () => validateCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Invalid regular expression'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ab');
      expect(latestChange, 'ab');

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(validateCalled, isTrue);
    });
  });

  group('RegexTestSection', () {
    testWidgets('displays match result', (tester) async {
      final controller = TextEditingController(text: 'ab');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegexTestSection(
              controller: controller,
              matchResult: true,
              matchMessage: null,
              onChanged: (_) {},
              onTest: () {},
            ),
          ),
        ),
      );

      expect(find.text('Matches!'), findsOneWidget);
    });

    testWidgets('displays custom message when provided', (tester) async {
      final controller = TextEditingController(text: 'ab');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegexTestSection(
              controller: controller,
              matchResult: null,
              matchMessage: 'Please validate the regex',
              onChanged: (_) {},
              onTest: () {},
            ),
          ),
        ),
      );

      expect(find.text('Please validate the regex'), findsOneWidget);
    });
  });

  group('RegexConversionActions', () {
    testWidgets('disables buttons when conversion is not allowed',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegexConversionActions(
              enableConversion: false,
              onConvertToNfa: () {},
              onConvertToDfa: () {},
            ),
          ),
        ),
      );

      final buttons =
          tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      for (final button in buttons) {
        expect(button.onPressed, isNull);
      }
    });
  });

  group('RegexEquivalenceSection', () {
    testWidgets('renders equivalence feedback', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegexEquivalenceSection(
              controller: controller,
              equivalenceResult: true,
              equivalenceMessage: 'The regular expressions are equivalent.',
              onChanged: (_) {},
              onCompare: () {},
            ),
          ),
        ),
      );

      expect(find.text('The regular expressions are equivalent.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  testWidgets('RegexHelpCard shows helpful patterns', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RegexHelpCard(),
        ),
      ),
    );

    expect(find.textContaining('Common patterns'), findsOneWidget);
    expect(find.textContaining('a*'), findsWidgets);
  });
}
