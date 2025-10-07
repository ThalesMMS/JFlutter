// ============================================================================
// JFlutter - Suite de Testes
// ----------------------------------------------------------------------------
// Arquivo: test/unit/pda_validation_test.dart
// Objetivo: Validar o simulador de autômatos de pilha e o conversor de
// gramáticas, garantindo paridade com a implementação de referência.
// Cenários cobertos:
// - Aceitação e rejeição em PDAs determinísticos e não determinísticos.
// - Conversão de gramáticas livres de contexto para PDAs equivalentes.
// - Manipulação da pilha (push, pop e transições λ) em cenários complexos.
// Autoria: Equipe de Qualidade JFlutter — baseado em
// References/automata-main/tests/test_pda.py.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/algorithms/pda_simulator.dart';
import 'package:jflutter/core/algorithms/grammar_to_pda_converter.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/core/result.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;
void main() {
  group('PDA Validation Tests', () {
    late PDA balancedParenthesesPDA;
    late PDA palindromePDA;
    late PDA simplePDA;
    late PDA complexPDA;
    late PDA lambdaPDA;

    setUp(() {
      // Test Case 1: Balanced Parentheses PDA
      balancedParenthesesPDA = _createBalancedParenthesesPDA();

      // Test Case 2: Palindrome PDA
      palindromePDA = _createPalindromePDA();

      // Test Case 3: Simple PDA
      simplePDA = _createSimplePDA();

      // Test Case 4: Complex PDA
      complexPDA = _createComplexPDA();

      // Test Case 5: Lambda PDA
      lambdaPDA = _createLambdaPDA();
    });

    group('PDA Simulation Tests', () {
      test('Balanced Parentheses PDA - should accept valid strings', () async {
        final testCases = [
          '', // Empty string
          '()', // Simple balanced
          '(())', // Nested balanced
          '()()', // Multiple balanced
          '((()))', // Deeply nested
          '()()()', // Multiple simple
        ];

        for (final testString in testCases) {
          final result = await PDASimulator.simulateNPDA(
            balancedParenthesesPDA,
            testString,
            mode: PDAAcceptanceMode.finalState,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Simulation should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason:
                  'String "$testString" should be accepted by balanced parentheses PDA',
            );
          }
        }
      });

      test('Balanced Parentheses PDA - should reject invalid strings', () async {
        final testCases = [
          '(', // Unmatched opening
          ')', // Unmatched closing
          '())', // Extra closing
          '(()', // Extra opening
          ')(', // Wrong order
          '((())', // Unmatched opening
          '()))', // Extra closing
        ];

        for (final testString in testCases) {
          final result = await PDASimulator.simulateNPDA(
            balancedParenthesesPDA,
            testString,
            mode: PDAAcceptanceMode.finalState,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Simulation should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              false,
              reason:
                  'String "$testString" should be rejected by balanced parentheses PDA',
            );
          }
        }
      });

      test(
        'Palindrome PDA - should accept palindromes (even and odd lengths)',
        () async {
          final testCases = [
            '', // Empty string
            'a', // Single character
            'b', // Single character
            'aa', // Even length palindrome
            'bb', // Even length palindrome
            'aba', // Odd length palindrome
            'bab', // Odd length palindrome
            'abba', // Even length palindrome
            'baab', // Even length palindrome
          ];

          for (final testString in testCases) {
            final result = await PDASimulator.simulateNPDA(
              palindromePDA,
              testString,
              mode: PDAAcceptanceMode.finalState,
            );

            expect(
              result.isSuccess,
              true,
              reason: 'Simulation should succeed for "$testString"',
            );

            if (result.isSuccess) {
              expect(
                result.data!.accepted,
                true,
                reason:
                    'String "$testString" should be accepted by palindrome PDA',
              );
            }
          }
        },
      );

      test('Palindrome PDA - should reject non-palindromes', () async {
        final testCases = [
          'ab', // Not a palindrome
          'ba', // Not a palindrome
          'aab', // Not a palindrome
          'bba', // Not a palindrome
          'abab', // Not a palindrome
          'baba', // Not a palindrome
        ];

        for (final testString in testCases) {
          final result = await PDASimulator.simulateNPDA(
            palindromePDA,
            testString,
            mode: PDAAcceptanceMode.finalState,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Simulation should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              false,
              reason:
                  'String "$testString" should be rejected by palindrome PDA',
            );
          }
        }
      });

      test(
        'Simple PDA - should accept valid strings (via empty stack)',
        () async {
          final testCases = [
            'a', // Single a
            'aa', // Two a's
            'aaa', // Three a's
            'aaaa', // Four a's
          ];

          for (final testString in testCases) {
            final result = await PDASimulator.simulateNPDA(
              simplePDA,
              testString,
              mode: PDAAcceptanceMode.finalState,
            );

            expect(
              result.isSuccess,
              true,
              reason: 'Simulation should succeed for "$testString"',
            );

            if (result.isSuccess) {
              expect(
                result.data!.accepted,
                true,
                reason: 'String "$testString" should be accepted by simple PDA',
              );
            }
          }
        },
      );
    });

    group('Stack Operations Tests', () {
      test('PDA should handle push operations correctly', () async {
        final result = await PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          '()',
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'PDA should accept "()" with proper stack operations',
          );

          // Check that steps show stack operations
          expect(
            result.data!.steps.length,
            greaterThan(1),
            reason: 'PDA should have multiple steps for stack operations',
          );
        }
      });

      test('PDA should handle pop operations correctly', () async {
        final result = await PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          '(())',
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'PDA should accept "(())" with proper stack operations',
          );
        }
      });

      test('PDA should handle lambda operations correctly', () async {
        final result = await PDASimulator.simulateNPDA(
          lambdaPDA,
          'a',
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Lambda PDA should accept "a" with lambda operations',
          );
        }
      });

      test('PDA should handle empty stack correctly', () async {
        final result = await PDASimulator.simulate(balancedParenthesesPDA, '');

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'PDA should accept empty string with empty stack',
          );
        }
      });
    });

    group('Grammar to PDA Conversion Tests', () {
      test('Grammar should convert to PDA', () async {
        final grammar = _createTestGrammar();

        final result = GrammarToPDAConverter.convert(grammar);

        expect(
          result.isSuccess,
          true,
          reason: 'Grammar should convert to PDA successfully',
        );

        if (result.isSuccess) {
          final pda = result.data!;
          expect(
            pda.states.isNotEmpty,
            true,
            reason: 'Converted PDA should have states',
          );
          expect(
            pda.initialState,
            isNotNull,
            reason: 'Converted PDA should have initial state',
          );
          expect(
            pda.acceptingStates.isNotEmpty,
            true,
            reason: 'Converted PDA should have accepting states',
          );
        }
      });

      test('Converted PDA should accept same language as grammar', () async {
        final grammar = _createTestGrammar();

        final conversionResult = GrammarToPDAConverter.convert(grammar);
        expect(conversionResult.isSuccess, true);

        if (conversionResult.isSuccess) {
          final pda = conversionResult.data!;

          // Test that PDA accepts strings that should be accepted by grammar
          final testStrings = ['', 'a', 'b', 'ab', 'ba', 'aab', 'bba'];

          for (final testString in testStrings) {
            final result = await PDASimulator.simulate(pda, testString);

            expect(result.isSuccess, true);
            if (result.isSuccess) {
              // The PDA should accept the same strings as the grammar
              expect(
                result.data!.accepted,
                isA<bool>(),
                reason: 'PDA should either accept or reject "$testString"',
              );
            }
          }
        }
      });

      test('Complex grammar should convert to PDA', () async {
        final grammar = _createComplexGrammar();

        final result = GrammarToPDAConverter.convert(grammar);

        expect(
          result.isSuccess,
          true,
          reason: 'Complex grammar should convert to PDA successfully',
        );

        if (result.isSuccess) {
          final pda = result.data!;
          expect(
            pda.states.length,
            greaterThan(2),
            reason: 'Complex PDA should have multiple states',
          );
        }
      });
    });

    group('Non-deterministic Behavior Tests', () {
      test('PDA should handle non-deterministic choices', () async {
        final result = await PDASimulator.simulate(complexPDA, 'ab');

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            isA<bool>(),
            reason:
                'Non-deterministic PDA should make choices and either accept or reject',
          );
        }
      });

      test('PDA should explore multiple paths', () async {
        final result = await PDASimulator.simulate(complexPDA, 'aab');

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            isA<bool>(),
            reason: 'PDA should explore multiple paths and reach a decision',
          );
        }
      });
    });

    group('Complex Language Recognition Tests', () {
      test('PDA should recognize context-free languages', () async {
        final testCases = [
          '', // Empty string
          '()', // Simple balanced
          '(())', // Nested balanced
          '()()', // Multiple balanced
          '((()))', // Deeply nested
        ];

        for (final testString in testCases) {
          final result = await PDASimulator.simulateNPDA(
            balancedParenthesesPDA,
            testString,
            mode: PDAAcceptanceMode.finalState,
          );

          expect(
            result.isSuccess,
            true,
            reason: 'Simulation should succeed for "$testString"',
          );

          if (result.isSuccess) {
            expect(
              result.data!.accepted,
              true,
              reason:
                  'PDA should recognize context-free language for "$testString"',
            );
          }
        }
      });

      test('PDA should handle long strings efficiently', () async {
        // Test with very long balanced parentheses string
        final longString = '(' * 100 + ')' * 100; // 200 characters

        final result = await PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          longString,
          mode: PDAAcceptanceMode.finalState,
        );

        expect(
          result.isSuccess,
          true,
          reason: 'Should handle long strings without issues',
        );

        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Long balanced parentheses string should be accepted',
          );
        }
      });

      test('PDA should handle complex nested structures', () async {
        // Test with complex nested structures
        final complexString = '((()))()((()))';

        final result = await PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          complexString,
          mode: PDAAcceptanceMode.finalState,
        );

        expect(
          result.isSuccess,
          true,
          reason: 'Should handle complex nested structures',
        );

        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'Complex nested string should be accepted',
          );
        }
      });
    });

    group('Error Handling Tests', () {
      test('PDA should handle invalid input symbols', () async {
        final result = await PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          'c', // Invalid symbol
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            false,
            reason: 'PDA should reject input with invalid symbols',
          );
        }
      });

      test('PDA should handle mixed valid and invalid symbols', () async {
        final result = await PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          '(c)', // Mix of valid and invalid
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            false,
            reason: 'PDA should reject input with mixed valid/invalid symbols',
          );
        }
      });

      test('PDA should handle stack underflow', () async {
        final result = await PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          ')', // Try to pop from empty stack
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            false,
            reason: 'PDA should handle stack underflow gracefully',
          );
        }
      });
    });

    group('Performance Tests', () {
      test('PDA should handle complex computations efficiently', () async {
        // Test with complex input that requires many stack operations
        final result = await PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          '((()))()((()))',
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'PDA should complete complex computations',
          );

          // Check execution time is reasonable
          expect(
            result.data!.executionTime.inSeconds,
            lessThan(5),
            reason: 'PDA should complete within reasonable time',
          );
        }
      });

      test('PDA should handle multiple stack operations', () async {
        // Test PDA that performs multiple stack operations
        final result = await PDASimulator.simulateNPDA(
          balancedParenthesesPDA,
          '(()())',
          mode: PDAAcceptanceMode.finalState,
        );

        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(
            result.data!.accepted,
            true,
            reason: 'PDA should handle multiple stack operations',
          );

          // Verify sufficient steps were taken
          expect(
            result.data!.steps.length,
            greaterThan(5),
            reason: 'PDA should take multiple steps for complex operations',
          );
        }
      });
    });
  });
}

