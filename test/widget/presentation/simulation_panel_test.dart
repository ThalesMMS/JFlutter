import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/core/models/simulation_highlight.dart';
import 'package:jflutter/core/services/simulation_highlight_service.dart';
import 'package:jflutter/presentation/widgets/simulation_panel.dart';

class _TestSimulationHighlightService extends SimulationHighlightService {
  int clearCallCount = 0;
  int emitFromStepsCallCount = 0;
  List<int> emittedIndices = [];

  @override
  void clear() {
    clearCallCount++;
    super.clear();
  }

  @override
  SimulationHighlight emitFromSteps(
    List<SimulationStep> steps,
    int currentIndex,
  ) {
    emitFromStepsCallCount++;
    emittedIndices.add(currentIndex);
    return super.emitFromSteps(steps, currentIndex);
  }
}

class _SimulationCallback {
  final List<String> receivedInputs = [];

  void call(String input) {
    receivedInputs.add(input);
  }
}

Future<void> _pumpSimulationPanel(
  WidgetTester tester, {
  required _SimulationCallback onSimulate,
  SimulationResult? simulationResult,
  String? regexResult,
  _TestSimulationHighlightService? highlightService,
  double animationSpeed = 1.0,
  ValueChanged<double>? onAnimationSpeedChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SimulationPanel(
          onSimulate: onSimulate,
          simulationResult: simulationResult,
          regexResult: regexResult,
          highlightService:
              highlightService ?? _TestSimulationHighlightService(),
          animationSpeed: animationSpeed,
          onAnimationSpeedChanged: onAnimationSpeedChanged,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SimulationPanel', () {
    testWidgets('renders basic UI elements', (tester) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(tester, onSimulate: callback);

      expect(find.text('Simulation'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Input String'), findsOneWidget);
      expect(find.text('Enter string to test'), findsOneWidget);
      expect(find.text('Simulate'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Step-by-Step Mode'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('calls onSimulate when simulate button is pressed', (
      tester,
    ) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(tester, onSimulate: callback);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simulate'));
      await tester.pumpAndSettle();

      expect(callback.receivedInputs, contains('abc'));
    });

    testWidgets('calls onSimulate when Enter is pressed in text field', (
      tester,
    ) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(tester, onSimulate: callback);

      await tester.enterText(find.byType(TextField), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(callback.receivedInputs, contains('test'));
    });

    testWidgets('does not call onSimulate with empty input', (tester) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(tester, onSimulate: callback);

      await tester.tap(find.text('Simulate'));
      await tester.pumpAndSettle();

      expect(callback.receivedInputs, isEmpty);
    });

    testWidgets('shows simulating state when simulating', (tester) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(tester, onSimulate: callback);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simulate'));
      await tester.pump();

      expect(find.text('Simulating...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Simulating...'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('displays accepted simulation result', (tester) async {
      final callback = _SimulationCallback();
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
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      expect(find.text('Simulation Result'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Steps: 2'), findsOneWidget);
    });

    testWidgets('displays rejected simulation result with error message', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.failure(
        inputString: 'xyz',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'xyz',
            stepNumber: 0,
          ),
        ],
        errorMessage: 'No valid transition found',
        executionTime: const Duration(milliseconds: 50),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      expect(find.text('Simulation Result'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.text('Steps: 1'), findsOneWidget);
      expect(find.text('Error: No valid transition found'), findsOneWidget);
    });

    testWidgets('displays regex result', (tester) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        regexResult: 'a(b|c)*d',
      );

      expect(find.text('Regex Result'), findsOneWidget);
      expect(find.text('Regular Expression'), findsOneWidget);
      expect(find.text('a(b|c)*d'), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
    });

    testWidgets('toggles step-by-step mode on', (tester) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();
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
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        highlightService: highlightService,
      );

      final switchFinder = find.byType(Switch);
      expect(tester.widget<Switch>(switchFinder).value, isFalse);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isTrue);
      expect(find.text('Step-by-Step Execution'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(highlightService.emitFromStepsCallCount, greaterThan(0));
    });

    testWidgets('toggles step-by-step mode off and clears highlight', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();
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
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        highlightService: highlightService,
      );

      final switchFinder = find.byType(Switch);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isTrue);
      final clearCountBefore = highlightService.clearCallCount;

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);
      expect(find.text('Step-by-Step Execution'), findsNothing);
      expect(highlightService.clearCallCount, greaterThan(clearCountBefore));
    });

    testWidgets('navigates to next step in step-by-step mode', (tester) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();
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
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        highlightService: highlightService,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Next Step'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(highlightService.emittedIndices, contains(1));
    });

    testWidgets('navigates to previous step in step-by-step mode', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();
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
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        highlightService: highlightService,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Next Step'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous Step'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(highlightService.emittedIndices, contains(0));
    });

    testWidgets('resets to first step when reset button is pressed', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();
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
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        highlightService: highlightService,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Next Step'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 2'), findsOneWidget);

      await tester.tap(find.byTooltip('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 2'), findsOneWidget);
    });

    testWidgets('disables previous button at first step', (tester) async {
      final callback = _SimulationCallback();
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
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final previousButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.skip_previous),
      );
      expect(previousButton.onPressed, isNull);
    });

    testWidgets('disables next button at last step', (tester) async {
      final callback = _SimulationCallback();
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
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Next Step'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 2'), findsOneWidget);

      final nextButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.skip_next),
      );
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('displays step descriptions in step list', (tester) async {
      final callback = _SimulationCallback();
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
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(CircleAvatar), findsNWidgets(3));
    });

    testWidgets('highlights current step in step list', (tester) async {
      final callback = _SimulationCallback();
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
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final avatars = tester.widgetList<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(avatars.length, 2);
    });

    testWidgets('shows play/pause button in step-by-step mode', (tester) async {
      final callback = _SimulationCallback();
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
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Play'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNWidgets(2));
    });

    testWidgets('clears highlight service on dispose', (tester) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        highlightService: highlightService,
      );

      final clearCountBefore = highlightService.clearCallCount;

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(highlightService.clearCallCount, greaterThan(clearCountBefore));
    });

    testWidgets('updates when simulation result changes', (tester) async {
      final callback = _SimulationCallback();
      final result1 = SimulationResult.success(
        inputString: 'a',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'a',
            stepNumber: 0,
          ),
        ],
        executionTime: const Duration(milliseconds: 50),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result1,
      );

      expect(find.text('Steps: 1'), findsOneWidget);

      final result2 = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result2,
      );

      expect(find.text('Steps: 2'), findsOneWidget);
    });

    testWidgets('displays current step information in step-by-step mode', (
      tester,
    ) async {
      final callback = _SimulationCallback();
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
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Step 1'), findsOneWidget);
      expect(find.textContaining('Start at q0'), findsOneWidget);

      await tester.tap(find.byTooltip('Next Step'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2'), findsOneWidget);
      expect(find.textContaining('Consumed: "a"'), findsOneWidget);
      expect(find.textContaining('Next state: q2'), findsOneWidget);
      expect(find.textContaining('Remaining input: "b"'), findsOneWidget);
    });

    testWidgets('shows final step with acceptance verdict', (tester) async {
      final callback = _SimulationCallback();
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
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Next Step'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2'), findsOneWidget);
      expect(find.textContaining('input accepted'), findsOneWidget);
    });

    testWidgets('handles epsilon transitions in step descriptions', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.success(
        inputString: '',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: '',
            stepNumber: 0,
          ),
        ],
        executionTime: const Duration(milliseconds: 50),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.textContaining('ε'), findsOneWidget);
    });
  });
}
