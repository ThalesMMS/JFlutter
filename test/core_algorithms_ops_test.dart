import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/automaton.dart';
import 'package:jflutter/core/algorithms.dart' as algo;

Automaton dfaEndsWithA() {
  return Automaton(
    alphabet: {'a', 'b'},
    states: [
      StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
      StateNode(id: 'q1', name: 'q1', x: 0, y: 0, isInitial: false, isFinal: true),
    ],
    transitions: {
      'q0|a': ['q1'], 'q0|b': ['q0'],
      'q1|a': ['q1'], 'q1|b': ['q0'],
    },
    initialId: 'q0',
    nextId: 2,
  );
}

Automaton dfaHasB() {
  return Automaton(
    alphabet: {'a', 'b'},
    states: [
      StateNode(id: 's0', name: 's0', x: 0, y: 0, isInitial: true, isFinal: false),
      StateNode(id: 's1', name: 's1', x: 0, y: 0, isInitial: false, isFinal: true),
    ],
    transitions: {
      's0|a': ['s0'], 's0|b': ['s1'],
      's1|a': ['s1'], 's1|b': ['s1'],
    },
    initialId: 's0',
    nextId: 2,
  );
}

void main() {
  test('completeDfa adds trap state when missing', () {
    final a = Automaton(
      alphabet: {'a', 'b'},
      states: [StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false)],
      transitions: {'q0|a': ['q0']},
      initialId: 'q0',
      nextId: 1,
    );
    final c = algo.completeDfa(a);
    expect(c.stateIds.contains('⊥'), true);
    expect(c.transitions['q0|b']?.first, '⊥');
    expect(c.transitions['⊥|a']?.first, '⊥');
    expect(c.transitions['⊥|b']?.first, '⊥');
  });

  test('complementDfa flips finals', () {
    final a = dfaEndsWithA();
    final b = algo.complementDfa(a);
    // 'a' accepted by a, rejected by b
    expect(algo.runWord(a, 'a').accepted, true);
    expect(algo.runWord(b, 'a').accepted, false);
    // 'bb' rejected by a, accepted by b
    expect(algo.runWord(a, 'bb').accepted, false);
    expect(algo.runWord(b, 'bb').accepted, true);
  });

  test('product/union/intersection/difference basic behavior', () {
    final A = dfaEndsWithA();
    final B = dfaHasB();
    final U = algo.unionDfa(A, B);
    final I = algo.intersectionDfa(A, B);
    final D = algo.differenceDfa(A, B); // A \ B
    // Union accepts strings ending with 'a' or with at least one 'b'
    expect(algo.runWord(U, 'a').accepted, true);
    expect(algo.runWord(U, 'bbb').accepted, true);
    expect(algo.runWord(U, '').accepted, false);
    // Intersection: ends with 'a' and has at least one 'b' (e.g., "ba")
    expect(algo.runWord(I, 'ba').accepted, true);
    expect(algo.runWord(I, 'aa').accepted, false);
    // Difference A\B: ends with 'a' and has no 'b'
    expect(algo.runWord(D, 'a').accepted, true);
    expect(algo.runWord(D, 'ba').accepted, false);
  });

  test('equivalentDfas detects equivalence', () {
    // Build another DFA for "ends with a" with different state names
    final X = Automaton(
      alphabet: {'a', 'b'},
      states: [
        StateNode(id: 's', name: 's', x: 0, y: 0, isInitial: true, isFinal: false),
        StateNode(id: 't', name: 't', x: 0, y: 0, isInitial: false, isFinal: true),
      ],
      transitions: {
        's|a': ['t'], 's|b': ['s'],
        't|a': ['t'], 't|b': ['s'],
      },
      initialId: 's',
      nextId: 2,
    );
    expect(algo.equivalentDfas(dfaEndsWithA(), X), true);
  });

  test('prefixClosure accepts all prefixes (ends-with-a → Σ*)', () {
    final A = dfaEndsWithA();
    final P = algo.prefixClosureDfa(A);
    expect(algo.runWord(P, '').accepted, true);
    expect(algo.runWord(P, 'bbb').accepted, true);
  });

  test('suffixClosure grows language (has-b → Σ*)', () {
    final B = dfaHasB();
    final S = algo.suffixClosureDfa(B);
    expect(algo.runWord(S, 'aaa').accepted, true);
  });

  test('dfaToRegex returns a non-empty expression', () {
    final A = dfaEndsWithA();
    final r = algo.dfaToRegex(A, allowLambda: true);
    expect(r.isNotEmpty, true);
    final okTokens = RegExp(r'^[A-Za-z0-9 ()∪*]+$');
    expect(okTokens.hasMatch(r), true);
  });
}

