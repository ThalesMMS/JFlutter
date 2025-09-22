import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/presentation/providers/automaton_canvas_controller.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutomatonCanvasController state IDs', () {
    test('increments IDs when adding new states', () {
      final controller = AutomatonCanvasController();

      controller.addState(Offset.zero);
      controller.addState(const Offset(100, 0));

      final ids = controller.states.map((state) => state.id).toList();
      final labels = controller.states.map((state) => state.label).toList();

      expect(ids, equals(['q0', 'q1']));
      expect(ids.toSet().length, ids.length);
      expect(labels.toSet().length, labels.length);
    });

    test('respects loaded automaton when generating next IDs', () {
      final existingStates = <automaton_state.State>{
        automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2.zero(),
          isInitial: true,
        ),
        automaton_state.State(
          id: 'q10',
          label: 'q10',
          position: Vector2(50, 0),
          isAccepting: true,
        ),
      };

      final automaton = FSA(
        id: 'test',
        name: 'Test Automaton',
        states: existingStates,
        transitions: <Transition>{},
        alphabet: <String>{},
        initialState: existingStates.first,
        acceptingStates: existingStates.where((state) => state.isAccepting).toSet(),
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      final controller = AutomatonCanvasController(automaton: automaton);

      controller.addState(const Offset(200, 0));

      expect(controller.states.last.id, 'q11');
      expect(controller.states.last.label, 'q11');
      expect(controller.states.map((s) => s.id).toSet().length,
          controller.states.length);
      expect(controller.states.map((s) => s.label).toSet().length,
          controller.states.length);
    });
  });
}
