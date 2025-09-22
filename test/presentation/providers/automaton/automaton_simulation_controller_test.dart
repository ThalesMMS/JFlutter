import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/core/use_cases/algorithm_use_cases.dart';
import 'package:jflutter/core/utils/automaton_entity_mapper.dart';
import 'package:jflutter/presentation/providers/automaton/automaton_simulation_controller.dart';
import 'package:jflutter/presentation/providers/automaton/automaton_state.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

class _StubSimulateWordUseCase extends SimulateWordUseCase {
  _StubSimulateWordUseCase(this._result)
      : super(FakeAlgorithmRepository());

  final Result<SimulationResult> Function(
    AutomatonEntity automaton,
    String word,
  ) _result;

  @override
  Future<Result<SimulationResult>> execute(
    AutomatonEntity automaton,
    String word,
  ) async {
    return _result(automaton, word);
  }
}

void main() {
  group('AutomatonSimulationController', () {
    test('simulate stores simulation result on success', () async {
      final automaton = automatonEntityToFsa(buildAutomatonEntity());
      final result = SimulationResult.success(
        inputString: '01',
        steps: const [SimulationStep(currentState: 'q0', remainingInput: '', stepNumber: 0)],
        executionTime: const Duration(milliseconds: 5),
      );

      final controller = AutomatonSimulationController(
        simulateWordUseCase: _StubSimulateWordUseCase(
          (automaton, word) => Success(result),
        ),
      );

      final updatedState = await controller.simulate(
        AutomatonState(currentAutomaton: automaton, isLoading: true),
        '01',
      );

      expect(updatedState.isLoading, isFalse);
      expect(updatedState.simulationResult, equals(result));
      expect(updatedState.error, isNull);
    });

    test('simulate stores error on failure', () async {
      final automaton = automatonEntityToFsa(buildAutomatonEntity());
      final controller = AutomatonSimulationController(
        simulateWordUseCase: _StubSimulateWordUseCase(
          (automaton, word) => Failure('simulation failed'),
        ),
      );

      final updatedState = await controller.simulate(
        AutomatonState(currentAutomaton: automaton, isLoading: true),
        '01',
      );

      expect(updatedState.isLoading, isFalse);
      expect(updatedState.simulationResult, isNull);
      expect(updatedState.error, 'simulation failed');
    });
  });
}
