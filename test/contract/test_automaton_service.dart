import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

void main() {
  group('AutomatonService Contract Tests', () {
    late AutomatonService service;
    
    setUp(() {
      service = AutomatonService();
    });
    
    test('should create automaton with valid request', () async {
      // Arrange
      final request = CreateAutomatonRequest(
        name: 'Test FSA',
        description: 'A simple test automaton',
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
      
      // Act
      final result = service.createAutomaton(request);
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, isA<FSA>());
      expect(result.data!.name, equals('Test FSA'));
      expect(result.data!.states.length, equals(2));
      expect(result.data!.transitions.length, equals(1));
      expect(result.data!.alphabet, equals({'a'}));
    });
    
    test('should fail to create automaton with empty name', () async {
      // Arrange
      final request = CreateAutomatonRequest(
        name: '',
        states: [],
        transitions: [],
        alphabet: [],
        bounds: Rect(0, 0, 100, 100),
      );
      
      // Act
      final result = service.createAutomaton(request);
      
      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('name cannot be empty'));
    });
    
    test('should get automaton by ID', () async {
      // Arrange
      final request = CreateAutomatonRequest(
        name: 'Test FSA',
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
      
      final createResult = service.createAutomaton(request);
      expect(createResult.isSuccess, isTrue);
      final automatonId = createResult.data!.id;
      
      // Act
      final result = service.getAutomaton(automatonId);
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.id, equals(automatonId));
      expect(result.data!.name, equals('Test FSA'));
    });
    
    test('should fail to get non-existent automaton', () async {
      // Act
      final result = service.getAutomaton('non-existent-id');
      
      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('not found'));
    });
    
    test('should update automaton', () async {
      // Arrange
      final createRequest = CreateAutomatonRequest(
        name: 'Original Name',
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
      
      final createResult = service.createAutomaton(createRequest);
      expect(createResult.isSuccess, isTrue);
      final automatonId = createResult.data!.id;
      
      final updateRequest = CreateAutomatonRequest(
        name: 'Updated Name',
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
      final result = service.updateAutomaton(automatonId, updateRequest);
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.name, equals('Updated Name'));
      expect(result.data!.id, equals(automatonId));
    });
    
    test('should delete automaton', () async {
      // Arrange
      final request = CreateAutomatonRequest(
        name: 'To Delete',
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
      
      final createResult = service.createAutomaton(request);
      expect(createResult.isSuccess, isTrue);
      final automatonId = createResult.data!.id;
      
      // Act
      final result = service.deleteAutomaton(automatonId);
      
      // Assert
      expect(result.isSuccess, isTrue);
      
      // Verify it's actually deleted
      final getResult = service.getAutomaton(automatonId);
      expect(getResult.isSuccess, isFalse);
    });
    
    test('should list all automata', () async {
      // Arrange
      final request1 = CreateAutomatonRequest(
        name: 'FSA 1',
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
      
      final request2 = CreateAutomatonRequest(
        name: 'FSA 2',
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
      
      service.createAutomaton(request1);
      service.createAutomaton(request2);
      
      // Act
      final result = service.listAutomata();
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.length, equals(2));
      expect(result.data!.any((a) => a.name == 'FSA 1'), isTrue);
      expect(result.data!.any((a) => a.name == 'FSA 2'), isTrue);
    });
    
    test('should clear all automata', () async {
      // Arrange
      final request = CreateAutomatonRequest(
        name: 'To Clear',
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
      
      service.createAutomaton(request);
      
      // Act
      final result = service.clearAutomata();
      
      // Assert
      expect(result.isSuccess, isTrue);
      
      // Verify list is empty
      final listResult = service.listAutomata();
      expect(listResult.isSuccess, isTrue);
      expect(listResult.data!.length, equals(0));
    });
  });
}
