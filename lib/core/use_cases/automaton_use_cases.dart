//
//  automaton_use_cases.dart
//  JFlutter
//
//  Conjunto de casos de uso que encapsula operações de ciclo de vida e edição
//  de autômatos, delegando persistência ao AutomatonRepository. Define fluxos
//  para criar, carregar, salvar, excluir, importar e exportar estruturas.
//  Também organiza comandos para gerenciar estados e transições garantindo
//  consistência dos dados.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../entities/automaton_entity.dart';
import '../result.dart';
import '../repositories/automaton_repository.dart';

/// Use case for creating a new automaton
class CreateAutomatonUseCase {
  final AutomatonRepository _repository;

  CreateAutomatonUseCase(this._repository);

  Future<AutomatonResult> execute({
    required String name,
    required AutomatonType type,
    Set<String> alphabet = const {},
  }) async {
    try {
      final automaton = AutomatonEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        alphabet: alphabet,
        states: [],
        transitions: {},
        nextId: 0,
        type: type,
      );

      return await _repository.saveAutomaton(automaton);
    } catch (e) {
      return Failure('Failed to create automaton: $e');
    }
  }
}

/// Use case for loading an automaton
class LoadAutomatonUseCase {
  final AutomatonRepository _repository;

  LoadAutomatonUseCase(this._repository);

  Future<AutomatonResult> execute(String id) async {
    return await _repository.loadAutomaton(id);
  }
}

/// Use case for saving an automaton
class SaveAutomatonUseCase {
  final AutomatonRepository _repository;

  SaveAutomatonUseCase(this._repository);

  Future<AutomatonResult> execute(AutomatonEntity automaton) async {
    return await _repository.saveAutomaton(automaton);
  }
}

/// Use case for deleting an automaton
class DeleteAutomatonUseCase {
  final AutomatonRepository _repository;

  DeleteAutomatonUseCase(this._repository);

  Future<BoolResult> execute(String id) async {
    return await _repository.deleteAutomaton(id);
  }
}

/// Use case for exporting an automaton
class ExportAutomatonUseCase {
  final AutomatonRepository _repository;

  ExportAutomatonUseCase(this._repository);

  Future<StringResult> execute(AutomatonEntity automaton) async {
    return await _repository.exportAutomaton(automaton);
  }
}

/// Use case for importing an automaton
class ImportAutomatonUseCase {
  final AutomatonRepository _repository;

  ImportAutomatonUseCase(this._repository);

  Future<AutomatonResult> execute(String jsonString) async {
    return await _repository.importAutomaton(jsonString);
  }
}

/// Use case for validating an automaton
class ValidateAutomatonUseCase {
  final AutomatonRepository _repository;

  ValidateAutomatonUseCase(this._repository);

  Future<BoolResult> execute(AutomatonEntity automaton) async {
    return await _repository.validateAutomaton(automaton);
  }
}

/// Use case for adding a state to an automaton
class AddStateUseCase {
  final AutomatonRepository _repository;

  AddStateUseCase(this._repository);

  Future<AutomatonResult> execute({
    required AutomatonEntity automaton,
    required String name,
    required double x,
    required double y,
    bool isInitial = false,
    bool isFinal = false,
  }) async {
    try {
      final newState = StateEntity(
        id: 'q${automaton.nextId}',
        name: name,
        x: x,
        y: y,
        isInitial: isInitial,
        isFinal: isFinal,
      );

      final updatedStates = [...automaton.states, newState];

      // If this is the initial state, update initialId
      String? newInitialId = automaton.initialId;
      if (isInitial) {
        newInitialId = newState.id;
        // Remove initial flag from other states
        for (var state in updatedStates) {
          if (state.id != newState.id && state.isInitial) {
            state = state.copyWith(isInitial: false);
          }
        }
      }

      final updatedAutomaton = automaton.copyWith(
        states: updatedStates,
        initialId: newInitialId,
        nextId: automaton.nextId + 1,
      );

      return await _repository.saveAutomaton(updatedAutomaton);
    } catch (e) {
      return Failure('Failed to add state: $e');
    }
  }
}

