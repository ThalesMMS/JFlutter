import '../../core/result.dart';
import '../../core/repositories/automaton_repository.dart';
import '../data_sources/examples_data_source.dart';

/// Implementation of ExamplesRepository using assets data source
class ExamplesRepositoryImpl implements ExamplesRepository {
  final ExamplesDataSource _dataSource;

  ExamplesRepositoryImpl(this._dataSource);

  @override
  Future<ListResult<ExampleEntity>> loadExamples() async {
    return await _dataSource.loadExamples();
  }

  @override
  Future<AutomatonResult> loadExample(String name) async {
    final result = await _dataSource.loadExample(name);
    return result.map((example) => example.automaton);
  }
}
