//
//  automaton_layout_provider.dart
//  JFlutter
//
//  Gerencia operações de layout automático para autômatos, aplicando algoritmos
//  de posicionamento espacial através do LayoutRepository e coordenando com
//  AutomatonStateProvider para atualizar posições de estados após layout.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../core/entities/automaton_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/state.dart';
import '../../core/repositories/automaton_repository.dart';
import '../../features/layout/layout_repository_impl.dart';
import 'automaton_state_provider.dart';

/// State for layout operations
class LayoutOperationState {
  final bool isLoading;
  final String? error;

  const LayoutOperationState({this.isLoading = false, this.error});

  static const _unset = Object();

  LayoutOperationState copyWith({bool? isLoading, Object? error = _unset}) {
    return LayoutOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
    );
  }

  /// Clear all state and reset to initial
  LayoutOperationState clear() {
    return const LayoutOperationState();
  }

  /// Clear only error state
  LayoutOperationState clearError() {
    return copyWith(error: null);
  }
}

/// Provider for automaton layout operations
class AutomatonLayoutNotifier extends StateNotifier<LayoutOperationState> {
  final Ref ref;
  final LayoutRepository _layoutRepository;

  AutomatonLayoutNotifier(this.ref, this._layoutRepository)
    : super(const LayoutOperationState()) {
    // Listen to automaton state changes and clear errors when automaton changes
    ref.listen<AutomatonStateProviderState>(automatonStateProvider, (
      previous,
      next,
    ) {
      // Clear layout errors when the automaton changes
      if (previous?.currentAutomaton?.id != next.currentAutomaton?.id) {
        state = state.clearError();
      }
    });
  }

  /// Applies auto layout to the current automaton
  Future<void> applyAutoLayout() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Convert FSA to AutomatonEntity for layout repository
      final automatonEntity = _convertFsaToEntity(currentAutomaton);
      final result = await _layoutRepository.applyAutoLayout(automatonEntity);

      if (result.isSuccess) {
        // Convert back to FSA
        final updatedFsa = _convertEntityToFsa(result.data!);
        // Update the automaton in the state provider
        ref.read(automatonStateProvider.notifier).updateAutomaton(updatedFsa);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error applying auto layout: $e',
      );
    }
  }

  /// Clears any error messages
  void clearError() {
    state = state.clearError();
  }

  /// Converts FSA to AutomatonEntity
  AutomatonEntity _convertFsaToEntity(FSA fsa) {
    final states = fsa.states
        .map(
          (s) => StateEntity(
            id: s.id,
            name: s.label,
            x: s.position.x,
            y: s.position.y,
            isInitial: s.isInitial,
            isFinal: s.isAccepting,
          ),
        )
        .toList();

    // Build transitions map from FSA transitions
    final transitions = <String, List<String>>{};
    for (final transition in fsa.transitions) {
      if (transition is FSATransition) {
        for (final symbol in transition.inputSymbols) {
          final key = '${transition.fromState.id}|$symbol';
          if (!transitions.containsKey(key)) {
            transitions[key] = [];
          }
          transitions[key]!.add(transition.toState.id);
        }
      }
    }

    return AutomatonEntity(
      id: fsa.id,
      name: fsa.name,
      alphabet: fsa.alphabet,
      states: states,
      transitions: transitions,
      initialId: fsa.initialState?.id,
      nextId: states.length + 1,
      type: AutomatonType.dfa, // Default to DFA
    );
  }

  /// Converts AutomatonEntity to FSA
  FSA _convertEntityToFsa(AutomatonEntity entity) {
    final states = entity.states
        .map(
          (s) => State(
            id: s.id,
            label: s.name,
            position: Vector2(s.x, s.y),
            isInitial: s.isInitial,
            isAccepting: s.isFinal,
          ),
        )
        .toSet();

    final initialState = states.where((s) => s.isInitial).firstOrNull;
    final acceptingStates = states.where((s) => s.isAccepting).toSet();

    // Build FSA transitions from transitions map
    final transitions = <FSATransition>{};
    int transitionId = 1;

    for (final entry in entity.transitions.entries) {
      final parts = entry.key.split('|');
      if (parts.length == 2) {
        final fromStateId = parts[0];
        final symbol = parts[1];
        final fromState = states.firstWhere((s) => s.id == fromStateId);

        for (final toStateId in entry.value) {
          final toState = states.firstWhere((s) => s.id == toStateId);
          transitions.add(
            FSATransition(
              id: 't${transitionId++}',
              fromState: fromState,
              toState: toState,
              label: symbol,
              inputSymbols: {symbol},
            ),
          );
        }
      }
    }

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
      bounds: const Rectangle(0, 0, 800, 600),
    );
  }
}

/// Provider registration for automaton layout operations
final automatonLayoutProvider =
    StateNotifierProvider<AutomatonLayoutNotifier, LayoutOperationState>(
      (ref) => AutomatonLayoutNotifier(ref, LayoutRepositoryImpl()),
    );
