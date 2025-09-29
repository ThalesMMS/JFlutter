import '../../core/result.dart';
import '../../core/repositories/automaton_repository.dart';
import '../data_sources/examples_asset_data_source.dart';

/// Service for managing the Examples v1 library with advanced functionality
class ExamplesService {
  final ExamplesAssetDataSource _dataSource;

  ExamplesService(this._dataSource);

  /// Cache for loaded examples to improve performance
  final Map<String, ExampleEntity> _examplesCache = {};
  final Map<ExampleCategory, List<ExampleEntity>> _categoryCache = {};

  /// Loads all examples with caching
  Future<ListResult<ExampleEntity>> loadAllExamples() async {
    if (_examplesCache.isNotEmpty) {
      return Success(_examplesCache.values.toList());
    }

    final result = await _dataSource.loadAllExamples();
    if (result.isSuccess) {
      for (final example in result.data!) {
        _examplesCache[example.name] = example;
      }
    }

    return result;
  }

  /// Loads examples by category with caching
  Future<ListResult<ExampleEntity>> loadExamplesByCategory(
      ExampleCategory category) async {
    if (_categoryCache.containsKey(category)) {
      return Success(_categoryCache[category]!);
    }

    final result = await _dataSource.loadExamplesByCategory(category);
    if (result.isSuccess) {
      _categoryCache[category] = result.data!;
    }

    return result;
  }

  /// Loads a specific example by name
  Future<Result<ExampleEntity>> loadExample(String name) async {
    // Check cache first
    if (_examplesCache.containsKey(name)) {
      return Success(_examplesCache[name]!);
    }

    final result = await _dataSource.loadExample(name);
    if (result.isSuccess) {
      _examplesCache[name] = result.data!;
    }

    return result;
  }

  /// Gets all available categories
  List<ExampleCategory> getAvailableCategories() {
    return _dataSource.getAvailableCategories();
  }

  /// Gets examples count by category
  Map<ExampleCategory, int> getExamplesCountByCategory() {
    return _dataSource.getExamplesCountByCategory();
  }

  /// Search examples by query string
  Future<List<ExampleEntity>> searchExamples(String query) async {
    final matchingNames = _dataSource.searchExamples(query);

    final results = <ExampleEntity>[];
    for (final name in matchingNames) {
      final result = await loadExample(name);
      if (result.isSuccess) {
        results.add(result.data!);
      }
    }

    return results;
  }

  /// Gets examples filtered by difficulty level
  Future<ListResult<ExampleEntity>> getExamplesByDifficulty(
      DifficultyLevel difficulty) async {
    final allExamplesResult = await loadAllExamples();
    if (allExamplesResult.isFailure) {
      return Failure(allExamplesResult.error!);
    }

    final filteredExamples = allExamplesResult.data!
        .where((example) => example.difficultyLevel == difficulty)
        .toList();

    return Success(filteredExamples);
  }

  /// Gets examples filtered by complexity level
  Future<ListResult<ExampleEntity>> getExamplesByComplexity(
      ComplexityLevel complexity) async {
    final allExamplesResult = await loadAllExamples();
    if (allExamplesResult.isFailure) {
      return Failure(allExamplesResult.error!);
    }

    final filteredExamples = allExamplesResult.data!
        .where((example) => example.estimatedComplexity == complexity)
        .toList();

    return Success(filteredExamples);
  }

  /// Gets examples with specific tags
  Future<ListResult<ExampleEntity>> getExamplesByTags(List<String> tags) async {
    final allExamplesResult = await loadAllExamples();
    if (allExamplesResult.isFailure) {
      return Failure(allExamplesResult.error!);
    }

    final filteredExamples = allExamplesResult.data!
        .where((example) => tags.any((tag) => example.tags.contains(tag)))
        .toList();

    return Success(filteredExamples);
  }

  /// Gets recommended examples for beginners
  Future<ListResult<ExampleEntity>> getBeginnerExamples() async {
    final easyExamplesResult =
        await getExamplesByDifficulty(DifficultyLevel.easy);
    if (easyExamplesResult.isFailure) {
      return Failure(easyExamplesResult.error!);
    }

    // Return only the first few easy examples for beginners
    final beginnerExamples = easyExamplesResult.data!.take(3).toList();
    return Success(beginnerExamples);
  }

