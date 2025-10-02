import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/presentation/mappers/draw2d_tm_mapper.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('Draw2DTMMapper', () {
    test('includes tm type in serialised payloads', () {
      final initialState = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final nextState = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
        isAccepting: true,
      );
      final transition = TMTransition(
        id: 't0',
        fromState: initialState,
        toState: nextState,
        label: 'a/b,R',
        controlPoint: Vector2.zero(),
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
      );
      final machine = TM(
        id: 'tm1',
        name: 'Example TM',
        states: {initialState, nextState},
        transitions: {transition},
        alphabet: {'a', 'b'},
        initialState: initialState,
        acceptingStates: {nextState},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 2),
        bounds: const math.Rectangle<double>(0, 0, 200, 100),
        zoomLevel: 1.0,
        panOffset: Vector2.zero(),
        tapeAlphabet: {'a', 'b', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      final serializedMachine = Draw2DTMMapper.toJson(machine);
      final serializedNull = Draw2DTMMapper.toJson(null);

      expect(serializedMachine['type'], 'tm');
      expect(serializedNull['type'], 'tm');
    });
  });
}
