import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/state.dart';
import '../models/transition.dart';

/// Encapsulates state and transition management required to build Thompson NFAs.
class ThompsonContext {
  ThompsonContext({
    Set<String>? wildcardAlphabet,
    String wildcardSymbol = defaultWildcardSymbol,
  })  : wildcardAlphabet =
            wildcardAlphabet == null ? {...defaultWildcardAlphabet} : {...wildcardAlphabet},
        wildcardSymbol = wildcardSymbol;

  /// Default label displayed on wildcard transitions.
  static const String defaultWildcardSymbol = '⋅';

  static const Set<String> defaultWildcardAlphabet = {'a', 'b', 'c'};

  /// Symbols consumed when a wildcard transition is traversed.
  final Set<String> wildcardAlphabet;

  /// Display label for wildcard transitions.
  final String wildcardSymbol;

  static const double _horizontalSpacing = 140;
  static const double _verticalSpacing = 120;

  int _stateCounter = 0;
  int _transitionCounter = 0;

  /// Creates a new automaton state with a layout-friendly position.
  State createState() {
    final id = 'q${_stateCounter++}';
    final column = (_stateCounter - 1) % 8;
    final row = (_stateCounter - 1) ~/ 8;
    final position = Vector2(
      120 + column * _horizontalSpacing,
      200 + row * _verticalSpacing,
    );

    return State(
      id: id,
      label: id,
      position: position,
    );
  }

  /// Builds an epsilon transition connecting [start] to [end].
  FSATransition createEpsilonTransition({
    required State start,
    required State end,
  }) {
    final id = 't${_transitionCounter++}';
    return FSATransition.epsilon(
      id: id,
      fromState: start,
      toState: end,
    );
  }

  /// Builds a deterministic transition labelled with [symbol].
  FSATransition createSymbolTransition({
    required State start,
    required State end,
    required String symbol,
  }) {
    final id = 't${_transitionCounter++}';
    return FSATransition.deterministic(
      id: id,
      fromState: start,
      toState: end,
      symbol: symbol,
    );
  }

  /// Builds a wildcard transition that consumes all [wildcardAlphabet] symbols.
  FSATransition createWildcardTransition({
    required State start,
    required State end,
  }) {
    final id = 't${_transitionCounter++}';
    if (wildcardAlphabet.length <= 1) {
      final symbol = wildcardAlphabet.isEmpty
          ? defaultWildcardAlphabet.first
          : wildcardAlphabet.first;
      return FSATransition.deterministic(
        id: id,
        fromState: start,
        toState: end,
        symbol: symbol,
        label: wildcardSymbol,
      );
    }

    return FSATransition.nondeterministic(
      id: id,
      fromState: start,
      toState: end,
      symbols: wildcardAlphabet,
      label: wildcardSymbol,
    );
  }

  /// Returns an epsilon fragment accepting only the empty word.
  ThompsonFragment createEpsilonFragment() {
    final start = createState();
    final accept = createState();
    final transition = createEpsilonTransition(start: start, end: accept);
    return ThompsonFragment(
      start: start,
      accept: accept,
      states: {start, accept},
      transitions: {transition},
      alphabet: const {},
    );
  }

  /// Concatenates [first] followed by [second].
  ThompsonFragment concatenate(ThompsonFragment first, ThompsonFragment second) {
    final epsilon = createEpsilonTransition(
      start: first.accept,
      end: second.start,
    );

    return ThompsonFragment(
      start: first.start,
      accept: second.accept,
      states: {...first.states, ...second.states},
      transitions: {...first.transitions, ...second.transitions, epsilon},
      alphabet: {...first.alphabet, ...second.alphabet},
    );
  }

  /// Creates a fragment that recognises the union of [left] and [right].
  ThompsonFragment alternate(ThompsonFragment left, ThompsonFragment right) {
    final start = createState();
    final accept = createState();

    final transitions = {
      ...left.transitions,
      ...right.transitions,
      createEpsilonTransition(start: start, end: left.start),
      createEpsilonTransition(start: start, end: right.start),
      createEpsilonTransition(start: left.accept, end: accept),
      createEpsilonTransition(start: right.accept, end: accept),
    };

    return ThompsonFragment(
      start: start,
      accept: accept,
      states: {...left.states, ...right.states, start, accept},
      transitions: transitions,
      alphabet: {...left.alphabet, ...right.alphabet},
    );
  }

