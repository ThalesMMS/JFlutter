import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../core/models/pda.dart';
import '../../core/models/pda_transition.dart';
import '../../core/models/state.dart';
import '../../core/models/transition.dart';

/// Holds the current PDA being edited in the canvas together with
/// metadata used by other widgets (e.g. highlighting information).
class PDAEditorState {
  /// The PDA built from the canvas contents.
  final PDA? pda;

  /// Identifiers of transitions that participate in nondeterministic choices.
  final Set<String> nondeterministicTransitionIds;

  /// Identifiers of transitions that involve at least one lambda operation.
  final Set<String> lambdaTransitionIds;

  const PDAEditorState({
    this.pda,
    this.nondeterministicTransitionIds = const {},
    this.lambdaTransitionIds = const {},
  });

  PDAEditorState copyWith({
    PDA? pda,
    Set<String>? nondeterministicTransitionIds,
    Set<String>? lambdaTransitionIds,
  }) {
    return PDAEditorState(
      pda: pda ?? this.pda,
      nondeterministicTransitionIds:
          nondeterministicTransitionIds ?? this.nondeterministicTransitionIds,
      lambdaTransitionIds: lambdaTransitionIds ?? this.lambdaTransitionIds,
    );
  }
}

/// Riverpod notifier responsible for maintaining the PDA that is edited by
/// the PDA canvas.
class PDAEditorNotifier extends StateNotifier<PDAEditorState> {
  PDAEditorNotifier() : super(const PDAEditorState());

  /// Updates the notifier using the raw state and transition collections
  /// maintained by the canvas.
  void updateFromCanvas({
    required List<State> states,
    required List<PDATransition> transitions,
  }) {
    if (states.isEmpty) {
      state = const PDAEditorState(pda: null);
      return;
    }

    final stateSet = states.toSet();
    final transitionSet = transitions.toSet();

    final initialState = states.firstWhere(
      (s) => s.isInitial,
      orElse: () => states.first,
    );

    final acceptingStates = states.where((s) => s.isAccepting).toSet();

    final alphabet = <String>{};
    final stackAlphabet = <String>{'Z'};

    for (final transition in transitionSet) {
      if (!transition.isLambdaInput && transition.inputSymbol.isNotEmpty) {
        alphabet.add(transition.inputSymbol);
      }

      if (!transition.isLambdaPop && transition.popSymbol.isNotEmpty) {
        stackAlphabet.add(transition.popSymbol);
      }

      if (!transition.isLambdaPush && transition.pushSymbol.isNotEmpty) {
        stackAlphabet.add(transition.pushSymbol);
      }
    }

    if (stackAlphabet.isEmpty) {
      stackAlphabet.add('Z');
    }

    final now = DateTime.now();

    final pda = PDA(
      id: 'editor-pda',
      name: 'Canvas PDA',
      states: stateSet,
      transitions: transitionSet.map<Transition>((t) => t).toSet(),
      alphabet: alphabet,
      initialState: initialState,
      acceptingStates: acceptingStates.isEmpty ? {states.last} : acceptingStates,
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
      stackAlphabet: stackAlphabet,
      initialStackSymbol: stackAlphabet.first,
      zoomLevel: 1,
      panOffset: Vector2.zero(),
    );

    final nondeterministicTransitionIds = _findNondeterministicTransitions(transitionSet);
    final lambdaTransitionIds = transitionSet
        .where((t) => t.isLambdaInput || t.isLambdaPop || t.isLambdaPush)
        .map((t) => t.id)
        .toSet();

    state = state.copyWith(
      pda: pda,
      nondeterministicTransitionIds: nondeterministicTransitionIds,
      lambdaTransitionIds: lambdaTransitionIds,
    );
  }

  Set<String> _findNondeterministicTransitions(Set<PDATransition> transitions) {
    final grouped = <String, List<PDATransition>>{};

    for (final transition in transitions) {
      final key = [
        transition.fromState.id,
        transition.isLambdaInput ? 'λ' : transition.inputSymbol,
        transition.isLambdaPop ? 'λ' : transition.popSymbol,
      ].join('|');

      grouped.putIfAbsent(key, () => []).add(transition);
    }

    return grouped.values
        .where((list) => list.length > 1)
        .expand((list) => list.map((transition) => transition.id))
        .toSet();
  }
}

/// Provider exposing the current PDA editor state.
final pdaEditorProvider =
    StateNotifierProvider<PDAEditorNotifier, PDAEditorState>(
  (ref) => PDAEditorNotifier(),
);
