import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jflutter/main.dart' as app;
import 'package:jflutter/data/data_sources/examples_asset_data_source.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads example and runs simulations', (tester) async {
    SharedPreferences.setMockInitialValues(const {});

    app.main();
    await tester.pumpAndSettle();

    // Find MaterialApp to ensure the app is loaded
    final materialAppFinder = find.byType(MaterialApp);
    expect(
      materialAppFinder,
      findsOneWidget,
      reason: 'The MaterialApp should be available.',
    );

    // Get the ProviderScope container from any widget in the tree
    final container = ProviderScope.containerOf(
      tester.element(materialAppFinder),
      listen: false,
    );

    final examplesDataSource = ExamplesAssetDataSource();
    final exampleResult = await examplesDataSource.loadExample(
      'AFD - Termina com A',
    );
    expect(
      exampleResult.isSuccess,
      isTrue,
      reason: exampleResult.error ?? 'Expected example to load successfully.',
    );

    final automaton = exampleResult.data?.automaton;
    expect(
      automaton,
      isNotNull,
      reason: 'The loaded example should contain an automaton.',
    );

    container
        .read(automatonProvider.notifier)
        .replaceCurrentAutomaton(automaton!);
    await tester.pumpAndSettle();

    // Open the simulation sheet through the quick action.
    final simulateAction = find.byTooltip('Simulate').first;
    await tester.tap(simulateAction);
    await tester.pumpAndSettle();

    final inputField = find.bySemanticsLabel('Input String');
    expect(inputField, findsOneWidget);

    Future<void> runSimulation(String input, String expectedLabel) async {
      await tester.enterText(inputField, input);
      await tester.pumpAndSettle();

      final simulateButton = find.text('Simulate');
      expect(simulateButton, findsWidgets);

      await tester.tap(simulateButton.first);
      await tester.pumpAndSettle();

      expect(find.text(expectedLabel), findsOneWidget);
    }

    await runSimulation('ba', 'Accepted');
    await runSimulation('bb', 'Rejected');
  });
}
