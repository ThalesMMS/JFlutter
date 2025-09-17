import '../models/tm.dart';
import '../models/state.dart';
import '../models/tm_transition.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';
import '../result.dart';

/// Simulates Turing Machines (TM) with input strings
class TMSimulator {
  /// Simulates a TM with an input string
  static Result<TMSimulationResult> simulate(
    TM tm,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(tm, inputString);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }

      // Handle empty TM
      if (tm.states.isEmpty) {
        return Result.failure('Cannot simulate empty Turing machine');
      }

      // Handle TM with no initial state
      if (tm.initialState == null) {
        return Result.failure('Turing machine must have an initial state');
      }

      // Simulate the TM
      final result = _simulateTM(tm, inputString, stepByStep, timeout);
      stopwatch.stop();
      
      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);
      
      return Result.success(finalResult);
    } catch (e) {
      return Result.failure('Error simulating Turing machine: $e');
    }
  }

  /// Validates the input TM and string
  static Result<void> _validateInput(TM tm, String inputString) {
    if (tm.states.isEmpty) {
      return Result.failure('Turing machine must have at least one state');
    }
    
    if (tm.initialState == null) {
      return Result.failure('Turing machine must have an initial state');
    }
    
    if (!tm.states.contains(tm.initialState)) {
      return Result.failure('Initial state must be in the states set');
    }
    
    for (final acceptingState in tm.acceptingStates) {
      if (!tm.states.contains(acceptingState)) {
        return Result.failure('Accepting state must be in the states set');
      }
    }
    
    // Validate input string symbols
    for (int i = 0; i < inputString.length; i++) {
      final symbol = inputString[i];
      if (!tm.alphabet.contains(symbol)) {
        return Result.failure('Input string contains invalid symbol: $symbol');
      }
    }
    
    return Result.success(null);
  }

  /// Simulates the TM with the input string
  static TMSimulationResult _simulateTM(
    TM tm,
    String inputString,
    bool stepByStep,
    Duration timeout,
  ) {
    final steps = <SimulationStep>[];
    final startTime = DateTime.now();
    
    // Initialize simulation
    var currentState = tm.initialState!;
    var tape = inputString.split('').toList();
    var headPosition = 0;
    int stepNumber = 0;
    
    // Add initial step
    steps.add(SimulationStep.initial(
      initialState: currentState.id,
      inputString: inputString,
    ));
    
    // Process until halting
    while (true) {
      stepNumber++;
      
      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        return TMSimulationResult.timeout(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }
      
      // Check for infinite loop (simplified)
      if (steps.length > 1000) {
        return TMSimulationResult.infiniteLoop(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }
      
      // Get current tape symbol
      final currentSymbol = headPosition < tape.length ? tape[headPosition] : tm.blankSymbol;
      
      // Find transition
      final transition = tm.getTMTransitionFromStateOnSymbol(currentState, currentSymbol);
      if (transition == null) {
        // No transition found, halt
        break;
      }
      
      // Write to tape
      if (headPosition < tape.length) {
        tape[headPosition] = transition.writeSymbol;
      } else {
        tape.add(transition.writeSymbol);
      }
      
      // Move head
      switch (transition.moveDirection) {
        case 'L':
          headPosition--;
          if (headPosition < 0) {
            headPosition = 0;
            tape.insert(0, tm.blankSymbol);
          }
          break;
        case 'R':
          headPosition++;
          if (headPosition >= tape.length) {
            tape.add(tm.blankSymbol);
          }
          break;
        case 'S':
          // Stay
          break;
        default:
          return TMSimulationResult.failure(
            inputString: inputString,
            steps: steps,
            errorMessage: 'Invalid move direction: ${transition.moveDirection}',
            executionTime: DateTime.now().difference(startTime),
          );
      }
      
      // Add step
      if (stepByStep) {
        steps.add(SimulationStep.tm(
          currentState: currentState.id,
          tapeContents: tape.join(''),
          headPosition: headPosition,
          usedTransition: currentSymbol,
          stepNumber: stepNumber,
        ));
      }
      
      // Move to next state
      currentState = transition.toState;
      
      // Check if we're in an accepting state
      if (tm.acceptingStates.contains(currentState)) {
        break;
      }
    }
    
    // Add final step
    steps.add(SimulationStep.final(
      finalState: currentState.id,
      remainingInput: '',
      stackContents: '',
      tapeContents: tape.join(''),
      stepNumber: stepNumber + 1,
    ));
    
    // Check if final state is accepting
    final isAccepted = tm.acceptingStates.contains(currentState);
    
    if (isAccepted) {
      return TMSimulationResult.success(
        inputString: inputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
      );
    } else {
      return TMSimulationResult.failure(
        inputString: inputString,
        steps: steps,
        errorMessage: 'Input not accepted - final state is not accepting',
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Tests if a TM accepts a specific string
  static Result<bool> accepts(TM tm, String inputString) {
    final simulationResult = simulate(tm, inputString);
    if (!simulationResult.isSuccess) {
      return Result.failure(simulationResult.error!);
    }
    
    return Result.success(simulationResult.data!.accepted);
  }

  /// Tests if a TM rejects a specific string
  static Result<bool> rejects(TM tm, String inputString) {
    final acceptsResult = accepts(tm, inputString);
    if (!acceptsResult.isSuccess) {
      return Result.failure(acceptsResult.error!);
    }
    
    return Result.success(!acceptsResult.data!);
  }

  /// Finds all strings of a given length that the TM accepts
  static Result<Set<String>> findAcceptedStrings(
    TM tm,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final acceptedStrings = <String>{};
      final alphabet = tm.alphabet.toList();
      
      // Generate all possible strings up to maxLength
      for (int length = 0; length <= maxLength && acceptedStrings.length < maxResults; length++) {
        _generateStrings(
          tm,
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
    TM tm,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> acceptedStrings,
    int maxResults,
  ) {
    if (acceptedStrings.length >= maxResults) return;
    
    if (remainingLength == 0) {
      final acceptsResult = accepts(tm, currentString);
      if (acceptsResult.isSuccess && acceptsResult.data!) {
        acceptedStrings.add(currentString);
      }
      return;
    }
    
    for (final symbol in alphabet) {
      _generateStrings(
        tm,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        acceptedStrings,
        maxResults,
      );
    }
  }

  /// Finds all strings of a given length that the TM rejects
  static Result<Set<String>> findRejectedStrings(
    TM tm,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final rejectedStrings = <String>{};
      final alphabet = tm.alphabet.toList();
      
      // Generate all possible strings up to maxLength
      for (int length = 0; length <= maxLength && rejectedStrings.length < maxResults; length++) {
        _generateRejectedStrings(
          tm,
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
    TM tm,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> rejectedStrings,
    int maxResults,
  ) {
    if (rejectedStrings.length >= maxResults) return;
    
    if (remainingLength == 0) {
      final acceptsResult = accepts(tm, currentString);
      if (acceptsResult.isSuccess && !acceptsResult.data!) {
        rejectedStrings.add(currentString);
      }
      return;
    }
    
    for (final symbol in alphabet) {
      _generateRejectedStrings(
        tm,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        rejectedStrings,
        maxResults,
      );
    }
  }

  /// Analyzes the behavior of a TM
  static Result<TMAnalysis> analyzeTM(
    TM tm, {
    int maxInputLength = 10,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(tm, '');
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }

      // Handle empty TM
      if (tm.states.isEmpty) {
        return Result.failure('Cannot analyze empty Turing machine');
      }

      // Handle TM with no initial state
      if (tm.initialState == null) {
        return Result.failure('Turing machine must have an initial state');
      }

      // Analyze the TM
      final result = _analyzeTM(tm, maxInputLength, timeout);
      stopwatch.stop();
      
      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);
      
      return Result.success(finalResult);
    } catch (e) {
      return Result.failure('Error analyzing Turing machine: $e');
    }
  }

  /// Analyzes the TM
  static TMAnalysis _analyzeTM(
    TM tm,
    int maxInputLength,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // Analyze states
    final stateAnalysis = _analyzeStates(tm);
    
    // Analyze transitions
    final transitionAnalysis = _analyzeTransitions(tm);
    
    // Analyze tape operations
    final tapeAnalysis = _analyzeTapeOperations(tm);
    
    // Analyze reachability
    final reachabilityAnalysis = _analyzeReachability(tm);
    
    return TMAnalysis(
      stateAnalysis: stateAnalysis,
      transitionAnalysis: transitionAnalysis,
      tapeAnalysis: tapeAnalysis,
      reachabilityAnalysis: reachabilityAnalysis,
      executionTime: DateTime.now().difference(startTime),
    );
  }

  /// Analyzes the states of the TM
  static StateAnalysis _analyzeStates(TM tm) {
    final totalStates = tm.states.length;
    final acceptingStates = tm.acceptingStates.length;
    final nonAcceptingStates = totalStates - acceptingStates;
    
    return StateAnalysis(
      totalStates: totalStates,
      acceptingStates: acceptingStates,
      nonAcceptingStates: nonAcceptingStates,
    );
  }

  /// Analyzes the transitions of the TM
  static TransitionAnalysis _analyzeTransitions(TM tm) {
    final totalTransitions = tm.transitions.length;
    final tmTransitions = tm.transitions.whereType<TMTransition>().length;
    final fsaTransitions = tm.transitions.whereType<FSATransition>().length;
    
    return TransitionAnalysis(
      totalTransitions: totalTransitions,
      tmTransitions: tmTransitions,
      fsaTransitions: fsaTransitions,
    );
  }

  /// Analyzes the tape operations of the TM
  static TapeAnalysis _analyzeTapeOperations(TM tm) {
    final writeOperations = <String>{};
    final readOperations = <String>{};
    final moveDirections = <String>{};
    final tapeSymbols = <String>{};
    
    for (final transition in tm.transitions) {
      if (transition is TMTransition) {
        writeOperations.add(transition.writeSymbol);
        readOperations.add(transition.readSymbol);
        moveDirections.add(transition.moveDirection);
        tapeSymbols.add(transition.readSymbol);
        tapeSymbols.add(transition.writeSymbol);
      }
    }
    
    return TapeAnalysis(
      writeOperations: writeOperations,
      readOperations: readOperations,
      moveDirections: moveDirections,
      tapeSymbols: tapeSymbols,
    );
  }

  /// Analyzes the reachability of the TM
  static ReachabilityAnalysis _analyzeReachability(TM tm) {
    final reachableStates = <State>{};
    final unreachableStates = <State>{};
    
    // Find reachable states from initial state
    if (tm.initialState != null) {
      _findReachableStates(tm, tm.initialState!, reachableStates);
    }
    
    // Find unreachable states
    for (final state in tm.states) {
      if (!reachableStates.contains(state)) {
        unreachableStates.add(state);
      }
    }
    
    return ReachabilityAnalysis(
      reachableStates: reachableStates,
      unreachableStates: unreachableStates,
    );
  }

  /// Recursively finds reachable states
  static void _findReachableStates(
    TM tm,
    State currentState,
    Set<State> reachableStates,
  ) {
    if (reachableStates.contains(currentState)) {
      return; // Already visited
    }
    
    reachableStates.add(currentState);
    
    // Find all states reachable from current state
    for (final transition in tm.transitions) {
      if (transition.fromState == currentState) {
        _findReachableStates(tm, transition.toState, reachableStates);
      }
    }
  }
}

/// Result of simulating a TM
class TMSimulationResult {
  final String inputString;
  final bool accepted;
  final List<SimulationStep> steps;
  final String? errorMessage;
  final Duration executionTime;

  const TMSimulationResult._({
    required this.inputString,
    required this.accepted,
    required this.steps,
    this.errorMessage,
    required this.executionTime,
  });

  factory TMSimulationResult.success({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return TMSimulationResult._(
      inputString: inputString,
      accepted: true,
      steps: steps,
      executionTime: executionTime,
    );
  }

  factory TMSimulationResult.failure({
    required String inputString,
    required List<SimulationStep> steps,
    required String errorMessage,
    required Duration executionTime,
  }) {
    return TMSimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }

  factory TMSimulationResult.timeout({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return TMSimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: 'Simulation timed out',
      executionTime: executionTime,
    );
  }

  factory TMSimulationResult.infiniteLoop({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return TMSimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: 'Infinite loop detected',
      executionTime: executionTime,
    );
  }

  TMSimulationResult copyWith({
    String? inputString,
    bool? accepted,
    List<SimulationStep>? steps,
    String? errorMessage,
    Duration? executionTime,
  }) {
    return TMSimulationResult._(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      steps: steps ?? this.steps,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}

/// Analysis result of a TM
class TMAnalysis {
  final StateAnalysis stateAnalysis;
  final TransitionAnalysis transitionAnalysis;
  final TapeAnalysis tapeAnalysis;
  final ReachabilityAnalysis reachabilityAnalysis;
  final Duration executionTime;

  const TMAnalysis({
    required this.stateAnalysis,
    required this.transitionAnalysis,
    required this.tapeAnalysis,
    required this.reachabilityAnalysis,
    required this.executionTime,
  });

  TMAnalysis copyWith({
    StateAnalysis? stateAnalysis,
    TransitionAnalysis? transitionAnalysis,
    TapeAnalysis? tapeAnalysis,
    ReachabilityAnalysis? reachabilityAnalysis,
    Duration? executionTime,
  }) {
    return TMAnalysis(
      stateAnalysis: stateAnalysis ?? this.stateAnalysis,
      transitionAnalysis: transitionAnalysis ?? this.transitionAnalysis,
      tapeAnalysis: tapeAnalysis ?? this.tapeAnalysis,
      reachabilityAnalysis: reachabilityAnalysis ?? this.reachabilityAnalysis,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}

/// Analysis of states
class StateAnalysis {
  final int totalStates;
  final int acceptingStates;
  final int nonAcceptingStates;

  const StateAnalysis({
    required this.totalStates,
    required this.acceptingStates,
    required this.nonAcceptingStates,
  });
}

/// Analysis of transitions
class TransitionAnalysis {
  final int totalTransitions;
  final int tmTransitions;
  final int fsaTransitions;

  const TransitionAnalysis({
    required this.totalTransitions,
    required this.tmTransitions,
    required this.fsaTransitions,
  });
}

/// Analysis of tape operations
class TapeAnalysis {
  final Set<String> writeOperations;
  final Set<String> readOperations;
  final Set<String> moveDirections;
  final Set<String> tapeSymbols;

  const TapeAnalysis({
    required this.writeOperations,
    required this.readOperations,
    required this.moveDirections,
    required this.tapeSymbols,
  });
}

/// Analysis of reachability
class ReachabilityAnalysis {
  final Set<State> reachableStates;
  final Set<State> unreachableStates;

  const ReachabilityAnalysis({
    required this.reachableStates,
    required this.unreachableStates,
  });
}
