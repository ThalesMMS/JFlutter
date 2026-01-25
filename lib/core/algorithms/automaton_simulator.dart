//
//  automaton_simulator.dart
//  JFlutter
//
//  Implementa o motor central de simulação para autômatos finitos, cobrindo
//  execuções determinísticas e não determinísticas com suporte a rastreamento
//  passo a passo. Realiza validações estruturais, controla tempo limite,
//  compila listas de etapas e produz resultados ricos que incluem estatísticas
//  de execução. Serve como base para fachadas de nível superior no domínio de
//  autômatos.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';
import '../models/nfa_path_node.dart';
import '../models/nfa_computation_tree.dart';
import '../result.dart';

/// Simulates Finite Automata (FA) with input strings
class AutomatonSimulator {
  /// Simulates a DFA with an input string (deterministic, no epsilon)
  static Future<Result<SimulationResult>> simulateDFA(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input (generic checks)
      final validationResult = _validateInput(automaton, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Validate DFA constraints
      if (automaton.isNondeterministic || automaton.hasEpsilonTransitions) {
        return const Failure(
          'DFA required: automaton must be deterministic and epsilon-free',
        );
      }

      // Handle empty automaton
      if (automaton.states.isEmpty) {
        return const Failure('Cannot simulate empty automaton');
      }

      // Handle automaton with no initial state
      if (automaton.initialState == null) {
        return const Failure('Automaton must have an initial state');
      }

      // Simulate as DFA
      final result = await _simulateDFA(
        automaton,
        inputString,
        stepByStep,
        timeout,
      );
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error simulating DFA: $e');
    }
  }

  /// Backwards-compatible generic simulate: routes to DFA simulation.
  static Future<Result<SimulationResult>> simulate(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // Route to NFA simulator when nondeterminism or epsilon transitions exist
    if (automaton.isNondeterministic || automaton.hasEpsilonTransitions) {
      return await simulateNFA(
        automaton,
        inputString,
        stepByStep: stepByStep,
        timeout: timeout,
      );
    }
    return await simulateDFA(
      automaton,
      inputString,
      stepByStep: stepByStep,
      timeout: timeout,
    );
  }

  /// Validates the input automaton and string
  static Result<void> _validateInput(
    FSA automaton,
    String inputString, {
    bool strictAlphabet = true,
  }) {
    if (automaton.states.isEmpty) {
      return const Failure('Automaton must have at least one state');
    }

    if (automaton.initialState == null) {
      return const Failure('Automaton must have an initial state');
    }

    if (!automaton.states.contains(automaton.initialState)) {
      return const Failure('Initial state must be in the states set');
    }

    for (final acceptingState in automaton.acceptingStates) {
      if (!automaton.states.contains(acceptingState)) {
        return const Failure('Accepting state must be in the states set');
      }
    }

    // Validate input string symbols
    if (strictAlphabet) {
      for (int i = 0; i < inputString.length; i++) {
        final symbol = inputString[i];
        if (!automaton.alphabet.contains(symbol)) {
          return Failure('Input string contains invalid symbol: $symbol');
        }
      }
    }

    return const Success(null);
  }

