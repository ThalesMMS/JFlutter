import 'package:petitparser/expression.dart';
import 'package:petitparser/parser.dart';

import '../models/fsa.dart';
import '../result.dart';

import 'ast.dart';
import 'thompson.dart';

/// Parser for building [RegexAst] instances using PetitParser's expression
/// builder. Inspired by the reference implementation in the PetitParser
/// [examples repository](https://github.com/petitparser/dart-petitparser-examples/blob/main/lib/src/regexp/parser.dart).
class RegexExpressionParser {
  RegexExpressionParser._();

  static final Parser<RegexAstNode> _nodeParser = _buildParser();

  /// Parses [pattern] into a [RegexAst].
  static Result<RegexAst> parse(String pattern) {
    try {
      final ast = parseAst(pattern);
      return ResultFactory.success(ast);
    } on FormatException catch (error) {
      return ResultFactory.failure(error.message);
    }
  }

  /// Parses [pattern] and returns the AST, throwing [FormatException] on error.
  static RegexAst parseAst(String pattern) {
    final trimmed = pattern.trim();
    final result = _nodeParser.parse(trimmed);
    return switch (result) {
      Success(value: final ast) => RegexAst(root: ast),
      Failure() => throw FormatException('${result.message} at position ${result.position}'),
    };
  }

  static Parser<RegexAstNode> _buildParser() {
    final builder = ExpressionBuilder<RegexAstNode>();

    const meta = r'\\()|*+?&{}.';

    builder.primitive(string('ε').trim().map((_) => const RegexEpsilonNode()));
    builder.primitive(string('eps').trim().map((_) => const RegexEpsilonNode()));
    builder.primitive(string('lambda').trim().map((_) => const RegexEpsilonNode()));
    builder.primitive(string('∅').trim().map((_) => const RegexEmptySetNode()));
    builder.primitive(string('Ø').trim().map((_) => const RegexEmptySetNode()));
    builder.primitive(string('emptyset').trim().map((_) => const RegexEmptySetNode()));
    builder.primitive(char('.').trim().map((_) => const RegexDotNode()));
    builder.primitive(
      anyOf(meta).skip(before: char('\\')).trim().map(RegexLiteralNode.new),
    );
    builder.primitive(
      noneOf(meta).trim().map(RegexLiteralNode.new),
    );

    builder.group().wrapper(
      char('(').trim(),
      char(')').trim(),
      (_, value, __) => value,
    );

    final integer = digit().plusString().trim().map(int.parse);
    final range = seq3(integer.optional(), char(',').trim().optional(), integer.optional())
        .skip(before: char('{'), after: char('}'))
        .map((values) {
      final min = values.$1;
      final comma = values.$2;
      final max = values.$3;
      if (comma == null && max == null) {
        final resolved = min ?? 0;
        return (min: resolved, max: resolved);
      }
      final resolvedMin = min ?? 0;
      return (min: resolvedMin, max: max);
    });

    builder.group()
      ..postfix(char('*').trim(), (exp, _) => RegexQuantifierNode(exp, 0, null))
      ..postfix(char('+').trim(), (exp, _) => RegexQuantifierNode(exp, 1, null))
      ..postfix(char('?').trim(), (exp, _) => RegexQuantifierNode(exp, 0, 1))
      ..postfix(range, (exp, range) {
        final min = range.min;
        final max = range.max;
        if (max != null && max < min) {
          throw FormatException('Quantifier upper bound must be ≥ lower bound');
        }
        return RegexQuantifierNode(exp, min, max);
      });

    builder.group()
      ..left(
        epsilon(),
        (left, _, right) => RegexConcatenationNode(left, right),
      )
      ..optional(const RegexEpsilonNode());

    builder.group()
      ..left(
        char('|').trim(),
        (left, _, right) => RegexAlternationNode(left, right),
      )
      ..left(
        char('&').trim(),
        (left, _, right) => RegexIntersectionNode(left, right),
      );

    return builder.build().trim().end();
  }
}

/// Convenience utility for compiling parsed regex ASTs into NFAs.
class RegexThompsonCompiler {
  /// Compiles [ast] into an [FSA] using Thompson's construction.
  static Result<FSA> compile({
    required RegexAst ast,
    required String pattern,
    Set<String>? wildcardAlphabet,
  }) {
    try {
      final alphabet = <String>{...ast.literalAlphabet};
      if (wildcardAlphabet != null) {
        alphabet.addAll(wildcardAlphabet);
      }
      final context = ThompsonContext(
        wildcardAlphabet: wildcardAlphabet ??
            (alphabet.isEmpty ? ThompsonContext.defaultWildcardAlphabet : alphabet),
      );
      final fragment = ast.buildFragment(context);
      final automaton = context.buildAutomaton(
        fragment: fragment,
        pattern: pattern,
      );
      return ResultFactory.success(automaton);
    } catch (error) {
      return ResultFactory.failure('Failed to compile regex: $error');
    }
  }
}
