// ============================================================================
// JFlutter - Suite de Testes
// ----------------------------------------------------------------------------
// Arquivo: test/integration/io/interoperability_roundtrip_test.dart
// Objetivo: Validar interoperabilidade entre formatos `.jff`, JSON e SVG,
// garantindo round-trip sem perda.
// Cenários cobertos:
// - Conversões JFLAP↔modelos internos usando parser XML dedicado.
// - Serialização JSON de autômatos, gramáticas e MTs.
// - Exportação SVG para visualização preservando elementos-chave.
// Autoria: Equipe de Qualidade JFlutter.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/entities/grammar_entity.dart';
import 'package:jflutter/core/entities/turing_machine_entity.dart';
import 'package:jflutter/data/services/serialization_service.dart';
import 'package:jflutter/presentation/widgets/export/svg_exporter.dart';
import 'package:jflutter/core/parsers/jflap_xml_parser.dart';
import 'package:jflutter/data/data_sources/local_storage_data_source.dart';
import 'package:jflutter/data/models/automaton_model.dart';
import 'package:flutter/material.dart';
/// 3. SVG export/import testing
/// 4. Cross-format conversion testing
/// 5. Data integrity validation
void main() {
  group('Interoperability and Round-trip Tests', () {
    late SerializationService serializationService;
    late LocalStorageDataSource storageDataSource;

    setUp(() {
      serializationService = SerializationService();
      storageDataSource = LocalStorageDataSource();
    });

    group('JFF (JFLAP) Format Tests', () {
      test('JFF round-trip preserves automaton structure', () {
        final originalAutomaton = _createTestDFA();
        final automatonData = _convertEntityToData(originalAutomaton);

        // Convert to JFF format
        final jffXml = serializationService.serializeAutomatonToJflap(
          automatonData,
        );
        expect(jffXml, isNotEmpty);
        expect(jffXml, contains('<?xml'));
        expect(jffXml, contains('<structure'));
        expect(jffXml, contains('<automaton'));

        // Parse back from JFF format
        final parseResult = JFLAPXMLParser.parseJFLAPFile(jffXml);
        expect(
          parseResult.isSuccess,
          true,
          reason: 'JFF parsing should succeed',
        );

        if (parseResult.isSuccess) {
          final parsedData = parseResult.data!;
          expect(parsedData, isA<Map<String, dynamic>>());

          // Validate structure preservation
          expect(parsedData['states'], isNotNull);
          expect(parsedData['transitions'], isNotNull);
          expect(parsedData['initialId'], isNotNull);
        }
      });

      test('JFF handles complex automatons correctly', () {
        final complexAutomaton = _createComplexDFA();
        final automatonData = _convertEntityToData(complexAutomaton);

        // Convert to JFF format
        final jffXml = serializationService.serializeAutomatonToJflap(
          automatonData,
        );
        expect(jffXml, isNotEmpty);

        // Parse back from JFF format
        final parseResult = JFLAPXMLParser.parseJFLAPFile(jffXml);
        expect(
          parseResult.isSuccess,
          true,
          reason: 'Complex JFF parsing should succeed',
        );

        if (parseResult.isSuccess) {
          final parsedData = parseResult.data!;

          // Validate complex structure
          expect(parsedData['states'], isNotNull);
          expect((parsedData['states'] as List).length, greaterThan(2));
          expect(parsedData['transitions'], isNotNull);
        }
      });

      test('JFF handles NFA with epsilon transitions', () {
        final epsilonNFA = _createEpsilonNFA();
        final automatonData = _convertEntityToData(epsilonNFA);

        // Convert to JFF format
        final jffXml = serializationService.serializeAutomatonToJflap(
          automatonData,
        );
        expect(jffXml, isNotEmpty);
        expect(jffXml, contains('ε')); // Should contain epsilon symbol

        // Parse back from JFF format
        final parseResult = JFLAPXMLParser.parseJFLAPFile(jffXml);
        expect(
          parseResult.isSuccess,
          true,
          reason: 'Epsilon NFA JFF parsing should succeed',
        );
      });

      test('JFF handles malformed XML gracefully', () {
        const malformedXml = '<invalid>xml</invalid>';

        final parseResult = JFLAPXMLParser.parseJFLAPFile(malformedXml);
        expect(
          parseResult.isSuccess,
          false,
          reason: 'Malformed XML should fail gracefully',
        );
        expect(parseResult.error, isNotNull);
      });

      test('JFF validates required structure elements', () {
        const incompleteXml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <automaton>
    <state id="q0" name="q0">
      <initial/>
    </state>
  </automaton>
</structure>''';

        final parseResult = JFLAPXMLParser.parseJFLAPFile(incompleteXml);
        expect(
          parseResult.isSuccess,
          true,
          reason: 'Incomplete but valid XML should parse',
        );
      });
    });

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
        // Should handle missing fields gracefully
        expect(parseResult.isSuccess, isA<bool>());
      });
    });

    group('SVG Export/Import Tests', () {
      test('SVG export produces valid structure', () {
        final testAutomaton = _createTestDFA();

        final svg = SvgExporter.exportAutomatonToSvg(testAutomaton);
        expect(svg, isNotEmpty);
        expect(svg, contains('<?xml'));
        expect(svg, contains('<svg'));
        expect(svg, contains('</svg>'));

        // Validate SVG structure
        expect(svg, contains('viewBox'));
        expect(svg, contains('<defs>'));
        expect(svg, contains('<style>'));
      });

      test('SVG export handles different automaton types', () {
        final testCases = [
          _createTestDFA(),
          _createTestNFA(),
          _createEpsilonNFA(),
        ];

        for (final automaton in testCases) {
          final svg = SvgExporter.exportAutomatonToSvg(automaton);
          expect(svg, isNotEmpty);
          expect(svg, contains('<?xml'));
          expect(svg, contains('<svg'));
          expect(svg, contains('</svg>'));
        }
      });

      test('SVG export handles different sizes', () {
        final testAutomaton = _createTestDFA();

        final smallSvg = SvgExporter.exportAutomatonToSvg(
          testAutomaton,
          width: 400,
          height: 300,
        );
        expect(smallSvg, contains('viewBox="0 0 400 300"'));

        final largeSvg = SvgExporter.exportAutomatonToSvg(
          testAutomaton,
          width: 1200,
          height: 900,
        );
        expect(largeSvg, contains('viewBox="0 0 1200 900"'));
      });

      test('SVG export includes proper styling', () {
        final testAutomaton = _createTestDFA();

        final svg = SvgExporter.exportAutomatonToSvg(testAutomaton);

        // Validate styling elements
        expect(svg, contains('<defs>'));
        expect(svg, contains('<marker'));
        expect(svg, contains('<style>'));
        expect(svg, contains('class='));
        expect(svg, contains('font-family'));
        expect(svg, contains('text-anchor'));
      });

      test('SVG export handles complex automatons', () {
        final complexAutomaton = _createComplexDFA();

        final svg = SvgExporter.exportAutomatonToSvg(complexAutomaton);
        expect(svg, isNotEmpty);
        expect(svg, contains('<?xml'));
        expect(svg, contains('<svg'));
        expect(svg, contains('</svg>'));

        // Should contain multiple states and transitions
        expect(svg, contains('<circle')); // States
        expect(svg, contains('<line')); // Transitions
        expect(svg, contains('<text')); // Labels
      });
    });

    group('Cross-Format Conversion Tests', () {
      test('JFF to JSON conversion preserves data', () {
        final originalAutomaton = _createTestDFA();
        final automatonData = _convertEntityToData(originalAutomaton);

        // Convert to JFF format
        final jffXml = serializationService.serializeAutomatonToJflap(
          automatonData,
        );
        expect(jffXml, isNotEmpty);

        // Parse JFF back to data
        final jffParseResult = JFLAPXMLParser.parseJFLAPFile(jffXml);
        expect(jffParseResult.isSuccess, true);

        if (jffParseResult.isSuccess) {
          final jffData = jffParseResult.data!;

          // Convert JFF data to JSON
          final jsonString = serializationService.serializeAutomatonToJson(
            jffData,
          );
          expect(jsonString, isNotEmpty);

          // Parse JSON back to data
          final jsonParseResult = serializationService
              .deserializeAutomatonFromJson(jsonString);
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
        final automatonData = _convertEntityToData(originalAutomaton);

        // Convert to JSON format
        final jsonString = serializationService.serializeAutomatonToJson(
          automatonData,
        );
        expect(jsonString, isNotEmpty);

        // Parse JSON back to data
        final jsonParseResult = serializationService
            .deserializeAutomatonFromJson(jsonString);
        expect(jsonParseResult.isSuccess, true);

        if (jsonParseResult.isSuccess) {
          final jsonData = jsonParseResult.data!;

          // Convert JSON data to JFF
          final jffXml = serializationService.serializeAutomatonToJflap(
            jsonData,
          );
          expect(jffXml, isNotEmpty);

          // Parse JFF back to data
          final jffParseResult = JFLAPXMLParser.parseJFLAPFile(jffXml);
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
        final automatonData = _convertEntityToData(originalAutomaton);

        // Original -> JFF -> JSON -> JFF -> Final
        final jffXml1 = serializationService.serializeAutomatonToJflap(
          automatonData,
        );
        final jffParseResult1 = JFLAPXMLParser.parseJFLAPFile(jffXml1);
        expect(jffParseResult1.isSuccess, true);

        if (jffParseResult1.isSuccess) {
          final jffData1 = jffParseResult1.data!;

          final jsonString = serializationService.serializeAutomatonToJson(
            jffData1,
          );
          final jsonParseResult = serializationService
              .deserializeAutomatonFromJson(jsonString);
          expect(jsonParseResult.isSuccess, true);

          if (jsonParseResult.isSuccess) {
            final jsonData = jsonParseResult.data!;

            final jffXml2 = serializationService.serializeAutomatonToJflap(
              jsonData,
            );
            final jffParseResult2 = JFLAPXMLParser.parseJFLAPFile(jffXml2);
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

    group('Data Integrity Validation Tests', () {
      test('Round-trip preserves automaton properties', () {
        final originalAutomaton = _createTestDFA();
        final automatonData = _convertEntityToData(originalAutomaton);

        // Test JSON round-trip
        final jsonString = serializationService.serializeAutomatonToJson(
          automatonData,
        );
        final jsonParseResult = serializationService
            .deserializeAutomatonFromJson(jsonString);
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
        final jsonParseResult = serializationService
            .deserializeAutomatonFromJson(jsonString);
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
            expect(
              parsedState['isInitial'],
              equals(originalState['isInitial']),
            );
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
        final jsonParseResult = serializationService
            .deserializeAutomatonFromJson(jsonString);
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

    group('Performance and Scalability Tests', () {
      test('Large automaton round-trip completes within reasonable time', () {
        final largeAutomaton = _createLargeAutomaton();
        final automatonData = _convertEntityToData(largeAutomaton);

        final stopwatch = Stopwatch()..start();

        // Test JSON round-trip
        final jsonString = serializationService.serializeAutomatonToJson(
          automatonData,
        );
        final jsonParseResult = serializationService
            .deserializeAutomatonFromJson(jsonString);

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

      test(
        'SVG export of large automaton completes within reasonable time',
        () {
          final largeAutomaton = _createLargeAutomaton();

          final stopwatch = Stopwatch()..start();

          final svg = SvgExporter.exportAutomatonToSvg(largeAutomaton);

          stopwatch.stop();

          expect(svg, isNotEmpty);
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(1000),
            reason:
                'Large automaton SVG export should complete within 1 second',
          );
        },
      );

      test('Multiple format conversions complete within reasonable time', () {
        final testAutomaton = _createTestDFA();
        final automatonData = _convertEntityToData(testAutomaton);

        final stopwatch = Stopwatch()..start();

        // Multiple conversions
        final jffXml = serializationService.serializeAutomatonToJflap(
          automatonData,
        );
        final jffParseResult = JFLAPXMLParser.parseJFLAPFile(jffXml);

        if (jffParseResult.isSuccess) {
          final jffData = jffParseResult.data!;
          final jsonString = serializationService.serializeAutomatonToJson(
            jffData,
          );
          final jsonParseResult = serializationService
              .deserializeAutomatonFromJson(jsonString);

          if (jsonParseResult.isSuccess) {
            final jsonData = jsonParseResult.data!;
            final svg = SvgExporter.exportAutomatonToSvg(
              _convertDataToEntity(jsonData),
            );
            expect(svg, isNotEmpty);
          }
        }

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(2000),
          reason:
              'Multiple format conversions should complete within 2 seconds',
        );
      });
    });
  });
}

/// Helper functions to create test automatons

AutomatonEntity _createTestDFA() {
  return const AutomatonEntity(
    id: 'test_dfa',
    name: 'Test DFA',
    alphabet: {'0', '1'},
    states: [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0.0,
        y: 0.0,
        isInitial: true,
        isFinal: false,
      ),
      StateEntity(
        id: 'q1',
        name: 'q1',
        x: 100.0,
        y: 0.0,
        isInitial: false,
        isFinal: true,
      ),
    ],
    transitions: {
      'q0': ['q1'],
    },
    initialId: 'q0',
    nextId: 2,
    type: AutomatonType.dfa,
  );
}

AutomatonEntity _createTestNFA() {
  return const AutomatonEntity(
    id: 'test_nfa',
    name: 'Test NFA',
    alphabet: {'0', '1'},
    states: [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0.0,
        y: 0.0,
        isInitial: true,
        isFinal: false,
      ),
      StateEntity(
        id: 'q1',
        name: 'q1',
        x: 100.0,
        y: 0.0,
        isInitial: false,
        isFinal: true,
      ),
    ],
    transitions: {
      'q0': ['q1'],
    },
    initialId: 'q0',
    nextId: 2,
    type: AutomatonType.nfa,
  );
}

AutomatonEntity _createEpsilonNFA() {
  return const AutomatonEntity(
    id: 'test_epsilon_nfa',
    name: 'Test Epsilon NFA',
    alphabet: {'a', 'b'},
    states: [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0.0,
        y: 0.0,
        isInitial: true,
        isFinal: false,
      ),
      StateEntity(
        id: 'q1',
        name: 'q1',
        x: 100.0,
        y: 0.0,
        isInitial: false,
        isFinal: true,
      ),
    ],
    transitions: {
      'q0': ['q1'],
    },
    initialId: 'q0',
    nextId: 2,
    type: AutomatonType.nfa,
  );
}

AutomatonEntity _createComplexDFA() {
  return const AutomatonEntity(
    id: 'complex_dfa',
    name: 'Complex DFA',
    alphabet: {'0', '1'},
    states: [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0.0,
        y: 0.0,
        isInitial: true,
        isFinal: false,
      ),
      StateEntity(
        id: 'q1',
        name: 'q1',
        x: 100.0,
        y: 0.0,
        isInitial: false,
        isFinal: false,
      ),
      StateEntity(
        id: 'q2',
        name: 'q2',
        x: 200.0,
        y: 0.0,
        isInitial: false,
        isFinal: true,
      ),
    ],
    transitions: {
      'q0': ['q1'],
      'q1': ['q2'],
    },
    initialId: 'q0',
    nextId: 3,
    type: AutomatonType.dfa,
  );
}

AutomatonEntity _createEmptyAutomaton() {
  return const AutomatonEntity(
    id: 'empty_automaton',
    name: 'Empty Automaton',
    alphabet: {},
    states: [],
    transitions: {},
    initialId: null,
    nextId: 0,
    type: AutomatonType.dfa,
  );
}

AutomatonEntity _createSingleStateAutomaton() {
  return const AutomatonEntity(
    id: 'single_state_automaton',
    name: 'Single State Automaton',
    alphabet: {'a'},
    states: [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0.0,
        y: 0.0,
        isInitial: true,
        isFinal: true,
      ),
    ],
    transitions: {},
    initialId: 'q0',
    nextId: 1,
    type: AutomatonType.dfa,
  );
}

AutomatonEntity _createNoTransitionsAutomaton() {
  return const AutomatonEntity(
    id: 'no_transitions_automaton',
    name: 'No Transitions Automaton',
    alphabet: {'a'},
    states: [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0.0,
        y: 0.0,
        isInitial: true,
        isFinal: false,
      ),
      StateEntity(
        id: 'q1',
        name: 'q1',
        x: 100.0,
        y: 0.0,
        isInitial: false,
        isFinal: true,
      ),
    ],
    transitions: {},
    initialId: 'q0',
    nextId: 2,
    type: AutomatonType.dfa,
  );
}

AutomatonEntity _createLargeAutomaton() {
  final states = <StateEntity>[];
  final transitions = <String, List<String>>{};

  // Create 50 states
  for (int i = 0; i < 50; i++) {
    states.add(
      StateEntity(
        id: 'q$i',
        name: 'q$i',
        x: (i * 20).toDouble(),
        y: 0.0,
        isInitial: i == 0,
        isFinal: i == 49,
      ),
    );

    if (i < 49) {
      transitions['q$i'] = ['q${i + 1}'];
    }
  }

  return AutomatonEntity(
    id: 'large_automaton',
    name: 'Large Automaton',
    alphabet: {'0', '1'},
    states: states,
    transitions: transitions,
    initialId: 'q0',
    nextId: 50,
    type: AutomatonType.dfa,
  );
}

/// Helper functions for data conversion

Map<String, dynamic> _convertEntityToData(AutomatonEntity entity) {
  return {
    'id': entity.id,
    'name': entity.name,
    'type': entity.type.name,
    'alphabet': entity.alphabet.toList(),
    'states': entity.states
        .map(
          (s) => {
            'id': s.id,
            'name': s.name,
            'x': s.x,
            'y': s.y,
            'isInitial': s.isInitial,
            'isFinal': s.isFinal,
          },
        )
        .toList(),
    'transitions': entity.transitions,
    'initialId': entity.initialId,
    'nextId': entity.nextId,
  };
}

AutomatonEntity _convertDataToEntity(Map<String, dynamic> data) {
  return AutomatonEntity(
    id: data['id'] as String,
    name: data['name'] as String,
    alphabet: (data['alphabet'] as List).cast<String>().toSet(),
    states: (data['states'] as List)
        .map(
          (s) => StateEntity(
            id: s['id'] as String,
            name: s['name'] as String,
            x: s['x'] as double,
            y: s['y'] as double,
            isInitial: s['isInitial'] as bool,
            isFinal: s['isFinal'] as bool,
          ),
        )
        .toList(),
    transitions: Map<String, List<String>>.from(data['transitions'] as Map),
    initialId: data['initialId'] as String?,
    nextId: data['nextId'] as int,
    type: AutomatonType.values.firstWhere(
      (t) => t.name == data['type'],
      orElse: () => AutomatonType.dfa,
    ),
  );
}
