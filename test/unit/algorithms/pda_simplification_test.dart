import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/pda_simulator.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('PDASimulator.simplify', () {
    test('removes unreachable and redundant states and transitions', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
      );
      final q2 = State(
        id: 'q2',
        label: 'q2',
        position: Vector2(200, 0),
      );
      final qDead = State(
        id: 'qdead',
        label: 'qdead',
        position: Vector2(300, 0),
      );
      final qUnreachable = State(
        id: 'qu',
        label: 'qu',
        position: Vector2(400, 0),
      );
      final qf = State(
        id: 'qf',
        label: 'qf',
        position: Vector2(500, 0),
        isAccepting: true,
      );

      final transitions = <PDATransition>{
        PDATransition(
          id: 't0',
          fromState: q0,
          toState: q1,
          label: 'λ',
          inputSymbol: '',
          popSymbol: 'Z',
          pushSymbol: 'Z',
          isLambdaInput: true,
        ),
        PDATransition(
          id: 't1',
          fromState: q0,
          toState: q2,
          label: 'λ',
          inputSymbol: '',
          popSymbol: 'Z',
          pushSymbol: 'Z',
          isLambdaInput: true,
        ),
        PDATransition(
          id: 't2',
          fromState: q1,
          toState: qf,
          label: 'a/Z→Z',
          inputSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: 'Z',
        ),
        PDATransition(
          id: 't3',
          fromState: q2,
          toState: qf,
          label: 'a/Z→Z',
          inputSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: 'Z',
        ),
        PDATransition(
          id: 't4',
          fromState: q0,
          toState: qDead,
          label: 'b/Z→Z',
          inputSymbol: 'b',
          popSymbol: 'Z',
          pushSymbol: 'Z',
        ),
        PDATransition(
          id: 't5',
          fromState: qDead,
          toState: qDead,
          label: 'b/Z→Z',
          inputSymbol: 'b',
          popSymbol: 'Z',
          pushSymbol: 'Z',
        ),
      };

      final now = DateTime.now();
      final pda = PDA(
        id: 'p1',
        name: 'test',
        states: {q0, q1, q2, qDead, qUnreachable, qf},
        transitions: transitions.map((t) => t).toSet(),
        alphabet: {'a', 'b'},
        initialState: q0,
        acceptingStates: {qf},
        created: now,
        modified: now,
        bounds: const math.Rectangle(0, 0, 600, 400),
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
      );

      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, isTrue);

      final summary = result.data!;
      final minimized = summary.minimizedPda;

      expect(minimized.states.length, 3);
      expect(minimized.pdaTransitions.length, 2);

      final removedStateIds = summary.removedStates.map((state) => state.id).toSet();
      expect(removedStateIds, containsAll({'q2', 'qdead', 'qu'}));

      expect(summary.mergeGroups.length, greaterThanOrEqualTo(1));
      final mergeGroup = summary.mergeGroups.firstWhere(
        (group) => group.representative.id == 'q1',
      );
      expect(mergeGroup.mergedStates.map((state) => state.id).toSet(), contains('q2'));

      expect(summary.removedTransitionIds.length, greaterThanOrEqualTo(2));
      expect(minimized.states.any((state) => state.id == 'qdead'), isFalse);
    });

    test('fails when no productive path to an accepting state exists', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
      );
      final qf = State(
        id: 'qf',
        label: 'qf',
        position: Vector2(200, 0),
        isAccepting: true,
      );

      final now = DateTime.now();
      final pda = PDA(
        id: 'p2',
        name: 'disconnected',
        states: {q0, q1, qf},
        transitions: {
          PDATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            label: 'a/Z→Z',
            inputSymbol: 'a',
            popSymbol: 'Z',
            pushSymbol: 'Z',
          ),
        },
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {qf},
        created: now,
        modified: now,
        bounds: const math.Rectangle(0, 0, 400, 300),
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
      );

      final result = PDASimulator.simplify(pda);
      expect(result.isFailure, isTrue);
      expect(
        result.error,
        contains('Initial state cannot reach any accepting configuration'),
      );
    });
  });
}
