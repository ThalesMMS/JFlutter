//
//  language_comparator_test.dart
//  JFlutter
//
//  Conjunto de testes que valida o LanguageComparator para comparação de
//  linguagens entre DFAs e NFAs. Cobre cenários de equivalência, não-equivalência,
//  geração de strings distinguidoras, e casos extremos. Verifica que o algoritmo
//  de produto corretamente identifica diferenças entre linguagens reconhecidas
//  por autômatos construídos de formas distintas.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/algorithms/language_comparator.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

void main() {
  group('Language Comparator Tests', () {
    late FSA dfa1;
    late FSA dfa2;
    late FSA nfa1;
    late FSA nfa2;
    late FSA nonEquivalentDFA;
    late FSA nonEquivalentNFA;

    setUp(() {
      // Test Case 1: Equivalent DFAs - recognizes strings ending in 'a'
      dfa1 = _createDFAEndingInA();
      dfa2 = _createDFAEndingInAAlternative();

      // Test Case 2: Equivalent NFAs - recognizes strings with 'ab'
      nfa1 = _createNFAContainingAB();
      nfa2 = _createNFAContainingABAlternative();

      // Test Case 3: Non-equivalent DFA - recognizes strings ending in 'b'
      nonEquivalentDFA = _createDFAEndingInB();

      // Test Case 4: Non-equivalent NFA - recognizes strings starting with 'a'
      nonEquivalentNFA = _createNFAStartingWithA();
    });

    group('Equivalent DFAs Tests', () {
      test('Equivalent DFAs should be recognized as equivalent', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
        expect(result.data!.distinguishingString, null);
        expect(result.data!.productAutomaton, isNotNull);
        expect(result.data!.steps, isNotEmpty);
        expect(result.data!.executionTimeMs, greaterThanOrEqualTo(0));
      });

      test('Same DFA should be equivalent to itself', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa1);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
        expect(result.data!.distinguishingString, null);
      });

      test('Non-equivalent DFAs should be recognized as non-equivalent', () {
        final result = LanguageComparator.compareLanguages(
          dfa1,
          nonEquivalentDFA,
        );

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, false);
        expect(result.data!.distinguishingString, isNotNull);
        expect(result.data!.distinguishingString, isNotEmpty);
      });
    });

    group('Equivalent NFAs Tests', () {
      test('Equivalent NFAs should be recognized as equivalent', () {
        final result = LanguageComparator.compareLanguages(nfa1, nfa2);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
        expect(result.data!.distinguishingString, null);
        expect(result.data!.productAutomaton, isNotNull);
      });

      test('Same NFA should be equivalent to itself', () {
        final result = LanguageComparator.compareLanguages(nfa1, nfa1);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
        expect(result.data!.distinguishingString, null);
      });

      test('Non-equivalent NFAs should be recognized as non-equivalent', () {
        final result = LanguageComparator.compareLanguages(
          nfa1,
          nonEquivalentNFA,
        );

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, false);
        expect(result.data!.distinguishingString, isNotNull);
      });
    });

    group('Cross-Type Comparison Tests', () {
      test('DFA and NFA with same language should be equivalent', () {
        final dfaEndingA = _createDFAEndingInA();
        final nfaEndingA = _createNFAEndingInA();

        final result = LanguageComparator.compareLanguages(
          dfaEndingA,
          nfaEndingA,
        );

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
        expect(result.data!.distinguishingString, null);
      });

      test('DFA and NFA with different languages should not be equivalent', () {
        final result = LanguageComparator.compareLanguages(
          dfa1,
          nonEquivalentNFA,
        );

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, false);
        expect(result.data!.distinguishingString, isNotNull);
      });
    });

    group('Distinguishing String Tests', () {
      test(
        'Distinguishing string should be found for non-equivalent automata',
        () {
          final result = LanguageComparator.compareLanguages(
            dfa1,
            nonEquivalentDFA,
          );

          expect(result.isSuccess, true);
          expect(result.data!.isEquivalent, false);
          expect(result.data!.distinguishingString, isNotNull);
          expect(result.data!.distinguishingString!.length, greaterThan(0));
        },
      );

      test('Empty string should be distinguishing for initial states', () {
        final acceptsEmpty = _createDFAAcceptingEmpty();
        final rejectsEmpty = _createDFARejectingEmpty();

        final result = LanguageComparator.compareLanguages(
          acceptsEmpty,
          rejectsEmpty,
        );

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, false);
        expect(result.data!.distinguishingString, '');
      });

      test('Distinguishing string should be minimal', () {
        final simple1 = _createSimpleDFA1();
        final simple2 = _createSimpleDFA2();

        final result = LanguageComparator.compareLanguages(simple1, simple2);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, false);
        expect(result.data!.distinguishingString, isNotNull);
        // BFS ensures we find shortest path
        expect(result.data!.distinguishingString!.length, lessThanOrEqualTo(3));
      });
    });

    group('Product Automaton Tests', () {
      test('Product automaton should be constructed', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(result.data!.productAutomaton, isNotNull);
        expect(result.data!.productAutomaton!.states, isNotEmpty);
        expect(result.data!.productAutomaton!.transitions, isNotEmpty);
        expect(result.data!.productAutomaton!.initialState, isNotNull);
      });

      test('Product automaton should have combined alphabet', () {
        final dfaAB = _createDFAWithAlphabet({'a', 'b'});
        final dfaBC = _createDFAWithAlphabet({'b', 'c'});

        final result = LanguageComparator.compareLanguages(dfaAB, dfaBC);

        expect(result.isSuccess, true);
        expect(result.data!.productAutomaton, isNotNull);
        expect(
          result.data!.productAutomaton!.alphabet,
          containsAll({'a', 'b', 'c'}),
        );
      });

      test('Product automaton accepting states mark differences', () {
        final result = LanguageComparator.compareLanguages(
          dfa1,
          nonEquivalentDFA,
        );

        expect(result.isSuccess, true);
        expect(result.data!.productAutomaton, isNotNull);
        // If non-equivalent, there should be at least one accepting state
        // in the product (marking where languages differ)
        expect(result.data!.productAutomaton!.acceptingStates, isNotEmpty);
      });
    });

    group('Edge Cases Tests', () {
      test('Empty automata should fail validation', () {
        final empty1 = _createEmptyAutomaton();
        final empty2 = _createEmptyAutomaton();

        final result = LanguageComparator.compareLanguages(empty1, empty2);

        expect(result.isSuccess, false);
        expect(result.error, contains('must have at least one state'));
      });

      test('Automata without initial state should fail validation', () {
        final noInitial1 = _createNoInitialStateAutomaton();
        final noInitial2 = _createNoInitialStateAutomaton();

        final result = LanguageComparator.compareLanguages(
          noInitial1,
          noInitial2,
        );

        expect(result.isSuccess, false);
        expect(result.error, contains('must have an initial state'));
      });

      test('Automata with initial state not in states should fail', () {
        final invalidInitial = _createInvalidInitialStateAutomaton();
        final valid = _createDFAEndingInA();

        final result = LanguageComparator.compareLanguages(
          invalidInitial,
          valid,
        );

        expect(result.isSuccess, false);
        expect(result.error, contains('must be in the states set'));
      });

      test('Automata with different alphabets should be handled', () {
        final dfaAB = _createDFAWithAlphabet({'a', 'b'});
        final dfaCD = _createDFAWithAlphabet({'c', 'd'});

        final result = LanguageComparator.compareLanguages(dfaAB, dfaCD);

        // Should succeed - alphabets are combined
        expect(result.isSuccess, true);
        expect(result.data!.productAutomaton, isNotNull);
      });

      test('Automata with epsilon transitions should be handled', () {
        final nfaWithEpsilon = _createNFAWithEpsilon();
        final dfa = _createDFAEndingInA();

        final result = LanguageComparator.compareLanguages(nfaWithEpsilon, dfa);

        // Should succeed - NFA is converted to DFA first
        expect(result.isSuccess, true);
      });

      test('Single state accepting automaton should work', () {
        final single1 = _createSingleStateAccepting();
        final single2 = _createSingleStateAccepting();

        final result = LanguageComparator.compareLanguages(single1, single2);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
      });

      test('Single state rejecting automaton should work', () {
        final single1 = _createSingleStateRejecting();
        final single2 = _createSingleStateRejecting();

        final result = LanguageComparator.compareLanguages(single1, single2);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
      });
    });

    group('Algorithm Steps Tests', () {
      test('Steps should be generated for successful comparison', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(result.data!.steps, isNotEmpty);
        expect(result.data!.steps.first['type'], equals('validation'));
        expect(result.data!.steps.last['type'], equals('result'));
      });

      test('Steps should include all major phases', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);

        final stepTypes = result.data!.steps.map((s) => s['type']).toList();

        expect(stepTypes, contains('validation'));
        expect(stepTypes, contains('alphabet_normalization'));
        expect(stepTypes, contains('product_construction_start'));
        expect(stepTypes, contains('bfs_search_start'));
        expect(stepTypes, contains('result'));
      });

      test('Steps should include NFA conversion when needed', () {
        final result = LanguageComparator.compareLanguages(nfa1, dfa1);

        expect(result.isSuccess, true);

        final stepTypes = result.data!.steps.map((s) => s['type']).toList();
        expect(stepTypes, contains('nfa_to_dfa'));
      });

      test('Steps should include DFA completion', () {
        final incomplete = _createIncompleteDFA();
        final complete = _createDFAEndingInA();

        final result = LanguageComparator.compareLanguages(
          incomplete,
          complete,
        );

        expect(result.isSuccess, true);

        final stepTypes = result.data!.steps.map((s) => s['type']).toList();
        expect(stepTypes, contains('dfa_completion'));
      });
    });

    group('Performance Tests', () {
      test('Comparison should complete within reasonable time', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(
          result.data!.executionTimeMs,
          lessThan(1000),
          reason: 'Comparison should complete within 1 second',
        );
      });

      test('Large automata should complete within reasonable time', () {
        final large1 = _createLargeDFA(10);
        final large2 = _createLargeDFA(10);

        final result = LanguageComparator.compareLanguages(large1, large2);

        expect(result.isSuccess, true);
        expect(
          result.data!.executionTimeMs,
          lessThan(5000),
          reason: 'Large automata comparison should complete within 5 seconds',
        );
      });
    });

    group('Result Metadata Tests', () {
      test('Result should include timestamp', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(result.data!.timestamp, isNotNull);
      });

      test('Result should reference original automata', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(result.data!.originalAutomaton.id, equals(dfa1.id));
        expect(result.data!.comparedAutomaton.id, equals(dfa2.id));
      });

      test('Execution time should be non-negative', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(result.data!.executionTimeMs, greaterThanOrEqualTo(0));
      });
    });
  });
}

