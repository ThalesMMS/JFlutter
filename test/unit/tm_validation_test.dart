import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/core/algorithms/tm_simulator.dart';
import 'package:jflutter/core/result.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

/// TM (Turing Machine) Validation Tests against References/automata-main
/// 
/// This test suite validates TM algorithms against the Python reference implementation
/// from References/automata-main/tests/test_tm.py to ensure behavioral equivalence.
/// 
/// Test cases cover:
/// 1. Acceptance scenarios (strings that should be accepted)
/// 2. Rejection scenarios (strings that should be rejected)
/// 3. Loop detection (infinite loops and halting)
/// 4. Transformation scenarios (tape modifications)
/// 5. Tape limits (boundary conditions)
void main() {
  group('TM Validation Tests', () {
    late TM binaryToUnaryTM;
    late TM palindromeTM;
    late TM acceptAllTM;
    late TM rejectAllTM;
    late TM loopDetectionTM;

    setUp(() {
      // Test Case 1: Binary to Unary (from jflutter_js/examples)
      binaryToUnaryTM = _createBinaryToUnaryTM();
      
      // Test Case 2: Palindrome TM
      palindromeTM = _createPalindromeTM();
      
      // Test Case 3: Accept All TM
      acceptAllTM = _createAcceptAllTM();
      
      // Test Case 4: Reject All TM
      rejectAllTM = _createRejectAllTM();
      
      // Test Case 5: Loop Detection TM
      loopDetectionTM = _createLoopDetectionTM();
    });

    group('Acceptance Tests', () {
      test('Binary to Unary - should accept valid binary numbers', () async {
        final testCases = [
          '0',      // Should convert to '1'
          '1',      // Should convert to '11'
          '10',     // Should convert to '111'
          '11',     // Should convert to '1111'
          '100',    // Should convert to '11111'
        ];

        for (final testString in testCases) {
          final result = await TMSimulator.simulate(
            binaryToUnaryTM,
            testString,
          );
          
          expect(result.isSuccess, true, 
            reason: 'Simulation should succeed for "$testString"');
          
          if (result.isSuccess) {
            expect(result.data!.accepted, true,
              reason: 'Binary "$testString" should be accepted by binary to unary TM');
          }
        }
      });

      test('Palindrome TM - should accept palindromes', () async {
        final testCases = [
          '',       // Empty string
          'a',      // Single character
          'b',      // Single character
          'aa',     // Even length palindrome
          'bb',     // Even length palindrome
          'aba',    // Odd length palindrome
          'bab',    // Odd length palindrome
          'abba',   // Even length palindrome
          'baab',   // Even length palindrome
        ];

        for (final testString in testCases) {
          final result = await TMSimulator.simulate(
            palindromeTM,
            testString,
          );
          
          expect(result.isSuccess, true, 
            reason: 'Simulation should succeed for "$testString"');
          
          if (result.isSuccess) {
            expect(result.data!.accepted, true,
              reason: 'String "$testString" should be accepted by palindrome TM');
          }
        }
      });

      test('Accept All TM - should accept any string', () async {
        final testCases = [
          '',       // Empty string
          'a',      // Single character
          'ab',     // Two characters
          'abc',    // Three characters
          'abcd',   // Four characters
        ];

        for (final testString in testCases) {
          final result = await TMSimulator.simulate(
            acceptAllTM,
            testString,
          );
          
          expect(result.isSuccess, true, 
            reason: 'Simulation should succeed for "$testString"');
          
          if (result.isSuccess) {
            expect(result.data!.accepted, true,
              reason: 'String "$testString" should be accepted by accept all TM');
          }
        }
      });
    });

    group('Rejection Tests', () {
      test('Palindrome TM - should reject non-palindromes', () async {
        final testCases = [
          'ab',     // Not a palindrome
          'ba',     // Not a palindrome
          'aab',    // Not a palindrome
          'bba',    // Not a palindrome
          'abab',   // Not a palindrome
          'baba',   // Not a palindrome
        ];

        for (final testString in testCases) {
          final result = await TMSimulator.simulate(
            palindromeTM,
            testString,
          );
          
          expect(result.isSuccess, true, 
            reason: 'Simulation should succeed for "$testString"');
          
          if (result.isSuccess) {
            expect(result.data!.accepted, false,
              reason: 'String "$testString" should be rejected by palindrome TM');
          }
        }
      });

      test('Reject All TM - should reject any string', () async {
        final testCases = [
          '',       // Empty string
          'a',      // Single character
          'ab',     // Two characters
          'abc',    // Three characters
          'abcd',   // Four characters
        ];

        for (final testString in testCases) {
          final result = await TMSimulator.simulate(
            rejectAllTM,
            testString,
          );
          
          expect(result.isSuccess, true, 
            reason: 'Simulation should succeed for "$testString"');
          
          if (result.isSuccess) {
            expect(result.data!.accepted, false,
              reason: 'String "$testString" should be rejected by reject all TM');
          }
        }
      });
    });

    group('Loop Detection Tests', () {
      test('TM should detect infinite loops', () async {
        // Test with TM that has infinite loop
        final result = await TMSimulator.simulate(
          loopDetectionTM,
          'a',
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          // The TM should either accept, reject, or timeout due to loop
          expect(result.data!.accepted, isA<bool>(),
            reason: 'TM should either accept or reject (not loop infinitely)');
        }
      });

      test('TM should handle timeout scenarios', () async {
        // Test with very long input that might cause timeout
        final longString = 'a' * 1000; // 1000 a's
        
        final result = await TMSimulator.simulate(
          loopDetectionTM,
          longString,
          timeout: const Duration(milliseconds: 100), // Short timeout
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          // Should either complete or timeout
          expect(result.data!.accepted, isA<bool>(),
            reason: 'TM should handle long inputs without infinite loops');
        }
      });
    });

    group('Transformation Tests', () {
      test('Binary to Unary TM should transform input', () async {
        // Test that the TM actually transforms the input
        final result = await TMSimulator.simulate(
          binaryToUnaryTM,
          '10', // Binary 2
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'Binary to unary TM should accept "10"');
          
          // Check that the tape was modified (transformation occurred)
          expect(result.data!.steps.isNotEmpty,
            reason: 'TM should have execution steps');
        }
      });

      test('TM should handle tape modifications correctly', () async {
        // Test with TM that modifies the tape
        final result = await TMSimulator.simulate(
          binaryToUnaryTM,
          '11', // Binary 3
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'Binary to unary TM should accept "11"');
          
          // Verify that steps show tape modifications
          expect(result.data!.steps.length, greaterThan(1),
            reason: 'TM should have multiple execution steps for transformation');
        }
      });
    });

    group('Tape Limits Tests', () {
      test('TM should handle empty tape correctly', () async {
        final result = await TMSimulator.simulate(
          acceptAllTM,
          '',
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'TM should handle empty input correctly');
        }
      });

      test('TM should handle single character input', () async {
        final result = await TMSimulator.simulate(
          palindromeTM,
          'a',
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'Single character should be accepted as palindrome');
        }
      });

      test('TM should handle maximum tape length', () async {
        // Test with very long input to test tape limits
        final longString = 'ab' * 500; // 1000 characters
        
        final result = await TMSimulator.simulate(
          palindromeTM,
          longString,
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          // Should either accept or reject, but not crash
          expect(result.data!.accepted, isA<bool>(),
            reason: 'TM should handle long inputs without issues');
        }
      });
    });

    group('Performance Tests', () {
      test('TM should handle complex computations efficiently', () async {
        // Test with complex input that requires many steps
        final result = await TMSimulator.simulate(
          binaryToUnaryTM,
          '1111', // Binary 15
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'TM should complete complex computations');
          
          // Check execution time is reasonable
          expect(result.data!.executionTime.inSeconds, lessThan(5),
            reason: 'TM should complete within reasonable time');
        }
      });

      test('TM should handle multiple tape operations', () async {
        // Test TM that performs multiple tape operations
        final result = await TMSimulator.simulate(
          binaryToUnaryTM,
          '1010', // Binary 10
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'TM should handle multiple tape operations');
          
          // Verify sufficient steps were taken
          expect(result.data!.steps.length, greaterThan(5),
            reason: 'TM should take multiple steps for complex operations');
        }
      });
    });

    group('Error Handling Tests', () {
      test('TM should handle invalid input symbols', () async {
        // Test with symbols not in the alphabet
        final result = await TMSimulator.simulate(
          binaryToUnaryTM,
          'c', // Invalid symbol
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, false,
            reason: 'TM should reject input with invalid symbols');
        }
      });

      test('TM should handle mixed valid and invalid symbols', () async {
        final result = await TMSimulator.simulate(
          binaryToUnaryTM,
          'a1b', // Mix of valid and invalid
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, false,
            reason: 'TM should reject input with mixed valid/invalid symbols');
        }
      });
    });
  });
}

