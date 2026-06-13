//
//  automaton_repository_impl.dart
//  JFlutter
//
//  Implementa o repositório de autômatos traduzindo entidades para o serviço interno, cobrindo persistência, operações de exportação e validações com conversões de modelo.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;

import '../../core/entities/automaton_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/result.dart';
import '../../core/utils/epsilon_utils.dart';
import '../../core/repositories/automaton_repository.dart';
import '../mappers/automaton_entity_mapper.dart';
import '../services/automaton_service.dart';

/// Concrete implementation of AutomatonRepository
class AutomatonRepositoryImpl implements AutomatonRepository {
  final AutomatonService _automatonService;

  AutomatonRepositoryImpl(this._automatonService);

  @override
  Future<AutomatonResult> saveAutomaton(AutomatonEntity automaton) async {
    try {
      final request = _convertEntityToRequest(automaton);
      final result = _automatonService.saveAutomaton(automaton.id, request);

      if (result.isFailure) {
        return Failure(result.error!);
      }

      return Success(_convertFsaToEntity(result.data!));
    } catch (e) {
      return Failure('Failed to save automaton: $e');
    }
  }

  @override
  Future<AutomatonResult> loadAutomaton(String id) async {
    try {
      final result = _automatonService.getAutomaton(id);
      if (result.isFailure) {
        return Failure(result.error!);
      }

      return Success(_convertFsaToEntity(result.data!));
    } catch (e) {
      return Failure('Failed to load automaton: $e');
    }
  }

  @override
  Future<ListResult<AutomatonEntity>> loadAllAutomatons() async {
    try {
      final result = _automatonService.listAutomata();
      if (result.isFailure) {
        return Failure(result.error!);
      }

      final automatons = result.data!.map(_convertFsaToEntity).toList();

      return Success(automatons);
    } catch (e) {
      return Failure('Failed to load automatons: $e');
    }
  }

  @override
  Future<BoolResult> deleteAutomaton(String id) async {
    try {
      final result = _automatonService.deleteAutomaton(id);
      if (result.isFailure) {
        return Failure(result.error!);
      }

      return const Success(true);
    } catch (e) {
      return Failure('Failed to delete automaton: $e');
    }
  }

  @override
  Future<StringResult> exportAutomaton(AutomatonEntity automaton) async {
    try {
      final fsa = _convertEntityToFsa(automaton);
      final result = _automatonService.exportAutomaton(fsa);
      if (result.isFailure) {
        return Failure(result.error!);
      }

      return Success(result.data!);
    } catch (e) {
      return Failure('Failed to export automaton: $e');
    }
  }

  @override
  Future<AutomatonResult> importAutomaton(String jsonString) async {
    try {
      final result = _automatonService.importAutomaton(jsonString);
      if (result.isFailure) {
        return Failure(result.error!);
      }

      return Success(_convertFsaToEntity(result.data!));
    } catch (e) {
      return Failure('Failed to import automaton: $e');
    }
  }

  @override
  Future<BoolResult> validateAutomaton(AutomatonEntity automaton) async {
    try {
      final fsa = _convertEntityToFsa(automaton);
      final result = _automatonService.validateAutomaton(fsa);
      if (result.isFailure) {
        return Failure(result.error!);
      }

      return Success(result.data!);
    } catch (e) {
      return Failure('Failed to validate automaton: $e');
    }
  }

  CreateAutomatonRequest _convertEntityToRequest(AutomatonEntity automaton) {
    final states = automaton.states
        .map(
          (state) => StateData(
            id: state.id,
            name: state.name,
            position: Point(state.x, state.y),
            isInitial: state.isInitial || automaton.initialId == state.id,
            isAccepting: state.isFinal,
          ),
        )
        .toList();

    final transitions = <TransitionData>[];
    automaton.transitions.forEach((key, destinations) {
      final fromStateId = extractStateIdFromTransitionKey(key);
      if (fromStateId.isEmpty) {
        return;
      }
      final symbol = normalizeToEpsilon(extractSymbolFromTransitionKey(key));
      for (final toStateId in destinations) {
        transitions.add(
          TransitionData(
            fromStateId: fromStateId,
            toStateId: toStateId,
            symbol: symbol,
          ),
        );
      }
    });

    final bounds = _calculateBounds(automaton.states);

    return CreateAutomatonRequest(
      name: automaton.name,
      description: null,
      states: states,
      transitions: transitions,
      alphabet: automaton.alphabet.toList(),
      bounds: bounds,
    );
  }

  AutomatonEntity _convertFsaToEntity(FSA automaton) {
    return AutomatonEntityMapper.fromFsa(automaton);
  }

  FSA _convertEntityToFsa(AutomatonEntity automaton) {
    return AutomatonEntityMapper.toFsa(
      automaton,
      missingEndpointPolicy: MissingTransitionEndpointPolicy.throwError,
      transitionIdBuilder: (index) => 't${automaton.id}_$index',
      bounds: _calculateFsaBounds(automaton.states),
    );
  }

  math.Rectangle<double> _calculateFsaBounds(List<StateEntity> states) {
    final bounds = _calculateBounds(states);
    return math.Rectangle<double>(
      bounds.left,
      bounds.top,
      bounds.right - bounds.left,
      bounds.bottom - bounds.top,
    );
  }

  Rect _calculateBounds(List<StateEntity> states) {
    if (states.isEmpty) {
      return const Rect(0, 0, 800, 600);
    }

    var minX = states.first.x;
    var minY = states.first.y;
    var maxX = states.first.x;
    var maxY = states.first.y;

    for (final state in states.skip(1)) {
      minX = math.min(minX, state.x);
      minY = math.min(minY, state.y);
      maxX = math.max(maxX, state.x);
      maxY = math.max(maxY, state.y);
    }

    const padding = 50.0;

    return Rect(minX - padding, minY - padding, maxX + padding, maxY + padding);
  }
}
