import 'dart:collection';

import '../models/pda.dart';
import '../models/state.dart';
import '../models/pda_transition.dart';
import '../models/fsa_transition.dart';
import '../models/simulation_step.dart';
import '../models/transition.dart';
import '../result.dart';

/// Acceptance modes for NPDA simulation
enum PDAAcceptanceMode { finalState, emptyStack, both }

/// Simulates Pushdown Automata (PDA) with input strings
class PDASimulator {
  /// Simulates a DPDA (deterministic) with an input string.
  /// Use [simulateNPDA] for non-deterministic behavior with ε-moves.
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
        return const Failure('Cannot simulate empty PDA');
      }

      // Handle PDA with no initial state
      if (pda.initialState == null) {
        return const Failure('PDA must have an initial state');
      }

      // Simulate as DPDA
      final result = _simulateDPDA(pda, inputString, stepByStep, timeout);
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
      return const Failure('PDA must have at least one state');
    }

    if (pda.initialState == null) {
      return const Failure('PDA must have an initial state');
    }

    if (!pda.states.contains(pda.initialState)) {
      return const Failure('Initial state must be in the states set');
    }

    for (final acceptingState in pda.acceptingStates) {
      if (!pda.states.contains(acceptingState)) {
        return const Failure('Accepting state must be in the states set');
      }
    }

    // Validate input string symbols
    for (int i = 0; i < inputString.length; i++) {
      final symbol = inputString[i];
      if (!pda.alphabet.contains(symbol)) {
        return Failure('Input string contains invalid symbol: $symbol');
      }
    }

    return const Success(null);
  }

  /// Simulates a DPDA with the input string
  static PDASimulationResult _simulateDPDA(
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
    final stack = <String>[pda.initialStackSymbol];
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
        currentState.id,
        symbol,
        stack.isNotEmpty ? stack.last : '',
      );

      if (transition == null) {
        return PDASimulationResult.failure(
          inputString: inputString,
          steps: steps,
          errorMessage:
              'No transition found for symbol $symbol and stack top ${stack.isNotEmpty ? stack.last : "empty"} in state ${currentState.id}',
          executionTime: DateTime.now().difference(startTime),
        );
      }

      // Update stack
      if (transition.stackPop.isNotEmpty) {
        if (stack.isNotEmpty && stack.last == transition.stackPop) {
          stack.removeLast();
        } else {
          return PDASimulationResult.failure(
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
          consumedInput: symbol,
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
    steps.add(SimulationStep.finalStep(
      finalState: currentState.id,
      remainingInput: remainingInput,
      stackContents: stack.join(''),
      tapeContents: '',
      stepNumber: stepNumber + 1,
    ));

    // Check if final state is accepting
    final isAccepted = pda.acceptingStates.contains(currentState);

    if (isAccepted) {
      return PDASimulationResult.success(
        inputString: inputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
      );
    } else {
      return PDASimulationResult.failure(
        inputString: inputString,
        steps: steps,
        errorMessage: 'Input not accepted - final state is not accepting',
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Configuration for NPDA simulation
  static const int defaultMaxBranchingDepth = 1000;
  static const int defaultMaxConfigurations = 100000;

  /// Simulates a (N)PDA with ε-moves and branching. Acceptance modes:
  /// - by final state
  /// - by empty stack
  /// - by both
  static Result<PDASimulationResult> simulateNPDA(
    PDA pda,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
    PDAAcceptanceMode mode = PDAAcceptanceMode.finalState,
    int maxDepth = defaultMaxBranchingDepth,
    int maxConfigurations = defaultMaxConfigurations,
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      final validationResult = _validateInput(pda, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }
      if (pda.initialState == null) {
        return const Failure('PDA must have an initial state');
      }

      final result = _simulateSearch(
        pda,
        inputString,
        stepByStep,
        timeout,
        mode,
        maxDepth,
        maxConfigurations,
      );
      stopwatch.stop();
      return Success(result.copyWith(executionTime: stopwatch.elapsed));
    } catch (e) {
      return Failure('Error simulating NPDA: $e');
    }
  }

  /// Internal NPDA search using BFS over configurations, applying ε-closure.
  static PDASimulationResult _simulateSearch(
    PDA pda,
    String inputString,
    bool stepByStep,
    Duration timeout,
    PDAAcceptanceMode mode,
    int maxDepth,
    int maxConfigurations,
  ) {
    final startTime = DateTime.now();
    int explored = 0;

    // Configuration: (state, remainingInput, stack as list, steps)
    final initialConfig = (
      pda.initialState!,
      inputString,
      <String>[pda.initialStackSymbol],
      <SimulationStep>[
        SimulationStep.initial(
            initialState: pda.initialState!.id, inputString: inputString),
      ],
      0,
    );

    final queue =
        Queue<(State, String, List<String>, List<SimulationStep>, int)>();
    queue.add(initialConfig);

    while (queue.isNotEmpty) {
      if (DateTime.now().difference(startTime) > timeout) {
        return PDASimulationResult.timeout(
          inputString: inputString,
          steps: const [],
          executionTime: DateTime.now().difference(startTime),
        );
      }
      if (explored++ > maxConfigurations) {
        return PDASimulationResult.infiniteLoop(
          inputString: inputString,
          steps: const [],
          executionTime: DateTime.now().difference(startTime),
        );
      }

      final (state, remaining, stack, steps, depth) = queue.removeFirst();

      // Acceptance checks
      final isFinalOk = pda.acceptingStates.contains(state);
      final isEmptyStackOk =
          stack.isEmpty || (stack.length == 1 && stack.last.isEmpty);
      final inputConsumed = remaining.isEmpty;

      bool accepted = false;
      switch (mode) {
        case PDAAcceptanceMode.finalState:
          accepted = inputConsumed && isFinalOk;
          break;
        case PDAAcceptanceMode.emptyStack:
          accepted = inputConsumed && isEmptyStackOk;
          break;
        case PDAAcceptanceMode.both:
          accepted = inputConsumed && isFinalOk && isEmptyStackOk;
          break;
      }
      if (accepted) {
        final finalSteps = List<SimulationStep>.from(steps)
          ..add(SimulationStep.finalStep(
            finalState: state.id,
            remainingInput: remaining,
            stackContents: stack.join(''),
            tapeContents: '',
            stepNumber: (steps.isNotEmpty ? steps.last.stepNumber : 0) + 1,
          ));
        return PDASimulationResult.success(
          inputString: inputString,
          steps: finalSteps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      if (depth >= maxDepth) {
        // Depth bound reached; continue exploring siblings
        continue;
      }

      // Generate ε-moves first (no input consumption)
      for (final t in pda.getEpsilonTransitionsFromState(state)) {
        final canPop =
            t.isLambdaPop || (stack.isNotEmpty && stack.last == t.popSymbol);
        if (!canPop) continue;
        final newStack = List<String>.from(stack);
        if (!t.isLambdaPop && newStack.isNotEmpty) {
          newStack.removeLast();
        }
        if (!t.isLambdaPush && t.pushSymbol.isNotEmpty) {
          newStack.add(t.pushSymbol);
        }
        final step = SimulationStep.pda(
          currentState: state.id,
          remainingInput: remaining,
          stackContents: newStack.join(''),
          usedTransition:
              'ε,${t.isLambdaPop ? 'ε' : t.popSymbol}→${t.isLambdaPush ? 'ε' : t.pushSymbol}',
          stepNumber: (steps.isNotEmpty ? steps.last.stepNumber : 0) + 1,
          consumedInput: '',
        );
        queue
            .add((t.toState, remaining, newStack, [...steps, step], depth + 1));
      }

      // Generate input-consuming moves if input remains
      if (remaining.isNotEmpty) {
        final a = remaining[0];
        for (final t in pda.getTransitionsFromStateOnInputAndStack(
            state, a, stack.isNotEmpty ? stack.last : '')) {
          final newStack = List<String>.from(stack);
          if (!t.isLambdaPop && newStack.isNotEmpty) {
            newStack.removeLast();
          }
          if (!t.isLambdaPush && t.pushSymbol.isNotEmpty) {
            newStack.add(t.pushSymbol);
          }
          final newRemaining = remaining.substring(1);
          final step = SimulationStep.pda(
            currentState: state.id,
            remainingInput: newRemaining,
            stackContents: newStack.join(''),
            usedTransition:
                '$a,${t.isLambdaPop ? 'ε' : t.popSymbol}→${t.isLambdaPush ? 'ε' : t.pushSymbol}',
            stepNumber: (steps.isNotEmpty ? steps.last.stepNumber : 0) + 1,
            consumedInput: a,
          );
          queue.add(
              (t.toState, newRemaining, newStack, [...steps, step], depth + 1));
        }
      }
    }

    return PDASimulationResult.failure(
      inputString: inputString,
      steps: const [],
      errorMessage: 'Rejected: no accepting configuration found',
      executionTime: DateTime.now().difference(startTime),
    );
  }

  /// Produces a simplified PDA by pruning unreachable/nonproductive states
  /// and merging obviously equivalent configurations.
  static Result<PDASimplificationSummary> simplify(PDA pda) {
    if (pda.states.isEmpty) {
      return const Failure('Cannot minimize an empty PDA.');
    }

    final initialState = pda.initialState;
    if (initialState == null) {
      return const Failure('PDA must define an initial state before minimization.');
    }

    if (pda.acceptingStates.isEmpty) {
      return const Failure('PDA must define at least one accepting state.');
    }

    final reachableStates = <State>{};
    _findReachableStates(pda, initialState, reachableStates);

    final productiveStates = _findProductiveStates(pda);

    final usefulStates = reachableStates.intersection(productiveStates);
    if (usefulStates.isEmpty) {
      return const Failure(
        'Initial state cannot reach any accepting configuration. '
        'Add transitions that lead to an accepting state before minimization.',
      );
    }

    final unreachableStates = pda.states.difference(reachableStates);
    final nonProductiveStates = pda.states.difference(productiveStates);

    final usefulStateIds = usefulStates.map((s) => s.id).toSet();

    final filteredStates =
        pda.states.where((s) => usefulStateIds.contains(s.id)).toSet();
    final prunedStates = pda.states.difference(filteredStates);

    final filteredTransitions = pda.pdaTransitions
        .where(
          (transition) =>
              usefulStateIds.contains(transition.fromState.id) &&
              usefulStateIds.contains(transition.toState.id),
        )
        .toList();

    final removedTransitionsFromPruning = pda.pdaTransitions
        .where(
          (transition) =>
              !usefulStateIds.contains(transition.fromState.id) ||
              !usefulStateIds.contains(transition.toState.id),
        )
        .map((transition) => transition.id)
        .toSet();

    final canonicalStateMap = {
      for (final state in filteredStates) state.id: state
    };

    final mergeTargets = <String, String>{};
    final signatureOwners = <String, String>{};
    final sortedStates = filteredStates.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final state in sortedStates) {
      final signature = _stateSignature(
          state, filteredTransitions, mergeTargets, canonicalStateMap);
      final owner = signatureOwners[signature];
      if (owner != null && owner != state.id) {
        mergeTargets[state.id] = owner;
      } else {
        signatureOwners[signature] = state.id;
      }
    }

    final mergeGroups = <PDAMergeGroup>[];
    final removedStatesFromMerging = <State>{};

    final groupedMerges = <String, Set<State>>{};
    mergeTargets.forEach((stateId, targetId) {
      final mergedState = canonicalStateMap[stateId];
      final targetState = canonicalStateMap[targetId];
      if (mergedState == null || targetState == null) {
        return;
      }
      groupedMerges.putIfAbsent(targetId, () => <State>{}).add(mergedState);
      removedStatesFromMerging.add(mergedState);
    });

    groupedMerges.forEach((targetId, mergedStates) {
      final representative = canonicalStateMap[targetId];
      if (representative != null) {
        mergeGroups.add(PDAMergeGroup(
            representative: representative, mergedStates: mergedStates));
      }
    });

    final canonicalStates = <String, State>{};
    for (final state in sortedStates) {
      final targetId = mergeTargets[state.id] ?? state.id;
      final representative = canonicalStateMap[targetId];
      if (representative != null) {
        canonicalStates[targetId] = representative;
      }
    }

    final canonicalTransitions = <String, PDATransition>{};
    final duplicateTransitionIds = <String>{};

    for (final transition in filteredTransitions) {
      final canonicalFromId =
          mergeTargets[transition.fromState.id] ?? transition.fromState.id;
      final canonicalToId =
          mergeTargets[transition.toState.id] ?? transition.toState.id;

      final canonicalFrom = canonicalStates[canonicalFromId];
      final canonicalTo = canonicalStates[canonicalToId];
      if (canonicalFrom == null || canonicalTo == null) {
        continue;
      }

      final canonicalTransition = transition.copyWith(
        fromState: canonicalFrom,
        toState: canonicalTo,
      );

      final key = _transitionKey(canonicalTransition);
      if (canonicalTransitions.containsKey(key)) {
        duplicateTransitionIds.add(transition.id);
      } else {
        canonicalTransitions[key] = canonicalTransition;
      }
    }

    final finalTransitions = canonicalTransitions.values.toSet();
    final removedTransitions = <String>{}
      ..addAll(removedTransitionsFromPruning)
      ..addAll(duplicateTransitionIds);

    final finalStates = canonicalStates.values.toSet();
    final finalAcceptingStates =
        finalStates.where((state) => state.isAccepting).toSet();
    if (finalAcceptingStates.isEmpty) {
      return const Failure(
        'Minimization removed all accepting states. Ensure at least one accepting state is reachable before retrying.',
      );
    }

    final canonicalInitialId = mergeTargets[initialState.id] ?? initialState.id;
    final finalInitialState = canonicalStates[canonicalInitialId];
    if (finalInitialState == null) {
      return const Failure('Initial state became invalid after simplification.');
    }

    final recomputedAlphabet = <String>{};
    final recomputedStackAlphabet = <String>{};
    for (final transition in finalTransitions) {
      if (!transition.isLambdaInput && transition.inputSymbol.isNotEmpty) {
        recomputedAlphabet.add(transition.inputSymbol);
      }
      if (!transition.isLambdaPop && transition.popSymbol.isNotEmpty) {
        recomputedStackAlphabet.add(transition.popSymbol);
      }
      if (!transition.isLambdaPush && transition.pushSymbol.isNotEmpty) {
        recomputedStackAlphabet.add(transition.pushSymbol);
      }
    }

    if (recomputedStackAlphabet.isEmpty) {
      recomputedStackAlphabet.add(pda.initialStackSymbol);
    } else if (!recomputedStackAlphabet.contains(pda.initialStackSymbol)) {
      recomputedStackAlphabet.add(pda.initialStackSymbol);
    }

    final minimizedPda = pda.copyWith(
      states: finalStates,
      transitions:
          finalTransitions.map<Transition>((transition) => transition).toSet(),
      alphabet: recomputedAlphabet.isEmpty ? pda.alphabet : recomputedAlphabet,
      initialState: finalInitialState,
      acceptingStates: finalAcceptingStates,
      stackAlphabet: recomputedStackAlphabet,
      modified: DateTime.now(),
    );

    final removedStates = <State>{}
      ..addAll(prunedStates)
      ..addAll(removedStatesFromMerging);

    final summary = PDASimplificationSummary(
      minimizedPda: minimizedPda,
      removedStates: removedStates,
      unreachableStates: unreachableStates,
      nonProductiveStates: nonProductiveStates,
      removedTransitionIds: removedTransitions,
      mergeGroups: mergeGroups,
      changed: removedStates.isNotEmpty || removedTransitions.isNotEmpty,
      warnings: const [],
    );

    return Success(summary);
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
      for (int length = 0;
          length <= maxLength && acceptedStrings.length < maxResults;
          length++) {
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
      for (int length = 0;
          length <= maxLength && rejectedStrings.length < maxResults;
          length++) {
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
        return const Failure('Cannot analyze empty PDA');
      }

      // Handle PDA with no initial state
      if (pda.initialState == null) {
        return const Failure('PDA must have an initial state');
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
  static PDAStateAnalysis _analyzeStates(PDA pda) {
    final totalStates = pda.states.length;
    final acceptingStates = pda.acceptingStates.length;
    final nonAcceptingStates = totalStates - acceptingStates;

    return PDAStateAnalysis(
      totalStates: totalStates,
      acceptingStates: acceptingStates,
      nonAcceptingStates: nonAcceptingStates,
    );
  }

  /// Analyzes the transitions of the PDA
  static PDATransitionAnalysis _analyzeTransitions(PDA pda) {
    final totalTransitions = pda.transitions.length;
    final pdaTransitions = pda.transitions.whereType<PDATransition>().length;
    final fsaTransitions = pda.transitions.whereType<FSATransition>().length;

    return PDATransitionAnalysis(
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
  static PDAReachabilityAnalysis _analyzeReachability(PDA pda) {
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

    return PDAReachabilityAnalysis(
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

  /// Finds all states that can eventually reach an accepting state.
  static Set<State> _findProductiveStates(PDA pda) {
    final productiveStates = <State>{};
    final workQueue = Queue<State>();

    for (final accepting in pda.acceptingStates) {
      if (productiveStates.add(accepting)) {
        workQueue.add(accepting);
      }
    }

    while (workQueue.isNotEmpty) {
      final current = workQueue.removeFirst();
      for (final transition in pda.pdaTransitions) {
        if (transition.toState == current) {
          if (productiveStates.add(transition.fromState)) {
            workQueue.add(transition.fromState);
          }
        }
      }
    }

    return productiveStates;
  }

  static String _stateSignature(
    State state,
    List<PDATransition> transitions,
    Map<String, String> mergeTargets,
    Map<String, State> canonicalStateMap,
  ) {
    final outgoing = transitions
        .where((transition) => transition.fromState.id == state.id)
        .map((transition) {
      final canonicalToId =
          mergeTargets[transition.toState.id] ?? transition.toState.id;
      final canonicalTo = canonicalStateMap[canonicalToId];
      final toId = canonicalTo?.id ?? canonicalToId;
      final input = transition.isLambdaInput ? 'λ' : transition.inputSymbol;
      final pop = transition.isLambdaPop ? 'λ' : transition.popSymbol;
      final push = transition.isLambdaPush ? 'λ' : transition.pushSymbol;
      return '$toId|$input|$pop|$push';
    }).toList()
      ..sort();

    return '${state.isInitial}|${state.isAccepting}|${outgoing.join(';')}';
  }

  static String _transitionKey(PDATransition transition) {
    final input = transition.isLambdaInput ? 'λ' : transition.inputSymbol;
    final pop = transition.isLambdaPop ? 'λ' : transition.popSymbol;
    final push = transition.isLambdaPush ? 'λ' : transition.pushSymbol;
    return '${transition.fromState.id}|${transition.toState.id}|$input|$pop|$push';
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

  factory PDASimulationResult.success({
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

  factory PDASimulationResult.failure({
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
  final PDAStateAnalysis stateAnalysis;
  final PDATransitionAnalysis transitionAnalysis;
  final StackAnalysis stackAnalysis;
  final PDAReachabilityAnalysis reachabilityAnalysis;
  final Duration executionTime;

  const PDAAnalysis({
    required this.stateAnalysis,
    required this.transitionAnalysis,
    required this.stackAnalysis,
    required this.reachabilityAnalysis,
    required this.executionTime,
  });

  PDAAnalysis copyWith({
    PDAStateAnalysis? stateAnalysis,
    PDATransitionAnalysis? transitionAnalysis,
    StackAnalysis? stackAnalysis,
    PDAReachabilityAnalysis? reachabilityAnalysis,
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

/// Summary of the PDA simplification step.
class PDASimplificationSummary {
  final PDA minimizedPda;
  final Set<State> removedStates;
  final Set<State> unreachableStates;
  final Set<State> nonProductiveStates;
  final Set<String> removedTransitionIds;
  final List<PDAMergeGroup> mergeGroups;
  final bool changed;
  final List<String> warnings;

  const PDASimplificationSummary({
    required this.minimizedPda,
    required this.removedStates,
    required this.unreachableStates,
    required this.nonProductiveStates,
    required this.removedTransitionIds,
    required this.mergeGroups,
    required this.changed,
    required this.warnings,
  });

  bool get hasMerges =>
      mergeGroups.any((group) => group.mergedStates.isNotEmpty);
}

/// Represents a group of states merged into a representative state.
class PDAMergeGroup {
  final State representative;
  final Set<State> mergedStates;

  const PDAMergeGroup({
    required this.representative,
    required this.mergedStates,
  });

  bool get isMeaningful => mergedStates.isNotEmpty;
}
