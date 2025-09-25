import '../models/grammar.dart';
import '../models/production.dart';
import '../models/parse_table.dart';
import '../result.dart';

/// Parses strings using context-free grammars
enum ParsingStrategyHint { auto, cyk, ll }

typedef _ParsingStrategy = ParseResult? Function(
  Grammar grammar,
  String inputString,
  Duration timeout,
);

class GrammarParser {
  /// Parses a string using a grammar
  static Result<ParseResult> parse(
    Grammar grammar,
    String inputString, {
    Duration timeout = const Duration(seconds: 5),
    ParsingStrategyHint strategyHint = ParsingStrategyHint.auto,
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(grammar, inputString);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return Failure('Cannot parse with empty grammar');
      }

      // Handle grammar with no start symbol
      if (grammar.startSymbol == null) {
        return Failure('Grammar must have a start symbol');
      }

      // Parse the string
      final strategies = _resolveStrategies(strategyHint);
      final result = _parseString(
        grammar,
        inputString,
        timeout,
        strategies,
        strategyHint,
      );
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error parsing string: $e');
    }
  }

  /// Validates the input grammar and string
  static Result<void> _validateInput(Grammar grammar, String inputString) {
    if (grammar.productions.isEmpty) {
      return Failure('Grammar must have at least one production');
    }
    
    if (grammar.startSymbol == null) {
      return Failure('Grammar must have a start symbol');
    }
    
    if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
      return Failure('Start symbol must be a non-terminal');
    }
    
    // Validate input string symbols
    for (int i = 0; i < inputString.length; i++) {
      final symbol = inputString[i];
      if (!grammar.terminals.contains(symbol)) {
        return Failure('Input string contains invalid symbol: $symbol');
      }
    }
    
    return Success(null);
  }

  /// Parses the string using the grammar
  static ParseResult _parseString(
    Grammar grammar,
    String inputString,
    Duration timeout,
    List<_ParsingStrategy> strategies,
    ParsingStrategyHint strategyHint,
  ) {
    final startTime = DateTime.now();

    for (final strategy in strategies) {
      try {
        final result = strategy(grammar, inputString, timeout);
        if (result != null) {
          return result.copyWith(executionTime: DateTime.now().difference(startTime));
        }
      } catch (e) {
        // Try next strategy
        continue;
      }
    }
    
    // If all strategies fail, return failure
    final failureMessage = strategyHint == ParsingStrategyHint.auto
        ? 'All parsing strategies failed'
        : 'Parsing using the ${_strategyDisplayName(strategyHint)} parser failed';
    return ParseResult.failure(
      inputString: inputString,
      errorMessage: failureMessage,
      executionTime: DateTime.now().difference(startTime),
    );
  }

  static List<_ParsingStrategy> _resolveStrategies(ParsingStrategyHint hint) {
    switch (hint) {
      case ParsingStrategyHint.cyk:
        return [_parseWithCYK];
      case ParsingStrategyHint.ll:
        return [_parseWithLL];
      case ParsingStrategyHint.auto:
      default:
        return [
          _parseWithCYK,
          _parseWithLL,
        ];
    }
  }

  static String _strategyDisplayName(ParsingStrategyHint hint) {
    switch (hint) {
      case ParsingStrategyHint.cyk:
        return 'CYK';
      case ParsingStrategyHint.ll:
        return 'LL';
      case ParsingStrategyHint.auto:
        return 'auto';
    }
  }

  /// Parses using CYK algorithm
  static ParseResult? _parseWithCYK(
    Grammar grammar,
    String inputString,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // Check timeout
    if (DateTime.now().difference(startTime) > timeout) {
      return null;
    }
    
    // Convert grammar to Chomsky Normal Form (simplified)
    final cnfGrammar = _convertToCNF(grammar);
    
    // Apply CYK algorithm
    final n = inputString.length;
    final table = List.generate(n, (i) => List.generate(n, (j) => <String>{}));
    
    // Initialize table for strings of length 1
    for (int i = 0; i < n; i++) {
      final symbol = inputString[i];
      for (final production in cnfGrammar.productions) {
        if (production.rightSide.length == 1 && production.rightSide.first == symbol) {
          table[i][i].add(production.leftSide.first);
        }
      }
    }
    
    // Fill table for longer strings
    for (int length = 2; length <= n; length++) {
      for (int i = 0; i <= n - length; i++) {
        final j = i + length - 1;
        for (int k = i; k < j; k++) {
          for (final production in cnfGrammar.productions) {
            if (production.rightSide.length == 2) {
              final left = production.rightSide.first;
              final right = production.rightSide.last;
              if (table[i][k].contains(left) && table[k + 1][j].contains(right)) {
                table[i][j].add(production.leftSide.first);
              }
            }
          }
        }
      }
    }
    
    // Check if start symbol is in table[0][n-1]
    if (table[0][n - 1].contains(cnfGrammar.startSymbol)) {
      return ParseResult.success(
        inputString: inputString,
        derivations: [], // CYK doesn't provide derivations
        executionTime: DateTime.now().difference(startTime),
      );
    }
    
    return null;
  }

  /// Converts grammar to Chomsky Normal Form (simplified)
  static Grammar _convertToCNF(Grammar grammar) {
    // This is a simplified conversion - in practice, this would be more complex
    final productions = <Production>[];
    
    for (final production in grammar.productions) {
      if (production.rightSide.length <= 2) {
        productions.add(production);
      } else {
        // Break down longer productions (simplified)
        var currentLeft = production.leftSide;
        for (int i = 0; i < production.rightSide.length - 1; i++) {
          final newNonTerminal = '${currentLeft}_${i}';
          if (i == production.rightSide.length - 2) {
            productions.add(Production(
              id: 'p_cnf_${productions.length}',
              leftSide: currentLeft,
              rightSide: [production.rightSide[i], production.rightSide[i + 1]],
            ));
          } else {
            productions.add(Production(
              id: 'p_cnf_${productions.length}',
              leftSide: currentLeft,
              rightSide: [production.rightSide[i], newNonTerminal],
            ));
            currentLeft = [newNonTerminal];
          }
        }
      }
    }
    
    return Grammar(
      id: 'cnf_${grammar.id}',
      name: '${grammar.name} (CNF)',
      productions: productions.toSet(),
      startSymbol: grammar.startSymbol,
      nonterminals: grammar.nonterminals,
      terminals: grammar.terminals,
      type: grammar.type,
      created: DateTime.now(),
      modified: DateTime.now(),
    );
  }

  /// Parses using LL parsing
  static ParseResult? _parseWithLL(
    Grammar grammar,
    String inputString,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // Check timeout
    if (DateTime.now().difference(startTime) > timeout) {
      return null;
    }
    
    // Build LL parse table
    final parseTable = _buildLLParseTable(grammar);
    if (parseTable == null) {
      return null; // Grammar is not LL(1)
    }
    
    // Parse using LL table
    final stack = <String>[grammar.startSymbol!];
    final input = inputString.split('').toList();
    final derivations = <List<String>>[];
    
    while (stack.isNotEmpty) {
      final top = stack.removeLast();
      
      if (grammar.terminals.contains(top)) {
        if (input.isNotEmpty && input[0] == top) {
          input.removeAt(0);
        } else {
          return null; // Parse error
        }
      } else if (grammar.nonTerminals.contains(top)) {
        if (input.isNotEmpty) {
          final symbol = input[0];
          final action = parseTable.getAction(top, symbol);
          if (action != null && action.type == ParseActionType.reduce) {
            final production = action.production!;
            for (int i = production.rightSide.length - 1; i >= 0; i--) {
              stack.add(production.rightSide[i]);
            }
            derivations.add([top, ...production.rightSide]);
          } else {
            return null; // Parse error
          }
        } else {
          return null; // Parse error
        }
      }
    }
    
    if (input.isEmpty) {
      return ParseResult.success(
        inputString: inputString,
        derivations: derivations,
        executionTime: DateTime.now().difference(startTime),
      );
    }
    
    return null;
  }

  /// Builds LL parse table
  static ParseTable? _buildLLParseTable(Grammar grammar) {
    // This is a simplified LL table building - in practice, this would be more complex
    final table = <String, Map<String, ParseAction>>{};
    
    for (final nonTerminal in grammar.nonTerminals) {
      table[nonTerminal] = <String, ParseAction>{};
    }
    
    for (final production in grammar.productions) {
      final leftSide = production.leftSide;
      final rightSide = production.rightSide;
      
      // Calculate FIRST set (simplified)
      final firstSet = _calculateFirst(grammar, rightSide);
      
      for (final terminal in firstSet) {
        if (grammar.terminals.contains(terminal)) {
          table[leftSide.first]![terminal] =
              ParseAction(type: ParseActionType.reduce, production: production);
        }
      }
    }
    
    return ParseTable(
      actionTable: table.map((key, value) => MapEntry(
          key,
          value.map((k, v) => MapEntry(
              k,
              ParseAction(
                type: v.type,
                production: v.production,
              ))))),
      grammar: grammar,
      type: ParseType.ll,
    );
  }

  /// Calculates FIRST set (simplified)
  static Set<String> _calculateFirst(Grammar grammar, List<String> symbols) {
    if (symbols.isEmpty) {
      return {'ε'}; // Epsilon
    }
    
    final first = <String>{};
    final firstSymbol = symbols[0];
    
    if (grammar.terminals.contains(firstSymbol)) {
      first.add(firstSymbol);
    } else if (grammar.nonTerminals.contains(firstSymbol)) {
      // Add FIRST of non-terminal (simplified)
      for (final production in grammar.productions) {
        if (production.leftSide.isNotEmpty && production.leftSide.first == firstSymbol) {
          first.addAll(_calculateFirst(grammar, production.rightSide));
        }
      }
    }
    
    return first;
  }
}

/// Result of parsing a string with a grammar
class ParseResult {
  final String inputString;
  final bool accepted;
  final List<List<String>> derivations;
  final String? errorMessage;
  final Duration executionTime;

  const ParseResult._({
    required this.inputString,
    required this.accepted,
    required this.derivations,
    this.errorMessage,
    required this.executionTime,
  });

  factory ParseResult.success({
    required String inputString,
    required List<List<String>> derivations,
    required Duration executionTime,
  }) {
    return ParseResult._(
      inputString: inputString,
      accepted: true,
      derivations: derivations,
      executionTime: executionTime,
    );
  }

  factory ParseResult.failure({
    required String inputString,
    required String errorMessage,
    required Duration executionTime,
  }) {
    return ParseResult._(
      inputString: inputString,
      accepted: false,
      derivations: [],
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }

  ParseResult copyWith({
    String? inputString,
    bool? accepted,
    List<List<String>>? derivations,
    String? errorMessage,
    Duration? executionTime,
  }) {
    return ParseResult._(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      derivations: derivations ?? this.derivations,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}
