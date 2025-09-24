import '../../../core/use_cases/automaton_use_cases.dart';
import '../../../core/utils/automaton_entity_mapper.dart';

import 'automaton_state.dart';

class AutomatonLayoutController {
  final ApplyAutoLayoutUseCase _applyAutoLayoutUseCase;

  AutomatonLayoutController({
    required ApplyAutoLayoutUseCase applyAutoLayoutUseCase,
  }) : _applyAutoLayoutUseCase = applyAutoLayoutUseCase;

  Future<AutomatonState> applyAutoLayout(AutomatonState state) async {
    try {
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _applyAutoLayoutUseCase.execute(automatonEntity);

      if (result.isSuccess) {
        return state.copyWith(
          currentAutomaton: automatonEntityToFsa(result.data!),
          simulationResult: null,
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
        error: 'Error applying auto layout: $e',
      );
    }
  }
}
