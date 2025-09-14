import 'turing.dart';
import 'result.dart';

/// Turing Machine Algorithms implementation
/// Based on JFLAP's Turing Machine algorithms
class TuringAlgorithms {
  /// Simulates a Turing Machine on a given input string
  /// Returns a list of configurations representing the computation path
  static Result<List<TMConfiguration>> simulateTM(
    TuringMachine tm,
    String input,
  ) {
    try {
      if (tm.initialId == null) {
        return Failure('No initial state defined');
      }

      // Create initial tapes
      final tapes = <Tape>[];
      for (int i = 0; i < tm.numTapes; i++) {
        tapes.add(Tape(initialContent: i == 0 ? input : ''));
      }

      final initialConfig = TMConfiguration(
        state: tm.initialId!,
        tapes: tapes,
        acceptanceMode: tm.acceptanceMode,
      );

      final configurations = <TMConfiguration>[initialConfig];
      final visited = <TMConfiguration>{};
      final queue = <TMConfiguration>[initialConfig];

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        
        if (visited.contains(current)) continue;
        visited.add(current);

        // Check if accepting
        if (_isAcceptingConfiguration(tm, current)) {
          return Success(configurations);
        }

        // Find applicable transitions
        final applicableTransitions = _getApplicableTransitions(tm, current);
        
        if (applicableTransitions.isEmpty) {
          // No applicable transitions - machine halts
          final haltedConfig = current.copyWith(isHalted: true);
          configurations.add(haltedConfig);
          if (tm.acceptanceMode == AcceptanceMode.halting) {
            return Success(configurations);
          }
          continue;
        }

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
  static bool _isAcceptingConfiguration(TuringMachine tm, TMConfiguration config) {
    switch (tm.acceptanceMode) {
      case AcceptanceMode.finalState:
        final state = tm.getState(config.state);
        return state != null && state.isFinal;
      case AcceptanceMode.halting:
        return config.isHalted;
    }
  }

  /// Gets transitions applicable to a configuration
  static List<TMTransition> _getApplicableTransitions(
    TuringMachine tm,
    TMConfiguration config,
  ) {
    final applicable = <TMTransition>[];

    for (final transition in tm.transitions) {
      if (transition.fromState != config.state) continue;
      if (transition.numTapes != config.tapes.length) continue;

      // Check if all tape symbols match
      bool allMatch = true;
      for (int i = 0; i < transition.numTapes; i++) {
        final tapeSymbol = config.tapes[i].read();
        final readSymbol = transition.readSymbols[i];
        
        // Handle special symbols
        if (readSymbol == Tape.blank && tapeSymbol != Tape.blank) {
          allMatch = false;
          break;
        }
        if (readSymbol != Tape.blank && tapeSymbol != readSymbol) {
          allMatch = false;
          break;
        }
      }

      if (allMatch) {
        applicable.add(transition);
      }
    }

    return applicable;
  }

  /// Applies a transition to a configuration
  static TMConfiguration? _applyTransition(
    TMConfiguration config,
    TMTransition transition,
  ) {
    try {
      // Create new tapes
      final newTapes = <Tape>[];
      for (int i = 0; i < config.tapes.length; i++) {
        final newTape = config.tapes[i].clone();
        
        // Write symbol
        newTape.write(transition.writeSymbols[i]);
        
        // Move head
        newTape.moveHead(transition.directions[i]);
        
        newTapes.add(newTape);
      }

      return TMConfiguration(
        state: transition.toState,
        tapes: newTapes,
        acceptanceMode: config.acceptanceMode,
        parent: config,
      );
    } catch (e) {
      return null;
    }
  }

  /// Converts a Turing Machine to Context-Sensitive Grammar
  /// Based on JFLAP's TuringToGrammarConverter
  static Result<Map<String, dynamic>> tmToCSG(TuringMachine tm) {
    try {
      if (tm.initialId == null) {
        return Failure('No initial state defined');
      }

      final productions = <String, List<String>>{};
      final variables = <String>{};

      // Add start variable
      final startVar = 'S';
      variables.add(startVar);

      // Create variables for tape symbols and states
      for (final symbol in tm.alphabet) {
        variables.add(symbol);
      }
      for (final state in tm.states) {
        variables.add(state.id);
      }

      // Add initial production
      productions[startVar] = ['${tm.initialId}Z']; // Z is start marker

      // Process transitions
      for (final transition in tm.transitions) {
        _processTransitionForCSG(transition, productions, variables);
      }

      return Success({
        'variables': variables.toList(),
        'terminals': tm.alphabet.toList(),
        'productions': productions,
        'startVariable': startVar,
        'type': 'CSG',
      });
    } catch (e) {
      return Failure('CSG conversion error: $e');
    }
  }

  /// Processes a transition for CSG conversion
  static void _processTransitionForCSG(
    TMTransition transition,
    Map<String, List<String>> productions,
    Set<String> variables,
  ) {
    // This is a simplified conversion
    // In practice, CSG conversion from TM is quite complex
    
    final fromVar = '${transition.fromState}_${transition.readSymbols[0]}';
    final toVar = '${transition.toState}_${transition.writeSymbols[0]}';
    
    if (!productions.containsKey(fromVar)) {
      productions[fromVar] = [];
    }
    productions[fromVar]!.add(toVar);
  }

  /// Checks if a Turing Machine is deterministic
  static bool isDeterministic(TuringMachine tm) {
    for (final state in tm.states) {
      final stateTransitions = tm.transitions.where((t) => t.fromState == state.id).toList();
      
      // Check for multiple transitions with same read symbols
      final transitionKeys = <String>{};
      for (final transition in stateTransitions) {
        final key = transition.readSymbols.join('|');
        if (transitionKeys.contains(key)) {
          return false; // Non-deterministic
        }
        transitionKeys.add(key);
      }
    }
    return true;
  }

  /// Removes unreachable states from Turing Machine
  static TuringMachine removeUnreachableStates(TuringMachine tm) {
    if (tm.initialId == null) return tm;

    final reachable = <String>{};
    final queue = <String>[tm.initialId!];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (reachable.contains(current)) continue;
      reachable.add(current);

      // Add reachable states through transitions
      for (final transition in tm.transitions) {
        if (transition.fromState == current) {
          queue.add(transition.toState);
        }
      }
    }

    // Remove unreachable states and transitions
    final newStates = tm.states.where((s) => reachable.contains(s.id)).toList();
    final newTransitions = tm.transitions.where((t) => 
        reachable.contains(t.fromState) && reachable.contains(t.toState)).toList();

    return TuringMachine(
      alphabet: tm.alphabet,
      states: newStates,
      transitions: newTransitions,
      initialId: tm.initialId,
      nextId: tm.nextId,
      numTapes: tm.numTapes,
      acceptanceMode: tm.acceptanceMode,
    );
  }

  /// Validates Turing Machine structure
  static Result<bool> validateTM(TuringMachine tm) {
    try {
      // Check for initial state
      if (tm.initialId == null) {
        return Failure('No initial state defined');
      }

      // Check if initial state exists
      if (tm.getState(tm.initialId!) == null) {
        return Failure('Initial state does not exist');
      }

      // Check transitions reference valid states
      for (final transition in tm.transitions) {
        if (tm.getState(transition.fromState) == null) {
          return Failure('Transition references non-existent from state: ${transition.fromState}');
        }
        if (tm.getState(transition.toState) == null) {
          return Failure('Transition references non-existent to state: ${transition.toState}');
        }
      }

      // Check transition tape count matches machine tape count
      for (final transition in tm.transitions) {
        if (transition.numTapes != tm.numTapes) {
          return Failure('Transition has ${transition.numTapes} tapes but machine has ${tm.numTapes} tapes');
        }
      }

      // Check directions are valid
      for (final transition in tm.transitions) {
        for (final direction in transition.directions) {
          if (!['L', 'R', 'S'].contains(direction)) {
            return Failure('Invalid direction: $direction');
          }
        }
      }

      return Success(true);
    } catch (e) {
      return Failure('Validation error: $e');
    }
  }

  /// Checks if a Turing Machine accepts a language
  static Result<bool> acceptsLanguage(TuringMachine tm, String input) {
    final simulationResult = simulateTM(tm, input);
    
    if (simulationResult.isFailure) {
      return Failure(simulationResult.error!);
    }

    final configurations = simulationResult.data!;
    
    // Check if any configuration is accepting
    for (final config in configurations) {
      if (_isAcceptingConfiguration(tm, config)) {
        return Success(true);
      }
    }

    return Success(false);
  }

  /// Gets the output of a Turing Machine computation
  static Result<String> getOutput(TuringMachine tm, String input) {
    final simulationResult = simulateTM(tm, input);
    
    if (simulationResult.isFailure) {
      return Failure(simulationResult.error!);
    }

    final configurations = simulationResult.data!;
    
    if (configurations.isEmpty) {
      return Failure('No configurations generated');
    }

    // Get the last configuration (final state)
    final lastConfig = configurations.last;
    
    // Return output from first tape
    if (lastConfig.tapes.isNotEmpty) {
      return Success(lastConfig.tapes[0].output);
    }

    return Success('');
  }
}
