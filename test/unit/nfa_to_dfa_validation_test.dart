// ============================================================================
// JFlutter - Suite de Testes
// ----------------------------------------------------------------------------
// Arquivo: test/unit/nfa_to_dfa_validation_test.dart
// Objetivo: Confirmar que a conversão de AFN para AFD mantém a linguagem e
// reproduz os resultados da implementação de referência.
// Cenários cobertos:
// - Casos simples e complexos de conversão com múltiplos estados.
// - Tratamento de transições λ, inclusive a partir do estado inicial.
// - Verificação de equivalência entre o AFN original e o AFD convertido.
// Autoria: Equipe de Qualidade JFlutter — baseado em
// References/automata-main/tests/test_dfa.py.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/algorithms/nfa_to_dfa_converter.dart';
import 'package:jflutter/core/algorithms/automaton_simulator.dart';
import 'package:jflutter/core/result.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;
void main() {
  group('NFA to DFA Conversion Validation Tests', () {
    late FSA simpleNFA;
    late FSA complexNFA;
    late FSA lambdaNFA;
    late FSA lambdaInitialNFA;
    late FSA epsilonNFA;

    setUp(() {
      // Test Case 1: Simple NFA
      simpleNFA = _createSimpleNFA();

      // Test Case 2: Complex NFA
      complexNFA = _createComplexNFA();

      // Test Case 3: NFA with lambda transitions
      lambdaNFA = _createLambdaNFA();

      // Test Case 4: NFA with lambda transitions from initial state
      lambdaInitialNFA = _createLambdaInitialNFA();

      // Test Case 5: NFA with epsilon transitions
      epsilonNFA = _createEpsilonNFA();
    });

    group('Simple NFA to DFA Conversion Tests', () {
      test('Simple NFA should convert to equivalent DFA', () async {
        final conversionResult = NFAToDFAConverter.convert(simpleNFA);

        expect(
          conversionResult.isSuccess,
          true,
          reason: 'Simple NFA conversion should succeed',
        );

        if (conversionResult.isSuccess) {
          final dfa = conversionResult.data!;

          // Test that DFA has correct structure
          expect(
            dfa.states.isNotEmpty,
            true,
            reason: 'Converted DFA should have states',
          );
          expect(
            dfa.initialState,
            isNotNull,
            reason: 'Converted DFA should have initial state',
          );
          expect(
            dfa.acceptingStates.isNotEmpty,
            true,
            reason: 'Converted DFA should have accepting states',
          );

          // Test equivalence with test strings
          final testStrings = ['0', '01', '001', '0001'];
          for (final testString in testStrings) {
            final nfaResult = await AutomatonSimulator.simulateNFA(
              simpleNFA,
              testString,
            );
            final dfaResult = await AutomatonSimulator.simulate(
              dfa,
              testString,
            );

            expect(
              nfaResult.isSuccess,
              true,
              reason: 'NFA simulation should succeed for "$testString"',
            );
            expect(
              dfaResult.isSuccess,
              true,
              reason: 'DFA simulation should succeed for "$testString"',
            );

            if (nfaResult.isSuccess && dfaResult.isSuccess) {
              expect(
                nfaResult.data!.accepted,
                dfaResult.data!.accepted,
                reason:
                    'NFA and DFA should have same acceptance for "$testString"',
              );
            }
          }
        }
      });

      test('Simple NFA conversion should handle empty string', () async {
        final conversionResult = NFAToDFAConverter.convert(simpleNFA);

        expect(conversionResult.isSuccess, true);

        if (conversionResult.isSuccess) {
          final dfa = conversionResult.data!;

          final nfaResult = await AutomatonSimulator.simulateNFA(simpleNFA, '');
          final dfaResult = await AutomatonSimulator.simulate(dfa, '');

          expect(nfaResult.isSuccess, true);
          expect(dfaResult.isSuccess, true);

          if (nfaResult.isSuccess && dfaResult.isSuccess) {
            expect(
              nfaResult.data!.accepted,
              dfaResult.data!.accepted,
              reason:
                  'NFA and DFA should have same acceptance for empty string',
            );
          }
        }
      });
    });

    group('Complex NFA to DFA Conversion Tests', () {
      test('Complex NFA should convert to equivalent DFA', () async {
        final conversionResult = NFAToDFAConverter.convert(complexNFA);

        expect(
          conversionResult.isSuccess,
          true,
          reason: 'Complex NFA conversion should succeed',
        );

        if (conversionResult.isSuccess) {
          final dfa = conversionResult.data!;

          // Test that DFA has correct structure
          expect(
            dfa.states.isNotEmpty,
            true,
            reason: 'Converted DFA should have states',
          );
          expect(
            dfa.initialState,
            isNotNull,
            reason: 'Converted DFA should have initial state',
          );

          // Test equivalence with test strings
          final testStrings = [
            '0',
            '1',
            '00',
            '01',
            '10',
            '11',
            '000',
            '001',
            '010',
            '011',
          ];
          for (final testString in testStrings) {
            final nfaResult = await AutomatonSimulator.simulateNFA(
              complexNFA,
              testString,
            );
            final dfaResult = await AutomatonSimulator.simulate(
              dfa,
              testString,
            );

            expect(
              nfaResult.isSuccess,
              true,
              reason: 'NFA simulation should succeed for "$testString"',
            );
            expect(
              dfaResult.isSuccess,
              true,
              reason: 'DFA simulation should succeed for "$testString"',
            );

            if (nfaResult.isSuccess && dfaResult.isSuccess) {
              expect(
                nfaResult.data!.accepted,
                dfaResult.data!.accepted,
                reason:
                    'NFA and DFA should have same acceptance for "$testString"',
              );
            }
          }
        }
      });

      test('Complex NFA conversion should handle multiple transitions', () async {
        final conversionResult = NFAToDFAConverter.convert(complexNFA);

        expect(conversionResult.isSuccess, true);

        if (conversionResult.isSuccess) {
          final dfa = conversionResult.data!;

          // Test that DFA has more states than original NFA (subset construction)
          expect(
            dfa.states.length,
            greaterThan(complexNFA.states.length),
            reason: 'DFA should have more states due to subset construction',
          );
        }
      });
    });

    group('Lambda Transition NFA to DFA Conversion Tests', () {
      test(
        'NFA with lambda transitions should convert to equivalent DFA',
        () async {
          final conversionResult = NFAToDFAConverter.convert(lambdaNFA);

          expect(
            conversionResult.isSuccess,
            true,
            reason: 'Lambda NFA conversion should succeed',
          );

          if (conversionResult.isSuccess) {
            final dfa = conversionResult.data!;

            // Test equivalence with test strings
            final testStrings = ['', 'a', 'b', 'ab', 'ba', 'aab', 'abb'];
            for (final testString in testStrings) {
              final nfaResult = await AutomatonSimulator.simulateNFA(
                lambdaNFA,
                testString,
              );
              final dfaResult = await AutomatonSimulator.simulate(
                dfa,
                testString,
              );

              expect(
                nfaResult.isSuccess,
                true,
                reason: 'NFA simulation should succeed for "$testString"',
              );
              expect(
                dfaResult.isSuccess,
                true,
                reason: 'DFA simulation should succeed for "$testString"',
              );

              if (nfaResult.isSuccess && dfaResult.isSuccess) {
                expect(
                  nfaResult.data!.accepted,
                  dfaResult.data!.accepted,
                  reason:
                      'NFA and DFA should have same acceptance for "$testString"',
                );
              }
            }
          }
        },
      );

      test(
        'NFA with lambda transitions from initial state should convert correctly',
        () async {
          final conversionResult = NFAToDFAConverter.convert(lambdaInitialNFA);

          expect(
            conversionResult.isSuccess,
            true,
            reason: 'Lambda initial NFA conversion should succeed',
          );

          if (conversionResult.isSuccess) {
            final dfa = conversionResult.data!;

            // Test that initial state includes states reachable via lambda transitions
            expect(
              dfa.initialState,
              isNotNull,
              reason: 'Converted DFA should have initial state',
            );

            // Test equivalence with test strings
            final testStrings = ['', 'a', 'b', 'ab', 'ba'];
            for (final testString in testStrings) {
              final nfaResult = await AutomatonSimulator.simulateNFA(
                lambdaInitialNFA,
                testString,
              );
              final dfaResult = await AutomatonSimulator.simulate(
                dfa,
                testString,
              );

              expect(
                nfaResult.isSuccess,
                true,
                reason: 'NFA simulation should succeed for "$testString"',
              );
              expect(
                dfaResult.isSuccess,
                true,
                reason: 'DFA simulation should succeed for "$testString"',
              );

              if (nfaResult.isSuccess && dfaResult.isSuccess) {
                expect(
                  nfaResult.data!.accepted,
                  dfaResult.data!.accepted,
                  reason:
                      'NFA and DFA should have same acceptance for "$testString"',
                );
              }
            }
          }
        },
      );
    });

    group('Epsilon Transition NFA to DFA Conversion Tests', () {
      test(
        'NFA with epsilon transitions should convert to equivalent DFA',
        () async {
          final conversionResult = NFAToDFAConverter.convert(epsilonNFA);

          expect(
            conversionResult.isSuccess,
            true,
            reason: 'Epsilon NFA conversion should succeed',
          );

          if (conversionResult.isSuccess) {
            final dfa = conversionResult.data!;

            // Test equivalence with test strings
            final testStrings = ['', 'a', 'b', 'ab', 'ba', 'aab', 'abb'];
            for (final testString in testStrings) {
              final nfaResult = await AutomatonSimulator.simulateNFA(
                epsilonNFA,
                testString,
              );
              final dfaResult = await AutomatonSimulator.simulate(
                dfa,
                testString,
              );

              expect(
                nfaResult.isSuccess,
                true,
                reason: 'NFA simulation should succeed for "$testString"',
              );
              expect(
                dfaResult.isSuccess,
                true,
                reason: 'DFA simulation should succeed for "$testString"',
              );

              if (nfaResult.isSuccess && dfaResult.isSuccess) {
                expect(
                  nfaResult.data!.accepted,
                  dfaResult.data!.accepted,
                  reason:
                      'NFA and DFA should have same acceptance for "$testString"',
                );
              }
            }
          }
        },
      );

      test(
        'Epsilon NFA conversion should remove epsilon transitions',
        () async {
          final conversionResult = NFAToDFAConverter.convert(epsilonNFA);

          expect(conversionResult.isSuccess, true);

          if (conversionResult.isSuccess) {
            final dfa = conversionResult.data!;

            // Check that DFA has no epsilon transitions
            for (final transition in dfa.transitions) {
              expect(
                transition.symbol,
                isNot(equals('')),
                reason: 'DFA should not have epsilon transitions',
              );
              expect(
                transition.symbol,
                isNot(equals('ε')),
                reason: 'DFA should not have epsilon transitions',
              );
            }
          }
        },
      );
    });

    group('Equivalence Testing', () {
      test('Converted DFA should be equivalent to original NFA', () async {
        final testCases = [
          (simpleNFA, 'Simple NFA'),
          (complexNFA, 'Complex NFA'),
          (lambdaNFA, 'Lambda NFA'),
          (lambdaInitialNFA, 'Lambda Initial NFA'),
          (epsilonNFA, 'Epsilon NFA'),
        ];

        for (final (nfa, description) in testCases) {
          final conversionResult = NFAToDFAConverter.convert(nfa);

          expect(
            conversionResult.isSuccess,
            true,
            reason: '$description conversion should succeed',
          );

          if (conversionResult.isSuccess) {
            final dfa = conversionResult.data!;

            // Test with various strings appropriate for each NFA's alphabet
            final testStrings = nfa.alphabet.contains('0')
                ? [
                    '',
                    '0',
                    '1',
                    '00',
                    '01',
                    '10',
                    '11',
                    '000',
                    '001',
                    '010',
                    '011',
                    '100',
                    '101',
                    '110',
                    '111',
                  ]
                : [
                    '',
                    'a',
                    'b',
                    'aa',
                    'ab',
                    'ba',
                    'bb',
                    'aaa',
                    'aab',
                    'aba',
                    'abb',
                    'baa',
                    'bab',
                    'bba',
                    'bbb',
                  ];

            for (final testString in testStrings) {
              final nfaResult = await AutomatonSimulator.simulateNFA(
                nfa,
                testString,
              );
              final dfaResult = await AutomatonSimulator.simulate(
                dfa,
                testString,
              );

              expect(
                nfaResult.isSuccess,
                true,
                reason:
                    'NFA simulation should succeed for "$testString" in $description',
              );
              expect(
                dfaResult.isSuccess,
                true,
                reason:
                    'DFA simulation should succeed for "$testString" in $description',
              );

              if (nfaResult.isSuccess && dfaResult.isSuccess) {
                expect(
                  nfaResult.data!.accepted,
                  dfaResult.data!.accepted,
                  reason:
                      'NFA and DFA should have same acceptance for "$testString" in $description',
                );
              }
            }
          }
        }
      });

      test('Converted DFA should handle edge cases', () async {
        final conversionResult = NFAToDFAConverter.convert(simpleNFA);

        expect(conversionResult.isSuccess, true);

        if (conversionResult.isSuccess) {
          final dfa = conversionResult.data!;

          // Test with edge case strings
          final edgeCases = ['', '0', '1', '00', '01', '10', '11'];

          for (final testString in edgeCases) {
            final nfaResult = await AutomatonSimulator.simulateNFA(
              simpleNFA,
              testString,
            );
            final dfaResult = await AutomatonSimulator.simulate(
              dfa,
              testString,
            );

            expect(
              nfaResult.isSuccess,
              true,
              reason:
                  'NFA simulation should succeed for edge case "$testString"',
            );
            expect(
              dfaResult.isSuccess,
              true,
              reason:
                  'DFA simulation should succeed for edge case "$testString"',
            );

            if (nfaResult.isSuccess && dfaResult.isSuccess) {
              expect(
                nfaResult.data!.accepted,
                dfaResult.data!.accepted,
                reason:
                    'NFA and DFA should have same acceptance for edge case "$testString"',
              );
            }
          }
        }
      });
    });

    group('Performance Tests', () {
      test(
        'NFA to DFA conversion should complete within reasonable time',
        () async {
          final stopwatch = Stopwatch()..start();

          final conversionResult = NFAToDFAConverter.convert(complexNFA);

          stopwatch.stop();

          expect(
            conversionResult.isSuccess,
            true,
            reason: 'Complex NFA conversion should succeed',
          );
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(1000),
            reason: 'NFA to DFA conversion should complete within 1 second',
          );
        },
      );

      test('Converted DFA should handle long strings efficiently', () async {
        final conversionResult = NFAToDFAConverter.convert(complexNFA);

        expect(conversionResult.isSuccess, true);

        if (conversionResult.isSuccess) {
          final dfa = conversionResult.data!;

          // Test with longer strings
          final longString = '01' * 10; // 20 characters

          final stopwatch = Stopwatch()..start();
          final result = await AutomatonSimulator.simulate(dfa, longString);
          stopwatch.stop();

          expect(
            result.isSuccess,
            true,
            reason: 'DFA simulation should succeed for long string',
          );
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(1000),
            reason: 'DFA simulation should complete within 1 second',
          );
        }
      });
    });

    group('Error Handling Tests', () {
      test('Empty NFA should fail conversion', () async {
        final emptyNFA = _createEmptyNFA();

        final conversionResult = NFAToDFAConverter.convert(emptyNFA);

        expect(
          conversionResult.isSuccess,
          false,
          reason: 'Empty NFA conversion should fail',
        );
      });

      test('NFA without initial state should fail conversion', () async {
        final noInitialNFA = _createNoInitialNFA();

        final conversionResult = NFAToDFAConverter.convert(noInitialNFA);

        expect(
          conversionResult.isSuccess,
          false,
          reason: 'NFA without initial state conversion should fail',
        );
      });
    });
  });
}

