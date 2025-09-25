import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';

/// Property checking algorithms for automata
class PropertyChecker {
  /// Check if a finite automaton accepts the empty language
  static bool isEmpty(FiniteAutomaton fa) {
    // Check if any final state is reachable from initial state
    final reachableStates = _getReachableStates(fa);
    final reachableFinalStates = reachableStates.intersection(
      fa.finalStates.map((s) => s.id).toSet(),
    );
    
    return reachableFinalStates.isEmpty;
  }

  /// Check if a finite automaton accepts all strings (universal language)
  static bool isUniversal(FiniteAutomaton fa) {
    // Complement the automaton and check if it's empty
    final complement = _complement(fa);
    return isEmpty(complement);
  }

  /// Check if a finite automaton accepts a finite language
  static bool isFinite(FiniteAutomaton fa) {
    // Check if there are any cycles in the automaton
    final hasCycle = _hasCycle(fa);
    return !hasCycle;
  }

  /// Check if two finite automata are equivalent
  static bool areEquivalent(FiniteAutomaton fa1, FiniteAutomaton fa2) {
    // Check if (L1 - L2) ∪ (L2 - L1) is empty
    final diff1 = _difference(fa1, fa2);
    final diff2 = _difference(fa2, fa1);
    final union = _union(diff1, diff2);
    
    return isEmpty(union);
  }

  /// Check if one finite automaton is a subset of another
  static bool isSubset(FiniteAutomaton fa1, FiniteAutomaton fa2) {
    // Check if L1 - L2 is empty
    final difference = _difference(fa1, fa2);
    return isEmpty(difference);
  }

  /// Check if a finite automaton accepts a specific string
  static bool acceptsString(FiniteAutomaton fa, String input) {
    // Simulate the automaton on the input string
    final result = _simulate(fa, input);
    return result.isAccepted;
  }

  /// Check if a pushdown automaton accepts the empty language
  static bool isEmptyPDA(PushdownAutomaton pda) {
    // This is a simplified check - in practice, you'd need to implement
    // the full emptiness checking algorithm for PDAs
    return pda.finalStates.isEmpty;
  }

  /// Check if a Turing machine halts on a given input
  static bool haltsOnInput(TuringMachine tm, String input) {
    // Simulate the Turing machine
    final result = _simulateTM(tm, input);
    return result.halts;
  }

  /// Check if a context-free grammar generates the empty language
  static bool isEmptyCFG(ContextFreeGrammar cfg) {
    // Check if the start variable can derive a terminal string
    final canDerive = _canDeriveTerminal(cfg, cfg.startVariable);
    return !canDerive;
  }

  /// Check if a context-free grammar is ambiguous
  static bool isAmbiguous(ContextFreeGrammar cfg) {
    // This is a simplified check - full ambiguity checking is undecidable
    // Check for obvious ambiguity patterns
    return _hasObviousAmbiguity(cfg);
  }

  /// Get reachable states from initial state
  static Set<String> _getReachableStates(FiniteAutomaton fa) {
    final reachable = <String>{};
    final workList = <String>[fa.initialState?.id ?? ''];
    
    while (workList.isNotEmpty) {
      final current = workList.removeAt(0);
      
      if (reachable.contains(current)) {
        continue;
      }
      
      reachable.add(current);
      
      // Add all states reachable from current state
      final outgoingTransitions = fa.transitions.where(
        (t) => t.from == current,
      );
      
      for (final transition in outgoingTransitions) {
        if (!reachable.contains(transition.to)) {
          workList.add(transition.to);
        }
      }
    }
    
    return reachable;
  }

