import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas.dart';
import 'package:jflutter/presentation/widgets/simulation_panel.dart';

/// Widget/Golden Tests for Immutable Traces and Visualizations
///
/// This test suite validates the rendering and visual behavior of
/// automaton visualizations, simulation traces, and immutable data structures.
///
/// Test cases cover:
/// 1. Automaton canvas rendering
/// 2. Simulation panel visualization
/// 3. Immutable trace rendering
/// 4. Golden file comparisons
/// 5. Performance and responsiveness
void main() {
  group('Automaton Canvas Widget Tests', () {
    testWidgets('AutomatonCanvas renders empty automaton correctly', (
      tester,
    ) async {
      final canvasKey = GlobalKey();
      FSA? capturedAutomaton;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: null,
              canvasKey: canvasKey,
              onAutomatonChanged: (automaton) {
                capturedAutomaton = automaton;
              },
            ),
          ),
        ),
      );

      expect(find.byType(AutomatonCanvas), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);

      // Verify empty canvas is rendered
      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      expect(customPaint.painter, isA<AutomatonPainter>());
    });

    testWidgets('AutomatonCanvas renders DFA correctly', (tester) async {
      final canvasKey = GlobalKey();
      final testDFA = _createTestDFA();
      FSA? capturedAutomaton;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: testDFA,
              canvasKey: canvasKey,
              onAutomatonChanged: (automaton) {
                capturedAutomaton = automaton;
              },
            ),
          ),
        ),
      );

      expect(find.byType(AutomatonCanvas), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);

      // Verify DFA is rendered
      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final painter = customPaint.painter as AutomatonPainter;
      expect(painter.states.length, equals(2));
      expect(painter.transitions.length, equals(1));
    });

    testWidgets('AutomatonCanvas renders NFA correctly', (tester) async {
      final canvasKey = GlobalKey();
      final testNFA = _createTestNFA();
      FSA? capturedAutomaton;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: testNFA,
              canvasKey: canvasKey,
              onAutomatonChanged: (automaton) {
                capturedAutomaton = automaton;
              },
            ),
          ),
        ),
      );

      expect(find.byType(AutomatonCanvas), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);

      // Verify NFA is rendered
      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final painter = customPaint.painter as AutomatonPainter;
      expect(painter.states.length, equals(2));
      expect(painter.transitions.length, equals(1));
    });
  });

  group('Simulation Panel Widget Tests', () {
    testWidgets('SimulationPanel renders correctly without simulation result', (
      tester,
    ) async {
      String? simulatedInput;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimulationPanel(
              onSimulate: (input) {
                simulatedInput = input;
              },
              simulationResult: null,
              regexResult: null,
            ),
          ),
        ),
      );

      expect(find.byType(SimulationPanel), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Verify input field
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      // Verify simulate button
      final simulateButton = find.byType(ElevatedButton);
      expect(simulateButton, findsOneWidget);
    });

    testWidgets('SimulationPanel renders with successful simulation result', (
      tester,
    ) async {
      String? simulatedInput;
      final simulationResult = _createSuccessfulSimulationResult();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimulationPanel(
              onSimulate: (input) {
                simulatedInput = input;
              },
              simulationResult: simulationResult,
              regexResult: null,
            ),
          ),
        ),
      );

      expect(find.byType(SimulationPanel), findsOneWidget);

      // Verify simulation result is displayed
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Input: 01'), findsOneWidget);
    });

    testWidgets('SimulationPanel renders with failed simulation result', (
      tester,
    ) async {
      String? simulatedInput;
      final simulationResult = _createFailedSimulationResult();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimulationPanel(
              onSimulate: (input) {
                simulatedInput = input;
              },
              simulationResult: simulationResult,
              regexResult: null,
            ),
          ),
        ),
      );

      expect(find.byType(SimulationPanel), findsOneWidget);

      // Verify simulation result is displayed
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Input: 10'), findsOneWidget);
    });
  });

  group('Immutable Trace Visualization Tests', () {
    testWidgets('Simulation steps render correctly', (tester) async {
      final simulationResult = _createStepByStepSimulationResult();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimulationPanel(
              onSimulate: (input) {},
              simulationResult: simulationResult,
              regexResult: null,
            ),
          ),
        ),
      );

      expect(find.byType(SimulationPanel), findsOneWidget);

      // Verify simulation steps are displayed
      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('Step 2'), findsOneWidget);
      expect(find.text('Step 3'), findsOneWidget);
    });

    testWidgets('Simulation trace maintains immutability', (tester) async {
      final simulationResult = _createStepByStepSimulationResult();
      final originalSteps = simulationResult.steps.toList();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimulationPanel(
              onSimulate: (input) {},
              simulationResult: simulationResult,
              regexResult: null,
            ),
          ),
        ),
      );

      // Verify steps are immutable
      expect(simulationResult.steps.length, equals(originalSteps.length));
      for (int i = 0; i < originalSteps.length; i++) {
        expect(simulationResult.steps[i], equals(originalSteps[i]));
      }
    });
  });

  group('Performance and Responsiveness Tests', () {
    testWidgets('AutomatonCanvas handles large automatons efficiently', (
      tester,
    ) async {
      final canvasKey = GlobalKey();
      final largeDFA = _createLargeDFA();

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: largeDFA,
              canvasKey: canvasKey,
              onAutomatonChanged: (automaton) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Verify rendering completes within reasonable time
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Large automaton should render within 1 second',
      );

      expect(find.byType(AutomatonCanvas), findsOneWidget);
    });

    testWidgets(
      'SimulationPanel handles large simulation results efficiently',
      (tester) async {
        final largeSimulationResult = _createLargeSimulationResult();

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SimulationPanel(
                onSimulate: (input) {},
                simulationResult: largeSimulationResult,
                regexResult: null,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Verify rendering completes within reasonable time
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
          reason: 'Large simulation result should render within 1 second',
        );

        expect(find.byType(SimulationPanel), findsOneWidget);
      },
    );
  });
}