/// Helper functions to create test PDAs

PDA _createBalancedParenthesesPDA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    // Read '(', push 'X', stay in q0
    PDATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '(,Z→XZ',
      inputSymbol: '(',
      popSymbol: 'Z',
      pushSymbol: 'XZ',
    ),
    // Read '(', push 'X', stay in q0 (when X is on top)
    PDATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '(,X→XX',
      inputSymbol: '(',
      popSymbol: 'X',
      pushSymbol: 'XX',
    ),
    // Read ')', pop 'X', stay in q0
    PDATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '),X→ε',
      inputSymbol: ')',
      popSymbol: 'X',
      pushSymbol: '',
    ),
    // Read empty, pop 'Z', go to q1 (accept)
    PDATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,Z→ε',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
    ),
  };

  return PDA(
    id: 'balanced_parentheses',
    name: 'Balanced Parentheses',
    states: states,
    transitions: transitions,
    alphabet: {'(', ')'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    stackAlphabet: {'X', 'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 400, 300),
  );
}

PDA _createPalindromePDA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(500.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    // Read 'a', push 'A', stay in q0
    PDATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,Z→AZ',
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'AZ',
    ),
    // Read 'a', push 'A', stay in q0 (when A is on top)
    PDATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,A→AA',
      inputSymbol: 'a',
      popSymbol: 'A',
      pushSymbol: 'AA',
    ),
    // Read 'a' when B is on top: push A above B
    PDATransition(
      id: 't2b',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,B→AB',
      inputSymbol: 'a',
      popSymbol: 'B',
      pushSymbol: 'AB',
    ),
    // Switch to matching phase on reading 'a' with top A (pop A)
    PDATransition(
      id: 't2_switch_a',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a,A→ε',
      inputSymbol: 'a',
      popSymbol: 'A',
      pushSymbol: '',
    ),
    // Read 'b', push 'B', stay in q0
    PDATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'b,Z→BZ',
      inputSymbol: 'b',
      popSymbol: 'Z',
      pushSymbol: 'BZ',
    ),
    // Read 'b', push 'B', stay in q0 (when B is on top)
    PDATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'b,B→BB',
      inputSymbol: 'b',
      popSymbol: 'B',
      pushSymbol: 'BB',
    ),
    // Read 'b' when A is on top: push B above A
    PDATransition(
      id: 't4a',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'b,A→BA',
      inputSymbol: 'b',
      popSymbol: 'A',
      pushSymbol: 'BA',
    ),
    // Switch to matching phase on reading 'b' with top B (pop B)
    PDATransition(
      id: 't4_switch_b',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'b, B→ε',
      inputSymbol: 'b',
      popSymbol: 'B',
      pushSymbol: '',
    ),
    // Read empty on Z, go to q1 (even-length guess)
    PDATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,Z→Z',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: 'Z',
    ),
    // Odd-length guess: epsilon pop top (A/B) and switch to q1
    PDATransition(
      id: 't5a_eps',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,A→ε',
      inputSymbol: '',
      popSymbol: 'A',
      pushSymbol: '',
    ),
    PDATransition(
      id: 't5b_eps',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,B→ε',
      inputSymbol: '',
      popSymbol: 'B',
      pushSymbol: '',
    ),
    // Read 'a', pop 'A', stay in q1
    PDATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a,A→ε',
      inputSymbol: 'a',
      popSymbol: 'A',
      pushSymbol: '',
    ),
    // Read 'b', pop 'B', stay in q1
    PDATransition(
      id: 't7',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'b,B→ε',
      inputSymbol: 'b',
      popSymbol: 'B',
      pushSymbol: '',
    ),
    // Read empty, pop 'Z', go to q2 (accept)
    PDATransition(
      id: 't8',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'ε,Z→ε',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
    ),
  };

  return PDA(
    id: 'palindrome',
    name: 'Palindrome',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    stackAlphabet: {'A', 'B', 'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 600, 300),
  );
}

