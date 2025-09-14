
/// Represents a production rule in a context-free grammar
class CFGProduction {
  final String leftHandSide;
  final String rightHandSide;

  CFGProduction(this.leftHandSide, this.rightHandSide);

  /// Get all variables in this production
  List<String> getVariables() {
    final variables = <String>[];
    
    // Variables on LHS
    for (int i = 0; i < leftHandSide.length; i++) {
      final char = leftHandSide[i];
      if (_isVariable(char)) {
        variables.add(char);
      }
    }
    
    // Variables on RHS
    for (int i = 0; i < rightHandSide.length; i++) {
      final char = rightHandSide[i];
      if (_isVariable(char)) {
        variables.add(char);
      }
    }
    
    return variables.toSet().toList();
  }

  /// Get all terminals in this production
  List<String> getTerminals() {
    final terminals = <String>[];
    
    // Terminals on LHS
    for (int i = 0; i < leftHandSide.length; i++) {
      final char = leftHandSide[i];
      if (_isTerminal(char)) {
        terminals.add(char);
      }
    }
    
    // Terminals on RHS
    for (int i = 0; i < rightHandSide.length; i++) {
      final char = rightHandSide[i];
      if (_isTerminal(char)) {
        terminals.add(char);
      }
    }
    
    return terminals.toSet().toList();
  }

  /// Get all symbols (variables and terminals) in this production
  List<String> getSymbols() {
    final symbols = <String>[];
    symbols.addAll(getVariables());
    symbols.addAll(getTerminals());
    return symbols.toSet().toList();
  }

  /// Get symbols on the right-hand side
  List<String> getSymbolsOnRHS() {
    final symbols = <String>[];
    for (int i = 0; i < rightHandSide.length; i++) {
      symbols.add(rightHandSide[i]);
    }
    return symbols;
  }

  /// Check if this is a unit production (A -> B where B is a single variable)
  bool get isUnitProduction {
    return rightHandSide.length == 1 && _isVariable(rightHandSide[0]);
  }

  /// Check if this is a lambda production (A -> λ)
  bool get isLambdaProduction {
    return rightHandSide == 'λ' || rightHandSide == 'ε' || rightHandSide.isEmpty;
  }

  /// Check if this is a terminal production (A -> a where a is a terminal)
  bool get isTerminalProduction {
    return rightHandSide.length == 1 && _isTerminal(rightHandSide[0]);
  }

  /// Check if this is a binary production (A -> BC where B and C are variables)
  bool get isBinaryProduction {
    return rightHandSide.length == 2 && 
           _isVariable(rightHandSide[0]) && 
           _isVariable(rightHandSide[1]);
  }

  static bool _isVariable(String char) {
    return char.length == 1 && char == char.toUpperCase() && char != 'λ' && char != 'ε';
  }

  static bool _isTerminal(String char) {
    return char.length == 1 && char == char.toLowerCase() && char != 'λ' && char != 'ε';
  }

  @override
  String toString() => '$leftHandSide → $rightHandSide';

  @override
  bool operator ==(Object other) =>
      other is CFGProduction &&
      leftHandSide == other.leftHandSide &&
      rightHandSide == other.rightHandSide;

  @override
  int get hashCode => Object.hash(leftHandSide, rightHandSide);
}

/// Represents a context-free grammar
class ContextFreeGrammar {
  final Set<String> variables;
  final Set<String> terminals;
  final String startVariable;
  final List<CFGProduction> productions;

  ContextFreeGrammar({
    required this.variables,
    required this.terminals,
    required this.startVariable,
    required this.productions,
  });

  /// Create an empty CFG
  factory ContextFreeGrammar.empty() {
    return ContextFreeGrammar(
      variables: <String>{},
      terminals: <String>{},
      startVariable: '',
      productions: <CFGProduction>[],
    );
  }

