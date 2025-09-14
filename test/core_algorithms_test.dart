import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/automaton.dart';
import 'package:jflutter/core/algorithms.dart' as algo;

void main() {
  test('epsilon-closure simple', () {
    final a = Automaton(
      alphabet: {'λ', 'a'},
      states: [
        StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
        StateNode(id: 'q1', name: 'q1', x: 0, y: 0, isInitial: false, isFinal: true),
      ],
      transitions: {
        'q0|λ': ['q1'],
      },
      initialId: 'q0',
      nextId: 2,
    );
    final cl = algo.epsilonClosure(a, {'q0'});
    expect(cl.contains('q0'), true);
    expect(cl.contains('q1'), true);
  });

  test('nfa-lambda to nfa removes λ', () {
    final a = Automaton(
      alphabet: {'λ', 'a'},
      states: [
        StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
        StateNode(id: 'q1', name: 'q1', x: 0, y: 0, isInitial: false, isFinal: true),
      ],
      transitions: {
        'q0|λ': ['q1'],
        'q1|a': ['q1'],
      },
      initialId: 'q0',
      nextId: 2,
    );
    final b = algo.nfaLambdaToNfa(a);
    expect(b.transitions.keys.where((k) => k.endsWith('|λ')).isEmpty, true);
  });

  test('nfa to dfa yields deterministic automaton', () {
    final nfa = Automaton(
      alphabet: {'a', 'b'},
      states: [
        StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
        StateNode(id: 'q1', name: 'q1', x: 0, y: 0, isInitial: false, isFinal: true),
      ],
      transitions: {
        'q0|a': ['q0', 'q1'],
        'q0|b': ['q0'],
        'q1|a': ['q1'],
        'q1|b': ['q1'],
      },
      initialId: 'q0',
      nextId: 2,
    );
    final dfa = algo.nfaToDfa(nfa);
    expect(dfa.isDfa, true);
    expect(dfa.transitions.keys.where((k) => k.endsWith('|λ')).isEmpty, true);
  });
}

