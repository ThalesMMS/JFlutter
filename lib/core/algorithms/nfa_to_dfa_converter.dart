//
//  nfa_to_dfa_converter.dart
//  JFlutter
//
//  Implementa a conversão de autômatos finitos não determinísticos em
//  determinísticos utilizando construção por subconjuntos com fechos-ε.
//  Inclui rotinas de validação, limpeza de transições lambda e criação das
//  estruturas determinísticas preservando estados, símbolos e aceitação.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:vector_math/vector_math_64.dart';
import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../result.dart';

/// Converts Non-deterministic Finite Automata (NFA) to Deterministic Finite Automata (DFA)
class NFAToDFAConverter {
  /// Converts an NFA to an equivalent DFA
  static Result<FSA> convert(FSA nfa) {
    try {
      // Validate input
      final validationResult = _validateInput(nfa);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty NFA
      if (nfa.states.isEmpty) {
        return ResultFactory.failure('Cannot convert empty NFA to DFA');
      }

      // Handle NFA with no initial state
      if (nfa.initialState == null) {
        return ResultFactory.failure('NFA must have an initial state');
      }

      // Build DFA directly from NFA using epsilon-closures in subset construction
      final dfa = _buildDFAWithEpsilon(nfa);

      return ResultFactory.success(dfa);
    } catch (e) {
      return ResultFactory.failure('Error converting NFA to DFA: $e');
    }
  }

  /// Validates the input NFA
  static Result<void> _validateInput(FSA nfa) {
    if (nfa.states.isEmpty) {
      return ResultFactory.failure('NFA must have at least one state');
    }

    if (nfa.initialState == null) {
      return ResultFactory.failure('NFA must have an initial state');
    }

    if (!nfa.states.contains(nfa.initialState)) {
      return ResultFactory.failure('Initial state must be in the states set');
    }

    for (final acceptingState in nfa.acceptingStates) {
      if (!nfa.states.contains(acceptingState)) {
        return ResultFactory.failure(
          'Accepting state must be in the states set',
        );
      }
    }

    return ResultFactory.success(null);
  }

  /// Removes epsilon transitions from the NFA
  static FSA _removeEpsilonTransitions(FSA nfa) {
    // Treat typical epsilon markers uniformly, regardless of encoding.
    bool isEpsilonSymbol(String s) {
      final normalized = s.trim().toLowerCase();
      return normalized.isEmpty ||
          normalized == 'ε' ||
          normalized == 'λ' ||
          normalized == 'lambda';
    }

    if (!nfa.hasEpsilonTransitions &&
        !nfa.fsaTransitions.any(
          (t) =>
              (t.lambdaSymbol != null && isEpsilonSymbol(t.lambdaSymbol!)) ||
              (t.inputSymbols.any(isEpsilonSymbol)),
        )) {
      return nfa;
    }

    final newTransitions = <FSATransition>{};
    final newStates = Set<State>.from(nfa.states);
    final newAcceptingStates = Set<State>.from(nfa.acceptingStates);

    // For each state, compute its epsilon closure (include transitions encoded via
    // lambdaSymbol or inputSymbols containing an epsilon-like marker)
    final epsilonClosures = <State, Set<State>>{};
    for (final state in nfa.states) {
      epsilonClosures[state] = _epsilonClosureFlexible(
        nfa,
        state,
        isEpsilonSymbol,
      );
    }

    // Add new transitions for epsilon closure
    for (final state in nfa.states) {
      final closure = epsilonClosures[state]!;

      // If any state in the closure is accepting, make the original state accepting
      for (final closureState in closure) {
        if (nfa.acceptingStates.contains(closureState)) {
          newAcceptingStates.add(state);
        }
      }

      // For each symbol in the alphabet (excluding epsilon-like markers)
      final workingAlphabet = nfa.alphabet
          .where((s) => !isEpsilonSymbol(s))
          .toSet();
      for (final symbol in workingAlphabet) {
        final reachableStates = <State>{};

        // Find all states reachable from the closure on this symbol
        for (final closureState in closure) {
          final transitions = nfa
              .getTransitionsFromStateOnSymbol(closureState, symbol)
              .where((t) => !t.isEpsilonTransition)
              .toList();
          for (final transition in transitions) {
            reachableStates.add(transition.toState);
          }
        }

        // Add transitions for all reachable states
        for (final reachableState in reachableStates) {
          final reachableClosure = epsilonClosures[reachableState]!;
          for (final finalState in reachableClosure) {
            final newTransition = FSATransition.deterministic(
              id: 't_${state.id}_${symbol}_${finalState.id}',
              fromState: state,
              toState: finalState,
              symbol: symbol,
            );
            newTransitions.add(newTransition);
          }
        }
      }
    }

    // Create new FSA without epsilon transitions
    return FSA(
      id: '${nfa.id}_no_epsilon',
      name: '${nfa.name} (No Epsilon)',
      states: newStates,
      transitions: newTransitions,
      alphabet: nfa.alphabet.where((s) => !isEpsilonSymbol(s)).toSet(),
      initialState: nfa.initialState,
      acceptingStates: newAcceptingStates,
      created: nfa.created,
      modified: DateTime.now(),
      bounds: nfa.bounds,
      zoomLevel: nfa.zoomLevel,
      panOffset: nfa.panOffset,
    );
  }

