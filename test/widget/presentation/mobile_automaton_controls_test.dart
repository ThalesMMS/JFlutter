import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/presentation/widgets/mobile_automaton_controls.dart';

void main() {
  testWidgets('MobileAutomatonControls surfaces canvas and workspace actions',
      (tester) async {
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
            onZoomIn: () {},
            onZoomOut: () {},
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

    expect(find.text('Simulate'), findsOneWidget);
    expect(find.text('Algorithms'), findsOneWidget);
    expect(find.text('Metrics'), findsOneWidget);
    expect(find.text('Add state'), findsOneWidget);
    expect(find.text('Clear canvas'), findsOneWidget);
    expect(find.text('3 states · 2 transitions'), findsOneWidget);

    await tester.tap(find.text('Simulate'));
    await tester.pump();
    await tester.tap(find.text('Algorithms'));
    await tester.pump();
    await tester.tap(find.text('Metrics'));
    await tester.pump();
    await tester.tap(find.text('Add state'));
    await tester.pump();
    await tester.tap(find.text('Clear canvas'));
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
            onZoomIn: () {},
            onZoomOut: () {},
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

    final simulateButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Simulate'),
    );
    final algorithmButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Algorithms'),
    );

    expect(simulateButton.onPressed, isNull);
    expect(algorithmButton.onPressed, isNull);
    expect(find.text('Metrics'), findsNothing);
  });
}
