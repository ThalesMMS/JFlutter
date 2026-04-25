part of '../interoperability_roundtrip_test.dart';

void _runDataIntegrityTests() {
  group('Data Integrity Validation Tests', () {
    test('Round-trip preserves automaton properties', () {
      final originalAutomaton = _createTestDFA();
      final automatonData = _convertEntityToData(originalAutomaton);

      // Test JSON round-trip
      final jsonString = serializationService.serializeAutomatonToJson(
        automatonData,
      );
      final jsonParseResult = serializationService.deserializeAutomatonFromJson(
        jsonString,
      );
      expect(jsonParseResult.isSuccess, true);

      if (jsonParseResult.isSuccess) {
        final jsonData = jsonParseResult.data!;

        // Validate key properties are preserved
        expect(jsonData['id'], equals(automatonData['id']));
        expect(jsonData['name'], equals(automatonData['name']));
        expect(jsonData['type'], equals(automatonData['type']));
        expect(jsonData['alphabet'], equals(automatonData['alphabet']));
        expect(jsonData['initialId'], equals(automatonData['initialId']));
      }
    });

    test('Round-trip preserves state information', () {
      final originalAutomaton = _createTestDFA();
      final automatonData = _convertEntityToData(originalAutomaton);

      // Test JSON round-trip
      final jsonString = serializationService.serializeAutomatonToJson(
        automatonData,
      );
      final jsonParseResult = serializationService.deserializeAutomatonFromJson(
        jsonString,
      );
      expect(jsonParseResult.isSuccess, true);

      if (jsonParseResult.isSuccess) {
        final jsonData = jsonParseResult.data!;

        // Validate state information
        final originalStates = automatonData['states'] as List;
        final parsedStates = jsonData['states'] as List;

        expect(parsedStates.length, equals(originalStates.length));

        for (int i = 0; i < originalStates.length; i++) {
          final originalState = originalStates[i] as Map<String, dynamic>;
          final parsedState = parsedStates[i] as Map<String, dynamic>;

          expect(parsedState['id'], equals(originalState['id']));
          expect(parsedState['name'], equals(originalState['name']));
          expect(parsedState['isInitial'], equals(originalState['isInitial']));
          expect(parsedState['isFinal'], equals(originalState['isFinal']));
        }
      }
    });

    test('Round-trip preserves transition information', () {
      final originalAutomaton = _createTestDFA();
      final automatonData = _convertEntityToData(originalAutomaton);

      // Test JSON round-trip
      final jsonString = serializationService.serializeAutomatonToJson(
        automatonData,
      );
      final jsonParseResult = serializationService.deserializeAutomatonFromJson(
        jsonString,
      );
      expect(jsonParseResult.isSuccess, true);

      if (jsonParseResult.isSuccess) {
        final jsonData = jsonParseResult.data!;

        // Validate transition information
        final originalTransitions =
            automatonData['transitions'] as Map<String, dynamic>;
        final parsedTransitions =
            jsonData['transitions'] as Map<String, dynamic>;

        expect(parsedTransitions.length, equals(originalTransitions.length));

        for (final entry in originalTransitions.entries) {
          final key = entry.key;
          final value = entry.value;

          expect(parsedTransitions.containsKey(key), isTrue);
          expect(parsedTransitions[key], equals(value));
        }
      }
    });

    test('Round-trip handles edge cases gracefully', () {
      final edgeCases = [
        _createEmptyAutomaton(),
        _createSingleStateAutomaton(),
        _createNoTransitionsAutomaton(),
      ];

      for (final automaton in edgeCases) {
        final automatonData = _convertEntityToData(automaton);

        // Test JSON round-trip
        final jsonString = serializationService.serializeAutomatonToJson(
          automatonData,
        );
        final jsonParseResult = serializationService
            .deserializeAutomatonFromJson(jsonString);
        expect(
          jsonParseResult.isSuccess,
          true,
          reason: 'Edge case should handle round-trip gracefully',
        );
      }
    });
  });
}
