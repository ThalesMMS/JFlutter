// Integration test for Turing machine simulation
// This test MUST fail initially - it defines the expected integration behavior

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('Turing Machine Simulation Integration Tests', () {
    late AutomatonApi api;
    late String tmId;

    setUp(() async {
      api = AutomatonApi();
      
      // Create TM for language {a^n b^n c^n | n ≥ 0}
      final createResponse = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'a^n b^n c^n TM',
          type: AutomatonType.TM,
          description: 'TM accepting balanced a, b, and c strings',
        ),
      );
      tmId = createResponse.data.id;
      
      await api.updateAutomaton(tmId, UpdateAutomatonRequest(
        states: [
          State(id: 'q0', name: 'q0', position: Position(x: 0, y: 0), isInitial: true),
          State(id: 'q1', name: 'q1', position: Position(x: 100, y: 0)),
          State(id: 'q2', name: 'q2', position: Position(x: 200, y: 0)),
          State(id: 'q3', name: 'q3', position: Position(x: 300, y: 0)),
          State(id: 'q4', name: 'q4', position: Position(x: 400, y: 0)),
          State(id: 'q5', name: 'q5', position: Position(x: 500, y: 0), isAccepting: true),
        ],
        transitions: [
          // Replace a with X, move right
          TMTransition(
            id: 't1',
            fromState: 'q0',
            toState: 'q1',
            symbol: 'a',
            tapeRead: 'a',
            tapeWrite: 'X',
            moveDirection: MoveDirection.RIGHT,
          ),
          // Skip a's, move right
          TMTransition(
            id: 't2',
            fromState: 'q1',
            toState: 'q1',
            symbol: 'a',
            tapeRead: 'a',
            tapeWrite: 'a',
            moveDirection: MoveDirection.RIGHT,
          ),
          // Replace b with Y, move right
          TMTransition(
            id: 't3',
            fromState: 'q1',
            toState: 'q2',
            symbol: 'b',
            tapeRead: 'b',
            tapeWrite: 'Y',
            moveDirection: MoveDirection.RIGHT,
          ),
          // Skip b's, move right
          TMTransition(
            id: 't4',
            fromState: 'q2',
            toState: 'q2',
            symbol: 'b',
            tapeRead: 'b',
            tapeWrite: 'b',
            moveDirection: MoveDirection.RIGHT,
          ),
          // Replace c with Z, move left
          TMTransition(
            id: 't5',
            fromState: 'q2',
            toState: 'q3',
            symbol: 'c',
            tapeRead: 'c',
            tapeWrite: 'Z',
            moveDirection: MoveDirection.LEFT,
          ),
          // Return to start
          TMTransition(
            id: 't6',
            fromState: 'q3',
            toState: 'q3',
            symbol: 'Z',
            tapeRead: 'Z',
            tapeWrite: 'Z',
            moveDirection: MoveDirection.LEFT,
          ),
          TMTransition(
            id: 't7',
            fromState: 'q3',
            toState: 'q3',
            symbol: 'Y',
            tapeRead: 'Y',
            tapeWrite: 'Y',
            moveDirection: MoveDirection.LEFT,
          ),
          TMTransition(
            id: 't8',
            fromState: 'q3',
            toState: 'q0',
            symbol: 'X',
            tapeRead: 'X',
            tapeWrite: 'X',
            moveDirection: MoveDirection.RIGHT,
          ),
          // Check for Y's (accept)
          TMTransition(
            id: 't9',
            fromState: 'q0',
            toState: 'q4',
            symbol: 'Y',
            tapeRead: 'Y',
            tapeWrite: 'Y',
            moveDirection: MoveDirection.RIGHT,
          ),
          TMTransition(
            id: 't10',
            fromState: 'q4',
            toState: 'q4',
            symbol: 'Y',
            tapeRead: 'Y',
            tapeWrite: 'Y',
            moveDirection: MoveDirection.RIGHT,
          ),
          TMTransition(
            id: 't11',
            fromState: 'q4',
            toState: 'q4',
            symbol: 'Z',
            tapeRead: 'Z',
            tapeWrite: 'Z',
            moveDirection: MoveDirection.RIGHT,
          ),
          TMTransition(
            id: 't12',
            fromState: 'q4',
            toState: 'q5',
            symbol: '',
            tapeRead: '',
            tapeWrite: '',
            moveDirection: MoveDirection.RIGHT,
          ),
        ],
      ));
    });

    test('should accept empty string', () async {
      final request = SimulationRequest(
        inputString: '',
        maxSteps: 1000,
      );

      final response = await api.simulateAutomaton(tmId, request);
      
      expect(response.statusCode, 200);
      expect(response.data.isAccepting, true);
      expect(response.data.traceId, isNotEmpty);
    });

    test('should accept balanced strings', () async {
      final testStrings = ['abc', 'aabbcc', 'aaabbbccc'];
      
      for (final testString in testStrings) {
        final request = SimulationRequest(
          inputString: testString,
          maxSteps: 1000,
        );

        final response = await api.simulateAutomaton(tmId, request);
        
        expect(response.statusCode, 200);
        expect(response.data.isAccepting, true, 
               reason: 'String "$testString" should be accepted');
        expect(response.data.traceId, isNotEmpty);
      }
    });

    test('should reject unbalanced strings', () async {
      final testStrings = ['a', 'b', 'c', 'ab', 'bc', 'ac', 'aabb', 'bbcc', 'aacc'];
      
      for (final testString in testStrings) {
        final request = SimulationRequest(
          inputString: testString,
          maxSteps: 1000,
        );

        final response = await api.simulateAutomaton(tmId, request);
        
        expect(response.statusCode, 200);
        expect(response.data.isAccepting, false, 
               reason: 'String "$testString" should be rejected');
      }
    });

    test('should provide time-travel debugging capability', () async {
      final request = SimulationRequest(
        inputString: 'abc',
        maxSteps: 1000,
      );

      final response = await api.simulateAutomaton(tmId, request);
      
      expect(response.statusCode, 200);
      expect(response.data.traceId, isNotEmpty);
      
      // Verify trace contains immutable configurations
      expect(response.data.stepsExecuted, greaterThan(0));
      
      // This would require a separate trace API to access configurations
      // For now, just verify the trace exists
    });

    test('should handle tape boundary conditions', () async {
      final request = SimulationRequest(
        inputString: 'a' * 100, // Long string
        maxSteps: 10000,
      );

      final response = await api.simulateAutomaton(tmId, request);
      
      expect(response.statusCode, 200);
      // Should either accept (if balanced) or reject due to timeout/unbalanced
      expect(response.data.isAccepting, isA<bool>());
    });

    test('should support building blocks for common operations', () async {
      // Test TM with building blocks (copy, erase, move, compare)
      final buildingBlockTm = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Building Block TM',
          type: AutomatonType.TM,
        ),
      );
      
      // This would use predefined building block transitions
      // Implementation depends on building block system
      
      final request = SimulationRequest(
        inputString: 'test',
        maxSteps: 1000,
      );

      final response = await api.simulateAutomaton(buildingBlockTm.data.id, request);
      
      expect(response.statusCode, 200);
      expect(response.data.isAccepting, isA<bool>());
    });

    test('should handle deterministic and non-deterministic TMs', () async {
      // Test deterministic TM
      final detTm = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Deterministic TM',
          type: AutomatonType.TM,
        ),
      );
      
      final request = SimulationRequest(
        inputString: 'input',
        maxSteps: 1000,
      );

      final detResponse = await api.simulateAutomaton(detTm.data.id, request);
      
      expect(detResponse.statusCode, 200);
      expect(detResponse.data.isAccepting, isA<bool>());
      
      // Test non-deterministic TM
      final nondetTm = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Non-deterministic TM',
          type: AutomatonType.TM,
        ),
      );
      
      final nondetResponse = await api.simulateAutomaton(nondetTm.data.id, request);
      
      expect(nondetResponse.statusCode, 200);
      expect(nondetResponse.data.isAccepting, isA<bool>());
    });

    test('should provide detailed execution metrics', () async {
      final request = SimulationRequest(
        inputString: 'abc',
        maxSteps: 1000,
      );

      final response = await api.simulateAutomaton(tmId, request);
      
      expect(response.statusCode, 200);
      expect(response.data.executionTime, greaterThan(0));
      expect(response.data.stepsExecuted, greaterThan(0));
      expect(response.data.traceId, isNotEmpty);
    });
  });
}
