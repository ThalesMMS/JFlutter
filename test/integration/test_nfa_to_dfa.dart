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
  group('NFA to DFA Conversion Integration Tests', () {
    late AutomatonService service;
    late NFAToDFAConverter converter;
    late AutomatonSimulator simulator;
    
    setUp(() {
      service = AutomatonService();
      converter = NFAToDFAConverter();
      simulator = AutomatonSimulator();
    });
    
    test('should convert simple NFA to DFA', () async {
      // Arrange - Create simple NFA: q0 --a--> q1, q0 --b--> q0
      final request = CreateAutomatonRequest(
        name: 'Simple NFA',
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
          TransitionData(
            fromStateId: 'q0',
            toStateId: 'q0',
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
      
      // Verify DFA properties
      expect(dfa.name, contains('DFA'));
      expect(dfa.states.length, greaterThanOrEqualTo(nfa.states.length));
      expect(dfa.alphabet, equals(nfa.alphabet));
      expect(dfa.hasInitialState, isTrue);
      expect(dfa.hasAcceptingStates, isTrue);
    });
    
    test('should produce equivalent DFA for same input strings', () async {
      // Arrange - Create NFA
      final request = CreateAutomatonRequest(
        name: 'Test NFA',
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
            symbol: 'a',
          ),
        ],
        alphabet: ['a'],
        bounds: Rect(0, 0, 300, 200),
      );
      
      final createResult = service.createAutomaton(request);
      expect(createResult.isSuccess, isTrue);
      final nfa = createResult.data!;
      
      // Act - Convert to DFA
      final convertResult = NFAToDFAConverter.convert(nfa);
      expect(convertResult.isSuccess, isTrue);
      final dfa = convertResult.data!;
      
      // Test multiple input strings
      final testStrings = ['a', 'ba', 'bba', 'bbba'];
      
      for (final inputString in testStrings) {
        final nfaResult = AutomatonSimulator.simulate(nfa, inputString);
        final dfaResult = AutomatonSimulator.simulate(dfa, inputString);
        
        expect(nfaResult.isSuccess, isTrue);
        expect(dfaResult.isSuccess, isTrue);
        expect(nfaResult.data!.accepted, equals(dfaResult.data!.accepted),
            reason: 'NFA and DFA should accept/reject "$inputString" the same way');
      }
    });
    
    test('should handle NFA with epsilon transitions', () async {
      // Arrange - Create NFA with epsilon transitions
      final request = CreateAutomatonRequest(
        name: 'Epsilon NFA',
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
            symbol: 'ε',
          ),
          TransitionData(
            fromStateId: 'q0',
            toStateId: 'q0',
            symbol: 'a',
          ),
          TransitionData(
            fromStateId: 'q1',
            toStateId: 'q1',
            symbol: 'a',
          ),
        ],
        alphabet: ['a', 'ε'],
        bounds: Rect(0, 0, 300, 200),
      );
      
      final createResult = service.createAutomaton(request);
      expect(createResult.isSuccess, isTrue);
      final nfa = createResult.data!;
      
      // Act - Convert to DFA
      final convertResult = NFAToDFAConverter.convert(nfa);
      
      // Assert
      expect(convertResult.isSuccess, isTrue);
      final dfa = convertResult.data!;
      
      // Verify DFA doesn't have epsilon transitions
      expect(dfa.alphabet.contains('ε'), isFalse);
      
      // Test equivalence
      final testStrings = ['', 'a', 'aa', 'aaa'];
      for (final inputString in testStrings) {
        final nfaResult = AutomatonSimulator.simulate(nfa, inputString);
        final dfaResult = AutomatonSimulator.simulate(dfa, inputString);
        
        expect(nfaResult.isSuccess, isTrue);
        expect(dfaResult.isSuccess, isTrue);
        expect(nfaResult.data!.accepted, equals(dfaResult.data!.accepted));
      }
    });
    
    test('should handle NFA with multiple transitions', () async {
      // Arrange - Create simpler NFA
      final request = CreateAutomatonRequest(
        name: 'Multi-transition NFA',
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
          TransitionData(
            fromStateId: 'q0',
            toStateId: 'q0',
            symbol: 'b',
          ),
          TransitionData(
            fromStateId: 'q1',
            toStateId: 'q1',
            symbol: 'a',
          ),
          TransitionData(
            fromStateId: 'q1',
            toStateId: 'q0',
            symbol: 'b',
          ),
        ],
        alphabet: ['a', 'b'],
        bounds: Rect(0, 0, 300, 200),
      );
      
      final createResult = service.createAutomaton(request);
      expect(createResult.isSuccess, isTrue);
      final nfa = createResult.data!;
      
      // Act - Convert to DFA
      final convertResult = NFAToDFAConverter.convert(nfa);
      
      // Assert
      expect(convertResult.isSuccess, isTrue);
      final dfa = convertResult.data!;
      
      // Verify DFA is deterministic
      for (final state in dfa.states) {
        for (final symbol in dfa.alphabet) {
          final transitions = dfa.getTransitionsFrom(state)
              .where((t) => t.label == symbol)
              .toList();
          expect(transitions.length, lessThanOrEqualTo(1),
              reason: 'DFA should have at most one transition per state-symbol pair');
        }
      }
    });
    
    test('should provide step-by-step conversion information', () async {
      // Arrange
      final request = CreateAutomatonRequest(
        name: 'Step Test NFA',
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
            symbol: 'a',
          ),
        ],
        alphabet: ['a'],
        bounds: Rect(0, 0, 300, 200),
      );
      
      final createResult = service.createAutomaton(request);
      expect(createResult.isSuccess, isTrue);
      final nfa = createResult.data!;
      
      // Act - Convert with steps
      final convertResult = NFAToDFAConverter.convertWithSteps(nfa);
      
      // Assert
      expect(convertResult.isSuccess, isTrue);
      final result = convertResult.data!;
      
      expect(result.originalNFA, equals(nfa));
      expect(result.resultDFA, isA<FSA>());
      expect(result.steps.length, greaterThan(0));
      expect(result.steps.first.stepNumber, equals(1));
      expect(result.steps.last.stepNumber, greaterThan(1));
    });
  });
}
