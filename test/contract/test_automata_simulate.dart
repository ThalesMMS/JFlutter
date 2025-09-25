// Contract test for POST /automata/{id}/simulate endpoint
// This test MUST fail initially - it defines the expected API contract

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('POST /automata/{id}/simulate Contract Tests', () {
    late AutomatonApi api;
    late String automatonId;

    setUp(() async {
      api = AutomatonApi();
      final createResponse = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Test FA',
          type: AutomatonType.DFA,
        ),
      );
      automatonId = createResponse.data.id;
      
      // Add states and transitions for a simple FA
      await api.updateAutomaton(automatonId, UpdateAutomatonRequest(
        states: [
          State(id: 'q0', name: 'q0', position: Position(x: 0, y: 0), isInitial: true),
          State(id: 'q1', name: 'q1', position: Position(x: 100, y: 0), isAccepting: true),
        ],
        transitions: [
          Transition(
            id: 't1',
            fromState: 'q0',
            toState: 'q1',
            symbol: 'a',
          ),
        ],
      ));
    });

    test('should simulate automaton with accepting string', () async {
      final request = SimulationRequest(
        inputString: 'a',
        maxSteps: 100,
      );

      final response = await api.simulateAutomaton(automatonId, request);
      
      expect(response.statusCode, 200);
      expect(response.data, isA<SimulationResult>());
      expect(response.data.isAccepting, true);
      expect(response.data.traceId, isNotEmpty);
    });

    test('should simulate automaton with rejecting string', () async {
      final request = SimulationRequest(
        inputString: 'b',
        maxSteps: 100,
      );

      final response = await api.simulateAutomaton(automatonId, request);
      
      expect(response.statusCode, 200);
      expect(response.data.isAccepting, false);
    });

    test('should return 400 for invalid simulation request', () async {
      final request = SimulationRequest(
        inputString: 'a',
        maxSteps: -1, // Invalid max steps
      );

      final response = await api.simulateAutomaton(automatonId, request);
      
      expect(response.statusCode, 400);
    });

    test('should return 404 for non-existent automaton', () async {
      final request = SimulationRequest(inputString: 'a');
      
      final response = await api.simulateAutomaton('non-existent-id', request);
      
      expect(response.statusCode, 404);
    });
  });
}
