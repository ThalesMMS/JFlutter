//
//  fa_algorithms_test.dart
//  JFlutter
//
//  Casos específicos que exercitam algoritmos utilitários de autômatos finitos como conversão AFN→AFD, minimização de Hopcroft e operações de linguagem.
//  Os testes montam autômatos pequenos para confirmar fechos epsilon, equivalência de linguagem e composição via complemento, união e interseção.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:jflutter/core/algorithms/automata/fa_algorithms.dart' as fa;
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';

void main() {
  group('FA algorithms (NFA→DFA, Hopcroft, language ops)', () {
    test('NFA→DFA converts epsilon-closures and preserves language', () {
      // Build tiny NFA: q0 -ε-> q1, q1 -a-> q2 (accepting)
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(20, 0),
        isInitial: false,
        isAccepting: false,
      );
      final q2 = State(
        id: 'q2',
        label: 'q2',
        position: Vector2(40, 0),
        isInitial: false,
        isAccepting: true,
      );
      final t01 = FSATransition.epsilon(id: 't01', fromState: q0, toState: q1);
      final t12 = FSATransition.deterministic(
        id: 't12',
        fromState: q1,
        toState: q2,
        symbol: 'a',
      );
      final nfa = FSA(
        id: 'n1',
        name: 'nfa',
        states: {q0, q1, q2},
        transitions: {t01, t12},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {q2},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 800, 600),
      );

      final dfaRes = fa.FAAlgorithms.nfaToDfa(nfa);
      expect(dfaRes.isSuccess, isTrue);
      final dfa = dfaRes.data!;
      // q0 should accept "a" due to ε to q1 then a to q2
      final acceptsA = dfa
          .getTransitionsFromStateOnSymbol(dfa.initialState!, 'a')
          .isNotEmpty;
      expect(acceptsA, isTrue);
    });

    test('Hopcroft minimization yields canonical minimal DFA', () {
      // Build DFA with two equivalent accepting states to be merged
      final s0 = State(
        id: 's0',
        label: 's0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final s1 = State(
        id: 's1',
        label: 's1',
        position: Vector2(20, 0),
        isInitial: false,
        isAccepting: true,
      );
      final s2 = State(
        id: 's2',
        label: 's2',
        position: Vector2(40, 0),
        isInitial: false,
        isAccepting: true,
      );
      final t01 = FSATransition.deterministic(
        id: 't01',
        fromState: s0,
        toState: s1,
        symbol: 'a',
      );
      final t02 = FSATransition.deterministic(
        id: 't02',
        fromState: s0,
        toState: s2,
        symbol: 'b',
      );
      final t11 = FSATransition.deterministic(
        id: 't11',
        fromState: s1,
        toState: s1,
        symbol: 'a',
      );
      final t12 = FSATransition.deterministic(
        id: 't12',
        fromState: s1,
        toState: s2,
        symbol: 'b',
      );
      final t21 = FSATransition.deterministic(
        id: 't21',
        fromState: s2,
        toState: s1,
        symbol: 'a',
      );
      final t22 = FSATransition.deterministic(
        id: 't22',
        fromState: s2,
        toState: s2,
        symbol: 'b',
      );
      final dfa = FSA(
        id: 'd1',
        name: 'dfa',
        states: {s0, s1, s2},
        transitions: {t01, t02, t11, t12, t21, t22},
        alphabet: {'a', 'b'},
        initialState: s0,
        acceptingStates: {s1, s2},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 800, 600),
      );

      final minimized = fa.FAAlgorithms.minimizeDfa(dfa);
      expect(minimized.isSuccess, isTrue);
      final md = minimized.data!;
      expect(md.stateCount < dfa.stateCount, isTrue);
    });

    test('Property diagnostics: emptiness, finiteness, equivalence', () {
      // Empty language DFA: initial non-accepting, self-loop
      final p0 = State(
        id: 'p0',
        label: 'p0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final lp = FSATransition.deterministic(
        id: 'lp',
        fromState: p0,
        toState: p0,
        symbol: 'a',
      );
      final emptyDfa = FSA(
        id: 'e',
        name: 'empty',
        states: {p0},
        transitions: {lp},
        alphabet: {'a'},
        initialState: p0,
        acceptingStates: {},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 800, 600),
      );
      expect(fa.FAAlgorithms.isEmpty(emptyDfa), isTrue);
      expect(fa.FAAlgorithms.isFinite(emptyDfa), isTrue);

      // Equivalence: two identical single-transition DFAs
      final a0 = State(
        id: 'a0',
        label: 'a0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final a1 = State(
        id: 'a1',
        label: 'a1',
        position: Vector2(20, 0),
        isInitial: false,
        isAccepting: true,
      );
      final at = FSATransition.deterministic(
        id: 'at',
        fromState: a0,
        toState: a1,
        symbol: 'a',
      );
      final dfa1 = FSA(
        id: 'a',
        name: 'dfa1',
        states: {a0, a1},
        transitions: {at},
        alphabet: {'a'},
        initialState: a0,
        acceptingStates: {a1},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 800, 600),
      );
      final b0 = a0.copyWith(isInitial: true, isAccepting: false);
      final b1 = a1.copyWith(isInitial: false, isAccepting: true);
      final bt = at.copyWith(fromState: b0, toState: b1);
      final dfa2 = dfa1.copyWith(
        id: 'b',
        states: {b0, b1},
        transitions: {bt},
        initialState: b0,
        acceptingStates: {b1},
      );
      expect(fa.FAAlgorithms.areEquivalent(dfa1, dfa2), isTrue);
    });

    test('NFA→DFA conversion reports guard exhaustion as failure', () {
      const largeStateCount = 1001;
      final states = List.generate(largeStateCount, (index) {
        return State(
          id: 'q$index',
          label: 'q$index',
          position: Vector2(index * 5.0, 0.0),
          isInitial: index == 0,
          isAccepting: index == largeStateCount - 1,
        );
      });

      final transitions = <FSATransition>{
        for (var i = 0; i < largeStateCount - 1; i++)
          FSATransition.deterministic(
            id: 't_${states[i].id}_${states[i + 1].id}',
            fromState: states[i],
            toState: states[i + 1],
            symbol: 'a',
          ),
      };

      final nfa = FSA(
        id: 'large_nfa',
        name: 'Large NFA',
        states: states.toSet(),
        transitions: transitions,
        alphabet: {'a'},
        initialState: states.first,
        acceptingStates: {states.last},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 800, 600),
      );

      final result = fa.FAAlgorithms.nfaToDfa(nfa);
      expect(result.isFailure, isTrue);
      expect(result.error, contains('Exceeded maximum number of DFA states'));
    });
  });
}
