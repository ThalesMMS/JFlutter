part of 'pda_simulator.dart';

// ignore_for_file: constant_identifier_names

const String PDA_SIMULATION_TIMEOUT_ERROR = 'Simulation timed out';
const String PDA_SIMULATION_INFINITE_LOOP_ERROR = 'Infinite loop detected';

/// Result of simulating a PDA
class PDASimulationResult {
  final String inputString;
  final bool accepted;
  final List<SimulationStep> steps;
  final String? errorMessage;
  final Duration executionTime;

  PDASimulationResult._({
    required this.inputString,
    required this.accepted,
    required List<SimulationStep> steps,
    this.errorMessage,
    required this.executionTime,
  }) : steps = List.unmodifiable(steps);

  factory PDASimulationResult.success({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: true,
      steps: steps,
      executionTime: executionTime,
    );
  }

  factory PDASimulationResult.failure({
    required String inputString,
    required List<SimulationStep> steps,
    required String errorMessage,
    required Duration executionTime,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }

  factory PDASimulationResult.timeout({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: PDA_SIMULATION_TIMEOUT_ERROR,
      executionTime: executionTime,
    );
  }

  factory PDASimulationResult.infiniteLoop({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: PDA_SIMULATION_INFINITE_LOOP_ERROR,
      executionTime: executionTime,
    );
  }

  PDASimulationResult copyWith({
    String? inputString,
    bool? accepted,
    List<SimulationStep>? steps,
    String? errorMessage,
    Duration? executionTime,
  }) {
    return PDASimulationResult._(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      steps: steps ?? this.steps,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}
