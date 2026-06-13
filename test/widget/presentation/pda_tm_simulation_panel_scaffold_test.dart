import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/presentation/widgets/pda_simulation_panel.dart';
import 'package:jflutter/presentation/widgets/tm_simulation_panel.dart';

Future<void> _pumpPanel(WidgetTester tester, Widget panel) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 720,
            child: panel,
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  group('PDA/TM simulation panel shared scaffolding', () {
    testWidgets('PDA panel keeps stack-specific input slots', (tester) async {
      await _pumpPanel(tester, PDASimulationPanel());

      expect(find.text('PDA Simulation'), findsOneWidget);
      expect(find.text('Simulation Input'), findsOneWidget);
      expect(find.text('Input String'), findsOneWidget);
      expect(find.text('Initial Stack Symbol'), findsOneWidget);
      expect(find.text('Record step-by-step trace'), findsOneWidget);
      expect(find.text('Simulate PDA'), findsOneWidget);
      expect(find.text('Simulation Results'), findsOneWidget);
      expect(find.text('No simulation results yet'), findsOneWidget);
    });

    testWidgets('TM panel keeps tape-oriented input slots', (tester) async {
      await _pumpPanel(tester, TMSimulationPanel());

      expect(find.text('TM Simulation'), findsOneWidget);
      expect(find.text('Simulation Input'), findsOneWidget);
      expect(find.text('Input String'), findsOneWidget);
      expect(
        find.text('Examples: 101 (binary), 1100 (palindrome), 111 (counting)'),
        findsOneWidget,
      );
      expect(find.text('Simulate TM'), findsOneWidget);
      expect(find.text('Simulation Results'), findsOneWidget);
      expect(find.text('No simulation results yet'), findsOneWidget);
    });
  });
}
