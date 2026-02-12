import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/automaton_simulator.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

/// DFA: q0 --a--> q1 --b--> q2(accept)
FSA _simpleDFA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
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
    isAccepting: true,
  );
  return FSA(
    id: 'dfa1',
    name: 'Simple DFA',
    states: {q0, q1, q2},
    transitions: {
      FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: {'a'},
        label: 'a',
      ),
      FSATransition(
        id: 't1',
        fromState: q1,
        toState: q2,
        inputSymbols: {'b'},
        label: 'b',
      ),
    },
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q2},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

/// NFA: q0 --a--> q1, q0 --a--> q2(accept)
FSA _simpleNFA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
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
    position: Vector2(100, 100),
    isAccepting: true,
  );
  return FSA(
    id: 'nfa1',
    name: 'Simple NFA',
    states: {q0, q1, q2},
    transitions: {
      FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: {'a'},
        label: 'a',
      ),
      FSATransition(
        id: 't1',
        fromState: q0,
        toState: q2,
        inputSymbols: {'a'},
        label: 'a',
      ),
    },
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q2},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

void main() {
  group('DFA simulator step recording', () {
    test('Step records destination state, not source', () async {
      final dfa = _simpleDFA();
      final result = await AutomatonSimulator.simulateDFA(
        dfa,
        'ab',
        stepByStep: true,
      );
      expect(result.isSuccess, true);
      final steps = result.data!.steps;

      // steps[0] = initial (q0), steps[1] = after 'a', steps[2] = after 'b', steps[3] = final
      expect(steps.length, greaterThanOrEqualTo(3));

      // After consuming 'a', current state should be q1 (destination)
      final stepAfterA = steps[1];
      expect(stepAfterA.currentState, 'q1');

      // After consuming 'b', current state should be q2 (destination)
      final stepAfterB = steps[2];
      expect(stepAfterB.currentState, 'q2');
    });
  });

  group('NFA simulator step recording', () {
    test('Step records destination states, not source', () async {
      final nfa = _simpleNFA();
      final result = await AutomatonSimulator.simulateNFA(
        nfa,
        'a',
        stepByStep: true,
      );
      expect(result.isSuccess, true);
      final steps = result.data!.steps;

      // After consuming 'a', current state should be the destination set {q1,q2}
      // (not the source q0)
      final intermediateSteps =
          steps.where((s) => s.stepNumber > 0).toList();
      expect(intermediateSteps, isNotEmpty);
      for (final step in intermediateSteps) {
        expect(step.currentState, isNot('q0'));
      }
    });
  });
}
