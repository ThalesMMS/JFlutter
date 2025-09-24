import 'dart:collection';

import '../models/pda.dart';
import '../models/state.dart';
import '../models/pda_transition.dart';
import '../models/fsa_transition.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';
import '../models/transition.dart';
import '../result.dart';

/// Simulates Pushdown Automata (PDA) with input strings
class PDASimulator {
  /// Simulates a PDA with an input string
  static Result<PDASimulationResult> simulate(
    PDA pda,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
    int maxAcceptedPaths = 5,
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
      final result = _simulatePDA(
        pda,
        inputString,
        stepByStep,
        timeout,
        maxAcceptedPaths,
      );
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
    int maxAcceptedPaths,
  ) {
    final startTime = DateTime.now();
    final initialState = pda.initialState!;
    final initialStack = <String>[pda.initialStackSymbol];
    final initialSteps = <SimulationStep>[
      SimulationStep.initial(
        initialState: initialState.id,
        inputString: inputString,
        initialStackSymbol: _formatStack(initialStack),
      ),
    ];

    final initialConfiguration = _PDAConfiguration(
      state: initialState,
      remainingInput: inputString,
      stack: initialStack,
      steps: initialSteps,
      stepCount: 0,
    );

    final queue = Queue<_PDAConfiguration>()..add(initialConfiguration);
    final visited = <String>{};
    _PDAConfiguration? lastExplored;
    final acceptedBranches = <PDASimulationWitness>[];
    bool truncatedBranches = false;
    final determinismConflicts = _detectDeterministicConflicts(pda);
    final bool deterministic = determinismConflicts.isEmpty;

    while (queue.isNotEmpty) {
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed > timeout) {
        final timedConfiguration = lastExplored ?? initialConfiguration;
        final timeoutSteps = _buildTerminalSteps(
          timedConfiguration,
          description: 'Simulation timed out before exploring all configurations',
          accepted: false,
        );
        return PDASimulationResult.timeout(
          inputString: inputString,
          steps: timeoutSteps,
          executionTime: elapsed,
          acceptanceMode: pda.acceptanceMode,
          acceptedBranches: acceptedBranches,
          determinismConflicts: determinismConflicts,
          branchesTruncated: truncatedBranches,
        );
      }

      final configuration = queue.removeFirst();
      lastExplored = configuration;

      final configurationKey = _configurationKey(
        configuration.state.id,
        configuration.remainingInput,
        configuration.stack,
      );

      if (!visited.add(configurationKey)) {
        continue;
      }

      final satisfiedCriteria =
          _satisfiedAcceptanceCriteria(pda, configuration);
      if (_isAcceptingConfiguration(pda, satisfiedCriteria)) {
        final branchSteps = _buildAcceptanceSteps(
          configuration,
          satisfiedCriteria,
        );

        acceptedBranches.add(
          PDASimulationWitness(
            steps: branchSteps,
            criteria: satisfiedCriteria,
          ),
        );

        if (deterministic) {
          break;
        }

        if (acceptedBranches.length >= maxAcceptedPaths) {
          truncatedBranches = queue.isNotEmpty;
          break;
        }

        // No need to expand successors for an accepting configuration.
        continue;
      }

      if (configuration.stepCount >= 1000) {
        continue;
      }

      final enabledTransitions = _availableTransitions(pda, configuration);
      for (final transition in enabledTransitions) {
        final nextConfiguration =
            _advanceConfiguration(configuration, transition, stepByStep);
        if (nextConfiguration == null) {
          continue;
        }

        final nextKey = _configurationKey(
          nextConfiguration.state.id,
          nextConfiguration.remainingInput,
          nextConfiguration.stack,
        );

        if (nextKey == configurationKey) {
          continue;
        }

        queue.add(nextConfiguration);
      }
    }

    final elapsed = DateTime.now().difference(startTime);

    if (acceptedBranches.isNotEmpty) {
      final representativeSteps = acceptedBranches.first.steps.toList();
      return PDASimulationResult.success(
        inputString: inputString,
        steps: representativeSteps,
        executionTime: elapsed,
        acceptanceMode: pda.acceptanceMode,
        acceptedBranches: acceptedBranches,
        determinismConflicts: determinismConflicts,
        branchesTruncated: truncatedBranches,
      );
    }

    final failureConfiguration = lastExplored ?? initialConfiguration;
    final failureSteps = _buildTerminalSteps(
      failureConfiguration,
      description: 'Input not accepted - no accepting configuration found',
      accepted: false,
    );

