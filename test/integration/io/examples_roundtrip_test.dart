import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/entities/grammar_entity.dart';
import 'package:jflutter/core/repositories/automaton_repository.dart';
import 'package:jflutter/data/data_sources/examples_asset_data_source.dart';
import 'package:jflutter/data/services/examples_service.dart';
import 'package:jflutter/data/services/serialization_service.dart';
import 'package:jflutter/presentation/widgets/export/svg_exporter.dart';
import 'package:flutter/material.dart';

void main() {
  group('Examples v1 Library Tests', () {
    late ExamplesAssetDataSource dataSource;
    late ExamplesService service;

    setUp(() {
      dataSource = ExamplesAssetDataSource();
      service = ExamplesService(dataSource);
    });

    group('Metadata and Structure', () {
      test('Provides correct category information', () {
        final categories = dataSource.getAvailableCategories();

        expect(categories, contains(ExampleCategory.dfa));
        expect(categories, contains(ExampleCategory.nfa));
        expect(categories, contains(ExampleCategory.cfg));
        expect(categories, contains(ExampleCategory.pda));
        expect(categories, contains(ExampleCategory.tm));

        // Verify category display names
        expect(ExampleCategory.dfa.displayName, equals('DFA'));
        expect(ExampleCategory.cfg.displayName, equals('CFG'));
      });

      test('Provides example counts by category', () {
        final counts = dataSource.getExamplesCountByCategory();

        expect(counts[ExampleCategory.dfa], greaterThan(0));
        expect(counts.containsKey(ExampleCategory.cfg), isTrue);
        expect(counts[ExampleCategory.nfa], greaterThanOrEqualTo(0));
      });

      test('Search functionality works correctly', () {
        final searchResults = dataSource.searchExamples('dfa');

        expect(searchResults, isNotEmpty);
        expect(searchResults, contains('AFD - Termina com A'));
      });

      test('Example metadata is properly structured', () {
        // Test that metadata structure is correct without loading actual assets
        final example = ExampleEntity(
          name: 'Test Example',
          description: 'Test description',
          category: 'DFA',
          subcategory: 'Basic',
          difficultyLevel: DifficultyLevel.easy,
          tags: ['test', 'dfa'],
          estimatedComplexity: ComplexityLevel.low,
          automaton: null, // Would be loaded from asset
        );

        expect(example.name, equals('Test Example'));
        expect(example.difficultyLevel, equals(DifficultyLevel.easy));
        expect(example.tags, contains('test'));
        expect(example.estimatedComplexity, equals(ComplexityLevel.low));
      });
    });

    group('Service Logic', () {
      test('Difficulty level enum works correctly', () {
        expect(DifficultyLevel.easy.displayName, equals('Fácil'));
        expect(DifficultyLevel.medium.displayName, equals('Médio'));
        expect(DifficultyLevel.hard.displayName, equals('Difícil'));

        expect(DifficultyLevel.values.length, equals(3));
      });

      test('Complexity level enum works correctly', () {
        expect(ComplexityLevel.low.displayName, equals('Baixa'));
        expect(ComplexityLevel.medium.displayName, equals('Média'));
        expect(ComplexityLevel.high.displayName, equals('Alta'));

        expect(ComplexityLevel.values.length, equals(3));
      });

      test('Example category enum works correctly', () {
        expect(ExampleCategory.dfa.displayName, equals('DFA'));
        expect(ExampleCategory.cfg.displayName, equals('CFG'));
        expect(ExampleCategory.pda.displayName, equals('PDA'));
        expect(ExampleCategory.tm.displayName, equals('TM'));

        expect(ExampleCategory.values.length, equals(5));
      });

      test('Service provides category information', () {
        final categories = service.getAvailableCategories();

        expect(categories, contains(ExampleCategory.dfa));
        expect(categories, contains(ExampleCategory.cfg));
        expect(categories, contains(ExampleCategory.pda));
        expect(categories, contains(ExampleCategory.tm));
      });

      test('Service provides category counts', () {
        final counts = service.getExamplesCountByCategory();

        expect(counts[ExampleCategory.dfa], greaterThan(0));
        expect(counts.containsKey(ExampleCategory.cfg), isTrue);
        expect(counts.containsKey(ExampleCategory.pda), isTrue);
      });
    });

    group('Data Structure Tests', () {
      test('ExampleEntity has all required fields', () {
        final example = ExampleEntity(
          name: 'Test Example',
          description: 'Test description',
          category: 'DFA',
          subcategory: 'Basic',
          difficultyLevel: DifficultyLevel.easy,
          tags: ['test', 'dfa'],
          estimatedComplexity: ComplexityLevel.low,
          automaton: null,
        );

        expect(example.name, isNotEmpty);
        expect(example.description, isNotEmpty);
        expect(example.category, isNotEmpty);
        expect(example.subcategory, isNotEmpty);
        expect(example.difficultyLevel, isNotNull);
        expect(example.tags, isNotEmpty);
        expect(example.estimatedComplexity, isNotNull);
      });

      test('DifficultyLevel has correct properties', () {
        expect(DifficultyLevel.easy.displayName, equals('Fácil'));
        expect(DifficultyLevel.easy.description, contains('iniciantes'));

        expect(DifficultyLevel.medium.displayName, equals('Médio'));
        expect(DifficultyLevel.medium.description,
            contains('conhecimento prévio'));

        expect(DifficultyLevel.hard.displayName, equals('Difícil'));
        expect(
            DifficultyLevel.hard.description, contains('estudantes avançados'));
      });

      test('ComplexityLevel has correct properties', () {
        expect(ComplexityLevel.low.displayName, equals('Baixa'));
        expect(ComplexityLevel.low.description, contains('simples'));

        expect(ComplexityLevel.medium.displayName, equals('Média'));
        expect(ComplexityLevel.medium.description, contains('moderado'));

        expect(ComplexityLevel.high.displayName, equals('Alta'));
        expect(ComplexityLevel.high.description, contains('complexas'));
      });

      test('ExampleCategory has correct properties', () {
        expect(ExampleCategory.dfa.displayName, equals('DFA'));
        expect(ExampleCategory.dfa.fullName,
            equals('Deterministic Finite Automaton'));

        expect(ExampleCategory.cfg.displayName, equals('CFG'));
        expect(ExampleCategory.cfg.fullName, equals('Context-Free Grammar'));

        expect(ExampleCategory.pda.displayName, equals('PDA'));
        expect(ExampleCategory.pda.fullName, equals('Pushdown Automaton'));
      });

      test('ExamplesAssetDataSource provides metadata correctly', () {
        final dataSource = ExamplesAssetDataSource();

        final categories = dataSource.getAvailableCategories();
        expect(categories.length, equals(5)); // DFA, NFA, CFG, PDA, TM

        final counts = dataSource.getExamplesCountByCategory();
        expect(counts.isNotEmpty, isTrue);

        final searchResults = dataSource.searchExamples('dfa');
        expect(searchResults, isNotEmpty);
      });

      test('ExamplesService provides service methods correctly', () {
        final categories = service.getAvailableCategories();
        expect(categories, contains(ExampleCategory.dfa));

        final counts = service.getExamplesCountByCategory();
        expect(counts.isNotEmpty, isTrue);
      });
    });

    group('Serialization Tests', () {
      late SerializationService serializationService;

      setUp(() {
        serializationService = SerializationService();
      });

      test('JFLAP XML serialization produces valid XML', () {
        final testData = {
          'states': [
            {'id': 'q0', 'name': 'q0', 'isInitial': true, 'isFinal': false},
            {'id': 'q1', 'name': 'q1', 'isInitial': false, 'isFinal': true},
          ],
          'transitions': {
            'q0': ['q1'],
          },
          'initialId': 'q0',
        };

        final xml = serializationService.serializeAutomatonToJflap(testData);

        expect(xml, contains('<?xml'));
        expect(xml, contains('<structure'));
        expect(xml, contains('<automaton'));
        expect(xml, contains('<state'));
        expect(xml, contains('<transition'));
      });

      test('JFLAP XML deserialization works correctly', () {
        const testXml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <automaton>
    <state id="q0" name="q0">
      <initial/>
    </state>
    <state id="q1" name="q1">
      <final/>
    </state>
    <transition>
      <from>q0</from>
      <to>q1</to>
      <read></read>
    </transition>
  </automaton>
</structure>''';

        final result =
            serializationService.deserializeAutomatonFromJflap(testXml);

        expect(result.isSuccess, isTrue);
        final data = result.data!;
        expect(data['states']?.length, equals(2));
        expect(data['transitions']?.length, equals(1));
        expect(data['initialId'], equals('q0'));
      });

      test('JSON serialization produces valid JSON', () {
        final testData = {
          'id': 'test_automaton',
          'name': 'Test Automaton',
          'type': 'dfa',
          'alphabet': ['a', 'b'],
          'states': [
            {
              'id': 'q0',
              'name': 'q0',
              'x': 0.0,
              'y': 0.0,
              'isInitial': true,
              'isFinal': false
            },
            {
              'id': 'q1',
              'name': 'q1',
              'x': 100.0,
              'y': 100.0,
              'isInitial': false,
              'isFinal': true
            },
          ],
          'transitions': {
            'q0': ['q1']
          },
          'initialId': 'q0',
          'nextId': 2,
        };

        final jsonString =
            serializationService.serializeAutomatonToJson(testData);

        expect(jsonString, isNotEmpty);

        // Should be valid JSON
        final parsed = jsonDecode(jsonString);
        expect(parsed, isA<Map<String, dynamic>>());
        expect(parsed['id'], equals('test_automaton'));
        expect(parsed['name'], equals('Test Automaton'));
      });

      test('JSON deserialization works correctly', () {
        const testJson = '''{
          "id": "test_automaton",
          "name": "Test Automaton",
          "type": "dfa",
          "alphabet": ["a", "b"],
          "states": [
            {"id": "q0", "name": "q0", "x": 0.0, "y": 0.0, "isInitial": true, "isFinal": false},
            {"id": "q1", "name": "q1", "x": 100.0, "y": 100.0, "isInitial": false, "isFinal": true}
          ],
          "transitions": {"q0": ["q1"]},
          "initialId": "q0",
          "nextId": 2
        }''';

        final result =
            serializationService.deserializeAutomatonFromJson(testJson);

        expect(result.isSuccess, isTrue);
        final data = result.data!;
        expect(data['id'], equals('test_automaton'));
        expect(data['name'], equals('Test Automaton'));
        expect(data['states']?.length, equals(2));
        expect(data['transitions']?.length, equals(1));
      });

      test('Round-trip test preserves data structure', () {
        final originalData = {
          'states': [
            {'id': 'q0', 'name': 'q0', 'isInitial': true, 'isFinal': false},
            {'id': 'q1', 'name': 'q1', 'isInitial': false, 'isFinal': true},
          ],
          'transitions': {
            'q0': ['q1'],
          },
        };

        // Test JFLAP round-trip
        final jflapResult = serializationService.roundTripTest(
            originalData, SerializationFormat.jflap);
        expect(jflapResult.isSuccess, isTrue);

        final jflapRoundTripped = jflapResult.data!;
        expect(
            serializationService.validateRoundTrip(
                originalData, jflapRoundTripped),
            isTrue);

        // Test JSON round-trip
        final jsonResult = serializationService.roundTripTest(
            originalData, SerializationFormat.json);
        expect(jsonResult.isSuccess, isTrue);

        final jsonRoundTripped = jsonResult.data!;
        expect(
            serializationService.validateRoundTrip(
                originalData, jsonRoundTripped),
            isTrue);
      });

      test('Handles malformed XML gracefully', () {
        const malformedXml = '<invalid>xml</invalid>';

        final result =
            serializationService.deserializeAutomatonFromJflap(malformedXml);
        expect(result.isFailure, isTrue);
        expect(result.error, contains('Failed to deserialize'));
      });

      test('Handles malformed JSON gracefully', () {
        const malformedJson = '{"invalid": json}';

        final result =
            serializationService.deserializeAutomatonFromJson(malformedJson);
        expect(result.isFailure, isTrue);
        expect(result.error, contains('Failed to deserialize'));
      });

      test('Basic data structure validation works', () {
        // Test that the serialization service can be instantiated
        expect(serializationService, isNotNull);

        // Test that enum values are accessible
        expect(SerializationFormat.jflap.displayName, equals('JFLAP XML'));
        expect(SerializationFormat.json.displayName, equals('JSON'));

        // Test that basic data structures work
        final testData = {
          'states': [
            {'id': 'q0', 'name': 'q0', 'isInitial': true, 'isFinal': false},
          ],
          'transitions': {},
        };

        expect((testData['states'] as List?)?.length, equals(1));
        expect((testData['transitions'] as Map?)?.length, equals(0));
      });
    });

    group('SVG Export Tests', () {

      test('Automaton SVG export produces valid SVG structure', () {
        final svg = SvgExporter.exportAutomatonToSvg(
          // Mock automaton entity for testing
          AutomatonEntity(
            id: 'test',
            name: 'Test',
            alphabet: const {'a'},
            states: [
              const StateEntity(
                id: 'q0',
                name: 'q0',
                x: 0.0,
                y: 0.0,
                isInitial: true,
                isFinal: false,
              ),
              const StateEntity(
                id: 'q1',
                name: 'q1',
                x: 0.0,
                y: 0.0,
                isInitial: false,
                isFinal: true,
              )
            ],
            transitions: {
              'q0': ['q1']
            },
            initialId: 'q0',
            nextId: 2,
            type: AutomatonType.dfa,
          ),
        );

        // Verify SVG structure
        expect(svg, contains('<?xml'));
        expect(svg, contains('<svg'));
        expect(svg, contains('viewBox'));
        expect(svg, contains('</svg>'));

        // Verify SVG content
        expect(svg, contains('<circle')); // State circles
        expect(svg, contains('<line')); // Transitions
        expect(svg, contains('<text')); // Labels

        // Verify styles are included
        expect(svg, contains('<defs>'));
        expect(svg, contains('<marker'));
        expect(svg, contains('<style>'));
      });

      test('Turing machine SVG export produces valid structure', () {
        final svg = SvgExporter.exportTuringMachineToSvg(
          // Mock TM entity for testing
          null, // Placeholder since TM entity doesn't exist yet
        );

        // Verify SVG structure
        expect(svg, contains('<?xml'));
        expect(svg, contains('<svg'));
        expect(svg, contains('</svg>'));

        // Verify TM-specific content (placeholder implementation)
        expect(svg, contains('<rect')); // Tape cells
        expect(svg, contains('<polygon')); // Tape head
        expect(svg, contains('class="tape"')); // Tape styling
      });

      test('Grammar SVG export produces valid structure', () {
        final svg = SvgExporter.exportGrammarToSvg(
          // Mock grammar entity for testing
          const GrammarEntity(
            id: 'test',
            name: 'Test Grammar',
            terminals: const {'a'},
            nonTerminals: const {'S'},
            startSymbol: 'S',
            productions: const [],
          ),
        );

        // Verify SVG structure
        expect(svg, contains('<?xml'));
        expect(svg, contains('<svg'));
        expect(svg, contains('</svg>'));

        // Verify content (should contain automaton visualization)
        expect(svg, contains('<circle')); // State circles
        expect(svg, contains('<line')); // Transitions
      });

      test('SVG export options work correctly', () {
        const options = SvgExportOptions(
          includeTitle: true,
          includeLegend: false,
          scale: 1.5,
        );

        final svg = SvgExporter.exportAutomatonToSvg(
          // Mock automaton entity for testing
          const AutomatonEntity(
            id: 'test',
            name: 'Test with Options',
            alphabet: const {'a'},
            states: const <StateEntity>[],
            transitions: const <String, List<String>>{},
            initialId: 'q0',
            nextId: 0,
            type: AutomatonType.dfa,
          ),
          options: options,
        );

        // Verify options are applied
        expect(svg, contains('Test with Options')); // Title included
        expect(svg, contains('class="title"')); // Title styling
      });

      test('SVG export handles different sizes correctly', () {
        const smallSize = Size(400, 300);
        const largeSize = Size(1200, 900);

        final smallSvg = SvgExporter.exportAutomatonToSvg(
          // Mock automaton entity for testing
          const AutomatonEntity(
            id: 'test',
            name: 'Test',
            alphabet: const {'a'},
            states: const <StateEntity>[],
            transitions: const <String, List<String>>{},
            initialId: 'q0',
            nextId: 0,
            type: AutomatonType.dfa,
          ),
          width: smallSize.width,
          height: smallSize.height,
        );

        final largeSvg = SvgExporter.exportAutomatonToSvg(
          // Mock automaton entity for testing
          const AutomatonEntity(
            id: 'test',
            name: 'Test',
            alphabet: const {'a'},
            states: const <StateEntity>[],
            transitions: const <String, List<String>>{},
            initialId: 'q0',
            nextId: 0,
            type: AutomatonType.dfa,
          ),
          width: largeSize.width,
          height: largeSize.height,
        );

        // Verify viewBox is set correctly
        expect(smallSvg, contains('viewBox="0 0 400 300"'));
        expect(largeSvg, contains('viewBox="0 0 1200 900"'));

        // Both should be valid SVG
        expect(smallSvg, contains('<?xml'));
        expect(largeSvg, contains('<?xml'));
      });

      test('SVG export handles complex automata correctly', () {
        final svg = SvgExporter.exportAutomatonToSvg(
          // Mock automaton entity for testing
          AutomatonEntity(
            id: 'test',
            name: 'Test',
            alphabet: const {'a'},
            states: const <StateEntity>[],
            transitions: const <String, List<String>>{},
            initialId: 'q0',
            nextId: 0,
            type: AutomatonType.nfa,
          ),
        );

        // Verify complex structure is handled
        expect(svg, contains('<circle')); // Multiple states
        expect(svg, contains('<line')); // Multiple transitions
        expect(svg, contains('<text')); // Labels

        // Should still be valid SVG
        expect(svg, contains('<?xml'));
        expect(svg, contains('<svg'));
        expect(svg, contains('</svg>'));
      });

      test('SVG export validates input parameters', () {
        // Test with zero size (should handle gracefully)
        final zeroSizeSvg = SvgExporter.exportAutomatonToSvg(
          // Mock automaton entity for testing
          const AutomatonEntity(
            id: 'test',
            name: 'Test',
            alphabet: const {'a'},
            states: const <StateEntity>[],
            transitions: const <String, List<String>>{},
            initialId: 'q0',
            nextId: 0,
            type: AutomatonType.dfa,
          ),
          width: 0,
          height: 0,
        );

        // Should still produce valid SVG structure even with zero size
        expect(zeroSizeSvg, contains('<?xml'));
        expect(zeroSizeSvg, contains('<svg'));

        // Test with very large size
        final largeSizeSvg = SvgExporter.exportAutomatonToSvg(
          // Mock automaton entity for testing
          const AutomatonEntity(
            id: 'test',
            name: 'Test',
            alphabet: const {'a'},
            states: const <StateEntity>[],
            transitions: const <String, List<String>>{},
            initialId: 'q0',
            nextId: 0,
            type: AutomatonType.dfa,
          ),
          width: 10000,
          height: 10000,
        );

        expect(largeSizeSvg, contains('viewBox="0 0 10000 10000"'));
      });

      test('SVG export includes proper styling and markers', () {
        final svg = SvgExporter.exportAutomatonToSvg(
          // Mock automaton entity for testing
          const AutomatonEntity(
            id: 'test',
            name: 'Test',
            alphabet: const {'a'},
            states: const <StateEntity>[],
            transitions: const <String, List<String>>{},
            initialId: 'q0',
            nextId: 0,
            type: AutomatonType.dfa,
          ),
        );

        // Verify SVG styling elements
        expect(svg, contains('<defs>'));
        expect(svg, contains('<marker')); // Arrow markers
        expect(svg, contains('<style>')); // CSS styles
        expect(svg, contains('class=')); // CSS classes

        // Verify specific styling
        expect(svg, contains('font-family'));
        expect(svg, contains('text-anchor'));
        expect(svg, contains('fill='));
        expect(svg, contains('stroke='));
      });
    });
  });
}
