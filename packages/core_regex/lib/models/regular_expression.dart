import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:core_fa/core_fa.dart';

part 'regular_expression.freezed.dart';
part 'regular_expression.g.dart';

/// Regular Expression implementation using freezed
@freezed
class RegularExpression with _$RegularExpression {
  const factory RegularExpression({
    required String id,
    required String name,
    required String pattern,
    required RegexAst ast,
    required Alphabet alphabet,
    required AutomatonMetadata metadata,
    String? description,
  }) = _RegularExpression;

  factory RegularExpression.fromJson(Map<String, dynamic> json) => _$RegularExpressionFromJson(json);
}

/// Base class for all regular expression AST nodes
abstract class RegexAstNode {
  const RegexAstNode();

  /// Builds a Thompson fragment for this node
  ThompsonFragment buildFragment(ThompsonContext context);

  /// Collects literal symbols referenced by this node
  void collectAlphabet(Set<String> alphabet);
}

/// Represents a parsed regular expression AST
class RegexAst {
  const RegexAst({required this.root});

  /// Root node of the parsed expression tree
  final RegexAstNode root;

  /// Computes the literal alphabet referenced by the regular expression
  Set<String> get literalAlphabet {
    final symbols = <String>{};
    root.collectAlphabet(symbols);
    return symbols;
  }

  /// Builds the Thompson NFA fragment for this AST using the provided context
  ThompsonFragment buildFragment(ThompsonContext context) =>
      root.buildFragment(context);
}

/// Represents a literal symbol in the regex
class RegexLiteralNode extends RegexAstNode {
  const RegexLiteralNode(this.symbol);

  /// Literal symbol recognised by this node
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

/// Represents a wildcard (dot) in the regex
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

/// Represents the empty word (epsilon)
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

/// Represents the empty language ∅
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

/// Represents concatenation of two expressions
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

/// Represents alternation (union) of two expressions
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

/// Represents language intersection
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

/// Represents quantified repetition (Kleene star, plus, optional or {m,n})
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

/// Thompson NFA fragment for building automata
class ThompsonFragment {
  const ThompsonFragment({
    required this.start,
    required this.accept,
    required this.states,
    required this.transitions,
    required this.alphabet,
  });

  final State start;
  final State accept;
  final Set<State> states;
  final Set<Transition> transitions;
  final Set<String> alphabet;
}

/// Context for building Thompson NFA fragments
class ThompsonContext {
  const ThompsonContext({
    required this.wildcardAlphabet,
    required this.createState,
    required this.createSymbolTransition,
    required this.createWildcardTransition,
    required this.createEpsilonFragment,
    required this.concatenate,
    required this.alternate,
    required this.kleeneStar,
    required this.optional,
  });

  static const defaultWildcardAlphabet = {'a', 'b', 'c', '0', '1'};

  final Set<String> wildcardAlphabet;
  final State Function() createState;
  final Transition Function({required State start, required State end, required String symbol}) createSymbolTransition;
  final Transition Function({required State start, required State end}) createWildcardTransition;
  final ThompsonFragment Function() createEpsilonFragment;
  final ThompsonFragment Function(ThompsonFragment left, ThompsonFragment right) concatenate;
  final ThompsonFragment Function(ThompsonFragment left, ThompsonFragment right) alternate;
  final ThompsonFragment Function(ThompsonFragment fragment) kleeneStar;
  final ThompsonFragment Function(ThompsonFragment fragment) optional;
}

/// Extension methods for RegularExpression to provide regex-specific functionality
extension RegularExpressionExtension on RegularExpression {
  /// Validates the regular expression properties
  List<String> validate() {
    final errors = <String>[];
    
    if (id.isEmpty) {
      errors.add('Regular expression ID cannot be empty');
    }
    
    if (name.isEmpty) {
      errors.add('Regular expression name cannot be empty');
    }
    
    if (pattern.isEmpty) {
      errors.add('Regular expression pattern cannot be empty');
    }
    
    // Validate that the alphabet matches the AST alphabet
    final astAlphabet = ast.literalAlphabet;
    final missingSymbols = astAlphabet.difference(alphabet.symbols);
    if (missingSymbols.isNotEmpty) {
      errors.add('Alphabet is missing symbols used in pattern: ${missingSymbols.join(', ')}');
    }
    
    return errors;
  }

