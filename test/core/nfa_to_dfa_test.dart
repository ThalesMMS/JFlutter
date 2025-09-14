import 'package:test/test.dart';
import 'package:jflutter/core/automaton.dart';
import 'package:jflutter/core/nfa_algorithms.dart';

void main() {
  group('NFA to DFA Conversion with Improved State Naming', () {
    test('Simple NFA with two states', () {
      // Create a simple NFA that accepts strings ending with 'a'
      final nfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(
            id: 'q0',
            name: 'q0',
            x: 0,
            y: 0,
            isInitial: true,
            isFinal: false,
          ),
          StateNode(
            id: 'q1',
            name: 'q1',
            x: 100,
            y: 0,
            isInitial: false,
            isFinal: true,
          ),
        ],
        transitions: {
          'q0|a': ['q0', 'q1'],
          'q0|b': ['q0'],
        },
        initialId: 'q0',
        nextId: 2,
      );

      // Convert to DFA
      final dfa = nfaToDfa(nfa);

      // Verify state names are human-readable
      final stateNames = dfa.states.map((s) => s.name).toSet();
      expect(stateNames.length, dfa.states.length, 
          reason: 'All state names should be unique');
      
      // Should have states like 'q0' and 'q0_q1'
      expect(stateNames.any((name) => name == 'q0'), isTrue);
      expect(stateNames.any((name) => name.contains('q1')), isTrue);
      
      // Verify the DFA structure
      expect(dfa.states.length, 2, reason: 'Should have 2 states');
      
      final initialState = dfa.states.firstWhere((s) => s.isInitial);
      final finalState = dfa.states.firstWhere((s) => s.isFinal);
      
      // Verify transitions
      expect(dfa.transitions['${initialState.id}|a']?.first, finalState.id);
      expect(dfa.transitions['${initialState.id}|b']?.first, initialState.id);
      expect(dfa.transitions['${finalState.id}|a']?.first, finalState.id);
      expect(dfa.transitions['${finalState.id}|b']?.first, initialState.id);
    });

    test('NFA with multiple states', () {
      // Create an NFA that accepts strings with 'ab' as substring
      final nfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
          StateNode(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: false),
          StateNode(id: 'q2', name: 'q2', x: 200, y: 0, isInitial: false, isFinal: true),
        ],
        transitions: {
          'q0|a': ['q0', 'q1'],
          'q0|b': ['q0'],
          'q1|b': ['q2'],
          'q2|a': ['q2'],
          'q2|b': ['q2'],
        },
        initialId: 'q0',
        nextId: 3,
      );

      // Convert to DFA
      final dfa = nfaToDfa(nfa);

      // Verify state names are human-readable
      final stateNames = dfa.states.map((s) => s.name).toList();
      print('DFA state names: $stateNames');
      
      // Should have states like 'q0', 'q0_q1', 'q0_q2', etc.
      expect(stateNames.length, greaterThanOrEqualTo(3));
      
      // Verify the DFA structure
      final initialState = dfa.states.firstWhere((s) => s.isInitial);
      final finalStates = dfa.states.where((s) => s.isFinal).toList();
      
      expect(finalStates.length, greaterThanOrEqualTo(1));
      
      // Print the DFA for debugging
      print('DFA transitions:');
      dfa.transitions.forEach((key, value) {
        print('  $key -> $value');
      });
    });

    test('NFA with epsilon transitions', () {
      // Create an NFA with epsilon transitions
      final nfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
          StateNode(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: true),
          StateNode(id: 'q2', name: 'q2', x: 200, y: 0, isInitial: false, isFinal: false),
        ],
        transitions: {
          'q0|ε': ['q1'],  // Epsilon transition
          'q0|a': ['q0'],
          'q1|b': ['q1', 'q2'],
          'q2|a': ['q2'],
        },
        initialId: 'q0',
        nextId: 3,
      );

      // Convert to DFA
      final dfa = nfaToDfa(nfa);

      // Verify state names are human-readable
      final stateNames = dfa.states.map((s) => s.name).toList();
      print('DFA with epsilon state names: $stateNames');
      
      // Should have at least 2 states
      expect(stateNames.length, greaterThanOrEqualTo(2));
      
      // The initial state should be final because of epsilon closure
      final initialState = dfa.states.firstWhere((s) => s.isInitial);
      expect(initialState.isFinal, isTrue);
    });
  });
}
