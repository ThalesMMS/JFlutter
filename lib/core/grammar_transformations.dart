import 'automaton.dart';
import 'algo_log.dart';

/// Represents a grammar production rule
class Production {
  final String leftHandSide;
  final String rightHandSide;
  final bool isUnit;
  final bool isLambda;

  Production(this.leftHandSide, this.rightHandSide)
      : isUnit = _isUnitProduction(leftHandSide, rightHandSide),
        isLambda = _isLambdaProduction(rightHandSide);

  static bool _isUnitProduction(String lhs, String rhs) {
    // Unit production: A -> B where B is a single non-terminal
    return rhs.length == 1 && rhs.toUpperCase() == rhs && rhs != 'λ';
  }

  static bool _isLambdaProduction(String rhs) {
    return rhs == 'λ' || rhs == 'epsilon' || rhs == 'ε' || rhs.isEmpty;
  }

  @override
  String toString() => '$leftHandSide -> $rightHandSide';

  @override
  bool operator ==(Object other) =>
      other is Production &&
      leftHandSide == other.leftHandSide &&
      rightHandSide == other.rightHandSide;

  @override
  int get hashCode => Object.hash(leftHandSide, rightHandSide);
}

/// Represents a context-free grammar
class Grammar {
  final Set<String> variables;
  final Set<String> terminals;
  final String startVariable;
  final List<Production> productions;

  Grammar({
    required this.variables,
    required this.terminals,
    required this.startVariable,
    required this.productions,
  });

