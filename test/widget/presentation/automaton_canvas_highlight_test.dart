import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/simulation_highlight.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/core/services/simulation_highlight_service.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_highlight_channel.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/providers/pda_editor_provider.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_native.dart';
import 'package:jflutter/presentation/widgets/pda_canvas_native.dart';
import 'package:jflutter/presentation/widgets/tm_canvas_native.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  testWidgets(
    'SimulationHighlightService propagates highlights through the canvas controller listeners',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = FlNodesCanvasController(
        automatonProvider: container.read(automatonProvider.notifier),
      );
      addTearDown(controller.dispose);

      final highlightService = SimulationHighlightService(
        channel: FlNodesSimulationHighlightChannel(controller),
      );
      addTearDown(highlightService.clear);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: _HighlightProbe(controller: controller)),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(''), findsOneWidget);

      const highlight = SimulationHighlight(
        stateIds: {'q0'},
        transitionIds: {'t1'},
      );
      highlightService.dispatch(highlight);
      await tester.pump();

      expect(find.text('q0'), findsOneWidget);

      highlightService.clear();
      await tester.pump();

      expect(find.text(''), findsOneWidget);
    },
  );

  testWidgets(
    'Canvas controller clears transition highlight when highlighted link is removed',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = FlNodesCanvasController(
        automatonProvider: container.read(automatonProvider.notifier),
      );
      addTearDown(controller.dispose);

      final highlightService = SimulationHighlightService(
        channel: FlNodesSimulationHighlightChannel(controller),
      );
      addTearDown(highlightService.clear);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: _HighlightProbe(controller: controller)),
          ),
        ),
      );
      await tester.pump();

      highlightService.dispatch(
        const SimulationHighlight(transitionIds: {'t1'}),
      );
      await tester.pump();

      expect(controller.highlightedTransitionIds, contains('t1'));
      expect(
        controller.highlightNotifier.value.transitionIds,
        contains('t1'),
      );

      controller.pruneLinkHighlight('t1');
      await tester.pump();

      expect(controller.highlightedTransitionIds, isEmpty);
      expect(controller.highlightNotifier.value, SimulationHighlight.empty);
    },
  );

  testWidgets(
    'AutomatonCanvas attaches highlight channel to the owned controller',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final automaton = _createSampleFsa();
      final theme = ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              body: AutomatonCanvas(
                automaton: automaton,
                canvasKey: GlobalKey(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final highlightService = container.read(canvasHighlightServiceProvider);
      addTearDown(highlightService.clear);

      final finder = find.text('q0');
      expect(finder, findsOneWidget);

      final initialText = tester.widget<Text>(finder);
      expect(
        initialText.style?.color,
        isNot(equals(theme.colorScheme.onPrimary)),
      );

      highlightService.dispatch(
        const SimulationHighlight(stateIds: {'q0'}, transitionIds: {}),
      );
      await tester.pump();

      final highlightedText = tester.widget<Text>(finder);
      expect(highlightedText.style?.color, theme.colorScheme.onPrimary);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SizedBox(),
        ),
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'PDACanvasNative attaches highlight channel to the owned controller',
    (tester) async {
      final pda = _createSamplePda();
      final container = ProviderContainer(
        overrides: [
          pdaEditorProvider.overrideWith(
            (ref) => _TestPdaEditorNotifier(pda),
          ),
        ],
      );
      addTearDown(container.dispose);

      final theme = ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              body: PDACanvasNative(
                onPdaModified: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final highlightService = container.read(canvasHighlightServiceProvider);
      addTearDown(highlightService.clear);

      final finder = find.text('p0');
      expect(finder, findsOneWidget);

      final initialText = tester.widget<Text>(finder);
      expect(
        initialText.style?.color,
        isNot(equals(theme.colorScheme.onPrimary)),
      );

      highlightService.dispatch(
        const SimulationHighlight(stateIds: {'p0'}, transitionIds: {}),
      );
      await tester.pump();

      final highlightedText = tester.widget<Text>(finder);
      expect(highlightedText.style?.color, theme.colorScheme.onPrimary);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SizedBox(),
        ),
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'TMCanvasNative attaches highlight channel to the owned controller',
    (tester) async {
      final tm = _createSampleTm();
      final container = ProviderContainer(
        overrides: [
          tmEditorProvider.overrideWith(
            (ref) => _TestTmEditorNotifier(tm),
          ),
        ],
      );
      addTearDown(container.dispose);

      final theme = ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              body: TMCanvasNative(
                onTMModified: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final highlightService = container.read(canvasHighlightServiceProvider);
      addTearDown(highlightService.clear);

      final finder = find.text('t0');
      expect(finder, findsOneWidget);

      final initialText = tester.widget<Text>(finder);
      expect(
        initialText.style?.color,
        isNot(equals(theme.colorScheme.onPrimary)),
      );

      highlightService.dispatch(
        const SimulationHighlight(stateIds: {'t0'}, transitionIds: {}),
      );
      await tester.pump();

      final highlightedText = tester.widget<Text>(finder);
      expect(highlightedText.style?.color, theme.colorScheme.onPrimary);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SizedBox(),
        ),
      );
      await tester.pumpAndSettle();
    },
  );
}

