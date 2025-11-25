import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jflutter/presentation/pages/fsa_page.dart';
import 'package:jflutter/presentation/pages/regex_page.dart';
import 'package:jflutter/presentation/pages/grammar_page.dart';
import 'package:jflutter/presentation/pages/tm_page.dart';
import 'package:jflutter/presentation/pages/pda_page.dart';
import 'package:jflutter/presentation/widgets/tablet_layout_container.dart';
import 'package:jflutter/presentation/providers/grammar_provider.dart';
import 'package:jflutter/presentation/pages/regex_page.dart';

void main() {
  group('Tablet Layout Tests', () {
    testWidgets('FSAPage uses TabletLayoutContainer on tablet width', (tester) async {
      tester.view.physicalSize = const Size(1100, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: FSAPage())));
      await tester.pumpAndSettle();

      expect(find.byType(TabletLayoutContainer), findsOneWidget);
    });

    testWidgets('RegexPage uses TabletLayoutContainer on tablet width', (tester) async {
      tester.view.physicalSize = const Size(1100, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RegexPage())));
      await tester.pumpAndSettle();

      expect(find.byType(TabletLayoutContainer), findsOneWidget);
    });

    testWidgets('GrammarPage uses TabletLayoutContainer on tablet width', (tester) async {
      tester.view.physicalSize = const Size(1100, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            grammarProvider.overrideWith((ref) => GrammarProvider()),
          ],
          child: const MaterialApp(
            home: GrammarPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabletLayoutContainer), findsOneWidget);
    });

    testWidgets('TMPage uses TabletLayoutContainer on tablet width', (tester) async {
      tester.view.physicalSize = const Size(1100, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: TMPage())));
      await tester.pumpAndSettle();

      expect(find.byType(TabletLayoutContainer), findsOneWidget);
    });

    testWidgets('PDAPage uses TabletLayoutContainer on tablet width', (tester) async {
      tester.view.physicalSize = const Size(1100, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: PDAPage())));
      await tester.pumpAndSettle();

      expect(find.byType(TabletLayoutContainer), findsOneWidget);
    });
  });
}
