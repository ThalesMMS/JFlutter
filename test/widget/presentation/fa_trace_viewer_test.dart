import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/presentation/widgets/trace_viewers/fa_trace_viewer.dart';
import 'package:jflutter/presentation/widgets/trace_viewers/base_trace_viewer.dart';

Future<void> _pumpFATraceViewer(
  WidgetTester tester, {
  required SimulationResult result,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FATraceViewer(result: result),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FATraceViewer', () {
    testWidgets('renders with accepted result and displays correct title',
        (tester) async {
      final result = SimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'bc',
            usedTransition: 'a',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            usedTransition: 'b',
            stepNumber: 2,
          ),
        ],
        executionTime: const Duration(milliseconds: 10),
      );

      await _pumpFATraceViewer(tester, result: result);

      expect(find.byType(BaseTraceViewer), findsOneWidget);
      expect(find.text('FA Trace (3 steps)'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders with rejected result and displays correct icon',
        (tester) async {
      final result = SimulationResult.failure(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        errorMessage: 'No valid transition',
        executionTime: const Duration(milliseconds: 5),
      );

      await _pumpFATraceViewer(tester, result: result);

      expect(find.byType(BaseTraceViewer), findsOneWidget);
      expect(find.text('FA Trace (2 steps)'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('displays epsilon for empty remaining input', (tester) async {
      final result = SimulationResult.success(
        inputString: 'a',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'a',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 5),
      );

      await _pumpFATraceViewer(tester, result: result);

      expect(find.text('FA Trace (2 steps)'), findsOneWidget);
      expect(find.textContaining('remaining=ε'), findsOneWidget);
    });

    testWidgets('displays step information with state and remaining input',
        (tester) async {
      final result = SimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'bc',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 8),
      );

      await _pumpFATraceViewer(tester, result: result);

      expect(find.textContaining('q=q0'), findsOneWidget);
      expect(find.textContaining('remaining=abc'), findsOneWidget);
      expect(find.textContaining('q=q1'), findsOneWidget);
      expect(find.textContaining('remaining=bc'), findsOneWidget);
      expect(find.textContaining('read a'), findsOneWidget);
    });

    testWidgets('displays transition information when available',
        (tester) async {
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            usedTransition: 'a',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            usedTransition: 'b',
            stepNumber: 2,
          ),
        ],
        executionTime: const Duration(milliseconds: 12),
      );

      await _pumpFATraceViewer(tester, result: result);

      expect(find.textContaining('read a'), findsOneWidget);
      expect(find.textContaining('read b'), findsOneWidget);
    });

    testWidgets('displays step numbers in sequence', (tester) async {
      final result = SimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'bc',
            usedTransition: 'a',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: 'c',
            usedTransition: 'b',
            stepNumber: 2,
          ),
        ],
        executionTime: const Duration(milliseconds: 15),
      );

      await _pumpFATraceViewer(tester, result: result);

      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('3.'), findsOneWidget);
    });

    testWidgets('handles empty steps list', (tester) async {
      final result = SimulationResult.error(
        inputString: '',
        errorMessage: 'Invalid automaton',
        executionTime: const Duration(milliseconds: 1),
      );

      await _pumpFATraceViewer(tester, result: result);

      expect(find.text('FA Trace (0 steps)'), findsOneWidget);
      expect(find.text('No steps recorded'), findsOneWidget);
    });

    testWidgets('renders all step containers with proper styling',
        (tester) async {
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 6),
      );

      await _pumpFATraceViewer(tester, result: result);

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Container),
        ),
      );

      expect(containers.length, greaterThanOrEqualTo(2));
    });

    testWidgets('displays correct information for single step',
        (tester) async {
      final result = SimulationResult.success(
        inputString: 'a',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: '',
            usedTransition: 'a',
            stepNumber: 0,
          ),
        ],
        executionTime: const Duration(milliseconds: 2),
      );

      await _pumpFATraceViewer(tester, result: result);

      expect(find.text('FA Trace (1 steps)'), findsOneWidget);
      expect(find.textContaining('q=q0'), findsOneWidget);
      expect(find.textContaining('remaining=ε'), findsOneWidget);
      expect(find.textContaining('read a'), findsOneWidget);
    });

    testWidgets('handles step without transition', (tester) async {
      final result = SimulationResult.success(
        inputString: '',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: '',
            stepNumber: 0,
          ),
        ],
        executionTime: const Duration(milliseconds: 1),
      );

      await _pumpFATraceViewer(tester, result: result);

      expect(find.textContaining('q=q0'), findsOneWidget);
      expect(find.textContaining('remaining=ε'), findsOneWidget);
      expect(find.textContaining('read'), findsNothing);
    });
  });
}