  /// Checks if the regular expression is valid
  bool get isValid => validate().isEmpty;

  /// Gets the alphabet symbols used in the pattern
  Set<String> get patternAlphabet => ast.literalAlphabet;

  /// Gets the pattern as a string representation
  String get stringRepresentation => pattern;

  /// Gets the AST as a string representation
  String get astRepresentation => ast.root.toString();

  /// Checks if the pattern contains wildcards
  bool get hasWildcards => ast.root.toString().contains('Dot(.)');

  /// Checks if the pattern contains quantifiers
  bool get hasQuantifiers => ast.root.toString().contains('Quantifier');

  /// Checks if the pattern contains alternation
  bool get hasAlternation => ast.root.toString().contains('Union');

  /// Checks if the pattern contains concatenation
  bool get hasConcatenation => ast.root.toString().contains('Concat');

  /// Gets the complexity of the regular expression
  int get complexity {
    return _calculateComplexity(ast.root);
  }

  int _calculateComplexity(RegexAstNode node) {
    if (node is RegexLiteralNode || node is RegexDotNode || 
        node is RegexEpsilonNode || node is RegexEmptySetNode) {
      return 1;
    }
    
    if (node is RegexConcatenationNode) {
      return 1 + _calculateComplexity(node.left) + _calculateComplexity(node.right);
    }
    
    if (node is RegexAlternationNode) {
      return 1 + _calculateComplexity(node.left) + _calculateComplexity(node.right);
    }
    
    if (node is RegexIntersectionNode) {
      return 1 + _calculateComplexity(node.left) + _calculateComplexity(node.right);
    }
    
    if (node is RegexQuantifierNode) {
      return 1 + _calculateComplexity(node.child);
    }
    
    return 1;
  }

  /// Checks if the pattern is equivalent to another pattern
  bool isEquivalentTo(RegularExpression other) {
    // This is a simplified equivalence check
    // In a full implementation, you would need to build NFAs and check equivalence
    return pattern == other.pattern;
  }

