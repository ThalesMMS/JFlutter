import 'mealy_moore.dart';
import 'result.dart';
import 'algo_log.dart';

/// Mealy and Moore Machine Algorithms implementation
/// Based on JFLAP's Mealy and Moore machine algorithms
class MealyMooreAlgorithms {
  
  /// Simulates a Mealy machine on a given input string
  /// Returns a list of configurations representing the computation path
  static Result<List<MealyConfiguration>> simulateMealy(
    MealyMachine mealy,
    String input,
  ) {
    try {
      if (mealy.initialId == null) {
        return Failure('No initial state defined');
      }

      final initialConfig = MealyConfiguration(
        state: mealy.initialId!,
        input: input,
        unprocessedInput: input,
        output: '',
      );

      final configurations = <MealyConfiguration>[initialConfig];
      final visited = <MealyConfiguration>{};
      final queue = <MealyConfiguration>[initialConfig];

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        
        if (visited.contains(current)) continue;
        visited.add(current);

        // Check if accepting (all input processed)
        if (current.unprocessedInput.isEmpty) {
          return Success(configurations);
        }

        // Find applicable transitions
        final applicableTransitions = _getApplicableMealyTransitions(mealy, current);
        
        for (final transition in applicableTransitions) {
          final nextConfig = _applyMealyTransition(current, transition);
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

  /// Simulates a Moore machine on a given input string
  /// Returns a list of configurations representing the computation path
  static Result<List<MooreConfiguration>> simulateMoore(
    MooreMachine moore,
    String input,
  ) {
    try {
      if (moore.initialId == null) {
        return Failure('No initial state defined');
      }

      // Get initial state output
      final initialState = moore.getState(moore.initialId!);
      final initialOutput = initialState?.output ?? '';

      final initialConfig = MooreConfiguration(
        state: moore.initialId!,
        input: input,
        unprocessedInput: input,
        output: initialOutput,
      );

      final configurations = <MooreConfiguration>[initialConfig];
      final visited = <MooreConfiguration>{};
      final queue = <MooreConfiguration>[initialConfig];

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        
        if (visited.contains(current)) continue;
        visited.add(current);

        // Check if accepting (all input processed)
        if (current.unprocessedInput.isEmpty) {
          return Success(configurations);
        }

        // Find applicable transitions
        final applicableTransitions = _getApplicableMooreTransitions(moore, current);
        
        for (final transition in applicableTransitions) {
          final nextConfig = _applyMooreTransition(moore, current, transition);
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

  /// Convert Mealy machine to Moore machine
  static Result<MooreMachine> mealyToMoore(MealyMachine mealy) {
    AlgoLog.startAlgo('mealyToMoore', 'Conversão Mealy → Moore');
    
    try {
      final mooreStates = <MooreState>[];
      final mooreTransitions = <MooreTransition>[];
      final stateOutputMap = <String, String>{}; // Maps (state, input) -> output
      int nextId = 0;

      // Create state-output pairs for each Mealy transition
      for (final transition in mealy.transitions) {
        final stateOutputKey = '${transition.fromState}_${transition.input}';
        stateOutputMap[stateOutputKey] = transition.output;
      }

      // Create Moore states for each (state, output) pair
      final stateOutputToMooreId = <String, String>{};
      
      for (final mealyState in mealy.states) {
        // Find all possible outputs from this state
        final outputs = <String>{};
        for (final transition in mealy.transitions) {
          if (transition.fromState == mealyState.id) {
            outputs.add(transition.output);
          }
        }
        
        // If no outputs, add empty output
        if (outputs.isEmpty) {
          outputs.add('');
        }
        
        // Create Moore state for each output
        for (final output in outputs) {
          final mooreStateId = 'q${nextId++}';
          final mooreState = MooreState(
            id: mooreStateId,
            name: '${mealyState.name}_$output',
            x: mealyState.x,
            y: mealyState.y,
            isInitial: mealyState.isInitial && output == '',
            isFinal: mealyState.isFinal,
            output: output,
          );
          
          mooreStates.add(mooreState);
          stateOutputToMooreId['${mealyState.id}_$output'] = mooreStateId;
        }
      }

      // Create Moore transitions
      for (final mealyTransition in mealy.transitions) {
        final fromStateOutputKey = '${mealyTransition.fromState}_${mealyTransition.input}';
        final fromOutput = stateOutputMap[fromStateOutputKey] ?? '';
        final fromMooreId = stateOutputToMooreId['${mealyTransition.fromState}_$fromOutput'];
        
        if (fromMooreId != null) {
          // Find target Moore state (any state corresponding to the target Mealy state)
          final targetMealyState = mealy.getState(mealyTransition.toState);
          if (targetMealyState != null) {
            // Find a Moore state for the target Mealy state
            for (final entry in stateOutputToMooreId.entries) {
              if (entry.key.startsWith('${mealyTransition.toState}_')) {
                final mooreTransition = MooreTransition(
                  fromState: fromMooreId,
                  toState: entry.value,
                  input: mealyTransition.input,
                );
                mooreTransitions.add(mooreTransition);
                break;
              }
            }
          }
        }
      }

      final moore = MooreMachine(
        alphabet: mealy.alphabet,
        states: mooreStates,
        transitions: mooreTransitions,
        nextId: nextId,
        initialId: mooreStates.firstWhere((s) => s.isInitial).id,
      );

      AlgoLog.add('Conversão Mealy → Moore concluída com ${mooreStates.length} estados');
      return Success(moore);
    } catch (e) {
      return Failure('Conversion error: $e');
    }
  }

  /// Convert Moore machine to Mealy machine
  static Result<MealyMachine> mooreToMealy(MooreMachine moore) {
    AlgoLog.startAlgo('mooreToMealy', 'Conversão Moore → Mealy');
    
    try {
      final mealyStates = <MealyState>[];
      final mealyTransitions = <MealyTransition>[];
      int nextId = 0;

      // Create Mealy states (one for each Moore state)
      final mooreToMealyId = <String, String>{};
      
      for (final mooreState in moore.states) {
        final mealyStateId = 'q${nextId++}';
        final mealyState = MealyState(
          id: mealyStateId,
          name: mooreState.name,
          x: mooreState.x,
          y: mooreState.y,
          isInitial: mooreState.isInitial,
          isFinal: mooreState.isFinal,
        );
        
        mealyStates.add(mealyState);
        mooreToMealyId[mooreState.id] = mealyStateId;
      }

      // Create Mealy transitions
      for (final mooreTransition in moore.transitions) {
        final fromMealyId = mooreToMealyId[mooreTransition.fromState];
        final toMealyId = mooreToMealyId[mooreTransition.toState];
        
        if (fromMealyId != null && toMealyId != null) {
          // Get output from target Moore state
          final targetMooreState = moore.getState(mooreTransition.toState);
          final output = targetMooreState?.output ?? '';
          
          final mealyTransition = MealyTransition(
            fromState: fromMealyId,
            toState: toMealyId,
            input: mooreTransition.input,
            output: output,
          );
          mealyTransitions.add(mealyTransition);
        }
      }

      final mealy = MealyMachine(
        alphabet: moore.alphabet,
        states: mealyStates,
        transitions: mealyTransitions,
        nextId: nextId,
        initialId: mealyStates.firstWhere((s) => s.isInitial).id,
      );

      AlgoLog.add('Conversão Moore → Mealy concluída com ${mealyStates.length} estados');
      return Success(mealy);
    } catch (e) {
      return Failure('Conversion error: $e');
    }
  }

  /// Validate a Mealy machine
  static Result<bool> validateMealy(MealyMachine mealy) {
    try {
      // Check if there's an initial state
      if (mealy.initialId == null) {
        return Failure('No initial state defined');
      }

      // Check if initial state exists
      if (mealy.getState(mealy.initialId!) == null) {
        return Failure('Initial state does not exist');
      }

      // Check if all transitions reference valid states
      for (final transition in mealy.transitions) {
        if (mealy.getState(transition.fromState) == null) {
          return Failure('Transition references non-existent from state: ${transition.fromState}');
        }
        if (mealy.getState(transition.toState) == null) {
          return Failure('Transition references non-existent to state: ${transition.toState}');
        }
        if (!mealy.alphabet.contains(transition.input)) {
          return Failure('Transition uses symbol not in alphabet: ${transition.input}');
        }
      }

      return Success(true);
    } catch (e) {
      return Failure('Validation error: $e');
    }
  }

  /// Validate a Moore machine
  static Result<bool> validateMoore(MooreMachine moore) {
    try {
      // Check if there's an initial state
      if (moore.initialId == null) {
        return Failure('No initial state defined');
      }

      // Check if initial state exists
      if (moore.getState(moore.initialId!) == null) {
        return Failure('Initial state does not exist');
      }

      // Check if all transitions reference valid states
      for (final transition in moore.transitions) {
        if (moore.getState(transition.fromState) == null) {
          return Failure('Transition references non-existent from state: ${transition.fromState}');
        }
        if (moore.getState(transition.toState) == null) {
          return Failure('Transition references non-existent to state: ${transition.toState}');
        }
        if (!moore.alphabet.contains(transition.input)) {
          return Failure('Transition uses symbol not in alphabet: ${transition.input}');
        }
      }

      return Success(true);
    } catch (e) {
      return Failure('Validation error: $e');
    }
  }

  /// Helper function to get applicable Mealy transitions
  static List<MealyTransition> _getApplicableMealyTransitions(
    MealyMachine mealy,
    MealyConfiguration config,
  ) {
    final applicable = <MealyTransition>[];
    
    for (final transition in mealy.transitions) {
      if (transition.fromState == config.state && 
          config.unprocessedInput.isNotEmpty &&
          transition.input == config.unprocessedInput[0]) {
        applicable.add(transition);
      }
    }
    
    return applicable;
  }

  /// Helper function to get applicable Moore transitions
  static List<MooreTransition> _getApplicableMooreTransitions(
    MooreMachine moore,
    MooreConfiguration config,
  ) {
    final applicable = <MooreTransition>[];
    
    for (final transition in moore.transitions) {
      if (transition.fromState == config.state && 
          config.unprocessedInput.isNotEmpty &&
          transition.input == config.unprocessedInput[0]) {
        applicable.add(transition);
      }
    }
    
    return applicable;
  }

  /// Helper function to apply a Mealy transition
  static MealyConfiguration? _applyMealyTransition(
    MealyConfiguration config,
    MealyTransition transition,
  ) {
    if (config.unprocessedInput.isEmpty || 
        config.unprocessedInput[0] != transition.input) {
      return null;
    }

    return config.copyWith(
      state: transition.toState,
      unprocessedInput: config.unprocessedInput.substring(1),
      output: config.output + transition.output,
    );
  }

  /// Helper function to apply a Moore transition
  static MooreConfiguration? _applyMooreTransition(
    MooreMachine moore,
    MooreConfiguration config,
    MooreTransition transition,
  ) {
    if (config.unprocessedInput.isEmpty || 
        config.unprocessedInput[0] != transition.input) {
      return null;
    }

    // Get output from target state
    final targetState = moore.getState(transition.toState);
    final newOutput = targetState?.output ?? '';

    return config.copyWith(
      state: transition.toState,
      unprocessedInput: config.unprocessedInput.substring(1),
      output: config.output + newOutput,
    );
  }
}
