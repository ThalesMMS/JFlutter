// Contract test for POST /automata endpoint
// This test MUST fail initially - it defines the expected API contract

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('POST /automata Contract Tests', () {
    late AutomatonApi api;

    setUp(() {
      api = AutomatonApi();
    });

    test('should create finite automaton successfully', () async {
      final request = CreateAutomatonRequest(
        name: 'Test FA',
        type: AutomatonType.DFA,
        description: 'Test finite automaton',
      );

      final response = await api.createAutomaton(request);
      
      expect(response.statusCode, 201);
      expect(response.data, isA<Automaton>());
      expect(response.data.name, 'Test FA');
      expect(response.data.type, AutomatonType.DFA);
      expect(response.data.id, isNotEmpty);
    });

    test('should create pushdown automaton successfully', () async {
      final request = CreateAutomatonRequest(
        name: 'Test PDA',
        type: AutomatonType.PDA,
        description: 'Test pushdown automaton',
      );

      final response = await api.createAutomaton(request);
      
      expect(response.statusCode, 201);
      expect(response.data, isA<Automaton>());
      expect(response.data.type, AutomatonType.PDA);
    });

    test('should create Turing machine successfully', () async {
      final request = CreateAutomatonRequest(
        name: 'Test TM',
        type: AutomatonType.TM,
        description: 'Test Turing machine',
      );

      final response = await api.createAutomaton(request);
      
      expect(response.statusCode, 201);
      expect(response.data, isA<Automaton>());
      expect(response.data.type, AutomatonType.TM);
    });

    test('should return 400 for invalid request', () async {
      final request = CreateAutomatonRequest(
        name: '', // Invalid empty name
        type: AutomatonType.DFA,
      );

      final response = await api.createAutomaton(request);
      
      expect(response.statusCode, 400);
      expect(response.error, isA<ErrorResponse>());
    });
  });
}
