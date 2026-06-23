part of '../interoperability_roundtrip_test.dart';

void _runPerformanceTests() {
  group('Performance and Scalability Tests', () {
    test('Large automaton round-trip completes within reasonable time', () {
      final largeAutomaton = _createLargeAutomaton();
      final automatonData = _copyAutomatonData(largeAutomaton);

      final stopwatch = Stopwatch()..start();

      // Test JSON round-trip
      final jsonString = _serializeAutomatonToJson(
        automatonData,
      );
      final jsonParseResult = _deserializeAutomatonFromJson(
        jsonString,
      );

      stopwatch.stop();

      expect(
        jsonParseResult.isSuccess,
        true,
        reason: 'Large automaton round-trip should succeed',
      );
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Large automaton round-trip should complete within 1 second',
      );
    });

    test('SVG export of large automaton completes within reasonable time', () {
      final largeAutomaton = _createLargeAutomaton();

      final stopwatch = Stopwatch()..start();

      final svg = SvgExporter.exportFsaToSvg(_fsaFromData(largeAutomaton));

      stopwatch.stop();

      expect(svg, isNotEmpty);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Large automaton SVG export should complete within 1 second',
      );
    });

    test('Multiple format conversions complete within reasonable time', () {
      final testAutomaton = _createTestDFA();
      final automatonData = _copyAutomatonData(testAutomaton);

      final stopwatch = Stopwatch()..start();

      // Multiple conversions
      final jffXml = _serializeAutomatonToJflap(
        automatonData,
      );
      final jffParseResult = _deserializeAutomatonFromJflap(jffXml);
      expect(jffParseResult.isSuccess, true);

      final jsonString = _serializeAutomatonToJson(
        automatonData,
      );
      final jsonParseResult = _deserializeAutomatonFromJson(
        jsonString,
      );
      expect(jsonParseResult.isSuccess, true);

      final jsonData = jsonParseResult.data!;
      final svg = SvgExporter.exportFsaToSvg(
        _fsaFromData(jsonData),
      );
      expect(svg, isNotEmpty);

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Multiple format conversions should complete within 2 seconds',
      );
    });
  });
}
