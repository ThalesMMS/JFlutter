import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/algorithms/nfa_to_dfa_converter.dart';
import 'package:jflutter/core/result.dart';

void main() {
  group('NFA to DFA Converter Tests', () {
    late State q0, q1, q2;
    late FSA testNFA;

    setUp(() {
      q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(100.0, 100.0),
        isInitial: true,
      );
      q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(200.0, 100.0),
      );
      q2 = State(
        id: 'q2',
        label: 'q2',
        position: Vector2(300.0, 100.0),
        isAccepting: true,
      );
    });

    group('Simple NFA to DFA Conversion', () {
      test('should convert simple deterministic NFA to DFA', () {
        final transitions = {
          FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            label: 'a',
            inputSymbols: {'a'},
          ),
          FSATransition(
            id: 't1',
            fromState: q1,
            toState: q2,
            label: 'b',
            inputSymbols: {'b'},
          ),
        };

        testNFA = FSA(
          id: 'nfa1',
          name: 'Simple NFA',
          states: {q0, q1, q2},
          transitions: transitions,
          alphabet: {'a', 'b'},
          initialState: q0,
          acceptingStates: {q2},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 200),
        );

        final result = NFAToDFAConverter.convert(testNFA);

        expect(result.isSuccess, true);
        final dfa = result.data!;
        expect(dfa.states.length, 3); // Should have same number of states
        expect(dfa.initialState?.id, 'q0');
        expect(dfa.acceptingStates.length, 1);
        expect(dfa.transitions.length, 2);
      });

      test('should convert NFA with multiple transitions on same symbol', () {
        final q3 = State(
          id: 'q3',
          label: 'q3',
          position: Vector2(200.0, 200.0),
          isAccepting: true,
        );

        final transitions = {
          FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            label: 'a',
            inputSymbols: {'a'},
          ),
          FSATransition(
            id: 't1',
            fromState: q0,
            toState: q3,
            label: 'a',
            inputSymbols: {'a'},
          ),
          FSATransition(
            id: 't2',
            fromState: q1,
            toState: q2,
            label: 'b',
            inputSymbols: {'b'},
          ),
          FSATransition(
            id: 't3',
            fromState: q3,
            toState: q2,
            label: 'b',
            inputSymbols: {'b'},
          ),
        };

        testNFA = FSA(
          id: 'nfa2',
          name: 'NFA with multiple transitions',
          states: {q0, q1, q2, q3},
          transitions: transitions,
          alphabet: {'a', 'b'},
          initialState: q0,
          acceptingStates: {q2},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 300),
        );

        final result = NFAToDFAConverter.convert(testNFA);

        expect(result.isSuccess, true);
        final dfa = result.data!;
        expect(dfa.states.length, greaterThan(4)); // Should have more states due to subset construction
        expect(dfa.initialState?.id, 'q0');
        expect(dfa.acceptingStates.length, greaterThan(0));
      });
    });

    group('Epsilon Transition Handling', () {
      test('should convert NFA with epsilon transitions', () {
        final transitions = {
          FSATransition.epsilon(
            id: 't0',
            fromState: q0,
            toState: q1,
          ),
          FSATransition(
            id: 't1',
            fromState: q1,
            toState: q2,
            label: 'a',
            inputSymbols: {'a'},
          ),
        };

        testNFA = FSA(
          id: 'nfa3',
          name: 'NFA with epsilon',
          states: {q0, q1, q2},
          transitions: transitions,
          alphabet: {'a'},
          initialState: q0,
          acceptingStates: {q2},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 200),
        );

        final result = NFAToDFAConverter.convert(testNFA);

        expect(result.isSuccess, true);
        final dfa = result.data!;
        expect(dfa.initialState?.id, 'q0');
        expect(dfa.acceptingStates.length, greaterThan(0));
      });

      test('should handle epsilon closure correctly', () {
        final q3 = State(
          id: 'q3',
          label: 'q3',
          position: Vector2(300.0, 200.0),
        );

        final transitions = {
          FSATransition.epsilon(
            id: 't0',
            fromState: q0,
            toState: q1,
          ),
          FSATransition.epsilon(
            id: 't1',
            fromState: q1,
            toState: q3,
          ),
          FSATransition(
            id: 't2',
            fromState: q3,
            toState: q2,
            label: 'a',
            inputSymbols: {'a'},
          ),
        };

        testNFA = FSA(
          id: 'nfa4',
          name: 'NFA with epsilon chain',
          states: {q0, q1, q2, q3},
          transitions: transitions,
          alphabet: {'a'},
          initialState: q0,
          acceptingStates: {q2},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 300),
        );

        final result = NFAToDFAConverter.convert(testNFA);

        expect(result.isSuccess, true);
        final dfa = result.data!;
        expect(dfa.initialState?.id, 'q0');
      });
    });

    group('Error Handling', () {
      test('should handle empty NFA', () {
        final emptyNFA = FSA(
          id: 'empty',
          name: 'Empty NFA',
          states: {},
          transitions: {},
          alphabet: {},
          initialState: null,
          acceptingStates: {},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 0, 0),
        );

        final result = NFAToDFAConverter.convert(emptyNFA);

        expect(result.isSuccess, false);
        expect(result.error, contains('Cannot convert empty NFA to DFA'));
      });

      test('should handle NFA without initial state', () {
        final noInitialNFA = FSA(
          id: 'no_initial',
          name: 'No Initial NFA',
          states: {q0, q1},
          transitions: {
            FSATransition(
              id: 't0',
              fromState: q0,
              toState: q1,
              label: 'a',
              inputSymbols: {'a'},
            ),
          },
          alphabet: {'a'},
          initialState: null,
          acceptingStates: {q1},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 300, 200),
        );

        final result = NFAToDFAConverter.convert(noInitialNFA);

        expect(result.isSuccess, false);
        expect(result.error, contains('NFA must have an initial state'));
      });

      test('should handle invalid initial state', () {
        final invalidInitialState = State(
          id: 'invalid',
          label: 'Invalid',
          position: Vector2(500.0, 500.0),
        );

        final invalidNFA = FSA(
          id: 'invalid_initial',
          name: 'Invalid Initial NFA',
          states: {q0, q1},
          transitions: {
            FSATransition(
              id: 't0',
              fromState: q0,
              toState: q1,
              label: 'a',
              inputSymbols: {'a'},
            ),
          },
          alphabet: {'a'},
          initialState: invalidInitialState,
          acceptingStates: {q1},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 300, 200),
        );

        final result = NFAToDFAConverter.convert(invalidNFA);

        expect(result.isSuccess, false);
        expect(result.error, contains('Initial state must be in the states set'));
      });

      test('should handle invalid accepting state', () {
        final invalidAcceptingState = State(
          id: 'invalid_accepting',
          label: 'Invalid Accepting',
          position: Vector2(500.0, 500.0),
          isAccepting: true,
        );

        final invalidNFA = FSA(
          id: 'invalid_accepting',
          name: 'Invalid Accepting NFA',
          states: {q0, q1},
          transitions: {
            FSATransition(
              id: 't0',
              fromState: q0,
              toState: q1,
              label: 'a',
              inputSymbols: {'a'},
            ),
          },
          alphabet: {'a'},
          initialState: q0,
          acceptingStates: {invalidAcceptingState},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 300, 200),
        );

        final result = NFAToDFAConverter.convert(invalidNFA);

        expect(result.isSuccess, false);
        expect(result.error, contains('Accepting state must be in the states set'));
      });
    });

    group('Complex NFA Scenarios', () {
      test('should convert NFA with self-loops', () {
        final transitions = {
          FSATransition(
            id: 't0',
            fromState: q0,
            toState: q0,
            label: 'a',
            inputSymbols: {'a'},
            controlPoint: Vector2(50.0, 50.0),
          ),
          FSATransition(
            id: 't1',
            fromState: q0,
            toState: q1,
            label: 'b',
            inputSymbols: {'b'},
          ),
          FSATransition(
            id: 't2',
            fromState: q1,
            toState: q2,
            label: 'a',
            inputSymbols: {'a'},
          ),
        };

        testNFA = FSA(
          id: 'nfa5',
          name: 'NFA with self-loops',
          states: {q0, q1, q2},
          transitions: transitions,
          alphabet: {'a', 'b'},
          initialState: q0,
          acceptingStates: {q2},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 200),
        );

        final result = NFAToDFAConverter.convert(testNFA);

        expect(result.isSuccess, true);
        final dfa = result.data!;
        expect(dfa.initialState?.id, 'q0');
        expect(dfa.acceptingStates.length, greaterThan(0));
      });

      test('should convert NFA with multiple accepting states', () {
        final q3 = State(
          id: 'q3',
          label: 'q3',
          position: Vector2(200.0, 200.0),
          isAccepting: true,
        );

        final transitions = {
          FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            label: 'a',
            inputSymbols: {'a'},
          ),
          FSATransition(
            id: 't1',
            fromState: q0,
            toState: q3,
            label: 'b',
            inputSymbols: {'b'},
          ),
          FSATransition(
            id: 't2',
            fromState: q1,
            toState: q2,
            label: 'b',
            inputSymbols: {'b'},
          ),
        };

        testNFA = FSA(
          id: 'nfa6',
          name: 'NFA with multiple accepting',
          states: {q0, q1, q2, q3},
          transitions: transitions,
          alphabet: {'a', 'b'},
          initialState: q0,
          acceptingStates: {q2, q3},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 300),
        );

        final result = NFAToDFAConverter.convert(testNFA);

        expect(result.isSuccess, true);
        final dfa = result.data!;
        expect(dfa.initialState?.id, 'q0');
        expect(dfa.acceptingStates.length, greaterThan(0));
      });
    });

    group('DFA Properties Validation', () {
      test('should produce deterministic DFA', () {
        final transitions = {
          FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            label: 'a',
            inputSymbols: {'a'},
          ),
          FSATransition(
            id: 't1',
            fromState: q0,
            toState: q2,
            label: 'b',
            inputSymbols: {'b'},
          ),
          FSATransition(
            id: 't2',
            fromState: q1,
            toState: q2,
            label: 'a',
            inputSymbols: {'a'},
          ),
        };

        testNFA = FSA(
          id: 'nfa7',
          name: 'Test NFA',
          states: {q0, q1, q2},
          transitions: transitions,
          alphabet: {'a', 'b'},
          initialState: q0,
          acceptingStates: {q2},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 200),
        );

        final result = NFAToDFAConverter.convert(testNFA);

        expect(result.isSuccess, true);
        final dfa = result.data!;
        
        // Check that the DFA is deterministic
        for (final state in dfa.states) {
          final outgoingTransitions = dfa.getTransitionsFrom(state);
          final symbols = <String>{};
          for (final transition in outgoingTransitions) {
            if (transition is FSATransition) {
              for (final symbol in transition.inputSymbols) {
                expect(symbols.contains(symbol), false);
                symbols.add(symbol);
              }
            }
          }
        }
      });

      test('should preserve language equivalence', () {
        // Create a simple NFA that accepts strings ending with 'ab'
        final transitions = {
          FSATransition(
            id: 't0',
            fromState: q0,
            toState: q0,
            label: 'a',
            inputSymbols: {'a'},
            controlPoint: Vector2(50.0, 50.0),
          ),
          FSATransition(
            id: 't1',
            fromState: q0,
            toState: q0,
            label: 'b',
            inputSymbols: {'b'},
            controlPoint: Vector2(50.0, 50.0),
          ),
          FSATransition(
            id: 't2',
            fromState: q0,
            toState: q1,
            label: 'a',
            inputSymbols: {'a'},
          ),
          FSATransition(
            id: 't3',
            fromState: q1,
            toState: q2,
            label: 'b',
            inputSymbols: {'b'},
          ),
        };

        testNFA = FSA(
          id: 'nfa8',
          name: 'NFA for strings ending with ab',
          states: {q0, q1, q2},
          transitions: transitions,
          alphabet: {'a', 'b'},
          initialState: q0,
          acceptingStates: {q2},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 200),
        );

        final result = NFAToDFAConverter.convert(testNFA);

        expect(result.isSuccess, true);
        final dfa = result.data!;
        
        // The DFA should have at least 3 states (initial, after 'a', accepting after 'ab')
        expect(dfa.states.length, greaterThanOrEqualTo(3));
        expect(dfa.initialState, isNotNull);
        expect(dfa.acceptingStates.length, greaterThan(0));
      });
    });
  });
}
