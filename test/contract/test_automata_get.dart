// Contract test for GET /automata endpoint
// This test MUST fail initially - it defines the expected API contract

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('GET /automata Contract Tests', () {
    late AutomatonApi api;

    setUp(() {
      api = AutomatonApi();
    });

    test('should return list of automaton summaries', () async {
      // This test will fail until the endpoint is implemented
      final response = await api.listAutomata();
      
      expect(response.statusCode, 200);
      expect(response.data, isA<List<AutomatonSummary>>());
      expect(response.data.isNotEmpty, true);
    });

    test('should return empty list when no automata exist', () async {
      // Clear all automata first
      await api.clearAllAutomata();
      
      final response = await api.listAutomata();
      
      expect(response.statusCode, 200);
      expect(response.data, isEmpty);
    });

    test('should return automaton summaries with required fields', () async {
      final response = await api.listAutomata();
      
      expect(response.statusCode, 200);
      if (response.data.isNotEmpty) {
        final summary = response.data.first;
        expect(summary.id, isNotEmpty);
        expect(summary.name, isNotEmpty);
        expect(summary.type, isA<AutomatonType>());
        expect(summary.stateCount, isA<int>());
        expect(summary.transitionCount, isA<int>());
      }
    });
  });
}
