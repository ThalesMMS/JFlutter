//
//  dfa_minimization_validation_test.dart
//  JFlutter
//
//  Testes que verificam o algoritmo de minimização de DFAs assegurando redução correta de estados sem alterar a linguagem reconhecida.
//  Englobam autômatos básicos, estruturas redundantes, casos já minimizados e máquinas sem estados de aceitação para checar diagnósticos.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/algorithms/dfa_minimizer.dart';
import 'dart:math' as math;
import 'package:jflutter/core/algorithms/automaton_simulator.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('DFA Minimization Validation Tests', () {
    late FSA basicDFA;
    late FSA complexDFA;
    late FSA minimalDFA;
    late FSA noFinalStatesDFA;
    late FSA redundantStatesDFA;

    setUp(() {
      // Test Case 1: Basic DFA
      basicDFA = _createBasicDFA();

      // Test Case 2: Complex DFA with redundant states
      complexDFA = _createComplexDFA();

      // Test Case 3: Already minimal DFA
      minimalDFA = _createMinimalDFA();

      // Test Case 4: DFA with no final states
      noFinalStatesDFA = _createNoFinalStatesDFA();

      // Test Case 5: DFA with redundant states
      redundantStatesDFA = _createRedundantStatesDFA();
    });

    group('Basic DFA Minimization Tests', () {
      test('Basic DFA should minimize correctly', () async {
        final minimizationResult = DFAMinimizer.minimize(basicDFA);

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'Basic DFA minimization should succeed',
        );

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test that minimized DFA has correct structure
          expect(
            minimizedDFA.states.isNotEmpty,
            true,
            reason: 'Minimized DFA should have states',
          );
          expect(
            minimizedDFA.initialState,
            isNotNull,
            reason: 'Minimized DFA should have initial state',
          );
          expect(
            minimizedDFA.acceptingStates.isNotEmpty,
            true,
            reason: 'Minimized DFA should have accepting states',
          );

          // Test equivalence with original DFA
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
            final originalResult = await AutomatonSimulator.simulate(
              basicDFA,
              testString,
            );
            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(
              originalResult.isSuccess,
              true,
              reason:
                  'Original DFA simulation should succeed for "$testString"',
            );
            expect(
              minimizedResult.isSuccess,
              true,
              reason:
                  'Minimized DFA simulation should succeed for "$testString"',
            );

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Original and minimized DFA should have same acceptance for "$testString"',
              );
            }
          }
        }
      });

      test('Basic DFA minimization should reduce state count', () async {
        final minimizationResult = DFAMinimizer.minimize(basicDFA);

        expect(minimizationResult.isSuccess, true);

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Minimized DFA should have fewer or equal states
          expect(
            minimizedDFA.states.length,
            lessThanOrEqualTo(basicDFA.states.length),
            reason: 'Minimized DFA should have fewer or equal states',
          );
        }
      });
    });

    group('Complex DFA Minimization Tests', () {
      test('Complex DFA should minimize correctly', () async {
        final minimizationResult = DFAMinimizer.minimize(complexDFA);

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'Complex DFA minimization should succeed',
        );

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test equivalence with original DFA
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
            '100',
            '101',
            '110',
            '111',
          ];
          for (final testString in testStrings) {
            final originalResult = await AutomatonSimulator.simulate(
              complexDFA,
              testString,
            );
            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(
              originalResult.isSuccess,
              true,
              reason:
                  'Original DFA simulation should succeed for "$testString"',
            );
            expect(
              minimizedResult.isSuccess,
              true,
              reason:
                  'Minimized DFA simulation should succeed for "$testString"',
            );

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Original and minimized DFA should have same acceptance for "$testString"',
              );
            }
          }
        }
      });

      test(
        'Complex DFA minimization should significantly reduce state count',
        () async {
          final minimizationResult = DFAMinimizer.minimize(complexDFA);

          expect(minimizationResult.isSuccess, true);

          if (minimizationResult.isSuccess) {
            final minimizedDFA = minimizationResult.data!;

            // Complex DFA should have significantly fewer states after minimization
            expect(
              minimizedDFA.states.length,
              lessThan(complexDFA.states.length),
              reason: 'Complex DFA should have fewer states after minimization',
            );
          }
        },
      );
    });

    group('Already Minimal DFA Tests', () {
      test('Already minimal DFA should remain equivalent', () async {
        final minimizationResult = DFAMinimizer.minimize(minimalDFA);

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'Minimal DFA minimization should succeed',
        );

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test equivalence with original DFA
          final testStrings = ['0', '1', '00', '01', '10', '11'];
          for (final testString in testStrings) {
            final originalResult = await AutomatonSimulator.simulate(
              minimalDFA,
              testString,
            );
            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(
              originalResult.isSuccess,
              true,
              reason:
                  'Original DFA simulation should succeed for "$testString"',
            );
            expect(
              minimizedResult.isSuccess,
              true,
              reason:
                  'Minimized DFA simulation should succeed for "$testString"',
            );

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Original and minimized DFA should have same acceptance for "$testString"',
              );
            }
          }
        }
      });

      test('Already minimal DFA should have same state count', () async {
        final minimizationResult = DFAMinimizer.minimize(minimalDFA);

        expect(minimizationResult.isSuccess, true);

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Already minimal DFA should have same number of states
          expect(
            minimizedDFA.states.length,
            equals(minimalDFA.states.length),
            reason: 'Already minimal DFA should have same state count',
          );
        }
      });
    });

    group('No Final States DFA Tests', () {
      test('DFA with no final states should minimize correctly', () async {
        final minimizationResult = DFAMinimizer.minimize(noFinalStatesDFA);

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'No final states DFA minimization should succeed',
        );

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test equivalence with original DFA
          final testStrings = ['0', '1', '00', '01', '10', '11'];
          for (final testString in testStrings) {
            final originalResult = await AutomatonSimulator.simulate(
              noFinalStatesDFA,
              testString,
            );
            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(
              originalResult.isSuccess,
              true,
              reason:
                  'Original DFA simulation should succeed for "$testString"',
            );
            expect(
              minimizedResult.isSuccess,
              true,
              reason:
                  'Minimized DFA simulation should succeed for "$testString"',
            );

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Original and minimized DFA should have same acceptance for "$testString"',
              );
            }
          }
        }
      });

      test(
        'DFA with no final states should have no accepting states after minimization',
        () async {
          final minimizationResult = DFAMinimizer.minimize(noFinalStatesDFA);

          expect(minimizationResult.isSuccess, true);

          if (minimizationResult.isSuccess) {
            final minimizedDFA = minimizationResult.data!;

            // DFA with no final states should have no accepting states
            expect(
              minimizedDFA.acceptingStates.isEmpty,
              true,
              reason:
                  'DFA with no final states should have no accepting states after minimization',
            );
          }
        },
      );
    });

    group('Redundant States DFA Tests', () {
      test('DFA with redundant states should minimize correctly', () async {
        final minimizationResult = DFAMinimizer.minimize(redundantStatesDFA);

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'Redundant states DFA minimization should succeed',
        );

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test equivalence with original DFA
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
            final originalResult = await AutomatonSimulator.simulate(
              redundantStatesDFA,
              testString,
            );
            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(
              originalResult.isSuccess,
              true,
              reason:
                  'Original DFA simulation should succeed for "$testString"',
            );
            expect(
              minimizedResult.isSuccess,
              true,
              reason:
                  'Minimized DFA simulation should succeed for "$testString"',
            );

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Original and minimized DFA should have same acceptance for "$testString"',
              );
            }
          }
        }
      });

      test(
        'DFA with redundant states should significantly reduce state count',
        () async {
          final minimizationResult = DFAMinimizer.minimize(redundantStatesDFA);

          expect(minimizationResult.isSuccess, true);

          if (minimizationResult.isSuccess) {
            final minimizedDFA = minimizationResult.data!;

            // DFA with redundant states should have significantly fewer states
            expect(
              minimizedDFA.states.length,
              lessThan(redundantStatesDFA.states.length),
              reason:
                  'DFA with redundant states should have fewer states after minimization',
            );
          }
        },
      );
    });

    group('Equivalence Testing', () {
      test('Minimized DFA should be equivalent to original DFA', () async {
        final testCases = [
          (basicDFA, 'Basic DFA'),
          (complexDFA, 'Complex DFA'),
          (minimalDFA, 'Minimal DFA'),
          (noFinalStatesDFA, 'No Final States DFA'),
          (redundantStatesDFA, 'Redundant States DFA'),
        ];

        for (final (dfa, description) in testCases) {
          final minimizationResult = DFAMinimizer.minimize(dfa);

          expect(
            minimizationResult.isSuccess,
            true,
            reason: '$description minimization should succeed',
          );

          if (minimizationResult.isSuccess) {
            final minimizedDFA = minimizationResult.data!;

            // Test with various strings
            final testStrings = [
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
            ];

            for (final testString in testStrings) {
              final originalResult = await AutomatonSimulator.simulate(
                dfa,
                testString,
              );
              final minimizedResult = await AutomatonSimulator.simulate(
                minimizedDFA,
                testString,
              );

              expect(
                originalResult.isSuccess,
                true,
                reason:
                    'Original DFA simulation should succeed for "$testString" in $description',
              );
              expect(
                minimizedResult.isSuccess,
                true,
                reason:
                    'Minimized DFA simulation should succeed for "$testString" in $description',
              );

              if (originalResult.isSuccess && minimizedResult.isSuccess) {
                expect(
                  originalResult.data!.accepted,
                  minimizedResult.data!.accepted,
                  reason:
                      'Original and minimized DFA should have same acceptance for "$testString" in $description',
                );
              }
            }
          }
        }
      });

      test('Minimized DFA should handle edge cases', () async {
        final minimizationResult = DFAMinimizer.minimize(basicDFA);

        expect(minimizationResult.isSuccess, true);

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test with edge case strings
          final edgeCases = ['', '0', '1', '00', '01', '10', '11'];

          for (final testString in edgeCases) {
            final originalResult = await AutomatonSimulator.simulate(
              basicDFA,
              testString,
            );
            final minimizedResult = await AutomatonSimulator.simulate(
              minimizedDFA,
              testString,
            );

            expect(
              originalResult.isSuccess,
              true,
              reason:
                  'Original DFA simulation should succeed for edge case "$testString"',
            );
            expect(
              minimizedResult.isSuccess,
              true,
              reason:
                  'Minimized DFA simulation should succeed for edge case "$testString"',
            );

            if (originalResult.isSuccess && minimizedResult.isSuccess) {
              expect(
                originalResult.data!.accepted,
                minimizedResult.data!.accepted,
                reason:
                    'Original and minimized DFA should have same acceptance for edge case "$testString"',
              );
            }
          }
        }
      });
    });

    group('Performance Tests', () {
      test('DFA minimization should complete within reasonable time', () async {
        final stopwatch = Stopwatch()..start();

        final minimizationResult = DFAMinimizer.minimize(complexDFA);

        stopwatch.stop();

        expect(
          minimizationResult.isSuccess,
          true,
          reason: 'Complex DFA minimization should succeed',
        );
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
          reason: 'DFA minimization should complete within 1 second',
        );
      });

      test('Minimized DFA should handle long strings efficiently', () async {
        final minimizationResult = DFAMinimizer.minimize(complexDFA);

        expect(minimizationResult.isSuccess, true);

        if (minimizationResult.isSuccess) {
          final minimizedDFA = minimizationResult.data!;

          // Test with longer strings
          final longString = '01' * 10; // 20 characters

          final stopwatch = Stopwatch()..start();
          final result = await AutomatonSimulator.simulate(
            minimizedDFA,
            longString,
          );
          stopwatch.stop();

          expect(
            result.isSuccess,
            true,
            reason: 'Minimized DFA simulation should succeed for long string',
          );
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(1000),
            reason: 'Minimized DFA simulation should complete within 1 second',
          );
        }
      });
    });

    group('Error Handling Tests', () {
      test('Empty DFA should fail minimization', () async {
        final emptyDFA = _createEmptyDFA();

        final minimizationResult = DFAMinimizer.minimize(emptyDFA);

        expect(
          minimizationResult.isSuccess,
          false,
          reason: 'Empty DFA minimization should fail',
        );
      });

      test('DFA without initial state should fail minimization', () async {
        final noInitialDFA = _createNoInitialDFA();

        final minimizationResult = DFAMinimizer.minimize(noInitialDFA);

        expect(
          minimizationResult.isSuccess,
          false,
          reason: 'DFA without initial state minimization should fail',
        );
      });
    });
  });
}

