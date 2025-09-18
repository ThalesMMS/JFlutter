import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/algorithms/nfa_to_dfa_converter.dart';
import 'package:jflutter/core/algorithms/automaton_simulator.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

void main() {
  group('Working NFA to DFA Conversion Tests', () {
    late AutomatonService service;
    
    setUp(() {
      service = AutomatonService();
    });
    
    test('should convert deterministic NFA (which is already a DFA)', () async {
      // Arrange - Create a simple deterministic automaton
      final request = CreateAutomatonRequest(
        name: 'Simple DFA',
        states: [
          StateData(
            id: 'q0',
            name: 'q0',
            position: Point(100, 100),
            isInitial: true,
            isAccepting: false,
          ),
          StateData(
            id: 'q1',
            name: 'q1',
            position: Point(200, 100),
            isInitial: false,
            isAccepting: true,
          ),
        ],
        transitions: [
          TransitionData(
            fromStateId: 'q0',
            toStateId: 'q1',
            symbol: 'a',
          ),
        ],
        alphabet: ['a'],
        bounds: Rect(0, 0, 300, 200),
      );
      
      final createResult = service.createAutomaton(request);
      expect(createResult.isSuccess, isTrue);
      final nfa = createResult.data!;
      
      // Act - Convert NFA to DFA
      final convertResult = NFAToDFAConverter.convert(nfa);
      
      // Assert
      expect(convertResult.isSuccess, isTrue);
      final dfa = convertResult.data!;
      
      // Test that both accept the same strings
      final testString = 'a';
      final nfaResult = AutomatonSimulator.simulate(nfa, testString);
      final dfaResult = AutomatonSimulator.simulate(dfa, testString);
      
      expect(nfaResult.isSuccess, isTrue);
      expect(dfaResult.isSuccess, isTrue);
      expect(nfaResult.data!.accepted, equals(dfaResult.data!.accepted));
    });
    
    test('should convert NFA with self-loop to DFA', () async {
      // Arrange - Create NFA: q0 --a--> q0, q0 --b--> q1
      final request = CreateAutomatonRequest(
        name: 'Self-loop NFA',
        states: [
          StateData(
            id: 'q0',
            name: 'q0',
            position: Point(100, 100),
            isInitial: true,
            isAccepting: false,
          ),
          StateData(
            id: 'q1',
            name: 'q1',
            position: Point(200, 100),
            isInitial: false,
            isAccepting: true,
          ),
        ],
        transitions: [
          TransitionData(
            fromStateId: 'q0',
            toStateId: 'q0',
            symbol: 'a',
          ),
          TransitionData(
            fromStateId: 'q0',
            toStateId: 'q1',
            symbol: 'b',
          ),
        ],
        alphabet: ['a', 'b'],
        bounds: Rect(0, 0, 300, 200),
      );
      
      final createResult = service.createAutomaton(request);
      expect(createResult.isSuccess, isTrue);
      final nfa = createResult.data!;
      
      // Act - Convert NFA to DFA
      final convertResult = NFAToDFAConverter.convert(nfa);
      
      // Assert
      expect(convertResult.isSuccess, isTrue);
      final dfa = convertResult.data!;
      
      // Test multiple strings
      final testStrings = ['b', 'ab', 'aab', 'aaab'];
      for (final testString in testStrings) {
        final nfaResult = AutomatonSimulator.simulate(nfa, testString);
        final dfaResult = AutomatonSimulator.simulate(dfa, testString);
        
        expect(nfaResult.isSuccess, isTrue, reason: 'NFA simulation failed for "$testString"');
        expect(dfaResult.isSuccess, isTrue, reason: 'DFA simulation failed for "$testString"');
        expect(nfaResult.data!.accepted, equals(dfaResult.data!.accepted),
            reason: 'NFA and DFA should accept/reject "$testString" the same way');
      }
    });
    
    test('should handle empty string correctly', () async {
      // Arrange - Create NFA that accepts empty string
      final request = CreateAutomatonRequest(
        name: 'Empty String NFA',
        states: [
          StateData(
            id: 'q0',
            name: 'q0',
            position: Point(100, 100),
            isInitial: true,
            isAccepting: true,
          ),
        ],
        transitions: [],
        alphabet: ['a'],
        bounds: Rect(0, 0, 100, 100),
      );
      
      final createResult = service.createAutomaton(request);
      expect(createResult.isSuccess, isTrue);
      final nfa = createResult.data!;
      
      // Act - Convert NFA to DFA
      final convertResult = NFAToDFAConverter.convert(nfa);
      
      // Assert
      expect(convertResult.isSuccess, isTrue);
      final dfa = convertResult.data!;
      
      // Test empty string
      final nfaResult = AutomatonSimulator.simulate(nfa, '');
      final dfaResult = AutomatonSimulator.simulate(dfa, '');
      
      expect(nfaResult.isSuccess, isTrue);
      expect(dfaResult.isSuccess, isTrue);
      expect(nfaResult.data!.accepted, equals(dfaResult.data!.accepted));
      expect(nfaResult.data!.accepted, isTrue); // Should accept empty string
    });
  });
}
