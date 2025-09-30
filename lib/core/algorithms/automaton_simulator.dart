import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';
import '../result.dart';

/// Simulates Finite Automata (FA) with input strings
class AutomatonSimulator {
  /// Simulates a DFA with an input string (deterministic, no epsilon)
  static Future<Result<SimulationResult>> simulateDFA(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input (generic checks)
      final validationResult = _validateInput(automaton, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Validate DFA constraints
      if (automaton.isNondeterministic || automaton.hasEpsilonTransitions) {
        return const Failure(
          'DFA required: automaton must be deterministic and epsilon-free',
        );
      }

      // Handle empty automaton
      if (automaton.states.isEmpty) {
        return const Failure('Cannot simulate empty automaton');
      }

      // Handle automaton with no initial state
      if (automaton.initialState == null) {
        return const Failure('Automaton must have an initial state');
      }

      // Simulate as DFA
      final result = await _simulateDFA(
        automaton,
        inputString,
        stepByStep,
        timeout,
      );
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error simulating DFA: $e');
    }
  }

  /// Backwards-compatible generic simulate: routes to DFA simulation.
  static Future<Result<SimulationResult>> simulate(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // Route to NFA simulator when nondeterminism or epsilon transitions exist
    if (automaton.isNondeterministic || automaton.hasEpsilonTransitions) {
      return await simulateNFA(
        automaton,
        inputString,
        stepByStep: stepByStep,
        timeout: timeout,
      );
    }
    return await simulateDFA(
      automaton,
      inputString,
      stepByStep: stepByStep,
      timeout: timeout,
    );
  }

  /// Validates the input automaton and string
  static Result<void> _validateInput(
    FSA automaton,
    String inputString, {
    bool strictAlphabet = true,
  }) {
    if (automaton.states.isEmpty) {
      return const Failure('Automaton must have at least one state');
    }

    if (automaton.initialState == null) {
      return const Failure('Automaton must have an initial state');
    }

    if (!automaton.states.contains(automaton.initialState)) {
      return const Failure('Initial state must be in the states set');
    }

    for (final acceptingState in automaton.acceptingStates) {
      if (!automaton.states.contains(acceptingState)) {
        return const Failure('Accepting state must be in the states set');
      }
    }

    // Validate input string symbols
    if (strictAlphabet) {
      for (int i = 0; i < inputString.length; i++) {
        final symbol = inputString[i];
        if (!automaton.alphabet.contains(symbol)) {
          return Failure('Input string contains invalid symbol: $symbol');
        }
      }
    }

    return const Success(null);
  }