/// Helper functions to create test automata

/// DFA that accepts strings ending in 'a'
FSA _createDFAEndingInA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q0,
      toState: q0,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q1,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't4',
      fromState: q1,
      toState: q0,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'dfa_ending_a',
    name: 'DFA Ending in A',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Alternative DFA that accepts strings ending in 'a' (different structure)
FSA _createDFAEndingInAAlternative() {
  final s0 = State(
    id: 's0',
    label: 's0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final s1 = State(
    id: 's1',
    label: 's1',
    position: Vector2(100, 100),
    isInitial: false,
    isAccepting: true,
  );

  final states = {s0, s1};

  final transitions = {
    FSATransition.deterministic(
      id: 'ta1',
      fromState: s0,
      toState: s1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'ta2',
      fromState: s0,
      toState: s0,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 'ta3',
      fromState: s1,
      toState: s1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'ta4',
      fromState: s1,
      toState: s0,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'dfa_ending_a_alt',
    name: 'DFA Ending in A (Alternative)',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: s0,
    acceptingStates: {s1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// DFA that accepts strings ending in 'b'
FSA _createDFAEndingInB() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q0,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q0,
      toState: q1,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q1,
      toState: q0,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't4',
      fromState: q1,
      toState: q1,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'dfa_ending_b',
    name: 'DFA Ending in B',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// NFA that accepts strings containing 'ab'
FSA _createNFAContainingAB() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: false,
  );

  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(200, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1, q2};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q0,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q0,
      toState: q0,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't4',
      fromState: q1,
      toState: q2,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 't5',
      fromState: q2,
      toState: q2,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't6',
      fromState: q2,
      toState: q2,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'nfa_containing_ab',
    name: 'NFA Containing AB',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q2},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Alternative NFA that accepts strings containing 'ab'
FSA _createNFAContainingABAlternative() {
  final s0 = State(
    id: 's0',
    label: 's0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final s1 = State(
    id: 's1',
    label: 's1',
    position: Vector2(100, 100),
    isInitial: false,
    isAccepting: false,
  );

  final s2 = State(
    id: 's2',
    label: 's2',
    position: Vector2(200, 100),
    isInitial: false,
    isAccepting: true,
  );

  final states = {s0, s1, s2};

  final transitions = {
    FSATransition.deterministic(
      id: 'ta1',
      fromState: s0,
      toState: s0,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'ta2',
      fromState: s0,
      toState: s0,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 'ta3',
      fromState: s0,
      toState: s1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'ta4',
      fromState: s1,
      toState: s2,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 'ta5',
      fromState: s2,
      toState: s2,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'ta6',
      fromState: s2,
      toState: s2,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'nfa_containing_ab_alt',
    name: 'NFA Containing AB (Alternative)',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: s0,
    acceptingStates: {s2},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// NFA that accepts strings starting with 'a'
FSA _createNFAStartingWithA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q1,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q1,
      toState: q1,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'nfa_starting_a',
    name: 'NFA Starting with A',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// NFA that accepts strings ending in 'a' (for cross-type comparison)
FSA _createNFAEndingInA() {
  final q0 = State(
    id: 'nq0',
    label: 'nq0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'nq1',
    label: 'nq1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 'nt1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'nt2',
      fromState: q0,
      toState: q0,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 'nt3',
      fromState: q1,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'nt4',
      fromState: q1,
      toState: q0,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'nfa_ending_a',
    name: 'NFA Ending in A',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// DFA that accepts only the empty string
FSA _createDFAAcceptingEmpty() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: true,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: false,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q0,
      toState: q1,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q1,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't4',
      fromState: q1,
      toState: q1,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'dfa_empty',
    name: 'DFA Accepting Empty',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q0},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// DFA that rejects the empty string
FSA _createDFARejectingEmpty() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q0,
      toState: q1,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q1,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't4',
      fromState: q1,
      toState: q1,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'dfa_reject_empty',
    name: 'DFA Rejecting Empty',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Simple DFA for minimal distinguishing string test
FSA _createSimpleDFA1() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q1,
      toState: q1,
      symbol: 'a',
    ),
  };

  return FSA(
    id: 'simple1',
    name: 'Simple DFA 1',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Simple DFA that differs at 'aa'
FSA _createSimpleDFA2() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(200, 0),
    isInitial: false,
    isAccepting: false,
  );

  final states = {q0, q1, q2};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q1,
      toState: q2,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q2,
      toState: q2,
      symbol: 'a',
    ),
  };

  return FSA(
    id: 'simple2',
    name: 'Simple DFA 2',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// DFA with specific alphabet
FSA _createDFAWithAlphabet(Set<String> alphabet) {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: true,
  );

  final states = {q0};

  final transitions = alphabet
      .map(
        (symbol) => FSATransition.deterministic(
          id: 't_$symbol',
          fromState: q0,
          toState: q0,
          symbol: symbol,
        ),
      )
      .toSet();

  return FSA(
    id: 'dfa_${alphabet.join('')}',
    name: 'DFA with alphabet ${alphabet.join('')}',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: q0,
    acceptingStates: {q0},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// NFA with epsilon transitions
FSA _createNFAWithEpsilon() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: false,
  );

  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(200, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1, q2};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'ε',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q1,
      toState: q2,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q2,
      toState: q2,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't4',
      fromState: q2,
      toState: q2,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'nfa_epsilon',
    name: 'NFA with Epsilon',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q2},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Single state accepting automaton
FSA _createSingleStateAccepting() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: true,
  );

  final states = {q0};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q0,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q0,
      toState: q0,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'single_accepting',
    name: 'Single State Accepting',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q0},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Single state rejecting automaton
