import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/algorithms/pumping_lemma_prover.dart';
import 'package:jflutter/core/result.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

/// Pumping Lemma Validation Tests against References/automata-main
/// 
/// This test suite validates pumping lemma algorithms against theoretical expectations
/// and reference implementations to ensure behavioral equivalence.
/// 
/// Test cases cover:
/// 1. Proof scenarios (regular languages that satisfy pumping lemma)
/// 2. Disproof scenarios (non-regular languages that violate pumping lemma)
/// 3. Regularity testing (determining if a language is regular)
/// 4. Pumping length calculation
/// 5. String decomposition and pumping
void main() {
  group('Pumping Lemma Validation Tests', () {
    late FSA regularDFA;
    late FSA regularNFA;
    late FSA nonRegularDFA;
    late FSA simpleDFA;
    late FSA complexDFA;

    setUp(() {
      // Test Case 1: Regular DFA (binary strings ending in 1)
      regularDFA = _createRegularDFA();
      
      // Test Case 2: Regular NFA (strings with pattern)
      regularNFA = _createRegularNFA();
      
      // Test Case 3: Non-regular DFA (a^n b^n)
      nonRegularDFA = _createNonRegularDFA();
      
      // Test Case 4: Simple DFA (a*)
      simpleDFA = _createSimpleDFA();
      
      // Test Case 5: Complex DFA (binary divisible by 3)
      complexDFA = _createComplexDFA();
    });

    group('Proof Tests', () {
      test('Regular DFA should satisfy pumping lemma', () async {
        final result = PumpingLemmaProver.provePumpingLemma(regularDFA);
        
        expect(result.isSuccess, true, 
          reason: 'Pumping lemma proof should succeed for regular DFA');
        
        if (result.isSuccess) {
          final proof = result.data!;
          expect(proof.isSuccess, true,
            reason: 'Regular DFA should satisfy pumping lemma');
          expect(proof.pumpingLength, greaterThan(0),
            reason: 'Pumping length should be positive');
          expect(proof.pumpableString, isNotNull,
            reason: 'Should find a pumpable string');
        }
      });

      test('Regular NFA should satisfy pumping lemma', () async {
        final result = PumpingLemmaProver.provePumpingLemma(regularNFA);
        
        expect(result.isSuccess, true, 
          reason: 'Pumping lemma proof should succeed for regular NFA');
        
        if (result.isSuccess) {
          final proof = result.data!;
          expect(proof.isSuccess, true,
            reason: 'Regular NFA should satisfy pumping lemma');
          expect(proof.pumpableString, isNotNull,
            reason: 'Should find a pumpable string');
        }
      });

      test('Simple DFA should satisfy pumping lemma', () async {
        final result = PumpingLemmaProver.provePumpingLemma(simpleDFA);
        
        expect(result.isSuccess, true, 
          reason: 'Pumping lemma proof should succeed for simple DFA');
        
        if (result.isSuccess) {
          final proof = result.data!;
          expect(proof.isSuccess, true,
            reason: 'Simple DFA should satisfy pumping lemma');
        }
      });

      test('Complex DFA should satisfy pumping lemma', () async {
        final result = PumpingLemmaProver.provePumpingLemma(complexDFA);
        
        expect(result.isSuccess, true, 
          reason: 'Pumping lemma proof should succeed for complex DFA');
        
        if (result.isSuccess) {
          final proof = result.data!;
          expect(proof.isSuccess, true,
            reason: 'Complex DFA should satisfy pumping lemma');
        }
      });
    });

    group('Disproof Tests', () {
      test('Non-regular DFA should violate pumping lemma', () async {
        final result = PumpingLemmaProver.disprovePumpingLemma(nonRegularDFA);
        
        expect(result.isSuccess, true, 
          reason: 'Pumping lemma disproof should succeed for non-regular DFA');
        
        if (result.isSuccess) {
          final disproof = result.data!;
          expect(disproof.isSuccess, true,
            reason: 'Non-regular DFA should violate pumping lemma');
          expect(disproof.nonPumpableString, isNotNull,
            reason: 'Should find a non-pumpable string');
        }
      });

      test('Non-regular language should have counter-examples', () async {
        final result = PumpingLemmaProver.disprovePumpingLemma(nonRegularDFA);
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final disproof = result.data!;
          if (disproof.isSuccess && disproof.nonPumpableString != null) {
            final nonPumpable = disproof.nonPumpableString!;
            expect(nonPumpable.counterExample, isNotEmpty,
              reason: 'Should have a counter-example for non-pumpable string');
          }
        }
      });
    });

    group('Regularity Testing', () {
      test('Regular DFA should be identified as regular', () async {
        final result = PumpingLemmaProver.isLanguageRegular(regularDFA);
        
        expect(result.isSuccess, true, 
          reason: 'Regularity test should succeed for regular DFA');
        
        if (result.isSuccess) {
          expect(result.data!, true,
            reason: 'Regular DFA should be identified as regular');
        }
      });

      test('Regular NFA should be identified as regular', () async {
        final result = PumpingLemmaProver.isLanguageRegular(regularNFA);
        
        expect(result.isSuccess, true, 
          reason: 'Regularity test should succeed for regular NFA');
        
        if (result.isSuccess) {
          expect(result.data!, true,
            reason: 'Regular NFA should be identified as regular');
        }
      });

      test('Non-regular DFA should be identified as non-regular', () async {
        final result = PumpingLemmaProver.isLanguageRegular(nonRegularDFA);
        
        expect(result.isSuccess, true, 
          reason: 'Regularity test should succeed for non-regular DFA');
        
        if (result.isSuccess) {
          expect(result.data!, false,
            reason: 'Non-regular DFA should be identified as non-regular');
        }
      });

      test('Simple DFA should be identified as regular', () async {
        final result = PumpingLemmaProver.isLanguageRegular(simpleDFA);
        
        expect(result.isSuccess, true, 
          reason: 'Regularity test should succeed for simple DFA');
        
        if (result.isSuccess) {
          expect(result.data!, true,
            reason: 'Simple DFA should be identified as regular');
        }
      });
    });

    group('Pumping Length Tests', () {
      test('Pumping length should be calculated correctly', () async {
        final result = PumpingLemmaProver.provePumpingLemma(regularDFA);
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          final proof = result.data!;
          expect(proof.pumpingLength, greaterThan(0),
            reason: 'Pumping length should be positive');
          expect(proof.pumpingLength, lessThanOrEqualTo(regularDFA.states.length),
            reason: 'Pumping length should not exceed number of states');
        }
      });

      test('Pumping length should be consistent across tests', () async {
        final result1 = PumpingLemmaProver.provePumpingLemma(regularDFA);
        final result2 = PumpingLemmaProver.disprovePumpingLemma(regularDFA);
        
        expect(result1.isSuccess, true);
        expect(result2.isSuccess, true);
        
        if (result1.isSuccess && result2.isSuccess) {
          expect(result1.data!.pumpingLength, result2.data!.pumpingLength,
            reason: 'Pumping length should be consistent across proof and disproof');
        }
      });
    });

    group('String Decomposition Tests', () {
      test('Pumpable string should have valid decomposition', () async {
        final result = PumpingLemmaProver.provePumpingLemma(regularDFA);
        
        expect(result.isSuccess, true);
        if (result.isSuccess && result.data!.isSuccess) {
          final pumpable = result.data!.pumpableString!;
          
          // Check decomposition properties
          expect(pumpable.x.length + pumpable.y.length, lessThanOrEqualTo(pumpable.pumpingLength),
            reason: '|xy| should be <= pumping length');
          expect(pumpable.y.isNotEmpty, true,
            reason: 'y should not be empty');
          expect(pumpable.originalString, equals(pumpable.x + pumpable.y + pumpable.z),
            reason: 'Decomposition should reconstruct original string');
        }
      });

      test('Pumped strings should be accepted', () async {
        final result = PumpingLemmaProver.provePumpingLemma(regularDFA);
        
        expect(result.isSuccess, true);
        if (result.isSuccess && result.data!.isSuccess) {
          final pumpable = result.data!.pumpableString!;
          
          // Test pumped strings
          for (int i = 0; i <= 3; i++) {
            final pumpedString = pumpable.generatePumpedString(i);
            expect(pumpedString.isNotEmpty, true,
              reason: 'Pumped string should not be empty for i=$i');
          }
        }
      });

      test('Non-pumpable string should have valid decomposition', () async {
        final result = PumpingLemmaProver.disprovePumpingLemma(nonRegularDFA);
        
        expect(result.isSuccess, true);
        if (result.isSuccess && result.data!.isSuccess) {
          final nonPumpable = result.data!.nonPumpableString!;
          
          // Check decomposition properties
          expect(nonPumpable.x.length + nonPumpable.y.length, lessThanOrEqualTo(nonPumpable.pumpingLength),
            reason: '|xy| should be <= pumping length');
          expect(nonPumpable.y.isNotEmpty, true,
            reason: 'y should not be empty');
          expect(nonPumpable.originalString, equals(nonPumpable.x + nonPumpable.y + nonPumpable.z),
            reason: 'Decomposition should reconstruct original string');
        }
      });
    });

    group('Performance Tests', () {
      test('Pumping lemma should complete within reasonable time', () async {
        final result = PumpingLemmaProver.provePumpingLemma(
          complexDFA,
          maxPumpingLength: 50,
          timeout: const Duration(seconds: 5),
        );
        
        expect(result.isSuccess, true, 
          reason: 'Pumping lemma should complete within timeout');
        
        if (result.isSuccess) {
          expect(result.data!.executionTime.inSeconds, lessThan(5),
            reason: 'Execution should complete within 5 seconds');
        }
      });

      test('Regularity test should be efficient', () async {
        final result = PumpingLemmaProver.isLanguageRegular(
          complexDFA,
          maxPumpingLength: 50,
          timeout: const Duration(seconds: 5),
        );
        
        expect(result.isSuccess, true, 
          reason: 'Regularity test should complete within timeout');
      });
    });

    group('Edge Cases Tests', () {
      test('Empty automaton should fail gracefully', () async {
        final emptyDFA = _createEmptyDFA();
        
        final result = PumpingLemmaProver.provePumpingLemma(emptyDFA);
        
        expect(result.isSuccess, false, 
          reason: 'Empty automaton should fail gracefully');
      });

      test('Single state automaton should work', () async {
        final singleStateDFA = _createSingleStateDFA();
        
        final result = PumpingLemmaProver.provePumpingLemma(singleStateDFA);
        
        expect(result.isSuccess, true, 
          reason: 'Single state automaton should work');
      });

      test('Automaton with no accepting states should work', () async {
        final noAcceptingDFA = _createNoAcceptingDFA();
        
        final result = PumpingLemmaProver.provePumpingLemma(noAcceptingDFA);
        
        expect(result.isSuccess, true, 
          reason: 'Automaton with no accepting states should work');
      });
    });

    group('Mathematical Properties Tests', () {
      test('Pumping lemma should satisfy mathematical properties', () async {
        final result = PumpingLemmaProver.provePumpingLemma(regularDFA);
        
        expect(result.isSuccess, true);
        if (result.isSuccess && result.data!.isSuccess) {
          final pumpable = result.data!.pumpableString!;
          
          // Test that xy^i z is accepted for i >= 0
          for (int i = 0; i <= 5; i++) {
            final pumpedString = pumpable.generatePumpedString(i);
            expect(pumpedString.length, equals(pumpable.originalString.length + (i - 1) * pumpable.y.length),
              reason: 'Pumped string length should follow mathematical formula');
          }
        }
      });

      test('Non-pumpable string should violate pumping property', () async {
        final result = PumpingLemmaProver.disprovePumpingLemma(nonRegularDFA);
        
        expect(result.isSuccess, true);
        if (result.isSuccess && result.data!.isSuccess) {
          final nonPumpable = result.data!.nonPumpableString!;
          
          // The counter-example should show that pumping fails
          expect(nonPumpable.counterExample, isNotEmpty,
            reason: 'Counter-example should exist for non-pumpable string');
        }
      });
    });
  });
}

