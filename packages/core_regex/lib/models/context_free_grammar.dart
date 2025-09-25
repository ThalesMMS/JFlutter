import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:core_fa/core_fa.dart';
import 'production.dart';

part 'context_free_grammar.freezed.dart';
part 'context_free_grammar.g.dart';

/// Types of grammars in the Chomsky hierarchy
enum GrammarType {
  /// Regular grammar
  regular,
  
  /// Context-free grammar
  contextFree,
  
  /// Context-sensitive grammar
  contextSensitive,
  
  /// Unrestricted grammar
  unrestricted,
}

/// Context-Free Grammar (CFG) implementation using freezed
@freezed
class ContextFreeGrammar with _$ContextFreeGrammar {
  const factory ContextFreeGrammar({
    required String id,
    required String name,
    required Set<String> terminals,
    required Set<String> nonterminals,
    required String startSymbol,
    required Set<Production> productions,
    required GrammarType type,
    required AutomatonMetadata metadata,
  }) = _ContextFreeGrammar;

  factory ContextFreeGrammar.fromJson(Map<String, dynamic> json) => _$ContextFreeGrammarFromJson(json);
}

/// Extension methods for ContextFreeGrammar to provide grammar-specific functionality
extension ContextFreeGrammarExtension on ContextFreeGrammar {
  /// Non-terminals (alias for nonterminals)
  Set<String> get nonTerminals => nonterminals;

  /// Validates the grammar properties
  List<String> validate() {
    final errors = <String>[];
    
    if (id.isEmpty) {
      errors.add('Grammar ID cannot be empty');
    }
    
    if (name.isEmpty) {
      errors.add('Grammar name cannot be empty');
    }
    
    if (terminals.isEmpty) {
      errors.add('Grammar must have at least one terminal symbol');
    }
    
    if (nonterminals.isEmpty) {
      errors.add('Grammar must have at least one non-terminal symbol');
    }
    
    if (startSymbol.isEmpty) {
      errors.add('Grammar must have a start symbol');
    }
    
    if (!nonterminals.contains(startSymbol)) {
      errors.add('Start symbol must be a non-terminal');
    }
    
    if (productions.isEmpty) {
      errors.add('Grammar must have at least one production rule');
    }
    
    // Check for symbol overlap
    final overlap = terminals.intersection(nonterminals);
    if (overlap.isNotEmpty) {
      errors.add('Terminals and non-terminals cannot overlap: ${overlap.join(', ')}');
    }
    
    // Validate each production
    for (final production in productions) {
      final productionErrors = production.validate();
      errors.addAll(productionErrors.map((e) => 'Production ${production.id}: $e'));
      
      // Check if left side contains only non-terminals
      for (final symbol in production.leftSide) {
        if (!nonterminals.contains(symbol)) {
          errors.add('Production ${production.id} left side contains invalid symbol: $symbol');
        }
      }
      
      // Check if right side contains only terminals and non-terminals
      for (final symbol in production.rightSide) {
        if (!terminals.contains(symbol) && !nonterminals.contains(symbol)) {
          errors.add('Production ${production.id} right side contains invalid symbol: $symbol');
        }
      }
    }
    
    // Check for unreachable symbols
    final reachableNonterminals = getReachableNonterminals();
    final unreachableNonterminals = nonterminals.difference(reachableNonterminals);
    if (unreachableNonterminals.isNotEmpty) {
      errors.add('Unreachable non-terminals: ${unreachableNonterminals.join(', ')}');
    }
    
    // Check for unproductive symbols
    final productiveNonterminals = getProductiveNonterminals();
    final unproductiveNonterminals = nonterminals.difference(productiveNonterminals);
    if (unproductiveNonterminals.isNotEmpty) {
      errors.add('Unproductive non-terminals: ${unproductiveNonterminals.join(', ')}');
    }
    
    return errors;
  }

  /// Checks if the grammar is valid
  bool get isValid => validate().isEmpty;

  /// Gets all productions for a given non-terminal
  Set<Production> getProductionsFor(String nonterminal) {
    return productions.where((p) => p.leftSide.contains(nonterminal)).toSet();
  }

  /// Gets all productions that generate a given symbol
  Set<Production> getProductionsGenerating(String symbol) {
    return productions.where((p) => p.generatesSymbol(symbol)).toSet();
  }

  /// Gets all productions that consume a given symbol
  Set<Production> getProductionsConsuming(String symbol) {
    return productions.where((p) => p.consumesSymbol(symbol)).toSet();
  }

  /// Gets all lambda productions
  Set<Production> get lambdaProductions {
    return productions.where((p) => p.isLambda).toSet();
  }

