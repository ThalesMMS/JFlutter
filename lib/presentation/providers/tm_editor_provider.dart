import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../core/models/state.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../../core/models/transition.dart';

/// Holds the current TM being edited in the canvas together with metadata
/// that other widgets might be interested in (like tape symbol usage and
/// highlighting information).
class TMEditorState {
  /// The TM built from the canvas contents.
  final TM? tm;

  /// Unique tape symbols discovered while building the TM.
  final Set<String> tapeSymbols;

  /// Directions that appear in transitions.
  final Set<String> moveDirections;

  /// Identifiers of transitions that participate in nondeterministic choices.
  final Set<String> nondeterministicTransitionIds;

  /// States currently rendered on the canvas.
  final List<State> states;

  /// TM transitions currently rendered on the canvas.
  final List<TMTransition> transitions;

  const TMEditorState({
    this.tm,
    this.tapeSymbols = const {},
    this.moveDirections = const {},
    this.nondeterministicTransitionIds = const {},
    this.states = const [],
    this.transitions = const [],
  });

  TMEditorState copyWith({
    TM? tm,
    Set<String>? tapeSymbols,
    Set<String>? moveDirections,
    Set<String>? nondeterministicTransitionIds,
    List<State>? states,
    List<TMTransition>? transitions,
  }) {
    return TMEditorState(
      tm: tm ?? this.tm,
      tapeSymbols: tapeSymbols ?? this.tapeSymbols,
      moveDirections: moveDirections ?? this.moveDirections,
      nondeterministicTransitionIds:
          nondeterministicTransitionIds ?? this.nondeterministicTransitionIds,
      states: states ?? this.states,
      transitions: transitions ?? this.transitions,
    );
  }
}

/// Riverpod notifier responsible for maintaining the TM that is edited on the canvas.
class TMEditorNotifier extends StateNotifier<TMEditorState> {
  TMEditorNotifier() : super(const TMEditorState());

  final List<State> _states = [];
  final List<TMTransition> _transitions = [];

  /// Updates the notifier using the raw state and transition collections
  /// maintained by the canvas and returns the resulting TM.
  TM? updateFromCanvas({
    required List<State> states,
    required List<TMTransition> transitions,
  }) {
    _states
      ..clear()
      ..addAll(states.map((state) => state.copyWith()));
    _transitions
      ..clear()
      ..addAll(transitions.map((transition) => transition.copyWith()));

    return _rebuildState();
  }

  /// Adds a new state or updates an existing one using the provided data.
  TM? upsertState({
    required String id,
    required String label,
    required double x,
    required double y,
    bool? isInitial,
    bool? isAccepting,
  }) {
    final index = _states.indexWhere((state) => state.id == id);
    final existing = index != -1 ? _states[index] : null;

    final hasInitial = _states.any((state) => state.isInitial);
    final resolvedInitial =
        isInitial ?? existing?.isInitial ?? (!hasInitial && index == -1);
    final resolvedAccepting = isAccepting ?? existing?.isAccepting ?? false;

    final updated = (existing ??
            State(
              id: id,
              label: label,
              position: Vector2(x, y),
              isInitial: resolvedInitial || _states.isEmpty,
              isAccepting: resolvedAccepting,
            ))
        .copyWith(
      label: label,
      position: Vector2(x, y),
      isInitial: resolvedInitial,
      isAccepting: resolvedAccepting,
    );

    if (index == -1) {
      _states.add(updated);
    } else {
      _states[index] = updated;
    }

    if (updated.isInitial) {
      for (var i = 0; i < _states.length; i++) {
        if (_states[i].id != updated.id && _states[i].isInitial) {
          _states[i] = _states[i].copyWith(isInitial: false);
        }
      }
    } else if (!_states.any((state) => state.isInitial) && _states.isNotEmpty) {
      final normalisedInitial = _states[0].copyWith(isInitial: true);
      _states[0] = normalisedInitial;
      _rebindTransitionsForState(normalisedInitial);
    }

    final storedState = index == -1 ? _states.last : _states[index];
    _rebindTransitionsForState(storedState);

    return _rebuildState();
  }

  /// Moves a state to a new position on the canvas.
  TM? moveState({
    required String id,
    required double x,
    required double y,
  }) {
    final index = _states.indexWhere((state) => state.id == id);
    if (index == -1) {
      return state.tm;
    }

    final updated = _states[index].copyWith(position: Vector2(x, y));
    _states[index] = updated;
    _rebindTransitionsForState(updated);

    return _rebuildState();
  }

  /// Updates the label of the state matching [id].
  TM? updateStateLabel({
    required String id,
    required String label,
  }) {
    final index = _states.indexWhere((state) => state.id == id);
    if (index == -1) {
      return state.tm;
    }

    final updated = _states[index].copyWith(label: label);
    _states[index] = updated;
    _rebindTransitionsForState(updated);

    return _rebuildState();
  }

