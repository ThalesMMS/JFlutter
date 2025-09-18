import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/algorithms/nfa_to_dfa_converter.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

void main() {
  group('Simple NFA to DFA Conversion Tests', () {
    late AutomatonService service;
    
    setUp(() {
      service = AutomatonService();
    });
    
    test('should convert very simple NFA to DFA', () async {
      // Arrange - Create a very simple NFA: q0 --a--> q1
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
      
      // Verify DFA properties
      expect(dfa.name, contains('DFA'));
      expect(dfa.states.length, greaterThanOrEqualTo(nfa.states.length));
      expect(dfa.alphabet, equals(nfa.alphabet));
      expect(dfa.hasInitialState, isTrue);
      expect(dfa.hasAcceptingStates, isTrue);
    });
    
    test('should handle NFA with no transitions', () async {
      // Arrange - Create NFA with no transitions
      final request = CreateAutomatonRequest(
        name: 'No Transitions NFA',
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
      
      // Should have same structure as original
      expect(dfa.states.length, equals(1));
      expect(dfa.transitions.length, equals(0));
      expect(dfa.hasInitialState, isTrue);
      expect(dfa.hasAcceptingStates, isTrue);
    });
  });
}
