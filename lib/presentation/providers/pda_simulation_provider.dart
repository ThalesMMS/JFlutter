import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pda.dart';
import '../../core/algorithms/pda/pda_simulator_facade.dart';
import '../../core/algorithms/pda_simulator.dart';

class PDASimulationState {
  final PDA? pda;
  final PDASimulationResult? result;
  final bool isRunning;
  final bool stepByStep;
  final PDAAcceptanceMode mode;
  final String lastInput;

  const PDASimulationState({
    this.pda,
    this.result,
    this.isRunning = false,
    this.stepByStep = false,
    this.mode = PDAAcceptanceMode.finalState,
    this.lastInput = '',
  });

  PDASimulationState copyWith({
    PDA? pda,
    PDASimulationResult? result,
    bool? isRunning,
    bool? stepByStep,
    PDAAcceptanceMode? mode,
    String? lastInput,
  }) {
    return PDASimulationState(
      pda: pda ?? this.pda,
      result: result ?? this.result,
      isRunning: isRunning ?? this.isRunning,
      stepByStep: stepByStep ?? this.stepByStep,
      mode: mode ?? this.mode,
      lastInput: lastInput ?? this.lastInput,
    );
  }
}

class PDASimulationNotifier extends StateNotifier<PDASimulationState> {
  PDASimulationNotifier() : super(const PDASimulationState());

  void setPda(PDA pda) {
    state = state.copyWith(pda: pda);
  }

  void setStepByStep(bool enabled) {
    state = state.copyWith(stepByStep: enabled);
  }

  void setAcceptanceMode(PDAAcceptanceMode mode) {
    state = state.copyWith(mode: mode);
  }

  Future<void> simulate(String input) async {
    if (state.pda == null) return;
    state = state.copyWith(isRunning: true, lastInput: input);

    final result = PDASimulatorFacade.run(
      state.pda!,
      input,
      mode: state.mode,
      stepByStep: state.stepByStep,
    );

    if (result.isSuccess) {
      state = state.copyWith(result: result.data, isRunning: false);
    } else {
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

final pdaSimulationProvider =
    StateNotifierProvider<PDASimulationNotifier, PDASimulationState>((ref) {
  return PDASimulationNotifier();
});


