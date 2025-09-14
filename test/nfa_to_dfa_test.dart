import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/automaton.dart';
import 'package:jflutter/core/nfa_algorithms.dart' as nfa_algo;
import 'package:jflutter/core/algorithms.dart';

void main() {
  group('NFA to DFA Conversion', () {
    test('Convert simple NFA to DFA', () {
      // Create an NFA that accepts strings ending with 'a' or 'b'
      final nfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
          StateNode(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: true),
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

      // Convert NFA to DFA
      final dfa = nfa_algo.nfaToDfa(nfa);

      // Verify the DFA has the correct number of states
      expect(dfa.states.length, equals(2));
      
      // Verify the DFA has the correct transitions
      expect(dfa.transitions.length, equals(4));
      
      // Verify the initial state
      final initialState = dfa.getState(dfa.initialId!);
      expect(initialState, isNotNull);
      
      // Verify final states
      final finalStates = dfa.states.where((s) => s.isFinal).toList();
      expect(finalStates.length, equals(1));
      
      // Verify transitions from the initial state
      final fromInitialA = dfa.transitions['${initialState!.id}|a'];
      expect(fromInitialA, isNotNull);
      expect(fromInitialA!.length, equals(1));
      
      final fromInitialB = dfa.transitions['${initialState.id}|b'];
      expect(fromInitialB, isNotNull);
      expect(fromInitialB!.length, equals(1));
    });

    test('Convert NFA with epsilon transitions to DFA', () {
      // Create an NFA that accepts strings with 'a' followed by any number of 'b's
      final nfa = Automaton(
        alphabet: {'a', 'b'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
          StateNode(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: true),
          StateNode(id: 'q2', name: 'q2', x: 200, y: 0, isInitial: false, isFinal: true),
        ],
        transitions: {
          'q0|a': ['q1'],
          'q1|ε': ['q2'],
          'q2|b': ['q2'],
        },
        initialId: 'q0',
        nextId: 3,
      );

      // Convert NFA to DFA
      final dfa = nfa_algo.nfaToDfa(nfa);

      // Verify the DFA has the correct number of states
      expect(dfa.states.length, isPositive);
      
      // Verify the DFA has the correct transitions
      expect(dfa.transitions.length, isPositive);
      
      // Verify the initial state
      final initialState = dfa.getState(dfa.initialId!);
      expect(initialState, isNotNull);
      
      // Verify final states (should include states containing q1 or q2)
      final finalStates = dfa.states.where((s) => s.isFinal).toList();
      expect(finalStates, isNotEmpty);
    });

    test('nfaToDfaIfValid returns null for DFA input', () {
      // Create a DFA (no epsilon transitions, deterministic)
      final dfa = Automaton(
        alphabet: {'0', '1'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
          StateNode(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: true),
        ],
        transitions: {
          'q0|0': ['q0'],
          'q0|1': ['q1'],
          'q1|0': ['q1'],
          'q1|1': ['q1'],
        },
        initialId: 'q0',
        nextId: 2,
      );

      // Should return null since it's already a DFA
      final result = nfaToDfaIfValid(dfa);
      expect(result, isNull);
    });
  });

  group('Epsilon Closure', () {
    test('Epsilon closure of a single state', () {
      final nfa = Automaton(
        alphabet: {'a', 'ε'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
          StateNode(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: true),
        ],
        transitions: {
          'q0|ε': ['q1'],
        },
        initialId: 'q0',
        nextId: 2,
      );

      // Test the NFA to DFA conversion
      print('Testing NFA to DFA conversion');
      print('NFA states: ${nfa.states.map((s) => '${s.id}${s.isFinal ? ' (final)' : ''}')}');
      print('NFA transitions: ${nfa.transitions}');
      
      final dfa = nfa_algo.nfaToDfa(nfa);
      
      // Debug print DFA information
      print('DFA states:');
      for (final state in dfa.states) {
        print('  ${state.id}${state.isInitial ? ' (initial)' : ''}${state.isFinal ? ' (final)' : ''}');
      }
      print('DFA transitions: ${dfa.transitions}');
      
      // Basic DFA validation
      expect(dfa.states, isNotEmpty);
      
      // Check that the DFA has an initial state
      final initialState = dfa.states.firstWhere(
        (s) => s.isInitial,
        orElse: () => throw TestFailure('No initial state found in DFA')
      );
      
      // For this specific test, we're only testing epsilon closure, not transitions
      // The DFA should have two states: one for {q0, q1} and one for {q1}
      expect(dfa.states.length, equals(2));
      
      // The initial state should be {q0, q1} and it should be final
      expect(initialState.id, equals('q0_q1'));
      expect(initialState.isFinal, isTrue);
      
      // The other state should be {q1} and should also be final
      final otherState = dfa.states.firstWhere((s) => s.id == 'q1');
      expect(otherState.isFinal, isTrue);
    });

    test('Epsilon closure with multiple epsilon transitions', () {
      final nfa = Automaton(
        alphabet: {'a', 'ε'},
        states: [
          StateNode(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
          StateNode(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: false),
          StateNode(id: 'q2', name: 'q2', x: 200, y: 0, isInitial: false, isFinal: true),
        ],
        transitions: {
          'q0|ε': ['q1'],
          'q1|ε': ['q2'],
        },
        initialId: 'q0',
        nextId: 3,
      );

      // Test the NFA to DFA conversion with multiple epsilon transitions
      print('Testing NFA to DFA conversion with multiple epsilon transitions');
      print('NFA states: ${nfa.states.map((s) => '${s.id}${s.isFinal ? ' (final)' : ''}')}');
      print('NFA transitions: ${nfa.transitions}');
      
      final dfa = nfa_algo.nfaToDfa(nfa);
      
      // Debug print DFA information
      print('DFA states:');
      for (final state in dfa.states) {
        print('  ${state.id}${state.isInitial ? ' (initial)' : ''}${state.isFinal ? ' (final)' : ''}');
      }
      print('DFA transitions: ${dfa.transitions}');
      
      // Basic DFA validation
      expect(dfa.states, isNotEmpty);
      
      // Check that the DFA has an initial state
      final initialState = dfa.states.firstWhere(
        (s) => s.isInitial,
        orElse: () => throw TestFailure('No initial state found in DFA')
      );
      
      // For this test with multiple epsilon transitions, we expect:
      // 1. Initial state {q0, q1, q2} which is final (since q2 is final)
      // 2. State {q1, q2} which is final
      // 3. State {q2} which is final
      expect(dfa.states.length, equals(3));
      
      // The initial state should be {q0, q1, q2} and it should be final
      expect(initialState.id, equals('q0_q1_q2'));
      expect(initialState.isFinal, isTrue);
      
      // Check for the other states
      final stateQ1Q2 = dfa.states.firstWhere((s) => s.id == 'q1_q2');
      expect(stateQ1Q2.isFinal, isTrue);
      
      final stateQ2 = dfa.states.firstWhere((s) => s.id == 'q2');
      expect(stateQ2.isFinal, isTrue);
    });
  });
}
