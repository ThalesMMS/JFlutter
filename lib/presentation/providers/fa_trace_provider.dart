import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/fsa.dart';
import '../../core/models/simulation_result.dart';
import '../../data/services/simulation_service.dart';

/// Immutable state holding the latest FA simulation result and flags.
class FATraceState {
  final FSA? automaton;
  final SimulationResult? result;
  final bool isRunning;
  final bool stepByStep;
  final String lastInput;
  final bool forceNfaMode; // explicit choice: false=DFA (default), true=NFA

  const FATraceState({
    this.automaton,
    this.result,
    this.isRunning = false,
    this.stepByStep = false,
    this.lastInput = '',
    this.forceNfaMode = false,
  });

  FATraceState copyWith({
    FSA? automaton,
    SimulationResult? result,
    bool? isRunning,
    bool? stepByStep,
    String? lastInput,
    bool? forceNfaMode,
  }) {
    return FATraceState(
      automaton: automaton ?? this.automaton,
      result: result ?? this.result,
      isRunning: isRunning ?? this.isRunning,
      stepByStep: stepByStep ?? this.stepByStep,
      lastInput: lastInput ?? this.lastInput,
      forceNfaMode: forceNfaMode ?? this.forceNfaMode,
    );
  }
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
    state = state.copyWith(isRunning: true, lastInput: input);

    final request = SimulationRequest.forInput(
      automaton: state.automaton!,
      inputString: input,
      stepByStep: state.stepByStep,
    );

    final result = state.forceNfaMode
        ? _simulationService.simulateNFA(request)
        : _simulationService.simulateDFA(request);

    if (result.isSuccess) {
      state = state.copyWith(result: result.data, isRunning: false);
    } else {
      // Represent failures as a result with error to show in UI panels.
      state = state.copyWith(
        isRunning: false,
        result: SimulationResult.error(
          inputString: input,
          errorMessage: result.error ?? 'Unknown simulation error',
          executionTime: const Duration(milliseconds: 0),
        ),
      );
    }
  }
}

/// Provider exposing FA trace state.
final faTraceProvider =
    StateNotifierProvider<FATraceNotifier, FATraceState>((ref) {
  return FATraceNotifier();
});
