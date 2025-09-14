import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/automaton.dart';
import 'package:jflutter/core/algorithms.dart';
import 'package:jflutter/core/dfa_algorithms.dart';
import 'package:matcher/matcher.dart';

void main() {
  group('DFA Minimization', () {
    test('Minimal DFA remains unchanged', () {
      // A minimal DFA that accepts strings with an even number of 'a's
      final dfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: true),
          StateNode(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: false),
        ],
        transitions: {
          'q0|a': ['q1'],
          'q0|b': ['q0'],
          'q1|a': ['q0'],
          'q1|b': ['q1'],
        },
        initialId: 'q0',
        nextId: 2,
      );

      final result = minimizeDfaIfValid(dfa);
      expect(result, isNotNull);
      
      // The DFA is already minimal, so it should be unchanged
      expect(result!.minimized.states.length, equals(2));
      expect(result.minimized.transitions.length, equals(4));
    });

    test('DFA minimization visualization steps', () {
      // Track the steps during minimization
      final steps = <String>[];
      
      // A non-minimal DFA that accepts strings with an even number of 'a's
      final dfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: true),
          StateNode(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: false),
          // These states are equivalent to q0 and q1 respectively
          StateNode(id: 'q2', name: 'q2', x: 200, y: 0, isInitial: false, isFinal: true),
          StateNode(id: 'q3', name: 'q3', x: 300, y: 0, isInitial: false, isFinal: false),
        ],
        transitions: {
          'q0|a': ['q1'], 'q0|b': ['q0'],
          'q1|a': ['q0'], 'q1|b': ['q1'],
          'q2|a': ['q3'], 'q2|b': ['q2'],
          'q3|a': ['q2'], 'q3|b': ['q3'],
        },
        initialId: 'q0',
        nextId: 4,
      );
      
      // Run minimization with step tracking
      final minimized = minimizeDfa(dfa, onStep: (title, description, {automaton, partitions}) {
        steps.add(title);
        
        // Verify the step has the expected data
        if (title == 'AFD Original') {
          expect(automaton, isNotNull);
          expect(automaton?.states.length, equals(4));
        } else if (title == 'Partições Iniciais') {
          expect(partitions, isNotNull);
          expect(partitions?.length, equals(2)); // Final and non-final partitions
        } else if (title == 'Construindo AFD minimizado') {
          // No specific assertions for this step
        } else if (title == 'AFD Minimizado') {
          expect(automaton, isNotNull);
          expect(automaton?.states.length, equals(2)); // Should be minimized to 2 states
        }
      });
      
      // Verify we went through all expected steps
      expect(steps, containsAllInOrder([
        'AFD Original',
        'Completando AFD',
        'Removendo estados inalcançáveis',
        'Inicializando partições',
        'Partições Iniciais',
        'Construindo AFD minimizado',
        'AFD Minimizado',
      ]));
      
      // Verify the final result is correct
      expect(minimized.states.length, equals(2));
      expect(minimized.transitions.length, equals(4));
    });

    test('Minimize non-minimal DFA', () {
      // A non-minimal DFA that accepts strings with an even number of 'a's
      final dfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: true),
          StateNode(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: false),
          // These states are equivalent to q0 and q1 respectively
          StateNode(id: 'q2', name: 'q2', x: 200, y: 0, isInitial: false, isFinal: true),
          StateNode(id: 'q3', name: 'q3', x: 300, y: 0, isInitial: false, isFinal: false),
        ],
        transitions: {
          'q0|a': ['q1'], 'q0|b': ['q0'],
          'q1|a': ['q0'], 'q1|b': ['q1'],
          'q2|a': ['q3'], 'q2|b': ['q2'],
          'q3|a': ['q2'], 'q3|b': ['q3'],
        },
        initialId: 'q0',
        nextId: 4,
      );

      final result = minimizeDfaIfValid(dfa);
      expect(result, isNotNull);
      
      // The minimized DFA should have only 2 states
      expect(result!.minimized.states.length, equals(2));
      
      // It should have 4 transitions (2 states × 2 symbols)
      expect(result.minimized.transitions.length, equals(4));
    });

    test('Minimize DFA with unreachable states', () {
      // A DFA with unreachable states
      final dfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: true),
          StateNode(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: false),
          // These states are unreachable
          StateNode(id: 'q2', name: 'q2', x: 200, y: 0, isInitial: false, isFinal: true),
          StateNode(id: 'q3', name: 'q3', x: 300, y: 0, isInitial: false, isFinal: false),
        ],
        transitions: {
          'q0|a': ['q1'], 'q0|b': ['q0'],
          'q1|a': ['q0'], 'q1|b': ['q1'],
          // Unreachable transitions
          'q2|a': ['q3'], 'q2|b': ['q2'],
          'q3|a': ['q2'], 'q3|b': ['q3'],
        },
        initialId: 'q0',
        nextId: 4,
      );

      final result = minimizeDfaIfValid(dfa);
      expect(result, isNotNull);
      
      // The minimized DFA should have only 2 states (unreachable states removed)
      expect(result!.minimized.states.length, equals(2));
      
      // It should have 4 transitions (2 states × 2 symbols)
      expect(result.minimized.transitions.length, equals(4));
    });

    test('Minimize DFA with trap state', () {
      // A DFA with explicit trap state
      final dfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: true),
          StateNode(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: false),
          StateNode(id: 'trap', name: 'trap', x: 200, y: 0, isInitial: false, isFinal: false),
        ],
        transitions: {
          'q0|a': ['q1'], 'q0|b': ['q0'],
          'q1|a': ['q0'], 'q1|b': ['q1'],
          'trap|a': ['trap'], 'trap|b': ['trap'],
        },
        initialId: 'q0',
        nextId: 3,
      );

      final result = minimizeDfaIfValid(dfa);
      expect(result, isNotNull);
      
      // The minimized DFA should have 2 states (q0 and q1) since the trap state is unreachable
      expect(result!.minimized.states.length, equals(2));
      
      // It should have 4 transitions (2 states × 2 symbols)
      expect(result.minimized.transitions.length, equals(4));
    });
  });
}
