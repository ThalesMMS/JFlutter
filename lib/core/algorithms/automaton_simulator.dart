import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';
import '../result.dart';

/// Simulates Finite Automata (FA) with input strings
class AutomatonSimulator {
  /// Simulates a DFA with an input string (deterministic, no epsilon)
  static Result<SimulationResult> simulateDFA(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input (generic checks)
      final validationResult = _validateInput(automaton, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Validate DFA constraints
      if (automaton.isNondeterministic || automaton.hasEpsilonTransitions) {
        return Failure(
            'DFA required: automaton must be deterministic and epsilon-free');
      }

      // Handle empty automaton
      if (automaton.states.isEmpty) {
        return Failure('Cannot simulate empty automaton');
      }

      // Handle automaton with no initial state
      if (automaton.initialState == null) {
        return Failure('Automaton must have an initial state');
      }

      // Simulate as DFA
      final result = _simulateDFA(automaton, inputString, stepByStep, timeout);
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error simulating DFA: $e');
    }
  }

  /// Backwards-compatible generic simulate: routes to DFA simulation.
  static Result<SimulationResult> simulate(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return simulateDFA(automaton, inputString,
        stepByStep: stepByStep, timeout: timeout);
  }

  /// Validates the input automaton and string
  static Result<void> _validateInput(FSA automaton, String inputString) {
    if (automaton.states.isEmpty) {
      return Failure('Automaton must have at least one state');
    }

    if (automaton.initialState == null) {
      return Failure('Automaton must have an initial state');
    }

    if (!automaton.states.contains(automaton.initialState)) {
      return Failure('Initial state must be in the states set');
    }

    for (final acceptingState in automaton.acceptingStates) {
      if (!automaton.states.contains(acceptingState)) {
        return Failure('Accepting state must be in the states set');
      }
    }

    // Validate input string symbols
    for (int i = 0; i < inputString.length; i++) {
      final symbol = inputString[i];
      if (!automaton.alphabet.contains(symbol)) {
        return Failure('Input string contains invalid symbol: $symbol');
      }
    }

    return Success(null);
  }

