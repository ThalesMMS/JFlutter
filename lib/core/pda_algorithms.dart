import 'pda.dart';
import 'result.dart';

/// PDA Algorithms implementation
/// Based on JFLAP's PDA algorithms
class PDAAlgorithms {
  /// Simulates a PDA on a given input string
  /// Returns a list of configurations representing the computation path
  static Result<List<PDAConfiguration>> simulatePDA(
    PushdownAutomaton pda,
    String input,
  ) {
    try {
      if (pda.initialId == null) {
        return Failure('No initial state defined');
      }

      final initialStack = CharacterStack();
      final initialConfig = PDAConfiguration(
        state: pda.initialId!,
        input: input,
        unprocessedInput: input,
        stack: initialStack,
        acceptanceMode: pda.acceptanceMode,
      );

      final configurations = <PDAConfiguration>[initialConfig];
      final visited = <PDAConfiguration>{};
      final queue = <PDAConfiguration>[initialConfig];

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        
        if (visited.contains(current)) continue;
        visited.add(current);

        // Check if accepting
        if (_isAcceptingConfiguration(pda, current)) {
          return Success(configurations);
        }

        // Find applicable transitions
        final applicableTransitions = _getApplicableTransitions(pda, current);
        
        for (final transition in applicableTransitions) {
          final nextConfig = _applyTransition(current, transition);
          if (nextConfig != null && !visited.contains(nextConfig)) {
            configurations.add(nextConfig);
            queue.add(nextConfig);
          }
        }
      }

      return Success(configurations);
    } catch (e) {
      return Failure('Simulation error: $e');
    }
  }

  /// Checks if a configuration is accepting
  static bool _isAcceptingConfiguration(PushdownAutomaton pda, PDAConfiguration config) {
    switch (pda.acceptanceMode) {
      case AcceptanceMode.finalState:
        final state = pda.getState(config.state);
        return config.unprocessedInput.isEmpty && 
               state != null && 
               state.isFinal;
      case AcceptanceMode.emptyStack:
        return config.unprocessedInput.isEmpty && config.stack.isEmpty;
    }
  }

  /// Gets transitions applicable to a configuration
  static List<PDATransition> _getApplicableTransitions(
    PushdownAutomaton pda,
    PDAConfiguration config,
  ) {
    final applicable = <PDATransition>[];

    for (final transition in pda.transitions) {
      if (transition.fromState != config.state) continue;

      // Check input symbol match
      final inputMatch = transition.inputToRead.isEmpty || 
                        (config.unprocessedInput.isNotEmpty && 
                         config.unprocessedInput[0] == transition.inputToRead);

      // Check stack symbol match
      final stackMatch = transition.stringToPop.isEmpty ||
                        (config.stack.height >= transition.stringToPop.length &&
                         _canPopFromStack(config.stack, transition.stringToPop));

      if (inputMatch && stackMatch) {
        applicable.add(transition);
      }
    }

    return applicable;
  }

  /// Checks if a string can be popped from the stack
  static bool _canPopFromStack(CharacterStack stack, String stringToPop) {
    if (stringToPop.isEmpty) return true;
    if (stack.height < stringToPop.length) return false;

    final stackTop = stack.toString().substring(0, stringToPop.length);
    return stackTop == stringToPop;
  }

  /// Applies a transition to a configuration
  static PDAConfiguration? _applyTransition(
    PDAConfiguration config,
    PDATransition transition,
  ) {
    try {
      // Create new stack
      final newStack = config.stack.clone();

      // Pop from stack
      if (transition.stringToPop.isNotEmpty) {
        final popped = newStack.popString(transition.stringToPop.length);
        if (popped != transition.stringToPop) return null;
      }

      // Push to stack
      if (transition.stringToPush.isNotEmpty) {
        newStack.push(transition.stringToPush);
      }

      // Update unprocessed input
      String newUnprocessed = config.unprocessedInput;
      if (transition.inputToRead.isNotEmpty && newUnprocessed.isNotEmpty) {
        newUnprocessed = newUnprocessed.substring(1);
      }

      return PDAConfiguration(
        state: transition.toState,
        input: config.input,
        unprocessedInput: newUnprocessed,
        stack: newStack,
        acceptanceMode: config.acceptanceMode,
        parent: config,
      );
    } catch (e) {
      return null;
    }
  }

  /// Converts a PDA to Context-Free Grammar
  /// Based on JFLAP's PDAToCFGConverter
  static Result<Map<String, dynamic>> pdaToCFG(PushdownAutomaton pda) {
    try {
      if (pda.initialId == null) {
        return Failure('No initial state defined');
      }

      final productions = <String, List<String>>{};
      final variables = <String>{};

      // Add start variable
      final startVar = 'S';
      variables.add(startVar);

      // Create variables for each state pair and stack symbol
      for (final state in pda.states) {
        for (final stackSym in pda.stackAlphabet) {
          final varName = '${state.id}_${stackSym}';
          variables.add(varName);
        }
      }

      // Add initial production
      final initialState = pda.getState(pda.initialId!);
      if (initialState != null) {
        final initialVar = '${pda.initialId}_Z'; // Z is bottom of stack
        productions[startVar] = [initialVar];
      }

      // Process transitions
      for (final transition in pda.transitions) {
        _processTransitionForCFG(transition, productions, variables);
      }

      return Success({
        'variables': variables.toList(),
        'terminals': pda.alphabet.toList(),
        'productions': productions,
        'startVariable': startVar,
      });
    } catch (e) {
      return Failure('CFG conversion error: $e');
    }
  }

  /// Processes a transition for CFG conversion
  static void _processTransitionForCFG(
    PDATransition transition,
    Map<String, List<String>> productions,
    Set<String> variables,
  ) {
    final fromVar = '${transition.fromState}_${transition.stringToPop}';
    final toVar = '${transition.toState}_${transition.stringToPush}';

    if (transition.inputToRead.isEmpty) {
      // Lambda transition
      if (!productions.containsKey(fromVar)) {
        productions[fromVar] = [];
      }
      productions[fromVar]!.add(toVar);
    } else {
      // Transition with input
      if (!productions.containsKey(fromVar)) {
        productions[fromVar] = [];
      }
      productions[fromVar]!.add('${transition.inputToRead}$toVar');
    }
  }

  /// Checks if a PDA is deterministic
  static bool isDeterministic(PushdownAutomaton pda) {
    for (final state in pda.states) {
      final stateTransitions = pda.transitions.where((t) => t.fromState == state.id).toList();
      
      // Check for multiple transitions with same input and stack top
      final transitionKeys = <String>{};
      for (final transition in stateTransitions) {
        final key = '${transition.inputToRead}|${transition.stringToPop}';
        if (transitionKeys.contains(key)) {
          return false; // Non-deterministic
        }
        transitionKeys.add(key);
      }
    }
    return true;
  }

  /// Removes unreachable states from PDA
  static PushdownAutomaton removeUnreachableStates(PushdownAutomaton pda) {
    if (pda.initialId == null) return pda;

    final reachable = <String>{};
    final queue = <String>[pda.initialId!];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (reachable.contains(current)) continue;
      reachable.add(current);

      // Add reachable states through transitions
      for (final transition in pda.transitions) {
        if (transition.fromState == current) {
          queue.add(transition.toState);
        }
      }
    }

    // Remove unreachable states and transitions
    final newStates = pda.states.where((s) => reachable.contains(s.id)).toList();
    final newTransitions = pda.transitions.where((t) => 
        reachable.contains(t.fromState) && reachable.contains(t.toState)).toList();

    return PushdownAutomaton(
      alphabet: pda.alphabet,
      stackAlphabet: pda.stackAlphabet,
      states: newStates,
      transitions: newTransitions,
      initialId: pda.initialId,
      nextId: pda.nextId,
      acceptanceMode: pda.acceptanceMode,
      singleInputPDA: pda.singleInputPDA,
    );
  }

  /// Validates PDA structure
  static Result<bool> validatePDA(PushdownAutomaton pda) {
    try {
      // Check for initial state
      if (pda.initialId == null) {
        return Failure('No initial state defined');
      }

      // Check if initial state exists
      if (pda.getState(pda.initialId!) == null) {
        return Failure('Initial state does not exist');
      }

      // Check transitions reference valid states
      for (final transition in pda.transitions) {
        if (pda.getState(transition.fromState) == null) {
          return Failure('Transition references non-existent from state: ${transition.fromState}');
        }
        if (pda.getState(transition.toState) == null) {
          return Failure('Transition references non-existent to state: ${transition.toState}');
        }
      }

      // Check stack alphabet contains all symbols used in transitions
      final usedStackSymbols = <String>{};
      for (final transition in pda.transitions) {
        usedStackSymbols.addAll(transition.stringToPop.split(''));
        usedStackSymbols.addAll(transition.stringToPush.split(''));
      }
      
      for (final symbol in usedStackSymbols) {
        if (symbol.isNotEmpty && !pda.stackAlphabet.contains(symbol)) {
          return Failure('Stack symbol "$symbol" used in transition but not in stack alphabet');
        }
      }

      return Success(true);
    } catch (e) {
      return Failure('Validation error: $e');
    }
  }
}