  /// Builds DFA using subset construction with epsilon-closures over the original NFA
  static FSA _buildDFAWithEpsilon(FSA nfa) {
    bool isEpsilonSymbol(String s) {
      final normalized = s.trim().toLowerCase();
      return normalized.isEmpty ||
          normalized == 'ε' ||
          normalized == 'λ' ||
          normalized == 'lambda';
    }

    final dfaStates = <String, State>{};
    final dfaTransitions = <FSATransition>{};
    final dfaAcceptingStates = <State>{};
    final queue = <String>[];
    final processed = <String>{};
    final stateSetMap = <String, Set<State>>{};

    // Start with the epsilon-closure of the initial state
    final initialStateSet = _epsilonClosureFlexible(
      nfa,
      nfa.initialState!,
      isEpsilonSymbol,
    );
    final initialStateKey = _getStateSetKey(initialStateSet);
    final initialState = _createDFAState(initialStateSet, 0);
    dfaStates[initialStateKey] = initialState;
    stateSetMap[initialStateKey] = initialStateSet;
    queue.add(initialStateKey);

    // Process each state set
    int stateCounter = 1;
    const int maxStates = 1000; // Performance safeguard
    while (queue.isNotEmpty) {
      final currentStateKey = queue.removeAt(0);
      if (processed.contains(currentStateKey)) continue;
      processed.add(currentStateKey);

      final currentStateSet = stateSetMap[currentStateKey]!;

      final currentDFAState = dfaStates[currentStateKey]!;

      // Check if this state set contains any accepting states
      if (currentStateSet.intersection(nfa.acceptingStates).isNotEmpty) {
        dfaAcceptingStates.add(currentDFAState);
      }

      // For each symbol in the alphabet (excluding epsilon-like markers)
      final workingAlphabet = nfa.alphabet
          .where((s) => !isEpsilonSymbol(s))
          .toSet();
      for (final symbol in workingAlphabet) {
        final nextStateSet = <State>{};

        // Move on symbol, then take epsilon-closure
        for (final state in currentStateSet) {
          final transitions = nfa
              .getTransitionsFromStateOnSymbol(state, symbol)
              .toList();
          for (final transition in transitions) {
            nextStateSet.addAll(
              _epsilonClosureFlexible(nfa, transition.toState, isEpsilonSymbol),
            );
          }
        }

        if (nextStateSet.isNotEmpty) {
          final nextStateKey = _getStateSetKey(nextStateSet);

          // Create or get the DFA state for this set
          State nextDFAState;
          if (dfaStates.containsKey(nextStateKey)) {
            nextDFAState = dfaStates[nextStateKey]!;
          } else {
            if (stateCounter >= maxStates) {
              throw StateError(
                'Exceeded maximum number of DFA states ($maxStates) during subset construction.',
              );
            }
            nextDFAState = _createDFAState(nextStateSet, stateCounter++);
            dfaStates[nextStateKey] = nextDFAState;
            stateSetMap[nextStateKey] = nextStateSet;
            queue.add(nextStateKey);
          }

          // Add transition
          final transition = FSATransition.deterministic(
            id: 't_${currentDFAState.id}_${symbol}_${nextDFAState.id}',
            fromState: currentDFAState,
            toState: nextDFAState,
            symbol: symbol,
          );
          dfaTransitions.add(transition);
        }
      }
    }

    // Create the DFA
    return FSA(
      id: '${nfa.id}_dfa',
      name: '${nfa.name} (DFA)',
      states: dfaStates.values.toSet(),
      transitions: dfaTransitions,
      alphabet: nfa.alphabet.where((s) => !isEpsilonSymbol(s)).toSet(),
      initialState: initialState,
      acceptingStates: dfaAcceptingStates,
      created: nfa.created,
      modified: DateTime.now(),
      bounds: nfa.bounds,
      zoomLevel: nfa.zoomLevel,
      panOffset: nfa.panOffset,
    );
  }

