import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/automaton.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('Automaton JSON round trips', () {
    test('loads FSA transitions saved with endpoint ids', () {
      final q0 = _state('q0', isInitial: true);
      final q1 = _state('q1', x: 120, isAccepting: true);
      final automaton = FSA(
        id: 'fsa_json',
        name: 'FSA JSON',
        states: {q0, q1},
        transitions: {
          FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            inputSymbols: const {'a'},
          ),
        },
        alphabet: const {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2026, 1, 1),
        modified: DateTime.utc(2026, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        panOffset: Vector2.zero(),
      );

      final loaded = Automaton.fromJson(automaton.toJson()) as FSA;
      final transition = loaded.transitions.whereType<FSATransition>().single;
      final loadedQ0 = loaded.states.singleWhere((state) => state.id == 'q0');
      final loadedQ1 = loaded.states.singleWhere((state) => state.id == 'q1');

      expect(transition.fromState, same(loadedQ0));
      expect(transition.toState, same(loadedQ1));
      expect(transition.inputSymbols, equals({'a'}));
    });

    test('loads PDA transitions saved with endpoint ids', () {
      final q0 = _state('q0', isInitial: true);
      final q1 = _state('q1', x: 120, isAccepting: true);
      final automaton = PDA(
        id: 'pda_json',
        name: 'PDA JSON',
        states: {q0, q1},
        transitions: {
          PDATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            label: 'a, Z/Z',
            inputSymbol: 'a',
            popSymbol: 'Z',
            pushSymbol: 'Z',
          ),
        },
        alphabet: const {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2026, 1, 1),
        modified: DateTime.utc(2026, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        panOffset: Vector2.zero(),
        stackAlphabet: const {'Z'},
        initialStackSymbol: 'Z',
      );

      final loaded = Automaton.fromJson(automaton.toJson()) as PDA;
      final transition = loaded.transitions.whereType<PDATransition>().single;
      final loadedQ0 = loaded.states.singleWhere((state) => state.id == 'q0');
      final loadedQ1 = loaded.states.singleWhere((state) => state.id == 'q1');

      expect(transition.fromState, same(loadedQ0));
      expect(transition.toState, same(loadedQ1));
      expect(transition.inputSymbol, equals('a'));
      expect(transition.popSymbol, equals('Z'));
      expect(transition.pushSymbol, equals('Z'));
    });
  });
}

automaton_state.State _state(
  String id, {
  double x = 0,
  bool isInitial = false,
  bool isAccepting = false,
}) {
  return automaton_state.State(
    id: id,
    label: id,
    position: Vector2(x, 0),
    isInitial: isInitial,
    isAccepting: isAccepting,
  );
}
