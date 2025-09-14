import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/automaton.dart';
import 'package:jflutter/core/algorithms.dart' as algo;

void main() {
  group('NFA Reversal', () {
    test('reverses simple NFA', () {
      // Create NFA that accepts strings ending with 'a'
      // q0 --a--> q1 (final)
      // q0 --b--> q0
      // q1 --a--> q1
      // q1 --b--> q0
      final nfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 100, y: 100, isInitial: true, isFinal: false),
          StateNode(id: 'q1', name: 'q1', x: 200, y: 100, isInitial: false, isFinal: true),
        ],
        transitions: {
          'q0|a': ['q1'],
          'q0|b': ['q0'],
          'q1|a': ['q1'],
          'q1|b': ['q0'],
        },
        initialId: 'q0',
        nextId: 2,
      );

      final reversed = algo.nfaReverse(nfa);

      // After reversal: accepts strings starting with 'a'
      // Original final (q1) becomes initial
      // Original initial (q0) becomes final
      expect(reversed.states.any((s) => s.id == 'q0' && s.isFinal), isTrue);
      expect(reversed.states.any((s) => s.id == 'q1' && s.isInitial), isTrue);

      // Check reversed transitions
      expect(reversed.transitions['q1|a'], contains('q0')); // reversed from q0 --a--> q1
      expect(reversed.transitions['q0|b'], contains('q0')); // reversed from q0 --b--> q0
      expect(reversed.transitions['q1|a'], contains('q1')); // reversed from q1 --a--> q1
      expect(reversed.transitions['q0|b'], contains('q1')); // reversed from q1 --b--> q0
    });

    test('handles multiple final states', () {
      // NFA with multiple final states
      final nfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 100, y: 100, isInitial: true, isFinal: false),
          StateNode(id: 'q1', name: 'q1', x: 200, y: 100, isInitial: false, isFinal: true),
          StateNode(id: 'q2', name: 'q2', x: 300, y: 100, isInitial: false, isFinal: true),
        ],
        transitions: {
          'q0|a': ['q1'],
          'q0|b': ['q2'],
          'q1|a': ['q2'],
          'q2|b': ['q1'],
        },
        initialId: 'q0',
        nextId: 3,
      );

      final reversed = algo.nfaReverse(nfa);

      // Should create a new initial state with λ-transitions to original finals
      expect(reversed.initialId, equals('__init'));
      expect(reversed.states.any((s) => s.id == '__init' && s.isInitial), isTrue);

      // Check λ-transitions from new initial to original finals
      expect(reversed.transitions['__init|λ'], isNotNull);
      expect(reversed.transitions['__init|λ'], containsAll(['q1', 'q2']));

      // Original initial becomes final
      expect(reversed.states.any((s) => s.id == 'q0' && s.isFinal), isTrue);
    });

    test('preserves language reversal property', () {
      // Create NFA that accepts 'ab'
      final nfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 100, y: 100, isInitial: true, isFinal: false),
          StateNode(id: 'q1', name: 'q1', x: 200, y: 100, isInitial: false, isFinal: false),
          StateNode(id: 'q2', name: 'q2', x: 300, y: 100, isInitial: false, isFinal: true),
        ],
        transitions: {
          'q0|a': ['q1'],
          'q1|b': ['q2'],
        },
        initialId: 'q0',
        nextId: 3,
      );

      final reversed = algo.nfaReverse(nfa);

      // Reversed should accept 'ba'
      // Check that q2 is now initial and q0 is final
      expect(reversed.states.any((s) => s.id == 'q2' && s.isInitial), isTrue);
      expect(reversed.states.any((s) => s.id == 'q0' && s.isFinal), isTrue);

      // Check reversed transitions
      expect(reversed.transitions['q2|b'], contains('q1')); // reversed from q1 --b--> q2
      expect(reversed.transitions['q1|a'], contains('q0')); // reversed from q0 --a--> q1
    });

    test('handles empty automaton', () {
      // Automaton with no final states
      final nfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 100, y: 100, isInitial: true, isFinal: false),
        ],
        transitions: {
          'q0|a': ['q0'],
        },
        initialId: 'q0',
        nextId: 1,
      );

      final reversed = algo.nfaReverse(nfa);

      // Should return empty automaton when no final states
      expect(reversed.states, isEmpty);
      expect(reversed.initialId, isNull);
    });

    test('handles self-loops correctly', () {
      // NFA with self-loops
      final nfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 100, y: 100, isInitial: true, isFinal: false),
          StateNode(id: 'q1', name: 'q1', x: 200, y: 100, isInitial: false, isFinal: true),
        ],
        transitions: {
          'q0|a': ['q1'],
          'q0|b': ['q0'], // self-loop
          'q1|a': ['q1'], // self-loop
        },
        initialId: 'q0',
        nextId: 2,
      );

      final reversed = algo.nfaReverse(nfa);

      // Check that self-loops are preserved
      expect(reversed.transitions['q0|b'], contains('q0')); // self-loop preserved
      expect(reversed.transitions['q1|a'], contains('q1')); // self-loop preserved
    });

    test('handles NFA with lambda transitions', () {
      // NFA with λ-transitions
      final nfa = Automaton(
        alphabet: {'a', 'b', 'λ'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 100, y: 100, isInitial: true, isFinal: false),
          StateNode(id: 'q1', name: 'q1', x: 200, y: 100, isInitial: false, isFinal: false),
          StateNode(id: 'q2', name: 'q2', x: 300, y: 100, isInitial: false, isFinal: true),
        ],
        transitions: {
          'q0|λ': ['q1'],
          'q1|a': ['q2'],
        },
        initialId: 'q0',
        nextId: 3,
      );

      final reversed = algo.nfaReverse(nfa);

      // Check that λ-transitions are reversed correctly
      expect(reversed.transitions['q1|λ'], contains('q0')); // reversed from q0 --λ--> q1
      expect(reversed.transitions['q2|a'], contains('q1')); // reversed from q1 --a--> q2
    });
  });
}