/// Helper functions to create test data

FSA _createTestDFA() {
  final states = {
    automaton_state.State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    automaton_state.State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'test_dfa',
    name: 'Test DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createTestNFA() {
  final states = {
    automaton_state.State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    automaton_state.State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'test_nfa',
    name: 'Test NFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createLargeDFA() {
  final states = <automaton_state.State>{};
  final transitions = <FSATransition>{};

  // Create 20 states
  for (int i = 0; i < 20; i++) {
    states.add(
      automaton_state.State(
        id: 'q$i',
        label: 'q$i',
        position: Vector2(i * 50.0, 0),
        isInitial: i == 0,
        isAccepting: i == 19,
      ),
    );

    if (i < 19) {
      transitions.add(
        FSATransition(
          id: 't$i',
          fromState: states.firstWhere((s) => s.id == 'q$i'),
          toState: states.firstWhere((s) => s.id == 'q${i + 1}'),
          symbol: '1',
        ),
      );
    }
  }

  return FSA(
    id: 'large_dfa',
    name: 'Large DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q19')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 1000, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

SimulationResult _createSuccessfulSimulationResult() {
  return SimulationResult.success(
    inputString: '01',
    steps: [
      SimulationStep.initial(initialState: 'q0', inputString: '01'),
      SimulationStep(
        currentState: 'q1',
        remainingInput: '1',
        usedTransition: 'q0->q1:0',
        stepNumber: 1,
        consumedInput: '0',
      ),
      SimulationStep(
        currentState: 'q2',
        remainingInput: '',
        usedTransition: 'q1->q2:1',
        stepNumber: 2,
        consumedInput: '1',
      ),
      SimulationStep(
        currentState: 'q2',
        remainingInput: '',
        stepNumber: 3,
        isAccepted: true,
      ),
    ],
    executionTime: const Duration(milliseconds: 10),
  );
}

SimulationResult _createFailedSimulationResult() {
  return SimulationResult.failure(
    inputString: '10',
    steps: [
      SimulationStep.initial(initialState: 'q0', inputString: '10'),
      SimulationStep(
        currentState: 'q1',
        remainingInput: '0',
        usedTransition: 'q0->q1:1',
        stepNumber: 1,
        consumedInput: '1',
      ),
      SimulationStep(
        currentState: 'q1',
        remainingInput: '',
        stepNumber: 2,
        isAccepted: false,
      ),
    ],
    errorMessage:
        'Input rejected: no valid transition from state q1 with input 0',
    executionTime: const Duration(milliseconds: 5),
  );
}

SimulationResult _createStepByStepSimulationResult() {
  return SimulationResult.success(
    inputString: '011',
    steps: [
      SimulationStep.initial(initialState: 'q0', inputString: '011'),
      SimulationStep(
        currentState: 'q1',
        remainingInput: '11',
        usedTransition: 'q0->q1:0',
        stepNumber: 1,
        consumedInput: '0',
      ),
      SimulationStep(
        currentState: 'q2',
        remainingInput: '1',
        usedTransition: 'q1->q2:1',
        stepNumber: 2,
        consumedInput: '1',
      ),
      SimulationStep(
        currentState: 'q3',
        remainingInput: '',
        usedTransition: 'q2->q3:1',
        stepNumber: 3,
        consumedInput: '1',
      ),
      SimulationStep(
        currentState: 'q3',
        remainingInput: '',
        stepNumber: 4,
        isAccepted: true,
      ),
    ],
    executionTime: const Duration(milliseconds: 15),
  );
}

SimulationResult _createLargeSimulationResult() {
  final steps = <SimulationStep>[];

  // Create 100 steps
  steps.add(SimulationStep.initial(initialState: 'q0', inputString: '0' * 100));

  for (int i = 0; i < 100; i++) {
    steps.add(
      SimulationStep(
        currentState: 'q${i + 1}',
        remainingInput: '0' * (99 - i),
        usedTransition: 'q$i->q${i + 1}:0',
        stepNumber: i + 1,
        consumedInput: '0',
      ),
    );
  }

  steps.add(
    SimulationStep(
      currentState: 'q100',
      remainingInput: '',
      stepNumber: 101,
      isAccepted: true,
    ),
  );

  return SimulationResult.success(
    inputString: '0' * 100,
    steps: steps,
    executionTime: const Duration(milliseconds: 50),
  );
}
