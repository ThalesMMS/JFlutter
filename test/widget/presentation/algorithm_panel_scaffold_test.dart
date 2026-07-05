import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/presentation/widgets/algorithm_panel_scaffold.dart';
import 'package:jflutter/presentation/widgets/common/algorithm_button_config.dart';

void main() {
  testWidgets('AlgorithmPanelScaffold renders title and children in card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AlgorithmPanelScaffold(
            title: 'Shared Algorithms',
            children: [
              Text('Panel body'),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Shared Algorithms'), findsOneWidget);
    expect(find.text('Panel body'), findsOneWidget);
  });

  testWidgets('AlgorithmButtonList renders configs with spacing and callbacks', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlgorithmButtonList(
            configs: [
              AlgorithmButtonConfig(
                title: 'Run analysis',
                description: 'Execute the shared list action',
                icon: Icons.analytics,
                onPressed: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Run analysis'), findsOneWidget);

    await tester.tap(find.text('Run analysis'));
    await tester.pumpAndSettle();

    expect(tapped, true);
  });

  testWidgets('AlgorithmPanelScaffold supports padding outside scroll view', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AlgorithmPanelScaffold(
            title: 'Outer Padding',
            paddingInsideScroll: false,
            children: [
              Text('Panel body'),
            ],
          ),
        ),
      ),
    );

    final scroll = find.byType(SingleChildScrollView);

    expect(
      find.ancestor(of: scroll, matching: find.byType(Padding)),
      findsOneWidget,
    );
  });

  testWidgets('AlgorithmResultsSection switches empty and result content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AlgorithmResultsSection(
            hasResults: false,
            empty: Text('No results'),
            results: Text('Results'),
          ),
        ),
      ),
    );

    expect(find.text('Analysis Results'), findsOneWidget);
    expect(find.text('No results'), findsOneWidget);
    expect(find.text('Results'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AlgorithmResultsSection(
            hasResults: true,
            empty: Text('No results'),
            results: Text('Results'),
          ),
        ),
      ),
    );

    expect(find.text('No results'), findsNothing);
    expect(find.text('Results'), findsOneWidget);
  });
}