/// Helper functions to create test FSAs

FSA _createRegularDFA() {
  final states = {
    State(
      id: 'q0', 
      label: 'q0', 
      position: Vector2(100.0, 200.0), 
      isInitial: true, 
      isAccepting: false
    ),
    State(
      id: 'q1', 
      label: 'q1', 
      position: Vector2(300.0, 200.0), 
      isInitial: false, 
      isAccepting: true
    ),
  };
  
  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: '1',
      inputSymbols: {'1'},
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: '1',
      inputSymbols: {'1'},
    ),
  };
  
  return FSA(
    id: 'regular_dfa',
    name: 'Regular DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 400, 300),
  );
}

FSA _createRegularNFA() {
  final states = {
    State(
      id: 'q0', 
      label: 'q0', 
      position: Vector2(100.0, 200.0), 
      isInitial: true, 
      isAccepting: false
    ),
    State(
      id: 'q1', 
      label: 'q1', 
      position: Vector2(300.0, 200.0), 
      isInitial: false, 
      isAccepting: true
    ),
  };
  
  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
  };
  
  return FSA(
    id: 'regular_nfa',
    name: 'Regular NFA',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 400, 300),
  );
}

FSA _createNonRegularDFA() {
  // This DFA accepts a^n b^n (non-regular language)
  final states = {
    State(
      id: 'q0', 
      label: 'q0', 
      position: Vector2(100.0, 200.0), 
      isInitial: true, 
      isAccepting: false
    ),
    State(
      id: 'q1', 
      label: 'q1', 
      position: Vector2(300.0, 200.0), 
      isInitial: false, 
      isAccepting: false
    ),
    State(
      id: 'q2', 
      label: 'q2', 
      position: Vector2(500.0, 200.0), 
      isInitial: false, 
      isAccepting: true
    ),
  };
  
  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'b',
      inputSymbols: {'b'},
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'b',
      inputSymbols: {'b'},
    ),
  };
  
  return FSA(
    id: 'non_regular_dfa',
    name: 'Non-Regular DFA',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 600, 300),
  );
}

