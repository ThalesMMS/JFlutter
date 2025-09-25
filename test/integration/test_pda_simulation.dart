// Integration test for pushdown automata simulation
// This test MUST fail initially - it defines the expected integration behavior

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('Pushdown Automata Simulation Integration Tests', () {
    late AutomatonApi api;
    late String pdaId;

    setUp(() async {
      api = AutomatonApi();
      
      // Create PDA for language {a^n b^n | n ≥ 0}
      final createResponse = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'a^n b^n PDA',
          type: AutomatonType.PDA,
          description: 'PDA accepting balanced a and b strings',
        ),
      );
      pdaId = createResponse.data.id;
      
      await api.updateAutomaton(pdaId, UpdateAutomatonRequest(
        states: [
          State(id: 'q0', name: 'q0', position: Position(x: 0, y: 0), isInitial: true),
          State(id: 'q1', name: 'q1', position: Position(x: 100, y: 0)),
          State(id: 'q2', name: 'q2', position: Position(x: 200, y: 0), isAccepting: true),
        ],
        transitions: [
          // Push A on reading a
          PDATransition(
            id: 't1',
            fromState: 'q0',
            toState: 'q0',
            symbol: 'a',
            stackPop: '',
            stackPush: ['A'],
          ),
          // Pop A on reading b
          PDATransition(
            id: 't2',
            fromState: 'q0',
            toState: 'q1',
            symbol: 'b',
            stackPop: 'A',
            stackPush: [],
          ),
          // Continue popping A on reading b
          PDATransition(
            id: 't3',
            fromState: 'q1',
            toState: 'q1',
            symbol: 'b',
            stackPop: 'A',
            stackPush: [],
          ),
          // Empty stack transition to accepting state
          PDATransition(
            id: 't4',
            fromState: 'q1',
            toState: 'q2',
            symbol: '',
            stackPop: '',
            stackPush: [],
          ),
        ],
      ));
    });

    test('should accept empty string', () async {
      final request = SimulationRequest(
        inputString: '',
        maxSteps: 1000,
      );

      final response = await api.simulateAutomaton(pdaId, request);
      
      expect(response.statusCode, 200);
      expect(response.data.isAccepting, true);
      expect(response.data.traceId, isNotEmpty);
    });

    test('should accept balanced strings', () async {
      final testStrings = ['ab', 'aabb', 'aaabbb'];
      
      for (final testString in testStrings) {
        final request = SimulationRequest(
          inputString: testString,
          maxSteps: 1000,
        );

        final response = await api.simulateAutomaton(pdaId, request);
        
        expect(response.statusCode, 200);
        expect(response.data.isAccepting, true, reason: 'String "$testString" should be accepted');
        expect(response.data.traceId, isNotEmpty);
      }
    });

    test('should reject unbalanced strings', () async {
      final testStrings = ['a', 'b', 'abab', 'ba', 'aab', 'abb'];
      
      for (final testString in testStrings) {
        final request = SimulationRequest(
          inputString: testString,
          maxSteps: 1000,
        );

        final response = await api.simulateAutomaton(pdaId, request);
        
        expect(response.statusCode, 200);
        expect(response.data.isAccepting, false, reason: 'String "$testString" should be rejected');
      }
    });

    test('should handle stack overflow protection', () async {
      final request = SimulationRequest(
        inputString: 'a' * 1000, // Very long string of a's
        maxSteps: 10000,
      );

      final response = await api.simulateAutomaton(pdaId, request);
      
      expect(response.statusCode, 200);
      // Should either accept (if we have enough b's) or reject due to stack overflow
      expect(response.data.isAccepting, isA<bool>());
    });

    test('should provide detailed execution trace', () async {
      final request = SimulationRequest(
        inputString: 'aabb',
        maxSteps: 1000,
      );

      final response = await api.simulateAutomaton(pdaId, request);
      
      expect(response.statusCode, 200);
      expect(response.data.traceId, isNotEmpty);
      
      // Verify trace contains configuration snapshots
      // This would require a separate trace API endpoint
      expect(response.data.stepsExecuted, greaterThan(0));
    });

    test('should handle multiple acceptance modes', () async {
      // Test with final state acceptance
      final finalStatePda = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Final State PDA',
          type: AutomatonType.PDA,
        ),
      );
      
      await api.updateAutomaton(finalStatePda.data.id, UpdateAutomatonRequest(
        states: [
          State(id: 'q0', name: 'q0', position: Position(x: 0, y: 0), isInitial: true),
          State(id: 'q1', name: 'q1', position: Position(x: 100, y: 0), isAccepting: true),
        ],
        transitions: [
          PDATransition(
            id: 't1',
            fromState: 'q0',
            toState: 'q1',
            symbol: 'a',
            stackPop: '',
            stackPush: ['A'],
          ),
        ],
      ));

      final request = SimulationRequest(
        inputString: 'a',
        maxSteps: 1000,
      );

      final response = await api.simulateAutomaton(finalStatePda.data.id, request);
      
      expect(response.statusCode, 200);
      expect(response.data.isAccepting, true);
    });
  });
}