  /// Gets all unit productions
  Set<Production> get unitProductions {
    return productions.where((p) => p.isUnitProduction(nonterminals)).toSet();
  }

  /// Gets all chain productions
  Set<Production> get chainProductions {
    return productions.where((p) => p.isChainProduction()).toSet();
  }

  /// Gets all productive productions
  Set<Production> get productiveProductions {
    return productions.where((p) => p.isProductive(terminals)).toSet();
  }

  /// Gets all terminal productions
  Set<Production> get terminalProductions {
    return productions.where((p) => p.isTerminalProduction(terminals)).toSet();
  }

  /// Gets all non-terminal productions
  Set<Production> get nonTerminalProductions {
    return productions.where((p) => p.isNonTerminalProduction(nonterminals)).toSet();
  }

  /// Gets all reachable non-terminals from the start symbol
  Set<String> getReachableNonterminals() {
    final reachable = <String>{startSymbol};
    final queue = <String>[startSymbol];
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final productionsForCurrent = getProductionsFor(current);
      
      for (final production in productionsForCurrent) {
        for (final symbol in production.rightSide) {
          if (nonterminals.contains(symbol) && !reachable.contains(symbol)) {
            reachable.add(symbol);
            queue.add(symbol);
          }
        }
      }
    }
    
    return reachable;
  }

  /// Gets all productive non-terminals (can derive terminals)
  Set<String> getProductiveNonterminals() {
    final productive = <String>{};
    final queue = <String>[];
    
    // Start with non-terminals that have terminal productions
    for (final production in productions) {
      if (production.isTerminalProduction(terminals)) {
        for (final symbol in production.leftSide) {
          if (nonterminals.contains(symbol) && !productive.contains(symbol)) {
            productive.add(symbol);
            queue.add(symbol);
          }
        }
      }
    }
    
    // Propagate productivity
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      
      for (final production in productions) {
        if (production.rightSide.contains(current) && 
            production.rightSide.every((s) => terminals.contains(s) || productive.contains(s))) {
          for (final symbol in production.leftSide) {
            if (nonterminals.contains(symbol) && !productive.contains(symbol)) {
              productive.add(symbol);
              queue.add(symbol);
            }
          }
        }
      }
    }
    
    return productive;
  }

  /// Gets all useless non-terminals (unreachable or unproductive)
  Set<String> getUselessNonterminals() {
    final reachable = getReachableNonterminals();
    final productive = getProductiveNonterminals();
    return nonterminals.difference(reachable.intersection(productive));
  }

  /// Gets all useless productions (containing useless non-terminals)
  Set<Production> getUselessProductions() {
    final uselessNonterminals = getUselessNonterminals();
    return productions.where((p) => 
        p.leftSide.any((s) => uselessNonterminals.contains(s)) ||
        p.rightSide.any((s) => uselessNonterminals.contains(s))).toSet();
  }

  /// Checks if the grammar is in Chomsky Normal Form (CNF)
  bool get isInChomskyNormalForm {
    for (final production in productions) {
      if (production.isLambda) {
        // Only start symbol can have lambda production
        if (!production.leftSide.contains(startSymbol)) {
          return false;
        }
      } else if (production.rightSide.length == 1) {
        // Must be terminal
        if (!terminals.contains(production.rightSide.first)) {
          return false;
        }
      } else if (production.rightSide.length == 2) {
        // Must be two non-terminals
        if (!nonterminals.contains(production.rightSide[0]) || 
            !nonterminals.contains(production.rightSide[1])) {
          return false;
        }
      } else {
        // Right side must have exactly 1 or 2 symbols
        return false;
      }
    }
    return true;
  }

  /// Checks if the grammar is in Greibach Normal Form (GNF)
  bool get isInGreibachNormalForm {
    for (final production in productions) {
      if (production.isLambda) {
        // Only start symbol can have lambda production
        if (!production.leftSide.contains(startSymbol)) {
          return false;
        }
      } else {
        // Right side must start with terminal
        if (!terminals.contains(production.rightSide.first)) {
          return false;
        }
        // Rest must be non-terminals
        for (int i = 1; i < production.rightSide.length; i++) {
          if (!nonterminals.contains(production.rightSide[i])) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Checks if the grammar is regular (type-3)
  bool get isRegular {
    for (final production in productions) {
      if (production.isLambda) {
        // Only start symbol can have lambda production
        if (!production.leftSide.contains(startSymbol)) {
          return false;
        }
      } else if (production.rightSide.length == 1) {
        // Must be terminal
        if (!terminals.contains(production.rightSide.first)) {
          return false;
        }
      } else if (production.rightSide.length == 2) {
        // Must be terminal followed by non-terminal
        if (!terminals.contains(production.rightSide[0]) || 
            !nonterminals.contains(production.rightSide[1])) {
          return false;
        }
      } else {
        // Right side must have exactly 1 or 2 symbols
        return false;
      }
    }
    return true;
  }

  /// Gets the grammar as a string representation
  String get stringRepresentation {
    final buffer = StringBuffer();
    buffer.writeln('Grammar: $name');
    buffer.writeln('Terminals: ${terminals.join(', ')}');
    buffer.writeln('Non-terminals: ${nonterminals.join(', ')}');
    buffer.writeln('Start symbol: $startSymbol');
    buffer.writeln('Productions:');
    
    for (final production in productions) {
      buffer.writeln('  ${production.stringRepresentation}');
    }
    
    return buffer.toString();
  }

  /// Gets the number of productions
  int get productionCount => productions.length;

  /// Gets the number of terminals
  int get terminalCount => terminals.length;

  /// Gets the number of non-terminals
  int get nonterminalCount => nonterminals.length;
}

/// Factory methods for creating common grammar patterns
class ContextFreeGrammarFactory {
  /// Creates an empty grammar
  static ContextFreeGrammar empty({
    required String id,
    required String name,
    String? description,
  }) {
    final now = DateTime.now();
    return ContextFreeGrammar(
      id: id,
      name: name,
      terminals: {},
      nonterminals: {},
      startSymbol: '',
      productions: {},
      type: GrammarType.contextFree,
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }

  /// Creates a simple grammar with one production
  static ContextFreeGrammar simple({
    required String id,
    required String name,
    required String startSymbol,
    required String terminal,
    String? description,
  }) {
    final now = DateTime.now();
    final production = ProductionFactory.simple(
      id: 'p1',
      leftSide: startSymbol,
      rightSide: terminal,
    );
    
    return ContextFreeGrammar(
      id: id,
      name: name,
      terminals: {terminal},
      nonterminals: {startSymbol},
      startSymbol: startSymbol,
      productions: {production},
      type: GrammarType.contextFree,
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }

  /// Creates a grammar for balanced parentheses
  static ContextFreeGrammar balancedParentheses({
    required String id,
    required String name,
    String? description,
  }) {
    final now = DateTime.now();
    final startSymbol = 'S';
    
    final p1 = ProductionFactory.simple(
      id: 'p1',
      leftSide: startSymbol,
      rightSide: '',
    );
    
    final p2 = ProductionFactory.multiSymbol(
      id: 'p2',
      leftSide: startSymbol,
      rightSide: ['(', startSymbol, ')'],
    );
    
    final p3 = ProductionFactory.multiSymbol(
      id: 'p3',
      leftSide: startSymbol,
      rightSide: [startSymbol, startSymbol],
    );
    
    return ContextFreeGrammar(
      id: id,
      name: name,
      terminals: {'(', ')'},
      nonterminals: {startSymbol},
      startSymbol: startSymbol,
      productions: {p1, p2, p3},
      type: GrammarType.contextFree,
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }

  /// Creates a grammar for arithmetic expressions
  static ContextFreeGrammar arithmeticExpressions({
    required String id,
    required String name,
    String? description,
  }) {
    final now = DateTime.now();
    final startSymbol = 'E';
    
    final p1 = ProductionFactory.simple(
      id: 'p1',
      leftSide: 'E',
      rightSide: 'T',
    );
    
    final p2 = ProductionFactory.multiSymbol(
      id: 'p2',
      leftSide: 'E',
      rightSide: ['E', '+', 'T'],
    );
    
    final p3 = ProductionFactory.simple(
      id: 'p3',
      leftSide: 'T',
      rightSide: 'F',
    );
    
    final p4 = ProductionFactory.multiSymbol(
      id: 'p4',
      leftSide: 'T',
      rightSide: ['T', '*', 'F'],
    );
    
    final p5 = ProductionFactory.simple(
      id: 'p5',
      leftSide: 'F',
      rightSide: 'id',
    );
    
    final p6 = ProductionFactory.multiSymbol(
      id: 'p6',
      leftSide: 'F',
      rightSide: ['(', 'E', ')'],
    );
    
    return ContextFreeGrammar(
      id: id,
      name: name,
      terminals: {'id', '+', '*', '(', ')'},
      nonterminals: {'E', 'T', 'F'},
      startSymbol: startSymbol,
      productions: {p1, p2, p3, p4, p5, p6},
      type: GrammarType.contextFree,
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }
}
