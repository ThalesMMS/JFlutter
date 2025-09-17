import '../models/pda.dart';
import '../models/state.dart';
import '../models/pda_transition.dart';
import '../models/fsa_transition.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';
import '../result.dart';
import 'automaton_analyzer.dart';

/// Simulates Pushdown Automata (PDA) with input strings
class PDASimulator {
  /// Simulates a PDA with an input string
  static Result<PDASimulationResult> simulate(
    PDA pda,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(pda, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty PDA
      if (pda.states.isEmpty) {
        return Failure('Cannot simulate empty PDA');
      }

      // Handle PDA with no initial state
      if (pda.initialState == null) {
        return Failure('PDA must have an initial state');
      }

      // Simulate the PDA
      final result = _simulatePDA(pda, inputString, stepByStep, timeout);
      stopwatch.stop();
      
      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);
      
      return Success(finalResult);
    } catch (e) {
      return Failure('Error simulating PDA: $e');
    }
  }

  /// Validates the input PDA and string
  static Result<void> _validateInput(PDA pda, String inputString) {
    if (pda.states.isEmpty) {
      return Failure('PDA must have at least one state');
    }
    
    if (pda.initialState == null) {
      return Failure('PDA must have an initial state');
    }
    
    if (!pda.states.contains(pda.initialState)) {
      return Failure('Initial state must be in the states set');
    }
    
    for (final acceptingState in pda.acceptingStates) {
      if (!pda.states.contains(acceptingState)) {
        return Failure('Accepting state must be in the states set');
      }
    }
    
    // Validate input string symbols
    for (int i = 0; i < inputString.length; i++) {
      final symbol = inputString[i];
      if (!pda.alphabet.contains(symbol)) {
        return Failure('Input string contains invalid symbol: $symbol');
      }
    }
    
    return Success(null);
  }

  /// Simulates the PDA with the input string
  static PDASimulationResult _simulatePDA(
    PDA pda,
    String inputString,
    bool stepByStep,
    Duration timeout,
  ) {
    final steps = <SimulationStep>[];
    final startTime = DateTime.now();
    
    // Initialize simulation
    var currentState = pda.initialState!;
    var remainingInput = inputString;
    var stack = <String>[pda.initialStackSymbol];
    int stepNumber = 0;
    
    // Add initial step
    steps.add(SimulationStep.initial(
      initialState: currentState.id,
      inputString: inputString,
    ));
    
    // Process each input symbol
    while (remainingInput.isNotEmpty) {
      stepNumber++;
      
      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        return PDASimulationResult.timeout(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }
      
      final symbol = remainingInput[0];
      remainingInput = remainingInput.substring(1);
      
      // Find transition
      final transition = pda.getPDATransitionFromStateOnSymbolAndStackTop(
        currentState,
        symbol,
        stack.isNotEmpty ? stack.last : '',
      );
      
      if (transition == null) {
        return PDASimulationFailure(
          inputString: inputString,
          steps: steps,
          errorMessage: 'No transition found for symbol $symbol and stack top ${stack.isNotEmpty ? stack.last : "empty"} in state ${currentState.id}',
          executionTime: DateTime.now().difference(startTime),
        );
      }
      
      // Update stack
      if (transition.stackPop.isNotEmpty) {
        if (stack.isNotEmpty && stack.last == transition.stackPop) {
          stack.removeLast();
        } else {
          return PDASimulationFailure(
            inputString: inputString,
            steps: steps,
            errorMessage: 'Cannot pop ${transition.stackPop} from stack',
            executionTime: DateTime.now().difference(startTime),
          );
        }
      }
      
      if (transition.stackPush.isNotEmpty) {
        stack.add(transition.stackPush);
      }
      
      // Add step
      if (stepByStep) {
        steps.add(SimulationStep.pda(
          currentState: currentState.id,
          remainingInput: remainingInput,
          usedTransition: symbol,
          stackContents: stack.join(''),
          stepNumber: stepNumber,
        ));
      }
      
      // Move to next state
      currentState = transition.toState;
      
      // Check for infinite loop (simplified)
      if (steps.length > 1000) {
        return PDASimulationResult.infiniteLoop(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }
    }
    
    // Add final step
        steps.add(SimulationStep.finalStepStep(
      finalState: currentState.id,
      remainingInput: remainingInput,
      stackContents: stack.join(''),
      tapeContents: '',
      stepNumber: stepNumber + 1,
    ));
    
    // Check if final state is accepting
    final isAccepted = pda.acceptingStates.contains(currentState);
    
    if (isAccepted) {
      return PDASimulationSuccess(
        inputString: inputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
      );
    } else {
      return PDASimulationFailure(
        inputString: inputString,
        steps: steps,
        errorMessage: 'Input not accepted - final state is not accepting',
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Tests if a PDA accepts a specific string
  static Result<bool> accepts(PDA pda, String inputString) {
    final simulationResult = simulate(pda, inputString);
    if (!simulationResult.isSuccess) {
      return Failure(simulationResult.error!);
    }
    
    return Success(simulationResult.data!.accepted);
  }

  /// Tests if a PDA rejects a specific string
  static Result<bool> rejects(PDA pda, String inputString) {
    final acceptsResult = accepts(pda, inputString);
    if (!acceptsResult.isSuccess) {
      return Failure(acceptsResult.error!);
    }
    
    return Success(!acceptsResult.data!);
  }

  /// Finds all strings of a given length that the PDA accepts
  static Result<Set<String>> findAcceptedStrings(
    PDA pda,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final acceptedStrings = <String>{};
      final alphabet = pda.alphabet.toList();
      
      // Generate all possible strings up to maxLength
      for (int length = 0; length <= maxLength && acceptedStrings.length < maxResults; length++) {
        _generateStrings(
          pda,
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
    PDA pda,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> acceptedStrings,
    int maxResults,
  ) {
    if (acceptedStrings.length >= maxResults) return;
    
    if (remainingLength == 0) {
      final acceptsResult = accepts(pda, currentString);
      if (acceptsResult.isSuccess && acceptsResult.data!) {
        acceptedStrings.add(currentString);
      }
      return;
    }
    
    for (final symbol in alphabet) {
      _generateStrings(
        pda,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        acceptedStrings,
        maxResults,
      );
    }
  }

  /// Finds all strings of a given length that the PDA rejects
  static Result<Set<String>> findRejectedStrings(
    PDA pda,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final rejectedStrings = <String>{};
      final alphabet = pda.alphabet.toList();
      
      // Generate all possible strings up to maxLength
      for (int length = 0; length <= maxLength && rejectedStrings.length < maxResults; length++) {
        _generateRejectedStrings(
          pda,
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
    PDA pda,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> rejectedStrings,
    int maxResults,
  ) {
    if (rejectedStrings.length >= maxResults) return;
    
    if (remainingLength == 0) {
      final acceptsResult = accepts(pda, currentString);
      if (acceptsResult.isSuccess && !acceptsResult.data!) {
        rejectedStrings.add(currentString);
      }
      return;
    }
    
    for (final symbol in alphabet) {
      _generateRejectedStrings(
        pda,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        rejectedStrings,
        maxResults,
      );
    }
  }

  /// Analyzes the behavior of a PDA
  static Result<PDAAnalysis> analyzePDA(
    PDA pda, {
    int maxInputLength = 10,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(pda, '');
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty PDA
      if (pda.states.isEmpty) {
        return Failure('Cannot analyze empty PDA');
      }

      // Handle PDA with no initial state
      if (pda.initialState == null) {
        return Failure('PDA must have an initial state');
      }

      // Analyze the PDA
      final result = _analyzePDA(pda, maxInputLength, timeout);
      stopwatch.stop();
      
      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);
      
      return Success(finalResult);
    } catch (e) {
      return Failure('Error analyzing PDA: $e');
    }
  }

  /// Analyzes the PDA
  static PDAAnalysis _analyzePDA(
    PDA pda,
    int maxInputLength,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // Analyze states
    final stateAnalysis = _analyzeStates(pda);
    
    // Analyze transitions
    final transitionAnalysis = _analyzeTransitions(pda);
    
    // Analyze stack operations
    final stackAnalysis = _analyzeStackOperations(pda);
    
    // Analyze reachability
    final reachabilityAnalysis = _analyzeReachability(pda);
    
    return PDAAnalysis(
      stateAnalysis: stateAnalysis,
      transitionAnalysis: transitionAnalysis,
      stackAnalysis: stackAnalysis,
      reachabilityAnalysis: reachabilityAnalysis,
      executionTime: DateTime.now().difference(startTime),
    );
  }

  /// Analyzes the states of the PDA
  static StateAnalysis _analyzeStates(PDA pda) {
    final totalStates = pda.states.length;
    final acceptingStates = pda.acceptingStates.length;
    final nonAcceptingStates = totalStates - acceptingStates;
    
    return StateAnalysis(
      totalStates: totalStates,
      acceptingStates: acceptingStates,
      nonAcceptingStates: nonAcceptingStates,
    );
  }

  /// Analyzes the transitions of the PDA
  static TransitionAnalysis _analyzeTransitions(PDA pda) {
    final totalTransitions = pda.transitions.length;
    final pdaTransitions = pda.transitions.whereType<PDATransition>().length;
    final fsaTransitions = pda.transitions.whereType<FSATransition>().length;
    
    return TransitionAnalysis(
      totalTransitions: totalTransitions,
      pdaTransitions: pdaTransitions,
      fsaTransitions: fsaTransitions,
    );
  }

  /// Analyzes the stack operations of the PDA
  static StackAnalysis _analyzeStackOperations(PDA pda) {
    final pushOperations = <String>{};
    final popOperations = <String>{};
    final stackSymbols = <String>{};
    
    for (final transition in pda.transitions) {
      if (transition is PDATransition) {
        if (transition.stackPush.isNotEmpty) {
          pushOperations.add(transition.stackPush);
        }
        if (transition.stackPop.isNotEmpty) {
          popOperations.add(transition.stackPop);
        }
        stackSymbols.addAll(pushOperations);
        stackSymbols.addAll(popOperations);
      }
    }
    
    return StackAnalysis(
      pushOperations: pushOperations,
      popOperations: popOperations,
      stackSymbols: stackSymbols,
    );
  }

  /// Analyzes the reachability of the PDA
  static ReachabilityAnalysis _analyzeReachability(PDA pda) {
    final reachableStates = <State>{};
    final unreachableStates = <State>{};
    
    // Find reachable states from initial state
    if (pda.initialState != null) {
      _findReachableStates(pda, pda.initialState!, reachableStates);
    }
    
    // Find unreachable states
    for (final state in pda.states) {
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
    PDA pda,
    State currentState,
    Set<State> reachableStates,
  ) {
    if (reachableStates.contains(currentState)) {
      return; // Already visited
    }
    
    reachableStates.add(currentState);
    
    // Find all states reachable from current state
    for (final transition in pda.transitions) {
      if (transition.fromState == currentState) {
        _findReachableStates(pda, transition.toState, reachableStates);
      }
    }
  }
}

/// Result of simulating a PDA
class PDASimulationResult {
  final String inputString;
  final bool accepted;
  final List<SimulationStep> steps;
  final String? errorMessage;
  final Duration executionTime;

  const PDASimulationResult._({
    required this.inputString,
    required this.accepted,
    required this.steps,
    this.errorMessage,
    required this.executionTime,
  });

  factory PDASimulationSuccess({
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

  factory PDASimulationFailure({
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
      errorMessage: 'Simulation timed out',
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
      errorMessage: 'Infinite loop detected',
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

/// Analysis result of a PDA
class PDAAnalysis {
  final StateAnalysis stateAnalysis;
  final TransitionAnalysis transitionAnalysis;
  final StackAnalysis stackAnalysis;
  final ReachabilityAnalysis reachabilityAnalysis;
  final Duration executionTime;

  const PDAAnalysis({
    required this.stateAnalysis,
    required this.transitionAnalysis,
    required this.stackAnalysis,
    required this.reachabilityAnalysis,
    required this.executionTime,
  });

  PDAAnalysis copyWith({
    StateAnalysis? stateAnalysis,
    TransitionAnalysis? transitionAnalysis,
    StackAnalysis? stackAnalysis,
    ReachabilityAnalysis? reachabilityAnalysis,
    Duration? executionTime,
  }) {
    return PDAAnalysis(
      stateAnalysis: stateAnalysis ?? this.stateAnalysis,
      transitionAnalysis: transitionAnalysis ?? this.transitionAnalysis,
      stackAnalysis: stackAnalysis ?? this.stackAnalysis,
      reachabilityAnalysis: reachabilityAnalysis ?? this.reachabilityAnalysis,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}

/// Analysis of states
class PDAStateAnalysis {
  final int totalStates;
  final int acceptingStates;
  final int nonAcceptingStates;

  const PDAStateAnalysis({
    required this.totalStates,
    required this.acceptingStates,
    required this.nonAcceptingStates,
  });
}

/// Analysis of transitions
class PDATransitionAnalysis {
  final int totalTransitions;
  final int pdaTransitions;
  final int fsaTransitions;

  const PDATransitionAnalysis({
    required this.totalTransitions,
    required this.pdaTransitions,
    required this.fsaTransitions,
  });
}

/// Analysis of stack operations
class StackAnalysis {
  final Set<String> pushOperations;
  final Set<String> popOperations;
  final Set<String> stackSymbols;

  const StackAnalysis({
    required this.pushOperations,
    required this.popOperations,
    required this.stackSymbols,
  });
}

/// Analysis of reachability
class PDAReachabilityAnalysis {
  final Set<State> reachableStates;
  final Set<State> unreachableStates;

  const PDAReachabilityAnalysis({
    required this.reachableStates,
    required this.unreachableStates,
  });
}
