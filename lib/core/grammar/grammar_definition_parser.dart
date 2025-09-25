import 'package:petitparser/parser.dart' as petit;
import 'package:petitparser/src/core/result.dart' as petit_result;

import '../result.dart' as core_result;

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

  static final petit.Parser<List<GrammarProductionAst>> _productionParser =
      _buildParser();

  /// Parses [source] and returns an analysis bundle with AST and errors.
  static core_result.Result<GrammarDefinitionAnalysis> parse(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return core_result.ResultFactory.failure(
        'Grammar definition cannot be empty.',
      );
    }

    try {
      final parseResult = _productionParser.parse(trimmed);
      if (parseResult is petit_result.Success<List<GrammarProductionAst>>) {
        final ast = GrammarAst(productions: parseResult.value);
        final errors = ast.validate();
        return core_result.ResultFactory.success(
          GrammarDefinitionAnalysis(ast: ast, errors: errors),
        );
      }

      final failure = parseResult as petit_result.Failure;
      return core_result.ResultFactory.failure(
        '${failure.message} at position ${failure.position}',
      );
    } on FormatException catch (error) {
      return core_result.ResultFactory.failure(error.message);
    }
  }

  static petit.Parser<List<GrammarProductionAst>> _buildParser() {
    final commentBody = petit.any().starLazy(petit.newline()).flatten();
    final comment = (petit.string('//') | petit.char('#'))
        .seq(commentBody)
        .seq(petit.newline().optional())
        .flatten();

    final globalIgnored = (petit.whitespace() | comment).star();
    final inlineIgnored = petit.pattern(' \t\r\f').star();

    petit.Parser<T> tokenGlobal<T>(petit.Parser<T> parser) =>
        parser.skip(before: globalIgnored, after: globalIgnored);
    petit.Parser<T> tokenInline<T>(petit.Parser<T> parser) =>
        parser.skip(before: inlineIgnored, after: inlineIgnored);

    final nonTerminal =
        (petit.pattern('A-Z') & petit.pattern('A-Za-z0-9_').star())
            .flatten()
            .map((value) => NonTerminalSymbolAst(value));

    final singleQuoted = petit
        .pattern(r"^'\")
        .starLazy(petit.char("'"))
        .flatten()
        .skip(before: petit.char("'"), after: petit.char("'"))
        .map((value) => value.replaceAll(r"\'", "'"));

    final doubleQuoted = petit
        .pattern(r'^"\')
        .starLazy(petit.char('"'))
        .flatten()
        .skip(before: petit.char('"'), after: petit.char('"'))
        .map((value) => value.replaceAll(r'\"', '"'));

    final bareTerminal = petit.pattern('a-z0-9').plusString();

    final terminal = (singleQuoted | doubleQuoted | bareTerminal)
        .map((value) => TerminalSymbolAst(value));

    final epsilonLiteral =
        (petit.string('ε') | petit.string('lambda') | petit.string('eps'))
            .map((_) => const _EpsilonToken());

    final symbol = tokenInline(
      epsilonLiteral
          .cast<Object>()
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
          throw const FormatException(
            'Epsilon cannot appear with other symbols in a production alternative.',
          );
        }
        return const GrammarEmptyExpressionAst();
      }

      return GrammarSequenceAst(concrete);
    });

    final alternativeList =
        sequence.plusSeparated(tokenInline(petit.char('|'))).map(
              (separated) =>
                  List<GrammarExpressionAst>.unmodifiable(separated.elements),
            );

    final arrow = tokenInline(
        petit.string('->') | petit.string('→') | petit.string('::='));

    final production =
        tokenGlobal(nonTerminal).seq(arrow).seq(alternativeList).map((value) {
      final head = (value[0] as NonTerminalSymbolAst).lexeme;
      final alternatives = (value[2] as List<GrammarExpressionAst>);
      return GrammarProductionAst(head: head, alternatives: alternatives);
    });

    final separator =
        (petit.char(';') | petit.newline()).plus().skip(after: globalIgnored);

    final productions = production.plusSeparated(separator).map(
          (separated) =>
              List<GrammarProductionAst>.unmodifiable(separated.elements),
        );

    final parser = globalIgnored
        .optional()
        .seq(productions)
        .seq(globalIgnored.optional())
        .map((value) => value[1] as List<GrammarProductionAst>);

    return parser.end();
  }
}

class _EpsilonToken {
  const _EpsilonToken();
}
