import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/algorithms/automaton_simulator.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

void main() {
  group('FSA Creation and Simulation Integration Tests', () {
    late AutomatonService service;
    late AutomatonSimulator simulator;
    
    setUp(() {
      service = AutomatonService();
      simulator = AutomatonSimulator();
    });
    
    test('should create FSA and simulate accepting string', () async {
      // Arrange - Create a simple FSA that accepts strings ending with 'a'
      final request = CreateAutomatonRequest(
        name: 'Ends with a',
        description: 'Accepts strings ending with a',
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
            symbol: 'b',
          ),
          TransitionData(
            fromStateId: 'q0',
            toStateId: 'q1',
            symbol: 'a',
          ),
          TransitionData(
            fromStateId: 'q1',
            toStateId: 'q0',
            symbol: 'b',
          ),
          TransitionData(
            fromStateId: 'q1',
            toStateId: 'q1',
            symbol: 'a',
          ),
        ],
        alphabet: ['a', 'b'],
        bounds: Rect(0, 0, 300, 200),
      );
      
      // Act - Create the automaton
      final createResult = service.createAutomaton(request);
      expect(createResult.isSuccess, isTrue);
      final fsa = createResult.data!;
      
      // Act - Simulate with accepting string
      final simulateResult = AutomatonSimulator.simulate(fsa, 'ba');
      
      // Assert
      expect(simulateResult.isSuccess, isTrue);
      expect(simulateResult.data!.accepted, isTrue);
      expect(simulateResult.data!.inputString, equals('ba'));
      expect(simulateResult.data!.steps.length, greaterThan(0));
    });
    
    test('should create FSA and simulate rejecting string', () async {
      // Arrange - Create the same FSA
      final request = CreateAutomatonRequest(
        name: 'Ends with a',
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
            symbol: 'b',
          ),
          TransitionData(
            fromStateId: 'q0',
            toStateId: 'q1',
            symbol: 'a',
          ),
          TransitionData(
            fromStateId: 'q1',
            toStateId: 'q0',
            symbol: 'b',
          ),
          TransitionData(
            fromStateId: 'q1',
            toStateId: 'q1',
            symbol: 'a',
          ),
        ],
        alphabet: ['a', 'b'],
        bounds: Rect(0, 0, 300, 200),
      );
      
      final createResult = service.createAutomaton(request);
      expect(createResult.isSuccess, isTrue);
      final fsa = createResult.data!;
      
      // Act - Simulate with rejecting string
      final simulateResult = AutomatonSimulator.simulate(fsa, 'bb');
      
      // Assert
      expect(simulateResult.isSuccess, isTrue);
      expect(simulateResult.data!.accepted, isFalse);
      expect(simulateResult.data!.inputString, equals('bb'));
    });
    
    test('should create FSA with epsilon transitions', () async {
      // Arrange - Create FSA with epsilon transitions
      final request = CreateAutomatonRequest(
        name: 'Epsilon FSA',
        description: 'FSA with epsilon transitions',
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
            symbol: 'ε', // Epsilon transition
          ),
          TransitionData(
            fromStateId: 'q0',
            toStateId: 'q0',
            symbol: 'a',
          ),
        ],
        alphabet: ['a', 'ε'],
        bounds: Rect(0, 0, 300, 200),
      );
      
      // Act
      final result = service.createAutomaton(request);
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.name, equals('Epsilon FSA'));
      expect(result.data!.transitions.length, equals(2));
      expect(result.data!.alphabet, contains('ε'));
    });
    
    test('should create FSA with multiple accepting states', () async {
      // Arrange
      final request = CreateAutomatonRequest(
        name: 'Multiple Accepting',
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
          StateData(
            id: 'q2',
            name: 'q2',
            position: Point(300, 100),
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
            toStateId: 'q2',
            symbol: 'b',
          ),
        ],
        alphabet: ['a', 'b'],
        bounds: Rect(0, 0, 400, 200),
      );
      
      // Act
      final result = service.createAutomaton(request);
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.acceptingStates.length, equals(2));
      expect(result.data!.acceptingStates.any((s) => s.id == 'q1'), isTrue);
      expect(result.data!.acceptingStates.any((s) => s.id == 'q2'), isTrue);
    });
    
    test('should validate FSA properties after creation', () async {
      // Arrange
      final request = CreateAutomatonRequest(
        name: 'Valid FSA',
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
        alphabet: [],
        bounds: Rect(0, 0, 100, 100),
      );
      
      // Act
      final result = service.createAutomaton(request);
      
      // Assert
      expect(result.isSuccess, isTrue);
      final fsa = result.data!;
      
      // Validate FSA properties
      expect(fsa.isValid, isTrue);
      expect(fsa.hasInitialState, isTrue);
      expect(fsa.hasAcceptingStates, isTrue);
      expect(fsa.stateCount, equals(1));
      expect(fsa.transitionCount, equals(0));
      expect(fsa.acceptingStateCount, equals(1));
    });
  });
}
