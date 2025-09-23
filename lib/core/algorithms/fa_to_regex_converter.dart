import 'package:vector_math/vector_math_64.dart';
import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../result.dart';

/// Converts Finite Automata (FA) to Regular Expressions using the state elimination method
class FAToRegexConverter {
  /// Converts a Finite Automaton to an equivalent regular expression
  static Result<String> convert(FSA fa) {
    try {
      // Validate input
      final validationResult = _validateInput(fa);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty automaton
      if (fa.states.isEmpty) {
        return ResultFactory.failure('Cannot convert empty automaton to regex');
      }

      // Handle automaton with no initial state
      if (fa.initialState == null) {
        return ResultFactory.failure('Automaton must have an initial state');
      }

      // Step 1: Ensure single initial and final states
      final faWithSingleStates = _ensureSingleInitialAndFinalStates(fa);
      
      // Step 2: Apply state elimination algorithm
      final regex = _stateElimination(faWithSingleStates);
      
      return ResultFactory.success(regex);
    } catch (e) {
      return ResultFactory.failure('Error converting FA to regex: $e');
    }
  }

  /// Validates the input FA
  static Result<void> _validateInput(FSA fa) {
    if (fa.states.isEmpty) {
      return ResultFactory.failure('FA must have at least one state');
    }
    
    if (fa.initialState == null) {
      return ResultFactory.failure('FA must have an initial state');
    }
    
    if (!fa.states.contains(fa.initialState)) {
      return ResultFactory.failure('Initial state must be in the states set');
    }
    
    for (final acceptingState in fa.acceptingStates) {
      if (!fa.states.contains(acceptingState)) {
        return ResultFactory.failure('Accepting state must be in the states set');
      }
    }
    
    return ResultFactory.success(null);
  }

  /// Ensures the FA has a single initial state and a single final state
  static FSA _ensureSingleInitialAndFinalStates(FSA fa) {
    final now = DateTime.now();
    
    // Create new initial state if needed
    State newInitialState;
    if (fa.initialState != null && fa.acceptingStates.length == 1) {
      newInitialState = fa.initialState!;
    } else {
      newInitialState = State(
        id: 'q_initial',
        label: 'q_initial',
        position: Vector2(50, 100),
        isInitial: true,
        isAccepting: false,
      );
    }
    
    // Create new final state if needed
    State newFinalState;
    if (fa.acceptingStates.length == 1) {
      newFinalState = fa.acceptingStates.first;
    } else {
      newFinalState = State(
        id: 'q_final',
        label: 'q_final',
        position: Vector2(350, 100),
        isInitial: false,
        isAccepting: true,
      );
    }
    
    // If we need to add new states
    if (newInitialState.id == 'q_initial' || newFinalState.id == 'q_final') {
      final newStates = Set<State>.from(fa.states);
      final newTransitions = Set<FSATransition>.from(fa.fsaTransitions);
      
      // Add new initial state if needed
      if (newInitialState.id == 'q_initial') {
        newStates.add(newInitialState);
        // Add epsilon transition from new initial to old initial
        newTransitions.add(FSATransition.epsilon(
          id: 't_eps_initial',
          fromState: newInitialState,
          toState: fa.initialState!,
        ));
      }
      
      // Add new final state if needed
      if (newFinalState.id == 'q_final') {
        newStates.add(newFinalState);
        // Add epsilon transitions from old accepting states to new final
        for (final acceptingState in fa.acceptingStates) {
          newTransitions.add(FSATransition.epsilon(
            id: 't_eps_final_${acceptingState.id}',
            fromState: acceptingState,
            toState: newFinalState,
          ));
        }
      }
      
      return FSA(
        id: '${fa.id}_single_states',
        name: '${fa.name} (Single States)',
        states: newStates,
        transitions: newTransitions,
        alphabet: fa.alphabet,
        initialState: newInitialState,
        acceptingStates: {newFinalState},
        created: fa.created,
        modified: now,
        bounds: fa.bounds,
        zoomLevel: fa.zoomLevel,
        panOffset: fa.panOffset,
      );
    }
    
    return fa;
  }

