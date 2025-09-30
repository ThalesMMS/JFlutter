import '../../models/fsa.dart';
import '../../models/simulation_result.dart';
import '../../result.dart';
import '../automaton_simulator.dart';

/// High-level FA simulator facade building on `AutomatonSimulator`.
class FASimulator {
  /// Run DFA/NFA simulation with optional step-by-step traces.
  static Future<Result<SimulationResult>> run(
    FSA automaton,
    String input, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // Choose NFA simulation when epsilon transitions are present or
    // non-deterministic transitions exist; otherwise use DFA path.
    final isNfa =
        automaton.hasEpsilonTransitions || automaton.isNondeterministic;
    return isNfa
        ? await AutomatonSimulator.simulateNFA(
            automaton,
            input,
            stepByStep: stepByStep,
            timeout: timeout,
          )
        : await AutomatonSimulator.simulate(
            automaton,
            input,
            stepByStep: stepByStep,
            timeout: timeout,
          );
  }

  /// Convenience: returns only boolean acceptance.
  static Future<Result<bool>> accepts(FSA automaton, String input) async {
    final result = await run(automaton, input, stepByStep: false);
    if (!result.isSuccess) return ResultFactory.failure(result.error!);
    return ResultFactory.success(result.data!.accepted);
  }
}
