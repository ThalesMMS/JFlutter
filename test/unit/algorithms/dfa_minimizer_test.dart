import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/dfa_minimizer.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

State _buildState(
  String id,
  double x,
  double y, {
  bool isInitial = false,
  bool isAccepting = false,
}) {
  return State(
    id: id,
    label: id,
    position: Vector2(x, y),
    isInitial: isInitial,
    isAccepting: isAccepting,
  );
}

FSA _buildDfa({
  required Set<State> states,
  required Set<FSATransition> transitions,
  required State initialState,
  required Set<State> acceptingStates,
}) {
  return FSA(
    id: 'dfa_test',
    name: 'dfa_test',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: initialState,
    acceptingStates: acceptingStates,
    created: DateTime.utc(2024, 1, 1),
    modified: DateTime.utc(2024, 1, 1),
    bounds: math.Rectangle<double>(0, 0, 300, 300),
  );
}

FSATransition _transition(
  String id,
  State from,
  State to,
  String symbol,
) {
  return FSATransition(
    id: id,
    fromState: from,
    toState: to,
    label: symbol,
    inputSymbols: {symbol},
  );
}

void main() {
  group('DFAMinimizer with queue-backed worklist', () {
    test('collapses duplicated parity classes into two states', () {
      final s0 = _buildState('s0', 0, 0, isInitial: true, isAccepting: true);
      final s1 = _buildState('s1', 10, 0);
      final s2 = _buildState('s2', 20, 0, isAccepting: true);
      final s3 = _buildState('s3', 30, 0);
      final s4 = _buildState('s4', 40, 0, isAccepting: true);
      final s5 = _buildState('s5', 50, 0);

      final states = {s0, s1, s2, s3, s4, s5};

      final transitions = <FSATransition>{
        _transition('t_s0_0', s0, s2, '0'),
        _transition('t_s0_1', s0, s1, '1'),
        _transition('t_s1_0', s1, s3, '0'),
        _transition('t_s1_1', s1, s2, '1'),
        _transition('t_s2_0', s2, s4, '0'),
        _transition('t_s2_1', s2, s3, '1'),
        _transition('t_s3_0', s3, s5, '0'),
        _transition('t_s3_1', s3, s4, '1'),
        _transition('t_s4_0', s4, s0, '0'),
        _transition('t_s4_1', s4, s5, '1'),
        _transition('t_s5_0', s5, s1, '0'),
        _transition('t_s5_1', s5, s0, '1'),
      };

      final dfa = _buildDfa(
        states: states,
        transitions: transitions,
        initialState: s0,
        acceptingStates: {s0, s2, s4},
      );

      final result = DFAMinimizer.minimize(dfa);

      expect(result.isSuccess, isTrue);
      final minimized = result.data!;

      expect(minimized.stateCount, 2);
      expect(minimized.acceptingStateCount, 1);
      expect(minimized.transitionCount, 4);

      for (final state in minimized.states) {
        final outgoing = minimized.fsaTransitions
            .where((transition) => transition.fromState == state)
            .toList();
        expect(outgoing.length, 2, reason: 'Each state should remain deterministic');
      }

      expect(
        minimized.states.any((state) => state.label.contains('{s0,s2,s4}')),
        isTrue,
      );
    });

    test('reduces multi-class remainder DFA to three canonical states', () {
      final r0a = _buildState('r0a', 0, 0, isInitial: true, isAccepting: true);
      final r0b = _buildState('r0b', 10, 0, isAccepting: true);
      final r0c = _buildState('r0c', 20, 0, isAccepting: true);
      final r1a = _buildState('r1a', 0, 10);
      final r1b = _buildState('r1b', 10, 10);
      final r1c = _buildState('r1c', 20, 10);
      final r2a = _buildState('r2a', 0, 20);
      final r2b = _buildState('r2b', 10, 20);
      final r2c = _buildState('r2c', 20, 20);

      final states = {r0a, r0b, r0c, r1a, r1b, r1c, r2a, r2b, r2c};

      final transitions = <FSATransition>{
        _transition('t_r0a_0', r0a, r0b, '0'),
        _transition('t_r0a_1', r0a, r1a, '1'),
        _transition('t_r0b_0', r0b, r0c, '0'),
        _transition('t_r0b_1', r0b, r1b, '1'),
        _transition('t_r0c_0', r0c, r0a, '0'),
        _transition('t_r0c_1', r0c, r1c, '1'),
        _transition('t_r1a_0', r1a, r2a, '0'),
        _transition('t_r1a_1', r1a, r0a, '1'),
        _transition('t_r1b_0', r1b, r2b, '0'),
        _transition('t_r1b_1', r1b, r0b, '1'),
        _transition('t_r1c_0', r1c, r2c, '0'),
        _transition('t_r1c_1', r1c, r0c, '1'),
        _transition('t_r2a_0', r2a, r1a, '0'),
        _transition('t_r2a_1', r2a, r2b, '1'),
        _transition('t_r2b_0', r2b, r1b, '0'),
        _transition('t_r2b_1', r2b, r2c, '1'),
        _transition('t_r2c_0', r2c, r1c, '0'),
        _transition('t_r2c_1', r2c, r2a, '1'),
      };

      final dfa = _buildDfa(
        states: states,
        transitions: transitions,
        initialState: r0a,
        acceptingStates: {r0a, r0b, r0c},
      );

      final result = DFAMinimizer.minimize(dfa);

      expect(result.isSuccess, isTrue);
      final minimized = result.data!;

      expect(minimized.stateCount, 3);
      expect(minimized.acceptingStateCount, 1);
      expect(minimized.transitionCount, 6);

      final labels = minimized.states.map((state) => state.label).toSet();
      expect(labels.length, 3);
      expect(labels.any((label) => label.contains('r0')), isTrue);
      expect(labels.any((label) => label.contains('r1')), isTrue);
      expect(labels.any((label) => label.contains('r2')), isTrue);
    });
  });
}