    return PDASimulationResult.failure(
      inputString: inputString,
      steps: failureSteps,
      errorMessage: 'Input not accepted - no accepting configuration found',
      executionTime: elapsed,
      acceptanceMode: pda.acceptanceMode,
      acceptedBranches: acceptedBranches,
      determinismConflicts: determinismConflicts,
      branchesTruncated: truncatedBranches,
    );
  }

  static Iterable<PDATransition> _availableTransitions(
    PDA pda,
    _PDAConfiguration configuration,
  ) sync* {
    for (final transition in pda.pdaTransitions) {
      if (transition.fromState != configuration.state) {
        continue;
      }

      final requiresPop =
          !(transition.isLambdaPop || transition.popSymbol.isEmpty);
      if (requiresPop) {
        if (configuration.stack.isEmpty) {
          continue;
        }
        if (configuration.stack.last != transition.popSymbol) {
          continue;
        }
      }

      final consumesInput =
          !(transition.isLambdaInput || transition.inputSymbol.isEmpty);
      if (consumesInput) {
        if (!configuration.remainingInput.startsWith(transition.inputSymbol)) {
          continue;
        }
      }

      yield transition;
    }
  }

  static _PDAConfiguration? _advanceConfiguration(
    _PDAConfiguration configuration,
    PDATransition transition,
    bool stepByStep,
  ) {
    final nextStack = List<String>.from(configuration.stack);

    final requiresPop =
        !(transition.isLambdaPop || transition.popSymbol.isEmpty);
    if (requiresPop) {
      if (nextStack.isEmpty || nextStack.last != transition.popSymbol) {
        return null;
      }
      nextStack.removeLast();
    }

    final pushSymbols = _extractPushSymbols(transition);
    for (final symbol in pushSymbols) {
      if (symbol.isEmpty) {
        continue;
      }
      if (symbol == 'ε' || symbol == 'λ') {
        continue;
      }
      nextStack.add(symbol);
    }

    final consumesInput =
        !(transition.isLambdaInput || transition.inputSymbol.isEmpty);
    final nextRemainingInput = consumesInput
        ? configuration.remainingInput.substring(transition.inputSymbol.length)
        : configuration.remainingInput;

    final consumedInput = consumesInput ? transition.inputSymbol : '';

    final nextSteps = List<SimulationStep>.from(configuration.steps);
    if (stepByStep) {
      nextSteps.add(
        SimulationStep.pda(
          currentState: transition.toState.id,
          remainingInput: nextRemainingInput,
          stackContents: _formatStack(nextStack),
          usedTransition: transition.id,
          stepNumber: configuration.stepCount + 1,
          consumedInput: consumedInput,
        ),
      );
    }

    return _PDAConfiguration(
      state: transition.toState,
      remainingInput: nextRemainingInput,
      stack: nextStack,
      steps: nextSteps,
      stepCount: configuration.stepCount + 1,
    );
  }

  static Set<PDAAcceptanceCriterion> _satisfiedAcceptanceCriteria(
    PDA pda,
    _PDAConfiguration configuration,
  ) {
    final satisfied = <PDAAcceptanceCriterion>{};
    final consumedAllInput = configuration.remainingInput.isEmpty;

    if (consumedAllInput && pda.acceptingStates.contains(configuration.state)) {
      satisfied.add(PDAAcceptanceCriterion.finalState);
    }

    if (consumedAllInput && configuration.stack.isEmpty) {
      satisfied.add(PDAAcceptanceCriterion.emptyStack);
    }

    return satisfied;
  }

  static bool _isAcceptingConfiguration(
    PDA pda,
    Set<PDAAcceptanceCriterion> satisfiedCriteria,
  ) {
    if (satisfiedCriteria.isEmpty) {
      return false;
    }

    switch (pda.acceptanceMode) {
      case PDAAcceptanceMode.finalState:
        return satisfiedCriteria.contains(PDAAcceptanceCriterion.finalState);
      case PDAAcceptanceMode.emptyStack:
        return satisfiedCriteria.contains(PDAAcceptanceCriterion.emptyStack);
      case PDAAcceptanceMode.either:
        return satisfiedCriteria.isNotEmpty;
      case PDAAcceptanceMode.both:
        return satisfiedCriteria.contains(PDAAcceptanceCriterion.finalState) &&
            satisfiedCriteria.contains(PDAAcceptanceCriterion.emptyStack);
    }
  }

  static List<SimulationStep> _buildAcceptanceSteps(
    _PDAConfiguration configuration,
    Set<PDAAcceptanceCriterion> criteria,
  ) {
    final description = _acceptanceDescription(criteria);
    return _buildTerminalSteps(
      configuration,
      description: description,
      accepted: true,
    );
  }

  static List<SimulationStep> _buildTerminalSteps(
    _PDAConfiguration configuration, {
    required String description,
    required bool accepted,
  }) {
    final steps = List<SimulationStep>.from(configuration.steps);
    final terminalStep = SimulationStep.finalStep(
      finalState: configuration.state.id,
      remainingInput: configuration.remainingInput,
      stackContents: _formatStack(configuration.stack),
      tapeContents: '',
      stepNumber: configuration.stepCount + 1,
    ).copyWith(
      description: description,
      isAccepted: accepted,
    );

    steps.add(terminalStep);
    return steps;
  }

  static String _acceptanceDescription(Set<PDAAcceptanceCriterion> criteria) {
    final acceptsFinalState = criteria.contains(PDAAcceptanceCriterion.finalState);
    final acceptsEmptyStack = criteria.contains(PDAAcceptanceCriterion.emptyStack);

    if (acceptsFinalState && acceptsEmptyStack) {
      return 'Accepted: reached accepting state with empty stack';
    }
    if (acceptsFinalState) {
      return 'Accepted: reached accepting state';
    }
    if (acceptsEmptyStack) {
      return 'Accepted: stack emptied';
    }
    return 'Accepted';
  }

  static List<PDADeterminismConflict> _detectDeterministicConflicts(PDA pda) {
    final conflicts = <PDADeterminismConflict>[];
    final groupedByKey = <String, List<PDATransition>>{};
    final lambdaByStack = <String, List<PDATransition>>{};

    for (final transition in pda.pdaTransitions) {
      final inputKey =
          transition.isLambdaInput || transition.inputSymbol.isEmpty ? 'λ' : transition.inputSymbol;
      final popKey =
          transition.isLambdaPop || transition.popSymbol.isEmpty ? 'λ' : transition.popSymbol;
      final groupKey = '${transition.fromState.id}::$inputKey::$popKey';
      groupedByKey.putIfAbsent(groupKey, () => <PDATransition>[]).add(transition);

      if (inputKey == 'λ') {
        final stackKey = '${transition.fromState.id}::$popKey';
        lambdaByStack.putIfAbsent(stackKey, () => <PDATransition>[]).add(transition);
      }
    }

    groupedByKey.forEach((key, transitions) {
      if (transitions.length <= 1) {
        return;
      }

      final parts = key.split('::');
      conflicts.add(
        PDADeterminismConflict(
          stateId: parts[0],
          inputSymbol: parts[1],
          stackSymbol: parts[2],
          transitionIds: transitions.map((transition) => transition.id).toList(),
        ),
      );
    });

    final processedLambdaKeys = <String>{};
    lambdaByStack.forEach((key, lambdaTransitions) {
      final parts = key.split('::');
      final stateId = parts[0];
      final stackSymbol = parts[1];

      final competingTransitions = pda.pdaTransitions.where((transition) {
        final popKey =
            transition.isLambdaPop || transition.popSymbol.isEmpty ? 'λ' : transition.popSymbol;
        if ('${transition.fromState.id}::$popKey' != key) {
          return false;
        }
        return !(transition.isLambdaInput || transition.inputSymbol.isEmpty);
      }).toList();

      if (competingTransitions.isEmpty) {
        return;
      }

      final conflictKey = '$stateId::λ::$stackSymbol';
      if (processedLambdaKeys.contains(conflictKey)) {
        return;
      }
      processedLambdaKeys.add(conflictKey);

      final transitionIds = <String>[
        ...lambdaTransitions.map((transition) => transition.id),
        ...competingTransitions.map((transition) => transition.id),
      ];

      conflicts.add(
        PDADeterminismConflict(
          stateId: stateId,
          inputSymbol: 'λ',
          stackSymbol: stackSymbol,
          transitionIds: transitionIds,
        ),
      );
    });

    return conflicts;
  }

  static List<String> _extractPushSymbols(PDATransition transition) {
    if (transition.isLambdaPush || transition.pushSymbol.isEmpty) {
      return const [];
    }

    final trimmed = transition.pushSymbol.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    return trimmed.split(RegExp(r'\s+'));
  }

  static String _formatStack(Iterable<String> stack) {
    if (stack.isEmpty) {
      return 'ε';
    }
    return stack.join(' ');
  }

  static String _configurationKey(
    String stateId,
    String remainingInput,
    Iterable<String> stack,
  ) {
    final buffer = StringBuffer(stateId)
      ..write('::')
      ..write(remainingInput)
      ..write('::')
      ..writeAll(stack, '|');
    return buffer.toString();
  }

  /// Produces a simplified PDA by pruning unreachable/nonproductive states
  /// and merging obviously equivalent configurations.
  static Result<PDASimplificationSummary> simplify(PDA pda) {
    if (pda.states.isEmpty) {
      return Failure('Cannot minimize an empty PDA.');
    }

    final initialState = pda.initialState;
    if (initialState == null) {
      return Failure('PDA must define an initial state before minimization.');
    }

    if (pda.acceptingStates.isEmpty) {
      return Failure('PDA must define at least one accepting state.');
    }

    final reachableStates = <State>{};
    _findReachableStates(pda, initialState, reachableStates);

    final productiveStates = _findProductiveStates(pda);

    final usefulStates = reachableStates.intersection(productiveStates);
    if (usefulStates.isEmpty) {
      return Failure(
        'Initial state cannot reach any accepting configuration. '
        'Add transitions that lead to an accepting state before minimization.',
      );
    }

    final unreachableStates = pda.states.difference(reachableStates);
    final nonProductiveStates = pda.states.difference(productiveStates);

    final usefulStateIds = usefulStates.map((s) => s.id).toSet();

    final filteredStates = pda.states.where((s) => usefulStateIds.contains(s.id)).toSet();
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

    final canonicalStateMap = {for (final state in filteredStates) state.id: state};

    final mergeTargets = <String, String>{};
    final signatureOwners = <String, String>{};
    final sortedStates = filteredStates.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final state in sortedStates) {
      final signature = _stateSignature(state, filteredTransitions, mergeTargets, canonicalStateMap);
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
        mergeGroups.add(PDAMergeGroup(representative: representative, mergedStates: mergedStates));
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
      final canonicalFromId = mergeTargets[transition.fromState.id] ?? transition.fromState.id;
      final canonicalToId = mergeTargets[transition.toState.id] ?? transition.toState.id;

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
    final finalAcceptingStates = finalStates.where((state) => state.isAccepting).toSet();
    if (finalAcceptingStates.isEmpty) {
      return Failure(
        'Minimization removed all accepting states. Ensure at least one accepting state is reachable before retrying.',
      );
    }

    final canonicalInitialId = mergeTargets[initialState.id] ?? initialState.id;
    final finalInitialState = canonicalStates[canonicalInitialId];
    if (finalInitialState == null) {
      return Failure('Initial state became invalid after simplification.');
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
      transitions: finalTransitions.map<Transition>((transition) => transition).toSet(),
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
      final canonicalToId = mergeTargets[transition.toState.id] ?? transition.toState.id;
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

enum PDAAcceptanceCriterion {
  finalState,
  emptyStack,
}

class _PDAConfiguration {
  final State state;
  final String remainingInput;
  final UnmodifiableListView<String> stack;
  final UnmodifiableListView<SimulationStep> steps;
  final int stepCount;

  _PDAConfiguration({
    required this.state,
    required this.remainingInput,
    required List<String> stack,
    required List<SimulationStep> steps,
    required this.stepCount,
  })  : stack = UnmodifiableListView(stack),
        steps = UnmodifiableListView(steps);
}

class PDASimulationWitness {
  final UnmodifiableListView<SimulationStep> steps;
  final UnmodifiableSetView<PDAAcceptanceCriterion> criteria;

  PDASimulationWitness({
    required List<SimulationStep> steps,
    required Set<PDAAcceptanceCriterion> criteria,
  })  : steps = UnmodifiableListView(steps),
        criteria = UnmodifiableSetView(criteria);

  bool get acceptedByFinalState => criteria.contains(PDAAcceptanceCriterion.finalState);
  bool get acceptedByEmptyStack => criteria.contains(PDAAcceptanceCriterion.emptyStack);
}

class PDADeterminismConflict {
  final String stateId;
  final String inputSymbol;
  final String stackSymbol;
  final UnmodifiableListView<String> transitionIds;

  PDADeterminismConflict({
    required this.stateId,
    required this.inputSymbol,
    required this.stackSymbol,
    required List<String> transitionIds,
  }) : transitionIds = UnmodifiableListView(transitionIds);

  bool get involvesLambdaInput => inputSymbol == 'λ';
  bool get involvesLambdaPop => stackSymbol == 'λ';
}

/// Result of simulating a PDA
class PDASimulationResult {
  final String inputString;
  final bool accepted;
  final UnmodifiableListView<SimulationStep> steps;
  final String? errorMessage;
  final Duration executionTime;
  final PDAAcceptanceMode acceptanceMode;
  final UnmodifiableListView<PDASimulationWitness> acceptedBranches;
  final bool branchesTruncated;
  final UnmodifiableListView<PDADeterminismConflict> determinismConflicts;

  bool get isDeterministic => determinismConflicts.isEmpty;
  bool get hasMultipleAcceptingBranches => acceptedBranches.length > 1;

  PDASimulationResult._({
    required this.inputString,
    required this.accepted,
    required List<SimulationStep> steps,
    this.errorMessage,
    required this.executionTime,
    required this.acceptanceMode,
    List<PDASimulationWitness>? acceptedBranches,
    List<PDADeterminismConflict>? determinismConflicts,
    this.branchesTruncated = false,
  })  : steps = UnmodifiableListView(steps),
        acceptedBranches =
            UnmodifiableListView(acceptedBranches ?? const <PDASimulationWitness>[]),
        determinismConflicts =
            UnmodifiableListView(determinismConflicts ?? const <PDADeterminismConflict>[]);

  factory PDASimulationResult.success({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
    required PDAAcceptanceMode acceptanceMode,
    List<PDASimulationWitness>? acceptedBranches,
    List<PDADeterminismConflict>? determinismConflicts,
    bool branchesTruncated = false,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: true,
      steps: steps,
      executionTime: executionTime,
      acceptanceMode: acceptanceMode,
      acceptedBranches: acceptedBranches,
      determinismConflicts: determinismConflicts,
      branchesTruncated: branchesTruncated,
    );
  }

  factory PDASimulationResult.failure({
    required String inputString,
    required List<SimulationStep> steps,
    required String errorMessage,
    required Duration executionTime,
    required PDAAcceptanceMode acceptanceMode,
    List<PDASimulationWitness>? acceptedBranches,
    List<PDADeterminismConflict>? determinismConflicts,
    bool branchesTruncated = false,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: errorMessage,
      executionTime: executionTime,
      acceptanceMode: acceptanceMode,
      acceptedBranches: acceptedBranches,
      determinismConflicts: determinismConflicts,
      branchesTruncated: branchesTruncated,
    );
  }

  factory PDASimulationResult.timeout({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
    required PDAAcceptanceMode acceptanceMode,
    List<PDASimulationWitness>? acceptedBranches,
    List<PDADeterminismConflict>? determinismConflicts,
    bool branchesTruncated = false,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: 'Simulation timed out',
      executionTime: executionTime,
      acceptanceMode: acceptanceMode,
      acceptedBranches: acceptedBranches,
      determinismConflicts: determinismConflicts,
      branchesTruncated: branchesTruncated,
    );
  }

  factory PDASimulationResult.infiniteLoop({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
    required PDAAcceptanceMode acceptanceMode,
    List<PDASimulationWitness>? acceptedBranches,
    List<PDADeterminismConflict>? determinismConflicts,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      errorMessage: 'Infinite loop detected',
      executionTime: executionTime,
      acceptanceMode: acceptanceMode,
      acceptedBranches: acceptedBranches,
      determinismConflicts: determinismConflicts,
    );
  }

  PDASimulationResult copyWith({
    String? inputString,
    bool? accepted,
    List<SimulationStep>? updatedSteps,
    String? errorMessage,
    Duration? executionTime,
    PDAAcceptanceMode? acceptanceMode,
    List<PDASimulationWitness>? updatedAcceptedBranches,
    bool? branchesTruncated,
    List<PDADeterminismConflict>? updatedDeterminismConflicts,
  }) {
    return PDASimulationResult._(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      steps: updatedSteps ?? this.steps.toList(),
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
      acceptanceMode: acceptanceMode ?? this.acceptanceMode,
      acceptedBranches: updatedAcceptedBranches ?? this.acceptedBranches.toList(),
      branchesTruncated: branchesTruncated ?? this.branchesTruncated,
      determinismConflicts:
          updatedDeterminismConflicts ?? this.determinismConflicts.toList(),
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

  bool get hasMerges => mergeGroups.any((group) => group.mergedStates.isNotEmpty);
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