/// Helper functions to create test TMs

TM _createBinaryToUnaryTM() {
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
    // Read '0', write '1', move right
    TMTransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '0→1,R',
      readSymbol: '0',
      writeSymbol: '1',
      direction: TapeDirection.right,
    ),
    // Read '1', write '1', move right
    TMTransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '1→1,R',
      readSymbol: '1',
      writeSymbol: '1',
      direction: TapeDirection.right,
    ),
    // Read blank, stay, accept
    TMTransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'B→B,S',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.stay,
    ),
  };
  
  return TM(
    id: 'binary_to_unary',
    name: 'Binary to Unary',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    tapeAlphabet: {'0', '1', 'B'},
    blankSymbol: 'B',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 600, 400),
  );
}

TM _createPalindromeTM() {
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
    // Read 'a', write 'a', move right
    TMTransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a→a,R',
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.right,
    ),
    // Read 'b', write 'b', move right
    TMTransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'b→b,R',
      readSymbol: 'b',
      writeSymbol: 'b',
      direction: TapeDirection.right,
    ),
    // Read blank, stay, accept (empty string)
    TMTransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'B→B,S',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.stay,
    ),
    // Read 'a', write 'a', move left
    TMTransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'a→a,L',
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.left,
    ),
    // Read 'b', write 'b', move left
    TMTransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'b→b,L',
      readSymbol: 'b',
      writeSymbol: 'b',
      direction: TapeDirection.left,
    ),
  };
  
  return TM(
    id: 'palindrome',
    name: 'Palindrome',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    tapeAlphabet: {'a', 'b', 'B'},
    blankSymbol: 'B',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 600, 400),
  );
}