class _HighlightProbe extends StatefulWidget {
  const _HighlightProbe({required this.controller});

  final FlNodesCanvasController controller;

  @override
  State<_HighlightProbe> createState() => _HighlightProbeState();
}

class _HighlightProbeState extends State<_HighlightProbe> {
  SimulationHighlight? _lastHighlight;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    final notifier = widget.controller.highlightNotifier;
    _lastHighlight = notifier.value;
    _listener = () {
      final current = notifier.value;
      final previous = _lastHighlight;
      if (previous != null &&
          setEquals(previous.stateIds, current.stateIds) &&
          setEquals(previous.transitionIds, current.transitionIds)) {
        return;
      }
      setState(() {
        _lastHighlight = current;
      });
    };
    notifier.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) {
      widget.controller.highlightNotifier.removeListener(_listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = _lastHighlight;
    final label = highlight == null || highlight.stateIds.isEmpty
        ? ''
        : highlight.stateIds.join(',');
    return Center(child: Text(label));
  }
}

FSA _createSampleFsa() {
  final now = DateTime(2023, 1, 1);
  final state = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  return FSA(
    id: 'sample-fsa',
    name: 'Sample FSA',
    states: {state},
    transitions: <Transition>{},
    alphabet: <String>{},
    initialState: state,
    acceptingStates: <automaton_state.State>{},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
  );
}

PDA _createSamplePda() {
  final now = DateTime(2023, 1, 1);
  final state = automaton_state.State(
    id: 'p0',
    label: 'p0',
    position: Vector2.zero(),
    isInitial: true,
  );
  return PDA(
    id: 'sample-pda',
    name: 'Sample PDA',
    states: {state},
    transitions: <Transition>{},
    alphabet: <String>{},
    initialState: state,
    acceptingStates: <automaton_state.State>{},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
    stackAlphabet: const {'Z'},
    initialStackSymbol: 'Z',
  );
}

TM _createSampleTm() {
  final now = DateTime(2023, 1, 1);
  final state = automaton_state.State(
    id: 't0',
    label: 't0',
    position: Vector2.zero(),
    isInitial: true,
  );
  return TM(
    id: 'sample-tm',
    name: 'Sample TM',
    states: {state},
    transitions: <Transition>{},
    alphabet: <String>{},
    initialState: state,
    acceptingStates: <automaton_state.State>{},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
    tapeAlphabet: const {'B'},
    blankSymbol: 'B',
  );
}

class _TestPdaEditorNotifier extends PDAEditorNotifier {
  _TestPdaEditorNotifier(PDA pda) {
    state = state.copyWith(pda: pda);
  }
}

class _TestTmEditorNotifier extends TMEditorNotifier {
  _TestTmEditorNotifier(TM tm) {
    state = state.copyWith(
      tm: tm,
      states: tm.states.toList(),
    );
  }
}