  /// Parse CFG from string representation
  factory ContextFreeGrammar.fromString(String raw) {
    final lines = raw
        .split(RegExp(r'\n+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final variables = <String>{};
    final terminals = <String>{};
    final productions = <CFGProduction>[];
    String? startVar;

    for (final line in lines) {
      final parts = line.split(RegExp(r'[→-]'));
      if (parts.length != 2) continue;
      
      final lhs = parts[0].trim();
      final rhs = parts[1].trim();
      
      startVar ??= lhs;
      variables.add(lhs);
      
      final prods = rhs.split('|').map((p) => p.trim()).where((p) => p.isNotEmpty);
      for (final prod in prods) {
        final production = CFGProduction(lhs, prod);
        productions.add(production);
        
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

    return ContextFreeGrammar(
      variables: variables,
      terminals: terminals,
      startVariable: startVar ?? '',
      productions: productions,
    );
  }

  /// Add a production to the grammar
  void addProduction(CFGProduction production) {
    if (!productions.contains(production)) {
      productions.add(production);
      
      // Add variables and terminals from the production
      variables.addAll(production.getVariables());
      terminals.addAll(production.getTerminals());
    }
  }

  /// Remove a production from the grammar
  void removeProduction(CFGProduction production) {
    productions.remove(production);
    
    // Remove variables and terminals that are no longer used
    _cleanupUnusedSymbols();
  }

  /// Check if a production is valid for this grammar
  bool isValidProduction(CFGProduction production) {
    // Check if LHS is a single variable
    if (production.leftHandSide.length != 1 || 
        !CFGProduction._isVariable(production.leftHandSide[0])) {
      return false;
    }
    
    // Check if all symbols in RHS are valid
    for (final char in production.rightHandSide.split('')) {
      if (char.isNotEmpty && char != 'λ' && char != 'ε') {
        if (!CFGProduction._isVariable(char) && !CFGProduction._isTerminal(char)) {
          return false;
        }
      }
    }
    
    return true;
  }

  /// Check if a variable is in the grammar
  bool isVariable(String variable) => variables.contains(variable);

  /// Check if a terminal is in the grammar
  bool isTerminal(String terminal) => terminals.contains(terminal);

  /// Get all productions for a given variable
  List<CFGProduction> getProductionsFor(String variable) {
    return productions.where((p) => p.leftHandSide == variable).toList();
  }

  /// Get all unit productions
  List<CFGProduction> getUnitProductions() {
    return productions.where((p) => p.isUnitProduction).toList();
  }

  /// Get all lambda productions
  List<CFGProduction> getLambdaProductions() {
    return productions.where((p) => p.isLambdaProduction).toList();
  }

  /// Get all terminal productions
  List<CFGProduction> getTerminalProductions() {
    return productions.where((p) => p.isTerminalProduction).toList();
  }

  /// Get all binary productions
  List<CFGProduction> getBinaryProductions() {
    return productions.where((p) => p.isBinaryProduction).toList();
  }

  /// Check if the grammar is in Chomsky Normal Form (CNF)
  bool get isInCNF {
    for (final production in productions) {
      // Skip lambda production for start variable
      if (production.isLambdaProduction && production.leftHandSide == startVariable) {
        continue;
      }
      
      // All other productions must be either terminal or binary
      if (!production.isTerminalProduction && !production.isBinaryProduction) {
        return false;
      }
    }
    return true;
  }

  /// Check if the grammar is in Greibach Normal Form (GNF)
  bool get isInGNF {
    for (final production in productions) {
      // Skip lambda production for start variable
      if (production.isLambdaProduction && production.leftHandSide == startVariable) {
        continue;
      }
      
      // All other productions must start with a terminal
      if (production.rightHandSide.isEmpty || 
          !CFGProduction._isTerminal(production.rightHandSide[0])) {
        return false;
      }
    }
    return true;
  }

  /// Convert grammar to string representation
  @override
  String toString() {
    final prodMap = <String, List<String>>{};
    
    for (final production in productions) {
      final lhs = production.leftHandSide;
      final rhs = production.rightHandSide;
      (prodMap[lhs] ??= []).add(rhs);
    }
    
    final lines = <String>[];
    final sortedVars = variables.toList()..sort();
    
    for (final variable in sortedVars) {
      final prods = prodMap[variable] ?? [];
      if (prods.isNotEmpty) {
        lines.add('$variable → ${prods.join(' | ')}');
      }
    }
    
    return lines.isEmpty ? '// Sem produções' : lines.join('\n');
  }

  /// Create a copy of this grammar
  ContextFreeGrammar copy() {
    return ContextFreeGrammar(
      variables: Set.from(variables),
      terminals: Set.from(terminals),
      startVariable: startVariable,
      productions: List.from(productions),
    );
  }

  /// Clean up unused variables and terminals
  void _cleanupUnusedSymbols() {
    final usedVariables = <String>{};
    final usedTerminals = <String>{};
    
    for (final production in productions) {
      usedVariables.addAll(production.getVariables());
      usedTerminals.addAll(production.getTerminals());
    }
    
    variables.removeWhere((v) => !usedVariables.contains(v));
    terminals.removeWhere((t) => !usedTerminals.contains(t));
  }

  /// Validate the grammar structure
  List<String> validate() {
    final errors = <String>[];
    
    if (startVariable.isEmpty) {
      errors.add('Variável inicial não definida');
    } else if (!variables.contains(startVariable)) {
      errors.add('Variável inicial "$startVariable" não está no conjunto de variáveis');
    }
    
    if (productions.isEmpty) {
      errors.add('Gramática não possui produções');
    }
    
    for (final production in productions) {
      if (!isValidProduction(production)) {
        errors.add('Produção inválida: ${production.toString()}');
      }
    }
    
    return errors;
  }

  /// Check if the grammar is well-formed
  bool get isWellFormed => validate().isEmpty;
}
