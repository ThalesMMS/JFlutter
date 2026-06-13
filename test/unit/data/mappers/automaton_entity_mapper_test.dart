import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart' as core_state;
import 'package:jflutter/data/mappers/automaton_entity_mapper.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('AutomatonEntityMapper', () {
    test('maps deterministic entity transitions to FSA and back', () {
      const entity = AutomatonEntity(
        id: 'dfa',
        name: 'DFA',
        alphabet: {'a', 'b'},
        states: [
          StateEntity(
            id: 'q0',
            name: 'q0',
            x: 10,
            y: 20,
            isInitial: false,
            isFinal: false,
          ),
          StateEntity(
            id: 'q1',
            name: 'q1',
            x: 30,
            y: 40,
            isInitial: false,
            isFinal: true,
          ),
        ],
        transitions: {
          'q0|a': ['q1'],
          'q1|b': ['q0'],
        },
        initialId: 'q0',
        nextId: 2,
        type: AutomatonType.dfa,
      );

      final fsa = AutomatonEntityMapper.toFsa(entity);

      expect(fsa.id, entity.id);
      expect(fsa.initialState?.id, 'q0');
      expect(fsa.initialState?.isInitial, isTrue);
      expect(fsa.acceptingStates.map((state) => state.id), {'q1'});
      expect(fsa.fsaTransitions.map((transition) => transition.id), {
        't1',
        't2',
      });

      final roundTrip = AutomatonEntityMapper.fromFsa(fsa);

      expect(roundTrip.type, AutomatonType.dfa);
      expect(roundTrip.transitions, entity.transitions);
      expect(roundTrip.initialId, entity.initialId);
      expect(roundTrip.nextId, entity.states.length);
    });

    test('infers lambda and nondeterministic FSA transitions consistently', () {
      final q0 = core_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final q1 = core_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
        isInitial: false,
        isAccepting: true,
      );
      final q2 = core_state.State(
        id: 'q2',
        label: 'q2',
        position: Vector2(200, 0),
        isInitial: false,
        isAccepting: true,
      );
      final fsa = FSA(
        id: 'nfa',
        name: 'NFA',
        states: {q0, q1, q2},
        transitions: {
          FSATransition(
            id: 'e',
            fromState: q0,
            toState: q1,
            label: 'λ',
            inputSymbols: const {},
            lambdaSymbol: 'λ',
          ),
          FSATransition(
            id: 'a1',
            fromState: q0,
            toState: q1,
            label: 'a',
            inputSymbols: {'a'},
          ),
          FSATransition(
            id: 'a2',
            fromState: q0,
            toState: q2,
            label: 'a',
            inputSymbols: {'a'},
          ),
        },
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {q1, q2},
        created: DateTime(2026),
        modified: DateTime(2026),
        bounds: const math.Rectangle<double>(0, 0, 800, 600),
      );

      final entity = AutomatonEntityMapper.fromFsa(fsa);

      expect(entity.type, AutomatonType.nfaLambda);
      expect(entity.transitions['q0|ε'], ['q1']);
      expect(entity.transitions['q0|a'], ['q1', 'q2']);
    });

    test('can skip or throw for transitions that reference missing endpoints',
        () {
      const entity = AutomatonEntity(
        id: 'broken',
        name: 'Broken',
        alphabet: {'a'},
        states: [
          StateEntity(
            id: 'q0',
            name: 'q0',
            x: 0,
            y: 0,
            isInitial: true,
            isFinal: false,
          ),
        ],
        transitions: {
          'q0|a': ['missing'],
          'missing|a': ['q0'],
        },
        initialId: 'q0',
        nextId: 1,
        type: AutomatonType.dfa,
      );

      final skipped = AutomatonEntityMapper.toFsa(entity);
      expect(skipped.fsaTransitions, isEmpty);

      expect(
        () => AutomatonEntityMapper.toFsa(
          entity,
          missingEndpointPolicy: MissingTransitionEndpointPolicy.throwError,
        ),
        throwsStateError,
      );
    });

    test('deduplicates and sorts destinations when requested', () {
      final q0 = core_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final q1 = core_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
        isInitial: false,
        isAccepting: true,
      );
      final q2 = core_state.State(
        id: 'q2',
        label: 'q2',
        position: Vector2(200, 0),
        isInitial: false,
        isAccepting: true,
      );

      final fsa = FSA(
        id: 'ordered',
        name: 'Ordered',
        states: {q0, q1, q2},
        transitions: {
          FSATransition(
            id: 'to-q2',
            fromState: q0,
            toState: q2,
            label: 'a',
            inputSymbols: {'a'},
          ),
          FSATransition(
            id: 'to-q1',
            fromState: q0,
            toState: q1,
            label: 'a',
            inputSymbols: {'a'},
          ),
          FSATransition(
            id: 'to-q2-again',
            fromState: q0,
            toState: q2,
            label: 'a',
            inputSymbols: {'a'},
          ),
        },
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {q1, q2},
        created: DateTime(2026),
        modified: DateTime(2026),
        bounds: const math.Rectangle<double>(0, 0, 800, 600),
      );

      final entity = AutomatonEntityMapper.fromFsa(
        fsa,
        deduplicateDestinations: true,
        sortDestinations: true,
      );

      expect(entity.transitions['q0|a'], ['q1', 'q2']);
    });
  });
}
