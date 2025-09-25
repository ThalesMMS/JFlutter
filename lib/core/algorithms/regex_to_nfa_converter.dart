import '../models/fsa.dart';
import '../result.dart';
import '../regex/ast.dart';
import '../regex/parser.dart';

/// Converts regular expressions into NFAs by delegating to the PetitParser-based
/// AST pipeline and Thompson compiler.
class RegexToNFAConverter {
  /// Parses [pattern] and returns the resulting NFA.
  static Result<FSA> convert(
    String pattern, {
    Set<String>? wildcardAlphabet,
  }) {
    if (pattern.trim().isEmpty) {
      return ResultFactory.failure('Regular expression cannot be empty');
    }

    final astResult = RegexExpressionParser.parse(pattern);
    if (astResult.isFailure) {
      return ResultFactory.failure(astResult.error!);
    }

    final ast = astResult.data!;
    final compilation = RegexThompsonCompiler.compile(
      ast: ast,
      pattern: pattern,
      wildcardAlphabet: wildcardAlphabet,
    );

    if (compilation.isFailure) {
      return ResultFactory.failure(compilation.error!);
    }

    return ResultFactory.success(compilation.data!);
  }

  /// Parses [pattern] and returns the AST, exposing intermediate analysis data.
  static Result<RegexAst> parseAst(String pattern) =>
      RegexExpressionParser.parse(pattern);
}
