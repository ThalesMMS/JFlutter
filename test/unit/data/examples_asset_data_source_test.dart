import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/repositories/automaton_repository.dart';
import 'package:jflutter/data/data_sources/examples_asset_data_source.dart';

void main() {
  group('ExamplesAssetDataSource JSON validation', () {
    late ExamplesAssetDataSource dataSource;

    setUp(() {
      dataSource = ExamplesAssetDataSource();
    });

    ExampleMetadata metadataFor({
      required ExampleCategory category,
      required String fileName,
    }) {
      return ExampleMetadata(
        fileName: fileName,
        category: category,
        subcategory: 'Test',
        difficulty: DifficultyLevel.medium,
        description: 'Test metadata',
        tags: const ['test'],
        estimatedComplexity: ComplexityLevel.medium,
      );
    }

    Map<String, dynamic> loadExample(String fileName) {
      final file = File('jflutter_js/examples/$fileName');
      final jsonString = file.readAsStringSync();
      final decoded = jsonDecode(jsonString);
      expect(
        decoded,
        isA<Map<String, dynamic>>(),
        reason: 'Fixture $fileName must decode to a JSON object',
      );
      return decoded as Map<String, dynamic>;
    }

    test('Returns failure when DFA example is missing states', () {
      final json = loadExample('afd_ends_with_a.json');
      final metadata = metadataFor(
        category: ExampleCategory.dfa,
        fileName: 'afd_ends_with_a.json',
      );

      json.remove('states');

      final result = dataSource.convertJsonForTesting(
        json,
        metadata,
        'AFD - Termina com A',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('states'));
    });

    test('Validates CFG example without producing an automaton model', () {
      final json = loadExample('glc_balanced_parentheses.json');
      final metadata = metadataFor(
        category: ExampleCategory.cfg,
        fileName: 'glc_balanced_parentheses.json',
      );

      final result = dataSource.convertJsonForTesting(
        json,
        metadata,
        'GLC - Parênteses balanceados',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('Validates PDA example structure', () {
      final json = loadExample('apda_palindrome.json');
      final metadata = metadataFor(
        category: ExampleCategory.pda,
        fileName: 'apda_palindrome.json',
      );

      final result = dataSource.convertJsonForTesting(
        json,
        metadata,
        'APD - Palíndromo',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('Validates TM example structure', () {
      final json = loadExample('tm_binary_to_unary.json');
      final metadata = metadataFor(
        category: ExampleCategory.tm,
        fileName: 'tm_binary_to_unary.json',
      );

      final result = dataSource.convertJsonForTesting(
        json,
        metadata,
        'MT - Binário para unário',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });
  });
}