  /// Check if automaton has cycles
  static bool _hasCycle(FiniteAutomaton fa) {
    final visited = <String>{};
    final recursionStack = <String>{};
    
    for (final state in fa.states) {
      if (!visited.contains(state.id)) {
        if (_hasCycleDFS(fa, state.id, visited, recursionStack)) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// DFS to check for cycles
  static bool _hasCycleDFS(
    FiniteAutomaton fa,
    String state,
    Set<String> visited,
    Set<String> recursionStack,
  ) {
    visited.add(state);
    recursionStack.add(state);
    
    final outgoingTransitions = fa.transitions.where(
      (t) => t.from == state,
    );
    
    for (final transition in outgoingTransitions) {
      if (!visited.contains(transition.to)) {
        if (_hasCycleDFS(fa, transition.to, visited, recursionStack)) {
          return true;
        }
      } else if (recursionStack.contains(transition.to)) {
        return true;
      }
    }
    
    recursionStack.remove(state);
    return false;
  }

  /// Complement of a finite automaton
  static FiniteAutomaton _complement(FiniteAutomaton fa) {
    // Convert to DFA first, then complement final states
    final dfa = _toDFA(fa);
    
    final newStates = dfa.states.map((state) => State(
      id: state.id,
      name: state.name,
      isInitial: state.isInitial,
      isFinal: !state.isFinal, // Complement final states
    )).toList();
    
    return FiniteAutomaton(
      id: 'complement_${fa.id}',
      name: '¬${fa.name}',
      states: newStates,
      transitions: dfa.transitions,
      alphabet: dfa.alphabet,
      initialState: newStates.firstWhere((s) => s.isInitial),
      finalStates: newStates.where((s) => s.isFinal).toList(),
      metadata: AutomatonMetadata(
        type: 'complement',
        description: 'Complement of ${fa.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Difference of two finite automata
  static FiniteAutomaton _difference(FiniteAutomaton fa1, FiniteAutomaton fa2) {
    // L1 - L2 = L1 ∩ ¬L2
    final complement2 = _complement(fa2);
    return _intersection(fa1, complement2);
  }

  /// Union of two finite automata
  static FiniteAutomaton _union(FiniteAutomaton fa1, FiniteAutomaton fa2) {
    // This would use the union algorithm from language operations
    // For now, return a placeholder
    return fa1;
  }

  /// Intersection of two finite automata
  static FiniteAutomaton _intersection(FiniteAutomaton fa1, FiniteAutomaton fa2) {
    // This would use the intersection algorithm from language operations
    // For now, return a placeholder
    return fa1;
  }

  /// Convert NFA to DFA
  static FiniteAutomaton _toDFA(FiniteAutomaton nfa) {
    // This would use the NFA to DFA conversion algorithm
    // For now, return the original NFA
    return nfa;
  }

  /// Simulate finite automaton on input string
  static SimulationResult _simulate(FiniteAutomaton fa, String input) {
    final currentStates = <String>{fa.initialState?.id ?? ''};
    
    for (int i = 0; i < input.length; i++) {
      final symbol = input[i];
      final nextStates = <String>{};
      
      for (final state in currentStates) {
        final transitions = fa.transitions.where(
          (t) => t.from == state && t.symbol == symbol,
        );
        
        for (final transition in transitions) {
          nextStates.add(transition.to);
        }
      }
      
      currentStates.clear();
      currentStates.addAll(nextStates);
    }
    
    final isAccepted = currentStates.any((state) => 
        fa.finalStates.any((finalState) => finalState.id == state));
    
    return SimulationResult(
      isAccepted: isAccepted,
      finalStates: currentStates.toList(),
      steps: input.length,
    );
  }

  /// Simulate Turing machine on input
  static TMSimulationResult _simulateTM(TuringMachine tm, String input) {
    // This would implement Turing machine simulation
    // For now, return a placeholder
    return TMSimulationResult(
      halts: true,
      accepts: false,
      steps: 0,
      finalConfiguration: null,
    );
  }

  /// Check if CFG variable can derive terminal string
  static bool _canDeriveTerminal(ContextFreeGrammar cfg, String variable) {
    final nullable = <String>{};
    var changed = true;
    
    while (changed) {
      changed = false;
      
      for (final production in cfg.productions) {
        if (production.rightSide.every((symbol) => 
            cfg.terminals.contains(symbol) || nullable.contains(symbol))) {
          if (!nullable.contains(production.leftSide)) {
            nullable.add(production.leftSide);
            changed = true;
          }
        }
      }
    }
    
    return nullable.contains(variable);
  }

  /// Check for obvious ambiguity in CFG
  static bool _hasObviousAmbiguity(ContextFreeGrammar cfg) {
    // Check for productions with same left side and right side
    final productionsByLeft = <String, List<Production>>{};
    
    for (final production in cfg.productions) {
      productionsByLeft.putIfAbsent(production.leftSide, () => []);
      productionsByLeft[production.leftSide]!.add(production);
    }
    
    for (final productions in productionsByLeft.values) {
      if (productions.length > 1) {
        // Check if any two productions have the same right side
        for (int i = 0; i < productions.length; i++) {
          for (int j = i + 1; j < productions.length; j++) {
            if (productions[i].rightSide.toString() == 
                productions[j].rightSide.toString()) {
              return true;
            }
          }
        }
      }
    }
    
    return false;
  }
}

/// Result of automaton simulation
class SimulationResult {
  final bool isAccepted;
  final List<String> finalStates;
  final int steps;

  const SimulationResult({
    required this.isAccepted,
    required this.finalStates,
    required this.steps,
  });
}

/// Result of Turing machine simulation
class TMSimulationResult {
  final bool halts;
  final bool accepts;
  final int steps;
  final String? finalConfiguration;

  const TMSimulationResult({
    required this.halts,
    required this.accepts,
    required this.steps,
    this.finalConfiguration,
  });
}
