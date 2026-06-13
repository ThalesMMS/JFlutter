//
//  automaton_layout_provider.dart
//  JFlutter
//
//  Gerencia operações de layout automático para autômatos, aplicando algoritmos
//  de posicionamento espacial através do LayoutRepository e coordenando com
//  AutomatonStateProvider para atualizar posições de estados após layout.
//
//  Thales Matheus Mendonça Santos - January 2026
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/automaton_repository.dart';
import '../../data/mappers/automaton_entity_mapper.dart';
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
      final automatonEntity = AutomatonEntityMapper.fromFsa(
        currentAutomaton,
        nextId: currentAutomaton.states.length + 1,
      );
      final result = await _layoutRepository.applyAutoLayout(automatonEntity);

      if (result.isSuccess) {
        // Convert back to FSA
        final updatedFsa = AutomatonEntityMapper.toFsa(result.data!);
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
}

/// Provider registration for automaton layout operations
final automatonLayoutProvider =
    StateNotifierProvider<AutomatonLayoutNotifier, LayoutOperationState>(
  (ref) => AutomatonLayoutNotifier(ref, LayoutRepositoryImpl()),
);