/// Helper functions to create test NFAs

FSA _createSimpleNFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(200, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = <FSATransition>{
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
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: '1',
      inputSymbols: {'1'},
    ),
  };

  return FSA(
    id: 'simple_nfa',
    name: 'Simple NFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q2')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 300, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createComplexNFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(200, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = <FSATransition>{
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
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: '1',
      inputSymbols: {'1'},
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: '0',
      inputSymbols: {'0'},
    ),
    FSATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: '1',
      inputSymbols: {'1'},
    ),
  };

  return FSA(
    id: 'complex_nfa',
    name: 'Complex NFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q2')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 300, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createLambdaNFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(200, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = <FSATransition>{
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε',
      inputSymbols: {},
      lambdaSymbol: 'ε',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'b',
      inputSymbols: {'b'},
    ),
  };

  return FSA(
    id: 'lambda_nfa',
    name: 'Lambda NFA',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q2')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 300, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createLambdaInitialNFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(200, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = <FSATransition>{
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: '',
      inputSymbols: {''},
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
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a',
      inputSymbols: {'a'},
    ),
  };

  return FSA(
    id: 'lambda_initial_nfa',
    name: 'Lambda Initial NFA',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 300, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createEpsilonNFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(200, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = <FSATransition>{
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε',
      inputSymbols: {'ε'},
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'a',
      inputSymbols: {'a'},
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'b',
      inputSymbols: {'b'},
    ),
  };

  return FSA(
    id: 'epsilon_nfa',
    name: 'Epsilon NFA',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q2')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 300, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createEmptyNFA() {
  return FSA(
    id: 'empty_nfa',
    name: 'Empty NFA',
    states: {},
    transitions: {},
    alphabet: {},
    initialState: null,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 0, 0),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createNoInitialNFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  return FSA(
    id: 'no_initial_nfa',
    name: 'No Initial NFA',
    states: states,
    transitions: {},
    alphabet: {'a'},
    initialState: null,
    acceptingStates: {states.firstWhere((s) => s.id == 'q1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}