  /// Wraps [fragment] with the standard Kleene star construction.
  ThompsonFragment kleeneStar(ThompsonFragment fragment) {
    final start = createState();
    final accept = createState();

    final transitions = {
      ...fragment.transitions,
      createEpsilonTransition(start: start, end: fragment.start),
      createEpsilonTransition(start: start, end: accept),
      createEpsilonTransition(start: fragment.accept, end: fragment.start),
      createEpsilonTransition(start: fragment.accept, end: accept),
    };

    return ThompsonFragment(
      start: start,
      accept: accept,
      states: {...fragment.states, start, accept},
      transitions: transitions,
      alphabet: {...fragment.alphabet},
    );
  }

  /// Creates a fragment representing an optional [fragment].
  ThompsonFragment optional(ThompsonFragment fragment) {
    final start = createState();
    final accept = createState();

    final transitions = {
      ...fragment.transitions,
      createEpsilonTransition(start: start, end: accept),
      createEpsilonTransition(start: start, end: fragment.start),
      createEpsilonTransition(start: fragment.accept, end: accept),
    };

    return ThompsonFragment(
      start: start,
      accept: accept,
      states: {...fragment.states, start, accept},
      transitions: transitions,
      alphabet: fragment.alphabet,
    );
  }

  /// Builds the final NFA automaton for [fragment] and [pattern].
  FSA buildAutomaton({
    required ThompsonFragment fragment,
    required String pattern,
  }) {
    var updatedFragment = fragment;
    final initial = fragment.start.copyWith(
      isInitial: true,
      type: StateType.initial,
    );
    updatedFragment = updatedFragment.rebindState(fragment.start, initial);

    final accepting = updatedFragment.accept.copyWith(
      isAccepting: true,
      type: StateType.accepting,
    );
    updatedFragment = updatedFragment.rebindState(updatedFragment.accept, accepting);

    final now = DateTime.now();
    final bounds = _computeBounds(updatedFragment.states);

    return FSA(
      id: 'regex_${now.microsecondsSinceEpoch}',
      name: 'Regex: $pattern',
      states: updatedFragment.states,
      transitions: updatedFragment.transitions,
      alphabet: updatedFragment.alphabet,
      initialState: initial,
      acceptingStates: {accepting},
      created: now,
      modified: now,
      bounds: bounds,
    );
  }

  math.Rectangle<double> _computeBounds(Set<State> states) {
    if (states.isEmpty) {
      return math.Rectangle<double>(0, 0, 600, 400);
    }

    var minX = states.first.position.x;
    var maxX = minX;
    var minY = states.first.position.y;
    var maxY = minY;

    for (final state in states) {
      minX = math.min(minX, state.position.x);
      maxX = math.max(maxX, state.position.x);
      minY = math.min(minY, state.position.y);
      maxY = math.max(maxY, state.position.y);
    }

    const margin = 120.0;
    return math.Rectangle<double>(
      minX - margin,
      minY - margin,
      (maxX - minX) + margin * 2,
      (maxY - minY) + margin * 2,
    );
  }
}

/// Intermediate Thompson fragment consisting of a start, accept state and the
/// aggregated states/transitions in between.
class ThompsonFragment {
  ThompsonFragment({
    required this.start,
    required this.accept,
    required Set<State> states,
    required Set<FSATransition> transitions,
    required Set<String> alphabet,
  })  : states = states,
        transitions = transitions,
        alphabet = alphabet;

  final State start;
  final State accept;
  final Set<State> states;
  final Set<FSATransition> transitions;
  final Set<String> alphabet;

  /// Replaces [target] state with [replacement] across the fragment.
  ThompsonFragment rebindState(State target, State replacement) {
    final updatedStates = {...states}..remove(target)..add(replacement);
    final updatedTransitions = transitions
        .map((transition) {
          final from = transition.fromState == target ? replacement : transition.fromState;
          final to = transition.toState == target ? replacement : transition.toState;
          if (from != transition.fromState || to != transition.toState) {
            return transition.copyWith(fromState: from, toState: to);
          }
          return transition;
        })
        .toSet();

    return ThompsonFragment(
      start: target == start ? replacement : start,
      accept: target == accept ? replacement : accept,
      states: updatedStates,
      transitions: updatedTransitions,
      alphabet: alphabet,
    );
  }
}
