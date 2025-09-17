import '../models/fsa.dart';
import '../models/state.dart';
import '../models/mealy_transition.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';
import '../result.dart';
import 'automaton_analyzer.dart';

/// Simulates Mealy machines with input strings
class MealyMachineSimulator {
  /// Simulates a Mealy machine with an input string
  static Result<MealySimulationResult> simulate(
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
        return Failure(validationResult.error!);
      }

      // Handle empty automaton
      if (automaton.states.isEmpty) {
        return Failure('Cannot simulate empty Mealy machine');
      }

      // Handle automaton with no initial state
      if (automaton.initialState == null) {
        return Failure('Mealy machine must have an initial state');
      }

      // Simulate the Mealy machine
      final result = _simulateMealyMachine(automaton, inputString, stepByStep, timeout);
      stopwatch.stop();
      
      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);
      
      return Success(finalResult);
    } catch (e) {
      return Failure('Error simulating Mealy machine: $e');
    }
  }

  /// Validates the input automaton and string
  static Result<void> _validateInput(FSA automaton, String inputString) {
    if (automaton.states.isEmpty) {
      return Failure('Mealy machine must have at least one state');
    }
    
    if (automaton.initialState == null) {
      return Failure('Mealy machine must have an initial state');
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

  /// Simulates the Mealy machine with the input string
  static MealySimulationResult _simulateMealyMachine(
    FSA automaton,
    String inputString,
    bool stepByStep,
    Duration timeout,
  ) {
    final steps = <SimulationStep>[];
    final startTime = DateTime.now();
    
    // Initialize simulation
    var currentState = automaton.initialState!;
    var remainingInput = inputString;
    var outputString = '';
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
        return MealySimulationResult.timeout(
          inputString: inputString,
          outputString: outputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }
      
      final symbol = remainingInput[0];
      remainingInput = remainingInput.substring(1);
      
      // Find transition
      final transition = automaton.getMealyTransitionFromStateOnSymbol(currentState, symbol);
      if (transition == null) {
        return MealySimulationFailure(
          inputString: inputString,
          outputString: outputString,
          steps: steps,
          errorMessage: 'No transition found for symbol $symbol in state ${currentState.id}',
          executionTime: DateTime.now().difference(startTime),
        );
      }
      
      // Update output string
      outputString += transition.output;
      
      // Add step
      if (stepByStep) {
        steps.add(SimulationStep.mealy(
          currentState: currentState.id,
          remainingInput: remainingInput,
          usedTransition: symbol,
          output: transition.output,
          stepNumber: stepNumber,
        ));
      }
      
      // Move to next state
      currentState = transition.toState;
      
      // Check for infinite loop (simplified)
      if (steps.length > 1000) {
        return MealySimulationResult.infiniteLoop(
          inputString: inputString,
          outputString: outputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }
    }
    
    // Add final step
    steps.add(SimulationStep.finalStep(
      finalState: currentState.id,
      remainingInput: remainingInput,
      stackContents: '',
      tapeContents: '',
      stepNumber: stepNumber + 1,
    ));
    
    // Check if final state is accepting
    final isAccepted = automaton.acceptingStates.contains(currentState);
    
    if (isAccepted) {
      return MealySimulationSuccess(
        inputString: inputString,
        outputString: outputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
      );
    } else {
      return MealySimulationFailure(
        inputString: inputString,
        outputString: outputString,
        steps: steps,
        errorMessage: 'Input not accepted - final state is not accepting',
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Tests if a Mealy machine accepts a specific string
  static Result<bool> accepts(FSA automaton, String inputString) {
    final simulationResult = simulate(automaton, inputString);
    if (!simulationResult.isSuccess) {
      return Failure(simulationResult.error!);
    }
    
    return Success(simulationResult.data!.accepted);
  }

  /// Tests if a Mealy machine rejects a specific string
  static Result<bool> rejects(FSA automaton, String inputString) {
    final acceptsResult = accepts(automaton, inputString);
    if (!acceptsResult.isSuccess) {
      return Failure(acceptsResult.error!);
    }
    
    return Success(!acceptsResult.data!);
  }

  /// Gets the output string for a given input
  static Result<String> getOutput(FSA automaton, String inputString) {
    final simulationResult = simulate(automaton, inputString);
    if (!simulationResult.isSuccess) {
      return Failure(simulationResult.error!);
    }
    
    return Success(simulationResult.data!.outputString);
  }

  /// Finds all input strings that produce a specific output
  static Result<Set<String>> findInputsForOutput(
    FSA automaton,
    String targetOutput, {
    int maxInputLength = 10,
    int maxResults = 100,
  }) {
    try {
      final inputStrings = <String>{};
      final alphabet = automaton.alphabet.toList();
      
      // Generate all possible input strings up to maxInputLength
      for (int length = 0; length <= maxInputLength && inputStrings.length < maxResults; length++) {
        _generateInputsForOutput(
          automaton,
          alphabet,
          '',
          length,
          targetOutput,
          inputStrings,
          maxResults,
        );
      }
      
      return Success(inputStrings);
    } catch (e) {
      return Failure('Error finding inputs for output: $e');
    }
  }

  /// Recursively generates input strings and tests them
  static void _generateInputsForOutput(
    FSA automaton,
    List<String> alphabet,
    String currentInput,
    int remainingLength,
    String targetOutput,
    Set<String> inputStrings,
    int maxResults,
  ) {
    if (inputStrings.length >= maxResults) return;
    
    if (remainingLength == 0) {
      final outputResult = getOutput(automaton, currentInput);
      if (outputResult.isSuccess && outputResult.data == targetOutput) {
        inputStrings.add(currentInput);
      }
      return;
    }
    
    for (final symbol in alphabet) {
      _generateInputsForOutput(
        automaton,
        alphabet,
        currentInput + symbol,
        remainingLength - 1,
        targetOutput,
        inputStrings,
        maxResults,
      );
    }
  }

  /// Finds all output strings that can be produced
  static Result<Set<String>> findPossibleOutputs(
    FSA automaton, {
    int maxInputLength = 10,
    int maxResults = 100,
  }) {
    try {
      final outputStrings = <String>{};
      final alphabet = automaton.alphabet.toList();
      
      // Generate all possible input strings up to maxInputLength
      for (int length = 0; length <= maxInputLength && outputStrings.length < maxResults; length++) {
        _generatePossibleOutputs(
          automaton,
          alphabet,
          '',
          length,
          outputStrings,
          maxResults,
        );
      }
      
      return Success(outputStrings);
    } catch (e) {
      return Failure('Error finding possible outputs: $e');
    }
  }

  /// Recursively generates input strings and collects outputs
  static void _generatePossibleOutputs(
    FSA automaton,
    List<String> alphabet,
    String currentInput,
    int remainingLength,
    Set<String> outputStrings,
    int maxResults,
  ) {
    if (outputStrings.length >= maxResults) return;
    
    if (remainingLength == 0) {
      final outputResult = getOutput(automaton, currentInput);
      if (outputResult.isSuccess) {
        outputStrings.add(outputResult.data!);
      }
      return;
    }
    
    for (final symbol in alphabet) {
      _generatePossibleOutputs(
        automaton,
        alphabet,
        currentInput + symbol,
        remainingLength - 1,
        outputStrings,
        maxResults,
      );
    }
  }

  /// Analyzes the behavior of a Mealy machine
  static Result<MealyAnalysis> analyzeMealyMachine(
    FSA automaton, {
    int maxInputLength = 10,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(automaton, '');
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty automaton
      if (automaton.states.isEmpty) {
        return Failure('Cannot analyze empty Mealy machine');
      }

      // Handle automaton with no initial state
      if (automaton.initialState == null) {
        return Failure('Mealy machine must have an initial state');
      }

      // Analyze the Mealy machine
      final result = _analyzeMealyMachine(automaton, maxInputLength, timeout);
      stopwatch.stop();
      
      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);
      
      return Success(finalResult);
    } catch (e) {
      return Failure('Error analyzing Mealy machine: $e');
    }
  }

  /// Analyzes the Mealy machine
  static MealyAnalysis _analyzeMealyMachine(
    FSA automaton,
    int maxInputLength,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // Analyze states
    final stateAnalysis = _analyzeStates(automaton);
    
    // Analyze transitions
    final transitionAnalysis = _analyzeTransitions(automaton);
    
    // Analyze outputs
    final outputAnalysis = _analyzeOutputs(automaton, maxInputLength, timeout);
    
    // Analyze reachability
    final reachabilityAnalysis = _analyzeReachability(automaton);
    
    return MealyAnalysis(
      stateAnalysis: stateAnalysis,
      transitionAnalysis: transitionAnalysis,
      outputAnalysis: outputAnalysis,
      reachabilityAnalysis: reachabilityAnalysis,
      executionTime: DateTime.now().difference(startTime),
    );
  }

  /// Analyzes the states of the Mealy machine
  static StateAnalysis _analyzeStates(FSA automaton) {
    final totalStates = automaton.states.length;
    final acceptingStates = automaton.acceptingStates.length;
    final nonAcceptingStates = totalStates - acceptingStates;
    
    return StateAnalysis(
      totalStates: totalStates,
      acceptingStates: acceptingStates,
      nonAcceptingStates: nonAcceptingStates,
    );
  }

  /// Analyzes the transitions of the Mealy machine
  static TransitionAnalysis _analyzeTransitions(FSA automaton) {
    final totalTransitions = automaton.transitions.length;
    final mealyTransitions = automaton.transitions.whereType<MealyTransition>().length;
    final fsaTransitions = automaton.transitions.whereType<FSATransition>().length;
    
    return TransitionAnalysis(
      totalTransitions: totalTransitions,
      mealyTransitions: mealyTransitions,
      fsaTransitions: fsaTransitions,
    );
  }

  /// Analyzes the outputs of the Mealy machine
  static OutputAnalysis _analyzeOutputs(
    FSA automaton,
    int maxInputLength,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    final possibleOutputs = <String>{};
    final alphabet = automaton.alphabet.toList();
    
    // Generate all possible input strings up to maxInputLength
    for (int length = 0; length <= maxInputLength && possibleOutputs.length < 100; length++) {
      _generatePossibleOutputs(
        automaton,
        alphabet,
        '',
        length,
        possibleOutputs,
        100,
      );
    }
    
    return OutputAnalysis(
      possibleOutputs: possibleOutputs,
      uniqueOutputs: possibleOutputs.length,
    );
  }

  /// Analyzes the reachability of the Mealy machine
  static ReachabilityAnalysis _analyzeReachability(FSA automaton) {
    final reachableStates = <State>{};
    final unreachableStates = <State>{};
    
    // Find reachable states from initial state
    if (automaton.initialState != null) {
      _findReachableStates(automaton, automaton.initialState!, reachableStates);
    }
    
    // Find unreachable states
    for (final state in automaton.states) {
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
    FSA automaton,
    State currentState,
    Set<State> reachableStates,
  ) {
    if (reachableStates.contains(currentState)) {
      return; // Already visited
    }
    
    reachableStates.add(currentState);
    
    // Find all states reachable from current state
    for (final transition in automaton.transitions) {
      if (transition.fromState == currentState) {
        _findReachableStates(automaton, transition.toState, reachableStates);
      }
    }
  }
}

/// Result of simulating a Mealy machine
class MealySimulationResult {
  final String inputString;
  final String outputString;
  final bool accepted;
  final List<SimulationStep> steps;
  final String? errorMessage;
  final Duration executionTime;

  const MealySimulationResult._({
    required this.inputString,
    required this.outputString,
    required this.accepted,
    required this.steps,
    this.errorMessage,
    required this.executionTime,
  });

  factory MealySimulationSuccess({
    required String inputString,
    required String outputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return MealySimulationResult._(
      inputString: inputString,
      outputString: outputString,
      accepted: true,
      steps: steps,
      executionTime: executionTime,
    );
  }

  factory MealySimulationFailure({
    required String inputString,
    required String outputString,
    required List<SimulationStep> steps,
    required String errorMessage,
    required Duration executionTime,
  }) {
    return MealySimulationResult._(
      inputString: inputString,
      outputString: outputString,
      accepted: false,
      steps: steps,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }

  factory MealySimulationResult.timeout({
    required String inputString,
    required String outputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return MealySimulationResult._(
      inputString: inputString,
      outputString: outputString,
      accepted: false,
      steps: steps,
      errorMessage: 'Simulation timed out',
      executionTime: executionTime,
    );
  }

  factory MealySimulationResult.infiniteLoop({
    required String inputString,
    required String outputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
  }) {
    return MealySimulationResult._(
      inputString: inputString,
      outputString: outputString,
      accepted: false,
      steps: steps,
      errorMessage: 'Infinite loop detected',
      executionTime: executionTime,
    );
  }

  MealySimulationResult copyWith({
    String? inputString,
    String? outputString,
    bool? accepted,
    List<SimulationStep>? steps,
    String? errorMessage,
    Duration? executionTime,
  }) {
    return MealySimulationResult._(
      inputString: inputString ?? this.inputString,
      outputString: outputString ?? this.outputString,
      accepted: accepted ?? this.accepted,
      steps: steps ?? this.steps,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}

/// Analysis result of a Mealy machine
class MealyAnalysis {
  final StateAnalysis stateAnalysis;
  final TransitionAnalysis transitionAnalysis;
  final OutputAnalysis outputAnalysis;
  final ReachabilityAnalysis reachabilityAnalysis;
  final Duration executionTime;

  const MealyAnalysis({
    required this.stateAnalysis,
    required this.transitionAnalysis,
    required this.outputAnalysis,
    required this.reachabilityAnalysis,
    required this.executionTime,
  });

  MealyAnalysis copyWith({
    StateAnalysis? stateAnalysis,
    TransitionAnalysis? transitionAnalysis,
    OutputAnalysis? outputAnalysis,
    ReachabilityAnalysis? reachabilityAnalysis,
    Duration? executionTime,
  }) {
    return MealyAnalysis(
      stateAnalysis: stateAnalysis ?? this.stateAnalysis,
      transitionAnalysis: transitionAnalysis ?? this.transitionAnalysis,
      outputAnalysis: outputAnalysis ?? this.outputAnalysis,
      reachabilityAnalysis: reachabilityAnalysis ?? this.reachabilityAnalysis,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}

/// Analysis of states
class MealyStateAnalysis {
  final int totalStates;
  final int acceptingStates;
  final int nonAcceptingStates;

  const MealyStateAnalysis({
    required this.totalStates,
    required this.acceptingStates,
    required this.nonAcceptingStates,
  });
}

/// Analysis of transitions
class MealyTransitionAnalysis {
  final int totalTransitions;
  final int mealyTransitions;
  final int fsaTransitions;

  const MealyTransitionAnalysis({
    required this.totalTransitions,
    required this.mealyTransitions,
    required this.fsaTransitions,
  });
}

/// Analysis of outputs
class OutputAnalysis {
  final Set<String> possibleOutputs;
  final int uniqueOutputs;

  const OutputAnalysis({
    required this.possibleOutputs,
    required this.uniqueOutputs,
  });
}

/// Analysis of reachability
class MealyReachabilityAnalysis {
  final Set<State> reachableStates;
  final Set<State> unreachableStates;

  const MealyReachabilityAnalysis({
    required this.reachableStates,
    required this.unreachableStates,
  });
}
