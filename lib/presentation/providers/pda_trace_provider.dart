import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pda.dart';
import '../../core/algorithms/pda/pda_simulator_facade.dart';
import '../../core/algorithms/pda_simulator.dart';

/// Immutable state holding the latest PDA simulation result and flags.
class PDATraceState {
  final PDA? pda;
  final PDASimulationResult? result;
  final bool isRunning;
  final bool stepByStep;
  final String lastInput;

  const PDATraceState({
    this.pda,
    this.result,
    this.isRunning = false,
    this.stepByStep = false,
    this.lastInput = '',
  });

  PDATraceState copyWith({
    PDA? pda,
    PDASimulationResult? result,
    bool? isRunning,
    bool? stepByStep,
    String? lastInput,
  }) {
    return PDATraceState(
      pda: pda ?? this.pda,
      result: result ?? this.result,
      isRunning: isRunning ?? this.isRunning,
      stepByStep: stepByStep ?? this.stepByStep,
      lastInput: lastInput ?? this.lastInput,
    );
  }
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
    state = state.copyWith(isRunning: true, lastInput: input);

    final result = PDASimulatorFacade.run(
      state.pda!,
      input,
      stepByStep: state.stepByStep,
    );

    if (result.isSuccess) {
      state = state.copyWith(result: result.data, isRunning: false);
    } else {
      // Represent failures directly in result with minimal wrapper
      state = state.copyWith(
        isRunning: false,
        result: PDASimulationResult.failure(
          inputString: input,
          steps: const [],
          errorMessage: result.error ?? 'Unknown simulation error',
          executionTime: const Duration(milliseconds: 0),
        ),
      );
    }
  }
}

/// Provider exposing PDA trace state.
final pdaTraceProvider =
    StateNotifierProvider<PDATraceNotifier, PDATraceState>((ref) {
  return PDATraceNotifier();
});