  /// Simulates a DFA step-by-step
  static Future<SimulationResult> _simulateDFA(
    FSA automaton,
    String inputString,
    bool stepByStep,
    Duration timeout,
  ) async {
    final steps = <SimulationStep>[];
    final startTime = DateTime.now();

    // Initialize simulation with a single current state
    var currentState = automaton.initialState!;
    int stepNumber = 0;

    // Add initial step
    steps.add(
      SimulationStep.initial(
        initialState: automaton.initialState!.id,
        inputString: inputString,
      ),
    );

    // Process each input symbol with batching for large inputs
    final inputSymbols = inputString.split('');
    var processedCount = 0;

    for (final symbol in inputSymbols) {
      stepNumber++;
      processedCount++;

      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        return SimulationResult.timeout(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      // Find next state deterministically
      final transitions = automaton
          .getTransitionsFromStateOnSymbol(currentState, symbol)
          .whereType<FSATransition>()
          .toList();
      if (transitions.isEmpty) {
        return SimulationResult.failure(
          inputString: inputString,
          steps: steps,
          errorMessage:
              'No transition from state ${currentState.id} on symbol $symbol',
          executionTime: DateTime.now().difference(startTime),
        );
      }
      final transition = transitions.first;
      final nextState = transition.toState;

      // Check for infinite loop (simplified)
      if (steps.length > 10000) {
        return SimulationResult.infiniteLoop(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      // Add step
      if (stepByStep) {
        steps.add(
          SimulationStep.fsa(
            currentState: currentState.id,
            remainingInput: inputSymbols.skip(processedCount).join(''),
            usedTransition: 'δ(${currentState.id}, $symbol) = ${nextState.id}',
            stepNumber: stepNumber,
            consumedInput: symbol,
          ),
        );
      }

      currentState = nextState;

      // Batch processing for large simulations (>1000 steps)
      if (processedCount > 1000 && processedCount % 500 == 0) {
        // Yield to prevent UI blocking
        await Future.delayed(Duration.zero);
      }
    }

    // Check if any current state is accepting
    final isAccepted = automaton.acceptingStates.contains(currentState);

    // Add final step
    steps.add(
      SimulationStep.finalStep(
        finalState: currentState.id,
        remainingInput: '',
        stackContents: '',
        tapeContents: '',
        stepNumber: stepNumber + 1,
      ),
    );

    if (isAccepted) {
      return SimulationResult.success(
        inputString: inputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
      );
    } else {
      return SimulationResult.failure(
        inputString: inputString,
        steps: steps,
        errorMessage: 'Rejected: no accepting state reached',
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Simulates an NFA with epsilon transitions
  static Future<Result<SimulationResult>> simulateNFA(
    FSA nfa,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      // For NFAs, don't fail early on symbols outside the alphabet; reject via simulation.
      final validationResult = _validateInput(
        nfa,
        inputString,
        strictAlphabet: false,
      );
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty automaton
      if (nfa.states.isEmpty) {
        return const Failure('Cannot simulate empty automaton');
      }

      // Handle automaton with no initial state
      if (nfa.initialState == null) {
        return const Failure('Automaton must have an initial state');
      }

      // Simulate the NFA
      final result = await _simulateNFA(nfa, inputString, stepByStep, timeout);
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error simulating NFA: $e');
    }
  }

  /// Simulates an NFA with epsilon transitions
  static Future<SimulationResult> _simulateNFA(
    FSA nfa,
    String inputString,
    bool stepByStep,
    Duration timeout,
  ) async {
    final steps = <SimulationStep>[];
    final startTime = DateTime.now();

    bool isEpsilonSymbol(String s) {
      final normalized = s.trim().toLowerCase();
      return normalized.isEmpty ||
          normalized == 'ε' ||
          normalized == 'λ' ||
          normalized == 'lambda';
    }

    Set<State> epsilonClosureFlexibleOf(State start) {
      final closure = <State>{start};
      final queue = <State>[start];
      while (queue.isNotEmpty) {
        final state = queue.removeAt(0);
        for (final t in nfa.fsaTransitions) {
          final isFrom = t.fromState == state;
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

    Set<State> epsilonClosureFlexibleOfSet(Set<State> states) {
      final closure = <State>{};
      for (final s in states) {
        closure.addAll(epsilonClosureFlexibleOf(s));
      }
      return closure;
    }

    // Initialize simulation with epsilon closure of initial state
    var currentStates = epsilonClosureFlexibleOf(nfa.initialState!);
    var remainingInput = inputString;
    int stepNumber = 0;

    // Add initial step
    final initialStateId = currentStates.length == 1
        ? currentStates.first.id
        : '{${currentStates.map((s) => s.id).join(',')}}';

    steps.add(
      SimulationStep.initial(
        initialState: initialStateId,
        inputString: inputString,
      ),
    );

    // Build computation tree - start with root nodes for each state in epsilon closure
    final rootNodes = <NFAPathNode>[];
    for (final state in currentStates) {
      rootNodes.add(
        NFAPathNode(
          currentState: state.id,
          remainingInput: inputString,
          stepNumber: 0,
          transitionUsed: 'Initial state (with ε-closure)',
          description: 'Initial state ${state.id}',
        ),
      );
    }

    // Maintain a queue of active path nodes to expand
    var activeLeaves = rootNodes.toList();
    final allLeaves = <NFAPathNode>[];
    int totalSteps = 0;

    // Process each input symbol
    while (remainingInput.isNotEmpty) {
      stepNumber++;
      totalSteps = stepNumber;

      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        // Build partial tree with current progress
        final partialRoot = _buildTreeRoot(rootNodes);
        final tree = NFAComputationTree.timeout(
          root: partialRoot,
          inputString: inputString,
          totalSteps: totalSteps,
        );
        return SimulationResult.timeout(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
          computationTree: tree,
        );
      }

      final symbol = remainingInput[0];
      remainingInput = remainingInput.substring(1);

      // Find next states by symbol, exploring all transitions
      var nextStates = <State>{};
      for (final state in currentStates) {
        final transitions = nfa.getTransitionsFromStateOnSymbol(state, symbol);
        nextStates.addAll(transitions.map((t) => t.toState));
      }

      // Apply epsilon closure to next states (flexible)
      nextStates = epsilonClosureFlexibleOfSet(nextStates);

      // Check for infinite loop (simplified)
      if (steps.length > 1000) {
        final partialRoot = _buildTreeRoot(rootNodes);
        final tree = NFAComputationTree.infiniteLoop(
          root: partialRoot,
          inputString: inputString,
          totalSteps: totalSteps,
        );
        return SimulationResult.infiniteLoop(
          inputString: inputString,
          steps: steps,
          executionTime: DateTime.now().difference(startTime),
          computationTree: tree,
        );
      }

      // Expand each active leaf node in the computation tree
      final newActiveLeaves = <NFAPathNode>[];
      for (final leaf in activeLeaves) {
        // Find which state this leaf represents
        final leafState = nfa.states.firstWhere(
          (s) => s.id == leaf.currentState,
          orElse: () => nfa.initialState!,
        );

        // Get transitions from this state on the current symbol
        final transitions = nfa.getTransitionsFromStateOnSymbol(
          leafState,
          symbol,
        );

        // Get epsilon closure destinations
        final destStates = <State>{};
        for (final t in transitions) {
          destStates.addAll(epsilonClosureFlexibleOf(t.toState));
        }

        if (destStates.isEmpty) {
          // Dead end - mark the leaf as dead-end and update it in the tree
          final deadEndLeaf = leaf.copyWith(isDeadEnd: true);
          _replaceNodeInTree(rootNodes, leaf, deadEndLeaf);
          allLeaves.add(deadEndLeaf);
        } else {
          // Create child nodes for each destination state
          final children = <NFAPathNode>[];
          for (final destState in destStates) {
            final childNode = NFAPathNode(
              currentState: destState.id,
              remainingInput: remainingInput,
              inputSymbol: symbol,
              transitionUsed:
                  'δ(${leaf.currentState}, $symbol) → ${destState.id}',
              stepNumber: stepNumber,
              description: 'Consumed $symbol, now at ${destState.id}',
            );
            children.add(childNode);
            newActiveLeaves.add(childNode);
          }
          // Update the leaf with its children (create a new node)
          final updatedLeaf = leaf.copyWith(children: children);
          // Replace the old leaf in rootNodes
          _replaceNodeInTree(rootNodes, leaf, updatedLeaf);
        }
      }

      // Add step
      if (stepByStep) {
        final currentStateId = currentStates.length == 1
            ? currentStates.first.id
            : '{${currentStates.map((s) => s.id).join(',')}}';

        steps.add(
          SimulationStep.fsa(
            currentState: currentStateId,
            remainingInput: remainingInput,
            usedTransition: symbol,
            stepNumber: stepNumber,
            consumedInput: symbol,
          ),
        );
      }

      currentStates = nextStates;
      activeLeaves = newActiveLeaves;

      // If no next states, early reject
      if (currentStates.isEmpty) {
        final treeRoot = _buildTreeRoot(rootNodes);
        final tree = NFAComputationTree.rejected(
          root: treeRoot,
          inputString: inputString,
          totalSteps: totalSteps,
          errorMessage: 'No transition found for symbol $symbol',
        );
        return SimulationResult.failure(
          inputString: inputString,
          steps: steps,
          errorMessage: 'No transition found for symbol $symbol',
          executionTime: DateTime.now().difference(startTime),
          computationTree: tree,
        );
      }
    }

    // Mark final leaf nodes as accepting or dead-end
    for (final leaf in activeLeaves) {
      final leafState = nfa.states.firstWhere(
        (s) => s.id == leaf.currentState,
        orElse: () => nfa.initialState!,
      );
      final isAccepting = nfa.acceptingStates.contains(leafState);
      final updatedLeaf = leaf.copyWith(
        isAccepting: isAccepting,
        isDeadEnd: !isAccepting,
      );
      _replaceNodeInTree(rootNodes, leaf, updatedLeaf);
      allLeaves.add(updatedLeaf);
    }

    // Check if any current state is accepting
    final isAccepted = currentStates
        .intersection(nfa.acceptingStates)
        .isNotEmpty;

    // Add final step
    final finalStateId = currentStates.length == 1
        ? currentStates.first.id
        : '{${currentStates.map((s) => s.id).join(',')}}';

    steps.add(
      SimulationStep.finalStep(
        finalState: finalStateId,
        remainingInput: remainingInput,
        stackContents: '',
        tapeContents: '',
        stepNumber: stepNumber + 1,
      ),
    );

    // Build final computation tree
    final treeRoot = _buildTreeRoot(rootNodes);
    final tree = isAccepted
        ? NFAComputationTree.accepted(
            root: treeRoot,
            inputString: inputString,
            totalSteps: totalSteps,
          )
        : NFAComputationTree.rejected(
            root: treeRoot,
            inputString: inputString,
            totalSteps: totalSteps,
            errorMessage: 'Input not accepted - no accepting state reached',
          );

    if (isAccepted) {
      return SimulationResult.success(
        inputString: inputString,
        steps: steps,
        executionTime: DateTime.now().difference(startTime),
        computationTree: tree,
      );
    } else {
      return SimulationResult.failure(
        inputString: inputString,
        steps: steps,
        errorMessage: 'Input not accepted - no accepting state reached',
        executionTime: DateTime.now().difference(startTime),
        computationTree: tree,
      );
    }
  }

  /// Builds a single root node from multiple root nodes (for epsilon closure)
  static NFAPathNode _buildTreeRoot(List<NFAPathNode> rootNodes) {
    if (rootNodes.isEmpty) {
      return const NFAPathNode(
        currentState: 'empty',
        remainingInput: '',
        stepNumber: 0,
        isDeadEnd: true,
      );
    }
    if (rootNodes.length == 1) {
      return rootNodes.first;
    }
    // Create a virtual root node that branches to all epsilon-closure states
    return NFAPathNode(
      currentState: '{${rootNodes.map((n) => n.currentState).join(',')}}',
      remainingInput: rootNodes.first.remainingInput,
      stepNumber: 0,
      children: rootNodes,
      transitionUsed: 'ε-closure of initial state',
      description: 'Initial ε-closure',
    );
  }

  /// Replaces a node in the tree (recursive helper)
  static void _replaceNodeInTree(
    List<NFAPathNode> rootNodes,
    NFAPathNode oldNode,
    NFAPathNode newNode,
  ) {
    for (int i = 0; i < rootNodes.length; i++) {
      if (rootNodes[i] == oldNode) {
        rootNodes[i] = newNode;
        return;
      }
      if (rootNodes[i].children.isNotEmpty) {
        final childrenList = rootNodes[i].children.toList();
        _replaceNodeInList(childrenList, oldNode, newNode);
        if (childrenList != rootNodes[i].children) {
          rootNodes[i] = rootNodes[i].copyWith(children: childrenList);
        }
      }
    }
  }

  /// Helper to replace a node in a list of children
  static void _replaceNodeInList(
    List<NFAPathNode> nodes,
    NFAPathNode oldNode,
    NFAPathNode newNode,
  ) {
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i] == oldNode) {
        nodes[i] = newNode;
        return;
      }
      if (nodes[i].children.isNotEmpty) {
        final childrenList = nodes[i].children.toList();
        _replaceNodeInList(childrenList, oldNode, newNode);
        if (childrenList != nodes[i].children) {
          nodes[i] = nodes[i].copyWith(children: childrenList);
        }
      }
    }
  }

  /// Tests if an automaton accepts a specific string
  static Future<Result<bool>> accepts(FSA automaton, String inputString) async {
    final simulationResult = await simulate(automaton, inputString);
    if (!simulationResult.isSuccess) {
      return Failure(simulationResult.error!);
    }

    return Success(simulationResult.data!.accepted);
  }

  /// Tests if an automaton rejects a specific string
  static Future<Result<bool>> rejects(FSA automaton, String inputString) async {
    final acceptsResult = await accepts(automaton, inputString);
    if (!acceptsResult.isSuccess) {
      return Failure(acceptsResult.error!);
    }

    return Success(!acceptsResult.data!);
  }

  /// Finds all strings of a given length that the automaton accepts
  static Future<Result<Set<String>>> findAcceptedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  }) async {
    try {
      final acceptedStrings = <String>{};
      final alphabet = automaton.alphabet.toList();

      // Generate all possible strings up to maxLength
      for (
        int length = 0;
        length <= maxLength && acceptedStrings.length < maxResults;
        length++
      ) {
        await _generateStrings(
          automaton,
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
  static Future<void> _generateStrings(
    FSA automaton,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> acceptedStrings,
    int maxResults,
  ) async {
    if (acceptedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final acceptsResult = await accepts(automaton, currentString);
      if (acceptsResult.isSuccess && acceptsResult.data!) {
        acceptedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      await _generateStrings(
        automaton,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        acceptedStrings,
        maxResults,
      );
    }
  }

  /// Finds all strings of a given length that the automaton rejects
  static Future<Result<Set<String>>> findRejectedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  }) async {
    try {
      final rejectedStrings = <String>{};
      final alphabet = automaton.alphabet.toList();

      // Generate all possible strings up to maxLength
      for (
        int length = 0;
        length <= maxLength && rejectedStrings.length < maxResults;
        length++
      ) {
        await _generateRejectedStrings(
          automaton,
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
  static Future<void> _generateRejectedStrings(
    FSA automaton,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> rejectedStrings,
    int maxResults,
  ) async {
    if (rejectedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final acceptsResult = await accepts(automaton, currentString);
      if (acceptsResult.isSuccess && !acceptsResult.data!) {
        rejectedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      await _generateRejectedStrings(
        automaton,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        rejectedStrings,
        maxResults,
      );
    }
  }
}