  /// Gets the language described by this regular expression
  String get languageDescription {
    if (ast.root is RegexEpsilonNode) {
      return 'Empty language {ε}';
    }
    
    if (ast.root is RegexEmptySetNode) {
      return 'Empty language ∅';
    }
    
    if (ast.root is RegexLiteralNode) {
      final literal = ast.root as RegexLiteralNode;
      return 'Language containing only the string "${literal.symbol}"';
    }
    
    return 'Language described by pattern: $pattern';
  }
}

/// Factory methods for creating common regular expression patterns
class RegularExpressionFactory {
  /// Creates a regular expression from a pattern string
  static RegularExpression fromPattern({
    required String id,
    required String name,
    required String pattern,
    Alphabet? alphabet,
    String? description,
  }) {
    final now = DateTime.now();
    
    // Create a simple AST for the pattern
    final ast = RegexAst(root: RegexLiteralNode(pattern));
    
    return RegularExpression(
      id: id,
      name: name,
      pattern: pattern,
      ast: ast,
      alphabet: alphabet ?? Alphabet(symbols: {pattern}),
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }

  /// Creates an empty regular expression
  static RegularExpression empty({
    required String id,
    required String name,
    String? description,
  }) {
    final now = DateTime.now();
    final ast = RegexAst(root: RegexEmptySetNode());
    
    return RegularExpression(
      id: id,
      name: name,
      pattern: '∅',
      ast: ast,
      alphabet: const Alphabet(symbols: {}),
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }

  /// Creates an epsilon regular expression
  static RegularExpression epsilon({
    required String id,
    required String name,
    String? description,
  }) {
    final now = DateTime.now();
    final ast = RegexAst(root: RegexEpsilonNode());
    
    return RegularExpression(
      id: id,
      name: name,
      pattern: 'ε',
      ast: ast,
      alphabet: const Alphabet(symbols: {}),
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }

  /// Creates a literal regular expression
  static RegularExpression literal({
    required String id,
    required String name,
    required String symbol,
    String? description,
  }) {
    final now = DateTime.now();
    final ast = RegexAst(root: RegexLiteralNode(symbol));
    
    return RegularExpression(
      id: id,
      name: name,
      pattern: symbol,
      ast: ast,
      alphabet: Alphabet(symbols: {symbol}),
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }

  /// Creates a wildcard regular expression
  static RegularExpression wildcard({
    required String id,
    required String name,
    Alphabet? alphabet,
    String? description,
  }) {
    final now = DateTime.now();
    final ast = RegexAst(root: RegexDotNode());
    
    return RegularExpression(
      id: id,
      name: name,
      pattern: '.',
      ast: ast,
      alphabet: alphabet ?? Alphabet(symbols: ThompsonContext.defaultWildcardAlphabet),
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }

  /// Creates a concatenation regular expression
  static RegularExpression concatenation({
    required String id,
    required String name,
    required RegularExpression left,
    required RegularExpression right,
    String? description,
  }) {
    final now = DateTime.now();
    final ast = RegexAst(
      root: RegexConcatenationNode(left.ast.root, right.ast.root),
    );
    
    return RegularExpression(
      id: id,
      name: name,
      pattern: '${left.pattern}${right.pattern}',
      ast: ast,
      alphabet: Alphabet(symbols: left.alphabet.symbols.union(right.alphabet.symbols)),
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }

  /// Creates an alternation regular expression
  static RegularExpression alternation({
    required String id,
    required String name,
    required RegularExpression left,
    required RegularExpression right,
    String? description,
  }) {
    final now = DateTime.now();
    final ast = RegexAst(
      root: RegexAlternationNode(left.ast.root, right.ast.root),
    );
    
    return RegularExpression(
      id: id,
      name: name,
      pattern: '${left.pattern}|${right.pattern}',
      ast: ast,
      alphabet: Alphabet(symbols: left.alphabet.symbols.union(right.alphabet.symbols)),
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }

  /// Creates a Kleene star regular expression
  static RegularExpression kleeneStar({
    required String id,
    required String name,
    required RegularExpression child,
    String? description,
  }) {
    final now = DateTime.now();
    final ast = RegexAst(
      root: RegexQuantifierNode(child.ast.root, 0, null),
    );
    
    return RegularExpression(
      id: id,
      name: name,
      pattern: '${child.pattern}*',
      ast: ast,
      alphabet: child.alphabet,
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }

  /// Creates a plus regular expression
  static RegularExpression plus({
    required String id,
    required String name,
    required RegularExpression child,
    String? description,
  }) {
    final now = DateTime.now();
    final ast = RegexAst(
      root: RegexQuantifierNode(child.ast.root, 1, null),
    );
    
    return RegularExpression(
      id: id,
      name: name,
      pattern: '${child.pattern}+',
      ast: ast,
      alphabet: child.alphabet,
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }

  /// Creates an optional regular expression
  static RegularExpression optional({
    required String id,
    required String name,
    required RegularExpression child,
    String? description,
  }) {
    final now = DateTime.now();
    final ast = RegexAst(
      root: RegexQuantifierNode(child.ast.root, 0, 1),
    );
    
    return RegularExpression(
      id: id,
      name: name,
      pattern: '${child.pattern}?',
      ast: ast,
      alphabet: child.alphabet,
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
    );
  }
}
