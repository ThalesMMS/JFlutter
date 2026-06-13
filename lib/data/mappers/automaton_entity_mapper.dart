import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../core/entities/automaton_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/state.dart';
import '../../core/models/transition.dart';
import '../../core/utils/epsilon_utils.dart';

enum MissingTransitionEndpointPolicy {
  skip,
  throwError,
}

class AutomatonEntityMapper {
  static FSA toFsa(
    AutomatonEntity entity, {
    MissingTransitionEndpointPolicy missingEndpointPolicy =
        MissingTransitionEndpointPolicy.skip,
    String Function(int index)? transitionIdBuilder,
    math.Rectangle<double> bounds =
        const math.Rectangle<double>(0, 0, 800, 600),
    bool markInitialStateFromInitialId = true,
  }) {
    final states = entity.states
        .map(
          (state) => State(
            id: state.id,
            label: state.name,
            position: Vector2(state.x, state.y),
            isInitial: state.isInitial ||
                (markInitialStateFromInitialId && entity.initialId == state.id),
            isAccepting: state.isFinal,
          ),
        )
        .toSet();

    final stateById = {for (final state in states) state.id: state};
    final transitions = <FSATransition>{};
    var transitionIndex = 0;

    void handleMissing(String message) {
      if (missingEndpointPolicy == MissingTransitionEndpointPolicy.throwError) {
        throw StateError(message);
      }
    }

    for (final entry in entity.transitions.entries) {
      final fromId = extractStateIdFromTransitionKey(entry.key);
      final fromState = stateById[fromId];
      if (fromState == null) {
        handleMissing('Unknown from state $fromId');
        continue;
      }

      final symbol = normalizeToEpsilon(
        extractSymbolFromTransitionKey(entry.key),
      );
      final isLambda = isEpsilonSymbol(symbol);
      final transitionType = isLambda
          ? TransitionType.epsilon
          : entry.value.length > 1
              ? TransitionType.nondeterministic
              : TransitionType.deterministic;

      for (final toStateId in entry.value) {
        final toState = stateById[toStateId];
        if (toState == null) {
          handleMissing('Unknown to state $toStateId');
          continue;
        }

        final transitionId = transitionIdBuilder?.call(transitionIndex) ??
            't${transitionIndex + 1}';
        transitions.add(
          FSATransition(
            id: transitionId,
            fromState: fromState,
            toState: toState,
            label: symbol,
            inputSymbols: isLambda ? const <String>{} : {symbol},
            lambdaSymbol: isLambda ? kEpsilonSymbol : null,
            type: transitionType,
          ),
        );
        transitionIndex++;
      }
    }

    final initialState = entity.initialId != null
        ? stateById[entity.initialId!]
        : states.where((state) => state.isInitial).firstOrNull;
    final acceptingStates = states.where((state) => state.isAccepting).toSet();

    return FSA(
      id: entity.id,
      name: entity.name,
      states: states,
      transitions: transitions,
      alphabet: entity.alphabet,
      initialState: initialState,
      acceptingStates: acceptingStates,
      created: DateTime.now(),
      modified: DateTime.now(),
      bounds: bounds,
      panOffset: Vector2.zero(),
      zoomLevel: 1.0,
    );
  }

  static AutomatonEntity fromFsa(
    FSA fsa, {
    int? nextId,
    AutomatonType? type,
    bool deduplicateDestinations = false,
    bool sortDestinations = false,
  }) {
    final states = fsa.states
        .map(
          (state) => StateEntity(
            id: state.id,
            name: state.label,
            x: state.position.x,
            y: state.position.y,
            isInitial: state.isInitial,
            isFinal: state.isAccepting,
          ),
        )
        .toList();

    final transitions = <String, List<String>>{};
    for (final transition in fsa.transitions.whereType<FSATransition>()) {
      for (final symbol in _symbolsForTransition(transition)) {
        final key = '${transition.fromState.id}|$symbol';
        final destinations = transitions.putIfAbsent(key, () => <String>[]);
        if (!deduplicateDestinations ||
            !destinations.contains(transition.toState.id)) {
          destinations.add(transition.toState.id);
        }
      }
    }

    if (sortDestinations) {
      for (final destinations in transitions.values) {
        destinations.sort();
      }
    }

    return AutomatonEntity(
      id: fsa.id,
      name: fsa.name,
      alphabet: fsa.alphabet,
      states: states,
      transitions: transitions,
      initialId: fsa.initialState?.id,
      nextId: nextId ?? states.length,
      type: type ?? _inferType(fsa, transitions),
    );
  }

  static Iterable<String> _symbolsForTransition(FSATransition transition) {
    if (transition.lambdaSymbol != null || transition.isEpsilonTransition) {
      return <String>[normalizeToEpsilon(transition.lambdaSymbol)];
    }

    return transition.inputSymbols.map(normalizeToEpsilon);
  }

  static AutomatonType _inferType(
    FSA fsa,
    Map<String, List<String>> transitions,
  ) {
    if (fsa.hasEpsilonTransitions) {
      return AutomatonType.nfaLambda;
    }
    if (!fsa.isDeterministic) {
      return AutomatonType.nfa;
    }

    for (final entry in transitions.entries) {
      if (isEpsilonSymbol(extractSymbolFromTransitionKey(entry.key))) {
        return AutomatonType.nfaLambda;
      }
      if (entry.value.toSet().length > 1) {
        return AutomatonType.nfa;
      }
    }

    return AutomatonType.dfa;
  }
}
