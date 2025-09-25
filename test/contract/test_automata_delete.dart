// Contract test for DELETE /automata/{id} endpoint
// This test MUST fail initially - it defines the expected API contract

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('DELETE /automata/{id} Contract Tests', () {
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

    test('should delete automaton successfully', () async {
      final response = await api.deleteAutomaton(automatonId);
      
      expect(response.statusCode, 204);
      
      // Verify automaton is deleted
      final getResponse = await api.getAutomaton(automatonId);
      expect(getResponse.statusCode, 404);
    });

    test('should return 404 for non-existent automaton', () async {
      final response = await api.deleteAutomaton('non-existent-id');
      
      expect(response.statusCode, 404);
    });
  });
}
