import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/simulation_highlight.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  testWidgets('applies controller highlight updates to rendered node headers',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = FlNodesCanvasController(
      automatonProvider: container.read(automatonProvider.notifier),
    );
    addTearDown(controller.dispose);

    final automaton = _singleStateAutomaton();
    final canvasKey = GlobalKey();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: automaton,
              canvasKey: canvasKey,
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final context = tester.element(find.byType(AutomatonCanvas));
    final theme = Theme.of(context);

    Color backgroundColorFor(String label) {
      final textFinder = find.text(label);
      expect(textFinder, findsOneWidget);
      final containerFinder = find.ancestor(
        of: textFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container && widget.decoration is BoxDecoration,
        ),
      );
      final containers = tester.widgetList<Container>(containerFinder);
      final header = containers.firstWhere(
        (candidate) => candidate.decoration is BoxDecoration,
      );
      final decoration = header.decoration! as BoxDecoration;
      return decoration.color ?? Colors.transparent;
    }

    expect(backgroundColorFor('q0'), theme.colorScheme.primaryContainer);

    controller.applyHighlight(const SimulationHighlight(stateIds: {'q0'}));
    await tester.pump();

    expect(backgroundColorFor('q0'), theme.colorScheme.primary);

    controller.clearHighlight();
    await tester.pump();

    expect(backgroundColorFor('q0'), theme.colorScheme.primaryContainer);
  });
}

FSA _singleStateAutomaton() {
  final state = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: false,
  );

  return FSA(
    id: 'a',
    name: 'single',
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: const {},
    created: DateTime(2024, 1, 1),
    modified: DateTime(2024, 1, 1),
    bounds: const math.Rectangle(0, 0, 400, 300),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
  );
}
