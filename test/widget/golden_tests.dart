// Golden tests for UI components
// These tests capture the visual appearance of widgets for regression testing

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/app.dart';
import 'package:jflutter/presentation/pages/fsa_page.dart';
import 'package:jflutter/presentation/pages/grammar_page.dart';
import 'package:jflutter/presentation/pages/pda_page.dart';
import 'package:jflutter/presentation/pages/regex_page.dart';
import 'package:jflutter/presentation/pages/settings_page.dart';
import 'package:jflutter/presentation/pages/tm_page.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas/automaton_canvas.dart';
import 'package:jflutter/presentation/widgets/simulation_panel.dart';
import 'package:jflutter/presentation/widgets/algorithm_panel.dart';
import 'package:jflutter/presentation/widgets/mobile_navigation.dart';
import 'package:jflutter/presentation/widgets/pumping_lemma_game.dart';
import 'package:jflutter/presentation/widgets/grammar_editor.dart';
import 'package:jflutter/presentation/widgets/tm/tm_desktop_layout.dart';
import 'package:jflutter/presentation/widgets/tm/tm_mobile_layout.dart';

void main() {
  group('Golden Tests', () {
    testWidgets('FSA Page - Mobile Layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FsaPage(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Capture the golden file
      await expectLater(
        find.byType(FsaPage),
        matchesGoldenFile('golden/fsa_page_mobile.png'),
      );
    });

    testWidgets('FSA Page - Desktop Layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FsaPage(),
        ),
      );
      
      // Simulate desktop screen size
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(FsaPage),
        matchesGoldenFile('golden/fsa_page_desktop.png'),
      );
    });

    testWidgets('Grammar Page - Mobile Layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GrammarPage(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(GrammarPage),
        matchesGoldenFile('golden/grammar_page_mobile.png'),
      );
    });

    testWidgets('PDA Page - Mobile Layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PdaPage(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(PdaPage),
        matchesGoldenFile('golden/pda_page_mobile.png'),
      );
    });

    testWidgets('Regex Page - Mobile Layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegexPage(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(RegexPage),
        matchesGoldenFile('golden/regex_page_mobile.png'),
      );
    });

    testWidgets('TM Page - Mobile Layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TmPage(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(TmPage),
        matchesGoldenFile('golden/tm_page_mobile.png'),
      );
    });

    testWidgets('Settings Page - Mobile Layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(SettingsPage),
        matchesGoldenFile('golden/settings_page_mobile.png'),
      );
    });

    testWidgets('Automaton Canvas - Empty State', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: null,
              onStateAdded: (x, y) {},
              onTransitionAdded: (from, to, symbol) {},
              onStateUpdated: (state) {},
              onTransitionUpdated: (transition) {},
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(AutomatonCanvas),
        matchesGoldenFile('golden/automaton_canvas_empty.png'),
      );
    });

    testWidgets('Simulation Panel - Default State', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimulationPanel(
              onSimulate: (input) {},
              onStep: () {},
              onReset: () {},
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(SimulationPanel),
        matchesGoldenFile('golden/simulation_panel_default.png'),
      );
    });

    testWidgets('Algorithm Panel - Default State', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlgorithmPanel(
              onAlgorithmSelected: (algorithm) {},
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(AlgorithmPanel),
        matchesGoldenFile('golden/algorithm_panel_default.png'),
      );
    });

    testWidgets('Mobile Navigation - Default State', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MobileNavigation(
              currentIndex: 0,
              onTap: (index) {},
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(MobileNavigation),
        matchesGoldenFile('golden/mobile_navigation_default.png'),
      );
    });

    testWidgets('Pumping Lemma Game - Initial State', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PumpingLemmaGame(
              onGameCompleted: () {},
              onHelpRequested: () {},
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(PumpingLemmaGame),
        matchesGoldenFile('golden/pumping_lemma_game_initial.png'),
      );
    });

    testWidgets('Grammar Editor - Empty State', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GrammarEditor(
              onGrammarChanged: (grammar) {},
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(GrammarEditor),
        matchesGoldenFile('golden/grammar_editor_empty.png'),
      );
    });

    testWidgets('TM Desktop Layout - Default State', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmDesktopLayout(
              onTapeChanged: (tape) {},
              onHeadMoved: (position) {},
              onStateChanged: (state) {},
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(TmDesktopLayout),
        matchesGoldenFile('golden/tm_desktop_layout_default.png'),
      );
    });

    testWidgets('TM Mobile Layout - Default State', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmMobileLayout(
              onTapeChanged: (tape) {},
              onHeadMoved: (position) {},
              onStateChanged: (state) {},
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(TmMobileLayout),
        matchesGoldenFile('golden/tm_mobile_layout_default.png'),
      );
    });
  });
}
