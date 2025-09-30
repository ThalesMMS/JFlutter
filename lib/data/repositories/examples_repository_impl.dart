import '../../core/result.dart';
import '../../core/repositories/automaton_repository.dart';
import '../data_sources/examples_asset_data_source.dart';
import '../services/examples_service.dart';

/// Implementation of ExamplesRepository using enhanced assets data source and service
class ExamplesRepositoryImpl implements ExamplesRepository {
  final ExamplesAssetDataSource _dataSource;
  late final ExamplesService _service;

  ExamplesRepositoryImpl(this._dataSource) {
    _service = ExamplesService(_dataSource);
  }

  @override
  Future<ListResult<ExampleEntity>> loadExamples() async {
    return await _service.loadAllExamples();
  }

  @override
  Future<AutomatonResult> loadExample(String name) async {
    final result = await _service.loadExample(name);
    return result.map((example) => example.automaton!);
  }

  /// Loads examples by category (enhanced functionality)
  Future<ListResult<ExampleEntity>> loadExamplesByCategory(
    ExampleCategory category,
  ) async {
    return await _service.loadExamplesByCategory(category);
  }

  /// Search examples (enhanced functionality)
  Future<List<ExampleEntity>> searchExamples(String query) async {
    return await _service.searchExamples(query);
  }

  /// Get examples by difficulty (enhanced functionality)
  Future<ListResult<ExampleEntity>> getExamplesByDifficulty(
    DifficultyLevel difficulty,
  ) async {
    return await _service.getExamplesByDifficulty(difficulty);
  }

  /// Get library statistics (enhanced functionality)
  Future<ExamplesLibraryStats> getLibraryStats() async {
    return await _service.getLibraryStats();
  }

  /// Preload examples for better performance (enhanced functionality)
  Future<void> preloadExamples() async {
    await _service.preloadAllExamples();
  }

  /// Clear cache (enhanced functionality)
  void clearCache() {
    _service.clearCache();
  }
}
