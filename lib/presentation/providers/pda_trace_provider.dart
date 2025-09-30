import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pda.dart';
import '../../core/models/simulation_step.dart';
import '../../core/algorithms/pda/pda_simulator_facade.dart';

/// Immutable state holding the latest PDA simulation result and flags.
class PDATraceState {
  final PDA? pda;
  final PDASimulationResult? result;
  final bool isRunning;
  final bool stepByStep;
  final String lastInput;
  final int currentStepIndex; // for navigation through simulation steps
  final List<PDASimulationResult> traceHistory; // persistent trace history
  final String? errorMessage;

  const PDATraceState({
    this.pda,
    this.result,
    this.isRunning = false,
    this.stepByStep = false,
    this.lastInput = '',
    this.currentStepIndex = 0,
    this.traceHistory = const [],
    this.errorMessage,
  });

  PDATraceState copyWith({
    PDA? pda,
    PDASimulationResult? result,
    bool? isRunning,
    bool? stepByStep,
    String? lastInput,
    int? currentStepIndex,
    List<PDASimulationResult>? traceHistory,
    String? errorMessage,
  }) {
    return PDATraceState(
      pda: pda ?? this.pda,
      result: result ?? this.result,
      isRunning: isRunning ?? this.isRunning,
      stepByStep: stepByStep ?? this.stepByStep,
      lastInput: lastInput ?? this.lastInput,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      traceHistory: traceHistory ?? this.traceHistory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Navigate to a specific step in the current simulation
  PDATraceState navigateToStep(int stepIndex) {
    if (result == null || stepIndex < 0 || stepIndex >= result!.steps.length) {
      return this;
    }
    return copyWith(currentStepIndex: stepIndex);
  }

  /// Navigate to the next step
  PDATraceState nextStep() {
    if (result == null) return this;
    final nextIndex = currentStepIndex + 1;
    if (nextIndex >= result!.steps.length) return this;
    return copyWith(currentStepIndex: nextIndex);
  }

  /// Navigate to the previous step
  PDATraceState previousStep() {
    final prevIndex = currentStepIndex - 1;
    if (prevIndex < 0) return this;
    return copyWith(currentStepIndex: prevIndex);
  }

  /// Navigate to the first step
  PDATraceState firstStep() => copyWith(currentStepIndex: 0);

  /// Navigate to the last step
  PDATraceState lastStep() {
    if (result == null) return this;
    return copyWith(currentStepIndex: result!.steps.length - 1);
  }

  /// Get the current simulation step
  SimulationStep? get currentStep {
    if (result == null || currentStepIndex >= result!.steps.length) return null;
    return result!.steps[currentStepIndex];
  }

  /// Check if we can navigate to the next step
  bool get canNavigateNext => result != null && currentStepIndex < result!.steps.length - 1;

  /// Check if we can navigate to the previous step
  bool get canNavigatePrevious => currentStepIndex > 0;
}

/// Riverpod notifier driving PDA simulations and trace state.
class PDATraceNotifier extends StateNotifier<PDATraceState> {
  PDATraceNotifier() : super(const PDATraceState());

  void setPda(PDA pda) {
    state = state.copyWith(pda: pda);
  }

  void setStepByStep(bool enabled) {
    state = state.copyWith(stepByStep: enabled);
  }

  Future<void> simulate(String input) async {
    if (state.pda == null) return;
    state = state.copyWith(
      isRunning: true, 
      lastInput: input,
      errorMessage: null,
      currentStepIndex: 0,
    );

    final result = PDASimulatorFacade.run(
      state.pda!,
      input,
      stepByStep: state.stepByStep,
    );

    if (result.isSuccess) {
      // Add to trace history and update state
      final newTraceHistory = [...state.traceHistory, result.data!];
      state = state.copyWith(
        result: result.data, 
        isRunning: false,
        traceHistory: newTraceHistory,
        currentStepIndex: 0,
      );
    } else {
      // Represent failures directly in result with minimal wrapper
      final errorResult = PDASimulationResult.failure(
        inputString: input,
        steps: const [],
        errorMessage: result.error ?? 'Unknown simulation error',
        executionTime: const Duration(milliseconds: 0),
      );
      state = state.copyWith(
        isRunning: false,
        result: errorResult,
        errorMessage: result.error ?? 'Unknown simulation error',
        currentStepIndex: 0,
      );
    }
  }

  /// Navigate to a specific step in the current simulation
  void navigateToStep(int stepIndex) {
    state = state.navigateToStep(stepIndex);
  }

  /// Navigate to the next step
  void nextStep() {
    state = state.nextStep();
  }

  /// Navigate to the previous step
  void previousStep() {
    state = state.previousStep();
  }

  /// Navigate to the first step
  void firstStep() {
    state = state.firstStep();
  }

  /// Navigate to the last step
  void lastStep() {
    state = state.lastStep();
  }

  /// Clear the current simulation and reset state
  void clearSimulation() {
    state = state.copyWith(
      result: null,
      currentStepIndex: 0,
      errorMessage: null,
    );
  }

  /// Clear all trace history
  void clearTraceHistory() {
    state = state.copyWith(
      traceHistory: [],
      result: null,
      currentStepIndex: 0,
      errorMessage: null,
    );
  }

  /// Get a specific trace from history
  PDASimulationResult? getTraceFromHistory(int index) {
    if (index < 0 || index >= state.traceHistory.length) return null;
    return state.traceHistory[index];
  }
}

/// Provider exposing PDA trace state.
final pdaTraceProvider = StateNotifierProvider<PDATraceNotifier, PDATraceState>(
  (ref) {
    return PDATraceNotifier();
  },
);