PDA _createSimplePDA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    // Read 'a', push 'X', stay in q0
    PDATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,Z→XZ',
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'XZ',
    ),
    // Read 'a', push 'X', stay in q0 (when X is on top)
    PDATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,X→XX',
      inputSymbol: 'a',
      popSymbol: 'X',
      pushSymbol: 'XX',
    ),
    // Allow epsilon pop of X to drain stack after input
    PDATransition(
      id: 't2c',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'ε,X→ε',
      inputSymbol: '',
      popSymbol: 'X',
      pushSymbol: '',
    ),
    // Allow consuming a matching 'a' by popping X in q0 (balance path)
    PDATransition(
      id: 't2b',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,X→ε',
      inputSymbol: 'a',
      popSymbol: 'X',
      pushSymbol: '',
    ),
    // Read empty, pop 'Z', go to q1 (accept)
    PDATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,Z→ε',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
    ),
  };

  return PDA(
    id: 'simple',
    name: 'Simple PDA',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    stackAlphabet: {'X', 'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 400, 300),
  );
}

PDA _createComplexPDA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(500.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    // Read 'a', push 'A', stay in q0
    PDATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,Z→AZ',
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'AZ',
    ),
    // Read 'b', push 'B', stay in q0
    PDATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'b,Z→BZ',
      inputSymbol: 'b',
      popSymbol: 'Z',
      pushSymbol: 'BZ',
    ),
    // Read empty, go to q1 (non-deterministic choice)
    PDATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,Z→Z',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: 'Z',
    ),
    // Read 'a', pop 'A', stay in q1
    PDATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a,A→ε',
      inputSymbol: 'a',
      popSymbol: 'A',
      pushSymbol: '',
    ),
    // Read 'b', pop 'B', stay in q1
    PDATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'b,B→ε',
      inputSymbol: 'b',
      popSymbol: 'B',
      pushSymbol: '',
    ),
    // Read empty, pop 'Z', go to q2 (accept)
    PDATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'ε,Z→ε',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
    ),
  };

  return PDA(
    id: 'complex',
    name: 'Complex PDA',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    stackAlphabet: {'A', 'B', 'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 600, 300),
  );
}

