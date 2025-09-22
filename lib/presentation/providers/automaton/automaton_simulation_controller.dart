import '../../../core/use_cases/algorithm_use_cases.dart';
import '../../../core/utils/automaton_entity_mapper.dart';

import 'automaton_state.dart';

class AutomatonSimulationController {
  final SimulateWordUseCase _simulateWordUseCase;

  AutomatonSimulationController({
    required SimulateWordUseCase simulateWordUseCase,
  }) : _simulateWordUseCase = simulateWordUseCase;

  Future<AutomatonState> simulate(
    AutomatonState state,
    String inputString,
  ) async {
    try {
      final automatonEntity =
          fsaToAutomatonEntity(state.currentAutomaton!); // assumes non-null
      final result = await _simulateWordUseCase.execute(
        automatonEntity,
        inputString,
      );

      if (result.isSuccess) {
        return state.copyWith(
          simulationResult: result.data,
          isLoading: false,
        );
      } else {
        return state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }
    } catch (e) {
      return state.copyWith(
        isLoading: false,
        error: 'Error simulating automaton: $e',
      );
    }
  }
}