  /// Parse grammar from string representation
  static Grammar fromString(String raw) {
    final lines = raw
        .split(RegExp(r'\n+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final variables = <String>{};
    final terminals = <String>{};
    final productions = <Production>[];
    String? startVar;

    for (final line in lines) {
      final parts = line.split('->');
      if (parts.length != 2) continue;
      
      final lhs = parts[0].trim();
      final rhs = parts[1].trim();
      
      startVar ??= lhs;
      variables.add(lhs);
      
      final prods = rhs.split('|').map((p) => p.trim()).where((p) => p.isNotEmpty);
      for (final prod in prods) {
        productions.add(Production(lhs, prod));
        
        // Extract terminals and variables from right-hand side
        for (final char in prod.split('')) {
          if (char.isNotEmpty) {
            if (char == char.toUpperCase() && char != 'λ' && char != 'ε') {
              variables.add(char);
            } else if (char != 'λ' && char != 'ε') {
              terminals.add(char);
            }
          }
        }
      }
    }

    return Grammar(
      variables: variables,
      terminals: terminals,
      startVariable: startVar ?? '',
      productions: productions,
    );
  }

  /// Convert grammar to string representation
  String toString() {
    final prodMap = <String, List<String>>{};
    for (final prod in productions) {
      (prodMap[prod.leftHandSide] ??= []).add(prod.rightHandSide);
    }
    
    final lines = <String>[];
    for (final entry in prodMap.entries) {
      lines.add('${entry.key} -> ${entry.value.join(' | ')}');
    }
    
    return lines.join('\n');
  }

  /// Get all unit productions
  List<Production> getUnitProductions() {
    return productions.where((p) => p.isUnit).toList();
  }

  /// Get all lambda productions
  List<Production> getLambdaProductions() {
    return productions.where((p) => p.isLambda).toList();
  }

  /// Get all non-unit productions
  List<Production> getNonUnitProductions() {
    return productions.where((p) => !p.isUnit).toList();
  }

  /// Get productions for a specific variable
  List<Production> getProductionsForVariable(String variable) {
    return productions.where((p) => p.leftHandSide == variable).toList();
  }

  /// Check if grammar has unit productions
  bool hasUnitProductions() {
    return productions.any((p) => p.isUnit);
  }

  /// Check if grammar has lambda productions
  bool hasLambdaProductions() {
    return productions.any((p) => p.isLambda);
  }
}

/// Grammar transformation operations
class GrammarTransformations {
  /// Remove unit productions from grammar
  static Grammar removeUnitProductions(Grammar grammar) {
    AlgoLog.startAlgo('removeUnitProductions', 'Remoção de Produções Unitárias');
    
    final unitProds = grammar.getUnitProductions();
    if (unitProds.isEmpty) {
      AlgoLog.add('Nenhuma produção unitária encontrada');
      return grammar;
    }

    AlgoLog.add('Produções unitárias encontradas: ${unitProds.length}');
    for (final prod in unitProds) {
      AlgoLog.add('  $prod');
    }

    // Build variable dependency graph
    final dependencies = <String, Set<String>>{};
    for (final prod in unitProds) {
      (dependencies[prod.leftHandSide] ??= {}).add(prod.rightHandSide);
    }

    AlgoLog.add('Grafo de dependências construído');

    // Start with non-unit productions
    final newProductions = <Production>[];
    for (final prod in grammar.getNonUnitProductions()) {
      newProductions.add(prod);
    }

    AlgoLog.add('Produções não-unitárias copiadas: ${newProductions.length}');

    // Add productions to replace unit productions
    for (final entry in dependencies.entries) {
      final fromVar = entry.key;
      final toVars = entry.value;
      
      for (final toVar in toVars) {
        // Get all non-unit productions for the target variable
        final targetProds = grammar.getProductionsForVariable(toVar)
            .where((p) => !p.isUnit)
            .toList();
        
        // Add new productions: fromVar -> rhs for each targetProd
        for (final targetProd in targetProds) {
          final newProd = Production(fromVar, targetProd.rightHandSide);
          if (!newProductions.contains(newProd)) {
            newProductions.add(newProd);
            AlgoLog.add('Nova produção: $newProd (substitui $fromVar -> $toVar)');
          }
        }
      }
    }

    final result = Grammar(
      variables: grammar.variables,
      terminals: grammar.terminals,
      startVariable: grammar.startVariable,
      productions: newProductions,
    );

    AlgoLog.step('removeUnitProductions', 'complete', data: {
      'original_productions': grammar.productions.length,
      'new_productions': newProductions.length,
      'unit_removed': unitProds.length,
    });

    return result;
  }

  /// Remove lambda productions from grammar
  static Grammar removeLambdaProductions(Grammar grammar) {
    AlgoLog.startAlgo('removeLambdaProductions', 'Remoção de Produções Lambda');
    
    final lambdaProds = grammar.getLambdaProductions();
    if (lambdaProds.isEmpty) {
      AlgoLog.add('Nenhuma produção lambda encontrada');
      return grammar;
    }

    AlgoLog.add('Produções lambda encontradas: ${lambdaProds.length}');
    for (final prod in lambdaProds) {
      AlgoLog.add('  $prod');
    }

    // Find all variables that can derive lambda
    final lambdaDerivers = <String>{};
    for (final prod in lambdaProds) {
      lambdaDerivers.add(prod.leftHandSide);
    }

    // Expand lambda derivations
    bool changed = true;
    while (changed) {
      changed = false;
      for (final prod in grammar.productions) {
        if (prod.isLambda) continue;
        
        // Check if all variables in RHS can derive lambda
        final rhsVars = prod.rightHandSide.split('')
            .where((c) => c == c.toUpperCase() && c != 'λ' && c != 'ε')
            .toSet();
        
        if (rhsVars.isNotEmpty && rhsVars.every((v) => lambdaDerivers.contains(v))) {
          if (lambdaDerivers.add(prod.leftHandSide)) {
            changed = true;
            AlgoLog.add('Variável ${prod.leftHandSide} pode derivar lambda');
          }
        }
      }
    }

    AlgoLog.add('Variáveis que derivam lambda: ${lambdaDerivers.join(', ')}');

    // Create new productions
    final newProductions = <Production>[];
    
    for (final prod in grammar.productions) {
      if (prod.isLambda) continue;
      
      // Add original production
      newProductions.add(prod);
      
      // Generate all possible combinations by removing lambda-deriving variables
      final combinations = _generateCombinations(prod.rightHandSide, lambdaDerivers);
      for (final combo in combinations) {
        if (combo.isNotEmpty && combo != prod.rightHandSide) {
          final newProd = Production(prod.leftHandSide, combo);
          if (!newProductions.contains(newProd)) {
            newProductions.add(newProd);
            AlgoLog.add('Nova produção: $newProd');
          }
        }
      }
    }

    // Handle start variable
    String newStartVar = grammar.startVariable;
    if (lambdaDerivers.contains(grammar.startVariable)) {
      newStartVar = '${grammar.startVariable}\'';
      newProductions.add(Production(newStartVar, grammar.startVariable));
      newProductions.add(Production(newStartVar, 'λ'));
      AlgoLog.add('Novo símbolo inicial: $newStartVar');
    }

    final result = Grammar(
      variables: {...grammar.variables, if (newStartVar != grammar.startVariable) newStartVar},
      terminals: grammar.terminals,
      startVariable: newStartVar,
      productions: newProductions,
    );

    AlgoLog.step('removeLambdaProductions', 'complete', data: {
      'original_productions': grammar.productions.length,
      'new_productions': newProductions.length,
      'lambda_removed': lambdaProds.length,
    });

    return result;
  }

  /// Generate all combinations by removing lambda-deriving variables
  static List<String> _generateCombinations(String rhs, Set<String> lambdaDerivers) {
    final combinations = <String>{};
    final chars = rhs.split('');
    
    void generate(int index, String current) {
      if (index == chars.length) {
        if (current.isNotEmpty) {
          combinations.add(current);
        }
        return;
      }
      
      final char = chars[index];
      if (lambdaDerivers.contains(char)) {
        // Include the character
        generate(index + 1, current + char);
        // Exclude the character (lambda derivation)
        generate(index + 1, current);
      } else {
        // Must include non-lambda-deriving characters
        generate(index + 1, current + char);
      }
    }
    
    generate(0, '');
    return combinations.toList();
  }

  /// Remove useless productions from grammar
  static Grammar removeUselessProductions(Grammar grammar) {
    AlgoLog.startAlgo('removeUselessProductions', 'Remoção de Produções Inúteis');
    
    // Step 1: Remove non-generating variables
    final generating = <String>{};
    bool changed = true;
    
    while (changed) {
      changed = false;
      for (final prod in grammar.productions) {
        if (prod.isLambda) {
          if (generating.add(prod.leftHandSide)) {
            changed = true;
            AlgoLog.add('Variável ${prod.leftHandSide} é geradora (produz lambda)');
          }
        } else {
          // Check if all variables in RHS are generating or terminals
          final rhsVars = prod.rightHandSide.split('')
              .where((c) => c == c.toUpperCase() && c != 'λ' && c != 'ε')
              .toSet();
          
          if (rhsVars.every((v) => generating.contains(v))) {
            if (generating.add(prod.leftHandSide)) {
              changed = true;
              AlgoLog.add('Variável ${prod.leftHandSide} é geradora');
            }
          }
        }
      }
    }

    AlgoLog.add('Variáveis geradoras: ${generating.join(', ')}');

    // Step 2: Remove non-reachable variables
    final reachable = <String>{grammar.startVariable};
    final queue = [grammar.startVariable];
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final prod in grammar.productions) {
        if (prod.leftHandSide == current && !prod.isLambda) {
          final rhsVars = prod.rightHandSide.split('')
              .where((c) => c == c.toUpperCase() && c != 'λ' && c != 'ε')
              .toSet();
          
          for (final v in rhsVars) {
            if (reachable.add(v)) {
              queue.add(v);
              AlgoLog.add('Variável $v é alcançável');
            }
          }
        }
      }
    }

    AlgoLog.add('Variáveis alcançáveis: ${reachable.join(', ')}');

    // Step 3: Keep only useful productions
    final usefulVars = generating.intersection(reachable);
    final usefulProductions = grammar.productions.where((prod) {
      return usefulVars.contains(prod.leftHandSide) &&
             prod.rightHandSide.split('')
                 .where((c) => c == c.toUpperCase() && c != 'λ' && c != 'ε')
                 .every((v) => usefulVars.contains(v));
    }).toList();

    AlgoLog.add('Produções úteis: ${usefulProductions.length}');

    final result = Grammar(
      variables: usefulVars,
      terminals: grammar.terminals,
      startVariable: grammar.startVariable,
      productions: usefulProductions,
    );

    AlgoLog.step('removeUselessProductions', 'complete', data: {
      'original_productions': grammar.productions.length,
      'useful_productions': usefulProductions.length,
      'generating_vars': generating.length,
      'reachable_vars': reachable.length,
    });

    return result;
  }

