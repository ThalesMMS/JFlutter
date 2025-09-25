// Contract test for POST /automata/{id}/algorithms endpoint
// This test MUST fail initially - it defines the expected API contract

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('POST /automata/{id}/algorithms Contract Tests', () {
    late AutomatonApi api;
    late String automatonId;

    setUp(() async {
      api = AutomatonApi();
      final createResponse = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Test NFA',
          type: AutomatonType.NFA,
        ),
      );
      automatonId = createResponse.data.id;
    });

    test('should run NFA to DFA conversion', () async {
      final request = AlgorithmRequest(
        algorithmType: AlgorithmType.NFA_TO_DFA,
      );

      final response = await api.runAlgorithm(automatonId, request);
      
      expect(response.statusCode, 200);
      expect(response.data, isA<AlgorithmResult>());
      expect(response.data.algorithmType, AlgorithmType.NFA_TO_DFA);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
      expect(response.data.outputAutomaton, isNotEmpty);
    });

    test('should run DFA minimization', () async {
      final request = AlgorithmRequest(
        algorithmType: AlgorithmType.MINIMIZE_DFA,
      );

      final response = await api.runAlgorithm(automatonId, request);
      
      expect(response.statusCode, 200);
      expect(response.data.algorithmType, AlgorithmType.MINIMIZE_DFA);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
    });

    test('should run regex to NFA conversion', () async {
      final request = AlgorithmRequest(
        algorithmType: AlgorithmType.REGEX_TO_NFA,
        parameters: {'regex': 'a*b+'},
      );

      final response = await api.runAlgorithm(automatonId, request);
      
      expect(response.statusCode, 200);
      expect(response.data.algorithmType, AlgorithmType.REGEX_TO_NFA);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
    });

    test('should return 400 for invalid algorithm request', () async {
      final request = AlgorithmRequest(
        algorithmType: null, // Invalid algorithm type
      );

      final response = await api.runAlgorithm(automatonId, request);
      
      expect(response.statusCode, 400);
    });

    test('should return 404 for non-existent automaton', () async {
      final request = AlgorithmRequest(
        algorithmType: AlgorithmType.NFA_TO_DFA,
      );
      
      final response = await api.runAlgorithm('non-existent-id', request);
      
      expect(response.statusCode, 404);
    });
  });
}
