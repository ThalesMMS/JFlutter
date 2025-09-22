import '../../../core/entities/automaton_entity.dart';
import '../../../core/models/fsa.dart';
import '../../../core/use_cases/automaton_use_cases.dart';
import '../../../core/utils/automaton_entity_mapper.dart';

import 'automaton_state.dart';

class AutomatonCreationController {
  final CreateAutomatonUseCase _createAutomatonUseCase;
  final AddStateUseCase _addStateUseCase;

  AutomatonCreationController({
    required CreateAutomatonUseCase createAutomatonUseCase,
    required AddStateUseCase addStateUseCase,
  })  : _createAutomatonUseCase = createAutomatonUseCase,
        _addStateUseCase = addStateUseCase;

  Future<AutomatonState> createAutomaton(
    AutomatonState state, {
    required String name,
    required List<String> alphabet,
  }) async {
    try {
      final createResult = await _createAutomatonUseCase.execute(
        name: name,
        type: AutomatonType.dfa,
        alphabet: alphabet.toSet(),
      );

      if (createResult.isFailure) {
        return state.copyWith(
          isLoading: false,
          error: createResult.error,
        );
      }

      var automatonEntity = createResult.data!;
      final addInitialStateResult = await _addStateUseCase.execute(
        automaton: automatonEntity,
        name: 'q0',
        x: 100,
        y: 100,
        isInitial: true,
        isFinal: false,
      );

      if (addInitialStateResult.isFailure) {
        return state.copyWith(
          isLoading: false,
          error: addInitialStateResult.error,
        );
      }

      automatonEntity = addInitialStateResult.data!;

      return state.copyWith(
        currentAutomaton: automatonEntityToFsa(automatonEntity),
        simulationResult: null,
        regexResult: null,
        grammarResult: null,
        equivalenceResult: null,
        equivalenceDetails: null,
        isLoading: false,
      );
    } catch (e) {
      return state.copyWith(
        isLoading: false,
        error: 'Error creating automaton: $e',
      );
    }
  }

  AutomatonState updateAutomaton(AutomatonState state, FSA automaton) {
    return state.copyWith(
      currentAutomaton: automaton,
      equivalenceResult: null,
      equivalenceDetails: null,
    );
  }

  AutomatonState clearAutomaton(AutomatonState state) {
    return state.copyWith(
      currentAutomaton: null,
      simulationResult: null,
      regexResult: null,
      grammarResult: null,
      equivalenceResult: null,
      equivalenceDetails: null,
      error: null,
    );
  }

  AutomatonState clearError(AutomatonState state) {
    return state.copyWith(error: null);
  }
}
