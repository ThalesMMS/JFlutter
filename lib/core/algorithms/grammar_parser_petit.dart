//
//  grammar_parser_petit.dart
//  JFlutter
//
//  Implementa um analisador de gramáticas baseado no PetitParser, criando
//  combinadores preguiçosos para cada não terminal e tratando produções
//  terminais, não terminais e vazias dentro da mesma arquitetura.
//  Expõe utilitários de validação, construção do parser e execução com
//  relatórios de depuração, controle de tempo e padronização das respostas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:petitparser/petitparser.dart';

import '../models/grammar.dart';
import '../models/production.dart';
import '../result.dart' as jflutter_result;
import 'grammar_parser.dart';

/// Simple grammar parser using PetitParser combinators
class SimpleCFGParser {
  final Grammar grammar;
  final Map<String, Parser> _parsers = {};

  SimpleCFGParser(this.grammar) {
    _buildParsers();
  }

  void _buildParsers() {
    // Initialize all non-terminals with undefined parsers
    for (final nonTerminal in grammar.nonTerminals) {
      _parsers[nonTerminal] = undefined();
    }

    // Build parsers for each non-terminal
    for (final nonTerminal in grammar.nonTerminals) {
      final productions = grammar.productions
          .where(
            (p) => p.leftSide.isNotEmpty && p.leftSide.first == nonTerminal,
          )
          .toList();

      if (productions.isEmpty) {
        _parsers[nonTerminal] = failure(
          message: 'No productions for $nonTerminal',
        );
        continue;
      }

      Parser? parser;
      for (final production in productions) {
        final productionParser = _buildProductionParser(production);
        if (productionParser != null) {
          if (parser == null) {
            parser = productionParser;
          } else {
            parser = parser | productionParser;
          }
        }
      }

      _parsers[nonTerminal] =
          parser ?? failure(message: 'No valid productions for $nonTerminal');
    }
  }

  Parser? _buildProductionParser(Production production) {
    // Handle epsilon productions
    if (production.rightSide.isEmpty || production.isLambda) {
      return epsilon().map((_) => [production.leftSide.first]);
    }

    // Handle single symbol productions
    if (production.rightSide.length == 1) {
      final symbol = production.rightSide.first;

      if (grammar.terminals.contains(symbol)) {
        // Terminal symbol
        return string(symbol).map((_) => [production.leftSide.first, symbol]);
      } else if (grammar.nonTerminals.contains(symbol)) {
        // Non-terminal symbol
        return _parsers[symbol]?.map(
          (result) => [production.leftSide.first, ...result],
        );
      }
    }

    // Handle multi-symbol productions
    if (production.rightSide.length > 1) {
      Parser? sequenceParser;

      for (final symbol in production.rightSide) {
        Parser? symbolParser;

        if (grammar.terminals.contains(symbol)) {
          symbolParser = string(symbol).map((_) => [symbol]);
        } else if (grammar.nonTerminals.contains(symbol)) {
          symbolParser = _parsers[symbol];
        }

        if (symbolParser != null) {
          if (sequenceParser == null) {
            sequenceParser = symbolParser;
          } else {
            sequenceParser = sequenceParser & symbolParser;
          }
        } else {
          return failure(message: 'Invalid symbol: $symbol');
        }
      }

      if (sequenceParser == null) {
        return failure(message: 'No valid sequence parser');
      }

      return sequenceParser.map((result) {
        final List<String> derivation = [production.leftSide.first];
        for (final item in result) {
          if (item is List<String>) {
            derivation.addAll(item);
          } else {
            derivation.add(item.toString());
          }
        }
        return derivation;
      });
    }

    return failure(message: 'Invalid production: ${production.rightSide}');
  }

  Parser getParser() {
    return _parsers[grammar.startSymbol]?.end() ??
        failure(message: 'No parser for start symbol');
  }
}

/// Grammar parser using PetitParser
class GrammarParserPetit {
  /// Parses a string using a grammar with PetitParser
  static jflutter_result.Result<ParseResult> parse(
    Grammar grammar,
    String inputString, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(grammar, inputString);
      if (!validationResult.isSuccess) {
        return jflutter_result.Failure(validationResult.error!);
      }

      // Convert grammar to PetitParser
      print('Building parser for grammar: ${grammar.name}');
      print('Start symbol: ${grammar.startSymbol}');
      print('Non-terminals: ${grammar.nonTerminals}');
      print('Terminals: ${grammar.terminals}');
      print('Productions: ${grammar.productions.length}');

      final parser = _buildParser(grammar);
      if (parser == null) {
        print('Failed to build parser from grammar');
        return const jflutter_result.Failure(
          'Failed to build parser from grammar',
        );
      }

      print('Parser built successfully');

      // Parse the string
      final result = parser.parse(inputString);
      stopwatch.stop();

      if (result is Success) {
        return jflutter_result.Success(
          ParseResult.success(
            inputString: inputString,
            derivations: [result.value],
            executionTime: stopwatch.elapsed,
          ),
        );
      } else {
        // Debug output
        print('PetitParser failed to parse "$inputString": ${result.message}');
        return jflutter_result.Failure(
          'String "$inputString" cannot be derived from grammar',
        );
      }
    } catch (e) {
      return jflutter_result.Failure('Error parsing string: $e');
    }
  }

  /// Validates the input grammar and string
  static jflutter_result.Result<void> _validateInput(
    Grammar grammar,
    String inputString,
  ) {
    if (grammar.productions.isEmpty) {
      return const jflutter_result.Failure(
        'Grammar must have at least one production',
      );
    }

    if (grammar.startSymbol.isEmpty) {
      return const jflutter_result.Failure('Grammar must have a start symbol');
    }

    if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
      return const jflutter_result.Failure(
        'Start symbol must be a non-terminal',
      );
    }

    // Validate input string symbols
    for (int i = 0; i < inputString.length; i++) {
      final symbol = inputString[i];
      if (!grammar.terminals.contains(symbol)) {
        return jflutter_result.Failure(
          'Input string contains invalid symbol: $symbol',
        );
      }
    }

    return const jflutter_result.Success(null);
  }

  /// Builds a PetitParser parser from a Grammar
  static Parser? _buildParser(Grammar grammar) {
    try {
      // Create a simple CFG parser
      final cfgParser = SimpleCFGParser(grammar);

      // Get the parser
      return cfgParser.getParser();
    } catch (e) {
      print('Error building parser: $e');
      return null;
    }
  }
}