  /// Applies the state elimination algorithm
  static String _stateElimination(FSA fa) {
    // Create a copy of the FA for modification
    var currentFA = fa;
    
    // Get all non-initial, non-final states
    final statesToEliminate = currentFA.states
        .where((state) => 
            state != currentFA.initialState && 
            !currentFA.acceptingStates.contains(state))
        .toList();
    
    // Eliminate states one by one
    for (final stateToEliminate in statesToEliminate) {
      currentFA = _eliminateState(currentFA, stateToEliminate);
    }
    
    // Extract regex from the final automaton
    return _extractRegexFromFinalFA(currentFA);
  }

  /// Eliminates a single state from the FA
  static FSA _eliminateState(FSA fa, State stateToEliminate) {
    final newTransitions = <FSATransition>{};
    final transitionByStates = <(State, State), FSATransition>{};
    final newStates = fa.states.where((s) => s != stateToEliminate).toSet();

    final incomingBySource = <State, List<FSATransition>>{};
    final outgoingByTarget = <State, List<FSATransition>>{};

    String selfLoopRegex = '';

    // Keep all transitions not involving the state to eliminate while
    // precomputing incoming/outgoing maps and detecting self-loops.
    for (final transition in fa.fsaTransitions) {
      final fromState = transition.fromState;
      final toState = transition.toState;

      if (fromState == stateToEliminate && toState == stateToEliminate) {
        if (selfLoopRegex.isEmpty) {
          selfLoopRegex = transition.label;
        } else {
          selfLoopRegex = '($selfLoopRegex|${transition.label})';
        }
        continue;
      }

      if (toState == stateToEliminate) {
        incomingBySource
            .putIfAbsent(fromState, () => <FSATransition>[])
            .add(transition);
      }

      if (fromState == stateToEliminate) {
        outgoingByTarget
            .putIfAbsent(toState, () => <FSATransition>[])
            .add(transition);
      }

      if (fromState != stateToEliminate && toState != stateToEliminate) {
        newTransitions.add(transition);
        transitionByStates[(fromState, toState)] = transition;
      }
    }
    
    // Add Kleene star if there's a self-loop
    if (selfLoopRegex.isNotEmpty) {
      selfLoopRegex = '($selfLoopRegex)*';
    }
    
    // Create new transitions for all combinations of incoming and outgoing states
    for (final MapEntry(key: incomingState, value: incomingTransitions)
        in incomingBySource.entries) {
      for (final MapEntry(key: outgoingState, value: outgoingTransitions)
          in outgoingByTarget.entries) {
        for (final incomingTransition in incomingTransitions) {
          for (final outgoingTransition in outgoingTransitions) {
            // Build the regex for this path
            String pathRegex = incomingTransition.label;
            if (selfLoopRegex.isNotEmpty) {
              pathRegex += selfLoopRegex;
            }
            pathRegex += outgoingTransition.label;

            final key = (incomingState, outgoingState);
            final existingTransition = transitionByStates[key];

            if (existingTransition != null) {
              final combinedRegex =
                  '(${existingTransition.label}|$pathRegex)';
              final combinedTransition = FSATransition(
                id: 't_combined_${incomingState.id}_${outgoingState.id}',
                fromState: incomingState,
                toState: outgoingState,
                label: combinedRegex,
                inputSymbols: {combinedRegex}, // Simplified
              );
              newTransitions
                ..remove(existingTransition)
                ..add(combinedTransition);
              transitionByStates[key] = combinedTransition;
            } else {
              final newTransition = FSATransition(
                id: 't_new_${incomingState.id}_${outgoingState.id}',
                fromState: incomingState,
                toState: outgoingState,
                label: pathRegex,
                inputSymbols: {pathRegex}, // Simplified
              );
              newTransitions.add(newTransition);
              transitionByStates[key] = newTransition;
            }
          }
        }
      }
    }
    
    return FSA(
      id: '${fa.id}_eliminated_${stateToEliminate.id}',
      name: '${fa.name} (Eliminated ${stateToEliminate.id})',
      states: newStates,
      transitions: newTransitions,
      alphabet: fa.alphabet,
      initialState: fa.initialState,
      acceptingStates: fa.acceptingStates,
      created: fa.created,
      modified: DateTime.now(),
      bounds: fa.bounds,
      zoomLevel: fa.zoomLevel,
      panOffset: fa.panOffset,
    );
  }