FSA _createSingleStateRejecting() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final states = {q0};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q0,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q0,
      toState: q0,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'single_rejecting',
    name: 'Single State Rejecting',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Empty automaton (no states)
FSA _createEmptyAutomaton() {
  return FSA(
    id: 'empty',
    name: 'Empty Automaton',
    states: {},
    transitions: {},
    alphabet: {'a', 'b'},
    initialState: null,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Automaton without initial state
FSA _createNoInitialStateAutomaton() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: false,
    isAccepting: false,
  );

  final states = {q0};

  return FSA(
    id: 'no_initial',
    name: 'No Initial State',
    states: states,
    transitions: {},
    alphabet: {'a', 'b'},
    initialState: null,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Automaton with invalid initial state
FSA _createInvalidInitialStateAutomaton() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: false,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: true,
    isAccepting: false,
  );

  final states = {q0};

  return FSA(
    id: 'invalid_initial',
    name: 'Invalid Initial State',
    states: states,
    transitions: {},
    alphabet: {'a', 'b'},
    initialState: q1, // q1 is not in states
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Incomplete DFA (missing some transitions)
FSA _createIncompleteDFA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1};

  // Missing transition from q0 on 'b' and from q1 on both symbols
  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
  };

  return FSA(
    id: 'incomplete_dfa',
    name: 'Incomplete DFA',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Large DFA for performance testing
FSA _createLargeDFA(int stateCount) {
  final states = <State>{};
  final transitions = <FSATransition>{};

  // Create states in a chain
  for (var i = 0; i < stateCount; i++) {
    states.add(
      State(
        id: 'q$i',
        label: 'q$i',
        position: Vector2(i * 100.0, 0),
        isInitial: i == 0,
        isAccepting: i == stateCount - 1,
      ),
    );
  }

  final stateList = states.toList();

  // Create transitions
  for (var i = 0; i < stateCount; i++) {
    final fromState = stateList[i];
    final toState = stateList[(i + 1) % stateCount];

    transitions.add(
      FSATransition.deterministic(
        id: 't${i}_a',
        fromState: fromState,
        toState: toState,
        symbol: 'a',
      ),
    );

    transitions.add(
      FSATransition.deterministic(
        id: 't${i}_b',
        fromState: fromState,
        toState: fromState,
        symbol: 'b',
      ),
    );
  }

  return FSA(
    id: 'large_dfa_$stateCount',
    name: 'Large DFA ($stateCount states)',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: stateList[0],
    acceptingStates: {stateList[stateCount - 1]},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}
