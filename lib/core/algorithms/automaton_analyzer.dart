/// Analysis classes for automaton properties and characteristics

/// Analysis of state-related properties
class AutomatonStateAnalysis {
  /// Total number of states in the automaton
  final int stateCount;
  
  /// Number of initial states
  final int initialStateCount;
  
  /// Number of accepting/final states
  final int acceptingStateCount;
  
  /// Number of unreachable states
  final int unreachableStateCount;
  
  /// Number of dead states
  final int deadStateCount;
  
  /// Whether the automaton has an initial state
  final bool hasInitialState;
  
  /// Whether the automaton has accepting states
  final bool hasAcceptingStates;

  const AutomatonStateAnalysis({
    required this.stateCount,
    required this.initialStateCount,
    required this.acceptingStateCount,
    required this.unreachableStateCount,
    required this.deadStateCount,
    required this.hasInitialState,
    required this.hasAcceptingStates,
  });

  /// Creates a AutomatonStateAnalysis from automaton data
  factory AutomatonStateAnalysis.fromAutomaton({
    required int stateCount,
    required int initialStateCount,
    required int acceptingStateCount,
    required int unreachableStateCount,
    required int deadStateCount,
  }) {
    return AutomatonStateAnalysis(
      stateCount: stateCount,
      initialStateCount: initialStateCount,
      acceptingStateCount: acceptingStateCount,
      unreachableStateCount: unreachableStateCount,
      deadStateCount: deadStateCount,
      hasInitialState: initialStateCount > 0,
      hasAcceptingStates: acceptingStateCount > 0,
    );
  }

  @override
  String toString() {
    return 'AutomatonStateAnalysis(states: $stateCount, initial: $initialStateCount, '
        'accepting: $acceptingStateCount, unreachable: $unreachableStateCount, '
        'dead: $deadStateCount)';
  }
}

/// Analysis of transition-related properties
class AutomatonTransitionAnalysis {
  /// Total number of transitions in the automaton
  final int transitionCount;
  
  /// Number of deterministic transitions
  final int deterministicTransitionCount;
  
  /// Number of non-deterministic transitions
  final int nondeterministicTransitionCount;
  
  /// Number of epsilon/lambda transitions
  final int epsilonTransitionCount;
  
  /// Whether the automaton is deterministic
  final bool isDeterministic;
  
  /// Whether the automaton has epsilon transitions
  final bool hasEpsilonTransitions;

  const AutomatonTransitionAnalysis({
    required this.transitionCount,
    required this.deterministicTransitionCount,
    required this.nondeterministicTransitionCount,
    required this.epsilonTransitionCount,
    required this.isDeterministic,
    required this.hasEpsilonTransitions,
  });

  /// Creates a AutomatonTransitionAnalysis from automaton data
  factory AutomatonTransitionAnalysis.fromAutomaton({
    required int transitionCount,
    required int deterministicTransitionCount,
    required int nondeterministicTransitionCount,
    required int epsilonTransitionCount,
  }) {
    return AutomatonTransitionAnalysis(
      transitionCount: transitionCount,
      deterministicTransitionCount: deterministicTransitionCount,
      nondeterministicTransitionCount: nondeterministicTransitionCount,
      epsilonTransitionCount: epsilonTransitionCount,
      isDeterministic: nondeterministicTransitionCount == 0,
      hasEpsilonTransitions: epsilonTransitionCount > 0,
    );
  }

  @override
  String toString() {
    return 'AutomatonTransitionAnalysis(transitions: $transitionCount, '
        'deterministic: $deterministicTransitionCount, '
        'nondeterministic: $nondeterministicTransitionCount, '
        'epsilon: $epsilonTransitionCount)';
  }
}

/// Analysis of reachability properties
class AutomatonReachabilityAnalysis {
  /// Number of reachable states from the initial state
  final int reachableStates;
  
  /// Number of unreachable states
  final int unreachableStates;
  
  /// Whether all states are reachable
  final bool allStatesReachable;
  
  /// Whether the automaton is empty (no accepting states reachable)
  final bool isEmpty;
  
  /// Whether the automaton is universal (all reachable states are accepting)
  final bool isUniversal;

  const AutomatonReachabilityAnalysis({
    required this.reachableStates,
    required this.unreachableStates,
    required this.allStatesReachable,
    required this.isEmpty,
    required this.isUniversal,
  });

  /// Creates a AutomatonReachabilityAnalysis from automaton data
  factory AutomatonReachabilityAnalysis.fromAutomaton({
    required int totalStates,
    required int reachableStates,
    required int acceptingStates,
    required int reachableAcceptingStates,
  }) {
    final unreachableStates = totalStates - reachableStates;
    final allStatesReachable = unreachableStates == 0;
    final isEmpty = reachableAcceptingStates == 0;
    final isUniversal = reachableStates > 0 && reachableStates == reachableAcceptingStates;
    
    return AutomatonReachabilityAnalysis(
      reachableStates: reachableStates,
      unreachableStates: unreachableStates,
      allStatesReachable: allStatesReachable,
      isEmpty: isEmpty,
      isUniversal: isUniversal,
    );
  }

  @override
  String toString() {
    return 'AutomatonReachabilityAnalysis(reachable: $reachableStates, '
        'unreachable: $unreachableStates, allReachable: $allStatesReachable, '
        'isEmpty: $isEmpty, isUniversal: $isUniversal)';
  }
}

/// Comprehensive analysis combining all analysis types
class AutomatonAnalysis {
  /// State analysis
  final AutomatonStateAnalysis stateAnalysis;
  
  /// Transition analysis
  final AutomatonTransitionAnalysis transitionAnalysis;
  
  /// Reachability analysis
  final AutomatonReachabilityAnalysis reachabilityAnalysis;
  
  /// Overall validity of the automaton
  final bool isValid;
  
  /// List of validation errors
  final List<String> errors;

  const AutomatonAnalysis({
    required this.stateAnalysis,
    required this.transitionAnalysis,
    required this.reachabilityAnalysis,
    required this.isValid,
    required this.errors,
  });

  /// Creates a comprehensive analysis from individual analyses
  factory AutomatonAnalysis.combine({
    required AutomatonStateAnalysis stateAnalysis,
    required AutomatonTransitionAnalysis transitionAnalysis,
    required AutomatonReachabilityAnalysis reachabilityAnalysis,
    List<String> errors = const [],
  }) {
    final isValid = errors.isEmpty;
    
    return AutomatonAnalysis(
      stateAnalysis: stateAnalysis,
      transitionAnalysis: transitionAnalysis,
      reachabilityAnalysis: reachabilityAnalysis,
      isValid: isValid,
      errors: errors,
    );
  }

  @override
  String toString() {
    return 'AutomatonAnalysis(valid: $isValid, errors: ${errors.length})';
  }
}