  /// Simulates a DFA step-by-step
  static SimulationResult _simulateDFA(
    FSA automaton,
    String inputString,
    bool stepByStep,
    Duration timeout,
  ) {
    final steps = <SimulationStep>[];
    final startTime = DateTime.now();

    // Initialize simulation with a single current state
    var currentState = automaton.initialState!;
    var remainingInput = inputString;
    int stepNumber = 0;

    // Add initial step
    steps.add(SimulationStep.initial(
      initialState: automaton.initialState!.id,
      inputString: inputString,
    ));

    // Process each input symbol
    while (remainingInput.isNotEmpty) {
      stepNumber++;

      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        return SimulationResult.timeout(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      final symbol = remainingInput[0];
      remainingInput = remainingInput.substring(1);

      // Find next state deterministically
      final transitions = automaton
          .getTransitionsFromStateOnSymbol(currentState, symbol)
          .whereType<FSATransition>()
          .toList();
      if (transitions.isEmpty) {
        return SimulationResult.failure(
          inputString: inputString,
          steps: steps,
          errorMessage:
              'No transition from state ${currentState.id} on symbol $symbol',
          executionTime: DateTime.now().difference(startTime),
        );
      }
      final transition = transitions.first;
      final nextState = transition.toState;

      // Check for infinite loop (simplified)
      if (steps.length > 1000) {
        return SimulationResult.infiniteLoop(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      // Add step
      if (stepByStep) {
        steps.add(SimulationStep.fsa(
          currentState: currentState.id,
          remainingInput: remainingInput,
          usedTransition: 'δ(${currentState.id}, $symbol) = ${nextState.id}',
          stepNumber: stepNumber,
          consumedInput: symbol,
        ));
      }

      currentState = nextState;
    }

    // Check if any current state is accepting
    final isAccepted = automaton.acceptingStates.contains(currentState);

    // Add final step
    steps.add(SimulationStep.finalStep(
      finalState: currentState.id,
      remainingInput: remainingInput,
      stackContents: '',
      tapeContents: '',
      stepNumber: stepNumber + 1,
    ));

    if (isAccepted) {
      return SimulationResult.success(
        inputString: inputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
      );
    } else {
      return SimulationResult.failure(
        inputString: inputString,
        steps: steps,
        errorMessage: 'Rejected: no accepting state reached',
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Simulates an NFA with epsilon transitions
  static Result<SimulationResult> simulateNFA(
    FSA nfa,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(nfa, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty automaton
      if (nfa.states.isEmpty) {
        return Failure('Cannot simulate empty automaton');
      }

      // Handle automaton with no initial state
      if (nfa.initialState == null) {
        return Failure('Automaton must have an initial state');
      }

      // Simulate the NFA
      final result = _simulateNFA(nfa, inputString, stepByStep, timeout);
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error simulating NFA: $e');
    }
  }

  /// Simulates an NFA with epsilon transitions
  static SimulationResult _simulateNFA(
    FSA nfa,
    String inputString,
    bool stepByStep,
    Duration timeout,
  ) {
    final steps = <SimulationStep>[];
    final startTime = DateTime.now();

    // Initialize simulation with epsilon closure of initial state
    var currentStates = nfa.getEpsilonClosure(nfa.initialState!);
    var remainingInput = inputString;
    int stepNumber = 0;

    // Add initial step
    final initialStateId = currentStates.length == 1
        ? currentStates.first.id
        : '{${currentStates.map((s) => s.id).join(',')}}';

    steps.add(SimulationStep.initial(
      initialState: initialStateId,
      inputString: inputString,
    ));

    // Process each input symbol
    while (remainingInput.isNotEmpty) {
      stepNumber++;

      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        return SimulationResult.timeout(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      final symbol = remainingInput[0];
      remainingInput = remainingInput.substring(1);

      // Find next states
      var nextStates = <State>{};
      for (final state in currentStates) {
        final transitions = nfa.getTransitionsFromStateOnSymbol(state, symbol);
        for (final transition in transitions) {
          nextStates.add(transition.toState);
        }
      }

      // Apply epsilon closure to next states
      nextStates = nfa.getEpsilonClosureOfSet(nextStates);

      // Check for infinite loop (simplified)
      if (steps.length > 1000) {
        return SimulationResult.infiniteLoop(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      // Add step
      if (stepByStep) {
        final currentStateId = currentStates.length == 1
            ? currentStates.first.id
            : '{${currentStates.map((s) => s.id).join(',')}}';

        steps.add(SimulationStep.fsa(
          currentState: currentStateId,
          remainingInput: remainingInput,
          usedTransition: symbol,
          stepNumber: stepNumber,
          consumedInput: symbol,
        ));
      }

      currentStates = nextStates;

      // If no next states, reject
      if (currentStates.isEmpty) {
        return SimulationResult.failure(
          inputString: inputString,
          steps: steps,
          errorMessage: 'No transition found for symbol $symbol',
          executionTime: DateTime.now().difference(startTime),
        );
      }
    }

    // Check if any current state is accepting
    final isAccepted =
        currentStates.intersection(nfa.acceptingStates).isNotEmpty;

    // Add final step
    final finalStateId = currentStates.length == 1
        ? currentStates.first.id
        : '{${currentStates.map((s) => s.id).join(',')}}';

    steps.add(SimulationStep.finalStep(
      finalState: finalStateId,
      remainingInput: remainingInput,
      stackContents: '',
      tapeContents: '',
      stepNumber: stepNumber + 1,
    ));

    if (isAccepted) {
      return SimulationResult.success(
        inputString: inputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
      );
    } else {
      return SimulationResult.failure(
        inputString: inputString,
        steps: steps,
        errorMessage: 'Input not accepted - no accepting state reached',
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Tests if an automaton accepts a specific string
  static Result<bool> accepts(FSA automaton, String inputString) {
    final simulationResult = simulate(automaton, inputString);
    if (!simulationResult.isSuccess) {
      return Failure(simulationResult.error!);
    }

    return Success(simulationResult.data!.accepted);
  }

  /// Tests if an automaton rejects a specific string
  static Result<bool> rejects(FSA automaton, String inputString) {
    final acceptsResult = accepts(automaton, inputString);
    if (!acceptsResult.isSuccess) {
      return Failure(acceptsResult.error!);
    }

    return Success(!acceptsResult.data!);
  }

  /// Finds all strings of a given length that the automaton accepts
  static Result<Set<String>> findAcceptedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final acceptedStrings = <String>{};
      final alphabet = automaton.alphabet.toList();

      // Generate all possible strings up to maxLength
      for (int length = 0;
          length <= maxLength && acceptedStrings.length < maxResults;
          length++) {
        _generateStrings(
          automaton,
          alphabet,
          '',
          length,
          acceptedStrings,
          maxResults,
        );
      }

      return Success(acceptedStrings);
    } catch (e) {
      return Failure('Error finding accepted strings: $e');
    }
  }

  /// Recursively generates strings and tests them
  static void _generateStrings(
    FSA automaton,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> acceptedStrings,
    int maxResults,
  ) {
    if (acceptedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final acceptsResult = accepts(automaton, currentString);
      if (acceptsResult.isSuccess && acceptsResult.data!) {
        acceptedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      _generateStrings(
        automaton,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        acceptedStrings,
        maxResults,
      );
    }
  }

  /// Finds all strings of a given length that the automaton rejects
  static Result<Set<String>> findRejectedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final rejectedStrings = <String>{};
      final alphabet = automaton.alphabet.toList();

      // Generate all possible strings up to maxLength
      for (int length = 0;
          length <= maxLength && rejectedStrings.length < maxResults;
          length++) {
        _generateRejectedStrings(
          automaton,
          alphabet,
          '',
          length,
          rejectedStrings,
          maxResults,
        );
      }

      return Success(rejectedStrings);
    } catch (e) {
      return Failure('Error finding rejected strings: $e');
    }
  }

  /// Recursively generates strings and tests them for rejection
  static void _generateRejectedStrings(
    FSA automaton,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> rejectedStrings,
    int maxResults,
  ) {
    if (rejectedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final acceptsResult = accepts(automaton, currentString);
      if (acceptsResult.isSuccess && !acceptsResult.data!) {
        rejectedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      _generateRejectedStrings(
        automaton,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        rejectedStrings,
        maxResults,
      );
    }
  }
}
