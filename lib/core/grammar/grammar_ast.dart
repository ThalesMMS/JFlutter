import '../models/grammar.dart';
import '../models/production.dart';

/// AST representation of a grammar definition. Enables validation, analysis and
/// conversion into the existing [Grammar] model used throughout the app.
class GrammarAst {
  GrammarAst({
    required List<GrammarProductionAst> productions,
    String? startSymbol,
  })  : productions = productions,
        startSymbol = startSymbol ?? (productions.isNotEmpty ? productions.first.head : '');

  /// Ordered list of productions as they appeared in the source definition.
  final List<GrammarProductionAst> productions;

  /// Declared start symbol for the grammar.
  final String startSymbol;

  /// Collected non-terminals (including start symbol and RHS references).
  Set<String> get nonTerminals {
    final symbols = <String>{};
    for (final production in productions) {
      production.collectNonTerminals(symbols);
    }
    return symbols;
  }

  /// Collected terminal symbols from all productions.
  Set<String> get terminals {
    final symbols = <String>{};
    for (final production in productions) {
      production.collectTerminals(symbols);
    }
    return symbols;
  }

  /// Performs structural validation and returns a list of errors.
  List<String> validate() {
    final errors = <String>[];

    if (productions.isEmpty) {
      errors.add('Grammar must declare at least one production.');
      return errors;
    }

    if (startSymbol.isEmpty) {
      errors.add('Grammar start symbol cannot be empty.');
    }

    final declaredHeads = productions.map((p) => p.head).toSet();

    for (final production in productions) {
      if (production.alternatives.isEmpty) {
        errors.add('Production ${production.head} must define at least one alternative.');
      }

      for (final alternative in production.alternatives) {
        if (alternative is GrammarSequenceAst && alternative.symbols.isEmpty) {
          errors.add('Production ${production.head} has an empty alternative.');
        }

        for (final symbol in alternative.nonTerminalSymbols) {
          if (!declaredHeads.contains(symbol.lexeme)) {
            errors.add('Production ${production.head} references undefined non-terminal ${symbol.lexeme}.');
          }
        }
      }
    }

    return errors;
  }

  /// Converts this AST to the existing [Grammar] domain model.
  Grammar toGrammar({
    required String id,
    required String name,
    GrammarType type = GrammarType.contextFree,
  }) {
    final now = DateTime.now();
    final productionSet = <Production>{};
    var order = 0;

    for (final production in productions) {
      for (final alternative in production.alternatives) {
        final prod = Production(
          id: 'p$order',
          leftSide: [production.head],
          rightSide: alternative.toSymbolList(),
          isLambda: alternative.isLambda,
          order: order,
        );
        productionSet.add(prod);
        order++;
      }
    }

    return Grammar(
      id: id,
      name: name,
      terminals: terminals,
      nonterminals: nonTerminals,
      startSymbol: startSymbol,
      productions: productionSet,
      type: type,
      created: now,
      modified: now,
    );
  }
}

/// Represents a single production head with its alternatives.
class GrammarProductionAst {
  const GrammarProductionAst({
    required this.head,
    required this.alternatives,
  });

  final String head;
  final List<GrammarExpressionAst> alternatives;

  void collectTerminals(Set<String> terminals) {
    for (final alternative in alternatives) {
      alternative.collectTerminals(terminals);
    }
  }

  void collectNonTerminals(Set<String> symbols) {
    symbols.add(head);
    for (final alternative in alternatives) {
      alternative.collectNonTerminals(symbols);
    }
  }
}

/// Base class for production right-hand side expressions.
abstract class GrammarExpressionAst {
  const GrammarExpressionAst();

  /// Indicates whether this expression represents a λ-production.
  bool get isLambda;

  /// Converts the expression into a list of grammar symbols.
  List<String> toSymbolList();

  /// Collects terminal symbols used in this expression.
  void collectTerminals(Set<String> terminals);

  /// Collects non-terminal symbols used in this expression.
  void collectNonTerminals(Set<String> nonTerminals);

  /// Non-terminals referenced by this expression.
  Iterable<NonTerminalSymbolAst> get nonTerminalSymbols;
}

/// Sequence of terminals/non-terminals.
class GrammarSequenceAst extends GrammarExpressionAst {
  const GrammarSequenceAst(this.symbols);

  final List<GrammarSymbolAst> symbols;

  @override
  bool get isLambda => false;

  @override
  List<String> toSymbolList() => symbols.map((s) => s.lexeme).toList(growable: false);

  @override
  void collectTerminals(Set<String> terminals) {
    for (final symbol in symbols) {
      if (symbol.isTerminal) {
        terminals.add(symbol.lexeme);
      }
    }
  }

  @override
  void collectNonTerminals(Set<String> nonTerminals) {
    for (final symbol in symbols) {
      if (symbol is NonTerminalSymbolAst) {
        nonTerminals.add(symbol.lexeme);
      }
    }
  }

  @override
  Iterable<NonTerminalSymbolAst> get nonTerminalSymbols sync* {
    for (final symbol in symbols) {
      if (symbol is NonTerminalSymbolAst) {
        yield symbol;
      }
    }
  }
}

/// Empty expression (lambda production).
class GrammarEmptyExpressionAst extends GrammarExpressionAst {
  const GrammarEmptyExpressionAst();

  @override
  bool get isLambda => true;

  @override
  List<String> toSymbolList() => const [];

  @override
  void collectTerminals(Set<String> terminals) {}

  @override
  void collectNonTerminals(Set<String> nonTerminals) {}

  @override
  Iterable<NonTerminalSymbolAst> get nonTerminalSymbols => const Iterable.empty();
}

/// Base representation of a grammar symbol.
abstract class GrammarSymbolAst {
  const GrammarSymbolAst(this.lexeme);

  final String lexeme;

  bool get isTerminal;
}

/// Terminal symbol.
class TerminalSymbolAst extends GrammarSymbolAst {
  const TerminalSymbolAst(super.lexeme);

  @override
  bool get isTerminal => true;
}

/// Non-terminal symbol.
class NonTerminalSymbolAst extends GrammarSymbolAst {
  const NonTerminalSymbolAst(super.lexeme);

  @override
  bool get isTerminal => false;
}
