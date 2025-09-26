import '../../models/pda.dart';
import '../../result.dart';
import '../../models/simulation_step.dart';
import '../../models/simulation_result.dart';
import '../pda_simulator.dart';

/// Acceptance mode for PDA: by final state, empty stack, or both.
enum PDAAcceptanceMode { finalState, emptyStack, both }

/// High-level PDA simulator facade supporting different acceptance modes.
class PDASimulatorFacade {
  static Result<PDASimulationResult> run(
    PDA pda,
    String input, {
    PDAAcceptanceMode mode = PDAAcceptanceMode.finalState,
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    // For now, delegate to PDASimulator (final-state acceptance semantics).
    // Future: add empty-stack and both modes by extending PDASimulator.
    return PDASimulator.simulate(
      pda,
      input,
      stepByStep: stepByStep,
      timeout: timeout,
    );
  }
}


