// Contract test for POST /automata/operations endpoint
// This test MUST fail initially - it defines the expected API contract

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('POST /automata/operations Contract Tests', () {
    late AutomatonApi api;
    late String automatonId1;
    late String automatonId2;

    setUp(() async {
      api = AutomatonApi();
      final createResponse1 = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'FA1',
          type: AutomatonType.DFA,
        ),
      );
      automatonId1 = createResponse1.data.id;

      final createResponse2 = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'FA2',
          type: AutomatonType.DFA,
        ),
      );
      automatonId2 = createResponse2.data.id;
    });

    test('should perform union operation', () async {
      final request = LanguageOperationRequest(
        operation: LanguageOperation.UNION,
        inputAutomata: [automatonId1, automatonId2],
      );

      final response = await api.performLanguageOperation(request);
      
      expect(response.statusCode, 200);
      expect(response.data, isA<LanguageOperationResult>());
      expect(response.data.operation, LanguageOperation.UNION);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
      expect(response.data.outputAutomaton, isNotEmpty);
    });

    test('should perform intersection operation', () async {
      final request = LanguageOperationRequest(
        operation: LanguageOperation.INTERSECTION,
        inputAutomata: [automatonId1, automatonId2],
      );

      final response = await api.performLanguageOperation(request);
      
      expect(response.statusCode, 200);
      expect(response.data.operation, LanguageOperation.INTERSECTION);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
    });

    test('should perform complement operation', () async {
      final request = LanguageOperationRequest(
        operation: LanguageOperation.COMPLEMENT,
        inputAutomata: [automatonId1],
      );

      final response = await api.performLanguageOperation(request);
      
      expect(response.statusCode, 200);
      expect(response.data.operation, LanguageOperation.COMPLEMENT);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
    });

    test('should perform concatenation operation', () async {
      final request = LanguageOperationRequest(
        operation: LanguageOperation.CONCATENATION,
        inputAutomata: [automatonId1, automatonId2],
      );

      final response = await api.performLanguageOperation(request);
      
      expect(response.statusCode, 200);
      expect(response.data.operation, LanguageOperation.CONCATENATION);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
    });

    test('should perform Kleene star operation', () async {
      final request = LanguageOperationRequest(
        operation: LanguageOperation.KLEENE_STAR,
        inputAutomata: [automatonId1],
      );

      final response = await api.performLanguageOperation(request);
      
      expect(response.statusCode, 200);
      expect(response.data.operation, LanguageOperation.KLEENE_STAR);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
    });

    test('should return 400 for invalid operation request', () async {
      final request = LanguageOperationRequest(
        operation: LanguageOperation.UNION,
        inputAutomata: [], // Invalid empty list
      );

      final response = await api.performLanguageOperation(request);
      
      expect(response.statusCode, 400);
    });
  });
}
