//
//  grammar_parser_simple.dart
//  JFlutter
//
//  Fornece um analisador recursivo descentralizado para gramáticas livres de
//  contexto, cobrindo validação de entrada, derivações vazias e controle de
//  tempo durante a busca.
//  A rotina percorre produções, deriva símbolos recursivamente e encapsula o
//  resultado em estruturas de ParseResult compatíveis com o restante da
//  plataforma.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/grammar.dart';
import '../models/production.dart';
import '../models/parse_table.dart';
import '../result.dart';
import 'grammar_parser.dart';

/// Simple grammar parser that can handle basic CFG parsing
class SimpleGrammarParser {
  /// Parses a string using a grammar with a simple approach
  static Result<ParseResult> parse(
    Grammar grammar,
    String inputString, {
    Duration timeout = const Duration(seconds: 5),
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
        return const Failure('Cannot parse with empty grammar');
      }

      // Handle grammar with no start symbol
      if (grammar.startSymbol.isEmpty) {
        return const Failure('Grammar must have a start symbol');
      }

      // Parse the string using simple recursive descent
      final result = _parseString(grammar, inputString, timeout);
      stopwatch.stop();

      if (result != null) {
        return Success(result.copyWith(executionTime: stopwatch.elapsed));
      } else {
        return Failure('String "$inputString" cannot be derived from grammar');
      }
    } catch (e) {
      return Failure('Error parsing string: $e');
    }
  }

  /// Validates the input grammar and string
  static Result<void> _validateInput(Grammar grammar, String inputString) {
    if (grammar.productions.isEmpty) {
      return const Failure('Grammar must have at least one production');
    }

    if (grammar.startSymbol.isEmpty) {
      return const Failure('Grammar must have a start symbol');
    }

    if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
      return const Failure('Start symbol must be a non-terminal');
    }

    // Validate input string symbols
    for (int i = 0; i < inputString.length; i++) {
      final symbol = inputString[i];
      if (!grammar.terminals.contains(symbol)) {
        return Failure('Input string contains invalid symbol: $symbol');
      }
    }

    return const Success(null);
  }

  /// Parses the string using simple recursive descent
  static ParseResult? _parseString(
    Grammar grammar,
    String inputString,
    Duration timeout,
  ) {
    final startTime = DateTime.now();

    // Handle empty string case
    if (inputString.isEmpty) {
      if (_canDeriveEmptyString(grammar, grammar.startSymbol)) {
        return ParseResult.success(
          inputString: inputString,
          derivations: [
            [grammar.startSymbol],
          ],
          executionTime: DateTime.now().difference(startTime),
        );
      }
      return null;
    }

    // Try to parse the string
    final result = _parseNonTerminal(
      grammar,
      grammar.startSymbol,
      inputString,
      startTime,
      timeout,
    );

    if (result != null) {
      return ParseResult.success(
        inputString: inputString,
        derivations: [result],
        executionTime: DateTime.now().difference(startTime),
      );
    }

    return null;
  }

  /// Parses a non-terminal against a string
  static List<String>? _parseNonTerminal(
    Grammar grammar,
    String nonTerminal,
    String inputString,
    DateTime startTime,
    Duration timeout,
  ) {
    // Check timeout
    if (DateTime.now().difference(startTime) > timeout) {
      return null;
    }

    // If input is empty, check if non-terminal can derive empty string
    if (inputString.isEmpty) {
      if (_canDeriveEmptyString(grammar, nonTerminal)) {
        return [nonTerminal];
      }
      return null;
    }

    // Try all productions for this non-terminal
    for (final production in grammar.productions) {
      if (production.leftSide.isNotEmpty &&
          production.leftSide.first == nonTerminal) {
        // Handle epsilon productions
        if (production.rightSide.isEmpty || production.isLambda) {
          if (inputString.isEmpty) {
            return [nonTerminal];
          }
          continue;
        }

        // Handle terminal productions
        if (production.rightSide.length == 1 &&
            grammar.terminals.contains(production.rightSide.first)) {
          if (inputString == production.rightSide.first) {
            return [nonTerminal, production.rightSide.first];
          }
          continue;
        }

        // Handle non-terminal productions
        if (production.rightSide.length == 1 &&
            grammar.nonTerminals.contains(production.rightSide.first)) {
          final result = _parseNonTerminal(
            grammar,
            production.rightSide.first,
            inputString,
            startTime,
            timeout,
          );
          if (result != null) {
            return [nonTerminal, ...result];
          }
        }

        // Handle productions with multiple symbols
        if (production.rightSide.length > 1) {
          // Try to split the input string in all possible ways
          for (int split = 0; split <= inputString.length; split++) {
            final leftPart = inputString.substring(0, split);
            final rightPart = inputString.substring(split);

            if (production.rightSide.length == 2) {
              final leftResult = _parseNonTerminal(
                grammar,
                production.rightSide[0],
                leftPart,
                startTime,
                timeout,
              );
              final rightResult = _parseNonTerminal(
                grammar,
                production.rightSide[1],
                rightPart,
                startTime,
                timeout,
              );

              if (leftResult != null && rightResult != null) {
                return [nonTerminal, ...leftResult, ...rightResult];
              }
            }
          }
        }
      }
    }

    return null;
  }

  /// Checks if a non-terminal can derive the empty string
  static bool _canDeriveEmptyString(Grammar grammar, String nonTerminal) {
    return _canDeriveEmptyStringFromSymbol(grammar, nonTerminal, <String>{});
  }

  /// Recursively checks if a symbol can derive empty string
  static bool _canDeriveEmptyStringFromSymbol(
    Grammar grammar,
    String symbol,
    Set<String> visited,
  ) {
    if (visited.contains(symbol)) {
      return false; // Avoid infinite recursion
    }
    visited.add(symbol);

    for (final production in grammar.productions) {
      if (production.leftSide.isNotEmpty &&
          production.leftSide.first == symbol) {
        if (production.rightSide.isEmpty || production.isLambda) {
          return true; // Direct epsilon production
        }

        // Check if all symbols in right side can derive empty string
        bool allCanDeriveEmpty = true;
        for (final rightSymbol in production.rightSide) {
          if (grammar.terminals.contains(rightSymbol)) {
            allCanDeriveEmpty = false;
            break;
          }
          if (!_canDeriveEmptyStringFromSymbol(
            grammar,
            rightSymbol,
            Set.from(visited),
          )) {
            allCanDeriveEmpty = false;
            break;
          }
        }
        if (allCanDeriveEmpty) {
          return true;
        }
      }
    }

    return false;
  }
}
