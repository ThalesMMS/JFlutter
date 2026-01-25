//
//  mobile_automaton_controls_test.dart
//  JFlutter
//
//  Conjunto de testes de widget que confirma o comportamento do
//  MobileAutomatonControls, cobrindo renderização dos botões principais e
//  habilitação condicional de simulação, algoritmos, métricas e ferramentas do
//  canvas. As verificações monitoram callbacks disparados e mensagens de status
//  para assegurar que o painel móvel responda corretamente a diferentes
//  configurações.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/presentation/widgets/mobile_automaton_controls.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_tool.dart';

void main() {
  testWidgets('MobileAutomatonControls surfaces canvas and workspace actions', (
    tester,
  ) async {
    var simulateInvoked = false;
    var algorithmInvoked = false;
    var metricsInvoked = false;
    var addStateInvoked = false;
    var clearInvoked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileAutomatonControls(
            onAddState: () => addStateInvoked = true,
            onFitToContent: () {},
            onResetView: () {},
            onClear: () => clearInvoked = true,
            onSimulate: () => simulateInvoked = true,
            onAlgorithms: () => algorithmInvoked = true,
            onMetrics: () => metricsInvoked = true,
            statusMessage: '3 states · 2 transitions',
          ),
        ),
      ),
    );

    expect(find.byTooltip('Simulate'), findsOneWidget);
    expect(find.byTooltip('Algorithms'), findsOneWidget);
    expect(find.byTooltip('Metrics'), findsOneWidget);
    expect(find.byTooltip('Add state'), findsOneWidget);
    expect(find.byTooltip('Clear canvas'), findsOneWidget);
    expect(find.text('3 states · 2 transitions'), findsOneWidget);

    await tester.tap(find.byTooltip('Simulate'));
    await tester.pump();
    await tester.tap(find.byTooltip('Algorithms'));
    await tester.pump();
    await tester.tap(find.byTooltip('Metrics'));
    await tester.pump();
    await tester.tap(find.byTooltip('Add state'));
    await tester.pump();
    await tester.tap(find.byTooltip('Clear canvas'));
    await tester.pump();

    expect(simulateInvoked, isTrue);
    expect(algorithmInvoked, isTrue);
    expect(metricsInvoked, isTrue);
    expect(addStateInvoked, isTrue);
    expect(clearInvoked, isTrue);
  });

  testWidgets('disables optional actions when flags are false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileAutomatonControls(
            onAddState: () {},
            onFitToContent: () {},
            onResetView: () {},
            onSimulate: () {},
            isSimulationEnabled: false,
            onAlgorithms: () {},
            isAlgorithmsEnabled: false,
          ),
        ),
      ),
    );

    final simulateButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byTooltip('Simulate'),
        matching: find.byType(IconButton),
      ),
    );
    final algorithmButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byTooltip('Algorithms'),
        matching: find.byType(IconButton),
      ),
    );

    expect(simulateButton.onPressed, isNull);
    expect(algorithmButton.onPressed, isNull);
    expect(find.byTooltip('Metrics'), findsNothing);
  });

  testWidgets('shows canvas tool toggles when enabled', (tester) async {
    var addStateInvoked = false;
    var transitionInvoked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileAutomatonControls(
            enableToolSelection: true,
            activeTool: AutomatonCanvasTool.addState,
            onAddState: () => addStateInvoked = true,
            onAddTransition: () => transitionInvoked = true,
            onFitToContent: () {},
            onResetView: () {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Select'), findsNothing);
    expect(find.byIcon(Icons.arrow_right_alt), findsOneWidget);

    await tester.tap(find.byTooltip('Add state'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_right_alt));
    await tester.pump();

    expect(addStateInvoked, isTrue);
    expect(transitionInvoked, isTrue);
  });
}
