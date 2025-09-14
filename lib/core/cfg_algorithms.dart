import 'cfg.dart';
import 'algo_log.dart';

/// Result of a parsing operation
class ParseResult {
  final bool accepted;
  final List<CFGProduction> derivation;
  final String explanation;

  ParseResult({
    required this.accepted,
    required this.derivation,
    required this.explanation,
  });
}

/// Result of CNF conversion
class CNFConversionResult {
  final ContextFreeGrammar cnfGrammar;
  final List<String> steps;
  final bool success;

  CNFConversionResult({
    required this.cnfGrammar,
    required this.steps,
    required this.success,
  });
}

/// Algorithms for Context-Free Grammars
class CFGAlgorithms {
  
  /// Convert a CFG to Chomsky Normal Form (CNF)
  static CNFConversionResult convertToCNF(ContextFreeGrammar grammar) {
    AlgoLog.startAlgo('cnfConversion', 'Conversão para Forma Normal de Chomsky');
    AlgoLog.add('Iniciando conversão da gramática para CNF');
    
    final steps = <String>[];
    final result = grammar.copy();
    
    try {
      // Step 1: Remove lambda productions (except for start variable)
      steps.add('1. Removendo produções lambda');
      _removeLambdaProductions(result, steps);
      
      // Step 2: Remove unit productions
      steps.add('2. Removendo produções unitárias');
      _removeUnitProductions(result, steps);
      
      // Step 3: Replace terminals with variables
      steps.add('3. Substituindo terminais por variáveis');
      _replaceTerminalsWithVariables(result, steps);
      
      // Step 4: Break long productions into binary productions
      steps.add('4. Quebrando produções longas em produções binárias');
      _breakLongProductions(result, steps);
      
      AlgoLog.add('Conversão para CNF concluída com sucesso');
      return CNFConversionResult(
        cnfGrammar: result,
        steps: steps,
        success: true,
      );
    } catch (e) {
      AlgoLog.add('Erro na conversão para CNF: $e');
      return CNFConversionResult(
        cnfGrammar: grammar,
        steps: steps,
        success: false,
      );
    }
  }

  /// Remove lambda productions (except for start variable)
  static void _removeLambdaProductions(ContextFreeGrammar grammar, List<String> steps) {
    final lambdaProds = grammar.getLambdaProductions();
    final lambdaVars = <String>{};
    
    for (final prod in lambdaProds) {
      if (prod.leftHandSide != grammar.startVariable) {
        lambdaVars.add(prod.leftHandSide);
        grammar.removeProduction(prod);
        steps.add('  Removida: ${prod.toString()}');
      }
    }
    
    // For each variable that can derive lambda, add new productions
    for (final lambdaVar in lambdaVars) {
      final prods = grammar.getProductionsFor(lambdaVar);
      for (final prod in prods) {
        if (prod.rightHandSide.contains(lambdaVar)) {
          // Add production with lambdaVar removed
          final newRhs = prod.rightHandSide.replaceAll(lambdaVar, '');
          if (newRhs.isNotEmpty) {
            final newProd = CFGProduction(prod.leftHandSide, newRhs);
            if (!grammar.productions.contains(newProd)) {
              grammar.addProduction(newProd);
              steps.add('  Adicionada: ${newProd.toString()}');
            }
          }
        }
      }
    }
  }

  /// Remove unit productions
  static void _removeUnitProductions(ContextFreeGrammar grammar, List<String> steps) {
    final unitProds = grammar.getUnitProductions();
    
    for (final unitProd in unitProds) {
      final lhs = unitProd.leftHandSide;
      final rhs = unitProd.rightHandSide;
      
      // Remove the unit production
      grammar.removeProduction(unitProd);
      steps.add('  Removida: ${unitProd.toString()}');
      
      // Add all productions from rhs to lhs
      final rhsProds = grammar.getProductionsFor(rhs);
      for (final rhsProd in rhsProds) {
        final newProd = CFGProduction(lhs, rhsProd.rightHandSide);
        if (!grammar.productions.contains(newProd)) {
          grammar.addProduction(newProd);
          steps.add('  Adicionada: ${newProd.toString()}');
        }
      }
    }
  }

