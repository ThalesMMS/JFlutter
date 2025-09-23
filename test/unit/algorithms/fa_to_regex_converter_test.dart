import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/fa_to_regex_converter.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('FAToRegexConverter state elimination', () {
    test('combines parallel transitions through eliminated states', () {
      final initial = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final middle = State(
        id: 'q1',
        label: 'q1',
        position: Vector2.zero(),
      );
      final accepting = State(
        id: 'q2',
        label: 'q2',
        position: Vector2.zero(),
        isAccepting: true,
      );

      final fsa = FSA(
        id: 'fa_parallel',
        name: 'Parallel transitions',
        states: {initial, middle, accepting},
        transitions: {
          FSATransition(
            id: 't_a',
            fromState: initial,
            toState: middle,
            label: 'a',
            inputSymbols: {'a'},
          ),
          FSATransition(
            id: 't_b',
            fromState: initial,
            toState: middle,
            label: 'b',
            inputSymbols: {'b'},
          ),
          FSATransition(
            id: 't_c',
            fromState: middle,
            toState: accepting,
            label: 'c',
            inputSymbols: {'c'},
          ),
          FSATransition(
            id: 't_d',
            fromState: middle,
            toState: accepting,
            label: 'd',
            inputSymbols: {'d'},
          ),
          FSATransition(
            id: 't_e',
            fromState: middle,
            toState: middle,
            label: 'e',
            inputSymbols: {'e'},
          ),
        },
        alphabet: {'a', 'b', 'c', 'd', 'e'},
        initialState: initial,
        acceptingStates: {accepting},
        created: DateTime(2024, 1, 1),
        modified: DateTime(2024, 1, 2),
        bounds: const math.Rectangle(0, 0, 400, 400),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      final result = FAToRegexConverter.convert(fsa);

      expect(result.isSuccess, isTrue);
      expect(
        result.data,
        '((((a(e)*c)|a(e)*d)|b(e)*c)|b(e)*d)',
      );
    });

    test('merges new paths with existing transitions between states', () {
      final initial = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final middle = State(
        id: 'q1',
        label: 'q1',
        position: Vector2.zero(),
      );
      final accepting = State(
        id: 'q2',
        label: 'q2',
        position: Vector2.zero(),
        isAccepting: true,
      );

      final fsa = FSA(
        id: 'fa_existing',
        name: 'Existing transition merge',
        states: {initial, middle, accepting},
        transitions: {
          FSATransition(
            id: 't_direct',
            fromState: initial,
            toState: accepting,
            label: 'z',
            inputSymbols: {'z'},
          ),
          FSATransition(
            id: 't_a',
            fromState: initial,
            toState: middle,
            label: 'a',
            inputSymbols: {'a'},
          ),
          FSATransition(
            id: 't_b',
            fromState: initial,
            toState: middle,
            label: 'b',
            inputSymbols: {'b'},
          ),
          FSATransition(
            id: 't_c',
            fromState: middle,
            toState: accepting,
            label: 'c',
            inputSymbols: {'c'},
          ),
          FSATransition(
            id: 't_d',
            fromState: middle,
            toState: accepting,
            label: 'd',
            inputSymbols: {'d'},
          ),
          FSATransition(
            id: 't_e',
            fromState: middle,
            toState: middle,
            label: 'e',
            inputSymbols: {'e'},
          ),
        },
        alphabet: {'a', 'b', 'c', 'd', 'e', 'z'},
        initialState: initial,
        acceptingStates: {accepting},
        created: DateTime(2024, 1, 1),
        modified: DateTime(2024, 1, 2),
        bounds: const math.Rectangle(0, 0, 400, 400),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      final result = FAToRegexConverter.convert(fsa);

      expect(result.isSuccess, isTrue);
      expect(
        result.data,
        '(((((z)|a(e)*c)|a(e)*d)|b(e)*c)|b(e)*d)',
      );
    });
  });
}
