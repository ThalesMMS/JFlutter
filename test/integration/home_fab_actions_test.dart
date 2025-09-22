import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/app.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/presentation/pages/fsa_page.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/providers/grammar_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas/index.dart';
import 'package:jflutter/presentation/widgets/grammar_editor.dart';

void main() {
  group('Home FAB actions', () {
    testWidgets('creates a new automaton and opens the editor',
        (WidgetTester tester) async {
      await tester.pumpWidget(const JFlutterApp());
      await tester.pumpAndSettle();

      expect(find.byType(FSAPage), findsOneWidget);

      await tester.tap(find.byTooltip('Create New Automaton'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProviderScope)),
        listen: false,
      );

      final automatonState = container.read(automatonProvider);
      expect(automatonState.currentAutomaton, isNotNull);

      expect(find.byType(AutomatonCanvas), findsOneWidget);
      expect(find.text('Empty Canvas'), findsNothing);
    });

    testWidgets('creates a new grammar and shows the grammar editor',
        (WidgetTester tester) async {
      await tester.pumpWidget(const JFlutterApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Grammar'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProviderScope)),
        listen: false,
      );

      container.read(grammarProvider.notifier).addProduction(
            leftSide: const ['S'],
            rightSide: const ['a'],
          );
      await tester.pump();

      await tester.tap(find.byTooltip('Create New Grammar'));
      await tester.pumpAndSettle();

      final grammarState = container.read(grammarProvider);
      expect(grammarState.productions, isEmpty);
      expect(grammarState.name, 'My Grammar');
      expect(grammarState.startSymbol, 'S');
      expect(grammarState.type, GrammarType.regular);

      expect(find.byType(GrammarEditor), findsWidgets);
    });
  });
}
