//
//  algorithm_step_provider.dart
//  JFlutter
//
//  Gerencia o estado de navegação passo a passo durante a execução de
//  algoritmos educacionais, permitindo ao usuário avançar, retroceder e
//  pausar para compreender cada etapa da conversão de autômatos.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a single step in an algorithm execution
class AlgorithmStep {
  final String id;
  final String title;
  final String explanation;
  final Map<String, dynamic>? metadata;

  const AlgorithmStep({
    required this.id,
    required this.title,
    required this.explanation,
    this.metadata,
  });

  AlgorithmStep copyWith({
    String? id,
    String? title,
    String? explanation,
    Map<String, dynamic>? metadata,
  }) {
    return AlgorithmStep(
      id: id ?? this.id,
      title: title ?? this.title,
      explanation: explanation ?? this.explanation,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// State for algorithm step navigation
class AlgorithmStepState {
  final List<AlgorithmStep> steps;
  final int currentStepIndex;
  final bool isPlaying;
  final bool isLoading;
  final String? error;

  const AlgorithmStepState({
    this.steps = const [],
    this.currentStepIndex = 0,
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
  });

  static const _unset = Object();

  AlgorithmStepState copyWith({
    List<AlgorithmStep>? steps,
    int? currentStepIndex,
    bool? isPlaying,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return AlgorithmStepState(
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
    );
  }

  /// Clear all steps and reset to initial state
  AlgorithmStepState clear() {
    return const AlgorithmStepState();
  }

  /// Clear only error state
  AlgorithmStepState clearError() {
    return copyWith(error: null);
  }

  /// Get the current step, if any
  AlgorithmStep? get currentStep {
    if (currentStepIndex >= 0 && currentStepIndex < steps.length) {
      return steps[currentStepIndex];
    }
    return null;
  }

  /// Check if there is a next step
  bool get hasNextStep => currentStepIndex < steps.length - 1;

  /// Check if there is a previous step
  bool get hasPreviousStep => currentStepIndex > 0;

  /// Check if at the first step
  bool get isAtFirstStep => currentStepIndex == 0;

  /// Check if at the last step
  bool get isAtLastStep => currentStepIndex == steps.length - 1;

  /// Check if there are any steps
  bool get hasSteps => steps.isNotEmpty;

  /// Get total number of steps
  int get totalSteps => steps.length;

  /// Get current step number (1-indexed for display)
  int get currentStepNumber => currentStepIndex + 1;
}

/// Provider for algorithm step navigation
class AlgorithmStepNotifier extends StateNotifier<AlgorithmStepState> {
  final Ref ref;

  AlgorithmStepNotifier(this.ref) : super(const AlgorithmStepState());

  /// Initialize steps for an algorithm execution
  void initializeSteps(List<AlgorithmStep> steps) {
    if (steps.isEmpty) {
      state = state.copyWith(error: 'Cannot initialize with empty steps list');
      return;
    }

    state = state.copyWith(
      steps: steps,
      currentStepIndex: 0,
      isPlaying: false,
      error: null,
    );
  }

  /// Navigate to the next step
  void nextStep() {
    if (!state.hasNextStep) return;

    state = state.copyWith(
      currentStepIndex: state.currentStepIndex + 1,
      error: null,
    );
  }

  /// Navigate to the previous step
  void previousStep() {
    if (!state.hasPreviousStep) return;

    state = state.copyWith(
      currentStepIndex: state.currentStepIndex - 1,
      error: null,
    );
  }

  /// Jump to a specific step by index
  void jumpToStep(int index) {
    if (index < 0 || index >= state.steps.length) {
      state = state.copyWith(error: 'Invalid step index: $index');
      return;
    }

    state = state.copyWith(currentStepIndex: index, error: null);
  }

  /// Jump to the first step
  void jumpToFirstStep() {
    if (!state.hasSteps) return;

    state = state.copyWith(currentStepIndex: 0, error: null);
  }

  /// Jump to the last step
  void jumpToLastStep() {
    if (!state.hasSteps) return;

    state = state.copyWith(
      currentStepIndex: state.steps.length - 1,
      error: null,
    );
  }

  /// Start auto-playing through steps
  void play() {
    if (!state.hasSteps) return;

    state = state.copyWith(isPlaying: true, error: null);
  }

  /// Pause auto-playing
  void pause() {
    state = state.copyWith(isPlaying: false, error: null);
  }

  /// Toggle play/pause
  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  /// Reset to initial state
  void reset() {
    state = state.copyWith(currentStepIndex: 0, isPlaying: false, error: null);
  }

  /// Clear all steps and reset
  void clearSteps() {
    state = state.clear();
  }

  /// Clear only error state
  void clearError() {
    state = state.clearError();
  }
}

/// Provider registration for algorithm step navigation
final algorithmStepProvider =
    StateNotifierProvider<AlgorithmStepNotifier, AlgorithmStepState>(
      (ref) => AlgorithmStepNotifier(ref),
    );
