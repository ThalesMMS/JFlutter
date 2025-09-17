import '../../core/models/fsa.dart';
import '../../core/models/simulation_result.dart';
import '../../core/result.dart';
import '../../core/algorithms/automaton_simulator.dart';

/// Service for automaton simulation operations
class SimulationService {
  /// Simulates an automaton with an input string
  Result<SimulationResult> simulate(SimulationRequest request) {
    try {
      // Validate request
      if (request.automaton == null) {
        return ResultFactory.failure('Automaton is required');
      }

      if (request.inputString == null) {
        return ResultFactory.failure('Input string is required');
      }

      // Use the automaton simulator
      final result = AutomatonSimulator.simulate(
        request.automaton!,
        request.inputString!,
        stepByStep: request.stepByStep ?? false,
        timeout: request.timeout ?? const Duration(seconds: 5),
      );

      return result;
    } catch (e) {
      return ResultFactory.failure('Error simulating automaton: $e');
    }
  }

  /// Simulates an NFA with epsilon transitions
  Result<SimulationResult> simulateNFA(SimulationRequest request) {
    try {
      // Validate request
      if (request.automaton == null) {
        return ResultFactory.failure('Automaton is required');
      }

      if (request.inputString == null) {
        return ResultFactory.failure('Input string is required');
      }

      // Use the NFA simulator
      final result = AutomatonSimulator.simulateNFA(
        request.automaton!,
        request.inputString!,
        stepByStep: request.stepByStep ?? false,
        timeout: request.timeout ?? const Duration(seconds: 5),
      );

      return result;
    } catch (e) {
      return ResultFactory.failure('Error simulating NFA: $e');
    }
  }

  /// Tests if an automaton accepts a string
  Result<bool> accepts(SimulationRequest request) {
    try {
      // Validate request
      if (request.automaton == null) {
        return ResultFactory.failure('Automaton is required');
      }

      if (request.inputString == null) {
        return ResultFactory.failure('Input string is required');
      }

      // Use the automaton simulator
      final result = AutomatonSimulator.accepts(
        request.automaton!,
        request.inputString!,
      );

      return result;
    } catch (e) {
      return ResultFactory.failure('Error testing acceptance: $e');
    }
  }

  /// Tests if an automaton rejects a string
  Result<bool> rejects(SimulationRequest request) {
    try {
      // Validate request
      if (request.automaton == null) {
        return ResultFactory.failure('Automaton is required');
      }

      if (request.inputString == null) {
        return ResultFactory.failure('Input string is required');
      }

      // Use the automaton simulator
      final result = AutomatonSimulator.rejects(
        request.automaton!,
        request.inputString!,
      );

      return result;
    } catch (e) {
      return ResultFactory.failure('Error testing rejection: $e');
    }
  }

  /// Finds accepted strings
  Result<Set<String>> findAcceptedStrings(SimulationRequest request) {
    try {
      // Validate request
      if (request.automaton == null) {
        return ResultFactory.failure('Automaton is required');
      }

      // Use the automaton simulator
      final result = AutomatonSimulator.findAcceptedStrings(
        request.automaton!,
        request.maxLength ?? 10,
        maxResults: request.maxResults ?? 100,
      );

      return result;
    } catch (e) {
      return ResultFactory.failure('Error finding accepted strings: $e');
    }
  }

  /// Finds rejected strings
  Result<Set<String>> findRejectedStrings(SimulationRequest request) {
    try {
      // Validate request
      if (request.automaton == null) {
        return ResultFactory.failure('Automaton is required');
      }

      // Use the automaton simulator
      final result = AutomatonSimulator.findRejectedStrings(
        request.automaton!,
        request.maxLength ?? 10,
        maxResults: request.maxResults ?? 100,
      );

      return result;
    } catch (e) {
      return ResultFactory.failure('Error finding rejected strings: $e');
    }
  }
}

/// Request for simulation operations
class SimulationRequest {
  final FSA? automaton;
  final String? inputString;
  final bool? stepByStep;
  final Duration? timeout;
  final int? maxLength;
  final int? maxResults;

  const SimulationRequest({
    this.automaton,
    this.inputString,
    this.stepByStep,
    this.timeout,
    this.maxLength,
    this.maxResults,
  });

  /// Creates a simulation request for a specific input string
  factory SimulationRequest.forInput({
    required FSA automaton,
    required String inputString,
    bool stepByStep = false,
    Duration? timeout,
  }) {
    return SimulationRequest(
      automaton: automaton,
      inputString: inputString,
      stepByStep: stepByStep,
      timeout: timeout,
    );
  }

  /// Creates a simulation request for finding strings
  factory SimulationRequest.forFinding({
    required FSA automaton,
    int maxLength = 10,
    int maxResults = 100,
  }) {
    return SimulationRequest(
      automaton: automaton,
      maxLength: maxLength,
      maxResults: maxResults,
    );
  }
}
