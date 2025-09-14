import '../../core/entities/automaton_entity.dart';
import '../../core/result.dart';
import '../../core/repositories/automaton_repository.dart';
import '../data_sources/local_storage_data_source.dart';
import '../models/automaton_model.dart';

/// Implementation of AutomatonRepository using local storage
class AutomatonRepositoryImpl implements AutomatonRepository {
  final LocalStorageDataSource _dataSource;

  AutomatonRepositoryImpl(this._dataSource);

  @override
  Future<AutomatonResult> saveAutomaton(AutomatonEntity automaton) async {
    try {
      final model = AutomatonModel.fromEntity(automaton);
      final result = await _dataSource.saveAutomaton(model);
      
      return result.map((_) => automaton);
    } catch (e) {
      return Failure('Failed to save automaton: $e');
    }
  }

  @override
  Future<AutomatonResult> loadAutomaton(String id) async {
    try {
      final result = await _dataSource.loadAutomaton(id);
      return result.map((model) => model.toEntity());
    } catch (e) {
      return Failure('Failed to load automaton: $e');
    }
  }

  @override
  Future<ListResult<AutomatonEntity>> loadAllAutomatons() async {
    try {
      final result = await _dataSource.loadAllAutomatons();
      return result.map((models) => models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Failure('Failed to load automatons: $e');
    }
  }

  @override
  Future<BoolResult> deleteAutomaton(String id) async {
    try {
      return await _dataSource.deleteAutomaton(id);
    } catch (e) {
      return Failure('Failed to delete automaton: $e');
    }
  }

  @override
  Future<StringResult> exportAutomaton(AutomatonEntity automaton) async {
    try {
      final model = AutomatonModel.fromEntity(automaton);
      return await _dataSource.exportAutomaton(model);
    } catch (e) {
      return Failure('Failed to export automaton: $e');
    }
  }

  @override
  Future<AutomatonResult> importAutomaton(String jsonString) async {
    try {
      final result = await _dataSource.importAutomaton(jsonString);
      return result.map((model) => model.toEntity());
    } catch (e) {
      return Failure('Failed to import automaton: $e');
    }
  }

  @override
  Future<BoolResult> validateAutomaton(AutomatonEntity automaton) async {
    try {
      final errors = <String>[];

      // Check for empty automaton
      if (automaton.states.isEmpty) {
        errors.add('Automaton não possui estados');
        return Success(errors.isEmpty);
      }

      // Check for initial state
      if (automaton.initialId == null) {
        errors.add('Automaton não possui estado inicial');
      } else if (automaton.getState(automaton.initialId!) == null) {
        errors.add('Estado inicial "${automaton.initialId}" não existe');
      }

      // Check for final states
      final finalStates = automaton.states.where((s) => s.isFinal).toList();
      if (finalStates.isEmpty) {
        errors.add('Automaton não possui estados finais');
      }

      // Check alphabet
      if (automaton.alphabet.isEmpty) {
        errors.add('Alfabeto está vazio');
      }

      // Check for unreachable states
      final reachableStates = _findReachableStates(automaton);
      final unreachableStates = automaton.states
          .where((s) => !reachableStates.contains(s.id))
          .toList();
      
      if (unreachableStates.isNotEmpty) {
        errors.add('Estados inalcançáveis: ${unreachableStates.map((s) => s.name).join(', ')}');
      }

      // Check for transitions with invalid states
      for (final entry in automaton.transitions.entries) {
        final parts = entry.key.split('|');
        if (parts.length != 2) {
          errors.add('Transição inválida: ${entry.key}');
          continue;
        }
        
        final fromState = parts[0];
        final symbol = parts[1];
        
        if (automaton.getState(fromState) == null) {
          errors.add('Transição de estado inexistente: $fromState');
        }
        
        if (!automaton.alphabet.contains(symbol) && symbol != 'λ') {
          errors.add('Transição com símbolo não pertencente ao alfabeto: $symbol');
        }
        
        for (final toState in entry.value) {
          if (automaton.getState(toState) == null) {
            errors.add('Transição para estado inexistente: $toState');
          }
        }
      }

      return Success(errors.isEmpty);
    } catch (e) {
      return Failure('Validation error: $e');
    }
  }

  /// Finds all reachable states from the initial state
  Set<String> _findReachableStates(AutomatonEntity automaton) {
    if (automaton.initialId == null) return {};
    
    final reachable = <String>{};
    final queue = <String>[automaton.initialId!];
    
    while (queue.isNotEmpty) {
      final state = queue.removeAt(0);
      if (reachable.contains(state)) continue;
      
      reachable.add(state);
      
      // Find all transitions from this state
      for (final entry in automaton.transitions.entries) {
        final parts = entry.key.split('|');
        if (parts.length == 2 && parts[0] == state) {
          for (final dest in entry.value) {
            if (!reachable.contains(dest)) {
              queue.add(dest);
            }
          }
        }
      }
    }
    
    return reachable;
  }
}
