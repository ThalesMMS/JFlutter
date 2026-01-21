import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/algorithms/pda_simulator.dart';
import 'package:jflutter/core/algorithms/tm_simulator.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/presentation/widgets/trace_viewers/pda_trace_viewer.dart';
import 'package:jflutter/presentation/widgets/trace_viewers/tm_trace_viewer.dart';
import 'package:jflutter/presentation/widgets/trace_viewers/base_trace_viewer.dart';

Future<void> _pumpPDATraceViewer(
  WidgetTester tester, {
  required PDASimulationResult result,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PDATraceViewer(result: result),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpTMTraceViewer(
  WidgetTester tester, {
  required TMSimulationResult result,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TMTraceViewer(result: result),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDATraceViewer', () {
    testWidgets('renders with accepted result and displays correct title',
        (tester) async {
      final result = PDASimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'bc',
            stackContents: 'AZ',
            usedTransition: 'a',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stackContents: 'Z',
            usedTransition: 'b',
            stepNumber: 2,
          ),
        ],
        executionTime: const Duration(milliseconds: 10),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.byType(BaseTraceViewer), findsOneWidget);
      expect(find.text('PDA Trace (3 steps)'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders with rejected result and displays correct icon',
        (tester) async {
      final result = PDASimulationResult.failure(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stackContents: 'AZ',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        errorMessage: 'No valid transition',
        executionTime: const Duration(milliseconds: 5),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.byType(BaseTraceViewer), findsOneWidget);
      expect(find.text('PDA Trace (2 steps)'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('displays lambda for empty remaining input', (tester) async {
      final result = PDASimulationResult.success(
        inputString: 'a',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'a',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stackContents: 'Z',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 5),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.text('PDA Trace (2 steps)'), findsOneWidget);
      expect(find.textContaining('rem=λ'), findsOneWidget);
    });

    testWidgets('displays lambda for empty stack', (tester) async {
      final result = PDASimulationResult.success(
        inputString: 'a',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'a',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stackContents: '',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 5),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.textContaining('stack=λ'), findsOneWidget);
    });

    testWidgets('displays step information with state, remaining input, and stack',
        (tester) async {
      final result = PDASimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'bc',
            stackContents: 'AZ',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 8),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.textContaining('q=q0'), findsOneWidget);
      expect(find.textContaining('rem=abc'), findsOneWidget);
      expect(find.textContaining('stack=Z'), findsOneWidget);
      expect(find.textContaining('q=q1'), findsOneWidget);
      expect(find.textContaining('rem=bc'), findsOneWidget);
      expect(find.textContaining('stack=AZ'), findsOneWidget);
    });

    testWidgets('displays transition information when available',
        (tester) async {
      final result = PDASimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stackContents: 'AZ',
            usedTransition: 'a, Z -> AZ',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stackContents: 'Z',
            usedTransition: 'b, A -> ε',
            stepNumber: 2,
          ),
        ],
        executionTime: const Duration(milliseconds: 12),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.textContaining('a, Z -> AZ'), findsOneWidget);
      expect(find.textContaining('b, A -> ε'), findsOneWidget);
    });

    testWidgets('displays step numbers in sequence', (tester) async {
      final result = PDASimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'bc',
            stackContents: 'AZ',
            usedTransition: 'a',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: 'c',
            stackContents: 'BZ',
            usedTransition: 'b',
            stepNumber: 2,
          ),
        ],
        executionTime: const Duration(milliseconds: 15),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('3.'), findsOneWidget);
    });

    testWidgets('handles empty steps list', (tester) async {
      final result = PDASimulationResult.failure(
        inputString: '',
        steps: const [],
        errorMessage: 'Invalid automaton',
        executionTime: const Duration(milliseconds: 1),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.text('PDA Trace (0 steps)'), findsOneWidget);
      expect(find.text('No steps recorded'), findsOneWidget);
    });

    testWidgets('handles timeout result', (tester) async {
      final result = PDASimulationResult.timeout(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stackContents: 'Z',
            stepNumber: 0,
          ),
        ],
        executionTime: const Duration(seconds: 5),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('handles infinite loop result', (tester) async {
      final result = PDASimulationResult.infiniteLoop(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stackContents: 'Z',
            stepNumber: 0,
          ),
        ],
        executionTime: const Duration(seconds: 3),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.byIcon(Icons.all_inclusive), findsOneWidget);
    });

    testWidgets('renders all step containers with proper styling',
        (tester) async {
      final result = PDASimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stackContents: 'AZ',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 6),
      );

      await _pumpPDATraceViewer(tester, result: result);

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Container),
        ),
      );

      expect(containers.length, greaterThanOrEqualTo(2));
    });

    testWidgets('handles step without transition', (tester) async {
      final result = PDASimulationResult.success(
        inputString: '',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: '',
            stackContents: 'Z',
            stepNumber: 0,
          ),
        ],
        executionTime: const Duration(milliseconds: 1),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.textContaining('q=q0'), findsOneWidget);
      expect(find.textContaining('rem=λ'), findsOneWidget);
      expect(find.textContaining('stack=Z'), findsOneWidget);
    });
  });

  group('TMTraceViewer', () {
    testWidgets('renders with accepted result and displays correct title',
        (tester) async {
      final result = TMSimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: '',
            tapeContents: 'abc',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            tapeContents: 'Xbc',
            usedTransition: 'a/X,R',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            tapeContents: 'XYc',
            usedTransition: 'b/Y,R',
            stepNumber: 2,
          ),
        ],
        executionTime: const Duration(milliseconds: 10),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.byType(BaseTraceViewer), findsOneWidget);
      expect(find.text('TM Trace (3 steps)'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders with rejected result and displays correct icon',
        (tester) async {
      final result = TMSimulationResult.failure(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'ab',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: 'Xb',
            usedTransition: 'a/X,R',
            stepNumber: 1,
            remainingInput: '',
          ),
        ],
        errorMessage: 'No valid transition',
        executionTime: const Duration(milliseconds: 5),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.byType(BaseTraceViewer), findsOneWidget);
      expect(find.text('TM Trace (2 steps)'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('displays blank square for empty tape', (tester) async {
      final result = TMSimulationResult.success(
        inputString: '',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: '',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: '',
            usedTransition: '□/□,R',
            stepNumber: 1,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 5),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.text('TM Trace (2 steps)'), findsOneWidget);
      expect(find.textContaining('tape=□'), findsOneWidget);
    });

    testWidgets('displays step information with state and tape',
        (tester) async {
      final result = TMSimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'abc',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: 'Xbc',
            usedTransition: 'a/X,R',
            stepNumber: 1,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 8),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.textContaining('q=q0'), findsOneWidget);
      expect(find.textContaining('tape=abc'), findsOneWidget);
      expect(find.textContaining('q=q1'), findsOneWidget);
      expect(find.textContaining('tape=Xbc'), findsOneWidget);
    });

    testWidgets('displays transition information when available',
        (tester) async {
      final result = TMSimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'ab',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: 'Xb',
            usedTransition: 'a/X,R',
            stepNumber: 1,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q2',
            tapeContents: 'XY',
            usedTransition: 'b/Y,R',
            stepNumber: 2,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 12),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.textContaining('read a/X,R'), findsOneWidget);
      expect(find.textContaining('read b/Y,R'), findsOneWidget);
    });

    testWidgets('displays step numbers in sequence', (tester) async {
      final result = TMSimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'abc',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: 'Xbc',
            usedTransition: 'a/X,R',
            stepNumber: 1,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q2',
            tapeContents: 'XYc',
            usedTransition: 'b/Y,R',
            stepNumber: 2,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 15),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('3.'), findsOneWidget);
    });

    testWidgets('handles empty steps list', (tester) async {
      final result = TMSimulationResult.failure(
        inputString: '',
        steps: const [],
        errorMessage: 'Invalid Turing machine',
        executionTime: const Duration(milliseconds: 1),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.text('TM Trace (0 steps)'), findsOneWidget);
      expect(find.text('No steps recorded'), findsOneWidget);
    });

    testWidgets('handles timeout result', (tester) async {
      final result = TMSimulationResult.timeout(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'abc',
            stepNumber: 0,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(seconds: 5),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('handles infinite loop result', (tester) async {
      final result = TMSimulationResult.infiniteLoop(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'abc',
            stepNumber: 0,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(seconds: 3),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.byIcon(Icons.all_inclusive), findsOneWidget);
    });

    testWidgets('renders all step containers with proper styling',
        (tester) async {
      final result = TMSimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'ab',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: 'Xb',
            usedTransition: 'a/X,R',
            stepNumber: 1,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 6),
      );

      await _pumpTMTraceViewer(tester, result: result);

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
      final result = TMSimulationResult.success(
        inputString: 'a',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'X',
            usedTransition: 'a/X,R',
            stepNumber: 0,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 2),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.text('TM Trace (1 steps)'), findsOneWidget);
      expect(find.textContaining('q=q0'), findsOneWidget);
      expect(find.textContaining('tape=X'), findsOneWidget);
      expect(find.textContaining('read a/X,R'), findsOneWidget);
    });

    testWidgets('handles step without transition', (tester) async {
      final result = TMSimulationResult.success(
        inputString: '',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: '',
            stepNumber: 0,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 1),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.textContaining('q=q0'), findsOneWidget);
      expect(find.textContaining('tape=□'), findsOneWidget);
      expect(find.textContaining('read'), findsNothing);
    });

    testWidgets('displays tape contents correctly for complex strings',
        (tester) async {
      final result = TMSimulationResult.success(
        inputString: '0011',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: '0011',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: 'X011',
            usedTransition: '0/X,R',
            stepNumber: 1,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q2',
            tapeContents: 'XX11',
            usedTransition: '0/X,R',
            stepNumber: 2,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 10),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.textContaining('tape=0011'), findsOneWidget);
      expect(find.textContaining('tape=X011'), findsOneWidget);
      expect(find.textContaining('tape=XX11'), findsOneWidget);
    });
  });
}
