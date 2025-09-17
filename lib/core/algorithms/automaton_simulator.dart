import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';
import '../result.dart';

/// Simulates Finite Automata (FA) with input strings
class AutomatonSimulator {
  /// Simulates an automaton with an input string
  static Result<SimulationResult> simulate(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(automaton, inputString);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }

      // Handle empty automaton
      if (automaton.states.isEmpty) {
        return Result.failure('Cannot simulate empty automaton');
      }

      // Handle automaton with no initial state
      if (automaton.initialState == null) {
        return Result.failure('Automaton must have an initial state');
      }

      // Simulate the automaton
      final result = _simulateAutomaton(automaton, inputString, stepByStep, timeout);
      stopwatch.stop();
      
      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);
      
      return Result.success(finalResult);
    } catch (e) {
      return Result.failure('Error simulating automaton: $e');
    }
  }

  /// Validates the input automaton and string
  static Result<void> _validateInput(FSA automaton, String inputString) {
    if (automaton.states.isEmpty) {
      return Result.failure('Automaton must have at least one state');
    }
    
    if (automaton.initialState == null) {
      return Result.failure('Automaton must have an initial state');
    }
    
    if (!automaton.states.contains(automaton.initialState)) {
      return Result.failure('Initial state must be in the states set');
    }
    
    for (final acceptingState in automaton.acceptingStates) {
      if (!automaton.states.contains(acceptingState)) {
        return Result.failure('Accepting state must be in the states set');
      }
    }
    
    // Validate input string symbols
    for (int i = 0; i < inputString.length; i++) {
      final symbol = inputString[i];
      if (!automaton.alphabet.contains(symbol)) {
        return Result.failure('Input string contains invalid symbol: $symbol');
      }
    }
    
    return Result.success(null);
  }

  /// Simulates the automaton with the input string
  static SimulationResult _simulateAutomaton(
    FSA automaton,
    String inputString,
    bool stepByStep,
    Duration timeout,
  ) {
    final steps = <SimulationStep>[];
    final startTime = DateTime.now();
    
    // Initialize simulation
    var currentStates = {automaton.initialState!};
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
      
      // Find next states
      final nextStates = <State>{};
      for (final state in currentStates) {
        final transitions = automaton.getTransitionsFromStateOnSymbol(state, symbol);
        for (final transition in transitions) {
          nextStates.add(transition.toState);
        }
      }
      
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
    final isAccepted = currentStates.intersection(automaton.acceptingStates).isNotEmpty;
    
    // Add final step
    final finalStateId = currentStates.length == 1 
        ? currentStates.first.id 
        : '{${currentStates.map((s) => s.id).join(',')}}';
    
    steps.add(SimulationStep.final(
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
        return Result.failure(validationResult.error!);
      }

      // Handle empty automaton
      if (nfa.states.isEmpty) {
        return Result.failure('Cannot simulate empty automaton');
      }

      // Handle automaton with no initial state
      if (nfa.initialState == null) {
        return Result.failure('Automaton must have an initial state');
      }

      // Simulate the NFA
      final result = _simulateNFA(nfa, inputString, stepByStep, timeout);
      stopwatch.stop();
      
      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);
      
      return Result.success(finalResult);
    } catch (e) {
      return Result.failure('Error simulating NFA: $e');
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
    final isAccepted = currentStates.intersection(nfa.acceptingStates).isNotEmpty;
    
    // Add final step
    final finalStateId = currentStates.length == 1 
        ? currentStates.first.id 
        : '{${currentStates.map((s) => s.id).join(',')}}';
    
    steps.add(SimulationStep.final(
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
      return Result.failure(simulationResult.error!);
    }
    
    return Result.success(simulationResult.data!.accepted);
  }

  /// Tests if an automaton rejects a specific string
  static Result<bool> rejects(FSA automaton, String inputString) {
    final acceptsResult = accepts(automaton, inputString);
    if (!acceptsResult.isSuccess) {
      return Result.failure(acceptsResult.error!);
    }
    
    return Result.success(!acceptsResult.data!);
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
      for (int length = 0; length <= maxLength && acceptedStrings.length < maxResults; length++) {
        _generateStrings(
          automaton,
          alphabet,
          '',
          length,
          acceptedStrings,
          maxResults,
        );
      }
      
      return Result.success(acceptedStrings);
    } catch (e) {
      return Result.failure('Error finding accepted strings: $e');
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
      for (int length = 0; length <= maxLength && rejectedStrings.length < maxResults; length++) {
        _generateRejectedStrings(
          automaton,
          alphabet,
          '',
          length,
          rejectedStrings,
          maxResults,
        );
      }
      
      return Result.success(rejectedStrings);
    } catch (e) {
      return Result.failure('Error finding rejected strings: $e');
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
