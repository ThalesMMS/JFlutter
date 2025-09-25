// Contract test for PUT /automata/{id} endpoint
// This test MUST fail initially - it defines the expected API contract

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('PUT /automata/{id} Contract Tests', () {
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
    });

    test('should update automaton successfully', () async {
      final updateRequest = UpdateAutomatonRequest(
        name: 'Updated FA',
        description: 'Updated description',
      );

      final response = await api.updateAutomaton(automatonId, updateRequest);
      
      expect(response.statusCode, 200);
      expect(response.data.name, 'Updated FA');
      expect(response.data.description, 'Updated description');
    });

    test('should return 404 for non-existent automaton', () async {
      final updateRequest = UpdateAutomatonRequest(name: 'Updated');
      
      final response = await api.updateAutomaton('non-existent-id', updateRequest);
      
      expect(response.statusCode, 404);
    });

    test('should update automaton states and transitions', () async {
      final updateRequest = UpdateAutomatonRequest(
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
      );

      final response = await api.updateAutomaton(automatonId, updateRequest);
      
      expect(response.statusCode, 200);
      expect(response.data.states.length, 2);
      expect(response.data.transitions.length, 1);
    });
  });
}
