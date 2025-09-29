import '../../models/pda.dart';
import '../../result.dart';
import '../pda_simulator.dart' as pda;

/// Acceptance mode for PDA: by final state, empty stack, or both.
typedef PDAAcceptanceMode = pda.PDAAcceptanceMode;
typedef PDASimulationResult = pda.PDASimulationResult;

typedef PDASimulationResult = pda.PDASimulationResult;

/// High-level PDA simulator facade supporting different acceptance modes.
class PDASimulatorFacade {
  static Result<PDASimulationResult> run(
    PDA automaton,
    String input, {
    PDAAcceptanceMode mode = PDAAcceptanceMode.finalState,
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    // Route to NPDA engine which supports modes and ε/branching.
    return pda.PDASimulator.simulateNPDA(
      automaton,
      input,
      stepByStep: stepByStep,
      timeout: timeout,
      mode: mode,
    );
  }
}