  /// Extracts the regex from the final FA (with only initial and final states)
  static String _extractRegexFromFinalFA(FSA fa) {
    final initialState = fa.initialState!;
    final finalState = fa.acceptingStates.first;
    
    // Find all transitions from initial to final state
    final transitions = fa.fsaTransitions
        .where((t) => t.fromState == initialState && t.toState == finalState)
        .toList();
    
    if (transitions.isEmpty) {
      return '∅'; // Empty language
    }
    
    if (transitions.length == 1) {
      return transitions.first.label;
    }
    
    // Combine multiple transitions with union
    final regexParts = transitions.map((t) => t.label).toList();
    return '(${regexParts.join('|')})';
  }

  /// Converts FA to regex with step-by-step information
  static Result<FAToRegexConversionResult> convertWithSteps(FSA fa) {
    try {
      final steps = <FARegexConversionStep>[];
      
      // Step 1: Validate input
      steps.add(FARegexConversionStep(
        stepNumber: 1,
        description: 'Validating input FA',
        fa: fa,
        regex: null,
      ));

      final validationResult = _validateInput(fa);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Step 2: Ensure single initial and final states
      steps.add(FARegexConversionStep(
        stepNumber: 2,
        description: 'Ensuring single initial and final states',
        fa: fa,
        regex: null,
      ));

      final faWithSingleStates = _ensureSingleInitialAndFinalStates(fa);
      steps.add(FARegexConversionStep(
        stepNumber: 3,
        description: 'Single initial and final states ensured',
        fa: faWithSingleStates,
        regex: null,
      ));

      // Step 3: Apply state elimination
      steps.add(FARegexConversionStep(
        stepNumber: 4,
        description: 'Applying state elimination algorithm',
        fa: faWithSingleStates,
        regex: null,
      ));

      final regex = _stateElimination(faWithSingleStates);
      steps.add(FARegexConversionStep(
        stepNumber: 5,
        description: 'State elimination completed',
        fa: faWithSingleStates,
        regex: regex,
      ));

      final result = FAToRegexConversionResult(
        originalFA: fa,
        resultRegex: regex,
        steps: steps,
        executionTime: Duration.zero, // Would be calculated in real implementation
      );

      return ResultFactory.success(result);
    } catch (e) {
      return ResultFactory.failure('Error converting FA to regex with steps: $e');
    }
  }
}

/// Result of FA to regex conversion with step-by-step information
class FAToRegexConversionResult {
  /// Original FA
  final FSA originalFA;
  
  /// Resulting regex
  final String resultRegex;
  
  /// Conversion steps
  final List<FARegexConversionStep> steps;
  
  /// Execution time
  final Duration executionTime;

  const FAToRegexConversionResult({
    required this.originalFA,
    required this.resultRegex,
    required this.steps,
    required this.executionTime,
  });

  /// Gets the number of steps
  int get stepCount => steps.length;

  /// Gets the first step
  FARegexConversionStep? get firstStep => steps.isNotEmpty ? steps.first : null;

  /// Gets the last step
  FARegexConversionStep? get lastStep => steps.isNotEmpty ? steps.last : null;

  /// Gets the execution time in milliseconds
  int get executionTimeMs => executionTime.inMilliseconds;

  /// Gets the execution time in seconds
  double get executionTimeSeconds => executionTime.inMicroseconds / 1000000.0;
}

/// Single step in FA to regex conversion
class FARegexConversionStep {
  /// Step number
  final int stepNumber;
  
  /// Description of the step
  final String description;
  
  /// FA at this step
  final FSA? fa;
  
  /// Regex at this step
  final String? regex;

  const FARegexConversionStep({
    required this.stepNumber,
    required this.description,
    this.fa,
    this.regex,
  });

  @override
  String toString() {
    return 'FARegexConversionStep(stepNumber: $stepNumber, description: $description)';
  }
}

