import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/data/data_sources/examples_data_source.dart';
import 'package:jflutter/core/result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExamplesDataSource dataSource;

  setUp(() {
    dataSource = ExamplesDataSource();
  });

  test('loadExample returns a successful result for known examples', () async {
    final result = await dataSource.loadExample('AFD - Termina com A');

    expect(result.isSuccess, isTrue);
    final example = (result as Success).data;

    expect(example.name, 'AFD - Termina com A');
    expect(example.description, contains('terminam'));
    expect(example.automaton.states.length, 2);
    expect(example.automaton.alphabet, containsAll(<String>{'a', 'b'}));
    expect(example.automaton.finalStates.length, 1);
  });

  test('loadExamples loads all available examples', () async {
    final result = await dataSource.loadExamples();

    expect(result.isSuccess, isTrue);
    final examples = (result as Success).data;

    expect(examples.length, 4);
    expect(
      examples.map((example) => example.name),
      containsAll(<String>{
        'AFD - Termina com A',
        'AFD - Binário divisível por 3',
        'AFD - Paridade AB',
        'AFNλ - A ou AB',
      }),
    );
  });

  test('loadExample returns failure for unknown example name', () async {
    final result = await dataSource.loadExample('Unknown Example');

    expect(result.isFailure, isTrue);
    expect(result.error, 'Example not found: Unknown Example');
  });
}