  /// Replace terminals with variables
  static void _replaceTerminalsWithVariables(ContextFreeGrammar grammar, List<String> steps) {
    final terminalToVar = <String, String>{};
    int varCounter = 0;
    
    // Create new variables for terminals
    for (final terminal in grammar.terminals) {
      final newVar = 'T${varCounter++}';
      terminalToVar[terminal] = newVar;
      grammar.variables.add(newVar);
    }
    
    // Replace terminals in productions
    final productionsToUpdate = <CFGProduction>[];
    for (final prod in grammar.productions) {
      if (prod.rightHandSide.length > 1) {
        String newRhs = prod.rightHandSide;
        for (final entry in terminalToVar.entries) {
          newRhs = newRhs.replaceAll(entry.key, entry.value);
        }
        
        if (newRhs != prod.rightHandSide) {
          productionsToUpdate.add(prod);
        }
      }
    }
    
    // Update productions
    for (final prod in productionsToUpdate) {
      grammar.removeProduction(prod);
      String newRhs = prod.rightHandSide;
      for (final entry in terminalToVar.entries) {
        newRhs = newRhs.replaceAll(entry.key, entry.value);
      }
      final newProd = CFGProduction(prod.leftHandSide, newRhs);
      grammar.addProduction(newProd);
      steps.add('  Atualizada: ${prod.toString()} → ${newProd.toString()}');
    }
    
    // Add terminal productions
    for (final entry in terminalToVar.entries) {
      final terminalProd = CFGProduction(entry.value, entry.key);
      grammar.addProduction(terminalProd);
      steps.add('  Adicionada: ${terminalProd.toString()}');
    }
  }

  /// Break long productions into binary productions
  static void _breakLongProductions(ContextFreeGrammar grammar, List<String> steps) {
    final productionsToUpdate = <CFGProduction>[];
    int varCounter = 0;
    
    for (final prod in grammar.productions) {
      if (prod.rightHandSide.length > 2) {
        productionsToUpdate.add(prod);
      }
    }
    
    for (final prod in productionsToUpdate) {
      grammar.removeProduction(prod);
      steps.add('  Removida: ${prod.toString()}');
      
      final rhs = prod.rightHandSide;
      final lhs = prod.leftHandSide;
      
      if (rhs.length == 3) {
        // A -> BCD becomes A -> BE, E -> CD
        final newVar = 'V${varCounter++}';
        grammar.variables.add(newVar);
        
        final prod1 = CFGProduction(lhs, '${rhs[0]}$newVar');
        final prod2 = CFGProduction(newVar, rhs.substring(1));
        
        grammar.addProduction(prod1);
        grammar.addProduction(prod2);
        
        steps.add('  Adicionada: ${prod1.toString()}');
        steps.add('  Adicionada: ${prod2.toString()}');
      } else if (rhs.length > 3) {
        // A -> BCDE... becomes A -> BF, F -> CG, G -> DH, etc.
        final newVars = <String>[];
        for (int i = 0; i < rhs.length - 2; i++) {
          final newVar = 'V${varCounter++}';
          newVars.add(newVar);
          grammar.variables.add(newVar);
        }
        
        // First production: A -> B[first new var]
        final firstProd = CFGProduction(lhs, '${rhs[0]}${newVars[0]}');
        grammar.addProduction(firstProd);
        steps.add('  Adicionada: ${firstProd.toString()}');
        
        // Middle productions: V_i -> C[V_{i+1}]
        for (int i = 0; i < newVars.length - 1; i++) {
          final prod = CFGProduction(newVars[i], '${rhs[i + 1]}${newVars[i + 1]}');
          grammar.addProduction(prod);
          steps.add('  Adicionada: ${prod.toString()}');
        }
        
        // Last production: V_{n-1} -> CD
        final lastProd = CFGProduction(newVars.last, rhs.substring(rhs.length - 2));
        grammar.addProduction(lastProd);
        steps.add('  Adicionada: ${lastProd.toString()}');
      }
    }
  }

