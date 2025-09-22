import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/lib/core/entities/automaton_entity.dart';
import 'package:jflutter/lib/core/repositories/automaton_repository.dart';
import 'package:jflutter/lib/core/result.dart';
import 'package:jflutter/lib/core/use_cases/automaton_use_cases.dart';

class _RecordingAutomatonRepository implements AutomatonRepository {
  AutomatonEntity? lastSaved;

  @override
  Future<AutomatonResult> saveAutomaton(AutomatonEntity automaton) async {
    lastSaved = automaton;
    return Success(automaton);
  }

  @override
  Future<BoolResult> deleteAutomaton(String id) {
    throw UnimplementedError();
  }

  @override
  Future<StringResult> exportAutomaton(AutomatonEntity automaton) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> importAutomaton(String jsonString) {
    throw UnimplementedError();
  }

  @override
  Future<ListResult<AutomatonEntity>> loadAllAutomatons() {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> loadAutomaton(String id) {
    throw UnimplementedError();
  }

  @override
  Future<BoolResult> validateAutomaton(AutomatonEntity automaton) {
    throw UnimplementedError();
  }
}

void main() {
  group('AddStateUseCase', () {
    test('updates previous states to non-initial when new initial state is added', () async {
      final repository = _RecordingAutomatonRepository();
      final useCase = AddStateUseCase(repository);
      final automaton = AutomatonEntity(
        id: 'auto-1',
        name: 'Test',
        alphabet: const {},
        states: const [
          StateEntity(
            id: 'q0',
            name: 'q0',
            x: 0,
            y: 0,
            isInitial: true,
            isFinal: false,
          ),
          StateEntity(
            id: 'q1',
            name: 'q1',
            x: 100,
            y: 0,
            isInitial: false,
            isFinal: true,
          ),
        ],
        transitions: const {},
        initialId: 'q0',
        nextId: 2,
        type: AutomatonType.dfa,
      );

      final result = await useCase.execute(
        automaton: automaton,
        name: 'q2',
        x: 200,
        y: 0,
        isInitial: true,
        isFinal: false,
      );

      expect(result, isA<Success<AutomatonEntity>>());
      final savedAutomaton = repository.lastSaved;
      expect(savedAutomaton, isNotNull);
      expect(savedAutomaton!.initialId, equals('q2'));

      final initialStates = savedAutomaton.states.where((state) => state.isInitial).toList();
      expect(initialStates.length, 1);
      expect(initialStates.single.id, equals('q2'));

      final previousInitial =
          savedAutomaton.states.firstWhere((state) => state.id == 'q0');
      expect(previousInitial.isInitial, isFalse);
    });
  });
}
