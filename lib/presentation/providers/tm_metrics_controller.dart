import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/tm.dart';
import 'tm_editor_provider.dart';

/// Holds computed metrics about the current TM being edited.
class TmMetricsState {
  /// Latest TM produced by the editor.
  final TM? tm;

  /// Total number of states present in the TM.
  final int stateCount;

  /// Total number of transitions present in the TM.
  final int transitionCount;

  /// Unique tape symbols discovered across transitions.
  final Set<String> tapeSymbols;

  /// Move directions used in transitions.
  final Set<String> moveDirections;

  /// Identifiers of transitions that are part of nondeterministic choices.
  final Set<String> nondeterministicTransitionIds;

  /// Whether the TM declares an initial state.
  final bool hasInitialState;

  /// Whether the TM has at least one accepting state.
  final bool hasAcceptingState;

  TmMetricsState({
    this.tm,
    this.stateCount = 0,
    this.transitionCount = 0,
    Set<String> tapeSymbols = const <String>{},
    Set<String> moveDirections = const <String>{},
    Set<String> nondeterministicTransitionIds = const <String>{},
    this.hasInitialState = false,
    this.hasAcceptingState = false,
  })  : tapeSymbols = Set.unmodifiable(tapeSymbols),
        moveDirections = Set.unmodifiable(moveDirections),
        nondeterministicTransitionIds =
            Set.unmodifiable(nondeterministicTransitionIds);

  /// Whether there is any TM currently available.
  bool get hasMachine => tm != null && stateCount > 0;

  /// Whether the TM is ready to be simulated.
  bool get isMachineReady => hasMachine && hasInitialState && hasAcceptingState;
}

/// Manages the TM metrics derived from the editor provider.
class TmMetricsController extends StateNotifier<TmMetricsState> {
  TmMetricsController() : super(TmMetricsState());

  /// Updates the metrics based on the latest editor state.
  void updateFromEditor(TMEditorState editorState) {
    final tm = editorState.tm;
    if (tm == null) {
      state = TmMetricsState();
      return;
    }

    final transitions = tm.tmTransitions;
    final moveDirections = editorState.moveDirections
        .map((direction) => direction.toUpperCase())
        .toSet();

    state = TmMetricsState(
      tm: tm,
      stateCount: tm.states.length,
      transitionCount: transitions.length,
      tapeSymbols: editorState.tapeSymbols,
      moveDirections: moveDirections,
      nondeterministicTransitionIds: editorState.nondeterministicTransitionIds,
      hasInitialState: tm.initialState != null,
      hasAcceptingState: tm.acceptingStates.isNotEmpty,
    );
  }
}

/// Provider exposing the TM metrics controller synchronized with the editor.
final tmMetricsControllerProvider =
    StateNotifierProvider<TmMetricsController, TmMetricsState>((ref) {
  final controller = TmMetricsController();
  ref.listen<TMEditorState>(
    tmEditorProvider,
    (_, next) => controller.updateFromEditor(next),
    fireImmediately: true,
  );
  return controller;
});