  /// Creates a string key for a set of states
  static String _getStateSetKey(Set<State> stateSet) {
    final stateIds = stateSet.map((s) => s.id).toList()..sort();
    return stateIds.join(',');
  }

  /// Creates a DFA state from a set of NFA states
  static State _createDFAState(Set<State> stateSet, int counter) {
    final stateIds = stateSet.map((s) => s.id).toList()..sort();
    final stateId = 'q${counter}_${stateIds.join('_')}';
    final stateLabel = '{${stateIds.join(',')}}';

    // Calculate position as center of the states
    double sumX = 0;
    double sumY = 0;
    for (final state in stateSet) {
      sumX += state.position.x;
      sumY += state.position.y;
    }
    final position = Vector2(sumX / stateSet.length, sumY / stateSet.length);

    return State(
      id: stateId,
      label: stateLabel,
      position: position,
      isInitial: counter == 0,
      isAccepting: false, // Will be set later
    );
  }

  /// Converts an NFA to DFA with step-by-step information
  static Result<NFAToDFAConversionResult> convertWithSteps(FSA nfa) {
    try {
      final steps = <NFADFAConversionStep>[];

      // Step 1: Validate input
      steps.add(
        NFADFAConversionStep(
          stepNumber: 1,
          description: 'Validating input NFA',
          nfa: nfa,
          dfa: null,
        ),
      );

      final validationResult = _validateInput(nfa);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Step 2: Build DFA (epsilon-aware subset construction)
      steps.add(
        NFADFAConversionStep(
          stepNumber: 2,
          description: 'Building DFA using epsilon-closure subset construction',
          nfa: nfa,
          dfa: null,
        ),
      );

      final dfa = _buildDFAWithEpsilon(nfa);
      steps.add(
        NFADFAConversionStep(
          stepNumber: 3,
          description: 'DFA construction completed',
          nfa: nfa,
          dfa: dfa,
        ),
      );

      final result = NFAToDFAConversionResult(
        originalNFA: nfa,
        resultDFA: dfa,
        steps: steps,
        executionTime:
            Duration.zero, // Would be calculated in real implementation
      );

      return ResultFactory.success(result);
    } catch (e) {
      return ResultFactory.failure(
        'Error converting NFA to DFA with steps: $e',
      );
    }
  }
}

/// Flexible epsilon-closure that treats both explicit epsilon transitions and
/// any transition whose symbol set contains an epsilon-like marker as epsilon.
Set<State> _epsilonClosureFlexible(
  FSA automaton,
  State start,
  bool Function(String) isEpsilonSymbol,
) {
  final closure = <State>{start};
  final queue = <State>[start];

  while (queue.isNotEmpty) {
    final state = queue.removeAt(0);
    for (final t in automaton.fsaTransitions) {
      final isFrom = t.fromState.id == state.id;
      final isEps =
          t.isEpsilonTransition || t.inputSymbols.any(isEpsilonSymbol);
      if (isFrom && isEps) {
        if (closure.add(t.toState)) {
          queue.add(t.toState);
        }
      }
    }
  }

  return closure;
}

/// Result of NFA to DFA conversion with step-by-step information
class NFAToDFAConversionResult {
  /// Original NFA
  final FSA originalNFA;

  /// Resulting DFA
  final FSA resultDFA;

  /// Conversion steps
  final List<NFADFAConversionStep> steps;

  /// Execution time
  final Duration executionTime;

  const NFAToDFAConversionResult({
    required this.originalNFA,
    required this.resultDFA,
    required this.steps,
    required this.executionTime,
  });

  /// Gets the number of steps
  int get stepCount => steps.length;

  /// Gets the first step
  NFADFAConversionStep? get firstStep => steps.isNotEmpty ? steps.first : null;

  /// Gets the last step
  NFADFAConversionStep? get lastStep => steps.isNotEmpty ? steps.last : null;

  /// Gets the execution time in milliseconds
  int get executionTimeMs => executionTime.inMilliseconds;

  /// Gets the execution time in seconds
  double get executionTimeSeconds => executionTime.inMicroseconds / 1000000.0;
}

/// Single step in NFA to DFA conversion
class NFADFAConversionStep {
  /// Step number
  final int stepNumber;

  /// Description of the step
  final String description;

  /// NFA at this step
  final FSA? nfa;

  /// DFA at this step
  final FSA? dfa;

  const NFADFAConversionStep({
    required this.stepNumber,
    required this.description,
    this.nfa,
    this.dfa,
  });

  @override
  String toString() {
    return 'NFADFAConversionStep(stepNumber: $stepNumber, description: $description)';
  }
}