  /// CYK (Cocke-Younger-Kasami) parsing algorithm
  static ParseResult cykParse(ContextFreeGrammar grammar, String input) {
    AlgoLog.startAlgo('cykParse', 'Algoritmo CYK - Parsing de Gramática Livre de Contexto');
    AlgoLog.add('Parsing da string: "$input"');
    
    if (input.isEmpty) {
      // Check if grammar accepts empty string
      final hasLambdaStart = grammar.productions.any((p) => 
          p.leftHandSide == grammar.startVariable && p.isLambdaProduction);
      
      return ParseResult(
        accepted: hasLambdaStart,
        derivation: hasLambdaStart ? [CFGProduction(grammar.startVariable, 'λ')] : [],
        explanation: hasLambdaStart ? 'Gramática aceita string vazia' : 'Gramática não aceita string vazia',
      );
    }
    
    final n = input.length;
    final table = List.generate(n, (i) => List.generate(n, (j) => <String>{}));
    
    // Fill diagonal (length 1 substrings)
    for (int i = 0; i < n; i++) {
      final symbol = input[i];
      for (final prod in grammar.productions) {
        if (prod.rightHandSide == symbol) {
          table[i][i].add(prod.leftHandSide);
        }
      }
      
      if (table[i][i].isEmpty) {
        AlgoLog.add('Símbolo "$symbol" na posição $i não pode ser derivado');
        return ParseResult(
          accepted: false,
          derivation: [],
          explanation: 'Símbolo "$symbol" não pode ser derivado pela gramática',
        );
      }
    }
    
    // Fill table for longer substrings
    for (int length = 2; length <= n; length++) {
      for (int i = 0; i <= n - length; i++) {
        final j = i + length - 1;
        
        for (int k = i; k < j; k++) {
          final leftVars = table[i][k];
          final rightVars = table[k + 1][j];
          
          for (final leftVar in leftVars) {
            for (final rightVar in rightVars) {
              final target = leftVar + rightVar;
              for (final prod in grammar.productions) {
                if (prod.rightHandSide == target) {
                  table[i][j].add(prod.leftHandSide);
                }
              }
            }
          }
        }
      }
    }
    
    final accepted = table[0][n - 1].contains(grammar.startVariable);
    
    if (accepted) {
      AlgoLog.add('String aceita pela gramática');
      final derivation = _buildDerivation(grammar, input, table, 0, n - 1, grammar.startVariable);
      return ParseResult(
        accepted: true,
        derivation: derivation,
        explanation: 'String aceita pela gramática',
      );
    } else {
      AlgoLog.add('String rejeitada pela gramática');
      return ParseResult(
        accepted: false,
        derivation: [],
        explanation: 'String não pode ser derivada pela gramática',
      );
    }
  }

  /// Build derivation tree from CYK table
  static List<CFGProduction> _buildDerivation(
    ContextFreeGrammar grammar,
    String input,
    List<List<Set<String>>> table,
    int i,
    int j,
    String variable,
  ) {
    if (i == j) {
      // Terminal production
      final symbol = input[i];
      return [CFGProduction(variable, symbol)];
    }
    
    // Find the split point
    for (int k = i; k < j; k++) {
      final leftVars = table[i][k];
      final rightVars = table[k + 1][j];
      
      for (final leftVar in leftVars) {
        for (final rightVar in rightVars) {
          final target = leftVar + rightVar;
          for (final prod in grammar.productions) {
            if (prod.rightHandSide == target && prod.leftHandSide == variable) {
              final leftDerivation = _buildDerivation(grammar, input, table, i, k, leftVar);
              final rightDerivation = _buildDerivation(grammar, input, table, k + 1, j, rightVar);
              
              return [prod, ...leftDerivation, ...rightDerivation];
            }
          }
        }
      }
    }
    
    return [];
  }

  /// Check if a grammar is in CNF
  static bool isInCNF(ContextFreeGrammar grammar) {
    for (final prod in grammar.productions) {
      // Skip lambda production for start variable
      if (prod.isLambdaProduction && prod.leftHandSide == grammar.startVariable) {
        continue;
      }
      
      // All other productions must be either terminal or binary
      if (!prod.isTerminalProduction && !prod.isBinaryProduction) {
        return false;
      }
    }
    return true;
  }

  /// Check if a grammar is in GNF (Greibach Normal Form)
  static bool isInGNF(ContextFreeGrammar grammar) {
    for (final prod in grammar.productions) {
      // Skip lambda production for start variable
      if (prod.isLambdaProduction && prod.leftHandSide == grammar.startVariable) {
        continue;
      }
      
      // All other productions must start with a terminal
      if (prod.rightHandSide.isEmpty || 
          !_isTerminal(prod.rightHandSide[0])) {
        return false;
      }
    }
    return true;
  }

