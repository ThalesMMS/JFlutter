import 'package:core_pda/core_pda.dart';
import 'package:core_regex/core_regex.dart';

/// CFG to PDA conversion algorithm
class CFGToPDAConverter {
  /// Convert context-free grammar to pushdown automaton
  static PushdownAutomaton convert(ContextFreeGrammar cfg) {
    // Step 1: Convert CFG to Chomsky Normal Form (CNF)
    final cnfGrammar = _convertToCNF(cfg);
    
    // Step 2: Create PDA from CNF grammar
    final pda = _createPDAFromCNF(cnfGrammar);
    
    return pda;
  }

  /// Convert CFG to Chomsky Normal Form
  static ContextFreeGrammar _convertToCNF(ContextFreeGrammar cfg) {
    // Step 1: Eliminate epsilon productions
    final grammar1 = _eliminateEpsilonProductions(cfg);
    
    // Step 2: Eliminate unit productions
    final grammar2 = _eliminateUnitProductions(grammar1);
    
    // Step 3: Eliminate useless symbols
    final grammar3 = _eliminateUselessSymbols(grammar2);
    
    // Step 4: Convert to CNF
    final cnfGrammar = _convertToCNFProductions(grammar3);
    
    return cnfGrammar;
  }

  /// Eliminate epsilon productions
  static ContextFreeGrammar _eliminateEpsilonProductions(ContextFreeGrammar cfg) {
    // Find nullable variables
    final nullable = <String>{};
    var changed = true;
    
    while (changed) {
      changed = false;
      
      for (final production in cfg.productions) {
        if (production.rightSide.isEmpty) {
          if (!nullable.contains(production.leftSide)) {
            nullable.add(production.leftSide);
            changed = true;
          }
        } else if (production.rightSide.every((symbol) => nullable.contains(symbol))) {
          if (!nullable.contains(production.leftSide)) {
            nullable.add(production.leftSide);
            changed = true;
          }
        }
      }
    }
    
    // Create new productions
    final newProductions = <Production>[];
    
    for (final production in cfg.productions) {
      if (production.rightSide.isEmpty) {
        // Skip epsilon productions
        continue;
      }
      
      // Generate all combinations without nullable symbols
      final combinations = _generateCombinations(production.rightSide, nullable);
      
      for (final combination in combinations) {
        if (combination.isNotEmpty) {
          newProductions.add(Production(
            leftSide: production.leftSide,
            rightSide: combination,
          ));
        }
      }
    }
    
    return ContextFreeGrammar(
      id: 'cnf_${cfg.id}',
      name: 'CNF ${cfg.name}',
      variables: cfg.variables,
      terminals: cfg.terminals,
      productions: newProductions,
      startVariable: cfg.startVariable,
      metadata: AutomatonMetadata(
        type: 'cnf_grammar',
        description: 'CNF grammar from ${cfg.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Generate all combinations without nullable symbols
  static List<List<String>> _generateCombinations(
    List<String> rightSide,
    Set<String> nullable,
  ) {
    final combinations = <List<String>>[];
    final indices = <int>[];
    
    // Find nullable symbol positions
    for (int i = 0; i < rightSide.length; i++) {
      if (nullable.contains(rightSide[i])) {
        indices.add(i);
      }
    }
    
    // Generate all subsets of nullable positions
    final subsets = _generateSubsets(indices);
    
    for (final subset in subsets) {
      final combination = <String>[];
      for (int i = 0; i < rightSide.length; i++) {
        if (!subset.contains(i)) {
          combination.add(rightSide[i]);
        }
      }
      combinations.add(combination);
    }
    
    return combinations;
  }

  /// Generate all subsets of a list
  static List<List<int>> _generateSubsets(List<int> list) {
    final subsets = <List<int>>[];
    final n = list.length;
    
    for (int i = 0; i < (1 << n); i++) {
      final subset = <int>[];
      for (int j = 0; j < n; j++) {
        if ((i & (1 << j)) != 0) {
          subset.add(list[j]);
        }
      }
      subsets.add(subset);
    }
    
    return subsets;
  }

  /// Eliminate unit productions
  static ContextFreeGrammar _eliminateUnitProductions(ContextFreeGrammar cfg) {
    // Find unit productions
    final unitProductions = <Production>[];
    final nonUnitProductions = <Production>[];
    
    for (final production in cfg.productions) {
      if (production.rightSide.length == 1 && 
          cfg.variables.contains(production.rightSide[0])) {
        unitProductions.add(production);
      } else {
        nonUnitProductions.add(production);
      }
    }
    
    // Create new productions by expanding unit productions
    final newProductions = <Production>[...nonUnitProductions];
    
    for (final unitProduction in unitProductions) {
      final leftSide = unitProduction.leftSide;
      final rightSide = unitProduction.rightSide[0];
      
      // Find all productions with rightSide as left side
      final expansions = cfg.productions.where(
        (p) => p.leftSide == rightSide && p.rightSide.length > 1,
      );
      
      for (final expansion in expansions) {
        newProductions.add(Production(
          leftSide: leftSide,
          rightSide: expansion.rightSide,
        ));
      }
    }
    
    return ContextFreeGrammar(
      id: 'no_unit_${cfg.id}',
      name: 'No Unit ${cfg.name}',
      variables: cfg.variables,
      terminals: cfg.terminals,
      productions: newProductions,
      startVariable: cfg.startVariable,
      metadata: AutomatonMetadata(
        type: 'no_unit_grammar',
        description: 'Grammar without unit productions from ${cfg.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Eliminate useless symbols
  static ContextFreeGrammar _eliminateUselessSymbols(ContextFreeGrammar cfg) {
    // Find generating symbols
    final generating = <String>{};
    var changed = true;
    
    while (changed) {
      changed = false;
      
      for (final production in cfg.productions) {
        if (production.rightSide.every((symbol) => 
            cfg.terminals.contains(symbol) || generating.contains(symbol))) {
          if (!generating.contains(production.leftSide)) {
            generating.add(production.leftSide);
            changed = true;
          }
        }
      }
    }
    
    // Find reachable symbols
    final reachable = <String>{cfg.startVariable};
    final workList = <String>[cfg.startVariable];
    
    while (workList.isNotEmpty) {
      final current = workList.removeAt(0);
      
      for (final production in cfg.productions) {
        if (production.leftSide == current) {
          for (final symbol in production.rightSide) {
            if (!reachable.contains(symbol)) {
              reachable.add(symbol);
              workList.add(symbol);
            }
          }
        }
      }
    }
    
    // Filter productions
    final usefulProductions = cfg.productions.where((production) {
      return generating.contains(production.leftSide) &&
             production.rightSide.every((symbol) => 
               cfg.terminals.contains(symbol) || 
               (generating.contains(symbol) && reachable.contains(symbol)));
    }).toList();
    
    return ContextFreeGrammar(
      id: 'useful_${cfg.id}',
      name: 'Useful ${cfg.name}',
      variables: cfg.variables,
      terminals: cfg.terminals,
      productions: usefulProductions,
      startVariable: cfg.startVariable,
      metadata: AutomatonMetadata(
        type: 'useful_grammar',
        description: 'Grammar with useful symbols from ${cfg.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Convert to CNF productions
  static ContextFreeGrammar _convertToCNFProductions(ContextFreeGrammar cfg) {
    final newProductions = <Production>[];
    final newVariables = <String>{...cfg.variables};
    final newTerminals = <String>{...cfg.terminals};
    
    for (final production in cfg.productions) {
      if (production.rightSide.length <= 2) {
        newProductions.add(production);
      } else {
        // Break down long productions
        final breakdown = _breakDownProduction(production, newVariables);
        newProductions.addAll(breakdown);
      }
    }
    
    return ContextFreeGrammar(
      id: 'cnf_final_${cfg.id}',
      name: 'CNF Final ${cfg.name}',
      variables: newVariables.toList(),
      terminals: newTerminals.toList(),
      productions: newProductions,
      startVariable: cfg.startVariable,
      metadata: AutomatonMetadata(
        type: 'cnf_final_grammar',
        description: 'Final CNF grammar from ${cfg.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Break down long productions into CNF
  static List<Production> _breakDownProduction(
    Production production,
    Set<String> newVariables,
  ) {
    final newProductions = <Production>[];
    final rightSide = production.rightSide;
    
    if (rightSide.length <= 2) {
      newProductions.add(production);
      return newProductions;
    }
    
    // Create intermediate variables
    final intermediateVars = <String>[];
    for (int i = 0; i < rightSide.length - 2; i++) {
      final varName = 'X${newVariables.length + i}';
      intermediateVars.add(varName);
      newVariables.add(varName);
    }
    
    // Create productions
    newProductions.add(Production(
      leftSide: production.leftSide,
      rightSide: [rightSide[0], intermediateVars[0]],
    ));
    
    for (int i = 0; i < intermediateVars.length - 1; i++) {
      newProductions.add(Production(
        leftSide: intermediateVars[i],
        rightSide: [rightSide[i + 1], intermediateVars[i + 1]],
      ));
    }
    
    newProductions.add(Production(
      leftSide: intermediateVars.last,
      rightSide: [rightSide[rightSide.length - 2], rightSide[rightSide.length - 1]],
    ));
    
    return newProductions;
  }

  /// Create PDA from CNF grammar
  static PushdownAutomaton _createPDAFromCNF(ContextFreeGrammar cnfGrammar) {
    final states = <State>[];
    final transitions = <PDATransition>[];
    
    // Create states
    final q0 = State(
      id: 'q0',
      name: 'q0',
      isInitial: true,
      isFinal: false,
    );
    
    final q1 = State(
      id: 'q1',
      name: 'q1',
      isInitial: false,
      isFinal: false,
    );
    
    final q2 = State(
      id: 'q2',
      name: 'q2',
      isInitial: false,
      isFinal: true,
    );
    
    states.addAll([q0, q1, q2]);
    
    // Create transitions
    // Transition from q0 to q1 with start symbol on stack
    transitions.add(PDATransition(
      from: q0.id,
      to: q1.id,
      inputSymbol: Alphabet.epsilon,
      stackSymbol: 'Z0',
      stackAction: '${cnfGrammar.startVariable}Z0',
    ));
    
    // Transitions for productions
    for (final production in cnfGrammar.productions) {
      if (production.rightSide.length == 1) {
        // Terminal production: A -> a
        transitions.add(PDATransition(
          from: q1.id,
          to: q1.id,
          inputSymbol: production.rightSide[0],
          stackSymbol: production.leftSide,
          stackAction: Alphabet.epsilon,
        ));
      } else if (production.rightSide.length == 2) {
        // Binary production: A -> BC
        transitions.add(PDATransition(
          from: q1.id,
          to: q1.id,
          inputSymbol: Alphabet.epsilon,
          stackSymbol: production.leftSide,
          stackAction: '${production.rightSide[1]}${production.rightSide[0]}',
        ));
      }
    }
    
    // Transition to final state
    transitions.add(PDATransition(
      from: q1.id,
      to: q2.id,
      inputSymbol: Alphabet.epsilon,
      stackSymbol: 'Z0',
      stackAction: Alphabet.epsilon,
    ));
    
    return PushdownAutomaton(
      id: 'pda_${cnfGrammar.id}',
      name: 'PDA(${cnfGrammar.name})',
      states: states,
      transitions: transitions,
      inputAlphabet: Alphabet(symbols: cnfGrammar.terminals.toSet()),
      stackAlphabet: Alphabet(symbols: {
        'Z0',
        ...cnfGrammar.variables,
        ...cnfGrammar.terminals,
      }),
      initialState: q0,
      finalStates: [q2],
      acceptanceMode: AcceptanceMode.finalState,
      metadata: AutomatonMetadata(
        type: 'cfg_pda',
        description: 'PDA from CFG ${cnfGrammar.name}',
        createdAt: DateTime.now(),
      ),
    );
  }
}
