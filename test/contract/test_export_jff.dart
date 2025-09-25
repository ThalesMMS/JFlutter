// Contract test for GET /export/{id}/jff endpoint
// This test MUST fail initially - it defines the expected API contract

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('GET /export/{id}/jff Contract Tests', () {
    late AutomatonApi api;
    late String automatonId;

    setUp(() async {
      api = AutomatonApi();
      final createResponse = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Export Test FA',
          type: AutomatonType.DFA,
        ),
      );
      automatonId = createResponse.data.id;
    });

    test('should export automaton to JFLAP format', () async {
      final response = await api.exportToJFLAP(automatonId);
      
      expect(response.statusCode, 200);
      expect(response.data, isA<String>()); // JFLAP file content
      expect(response.data.isNotEmpty, true);
      expect(response.data.contains('<?xml'), true);
      expect(response.data.contains('<structure>'), true);
    });

    test('should return 404 for non-existent automaton', () async {
      final response = await api.exportToJFLAP('non-existent-id');
      
      expect(response.statusCode, 404);
    });

    test('should export PDA to JFLAP format', () async {
      final createResponse = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Export Test PDA',
          type: AutomatonType.PDA,
        ),
      );
      
      final response = await api.exportToJFLAP(createResponse.data.id);
      
      expect(response.statusCode, 200);
      expect(response.data.contains('<type>pda</type>'), true);
    });

    test('should export TM to JFLAP format', () async {
      final createResponse = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Export Test TM',
          type: AutomatonType.TM,
        ),
      );
      
      final response = await api.exportToJFLAP(createResponse.data.id);
      
      expect(response.statusCode, 200);
      expect(response.data.contains('<type>tm</type>'), true);
    });
  });
}