/// Use case for removing a state from an automaton
class RemoveStateUseCase {
  final AutomatonRepository _repository;

  RemoveStateUseCase(this._repository);

  Future<AutomatonResult> execute({
    required AutomatonEntity automaton,
    required String stateId,
  }) async {
    try {
      final updatedStates = automaton.states
          .where((state) => state.id != stateId)
          .toList();

      // Remove transitions involving this state
      final updatedTransitions = <String, List<String>>{};
      for (final entry in automaton.transitions.entries) {
        final parts = entry.key.split('|');
        if (parts.length == 2 && parts[0] != stateId) {
          final filteredDestinations = entry.value
              .where((dest) => dest != stateId)
              .toList();
          if (filteredDestinations.isNotEmpty) {
            updatedTransitions[entry.key] = filteredDestinations;
          }
        }
      }

      // Update initialId if the removed state was initial
      String? newInitialId = automaton.initialId;
      if (automaton.initialId == stateId) {
        newInitialId = updatedStates.isNotEmpty ? updatedStates.first.id : null;
      }

      final updatedAutomaton = automaton.copyWith(
        states: updatedStates,
        transitions: updatedTransitions,
        initialId: newInitialId,
      );

      return await _repository.saveAutomaton(updatedAutomaton);
    } catch (e) {
      return Failure('Failed to remove state: $e');
    }
  }
}

/// Use case for adding a transition to an automaton
class AddTransitionUseCase {
  final AutomatonRepository _repository;

  AddTransitionUseCase(this._repository);

  Future<AutomatonResult> execute({
    required AutomatonEntity automaton,
    required String fromStateId,
    required String symbol,
    required String toStateId,
  }) async {
    try {
      final transitionKey = '$fromStateId|$symbol';
      final updatedTransitions = Map<String, List<String>>.from(
        automaton.transitions,
      );

      if (updatedTransitions.containsKey(transitionKey)) {
        if (!updatedTransitions[transitionKey]!.contains(toStateId)) {
          updatedTransitions[transitionKey]!.add(toStateId);
        }
      } else {
        updatedTransitions[transitionKey] = [toStateId];
      }

      // Add symbol to alphabet if not present
      final updatedAlphabet = Set<String>.from(automaton.alphabet);
      updatedAlphabet.add(symbol);

      final updatedAutomaton = automaton.copyWith(
        transitions: updatedTransitions,
        alphabet: updatedAlphabet,
      );

      return await _repository.saveAutomaton(updatedAutomaton);
    } catch (e) {
      return Failure('Failed to add transition: $e');
    }
  }
}

/// Use case for removing a transition from an automaton
class RemoveTransitionUseCase {
  final AutomatonRepository _repository;

  RemoveTransitionUseCase(this._repository);

  Future<AutomatonResult> execute({
    required AutomatonEntity automaton,
    required String fromStateId,
    required String symbol,
    String? toStateId,
  }) async {
    try {
      final transitionKey = '$fromStateId|$symbol';
      final updatedTransitions = Map<String, List<String>>.from(
        automaton.transitions,
      );

      if (updatedTransitions.containsKey(transitionKey)) {
        if (toStateId != null) {
          updatedTransitions[transitionKey]!.remove(toStateId);
          if (updatedTransitions[transitionKey]!.isEmpty) {
            updatedTransitions.remove(transitionKey);
          }
        } else {
          updatedTransitions.remove(transitionKey);
        }
      }

      final updatedAutomaton = automaton.copyWith(
        transitions: updatedTransitions,
      );

      return await _repository.saveAutomaton(updatedAutomaton);
    } catch (e) {
      return Failure('Failed to remove transition: $e');
    }
  }
}
