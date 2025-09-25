// Contract test for GET /automata/{id} endpoint
// This test MUST fail initially - it defines the expected API contract

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('GET /automata/{id} Contract Tests', () {
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

    test('should return automaton by ID', () async {
      final response = await api.getAutomaton(automatonId);
      
      expect(response.statusCode, 200);
      expect(response.data, isA<Automaton>());
      expect(response.data.id, automatonId);
    });

    test('should return 404 for non-existent automaton', () async {
      final response = await api.getAutomaton('non-existent-id');
      
      expect(response.statusCode, 404);
      expect(response.error, isA<ErrorResponse>());
    });

    test('should return automaton with all required fields', () async {
      final response = await api.getAutomaton(automatonId);
      
      expect(response.statusCode, 200);
      final automaton = response.data;
      expect(automaton.id, isNotEmpty);
      expect(automaton.name, isNotEmpty);
      expect(automaton.type, isA<AutomatonType>());
      expect(automaton.states, isA<List<State>>());
      expect(automaton.transitions, isA<List<Transition>>());
      expect(automaton.alphabet, isA<Alphabet>());
      expect(automaton.metadata, isA<AutomatonMetadata>());
    });
  });
}
