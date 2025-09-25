import 'package:core_pda/core_pda.dart';
import 'package:core_regex/core_regex.dart';

/// PDA to CFG conversion algorithm
class PDAToCFGConverter {
  /// Convert pushdown automaton to context-free grammar
  static ContextFreeGrammar convert(PushdownAutomaton pda) {
    // Step 1: Create variables for each state pair
    final variables = <String>[];
    final productions = <Production>[];
    
    // Create variables [p, A, q] for each state p, q and stack symbol A
    for (final state1 in pda.states) {
      for (final state2 in pda.states) {
        for (final stackSymbol in pda.stackAlphabet.symbols) {
          variables.add('[$state1,$stackSymbol,$state2]');
        }
      }
    }
    
    // Step 2: Create productions based on transitions
    for (final transition in pda.transitions) {
      if (transition.stackAction == Alphabet.epsilon) {
        // Pop transition: (p, a, A) -> (q, ε)
        // Create production: [p, A, q] -> a
        productions.add(Production(
          leftSide: '[${transition.from},${transition.stackSymbol},${transition.to}]',
          rightSide: [transition.inputSymbol],
        ));
      } else if (transition.stackAction.length == 1) {
        // Replace transition: (p, a, A) -> (q, B)
        // Create production: [p, A, r] -> a[q, B, r] for all states r
        for (final state in pda.states) {
          productions.add(Production(
            leftSide: '[${transition.from},${transition.stackSymbol},$state]',
            rightSide: [transition.inputSymbol, '[${transition.to},${transition.stackAction},$state]'],
          ));
        }
      } else if (transition.stackAction.length == 2) {
        // Push transition: (p, a, A) -> (q, BC)
        // Create production: [p, A, r] -> a[q, B, s][s, C, r] for all states s, r
        for (final state1 in pda.states) {
          for (final state2 in pda.states) {
            productions.add(Production(
              leftSide: '[${transition.from},${transition.stackSymbol},$state1]',
              rightSide: [
                transition.inputSymbol,
                '[${transition.to},${transition.stackAction[0]},$state2]',
                '[$state2,${transition.stackAction[1]},$state1]',
              ],
            ));
          }
        }
      }
    }
    
    // Step 3: Create start variable
    final startVariable = 'S';
    variables.add(startVariable);
    
    // Add productions from start variable to initial state
    if (pda.initialState != null) {
      for (final finalState in pda.finalStates) {
        productions.add(Production(
          leftSide: startVariable,
          rightSide: ['[${pda.initialState!.id},Z0,$finalState]'],
        ));
      }
    }
    
    // Step 4: Create terminals from input alphabet
    final terminals = pda.inputAlphabet.symbols.toList();
    
    return ContextFreeGrammar(
      id: 'cfg_${pda.id}',
      name: 'CFG(${pda.name})',
      variables: variables,
      terminals: terminals,
      productions: productions,
      startVariable: startVariable,
      metadata: AutomatonMetadata(
        type: 'pda_cfg',
        description: 'CFG from PDA ${pda.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Convert PDA to CFG using alternative method
  static ContextFreeGrammar convertAlternative(PushdownAutomaton pda) {
    // This method uses a different approach for PDA to CFG conversion
    final variables = <String>[];
    final productions = <Production>[];
    
    // Create variables for each state
    for (final state in pda.states) {
      variables.add(state.id);
    }
    
    // Create productions based on transitions
    for (final transition in pda.transitions) {
      if (transition.stackAction == Alphabet.epsilon) {
        // Pop transition
        productions.add(Production(
          leftSide: transition.from,
          rightSide: [transition.inputSymbol, transition.to],
        ));
      } else if (transition.stackAction.length == 1) {
        // Replace transition
        productions.add(Production(
          leftSide: transition.from,
          rightSide: [transition.inputSymbol, transition.to],
        ));
      } else if (transition.stackAction.length == 2) {
        // Push transition
        productions.add(Production(
          leftSide: transition.from,
          rightSide: [transition.inputSymbol, transition.to],
        ));
      }
    }
    
    // Create terminals
    final terminals = pda.inputAlphabet.symbols.toList();
    
    return ContextFreeGrammar(
      id: 'cfg_alt_${pda.id}',
      name: 'CFG(Alt)(${pda.name})',
      variables: variables,
      terminals: terminals,
      productions: productions,
      startVariable: pda.initialState?.id ?? 'q0',
      metadata: AutomatonMetadata(
        type: 'pda_cfg_alt',
        description: 'Alternative CFG from PDA ${pda.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Optimize CFG by removing useless symbols
  static ContextFreeGrammar optimize(ContextFreeGrammar cfg) {
    // Remove useless symbols
    final usefulVariables = _findUsefulVariables(cfg);
    final usefulTerminals = _findUsefulTerminals(cfg, usefulVariables);
    
    // Filter productions
    final usefulProductions = cfg.productions.where((production) {
      return usefulVariables.contains(production.leftSide) &&
             production.rightSide.every((symbol) => 
               usefulVariables.contains(symbol) || 
               usefulTerminals.contains(symbol));
    }).toList();
    
    return ContextFreeGrammar(
      id: 'optimized_${cfg.id}',
      name: 'Optimized ${cfg.name}',
      variables: usefulVariables.toList(),
      terminals: usefulTerminals.toList(),
      productions: usefulProductions,
      startVariable: cfg.startVariable,
      metadata: AutomatonMetadata(
        type: 'optimized_cfg',
        description: 'Optimized CFG from ${cfg.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Find useful variables in CFG
  static Set<String> _findUsefulVariables(ContextFreeGrammar cfg) {
    final useful = <String>{};
    var changed = true;
    
    while (changed) {
      changed = false;
      
      for (final production in cfg.productions) {
        if (production.rightSide.every((symbol) => 
            cfg.terminals.contains(symbol) || useful.contains(symbol))) {
          if (!useful.contains(production.leftSide)) {
            useful.add(production.leftSide);
            changed = true;
          }
        }
      }
    }
    
    return useful;
  }

  /// Find useful terminals in CFG
  static Set<String> _findUsefulTerminals(
    ContextFreeGrammar cfg,
    Set<String> usefulVariables,
  ) {
    final useful = <String>{};
    
    for (final production in cfg.productions) {
      if (usefulVariables.contains(production.leftSide)) {
        for (final symbol in production.rightSide) {
          if (cfg.terminals.contains(symbol)) {
            useful.add(symbol);
          }
        }
      }
    }
    
    return useful;
  }

  /// Convert CFG to Chomsky Normal Form
  static ContextFreeGrammar convertToCNF(ContextFreeGrammar cfg) {
    // This would implement the full CNF conversion
    // For now, return the original grammar
    return cfg;
  }

  /// Get conversion statistics
  static ConversionStats getStats(PushdownAutomaton pda, ContextFreeGrammar cfg) {
    return ConversionStats(
      pdaStateCount: pda.states.length,
      pdaTransitionCount: pda.transitions.length,
      cfgVariableCount: cfg.variables.length,
      cfgProductionCount: cfg.productions.length,
      cfgTerminalCount: cfg.terminals.length,
    );
  }
}

/// Statistics about PDA to CFG conversion
class ConversionStats {
  final int pdaStateCount;
  final int pdaTransitionCount;
  final int cfgVariableCount;
  final int cfgProductionCount;
  final int cfgTerminalCount;

  const ConversionStats({
    required this.pdaStateCount,
    required this.pdaTransitionCount,
    required this.cfgVariableCount,
    required this.cfgProductionCount,
    required this.cfgTerminalCount,
  });

  @override
  String toString() {
    return 'ConversionStats('
        'pdaStates: $pdaStateCount, '
        'pdaTransitions: $pdaTransitionCount, '
        'cfgVariables: $cfgVariableCount, '
        'cfgProductions: $cfgProductionCount, '
        'cfgTerminals: $cfgTerminalCount)';
  }
}