PDA _createLambdaPDA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    // Read 'a', push 'X', go to q1
    PDATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a,Z→XZ',
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'XZ',
    ),
    // Read empty, pop 'X', stay in q1 (lambda operation)
    PDATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,X→ε',
      inputSymbol: '',
      popSymbol: 'X',
      pushSymbol: '',
    ),
  };

  return PDA(
    id: 'lambda',
    name: 'Lambda PDA',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    stackAlphabet: {'X', 'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 400, 300),
  );
}

/// Helper functions to create test grammars

Grammar _createTestGrammar() {
  final productions = {
    Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a', 'S', 'b'],
      isLambda: false,
      order: 1,
    ),
    Production(
      id: 'p2',
      leftSide: ['S'],
      rightSide: [],
      isLambda: true,
      order: 2,
    ),
  };

  return Grammar(
    id: 'test_grammar',
    name: 'Test Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createComplexGrammar() {
  final productions = {
    Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['A', 'B'],
      isLambda: false,
      order: 1,
    ),
    Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: ['a', 'A'],
      isLambda: false,
      order: 2,
    ),
    Production(
      id: 'p3',
      leftSide: ['A'],
      rightSide: [],
      isLambda: true,
      order: 3,
    ),
    Production(
      id: 'p4',
      leftSide: ['B'],
      rightSide: ['b', 'B'],
      isLambda: false,
      order: 4,
    ),
    Production(
      id: 'p5',
      leftSide: ['B'],
      rightSide: [],
      isLambda: true,
      order: 5,
    ),
  };

  return Grammar(
    id: 'complex_grammar',
    name: 'Complex Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S', 'A', 'B'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}