/// Helper functions to create test DFAs

FSA _createBasicDFA() {
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

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '1',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '1',
    ),
    FSATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '0',
    ),
    FSATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'basic_dfa',
    name: 'Basic DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q2')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 300, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createComplexDFA() {
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
      isAccepting: false,
    ),
    State(
      id: 'q3',
      label: 'q3',
      position: Vector2(300, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q4',
      label: 'q4',
      position: Vector2(400, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q5',
      label: 'q5',
      position: Vector2(500, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '1',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q4'),
      symbol: '1',
    ),
    FSATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      symbol: '0',
    ),
    FSATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q4'),
      symbol: '1',
    ),
    FSATransition(
      id: 't7',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '0',
    ),
    FSATransition(
      id: 't8',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '1',
    ),
    FSATransition(
      id: 't9',
      fromState: states.firstWhere((s) => s.id == 'q4'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '0',
    ),
    FSATransition(
      id: 't10',
      fromState: states.firstWhere((s) => s.id == 'q4'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '1',
    ),
    FSATransition(
      id: 't11',
      fromState: states.firstWhere((s) => s.id == 'q5'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '0',
    ),
    FSATransition(
      id: 't12',
      fromState: states.firstWhere((s) => s.id == 'q5'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'complex_dfa',
    name: 'Complex DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q5')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createMinimalDFA() {
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
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '1',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      symbol: '0',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'minimal_dfa',
    name: 'Minimal DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createNoFinalStatesDFA() {
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
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '1',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'no_final_states_dfa',
    name: 'No Final States DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createRedundantStatesDFA() {
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
      isAccepting: false,
    ),
    State(
      id: 'q3',
      label: 'q3',
      position: Vector2(300, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q4',
      label: 'q4',
      position: Vector2(400, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q5',
      label: 'q5',
      position: Vector2(500, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q6',
      label: 'q6',
      position: Vector2(600, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q7',
      label: 'q7',
      position: Vector2(700, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '1',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q4'),
      symbol: '1',
    ),
    FSATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      symbol: '0',
    ),
    FSATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q4'),
      symbol: '1',
    ),
    FSATransition(
      id: 't7',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '0',
    ),
    FSATransition(
      id: 't8',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q6'),
      symbol: '1',
    ),
    FSATransition(
      id: 't9',
      fromState: states.firstWhere((s) => s.id == 'q4'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '0',
    ),
    FSATransition(
      id: 't10',
      fromState: states.firstWhere((s) => s.id == 'q4'),
      toState: states.firstWhere((s) => s.id == 'q6'),
      symbol: '1',
    ),
    FSATransition(
      id: 't11',
      fromState: states.firstWhere((s) => s.id == 'q5'),
      toState: states.firstWhere((s) => s.id == 'q7'),
      symbol: '0',
    ),
    FSATransition(
      id: 't12',
      fromState: states.firstWhere((s) => s.id == 'q5'),
      toState: states.firstWhere((s) => s.id == 'q7'),
      symbol: '1',
    ),
    FSATransition(
      id: 't13',
      fromState: states.firstWhere((s) => s.id == 'q6'),
      toState: states.firstWhere((s) => s.id == 'q7'),
      symbol: '0',
    ),
    FSATransition(
      id: 't14',
      fromState: states.firstWhere((s) => s.id == 'q6'),
      toState: states.firstWhere((s) => s.id == 'q7'),
      symbol: '1',
    ),
    FSATransition(
      id: 't15',
      fromState: states.firstWhere((s) => s.id == 'q7'),
      toState: states.firstWhere((s) => s.id == 'q7'),
      symbol: '0',
    ),
    FSATransition(
      id: 't16',
      fromState: states.firstWhere((s) => s.id == 'q7'),
      toState: states.firstWhere((s) => s.id == 'q7'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'redundant_states_dfa',
    name: 'Redundant States DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q7')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 800, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
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
    bounds: const math.Rectangle(0, 0, 0, 0),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createNoInitialDFA() {
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
    id: 'no_initial_dfa',
    name: 'No Initial DFA',
    states: states,
    transitions: {},
    alphabet: {'a'},
    initialState: null,
    acceptingStates: {states.firstWhere((s) => s.id == 'q1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}