  /// Simulates a DFA step-by-step
  static Future<SimulationResult> _simulateDFA(
    FSA automaton,
    String inputString,
    bool stepByStep,
    Duration timeout,
  ) async {
    final steps = <SimulationStep>[];
    final startTime = DateTime.now();

    // Initialize simulation with a single current state
    var currentState = automaton.initialState!;
    int stepNumber = 0;

    // Add initial step
    steps.add(
      SimulationStep.initial(
        initialState: automaton.initialState!.id,
        inputString: inputString,
      ),
    );

    // Process each input symbol with batching for large inputs
    final inputSymbols = inputString.split('');
    var processedCount = 0;

    for (final symbol in inputSymbols) {
      stepNumber++;
      processedCount++;

      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        return SimulationResult.timeout(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

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
      if (steps.length > 10000) {
        return SimulationResult.infiniteLoop(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      // Add step
      if (stepByStep) {
        steps.add(
          SimulationStep.fsa(
            currentState: currentState.id,
            remainingInput: inputSymbols.skip(processedCount).join(''),
            usedTransition: 'δ(${currentState.id}, $symbol) = ${nextState.id}',
            stepNumber: stepNumber,
            consumedInput: symbol,
          ),
        );
      }

      currentState = nextState;

      // Batch processing for large simulations (>1000 steps)
      if (processedCount > 1000 && processedCount % 500 == 0) {
        // Yield to prevent UI blocking
        await Future.delayed(Duration.zero);
      }
    }

    // Check if any current state is accepting
    final isAccepted = automaton.acceptingStates.contains(currentState);

    // Add final step
    steps.add(
      SimulationStep.finalStep(
        finalState: currentState.id,
        remainingInput: '',
        stackContents: '',
        tapeContents: '',
        stepNumber: stepNumber + 1,
      ),
    );

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
  static Future<Result<SimulationResult>> simulateNFA(
    FSA nfa,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      // For NFAs, don't fail early on symbols outside the alphabet; reject via simulation.
      final validationResult = _validateInput(
        nfa,
        inputString,
        strictAlphabet: false,
      );
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty automaton
      if (nfa.states.isEmpty) {
        return const Failure('Cannot simulate empty automaton');
      }

      // Handle automaton with no initial state
      if (nfa.initialState == null) {
        return const Failure('Automaton must have an initial state');
      }

      // Simulate the NFA
      final result = await _simulateNFA(nfa, inputString, stepByStep, timeout);
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error simulating NFA: $e');
    }
  }

  /// Simulates an NFA with epsilon transitions
  static Future<SimulationResult> _simulateNFA(
    FSA nfa,
    String inputString,
    bool stepByStep,
    Duration timeout,
  ) async {
    final steps = <SimulationStep>[];
    final startTime = DateTime.now();

    bool isEpsilonSymbol(String s) {
      final normalized = s.trim().toLowerCase();
      return normalized.isEmpty || normalized == 'ε' || normalized == 'λ' || normalized == 'lambda';
    }

    Set<State> epsilonClosureFlexibleOf(State start) {
      final closure = <State>{start};
      final queue = <State>[start];
      while (queue.isNotEmpty) {
        final state = queue.removeAt(0);
        for (final t in nfa.fsaTransitions) {
          final isFrom = t.fromState == state;
          final isEps = t.isEpsilonTransition || t.inputSymbols.any(isEpsilonSymbol);
          if (isFrom && isEps) {
            if (closure.add(t.toState)) {
              queue.add(t.toState);
            }
          }
        }
      }
      return closure;
    }

    Set<State> epsilonClosureFlexibleOfSet(Set<State> states) {
      final closure = <State>{};
      for (final s in states) {
        closure.addAll(epsilonClosureFlexibleOf(s));
      }
      return closure;
    }

    // Initialize simulation with epsilon closure of initial state
    var currentStates = epsilonClosureFlexibleOf(nfa.initialState!);
    var remainingInput = inputString;
    int stepNumber = 0;

    // Add initial step
    final initialStateId = currentStates.length == 1
        ? currentStates.first.id
        : '{${currentStates.map((s) => s.id).join(',')}}';

    steps.add(
      SimulationStep.initial(
        initialState: initialStateId,
        inputString: inputString,
      ),
    );

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

      // Find next states by symbol, exploring all transitions
      var nextStates = <State>{};
      for (final state in currentStates) {
        final transitions = nfa.getTransitionsFromStateOnSymbol(state, symbol);
        nextStates.addAll(transitions.map((t) => t.toState));
      }

      // Apply epsilon closure to next states (flexible)
      nextStates = epsilonClosureFlexibleOfSet(nextStates);

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

        steps.add(
          SimulationStep.fsa(
            currentState: currentStateId,
            remainingInput: remainingInput,
            usedTransition: symbol,
            stepNumber: stepNumber,
            consumedInput: symbol,
          ),
        );
      }

      currentStates = nextStates;

      // If no next states, early reject
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
    final isAccepted = currentStates
        .intersection(nfa.acceptingStates)
        .isNotEmpty;

    // Add final step
    final finalStateId = currentStates.length == 1
        ? currentStates.first.id
        : '{${currentStates.map((s) => s.id).join(',')}}';

    steps.add(
      SimulationStep.finalStep(
        finalState: finalStateId,
        remainingInput: remainingInput,
        stackContents: '',
        tapeContents: '',
        stepNumber: stepNumber + 1,
      ),
    );

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
  static Future<Result<bool>> accepts(FSA automaton, String inputString) async {
    final simulationResult = await simulate(automaton, inputString);
    if (!simulationResult.isSuccess) {
      return Failure(simulationResult.error!);
    }

    return Success(simulationResult.data!.accepted);
  }

  /// Tests if an automaton rejects a specific string
  static Future<Result<bool>> rejects(FSA automaton, String inputString) async {
    final acceptsResult = await accepts(automaton, inputString);
    if (!acceptsResult.isSuccess) {
      return Failure(acceptsResult.error!);
    }

    return Success(!acceptsResult.data!);
  }

  /// Finds all strings of a given length that the automaton accepts
  static Future<Result<Set<String>>> findAcceptedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  }) async {
    try {
      final acceptedStrings = <String>{};
      final alphabet = automaton.alphabet.toList();

      // Generate all possible strings up to maxLength
      for (
        int length = 0;
        length <= maxLength && acceptedStrings.length < maxResults;
        length++
      ) {
        await _generateStrings(
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
  static Future<void> _generateStrings(
    FSA automaton,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> acceptedStrings,
    int maxResults,
  ) async {
    if (acceptedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final acceptsResult = await accepts(automaton, currentString);
      if (acceptsResult.isSuccess && acceptsResult.data!) {
        acceptedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      await _generateStrings(
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
  static Future<Result<Set<String>>> findRejectedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  }) async {
    try {
      final rejectedStrings = <String>{};
      final alphabet = automaton.alphabet.toList();

      // Generate all possible strings up to maxLength
      for (
        int length = 0;
        length <= maxLength && rejectedStrings.length < maxResults;
        length++
      ) {
        await _generateRejectedStrings(
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
  static Future<void> _generateRejectedStrings(
    FSA automaton,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> rejectedStrings,
    int maxResults,
  ) async {
    if (rejectedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final acceptsResult = await accepts(automaton, currentString);
      if (acceptsResult.isSuccess && !acceptsResult.data!) {
        rejectedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      await _generateRejectedStrings(
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
