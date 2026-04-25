part of '../interoperability_roundtrip_test.dart';

void _runJsonFormatTests() {
  group('JSON Format Tests', () {
    test('JSON round-trip preserves automaton structure', () {
      final originalAutomaton = _createTestDFA();
      final automatonData = _convertEntityToData(originalAutomaton);

      // Convert to JSON format
      final jsonString = serializationService.serializeAutomatonToJson(
        automatonData,
      );
      expect(jsonString, isNotEmpty);

      // Validate JSON structure
      final jsonData = jsonDecode(jsonString);
      expect(jsonData, isA<Map<String, dynamic>>());
      expect(jsonData['id'], isNotNull);
      expect(jsonData['name'], isNotNull);
      expect(jsonData['states'], isNotNull);
      expect(jsonData['transitions'], isNotNull);

      // Parse back from JSON format
      final parseResult = serializationService.deserializeAutomatonFromJson(
        jsonString,
      );
      expect(
        parseResult.isSuccess,
        true,
        reason: 'JSON parsing should succeed',
      );

      if (parseResult.isSuccess) {
        final parsedData = parseResult.data!;

        // Validate structure preservation
        expect(parsedData['id'], equals(automatonData['id']));
        expect(parsedData['name'], equals(automatonData['name']));
        expect(parsedData['states'], isNotNull);
        expect(parsedData['transitions'], isNotNull);
      }
    });

    test('JSON handles complex automatons correctly', () {
      final complexAutomaton = _createComplexDFA();
      final automatonData = _convertEntityToData(complexAutomaton);

      // Convert to JSON format
      final jsonString = serializationService.serializeAutomatonToJson(
        automatonData,
      );
      expect(jsonString, isNotEmpty);

      // Parse back from JSON format
      final parseResult = serializationService.deserializeAutomatonFromJson(
        jsonString,
      );
      expect(
        parseResult.isSuccess,
        true,
        reason: 'Complex JSON parsing should succeed',
      );

      if (parseResult.isSuccess) {
        final parsedData = parseResult.data!;

        // Validate complex structure
        expect(parsedData['states'], isNotNull);
        expect((parsedData['states'] as List).length, greaterThan(2));
        expect(parsedData['transitions'], isNotNull);
      }
    });

    test('JSON handles different automaton types', () {
      final testCases = [
        _createTestDFA(),
        _createTestNFA(),
        _createEpsilonNFA(),
      ];

      for (final automaton in testCases) {
        final automatonData = _convertEntityToData(automaton);

        // Convert to JSON format
        final jsonString = serializationService.serializeAutomatonToJson(
          automatonData,
        );
        expect(jsonString, isNotEmpty);

        // Parse back from JSON format
        final parseResult = serializationService.deserializeAutomatonFromJson(
          jsonString,
        );
        expect(
          parseResult.isSuccess,
          true,
          reason: 'JSON parsing should succeed for ${automaton.type}',
        );
      }
    });

    test('JSON handles malformed data gracefully', () {
      const malformedJson = '{"invalid": json}';

      final parseResult = serializationService.deserializeAutomatonFromJson(
        malformedJson,
      );
      expect(
        parseResult.isSuccess,
        false,
        reason: 'Malformed JSON should fail gracefully',
      );
      expect(parseResult.error, isNotNull);
    });

    test('JSON validates required fields', () {
      const incompleteJson = '{"id": "test", "name": "Test"}';

      final parseResult = serializationService.deserializeAutomatonFromJson(
        incompleteJson,
      );
      expect(
        parseResult.isSuccess,
        false,
        reason: 'JSON missing required automaton fields should fail',
      );
      expect(parseResult.error, isNotNull);
      expect(
        parseResult.error,
        contains('Failed to deserialize JSON automaton'),
      );
    });
  });
}