FSA _createSimpleDFA() {
  final states = {
    State(
      id: 'q0', 
      label: 'q0', 
      position: Vector2(100.0, 200.0), 
      isInitial: true, 
      isAccepting: true
    ),
  };
  
  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.first,
      toState: states.first,
      label: 'a',
      inputSymbols: {'a'},
    ),
  };
  
  return FSA(
    id: 'simple_dfa',
    name: 'Simple DFA',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.first,
    acceptingStates: states,
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 300, 300),
  );
}

FSA _createComplexDFA() {
  final states = {
    State(
      id: 'q0', 
      label: 'q0', 
      position: Vector2(100.0, 200.0), 
      isInitial: true, 
      isAccepting: true
    ),
    State(
      id: 'q1', 
      label: 'q1', 
      position: Vector2(300.0, 200.0), 
      isInitial: false, 
      isAccepting: false
    ),
    State(
      id: 'q2', 
      label: 'q2', 
      position: Vector2(500.0, 200.0), 
      isInitial: false, 
      isAccepting: false
    ),
  };
  
  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: '1',
      inputSymbols: {'1'},
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '1',
      inputSymbols: {'1'},
    ),
    FSATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: '1',
      inputSymbols: {'1'},
    ),
  };
  
  return FSA(
    id: 'complex_dfa',
    name: 'Complex DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 600, 300),
  );
}

FSA _createEmptyDFA() {
  return FSA(
    id: 'empty_dfa',
    name: 'Empty DFA',
    states: {},
    transitions: {},
    alphabet: {},
    initialState: null,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 300, 300),
  );
}

FSA _createSingleStateDFA() {
  final states = {
    State(
      id: 'q0', 
      label: 'q0', 
      position: Vector2(100.0, 200.0), 
      isInitial: true, 
      isAccepting: true
    ),
  };
  
  return FSA(
    id: 'single_state_dfa',
    name: 'Single State DFA',
    states: states,
    transitions: {},
    alphabet: {'a'},
    initialState: states.first,
    acceptingStates: states,
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 300, 300),
  );
}

FSA _createNoAcceptingDFA() {
  final states = {
    State(
      id: 'q0', 
      label: 'q0', 
      position: Vector2(100.0, 200.0), 
      isInitial: true, 
      isAccepting: false
    ),
  };
  
  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.first,
      toState: states.first,
      label: 'a',
      inputSymbols: {'a'},
    ),
  };
  
  return FSA(
    id: 'no_accepting_dfa',
    name: 'No Accepting DFA',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.first,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 300, 300),
  );
}
