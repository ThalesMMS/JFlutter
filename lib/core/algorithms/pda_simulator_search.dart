part of 'pda_simulator.dart';

/// Applies a PDA transition's stack operations to a copy of [stack].
///
/// Returns the updated stack, or `null` if the pop operation cannot be applied.
List<String>? _applyTransitionStack(
  PDATransition t,
  List<String> stack,
) {
  final lambdaPop = t.isLambdaPop || t.popSymbol.isEmpty;
  final lambdaPush = t.isLambdaPush || t.pushSymbol.isEmpty;
  final canPop = lambdaPop || (stack.isNotEmpty && stack.last == t.popSymbol);
  if (!canPop) return null;

  final newStack = List<String>.from(stack);
  if (!lambdaPop && newStack.isNotEmpty) {
    newStack.removeLast();
  }
  if (!lambdaPush && t.pushSymbol.isNotEmpty) {
    for (final ch in t.pushSymbol.split('').reversed) {
      newStack.add(ch);
    }
  }
  return newStack;
}

/// Returns a human-readable label for a PDA transition.
String _transitionLabel(PDATransition t, String input) {
  final lambdaPop = t.isLambdaPop || t.popSymbol.isEmpty;
  final lambdaPush = t.isLambdaPush || t.pushSymbol.isEmpty;
  return '$input,${lambdaPop ? 'ε' : t.popSymbol}→${lambdaPush ? 'ε' : t.pushSymbol}';
}

String _configurationKey(State state, String remaining, List<String> stack) {
  return '${state.id}\u0000$remaining\u0000${stack.join('\u0001')}';
}

List<SimulationStep> _appendStep(
  List<SimulationStep> steps,
  SimulationStep step,
  bool stepByStep,
) {
  return stepByStep ? [...steps, step] : <SimulationStep>[step];
}

/// Internal NPDA search using BFS over configurations, applying ε-closure.
PDASimulationResult _simulateSearch(
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
  final initialStack = <String>[pda.initialStackSymbol];
  final initialSteps = stepByStep
      ? <SimulationStep>[
          SimulationStep.pda(
            currentState: pda.initialState!.id,
            remainingInput: inputString,
            stackContents: pda.initialStackSymbol,
            stepNumber: 0,
          ),
        ]
      : <SimulationStep>[];
  final initialConfig = (
    pda.initialState!,
    inputString,
    initialStack,
    initialSteps,
    0,
  );

  final queue =
      Queue<(State, String, List<String>, List<SimulationStep>, int)>();
  final seenConfigs = <String>{
    _configurationKey(pda.initialState!, inputString, initialStack),
  };
  queue.add(initialConfig);

  // Track longest explored branch for trace preservation on failure
  var longestBranch = <SimulationStep>[];

  while (queue.isNotEmpty) {
    if (DateTime.now().difference(startTime) > timeout) {
      return PDASimulationResult.timeout(
        inputString: inputString,
        steps: longestBranch,
        executionTime: DateTime.now().difference(startTime),
      );
    }
    if (explored++ > maxConfigurations) {
      return PDASimulationResult.infiniteLoop(
        inputString: inputString,
        steps: longestBranch,
        executionTime: DateTime.now().difference(startTime),
      );
    }

    final (state, remaining, stack, steps, depth) = queue.removeFirst();

    // Track longest branch for trace preservation
    if (stepByStep && steps.length > longestBranch.length) {
      longestBranch = steps;
    }

    // Acceptance checks
    final isFinalOk = pda.acceptingStates.contains(state);
    final isEmptyStackOk =
        stack.isEmpty || (stack.length == 1 && stack.last.isEmpty);
    final inputConsumed = remaining.isEmpty;

    final accepted = switch (mode) {
      PDAAcceptanceMode.finalState => inputConsumed && isFinalOk,
      PDAAcceptanceMode.emptyStack => inputConsumed && isEmptyStackOk,
      PDAAcceptanceMode.both => inputConsumed && isFinalOk && isEmptyStackOk,
    };

    if (accepted) {
      final finalStep = SimulationStep.finalStep(
        finalState: state.id,
        remainingInput: remaining,
        stackContents: stack.join(''),
        tapeContents: '',
        stepNumber: (steps.isNotEmpty ? steps.last.stepNumber : 0) + 1,
      );
      final finalSteps = stepByStep
          ? (List<SimulationStep>.from(steps)..add(finalStep))
          : <SimulationStep>[finalStep];
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

    void enqueue(
      State nextState,
      String nextRemaining,
      List<String> nextStack,
      SimulationStep step,
    ) {
      final key = _configurationKey(nextState, nextRemaining, nextStack);
      if (!seenConfigs.add(key)) {
        return;
      }
      queue.add(
        (
          nextState,
          nextRemaining,
          nextStack,
          _appendStep(steps, step, stepByStep),
          depth + 1,
        ),
      );
    }

    final nextStepNumber = (steps.isNotEmpty ? steps.last.stepNumber : 0) + 1;

    // Generate ε-moves first (no input consumption). Consider either
    // explicit lambda flags or empty strings in the transition fields.
    for (final t in pda.pdaTransitions.where(
      (t) => t.fromState == state && (t.isLambdaInput || t.inputSymbol.isEmpty),
    )) {
      final newStack = _applyTransitionStack(t, stack);
      if (newStack == null) continue;

      final step = SimulationStep.pda(
        currentState: t.toState.id,
        remainingInput: remaining,
        stackContents: newStack.join(''),
        usedTransition: _transitionLabel(t, 'ε'),
        stepNumber: nextStepNumber,
        consumedInput: '',
      );
      enqueue(t.toState, remaining, newStack, step);
    }

    // Generate input-consuming moves if input remains
    if (remaining.isNotEmpty) {
      final a = remaining[0];
      final newRemaining = remaining.substring(1);
      for (final t in pda.pdaTransitions.where(
        (t) => t.fromState == state && !t.isLambdaInput && t.inputSymbol == a,
      )) {
        final newStack = _applyTransitionStack(t, stack);
        if (newStack == null) continue;

        final step = SimulationStep.pda(
          currentState: t.toState.id,
          remainingInput: newRemaining,
          stackContents: newStack.join(''),
          usedTransition: _transitionLabel(t, a),
          stepNumber: nextStepNumber,
          consumedInput: a,
        );
        enqueue(t.toState, newRemaining, newStack, step);
      }
    }
  }

  return PDASimulationResult.failure(
    inputString: inputString,
    steps: longestBranch,
    errorMessage: 'Rejected: no accepting configuration found',
    executionTime: DateTime.now().difference(startTime),
  );
}