  /// Remove useless productions (productions that can't be reached or can't derive terminals)
  static ContextFreeGrammar removeUselessProductions(ContextFreeGrammar grammar) {
    AlgoLog.startAlgo('removeUseless', 'Remoção de Produções Inúteis');
    
    final result = grammar.copy();
    
    // Step 1: Remove non-generating variables
    final generating = <String>{};
    bool changed = true;
    
    while (changed) {
      changed = false;
      for (final prod in result.productions) {
        if (prod.isTerminalProduction || 
            prod.rightHandSide.split('').every((s) => generating.contains(s))) {
          if (!generating.contains(prod.leftHandSide)) {
            generating.add(prod.leftHandSide);
            changed = true;
          }
        }
      }
    }
    
    // Remove productions with non-generating variables
    result.productions.removeWhere((prod) => 
        !generating.contains(prod.leftHandSide) ||
        !prod.rightHandSide.split('').every((s) => 
            generating.contains(s) || _isTerminal(s)));
    
    // Step 2: Remove unreachable variables
    final reachable = <String>{grammar.startVariable};
    changed = true;
    
    while (changed) {
      changed = false;
      for (final prod in result.productions) {
        if (reachable.contains(prod.leftHandSide)) {
          for (final symbol in prod.rightHandSide.split('')) {
            if (_isVariable(symbol) && !reachable.contains(symbol)) {
              reachable.add(symbol);
              changed = true;
            }
          }
        }
      }
    }
    
    // Remove productions with unreachable variables
    result.productions.removeWhere((prod) => !reachable.contains(prod.leftHandSide));
    
    // Clean up unused variables and terminals
    _cleanupUnusedSymbols(result);
    
    AlgoLog.add('Produções inúteis removidas');
    return result;
  }

  /// Helper function to check if a character is a terminal
  static bool _isTerminal(String char) {
    return char.length == 1 && char == char.toLowerCase() && char != 'λ' && char != 'ε';
  }

  /// Helper function to check if a character is a variable
  static bool _isVariable(String char) {
    return char.length == 1 && char == char.toUpperCase() && char != 'λ' && char != 'ε';
  }

  /// Helper function to clean up unused symbols
  static void _cleanupUnusedSymbols(ContextFreeGrammar grammar) {
    final usedVariables = <String>{};
    final usedTerminals = <String>{};
    
    for (final production in grammar.productions) {
      usedVariables.addAll(production.getVariables());
      usedTerminals.addAll(production.getTerminals());
    }
    
    grammar.variables.removeWhere((v) => !usedVariables.contains(v));
    grammar.terminals.removeWhere((t) => !usedTerminals.contains(t));
  }

  /// Convert CFG to PDA (Pushdown Automaton)
  static Map<String, dynamic> cfgToPDA(ContextFreeGrammar grammar) {
    AlgoLog.startAlgo('cfgToPDA', 'Conversão CFG → PDA');
    
    final states = <String>['q0', 'q1', 'q2'];
    final alphabet = Set<String>.from(grammar.terminals);
    final stackAlphabet = <String>{};
    final transitions = <String, List<Map<String, dynamic>>>{};
    
    // Add variables to stack alphabet
    stackAlphabet.addAll(grammar.variables);
    stackAlphabet.add('Z0'); // Bottom of stack marker
    
    // Initial transition: q0 -- ε,ε → SZ0 --> q1
    transitions['q0'] = [
      {
        'read': 'ε',
        'pop': 'ε',
        'push': '${grammar.startVariable}Z0',
        'to': 'q1',
      }
    ];
    
    // Production transitions: q1 -- ε,A → α --> q1
    for (final prod in grammar.productions) {
      final lhs = prod.leftHandSide;
      final rhs = prod.rightHandSide;
      
      if (rhs == 'λ') {
        // A → λ becomes ε,A → ε
        transitions['q1'] ??= [];
        transitions['q1']!.add({
          'read': 'ε',
          'pop': lhs,
          'push': 'ε',
          'to': 'q1',
        });
      } else {
        // A → α becomes ε,A → α (reversed)
        final reversedRhs = rhs.split('').reversed.join('');
        transitions['q1'] ??= [];
        transitions['q1']!.add({
          'read': 'ε',
          'pop': lhs,
          'push': reversedRhs,
          'to': 'q1',
        });
      }
    }
    
    // Terminal transitions: q1 -- a,a → ε --> q1
    for (final terminal in grammar.terminals) {
      transitions['q1'] ??= [];
      transitions['q1']!.add({
        'read': terminal,
        'pop': terminal,
        'push': 'ε',
        'to': 'q1',
      });
    }
    
    // Final transition: q1 -- ε,Z0 → ε --> q2
    transitions['q1'] ??= [];
    transitions['q1']!.add({
      'read': 'ε',
      'pop': 'Z0',
      'push': 'ε',
      'to': 'q2',
    });
    
    AlgoLog.add('PDA criado com ${states.length} estados e ${transitions.length} transições');
    
    return {
      'states': states,
      'alphabet': alphabet.toList(),
      'stackAlphabet': stackAlphabet.toList(),
      'transitions': transitions,
      'initialState': 'q0',
      'finalStates': ['q2'],
    };
  }
}