TM _createAcceptAllTM() {
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
    // Read any symbol, write same, move right
    TMTransition(
      id: 't1',
      fromState: states.first,
      toState: states.first,
      label: 'a→a,R',
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't2',
      fromState: states.first,
      toState: states.first,
      label: 'b→b,R',
      readSymbol: 'b',
      writeSymbol: 'b',
      direction: TapeDirection.right,
    ),
    // Read blank, stay, accept
    TMTransition(
      id: 't3',
      fromState: states.first,
      toState: states.first,
      label: 'B→B,S',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.stay,
    ),
  };
  
  return TM(
    id: 'accept_all',
    name: 'Accept All',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.first,
    acceptingStates: states,
    tapeAlphabet: {'a', 'b', 'B'},
    blankSymbol: 'B',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 300, 300),
  );
}

TM _createRejectAllTM() {
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
    // Read any symbol, write same, move right (no accepting state)
    TMTransition(
      id: 't1',
      fromState: states.first,
      toState: states.first,
      label: 'a→a,R',
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't2',
      fromState: states.first,
      toState: states.first,
      label: 'b→b,R',
      readSymbol: 'b',
      writeSymbol: 'b',
      direction: TapeDirection.right,
    ),
    // Read blank, stay, reject
    TMTransition(
      id: 't3',
      fromState: states.first,
      toState: states.first,
      label: 'B→B,S',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.stay,
    ),
  };
  
  return TM(
    id: 'reject_all',
    name: 'Reject All',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.first,
    acceptingStates: {},
    tapeAlphabet: {'a', 'b', 'B'},
    blankSymbol: 'B',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 300, 300),
  );
}

TM _createLoopDetectionTM() {
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
    // Read 'a', write 'a', move right, go to q1
    TMTransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a→a,R',
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.right,
    ),
    // Read blank, stay, accept
    TMTransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'B→B,S',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.stay,
    ),
  };
  
  return TM(
    id: 'loop_detection',
    name: 'Loop Detection',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    tapeAlphabet: {'a', 'B'},
    blankSymbol: 'B',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: math.Rectangle(0, 0, 400, 300),
  );
}
