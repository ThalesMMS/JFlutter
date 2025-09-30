import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/data/data_sources/examples_asset_data_source.dart';
import 'package:jflutter/data/services/examples_service.dart';
import 'package:jflutter/core/repositories/automaton_repository.dart';

void main() {
  group('ExamplesLibraryStats toString', () {
    test('handles empty stats without errors', () {
      final stats = ExamplesLibraryStats.empty();

      expect(
        stats.toString(),
        'ExamplesLibraryStats(total: 0, categories: 0, difficulties: 0, complexities: 0, topTags: )',
      );
    });

    test('computes sums safely for partially empty maps', () {
      final stats = ExamplesLibraryStats(
        totalExamples: 5,
        examplesByCategory: {ExampleCategory.dfa: 5},
        examplesByDifficulty: const {},
        examplesByComplexity: const {ComplexityLevel.low: 3},
        mostCommonTags: const ['dfa', 'automaton'],
      );

      final description = stats.toString();

      expect(description, contains('total: 5'));
      expect(description, contains('categories: 1'));
      expect(description, contains('difficulties: 0'));
      expect(description, contains('complexities: 3'));
      expect(description, contains('topTags: dfa, automaton'));
    });
  });
}
