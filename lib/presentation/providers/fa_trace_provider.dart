/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/providers/fa_trace_provider.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Controla o estado imutável das simulações de autômatos finitos determinísticos e não determinísticos. Centraliza a seleção do autômato ativo, o progresso da execução e os resultados em memória.
/// Contexto: Expõe uma StateNotifier do Riverpod que dispara execuções via SimulationService e atualiza histórico de traços. Fornece operações para alternar modos, executar simulações passo a passo e armazenar falhas de forma apresentável.
/// Observações: Inclui utilitários de navegação entre passos para sincronizar os painéis de visualização. Mantém histórico de execuções para que telas e widgets possam reabrir traços anteriores.
/// ---------------------------------------------------------------------------
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/fsa.dart';
import '../../core/models/simulation_result.dart';
import '../../core/models/simulation_step.dart';
import '../../data/services/simulation_service.dart';

/// Immutable state holding the latest FA simulation result and flags.
class FATraceState {
  final FSA? automaton;
  final SimulationResult? result;
  final bool isRunning;
  final bool stepByStep;
  final String lastInput;
  final bool forceNfaMode; // explicit choice: false=DFA (default), true=NFA
  final int currentStepIndex; // for navigation through simulation steps
  final List<SimulationResult> traceHistory; // persistent trace history
  final String? errorMessage;

  const FATraceState({
    this.automaton,
    this.result,
    this.isRunning = false,
    this.stepByStep = false,
    this.lastInput = '',
    this.forceNfaMode = false,
    this.currentStepIndex = 0,
    this.traceHistory = const [],
    this.errorMessage,
  });

  FATraceState copyWith({
    FSA? automaton,
    SimulationResult? result,
    bool? isRunning,
    bool? stepByStep,
    String? lastInput,
    bool? forceNfaMode,
    int? currentStepIndex,
    List<SimulationResult>? traceHistory,
    String? errorMessage,
  }) {
    return FATraceState(
      automaton: automaton ?? this.automaton,
      result: result ?? this.result,
      isRunning: isRunning ?? this.isRunning,
      stepByStep: stepByStep ?? this.stepByStep,
      lastInput: lastInput ?? this.lastInput,
      forceNfaMode: forceNfaMode ?? this.forceNfaMode,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      traceHistory: traceHistory ?? this.traceHistory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Navigate to a specific step in the current simulation
  FATraceState navigateToStep(int stepIndex) {
    if (result == null || stepIndex < 0 || stepIndex >= result!.steps.length) {
      return this;
    }
    return copyWith(currentStepIndex: stepIndex);
  }

  /// Navigate to the next step
  FATraceState nextStep() {
    if (result == null) return this;
    final nextIndex = currentStepIndex + 1;
    if (nextIndex >= result!.steps.length) return this;
    return copyWith(currentStepIndex: nextIndex);
  }

  /// Navigate to the previous step
  FATraceState previousStep() {
    final prevIndex = currentStepIndex - 1;
    if (prevIndex < 0) return this;
    return copyWith(currentStepIndex: prevIndex);
  }

  /// Navigate to the first step
  FATraceState firstStep() => copyWith(currentStepIndex: 0);

  /// Navigate to the last step
  FATraceState lastStep() {
    if (result == null) return this;
    return copyWith(currentStepIndex: result!.steps.length - 1);
  }

  /// Get the current simulation step
  SimulationStep? get currentStep {
    if (result == null || currentStepIndex >= result!.steps.length) return null;
    return result!.steps[currentStepIndex];
  }

  /// Check if we can navigate to the next step
  bool get canNavigateNext =>
      result != null && currentStepIndex < result!.steps.length - 1;

  /// Check if we can navigate to the previous step
  bool get canNavigatePrevious => currentStepIndex > 0;
}

/// Riverpod notifier driving FA simulations and trace state.
class FATraceNotifier extends StateNotifier<FATraceState> {
  final SimulationService _simulationService;

  FATraceNotifier({SimulationService? simulationService})
    : _simulationService = simulationService ?? SimulationService(),
      super(const FATraceState());

  void setAutomaton(FSA automaton) {
    state = state.copyWith(automaton: automaton);
  }

  void setStepByStep(bool enabled) {
    state = state.copyWith(stepByStep: enabled);
  }

  void setModeNfa(bool enabled) {
    state = state.copyWith(forceNfaMode: enabled);
  }

  Future<void> simulate(String input) async {
    if (state.automaton == null) return;
    state = state.copyWith(
      isRunning: true,
      lastInput: input,
      errorMessage: null,
      currentStepIndex: 0,
    );

    final request = SimulationRequest.forInput(
      automaton: state.automaton!,
      inputString: input,
      stepByStep: state.stepByStep,
    );

    final result = state.forceNfaMode
        ? await _simulationService.simulateNFA(request)
        : await _simulationService.simulateDFA(request);

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
      // Represent failures as a result with error to show in UI panels.
      final errorResult = SimulationResult.error(
        inputString: input,
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
  SimulationResult? getTraceFromHistory(int index) {
    if (index < 0 || index >= state.traceHistory.length) return null;
    return state.traceHistory[index];
  }
}

/// Provider exposing FA trace state.
final faTraceProvider = StateNotifierProvider<FATraceNotifier, FATraceState>((
  ref,
) {
  return FATraceNotifier();
});
