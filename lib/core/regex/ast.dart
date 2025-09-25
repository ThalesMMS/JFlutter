import 'thompson.dart';

/// Represents a parsed regular expression AST that can be reused across
/// multiple analyses (alphabet inspection, Thompson compilation, pretty print).
class RegexAst {
  /// Creates a [RegexAst] with the provided [root] node.
  const RegexAst({required this.root});

  /// Root node of the parsed expression tree.
  final RegexAstNode root;

  /// Computes the literal alphabet referenced by the regular expression.
  Set<String> get literalAlphabet {
    final symbols = <String>{};
    root.collectAlphabet(symbols);
    return symbols;
  }

  /// Builds the Thompson NFA fragment for this AST using the provided context.
  ThompsonFragment buildFragment(ThompsonContext context) =>
      root.buildFragment(context);
}

/// Base class for all regular expression AST nodes.
abstract class RegexAstNode {
  const RegexAstNode();

  /// Builds a Thompson fragment for this node.
  ThompsonFragment buildFragment(ThompsonContext context);

  /// Collects literal symbols referenced by this node.
  void collectAlphabet(Set<String> alphabet);
}

/// Represents a literal symbol in the regex.
class RegexLiteralNode extends RegexAstNode {
  const RegexLiteralNode(this.symbol);

  /// Literal symbol recognised by this node.
  final String symbol;

  @override
  ThompsonFragment buildFragment(ThompsonContext context) {
    final start = context.createState();
    final accept = context.createState();
    final transition =
        context.createSymbolTransition(start: start, end: accept, symbol: symbol);

    return ThompsonFragment(
      start: start,
      accept: accept,
      states: {start, accept},
      transitions: {transition},
      alphabet: {symbol},
    );
  }

  @override
  void collectAlphabet(Set<String> alphabet) => alphabet.add(symbol);

  @override
  String toString() => 'Literal($symbol)';
}

/// Represents a wildcard (dot) in the regex.
class RegexDotNode extends RegexAstNode {
  const RegexDotNode();

  @override
  ThompsonFragment buildFragment(ThompsonContext context) {
    final start = context.createState();
    final accept = context.createState();
    final transition = context.createWildcardTransition(start: start, end: accept);

    return ThompsonFragment(
      start: start,
      accept: accept,
      states: {start, accept},
      transitions: {transition},
      alphabet: {...context.wildcardAlphabet},
    );
  }

  @override
  void collectAlphabet(Set<String> alphabet) {
    alphabet.addAll(ThompsonContext.defaultWildcardAlphabet);
  }

  @override
  String toString() => 'Dot(.)';
}

/// Represents the empty word (epsilon).
class RegexEpsilonNode extends RegexAstNode {
  const RegexEpsilonNode();

  @override
  ThompsonFragment buildFragment(ThompsonContext context) =>
      context.createEpsilonFragment();

  @override
  void collectAlphabet(Set<String> alphabet) {}

  @override
  String toString() => 'Epsilon(ε)';
}

/// Represents the empty language ∅.
class RegexEmptySetNode extends RegexAstNode {
  const RegexEmptySetNode();

  @override
  ThompsonFragment buildFragment(ThompsonContext context) {
    final start = context.createState();
    final accept = context.createState();
    return ThompsonFragment(
      start: start,
      accept: accept,
      states: {start, accept},
      transitions: const {},
      alphabet: const {},
    );
  }

  @override
  void collectAlphabet(Set<String> alphabet) {}

  @override
  String toString() => 'Empty(∅)';
}

/// Represents concatenation of two expressions.
class RegexConcatenationNode extends RegexAstNode {
  const RegexConcatenationNode(this.left, this.right);

  final RegexAstNode left;
  final RegexAstNode right;

  @override
  ThompsonFragment buildFragment(ThompsonContext context) {
    final leftFragment = left.buildFragment(context);
    final rightFragment = right.buildFragment(context);
    return context.concatenate(leftFragment, rightFragment);
  }

  @override
  void collectAlphabet(Set<String> alphabet) {
    left.collectAlphabet(alphabet);
    right.collectAlphabet(alphabet);
  }

  @override
  String toString() => 'Concat($left, $right)';
}

/// Represents alternation (union) of two expressions.
class RegexAlternationNode extends RegexAstNode {
  const RegexAlternationNode(this.left, this.right);

  final RegexAstNode left;
  final RegexAstNode right;

  @override
  ThompsonFragment buildFragment(ThompsonContext context) {
    final leftFragment = left.buildFragment(context);
    final rightFragment = right.buildFragment(context);
    return context.alternate(leftFragment, rightFragment);
  }

  @override
  void collectAlphabet(Set<String> alphabet) {
    left.collectAlphabet(alphabet);
    right.collectAlphabet(alphabet);
  }

  @override
  String toString() => 'Union($left, $right)';
}

/// Represents language intersection.
class RegexIntersectionNode extends RegexAstNode {
  const RegexIntersectionNode(this.left, this.right);

  final RegexAstNode left;
  final RegexAstNode right;

  @override
  ThompsonFragment buildFragment(ThompsonContext context) {
    throw UnsupportedError('Intersection is not supported in Thompson compilation');
  }

  @override
  void collectAlphabet(Set<String> alphabet) {
    left.collectAlphabet(alphabet);
    right.collectAlphabet(alphabet);
  }

  @override
  String toString() => 'Intersection($left, $right)';
}

/// Represents quantified repetition (Kleene star, plus, optional or {m,n}).
class RegexQuantifierNode extends RegexAstNode {
  const RegexQuantifierNode(this.child, this.min, this.max);

  final RegexAstNode child;
  final int min;
  final int? max;

  @override
  ThompsonFragment buildFragment(ThompsonContext context) {
    if (min == 0 && max == null) {
      final fragment = child.buildFragment(context);
      return context.kleeneStar(fragment);
    }

    if (min == 0 && max == 1) {
      final fragment = child.buildFragment(context);
      return context.optional(fragment);
    }

    if (min == 1 && max == null) {
      final first = child.buildFragment(context);
      final rest = child.buildFragment(context);
      final star = context.kleeneStar(rest);
      return context.concatenate(first, star);
    }

    ThompsonFragment? result;

    for (var i = 0; i < min; i++) {
      final iteration = child.buildFragment(context);
      result = result == null
          ? iteration
          : context.concatenate(result, iteration);
    }

    if (max == null) {
      final star = context.kleeneStar(child.buildFragment(context));
      return result == null ? star : context.concatenate(result, star);
    }

    final optionalCount = max! - min;
    for (var i = 0; i < optionalCount; i++) {
      final option = context.optional(child.buildFragment(context));
      result = result == null ? option : context.concatenate(result, option);
    }

    return result ?? context.createEpsilonFragment();
  }

  @override
  void collectAlphabet(Set<String> alphabet) => child.collectAlphabet(alphabet);

  @override
  String toString() => 'Quantifier($child, min: $min, max: $max)';
}
