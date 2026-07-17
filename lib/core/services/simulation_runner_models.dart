import '../algorithms/pda_simulator.dart';
import '../algorithms/tm_simulator.dart';
import '../models/pda.dart';
import '../models/tm.dart';

enum SimulationOutcomeKind {
  accepted,
  rejected,
  timeout,
  configurationLimit,
  cancelled,
  failed,
}

class SimulationOutcome<T> {
  const SimulationOutcome({required this.kind, this.result, this.message});

  final SimulationOutcomeKind kind;
  final T? result;
  final String? message;
}

abstract class SimulationTask<T> {
  Future<SimulationOutcome<T>> get outcome;

  void cancel();
}

abstract class SimulationRunnerBackend {
  SimulationTask<PDASimulationResult> runPda(
    PDA pda,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  });

  SimulationTask<TMSimulationResult> runTm(
    TM tm,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  });
}

SimulationOutcome<PDASimulationResult> classifyPdaResult(
  PDASimulationResult result,
) {
  final message = result.errorMessage;
  final kind = result.accepted
      ? SimulationOutcomeKind.accepted
      : message == PDA_SIMULATION_TIMEOUT_ERROR
          ? SimulationOutcomeKind.timeout
          : message == PDA_SIMULATION_LIMIT_REACHED_ERROR ||
                  message == PDA_SIMULATION_INFINITE_LOOP_ERROR
              ? SimulationOutcomeKind.configurationLimit
              : SimulationOutcomeKind.rejected;
  return SimulationOutcome(kind: kind, result: result, message: message);
}

SimulationOutcome<TMSimulationResult> classifyTmResult(
  TMSimulationResult result,
) {
  final message = result.errorMessage;
  final kind = result.accepted
      ? SimulationOutcomeKind.accepted
      : message == 'Simulation timed out'
          ? SimulationOutcomeKind.timeout
          : message == 'Infinite loop detected'
              ? SimulationOutcomeKind.configurationLimit
              : SimulationOutcomeKind.rejected;
  return SimulationOutcome(kind: kind, result: result, message: message);
}
