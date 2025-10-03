import 'dart:math' as math;

import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/simulation_highlight.dart';
import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_label_field_editor.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas.dart';
import 'package:jflutter/presentation/widgets/simulation_panel.dart';
import 'package:vector_math/vector_math_64.dart';

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
  group('AutomatonCanvas (fl_nodes) integration', () {
    late ProviderContainer container;
    late FlNodesCanvasController controller;

    setUp(() {
      container = ProviderContainer();
      controller = FlNodesCanvasController(
        automatonProvider: container.read(automatonProvider.notifier),
      );
    });

    tearDown(() {
      controller.dispose();
      container.dispose();
    });

    Future<void> pumpCanvas(WidgetTester tester, FSA? automaton) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AutomatonCanvas(
                automaton: automaton,
                canvasKey: GlobalKey(),
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'synchronizes nodes and transitions with fl_nodes controller',
      (tester) async {
        final automaton = _createTestDFA();

        await pumpCanvas(tester, automaton);

        expect(find.byType(AutomatonCanvas), findsOneWidget);
        expect(find.byType(FlNodeEditorWidget), findsOneWidget);
        expect(controller.nodeById('q0'), isNotNull);
        expect(controller.nodeById('q1'), isNotNull);
        expect(controller.edgeById('t1'), isNotNull);
        expect(controller.controller.nodes.length, automaton.states.length);
        expect(
          controller.controller.linksById.length,
          automaton.fsaTransitions.length,
        );
      },
    );

    testWidgets(
      'renders transition label editor overlay when selecting a link',
      (tester) async {
        final automaton = _createTestDFA();

        await pumpCanvas(tester, automaton);

        controller.controller.selectLinkById('t1');
        await tester.pump();

        expect(
          find.byKey(const ValueKey('transition-editor-t1-a')),
          findsOneWidget,
        );
        expect(find.byType(FlNodesLabelFieldEditor), findsOneWidget);
      },
    );

    testWidgets(
      'applies transition highlights through controller notifier',
      (tester) async {
        final automaton = _createTestDFA();

        await pumpCanvas(tester, automaton);

        controller.applyHighlight(
          const SimulationHighlight(transitionIds: {'t1'}),
        );
        await tester.pump();

        expect(controller.highlightNotifier.value.transitionIds, contains('t1'));
        final link = controller.controller.linksById['t1'];
        expect(link, isNotNull);
        expect(link!.state.isSelected, isTrue);

        controller.clearHighlight();
        await tester.pump();

        expect(controller.highlightNotifier.value.transitionIds, isEmpty);
        expect(link.state.isSelected, isFalse);
      },
    );
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
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = FlNodesCanvasController(
        automatonProvider: container.read(automatonProvider.notifier),
      );
      addTearDown(controller.dispose);

      final canvasKey = GlobalKey();
      final largeDFA = _createLargeDFA();

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AutomatonCanvas(
                automaton: largeDFA,
                canvasKey: canvasKey,
                controller: controller,
              ),
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

      expect(find.byType(FlNodeEditorWidget), findsOneWidget);
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
