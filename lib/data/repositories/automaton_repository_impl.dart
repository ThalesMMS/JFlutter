import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../core/entities/automaton_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/state.dart';
import '../../core/result.dart';
import '../../core/repositories/automaton_repository.dart';
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
        .map((state) => StateData(
              id: state.id,
              name: state.name,
              position: Point(state.x, state.y),
              isInitial: state.isInitial || automaton.initialId == state.id,
              isAccepting: state.isFinal,
            ))
        .toList();

    final transitions = <TransitionData>[];
    automaton.transitions.forEach((key, destinations) {
      final parts = key.split('|');
      if (parts.length != 2) {
        return;
      }
      final fromStateId = parts[0];
      final symbol = parts[1];
      for (final toStateId in destinations) {
        transitions.add(TransitionData(
          fromStateId: fromStateId,
          toStateId: toStateId,
          symbol: symbol,
        ));
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
    final states = automaton.states
        .map((state) => StateEntity(
              id: state.id,
              name: state.label,
              x: state.position.x,
              y: state.position.y,
              isInitial: state.isInitial,
              isFinal: state.isAccepting,
            ))
        .toList();

    final transitions = <String, List<String>>{};
    for (final transition in automaton.transitions.whereType<FSATransition>()) {
      final symbols = <String>{};
      if (transition.lambdaSymbol != null) {
        symbols.add(transition.lambdaSymbol!);
      } else {
        symbols.addAll(transition.inputSymbols);
      }

      for (final symbol in symbols) {
        final key = '${transition.fromState.id}|$symbol';
        transitions
            .putIfAbsent(key, () => <String>[])
            .add(transition.toState.id);
      }
    }

    final type = automaton.hasEpsilonTransitions
        ? AutomatonType.nfaLambda
        : automaton.isDeterministic
            ? AutomatonType.dfa
            : AutomatonType.nfa;

    return AutomatonEntity(
      id: automaton.id,
      name: automaton.name,
      alphabet: automaton.alphabet,
      states: states,
      transitions: transitions,
      initialId: automaton.initialState?.id,
      nextId: states.length,
      type: type,
    );
  }

  FSA _convertEntityToFsa(AutomatonEntity automaton) {
    final states = automaton.states
        .map((state) => State(
              id: state.id,
              label: state.name,
              position: Vector2(state.x, state.y),
              isInitial: state.isInitial || automaton.initialId == state.id,
              isAccepting: state.isFinal,
            ))
        .toSet();

    final stateById = {for (final state in states) state.id: state};

    final transitions = <FSATransition>{};
    var transitionIndex = 0;

    automaton.transitions.forEach((key, destinations) {
      final parts = key.split('|');
      if (parts.length != 2) {
        return;
      }

      final fromState = stateById[parts[0]];
      if (fromState == null) {
        throw StateError('Unknown from state ${parts[0]}');
      }

      final symbol = parts[1];
      final isLambda =
          symbol == 'λ' || symbol == 'ε' || symbol.toLowerCase() == 'lambda';

      for (final destination in destinations) {
        final toState = stateById[destination];
        if (toState == null) {
          throw StateError('Unknown to state $destination');
        }

        transitions.add(FSATransition(
          id: 't${automaton.id}_$transitionIndex',
          fromState: fromState,
          toState: toState,
          label: symbol,
          inputSymbols: isLambda ? <String>{} : {symbol},
          lambdaSymbol: isLambda ? symbol : null,
        ));
        transitionIndex++;
      }
    });

    final initialState = automaton.initialId != null
        ? stateById[automaton.initialId!]
        : () {
            try {
              return states.firstWhere((s) => s.isInitial);
            } catch (_) {
              return null;
            }
          }();

    final acceptingStates = states.where((state) => state.isAccepting).toSet();

    final boundsRect = _calculateBounds(automaton.states);
    final bounds = math.Rectangle(
      boundsRect.left,
      boundsRect.top,
      boundsRect.right - boundsRect.left,
      boundsRect.bottom - boundsRect.top,
    );

    return FSA(
      id: automaton.id,
      name: automaton.name,
      states: states,
      transitions: transitions,
      alphabet: automaton.alphabet,
      initialState: initialState,
      acceptingStates: acceptingStates,
      created: DateTime.now(),
      modified: DateTime.now(),
      bounds: bounds,
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

    return Rect(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }
}