  /// Adds or updates a TM transition using the supplied values.
  TM? addOrUpdateTransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    Vector2? controlPoint,
  }) {
    final fromIndex = _states.indexWhere((state) => state.id == fromStateId);
    final toIndex = _states.indexWhere((state) => state.id == toStateId);
    if (fromIndex == -1 || toIndex == -1) {
      return state.tm;
    }

    final existingIndex =
        _transitions.indexWhere((transition) => transition.id == id);
    final existing = existingIndex != -1 ? _transitions[existingIndex] : null;

    final resolvedRead = readSymbol ?? existing?.readSymbol ?? '';
    final resolvedWrite = writeSymbol ?? existing?.writeSymbol ?? '';
    final resolvedDirection = direction ?? existing?.direction ?? TapeDirection.right;
    final resolvedControlPoint =
        controlPoint ?? existing?.controlPoint ?? Vector2.zero();

    final base = existing ??
        TMTransition(
          id: id,
          fromState: _states[fromIndex],
          toState: _states[toIndex],
          label: '',
          controlPoint: resolvedControlPoint,
          readSymbol: resolvedRead,
          writeSymbol: resolvedWrite,
          direction: resolvedDirection,
        );

    final updated = base.copyWith(
      fromState: _states[fromIndex],
      toState: _states[toIndex],
      controlPoint: resolvedControlPoint,
      readSymbol: resolvedRead,
      writeSymbol: resolvedWrite,
      direction: resolvedDirection,
      label: _formatTransitionLabel(
        resolvedRead,
        resolvedWrite,
        resolvedDirection,
      ),
    );

    if (existingIndex == -1) {
      _transitions.add(updated);
    } else {
      _transitions[existingIndex] = updated;
    }

    return _rebuildState();
  }

  /// Updates the tape operations for an existing transition.
  TM? updateTransitionOperations({
    required String id,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
  }) {
    final index = _transitions.indexWhere((transition) => transition.id == id);
    if (index == -1) {
      return state.tm;
    }

    final transition = _transitions[index];
    return addOrUpdateTransition(
      id: id,
      fromStateId: transition.fromState.id,
      toStateId: transition.toState.id,
      readSymbol: readSymbol ?? transition.readSymbol,
      writeSymbol: writeSymbol ?? transition.writeSymbol,
      direction: direction ?? transition.direction,
      controlPoint: transition.controlPoint,
    );
  }

  Set<String> _findNondeterministicTransitions(Set<TMTransition> transitions) {
    final grouped = <String, List<TMTransition>>{};

    for (final transition in transitions) {
      final key = [
        transition.fromState.id,
        transition.readSymbol,
        transition.tapeNumber.toString(),
      ].join('|');

      grouped.putIfAbsent(key, () => []).add(transition);
    }

    return grouped.values
        .where((list) => list.length > 1)
        .expand((list) => list.map((transition) => transition.id))
        .toSet();
  }

  TM? _rebuildState() {
    if (_states.isEmpty) {
      state = const TMEditorState(tm: null);
      return null;
    }

    final stateSet = _states.toSet();
    final transitionSet = _transitions.toSet();

    final initialState = _states.firstWhere(
      (state) => state.isInitial,
      orElse: () => _states.first,
    );

    final acceptingStates = _states.where((state) => state.isAccepting).toSet();

    final alphabet = <String>{};
    final tapeAlphabet = <String>{'B'};
    final moveDirections = <String>{};

    for (final transition in transitionSet) {
      if (transition.readSymbol.isNotEmpty) {
        alphabet.add(transition.readSymbol);
        tapeAlphabet.add(transition.readSymbol);
      }

      if (transition.writeSymbol.isNotEmpty) {
        tapeAlphabet.add(transition.writeSymbol);
      }

      moveDirections.add(transition.direction.name);
    }

    const blankSymbol = 'B';
    tapeAlphabet.add(blankSymbol);

    final now = DateTime.now();

    final tm = TM(
      id: 'editor-tm',
      name: 'Canvas TM',
      states: stateSet,
      transitions: transitionSet.map<Transition>((t) => t).toSet(),
      alphabet: alphabet,
      initialState: initialState,
      acceptingStates:
          acceptingStates.isEmpty ? {_states.last} : acceptingStates,
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
      tapeAlphabet: tapeAlphabet,
      blankSymbol: blankSymbol,
      tapeCount: 1,
      zoomLevel: 1,
      panOffset: Vector2.zero(),
    );

    final nondeterministicTransitionIds = _findNondeterministicTransitions(
      transitionSet,
    );

    state = state.copyWith(
      tm: tm,
      tapeSymbols: tapeAlphabet,
      moveDirections: moveDirections,
      nondeterministicTransitionIds: nondeterministicTransitionIds,
      states: List<State>.unmodifiable(_states),
      transitions: List<TMTransition>.unmodifiable(_transitions),
    );

    return tm;
  }

  void _rebindTransitionsForState(State updatedState) {
    for (var i = 0; i < _transitions.length; i++) {
      final transition = _transitions[i];
      if (transition.fromState.id == updatedState.id ||
          transition.toState.id == updatedState.id) {
        _transitions[i] = transition.copyWith(
          fromState: transition.fromState.id == updatedState.id
              ? updatedState
              : transition.fromState,
          toState: transition.toState.id == updatedState.id
              ? updatedState
              : transition.toState,
        );
      }
    }
  }

  String _formatTransitionLabel(
    String read,
    String write,
    TapeDirection direction,
  ) {
    final directionSymbol = switch (direction) {
      TapeDirection.left => 'L',
      TapeDirection.right => 'R',
      TapeDirection.stay => 'S',
    };

    final safeRead = read.isEmpty ? '∅' : read;
    final safeWrite = write.isEmpty ? '∅' : write;
    return '$safeRead/$safeWrite,$directionSymbol';
  }
}

/// Provider exposing the current TM editor state.
final tmEditorProvider =
    StateNotifierProvider<TMEditorNotifier, TMEditorState>(
  (ref) => TMEditorNotifier(),
);
