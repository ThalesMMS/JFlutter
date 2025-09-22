import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../entities/automaton_entity.dart';
import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/state.dart';

/// Converts a [FSA] model into an [AutomatonEntity].
AutomatonEntity fsaToAutomatonEntity(FSA automaton) {
  final states = automaton.states
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
  for (final transition in automaton.transitions.whereType<FSATransition>()) {
    final symbols = <String>{};
    if (transition.lambdaSymbol != null) {
      symbols.add(transition.lambdaSymbol!);
    } else {
      symbols.addAll(transition.inputSymbols);
    }

    for (final symbol in symbols) {
      final key = '${transition.fromState.id}|$symbol';
      transitions.putIfAbsent(key, () => <String>[]).add(transition.toState.id);
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

/// Converts an [AutomatonEntity] into a [FSA] model.
FSA automatonEntityToFsa(
  AutomatonEntity automaton, {
  DateTime? created,
  DateTime? modified,
}) {
  final states = automaton.states
      .map(
        (state) => State(
          id: state.id,
          label: state.name,
          position: Vector2(state.x, state.y),
          isInitial: state.isInitial || automaton.initialId == state.id,
          isAccepting: state.isFinal,
        ),
      )
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
    final normalized = symbol.toLowerCase();
    final isLambda = symbol == 'λ' ||
        symbol == 'ε' ||
        normalized == 'lambda' ||
        normalized == '£' ||
        normalized == '€';

    for (final destination in destinations) {
      final toState = stateById[destination];
      if (toState == null) {
        throw StateError('Unknown to state $destination');
      }

      transitions.add(
        FSATransition(
          id: 't${automaton.id}_$transitionIndex',
          fromState: fromState,
          toState: toState,
          label: symbol,
          inputSymbols: isLambda ? <String>{} : {symbol},
          lambdaSymbol: isLambda ? symbol : null,
        ),
      );
      transitionIndex++;
    }
  });

  State? initialState;
  if (automaton.initialId != null) {
    initialState = stateById[automaton.initialId!];
  }

  initialState ??= () {
    try {
      return states.firstWhere((state) => state.isInitial);
    } catch (_) {
      return null;
    }
  }();

  final acceptingStates = states.where((state) => state.isAccepting).toSet();

  final bounds = _calculateBounds(automaton.states);

  return FSA(
    id: automaton.id,
    name: automaton.name,
    states: states,
    transitions: transitions,
    alphabet: automaton.alphabet,
    initialState: initialState,
    acceptingStates: acceptingStates,
    created: created ?? DateTime.now(),
    modified: modified ?? DateTime.now(),
    bounds: bounds,
  );
}

math.Rectangle<double> _calculateBounds(List<StateEntity> states) {
  if (states.isEmpty) {
    return math.Rectangle<double>(0, 0, 800, 600);
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
  final left = minX - padding;
  final top = minY - padding;
  final right = maxX + padding;
  final bottom = maxY + padding;

  return math.Rectangle<double>(
    left,
    top,
    right - left,
    bottom - top,
  );
}