  /// Gets advanced examples for experienced users
  Future<ListResult<ExampleEntity>> getAdvancedExamples() async {
    final hardExamplesResult =
        await getExamplesByDifficulty(DifficultyLevel.hard);
    if (hardExamplesResult.isFailure) {
      return Failure(hardExamplesResult.error!);
    }

    return hardExamplesResult;
  }

  /// Gets examples organized by learning path
  Future<Map<String, List<ExampleEntity>>> getExamplesByLearningPath() async {
    final allExamplesResult = await loadAllExamples();
    if (allExamplesResult.isFailure) {
      return {};
    }

    final examples = allExamplesResult.data!;

    return {
      'Basics': examples
          .where((e) => e.difficultyLevel == DifficultyLevel.easy)
          .toList(),
      'Intermediate': examples
          .where((e) => e.difficultyLevel == DifficultyLevel.medium)
          .toList(),
      'Advanced': examples
          .where((e) => e.difficultyLevel == DifficultyLevel.hard)
          .toList(),
    };
  }

  /// Gets statistics about the examples library
  Future<ExamplesLibraryStats> getLibraryStats() async {
    final allExamplesResult = await loadAllExamples();
    if (allExamplesResult.isFailure) {
      return ExamplesLibraryStats.empty();
    }

    final examples = allExamplesResult.data!;

    final stats = ExamplesLibraryStats(
      totalExamples: examples.length,
      examplesByCategory: _dataSource.getExamplesCountByCategory(),
      examplesByDifficulty: _countByDifficulty(examples),
      examplesByComplexity: _countByComplexity(examples),
      mostCommonTags: _getMostCommonTags(examples),
    );

    return stats;
  }

  /// Clears the cache (useful for memory management or updates)
  void clearCache() {
    _examplesCache.clear();
    _categoryCache.clear();
  }

  /// Preloads all examples into cache for better performance
  Future<void> preloadAllExamples() async {
    await loadAllExamples();
  }

  // Private helper methods

  Map<DifficultyLevel, int> _countByDifficulty(List<ExampleEntity> examples) {
    final counts = <DifficultyLevel, int>{};
    for (final level in DifficultyLevel.values) {
      counts[level] = examples.where((e) => e.difficultyLevel == level).length;
    }
    return counts;
  }

  Map<ComplexityLevel, int> _countByComplexity(List<ExampleEntity> examples) {
    final counts = <ComplexityLevel, int>{};
    for (final level in ComplexityLevel.values) {
      counts[level] =
          examples.where((e) => e.estimatedComplexity == level).length;
    }
    return counts;
  }

  List<String> _getMostCommonTags(List<ExampleEntity> examples) {
    final tagCounts = <String, int>{};

    for (final example in examples) {
      for (final tag in example.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags.take(10).map((e) => e.key).toList();
  }
}

/// Statistics about the examples library
class ExamplesLibraryStats {
  final int totalExamples;
  final Map<ExampleCategory, int> examplesByCategory;
  final Map<DifficultyLevel, int> examplesByDifficulty;
  final Map<ComplexityLevel, int> examplesByComplexity;
  final List<String> mostCommonTags;

  const ExamplesLibraryStats({
    required this.totalExamples,
    required this.examplesByCategory,
    required this.examplesByDifficulty,
    required this.examplesByComplexity,
    required this.mostCommonTags,
  });

  factory ExamplesLibraryStats.empty() {
    return ExamplesLibraryStats(
      totalExamples: 0,
      examplesByCategory: <ExampleCategory, int>{},
      examplesByDifficulty: <DifficultyLevel, int>{},
      examplesByComplexity: <ComplexityLevel, int>{},
      mostCommonTags: [],
    );
  }

  @override
  String toString() {
    return 'ExamplesLibraryStats('
        'total: $totalExamples, '
        'categories: ${examplesByCategory.length}, '
        'difficulties: ${examplesByDifficulty.values.reduce((a, b) => a + b)}, '
        'complexities: ${examplesByComplexity.values.reduce((a, b) => a + b)}, '
        'topTags: ${mostCommonTags.take(3).join(", ")}'
        ')';
  }
}
