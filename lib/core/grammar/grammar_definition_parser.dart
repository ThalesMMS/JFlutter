import 'package:petitparser/parser.dart';

import '../result.dart';

import 'grammar_ast.dart';

/// Result bundle containing the parsed AST and validation diagnostics.
class GrammarDefinitionAnalysis {
  const GrammarDefinitionAnalysis({
    required this.ast,
    required this.errors,
  });

  final GrammarAst ast;
  final List<String> errors;

  bool get isValid => errors.isEmpty;

  Set<String> get terminals => ast.terminals;

  Set<String> get nonTerminals => ast.nonTerminals;
}

/// Parser for textual grammar definitions inspired by the PetitParser examples
/// repository, adapted to produce the reusable AST defined in this module.
class GrammarDefinitionParser {
  GrammarDefinitionParser._();

  static final Parser<List<GrammarProductionAst>> _productionParser =
      _buildParser();

  /// Parses [source] and returns an analysis bundle with AST and errors.
  static Result<GrammarDefinitionAnalysis> parse(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return ResultFactory.failure('Grammar definition cannot be empty.');
    }

    try {
      final parseResult = _productionParser.parse(trimmed);
      return switch (parseResult) {
        Success(value: final productions) => () {
          final ast = GrammarAst(productions: productions);
          final errors = ast.validate();
          return ResultFactory.success(
            GrammarDefinitionAnalysis(ast: ast, errors: errors),
          );
        }(),
        Failure() => ResultFactory.failure('${parseResult.message} at position ${parseResult.position}'),
      };
    } on FormatException catch (error) {
      return ResultFactory.failure(error.message);
    }
  }

  static Parser<List<GrammarProductionAst>> _buildParser() {
    final commentBody = any().starLazy(newline()).flatten();
    final comment = (string('//') | char('#'))
        .seq(commentBody)
        .seq(newline().optional())
        .flatten();

    final ignored = (whitespace() | comment).star();

    Parser<T> trim<T>(Parser<T> parser) => parser.trim(ignored, ignored);

    final nonTerminal = (pattern('A-Z') & pattern('A-Za-z0-9_').star())
        .flatten()
        .map((value) => NonTerminalSymbolAst(value));

    final singleQuoted = pattern(r"^'\\")
        .starLazy(char("'"))
        .flatten()
        .skip(before: char("'"), after: char("'"))
        .map((value) => value.replaceAll(r"\'", "'"));

    final doubleQuoted = pattern(r'^"\\')
        .starLazy(char('"'))
        .flatten()
        .skip(before: char('"'), after: char('"'))
        .map((value) => value.replaceAll(r'\"', '"'));

    final bareTerminal = pattern('a-z0-9').plusString();

    final terminal = (singleQuoted | doubleQuoted | bareTerminal)
        .map((value) => TerminalSymbolAst(value));

    final epsilonLiteral =
        (string('ε') | string('lambda') | string('eps')).map((_) => const _EpsilonToken());

    final symbol = trim(
      epsilonLiteral.cast<Object>()
          .or(nonTerminal.cast<Object>())
          .or(terminal.cast<Object>()),
    );

    final sequence = symbol.plus().map((symbols) {
      _EpsilonToken? epsilon;
      final concrete = <GrammarSymbolAst>[];

      for (final item in symbols) {
        if (item is _EpsilonToken) {
          epsilon = item;
        } else if (item is GrammarSymbolAst) {
          concrete.add(item);
        }
      }

      if (epsilon != null) {
        if (concrete.isNotEmpty || symbols.length > 1) {
          throw const FormatException('Epsilon cannot appear with other symbols in a production alternative.');
        }
        return const GrammarEmptyExpressionAst();
      }

      return GrammarSequenceAst(concrete);
    });

    final alternativeList = sequence
        .starSeparated(trim(char('|')))
        .map((alternatives) => alternatives.cast<GrammarExpressionAst>());

    final arrow = trim(string('->') | string('→') | string('::='));

    final production = trim(nonTerminal)
        .seq(arrow)
        .seq(alternativeList)
        .map((value) {
      final head = (value[0] as NonTerminalSymbolAst).lexeme;
      final alternatives = (value[2] as List<GrammarExpressionAst>);
      return GrammarProductionAst(head: head, alternatives: alternatives);
    });

    final separator = trim((char(';') | newline()).plus());

    final productions = production
        .starSeparated(separator.optional())
        .map((list) => list.cast<GrammarProductionAst>());

    return productions.end();
  }
}

class _EpsilonToken {
  const _EpsilonToken();
}