  /// Convert grammar to Chomsky Normal Form
  static Grammar toChomskyNormalForm(Grammar grammar) {
    AlgoLog.startAlgo('toChomskyNormalForm', 'Conversão para Forma Normal de Chomsky');
    
    var result = grammar;
    
    // Step 1: Remove lambda productions
    if (result.hasLambdaProductions()) {
      AlgoLog.add('Removendo produções lambda...');
      result = removeLambdaProductions(result);
    }
    
    // Step 2: Remove unit productions
    if (result.hasUnitProductions()) {
      AlgoLog.add('Removendo produções unitárias...');
      result = removeUnitProductions(result);
    }
    
    // Step 3: Remove useless productions
    AlgoLog.add('Removendo produções inúteis...');
    result = removeUselessProductions(result);
    
    // Step 4: Convert to CNF
    final cnfProductions = <Production>[];
    final newVars = <String>{};
    int varCounter = 0;
    String newVar() => 'X${varCounter++}';
    
    for (final prod in result.productions) {
      if (prod.isLambda) {
        // Lambda productions should already be removed
        continue;
      } else if (prod.rightHandSide.length == 1) {
        // Single terminal or variable
        cnfProductions.add(prod);
      } else if (prod.rightHandSide.length == 2) {
        // Two symbols - check if both are variables
        final chars = prod.rightHandSide.split('');
        if (chars.every((c) => c == c.toUpperCase())) {
          cnfProductions.add(prod);
        } else {
          // Replace terminals with new variables
          String newRhs = prod.rightHandSide;
          for (final char in chars) {
            if (char != char.toUpperCase()) {
              final newVarName = newVar();
              newVars.add(newVarName);
              newRhs = newRhs.replaceFirst(char, newVarName);
              cnfProductions.add(Production(newVarName, char));
            }
          }
          cnfProductions.add(Production(prod.leftHandSide, newRhs));
        }
      } else {
        // Long production - break into binary productions
        final chars = prod.rightHandSide.split('');
        String currentLhs = prod.leftHandSide;
        
        for (int i = 0; i < chars.length - 2; i++) {
          final newVarName = newVar();
          newVars.add(newVarName);
          cnfProductions.add(Production(currentLhs, chars[i] + newVarName));
          currentLhs = newVarName;
        }
        
        // Last production
        cnfProductions.add(Production(currentLhs, chars[chars.length - 2] + chars[chars.length - 1]));
      }
    }

    final cnfResult = Grammar(
      variables: {...result.variables, ...newVars},
      terminals: result.terminals,
      startVariable: result.startVariable,
      productions: cnfProductions,
    );

    AlgoLog.step('toChomskyNormalForm', 'complete', data: {
      'original_productions': grammar.productions.length,
      'cnf_productions': cnfProductions.length,
      'new_variables': newVars.length,
    });

    return cnfResult;
  }

  /// Analyze grammar properties
  static Map<String, dynamic> analyzeGrammar(Grammar grammar) {
    return {
      'variables': grammar.variables.length,
      'terminals': grammar.terminals.length,
      'productions': grammar.productions.length,
      'unit_productions': grammar.getUnitProductions().length,
      'lambda_productions': grammar.getLambdaProductions().length,
      'has_unit_productions': grammar.hasUnitProductions(),
      'has_lambda_productions': grammar.hasLambdaProductions(),
      'start_variable': grammar.startVariable,
    };
  }
}
