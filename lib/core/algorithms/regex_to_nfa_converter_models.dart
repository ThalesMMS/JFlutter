part of 'regex_to_nfa_converter.dart';

/// Abstract base class for regex nodes
abstract class RegexNode {
  final int? position;
  const RegexNode({this.position});
}

/// Symbol node
class SymbolNode extends RegexNode {
  final String symbol;
  const SymbolNode({required this.symbol, super.position});
}

/// Dot node (any symbol)
class DotNode extends RegexNode {
  const DotNode({super.position});
}

/// Epsilon node (empty string)
class EpsilonNode extends RegexNode {
  const EpsilonNode({super.position});
}

/// Set/character class node ([...])
class SetNode extends RegexNode {
  final Set<String> symbols;
  const SetNode({required this.symbols, super.position});
}

/// Shortcut class node (\d, \w, \s)
class ShortcutNode extends RegexNode {
  final String code;
  const ShortcutNode({required this.code, super.position});
}

/// Union node (|)
class UnionNode extends RegexNode {
  final RegexNode left;
  final RegexNode right;
  const UnionNode({
    required this.left,
    required this.right,
    super.position,
  });
}

/// Concatenation node
class ConcatenationNode extends RegexNode {
  final RegexNode left;
  final RegexNode right;
  const ConcatenationNode({
    required this.left,
    required this.right,
    super.position,
  });
}

/// Kleene star node (*)
class KleeneStarNode extends RegexNode {
  final RegexNode child;
  const KleeneStarNode({required this.child, super.position});
}

/// Plus node (+)
class PlusNode extends RegexNode {
  final RegexNode child;
  const PlusNode({required this.child, super.position});
}

/// Question node (?)
class QuestionNode extends RegexNode {
  final RegexNode child;
  const QuestionNode({required this.child, super.position});
}

/// Token types for regex parsing
enum TokenType {
  symbol,
  leftParen,
  rightParen,
  union,
  kleeneStar,
  plus,
  question,
  dot,
  charClass,
  charShortcut,
  epsilon,
}

/// Token for regex parsing
class RegexToken {
  final TokenType type;
  final String value;
  final int position;

  const RegexToken({
    required this.type,
    required this.value,
    required this.position,
  });
}

/// Result of Regex to NFA conversion with step-by-step information
class RegexToNFAConversionResult {
  /// Original regular expression
  final String regex;

  /// Resulting NFA
  final FSA resultNFA;

  /// Detailed conversion steps
  final List<RegexToNFAStep> steps;

  /// Execution time
  final Duration executionTime;

  const RegexToNFAConversionResult({
    required this.regex,
    required this.resultNFA,
    required this.steps,
    required this.executionTime,
  });

  /// Gets the number of steps
  int get stepCount => steps.length;

  /// Gets the first step
  RegexToNFAStep? get firstStep => steps.isNotEmpty ? steps.first : null;

  /// Gets the last step
  RegexToNFAStep? get lastStep => steps.isNotEmpty ? steps.last : null;

  /// Gets the execution time in milliseconds
  int get executionTimeMs => executionTime.inMilliseconds;

  /// Gets the execution time in seconds
  double get executionTimeSeconds => executionTime.inMicroseconds / 1000000.0;
}
