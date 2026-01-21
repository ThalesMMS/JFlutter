import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/models/algorithm_step.dart';
import 'package:jflutter/presentation/widgets/algorithm_step_viewer.dart';
import 'package:jflutter/presentation/widgets/step_navigation_controls.dart';

class _TestCallbacks {
  int showDetailsCallCount = 0;
  int previousCallCount = 0;
  int playPauseCallCount = 0;
  int nextCallCount = 0;
  int resetCallCount = 0;
  double? lastSpeedValue;

  void onShowDetails() {
    showDetailsCallCount++;
  }

  void onPrevious() {
    previousCallCount++;
  }

  void onPlayPause() {
    playPauseCallCount++;
  }

  void onNext() {
    nextCallCount++;
  }

  void onReset() {
    resetCallCount++;
  }

  void onSpeedChanged(double value) {
    lastSpeedValue = value;
  }
}

Future<void> _pumpStepViewer(
  WidgetTester tester, {
  required AlgorithmStep step,
  VoidCallback? onShowDetails,
  bool showExpandedDetails = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AlgorithmStepViewer(
            step: step,
            onShowDetails: onShowDetails,
            showExpandedDetails: showExpandedDetails,
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _pumpNavigationControls(
  WidgetTester tester, {
  int currentStepIndex = 0,
  int totalSteps = 5,
  bool isPlaying = false,
  double playbackSpeed = 1.0,
  VoidCallback? onPrevious,
  VoidCallback? onPlayPause,
  VoidCallback? onNext,
  VoidCallback? onReset,
  ValueChanged<double>? onSpeedChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StepNavigationControls(
          currentStepIndex: currentStepIndex,
          totalSteps: totalSteps,
          isPlaying: isPlaying,
          playbackSpeed: playbackSpeed,
          onPrevious: onPrevious,
          onPlayPause: onPlayPause,
          onNext: onNext,
          onReset: onReset,
          onSpeedChanged: onSpeedChanged,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlgorithmStepViewer', () {
    testWidgets('renders step header with number, title, and algorithm badge',
        (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Initialize DFA',
        explanation: 'Creating initial DFA structure',
        type: AlgorithmType.nfaToDfa,
      );

      await _pumpStepViewer(tester, step: step);

      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('Initialize DFA'), findsOneWidget);
      expect(find.text('NFA→DFA'), findsOneWidget);
    });

    testWidgets('renders explanation section with icon and text',
        (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'This is a detailed explanation of the step',
        type: AlgorithmType.dfaMinimization,
      );

      await _pumpStepViewer(tester, step: step);

      expect(find.text('Explanation'), findsOneWidget);
      expect(
        find.text('This is a detailed explanation of the step'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders properties section with list values', (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
        properties: {
          'currentStates': ['q0', 'q1', 'q2'],
        },
      );

      await _pumpStepViewer(tester, step: step);

      expect(find.text('Step Data'), findsOneWidget);
      expect(find.text('Current States'), findsOneWidget);
      expect(find.text('q0'), findsOneWidget);
      expect(find.text('q1'), findsOneWidget);
      expect(find.text('q2'), findsOneWidget);
      expect(find.byIcon(Icons.data_object), findsOneWidget);
    });

    testWidgets('renders properties section with set values', (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
        properties: {
          'visitedStates': {'q0', 'q1'},
        },
      );

      await _pumpStepViewer(tester, step: step);

      expect(find.text('Visited States'), findsOneWidget);
      expect(find.text('q0'), findsOneWidget);
      expect(find.text('q1'), findsOneWidget);
    });

    testWidgets('renders empty set as empty set symbol', (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
        properties: {
          'emptySet': <String>{},
        },
      );

      await _pumpStepViewer(tester, step: step);

      expect(find.text('∅'), findsOneWidget);
    });

    testWidgets('renders empty list with (empty) text', (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
        properties: {
          'emptyList': <String>[],
        },
      );

      await _pumpStepViewer(tester, step: step);

      expect(find.text('(empty)'), findsOneWidget);
    });

    testWidgets('renders boolean values with check/cancel icons',
        (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
        properties: {
          'isAcceptingState': true,
          'hasTransitions': false,
        },
      );

      await _pumpStepViewer(tester, step: step);

      expect(find.text('Is Accepting State'), findsOneWidget);
      expect(find.text('Has Transitions'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('renders map values with item count', (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
        properties: {
          'transitions': {'a': 'q1', 'b': 'q2', 'c': 'q3'},
        },
      );

      await _pumpStepViewer(tester, step: step);

      expect(find.text('{3 items}'), findsOneWidget);
    });

    testWidgets('renders empty string as epsilon symbol', (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
        properties: {
          'symbol': '',
        },
      );

      await _pumpStepViewer(tester, step: step);

      expect(find.text('ε'), findsOneWidget);
    });

    testWidgets('formats camelCase property keys to Title Case',
        (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
        properties: {
          'currentState': 'q0',
          'nextStateToProcess': 'q1',
        },
      );

      await _pumpStepViewer(tester, step: step);

      expect(find.text('Current State'), findsOneWidget);
      expect(find.text('Next State To Process'), findsOneWidget);
    });

    testWidgets('hides properties section when properties are empty',
        (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
        properties: {},
      );

      await _pumpStepViewer(tester, step: step);

      expect(find.text('Step Data'), findsNothing);
      expect(find.byIcon(Icons.data_object), findsNothing);
    });

    testWidgets('shows details button when callback is provided',
        (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
      );

      await _pumpStepViewer(
        tester,
        step: step,
        onShowDetails: () {},
      );

      expect(find.text('Show More Details'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('hides details button when callback is not provided',
        (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
      );

      await _pumpStepViewer(tester, step: step);

      expect(find.text('Show More Details'), findsNothing);
      expect(find.text('Hide Details'), findsNothing);
    });

    testWidgets('shows Hide Details when expanded', (tester) async {
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
      );

      await _pumpStepViewer(
        tester,
        step: step,
        onShowDetails: () {},
        showExpandedDetails: true,
      );

      expect(find.text('Hide Details'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('triggers onShowDetails callback when button is tapped',
        (tester) async {
      final callbacks = _TestCallbacks();
      final step = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test Step',
        explanation: 'Test explanation',
        type: AlgorithmType.nfaToDfa,
      );

      await _pumpStepViewer(
        tester,
        step: step,
        onShowDetails: callbacks.onShowDetails,
      );

      expect(callbacks.showDetailsCallCount, 0);

      await tester.tap(find.text('Show More Details'));
      await tester.pumpAndSettle();

      expect(callbacks.showDetailsCallCount, 1);
    });

    testWidgets('displays correct algorithm type labels', (tester) async {
      final nfaToDfaStep = AlgorithmStep(
        id: 'step-1',
        stepNumber: 0,
        title: 'Test',
        explanation: 'Test',
        type: AlgorithmType.nfaToDfa,
      );

      await _pumpStepViewer(tester, step: nfaToDfaStep);
      expect(find.text('NFA→DFA'), findsOneWidget);

      final minimizeStep = AlgorithmStep(
        id: 'step-2',
        stepNumber: 0,
        title: 'Test',
        explanation: 'Test',
        type: AlgorithmType.dfaMinimization,
      );

      await _pumpStepViewer(tester, step: minimizeStep);
      expect(find.text('Minimize'), findsOneWidget);

      final regexStep = AlgorithmStep(
        id: 'step-3',
        stepNumber: 0,
        title: 'Test',
        explanation: 'Test',
        type: AlgorithmType.faToRegex,
      );

      await _pumpStepViewer(tester, step: regexStep);
      expect(find.text('FA→Regex'), findsOneWidget);
    });
  });

  group('StepNavigationControls', () {
    testWidgets('renders all navigation buttons', (tester) async {
      await _pumpNavigationControls(tester);

      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('displays correct step counter', (tester) async {
      await _pumpNavigationControls(
        tester,
        currentStepIndex: 2,
        totalSteps: 5,
      );

      expect(find.text('3 / 5'), findsOneWidget);
    });

    testWidgets('displays 0 / 0 when no steps', (tester) async {
      await _pumpNavigationControls(
        tester,
        currentStepIndex: 0,
        totalSteps: 0,
      );

      expect(find.text('0 / 0'), findsOneWidget);
    });

    testWidgets('disables previous button on first step', (tester) async {
      await _pumpNavigationControls(
        tester,
        currentStepIndex: 0,
        totalSteps: 5,
        onPrevious: () {},
      );

      final previousButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.skip_previous),
      );

      expect(previousButton.onPressed, isNull);
    });

    testWidgets('enables previous button when not on first step',
        (tester) async {
      await _pumpNavigationControls(
        tester,
        currentStepIndex: 2,
        totalSteps: 5,
        onPrevious: () {},
      );

      final previousButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.skip_previous),
      );

      expect(previousButton.onPressed, isNotNull);
    });

    testWidgets('disables next button on last step', (tester) async {
      await _pumpNavigationControls(
        tester,
        currentStepIndex: 4,
        totalSteps: 5,
        onNext: () {},
      );

      final nextButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.skip_next),
      );

      expect(nextButton.onPressed, isNull);
    });

    testWidgets('enables next button when not on last step', (tester) async {
      await _pumpNavigationControls(
        tester,
        currentStepIndex: 2,
        totalSteps: 5,
        onNext: () {},
      );

      final nextButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.skip_next),
      );

      expect(nextButton.onPressed, isNotNull);
    });

    testWidgets('shows play icon when not playing', (tester) async {
      await _pumpNavigationControls(
        tester,
        isPlaying: false,
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('shows pause icon when playing', (tester) async {
      await _pumpNavigationControls(
        tester,
        isPlaying: true,
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('triggers previous callback when button is tapped',
        (tester) async {
      final callbacks = _TestCallbacks();

      await _pumpNavigationControls(
        tester,
        currentStepIndex: 2,
        totalSteps: 5,
        onPrevious: callbacks.onPrevious,
      );

      expect(callbacks.previousCallCount, 0);

      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pumpAndSettle();

      expect(callbacks.previousCallCount, 1);
    });

    testWidgets('triggers play/pause callback when button is tapped',
        (tester) async {
      final callbacks = _TestCallbacks();

      await _pumpNavigationControls(
        tester,
        onPlayPause: callbacks.onPlayPause,
      );

      expect(callbacks.playPauseCallCount, 0);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(callbacks.playPauseCallCount, 1);
    });

    testWidgets('triggers next callback when button is tapped',
        (tester) async {
      final callbacks = _TestCallbacks();

      await _pumpNavigationControls(
        tester,
        currentStepIndex: 2,
        totalSteps: 5,
        onNext: callbacks.onNext,
      );

      expect(callbacks.nextCallCount, 0);

      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      expect(callbacks.nextCallCount, 1);
    });

    testWidgets('shows reset button when callback is provided',
        (tester) async {
      await _pumpNavigationControls(
        tester,
        onReset: () {},
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('hides reset button when callback is not provided',
        (tester) async {
      await _pumpNavigationControls(tester);

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('triggers reset callback when button is tapped',
        (tester) async {
      final callbacks = _TestCallbacks();

      await _pumpNavigationControls(
        tester,
        onReset: callbacks.onReset,
      );

      expect(callbacks.resetCallCount, 0);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(callbacks.resetCallCount, 1);
    });

    testWidgets('shows speed slider when callback is provided',
        (tester) async {
      await _pumpNavigationControls(
        tester,
        onSpeedChanged: (value) {},
      );

      expect(find.text('Speed:'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byIcon(Icons.speed), findsOneWidget);
    });

    testWidgets('hides speed slider when callback is not provided',
        (tester) async {
      await _pumpNavigationControls(tester);

      expect(find.text('Speed:'), findsNothing);
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('displays current speed correctly', (tester) async {
      await _pumpNavigationControls(
        tester,
        playbackSpeed: 2.5,
        onSpeedChanged: (value) {},
      );

      expect(find.text('2.50x'), findsNWidgets(2)); // Label and display text
    });

    testWidgets('triggers speed change callback when slider is moved',
        (tester) async {
      final callbacks = _TestCallbacks();

      await _pumpNavigationControls(
        tester,
        playbackSpeed: 1.0,
        onSpeedChanged: callbacks.onSpeedChanged,
      );

      expect(callbacks.lastSpeedValue, isNull);

      // Find and drag the slider
      await tester.drag(find.byType(Slider), const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(callbacks.lastSpeedValue, isNotNull);
      expect(callbacks.lastSpeedValue! > 1.0, isTrue);
    });

    testWidgets('has correct tooltip texts', (tester) async {
      await _pumpNavigationControls(
        tester,
        onPrevious: () {},
        onPlayPause: () {},
        onNext: () {},
        onReset: () {},
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton && widget.tooltip == 'Previous Step',
        ),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Play',
        ),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Next Step',
        ),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton && widget.tooltip == 'Reset to First Step',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tooltip changes to Pause when playing', (tester) async {
      await _pumpNavigationControls(
        tester,
        isPlaying: true,
        onPlayPause: () {},
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Pause',
        ),
        findsOneWidget,
      );
    });
  });
}
