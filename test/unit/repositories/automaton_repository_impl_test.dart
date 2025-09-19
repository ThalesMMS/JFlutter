import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/lib/core/entities/automaton_entity.dart';
import 'package:jflutter/lib/core/result.dart';
import 'package:jflutter/lib/data/repositories/automaton_repository_impl.dart';
import 'package:jflutter/lib/data/services/automaton_service.dart';

void main() {
  late AutomatonService service;
  late AutomatonRepositoryImpl repository;

  setUp(() {
    service = AutomatonService();
    repository = AutomatonRepositoryImpl(service);
  });

  AutomatonEntity buildAutomaton({String id = 'auto-1'}) {
    return AutomatonEntity(
      id: id,
      name: 'Test Automaton',
      alphabet: {'0', '1'},
      states: const [
        StateEntity(
          id: 'q0',
          name: 'q0',
          x: 100,
          y: 100,
          isInitial: true,
          isFinal: false,
        ),
        StateEntity(
          id: 'q1',
          name: 'q1',
          x: 300,
          y: 100,
          isInitial: false,
          isFinal: true,
        ),
      ],
      transitions: {
        'q0|0': ['q1'],
        'q1|1': ['q0'],
      },
      initialId: 'q0',
      nextId: 2,
      type: AutomatonType.dfa,
    );
  }

  group('save/load/delete', () {
    test('saves and loads automaton preserving data', () async {
      final automaton = buildAutomaton();

      final saveResult = await repository.saveAutomaton(automaton);
      expect(saveResult, isA<Success<AutomatonEntity>>());
      expect(saveResult.data!.id, equals(automaton.id));
      expect(saveResult.data!.states.length, equals(2));

      final loadResult = await repository.loadAutomaton(automaton.id);
      expect(loadResult, isA<Success<AutomatonEntity>>());
      expect(loadResult.data!.name, equals('Test Automaton'));
      expect(loadResult.data!.transitions['q0|0'], equals(['q1']));
    });

    test('returns failure when loading unknown automaton', () async {
      final loadResult = await repository.loadAutomaton('missing');
      expect(loadResult, isA<Failure<AutomatonEntity>>());
    });

    test('loadAll returns persisted automatons', () async {
      final automaton1 = buildAutomaton();
      final automaton2 = buildAutomaton(id: 'auto-2');

      await repository.saveAutomaton(automaton1);
      await repository.saveAutomaton(automaton2);

      final listResult = await repository.loadAllAutomatons();
      expect(listResult, isA<Success<List<AutomatonEntity>>>());
      expect(listResult.data, isNotNull);
      expect(listResult.data!.length, equals(2));
    });

    test('delete removes persisted automaton', () async {
      final automaton = buildAutomaton();
      await repository.saveAutomaton(automaton);

      final deleteResult = await repository.deleteAutomaton(automaton.id);
      expect(deleteResult, isA<Success<bool>>());

      final reload = await repository.loadAutomaton(automaton.id);
      expect(reload, isA<Failure<AutomatonEntity>>());
    });

    test('delete returns failure for unknown id', () async {
      final deleteResult = await repository.deleteAutomaton('missing');
      expect(deleteResult, isA<Failure<bool>>());
    });
  });

  group('export/import', () {
    test('exports automaton as JSON and re-imports', () async {
      final automaton = buildAutomaton();
      await repository.saveAutomaton(automaton);

      final exportResult = await repository.exportAutomaton(automaton);
      expect(exportResult, isA<Success<String>>());
      final json = exportResult.data!;
      expect(json, contains('Test Automaton'));

      service.clearAutomata();
      final importResult = await repository.importAutomaton(json);
      expect(importResult, isA<Success<AutomatonEntity>>());
      expect(importResult.data!.states.length, equals(2));
    });

    test('import returns failure for invalid json', () async {
      final result = await repository.importAutomaton('{invalid json');
      expect(result, isA<Failure<AutomatonEntity>>());
    });
  });

  group('validation', () {
    test('validate returns success for valid automaton', () async {
      final automaton = buildAutomaton();
      final result = await repository.validateAutomaton(automaton);
      expect(result, isA<Success<bool>>());
      expect(result.data, isTrue);
    });

    test('validate returns failure for invalid automaton', () async {
      final invalidAutomaton = AutomatonEntity(
        id: 'invalid',
        name: 'Invalid',
        alphabet: const {},
        states: const [],
        transitions: const {},
        initialId: null,
        nextId: 0,
        type: AutomatonType.dfa,
      );

      final result = await repository.validateAutomaton(invalidAutomaton);
      expect(result, isA<Failure<bool>>());
    });
  });

  test('save propagates service failure', () async {
    final invalidAutomaton = AutomatonEntity(
      id: 'invalid',
      name: '',
      alphabet: const {},
      states: const [],
      transitions: const {},
      initialId: null,
      nextId: 0,
      type: AutomatonType.dfa,
    );

    final result = await repository.saveAutomaton(invalidAutomaton);
    expect(result, isA<Failure<AutomatonEntity>>());
  });
}
