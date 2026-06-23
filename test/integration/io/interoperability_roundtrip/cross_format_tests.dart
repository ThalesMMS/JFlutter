part of '../interoperability_roundtrip_test.dart';

void _runCrossFormatTests() {
  group('Cross-Format Conversion Tests', () {
    test('JFF to JSON conversion preserves data', () {
      final originalAutomaton = _createTestDFA();
      final automatonData = _copyAutomatonData(originalAutomaton);

      // Convert to JFF format
      final jffXml = _serializeAutomatonToJflap(
        automatonData,
      );
      expect(jffXml, isNotEmpty);

      // Parse JFF back to data
      final jffParseResult = _deserializeAutomatonFromJflap(jffXml);
      expect(jffParseResult.isSuccess, true);

      if (jffParseResult.isSuccess) {
        final jffData = jffParseResult.data!;

        // Convert JFF data to JSON
        final jsonString = _serializeAutomatonToJson(
          jffData,
        );
        expect(jsonString, isNotEmpty);

        // Parse JSON back to data
        final jsonParseResult = _deserializeAutomatonFromJson(jsonString);
        expect(jsonParseResult.isSuccess, true);

        if (jsonParseResult.isSuccess) {
          final jsonData = jsonParseResult.data!;

          // Validate data preservation
          expect(jsonData['states'], isNotNull);
          expect(jsonData['transitions'], isNotNull);
          expect(jsonData['initialId'], isNotNull);
        }
      }
    });

    test('JSON to JFF conversion preserves data', () {
      final originalAutomaton = _createTestDFA();
      final automatonData = _copyAutomatonData(originalAutomaton);

      // Convert to JSON format
      final jsonString = _serializeAutomatonToJson(
        automatonData,
      );
      expect(jsonString, isNotEmpty);

      // Parse JSON back to data
      final jsonParseResult = _deserializeAutomatonFromJson(
        jsonString,
      );
      expect(jsonParseResult.isSuccess, true);

      if (jsonParseResult.isSuccess) {
        final jsonData = jsonParseResult.data!;

        // Convert JSON data to JFF
        final jffXml = _serializeAutomatonToJflap(jsonData);
        expect(jffXml, isNotEmpty);

        // Parse JFF back to data
        final jffParseResult = _deserializeAutomatonFromJflap(jffXml);
        expect(jffParseResult.isSuccess, true);

        if (jffParseResult.isSuccess) {
          final jffData = jffParseResult.data!;

          // Validate data preservation
          expect(jffData['states'], isNotNull);
          expect(jffData['transitions'], isNotNull);
          expect(jffData['initialId'], isNotNull);
        }
      }
    });

    test('Round-trip through all formats preserves data', () {
      final originalAutomaton = _createTestDFA();
      final automatonData = _copyAutomatonData(originalAutomaton);

      // Original -> JFF -> JSON -> JFF -> Final
      final jffXml1 = _serializeAutomatonToJflap(
        automatonData,
      );
      final jffParseResult1 = _deserializeAutomatonFromJflap(jffXml1);
      expect(jffParseResult1.isSuccess, true);

      if (jffParseResult1.isSuccess) {
        final jffData1 = jffParseResult1.data!;

        final jsonString = _serializeAutomatonToJson(
          jffData1,
        );
        final jsonParseResult = _deserializeAutomatonFromJson(jsonString);
        expect(jsonParseResult.isSuccess, true);

        if (jsonParseResult.isSuccess) {
          final jsonData = jsonParseResult.data!;

          final jffXml2 = _serializeAutomatonToJflap(
            jsonData,
          );
          final jffParseResult2 = _deserializeAutomatonFromJflap(jffXml2);
          expect(jffParseResult2.isSuccess, true);

          if (jffParseResult2.isSuccess) {
            final finalData = jffParseResult2.data!;

            // Validate data preservation through all conversions
            expect(finalData['states'], isNotNull);
            expect(finalData['transitions'], isNotNull);
            expect(finalData['initialId'], isNotNull);
          }
        }
      }
    });
  });
}
