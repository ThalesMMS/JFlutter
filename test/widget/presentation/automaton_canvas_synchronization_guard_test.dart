import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart';
import 'package:jflutter/features/layout/layout_repository_impl.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_native.dart';

class _TrackingFlNodesCanvasController extends FlNodesCanvasController {
  _TrackingFlNodesCanvasController({required AutomatonProvider automatonProvider})
      : super(automatonProvider: automatonProvider);

  int synchronizeCallCount = 0;

  @override
  void synchronize(FSA? automaton) {
    synchronizeCallCount += 1;
    super.synchronize(automaton);
  }
}

void main() {
  testWidgets('AutomatonCanvas skips synchronization when snapshot is unchanged',
      (tester) async {
    final notifier = AutomatonProvider(
      automatonService: AutomatonService(),
      layoutRepository: LayoutRepositoryImpl(),
    );
    addTearDown(notifier.dispose);

    final controller =
        _TrackingFlNodesCanvasController(automatonProvider: notifier);
    addTearDown(controller.dispose);

    final canvasKey = GlobalKey();
    final initialAutomaton = _buildAutomaton();

    notifier.state = AutomatonState(currentAutomaton: initialAutomaton);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          automatonProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(automatonProvider);
              return Scaffold(
                body: SizedBox(
                  width: 600,
                  height: 400,
                  child: AutomatonCanvas(
                    automaton: state.currentAutomaton,
                    canvasKey: canvasKey,
                    controller: controller,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(controller.synchronizeCallCount, 1);

    final equivalentAutomaton = _buildAutomaton();
    notifier.state = notifier.state.copyWith(
      currentAutomaton: equivalentAutomaton,
    );

    await tester.pump();

    expect(controller.synchronizeCallCount, 1);

    final movedAutomaton = _buildAutomaton(q1Position: Vector2(180, 0));
    notifier.state = notifier.state.copyWith(
      currentAutomaton: movedAutomaton,
    );

    await tester.pump();

    expect(controller.synchronizeCallCount, 2);
  });
}

FSA _buildAutomaton({
  Vector2? q0Position,
  Vector2? q1Position,
  Set<String>? inputSymbols,
}) {
  final q0 = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: (q0Position ?? Vector2.zero()).clone(),
    isInitial: true,
    isAccepting: false,
  );
  final q1 = automaton_state.State(
    id: 'q1',
    label: 'q1',
    position: (q1Position ?? Vector2(120, 0)).clone(),
    isInitial: false,
    isAccepting: true,
  );

  final transition = FSATransition(
    id: 't0',
    fromState: q0,
    toState: q1,
    inputSymbols: inputSymbols ?? {'a'},
    controlPoint: Vector2(60, -40),
  );

  final timestamp = DateTime(2024, 1, 1);

  return FSA(
    id: 'test-fsa',
    name: 'Test FSA',
    states: {q0, q1},
    transitions: {transition},
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: timestamp,
    modified: timestamp,
    bounds: math.Rectangle<double>(0, 0, 400, 400),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
  );
}
