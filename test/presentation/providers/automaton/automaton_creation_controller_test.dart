import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/core/use_cases/automaton_use_cases.dart';
import 'package:jflutter/core/utils/automaton_entity_mapper.dart';
import 'package:jflutter/presentation/providers/automaton/automaton_creation_controller.dart';
import 'package:jflutter/presentation/providers/automaton/automaton_state.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

class _StubCreateAutomatonUseCase extends CreateAutomatonUseCase {
  _StubCreateAutomatonUseCase(this._result)
      : super(FakeAutomatonRepository());

  final AutomatonResult Function({
    required String name,
    required AutomatonType type,
    Set<String> alphabet,
  }) _result;

  @override
  Future<AutomatonResult> execute({
    required String name,
    required AutomatonType type,
    Set<String> alphabet = const {},
  }) async {
    return _result(name: name, type: type, alphabet: alphabet);
  }
}

class _StubAddStateUseCase extends AddStateUseCase {
  _StubAddStateUseCase(this._result) : super(FakeAutomatonRepository());

  factory _StubAddStateUseCase.unused() {
    return _StubAddStateUseCase(({
      required automaton,
      required String name,
      required double x,
      required double y,
      bool isInitial = false,
      bool isFinal = false,
    }) {
      throw UnimplementedError();
    });
  }

  final AutomatonResult Function({
    required AutomatonEntity automaton,
    required String name,
    required double x,
    required double y,
    bool isInitial,
    bool isFinal,
  }) _result;

  @override
  Future<AutomatonResult> execute({
    required AutomatonEntity automaton,
    required String name,
    required double x,
    required double y,
    bool isInitial = false,
    bool isFinal = false,
  }) async {
    return _result(
      automaton: automaton,
      name: name,
      x: x,
      y: y,
      isInitial: isInitial,
      isFinal: isFinal,
    );
  }
}

void main() {
  group('AutomatonCreationController', () {
    test('createAutomaton builds initial automaton on success', () async {
      final createdEntity = buildAutomatonEntity();
      final withInitialState = buildAutomatonEntity(id: 'withState');

      final controller = AutomatonCreationController(
        createAutomatonUseCase: _StubCreateAutomatonUseCase(
          ({required name, required type, Set<String> alphabet = const {}}) =>
              Success(createdEntity),
        ),
        addStateUseCase: _StubAddStateUseCase(
          ({
            required automaton,
            required name,
            required double x,
            required double y,
            bool isInitial = false,
            bool isFinal = false,
          }) =>
              Success(withInitialState),
        ),
      );

      final result = await controller.createAutomaton(
        const AutomatonState(isLoading: true),
        name: 'Test',
        alphabet: const ['0', '1'],
      );

      expect(result.isLoading, isFalse);
      expect(result.error, isNull);
      expect(result.currentAutomaton, isNotNull);
      expect(result.currentAutomaton!.states.length, equals(2));
      expect(result.simulationResult, isNull);
      expect(result.equivalenceResult, isNull);
    });

    test('createAutomaton propagates creation failure', () async {
      final controller = AutomatonCreationController(
        createAutomatonUseCase: _StubCreateAutomatonUseCase(
          ({required name, required type, Set<String> alphabet = const {}}) =>
              Failure('unable to create'),
        ),
        addStateUseCase: _StubAddStateUseCase.unused(),
      );

      final result = await controller.createAutomaton(
        const AutomatonState(isLoading: true),
        name: 'Test',
        alphabet: const ['0'],
      );

      expect(result.isLoading, isFalse);
      expect(result.error, 'unable to create');
      expect(result.currentAutomaton, isNull);
    });

    test('createAutomaton propagates add state failure', () async {
      final controller = AutomatonCreationController(
        createAutomatonUseCase: _StubCreateAutomatonUseCase(
          ({required name, required type, Set<String> alphabet = const {}}) =>
              Success(buildAutomatonEntity()),
        ),
        addStateUseCase: _StubAddStateUseCase(({
          required automaton,
          required String name,
          required double x,
          required double y,
          bool isInitial = false,
          bool isFinal = false,
        }) =>
            Failure('add state failed')),
      );

      final result = await controller.createAutomaton(
        const AutomatonState(isLoading: true),
        name: 'Test',
        alphabet: const [],
      );

      expect(result.isLoading, isFalse);
      expect(result.error, 'add state failed');
      expect(result.currentAutomaton, isNull);
    });

    test('updateAutomaton replaces automaton and clears equivalence', () {
      final controller = AutomatonCreationController(
        createAutomatonUseCase: _StubCreateAutomatonUseCase(({}) =>
            throw UnimplementedError()),
        addStateUseCase: _StubAddStateUseCase.unused(),
      );

      final automaton = controller.updateAutomaton(
        const AutomatonState(),
        automatonEntityToFsa(buildAutomatonEntity()),
      );

      expect(automaton.currentAutomaton, isNotNull);
      expect(automaton.equivalenceDetails, isNull);
      expect(automaton.equivalenceResult, isNull);
    });

    test('clear helpers reset fields', () {
      final controller = AutomatonCreationController(
        createAutomatonUseCase: _StubCreateAutomatonUseCase(({}) =>
            throw UnimplementedError()),
        addStateUseCase: _StubAddStateUseCase.unused(),
      );

      final cleared = controller.clearAutomaton(
        const AutomatonState(
          currentAutomaton: null,
          simulationResult: null,
          regexResult: 'regex',
          grammarResult: null,
          equivalenceResult: true,
          equivalenceDetails: 'details',
          error: 'err',
        ),
      );

      expect(cleared.currentAutomaton, isNull);
      expect(cleared.regexResult, isNull);
      expect(cleared.equivalenceResult, isNull);
      expect(cleared.error, isNull);

      final errorCleared = controller.clearError(
        const AutomatonState(error: 'err'),
      );

      expect(errorCleared.error, isNull);
    });
  });
}
