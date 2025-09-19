import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../core/models/state.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../../core/models/transition.dart';

/// Holds the current TM being edited in the canvas together with metadata
/// that other widgets might be interested in (like tape symbol usage).
class TMEditorState {
  /// The TM built from the canvas contents.
  final TM? tm;

  /// Unique tape symbols discovered while building the TM.
  final Set<String> tapeSymbols;

  /// Directions that appear in transitions.
  final Set<String> moveDirections;

  const TMEditorState({
    this.tm,
    this.tapeSymbols = const {},
    this.moveDirections = const {},
  });

  TMEditorState copyWith({
    TM? tm,
    Set<String>? tapeSymbols,
    Set<String>? moveDirections,
  }) {
    return TMEditorState(
      tm: tm ?? this.tm,
      tapeSymbols: tapeSymbols ?? this.tapeSymbols,
      moveDirections: moveDirections ?? this.moveDirections,
    );
  }
}

/// Notifier responsible for maintaining the TM that is edited on the canvas.
class TMEditorNotifier extends StateNotifier<TMEditorState> {
  TMEditorNotifier() : super(const TMEditorState());

  /// Updates the notifier using the raw state and transition collections
  /// maintained by the canvas and returns the resulting TM.
  TM? updateFromCanvas({
    required List<State> states,
    required List<TMTransition> transitions,
  }) {
    if (states.isEmpty) {
      state = const TMEditorState(tm: null);
      return null;
    }

    final stateSet = states.toSet();
    final transitionSet = transitions.toSet();

    final initialState = states.firstWhere(
      (s) => s.isInitial,
      orElse: () => states.first,
    );

    final acceptingStates = states.where((s) => s.isAccepting).toSet();

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

    final now = DateTime.now();

    final tm = TM(
      id: 'editor-tm',
      name: 'Canvas TM',
      states: stateSet,
      transitions: transitionSet.map<Transition>((t) => t).toSet(),
      alphabet: alphabet,
      initialState: initialState,
      acceptingStates: acceptingStates,
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
      tapeAlphabet: tapeAlphabet,
      blankSymbol: 'B',
      tapeCount: 1,
      zoomLevel: 1,
      panOffset: Vector2.zero(),
    );

    state = state.copyWith(
      tm: tm,
      tapeSymbols: tapeAlphabet,
      moveDirections: moveDirections,
    );

    return tm;
  }
}

/// Provider exposing the current TM editor state.
final tmEditorProvider =
    StateNotifierProvider<TMEditorNotifier, TMEditorState>(
  (ref) => TMEditorNotifier(),
);
