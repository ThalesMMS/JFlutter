//
//  regex_analyzer.dart
//  JFlutter
//
//  Analisa expressões regulares para extrair métricas de complexidade, incluindo
//  star height (altura de estrela), profundidade de aninhamento, contagem de
//  operadores e tamanho do alfabeto. Utiliza parsing de AST para calcular métricas
//  precisas e retorna estruturas tipadas prontas para visualização educacional.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'dart:math' as math;
import '../models/regex_analysis.dart';
import '../result.dart';
import 'regex_to_nfa_converter.dart';

/// Random number generator for sample string generation
final _random = math.Random();

/// Analyzes regular expressions for complexity metrics and structural analysis
///
/// Provides methods to analyze regex expressions and compute:
/// - Star height (maximum nesting of Kleene stars)
/// - Nesting depth (maximum parentheses depth)
/// - Operator counts (union, concatenation, star, plus, question)
/// - Alphabet size and set
///
/// Example usage:
/// ```dart
/// final result = RegexAnalyzer.analyze('(a|b)*c+');
/// if (result.isSuccess) {
///   print('Star height: ${result.data!.starHeight}');
///   print('Complexity: ${result.data!.complexityLevel.displayName}');
/// }
/// ```
class RegexAnalyzer {
  /// Analyzes a regular expression and returns comprehensive metrics
  ///
  /// Parses the regex into an AST and traverses it to compute:
  /// - Complexity metrics (star height, nesting depth, complexity score)
  /// - Structure analysis (operator counts, alphabet size)
  /// - Sample strings placeholder (populated separately via generateSampleStrings)
  ///
  /// Returns a [Result] containing [RegexAnalysis] on success, or an error
  /// message on failure if the regex is invalid.
  static Result<RegexAnalysis> analyze(String regex) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateRegex(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Parse the regular expression into AST
      final node = _parseRegex(regex);
      if (node == null) {
        return ResultFactory.failure('Invalid regular expression syntax');
      }

      // Compute complexity metrics from AST
      final starHeight = _computeStarHeight(node);
      final nestingDepth = _computeNestingDepth(regex);
      final operatorCounts = _countOperatorsFromAst(node);
      final alphabet = _extractAlphabet(node);

      // Build complexity analysis
      final complexityAnalysis = RegexComplexityAnalysis.fromMetrics(
        starHeight: starHeight,
        nestingDepth: nestingDepth,
        operatorTotal: operatorCounts.values.fold(0, (a, b) => a + b),
        length: regex.length,
      );

      // Build structure analysis
      final structureAnalysis = RegexStructureAnalysis(
        operatorCount: operatorCounts,
        alphabetSize: alphabet.length,
        alphabet: alphabet,
        totalLength: regex.length,
      );

      // Build sample strings placeholder (empty until generateSampleStrings is called)
      final sampleStrings = RegexSampleStrings(
        samples: [],
        shortestString: null,
        acceptsEmptyString: _acceptsEmptyString(node),
      );

      stopwatch.stop();

      final analysis = RegexAnalysis(
        complexityAnalysis: complexityAnalysis,
        structureAnalysis: structureAnalysis,
        sampleStrings: sampleStrings,
        executionTime: stopwatch.elapsed,
      );

      return ResultFactory.success(analysis);
    } catch (e) {
      return ResultFactory.failure('Error analyzing regex: $e');
    }
  }

  /// Computes only the star height of a regex string
  ///
  /// Star height is the maximum nesting level of Kleene star operators.
  /// For example:
  /// - 'a' has star height 0
  /// - 'a*' has star height 1
  /// - '(a*)*' has star height 2
  /// - '((a*)*)*' has star height 3
  ///
  /// Returns a [Result] containing the star height integer on success.
  static Result<int> computeStarHeight(String regex) {
    try {
      final validationResult = _validateRegex(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      final node = _parseRegex(regex);
      if (node == null) {
        return ResultFactory.failure('Invalid regular expression syntax');
      }

      return ResultFactory.success(_computeStarHeight(node));
    } catch (e) {
      return ResultFactory.failure('Error computing star height: $e');
    }
  }

  /// Computes only the nesting depth of parentheses in a regex
  ///
  /// Nesting depth is the maximum depth of parentheses in the expression.
  /// For example:
  /// - 'a' has nesting depth 0
  /// - '(a)' has nesting depth 1
  /// - '((a|b))' has nesting depth 2
  /// - '(((a)))' has nesting depth 3
  ///
  /// Returns a [Result] containing the nesting depth integer on success.
  static Result<int> computeNestingDepth(String regex) {
    try {
      final validationResult = _validateRegex(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      return ResultFactory.success(_computeNestingDepth(regex));
    } catch (e) {
      return ResultFactory.failure('Error computing nesting depth: $e');
    }
  }

  /// Extracts the alphabet (set of symbols) used in a regex
  ///
  /// Returns all distinct terminal symbols that appear in the regex,
  /// excluding operators and special symbols like epsilon.
  ///
  /// Returns a [Result] containing the set of alphabet symbols on success.
  static Result<Set<String>> extractAlphabet(String regex) {
    try {
      final validationResult = _validateRegex(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      final node = _parseRegex(regex);
      if (node == null) {
        return ResultFactory.failure('Invalid regular expression syntax');
      }

      return ResultFactory.success(_extractAlphabet(node));
    } catch (e) {
      return ResultFactory.failure('Error extracting alphabet: $e');
    }
  }

  /// Counts operators in a regex expression
  ///
  /// Returns a map with counts for each operator type:
  /// - 'union': count of | operators
  /// - 'concatenation': count of implicit concatenations
  /// - 'star': count of * operators
  /// - 'plus': count of + operators
  /// - 'question': count of ? operators
  ///
  /// Returns a [Result] containing the operator count map on success.
  static Result<Map<String, int>> countOperators(String regex) {
    try {
      final validationResult = _validateRegex(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      final node = _parseRegex(regex);
      if (node == null) {
        return ResultFactory.failure('Invalid regular expression syntax');
      }

      return ResultFactory.success(_countOperatorsFromAst(node));
    } catch (e) {
      return ResultFactory.failure('Error counting operators: $e');
    }
  }

  /// Determines the complexity level of a regex based on its metrics
  ///
  /// Returns one of:
  /// - [ComplexityLevel.simple]: Easy expressions with low star height
  /// - [ComplexityLevel.moderate]: Medium complexity expressions
  /// - [ComplexityLevel.complex]: Difficult expressions with high nesting
  ///
  /// Returns a [Result] containing the [ComplexityLevel] on success.
  static Result<ComplexityLevel> determineComplexity(String regex) {
    final analysisResult = analyze(regex);
    if (analysisResult.isFailure) {
      return ResultFactory.failure(analysisResult.error!);
    }
    return ResultFactory.success(analysisResult.data!.complexityLevel);
  }

  /// Generates sample strings that match the regular expression
  ///
  /// Uses AST-based generation to produce sample strings of varying lengths.
  /// Includes edge cases:
  /// - Empty string if the regex accepts it
  /// - Shortest possible string
  /// - Strings of varying lengths (short to medium)
  ///
  /// Parameters:
  /// - [regex]: The regular expression to generate samples for
  /// - [maxSamples]: Maximum number of samples to generate (default: 10)
  /// - [maxLength]: Maximum length for generated strings (default: 20)
  ///
  /// Returns a [Result] containing [RegexSampleStrings] on success.
  ///
  /// Example:
  /// ```dart
  /// final result = RegexAnalyzer.generateSampleStrings('a*b+', maxSamples: 5);
  /// if (result.isSuccess) {
  ///   for (final sample in result.data!.samples) {
  ///     print('Sample: "$sample"');
  ///   }
  /// }
  /// ```
  static Result<RegexSampleStrings> generateSampleStrings(
    String regex, {
    int maxSamples = 10,
    int maxLength = 20,
  }) {
    try {
      final validationResult = _validateRegex(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      final node = _parseRegex(regex);
      if (node == null) {
        return ResultFactory.failure('Invalid regular expression syntax');
      }

      final samples = <String>{};
      final acceptsEmpty = _acceptsEmptyString(node);

      // Add empty string if accepted
      if (acceptsEmpty) {
        samples.add('');
      }

      // Find and add shortest string
      final shortest = _findShortestString(node);
      if (shortest != null && shortest.length <= maxLength) {
        samples.add(shortest);
      }

      // Generate random samples until we have enough unique ones
      int attempts = 0;
      final maxAttempts = maxSamples * 10; // Avoid infinite loops

      while (samples.length < maxSamples && attempts < maxAttempts) {
        attempts++;
        final sample = _generateSampleFromNode(node, maxLength);
        if (sample != null && sample.length <= maxLength) {
          samples.add(sample);
        }
      }

      // Sort samples by length for better presentation
      final sortedSamples = samples.toList()
        ..sort((a, b) {
          final lenDiff = a.length.compareTo(b.length);
          if (lenDiff != 0) return lenDiff;
          return a.compareTo(b);
        });

      return ResultFactory.success(
        RegexSampleStrings(
          samples: sortedSamples,
          shortestString: shortest,
          acceptsEmptyString: acceptsEmpty,
        ),
      );
    } catch (e) {
      return ResultFactory.failure('Error generating sample strings: $e');
    }
  }

  /// Performs full analysis including sample string generation
  ///
  /// This is a convenience method that combines [analyze] and
  /// [generateSampleStrings] into a single call.
  ///
  /// Returns a [Result] containing [RegexAnalysis] with populated samples.
  static Result<RegexAnalysis> analyzeWithSamples(
    String regex, {
    int maxSamples = 10,
    int maxLength = 20,
  }) {
    final analysisResult = analyze(regex);
    if (analysisResult.isFailure) {
      return analysisResult;
    }

    final samplesResult = generateSampleStrings(
      regex,
      maxSamples: maxSamples,
      maxLength: maxLength,
    );
    if (samplesResult.isFailure) {
      return analysisResult; // Return analysis without samples if generation fails
    }

    return ResultFactory.success(
      analysisResult.data!.copyWith(
        sampleStrings: samplesResult.data,
      ),
    );
  }

  // ============================================================
  // Private helper methods
  // ============================================================

  /// Validates the regular expression syntax
  static Result<void> _validateRegex(String regex) {
    if (regex.isEmpty) {
      return ResultFactory.failure('Regular expression cannot be empty');
    }

    // Check for balanced parentheses
    int parenCount = 0;
    for (int i = 0; i < regex.length; i++) {
      if (regex[i] == '(') {
        parenCount++;
      } else if (regex[i] == ')') {
        parenCount--;
        if (parenCount < 0) {
          return ResultFactory.failure(
            'Unbalanced parentheses: closing parenthesis at position $i '
            'has no matching opening parenthesis',
          );
        }
      }
    }

    if (parenCount != 0) {
      return ResultFactory.failure(
        'Unbalanced parentheses: $parenCount unclosed opening parenthesis(es)',
      );
    }

    // Check for invalid characters (allow epsilon literal ε)
    final validChars = RegExp(r'[a-zA-Z0-9\(\)\[\]\|\*\+\?\.|ε∅λ]');
    for (int i = 0; i < regex.length; i++) {
      if (!validChars.hasMatch(regex[i])) {
        return ResultFactory.failure(
          'Invalid character in regular expression: ${regex[i]}',
        );
      }
    }

    // Check operator placement
    const quantifiers = {'*', '+', '?'};
    if (regex.isNotEmpty && quantifiers.contains(regex[0])) {
      return ResultFactory.failure('Regex cannot start with a quantifier');
    }

    for (int i = 1; i < regex.length; i++) {
      final prev = regex[i - 1];
      final curr = regex[i];

      // Reject consecutive quantifiers
      if (quantifiers.contains(prev) && quantifiers.contains(curr)) {
        return ResultFactory.failure('Consecutive quantifiers are not allowed');
      }

      // Union operator cannot be at ends
      if (curr == '|' && (i == 0 || i == regex.length - 1)) {
        return ResultFactory.failure('Union operator cannot be at ends');
      }

      // Empty parentheses
      if (curr == ')' && prev == '(') {
        return ResultFactory.failure('Empty parentheses are not allowed');
      }
    }

    return ResultFactory.success(null);
  }

  /// Parses regex string into AST using the converter's tokenizer
  static RegexNode? _parseRegex(String regex) {
    try {
      final tokens = _tokenize(regex);
      return _parseExpression(tokens);
    } catch (e) {
      return null;
    }
  }

  /// Tokenizes the regular expression
  static List<_RegexToken> _tokenize(String regex) {
    final tokens = <_RegexToken>[];
    int i = 0;

    while (i < regex.length) {
      final char = regex[i];

      switch (char) {
        case '(':
          tokens.add(_RegexToken(type: _TokenType.leftParen, value: char));
          break;
        case ')':
          tokens.add(_RegexToken(type: _TokenType.rightParen, value: char));
          break;
        case '|':
          tokens.add(_RegexToken(type: _TokenType.union, value: char));
          break;
        case '*':
          tokens.add(_RegexToken(type: _TokenType.kleeneStar, value: char));
          break;
        case '+':
          tokens.add(_RegexToken(type: _TokenType.plus, value: char));
          break;
        case '?':
          tokens.add(_RegexToken(type: _TokenType.question, value: char));
          break;
        case '.':
          tokens.add(_RegexToken(type: _TokenType.dot, value: char));
          break;
        case '[':
          // Character class until ']'
          int j = i + 1;
          final buf = StringBuffer();
          while (j < regex.length && regex[j] != ']') {
            if (regex[j] == '\\' &&
                j + 1 < regex.length &&
                regex[j + 1] != ']') {
              buf.write(regex[j + 1]);
              j += 2;
              continue;
            }
            buf.write(regex[j]);
            j++;
          }
          if (j >= regex.length || regex[j] != ']') {
            tokens.add(_RegexToken(type: _TokenType.symbol, value: char));
          } else {
            tokens.add(
              _RegexToken(type: _TokenType.charClass, value: buf.toString()),
            );
            i = j;
          }
          break;
        case '\\':
          if (i + 1 < regex.length) {
            final next = regex[i + 1];
            if ('dDsSwW'.contains(next)) {
              tokens.add(_RegexToken(type: _TokenType.charShortcut, value: next));
              i++;
              break;
            }
            tokens.add(_RegexToken(type: _TokenType.symbol, value: next));
            i++;
          } else {
            tokens.add(_RegexToken(type: _TokenType.symbol, value: char));
          }
          break;
        default:
          if (char == 'ε' || char == 'λ') {
            tokens.add(_RegexToken(type: _TokenType.epsilon, value: char));
          } else if (char == '∅') {
            tokens.add(_RegexToken(type: _TokenType.emptySet, value: char));
          } else {
            tokens.add(_RegexToken(type: _TokenType.symbol, value: char));
          }
          break;
      }

      i++;
    }

    return tokens;
  }

  /// Parses the expression from tokens
  static RegexNode? _parseExpression(List<_RegexToken> tokens) {
    if (tokens.isEmpty) return null;
    return _parseUnion(tokens);
  }

  /// Parses union expressions (|)
  static RegexNode? _parseUnion(List<_RegexToken> tokens) {
    var node = _parseConcatenation(tokens);

    while (tokens.isNotEmpty && tokens.first.type == _TokenType.union) {
      tokens.removeAt(0);
      final right = _parseConcatenation(tokens);
      if (right == null) return null;
      node = UnionNode(left: node!, right: right);
    }

    return node;
  }

  /// Parses concatenation expressions
  static RegexNode? _parseConcatenation(List<_RegexToken> tokens) {
    var node = _parseUnary(tokens);

    while (tokens.isNotEmpty &&
        tokens.first.type != _TokenType.union &&
        tokens.first.type != _TokenType.rightParen) {
      final right = _parseUnary(tokens);
      if (right == null) return null;
      node = ConcatenationNode(left: node!, right: right);
    }

    return node;
  }

  /// Parses unary expressions (*, +, ?)
  static RegexNode? _parseUnary(List<_RegexToken> tokens) {
    var node = _parsePrimary(tokens);

    while (tokens.isNotEmpty) {
      final token = tokens.first;
      switch (token.type) {
        case _TokenType.kleeneStar:
          tokens.removeAt(0);
          node = KleeneStarNode(child: node!);
          break;
        case _TokenType.plus:
          tokens.removeAt(0);
          node = PlusNode(child: node!);
          break;
        case _TokenType.question:
          tokens.removeAt(0);
          node = QuestionNode(child: node!);
          break;
        default:
          return node;
      }
    }

    return node;
  }

  /// Parses primary expressions (symbols, parentheses)
  static RegexNode? _parsePrimary(List<_RegexToken> tokens) {
    if (tokens.isEmpty) return null;

    final token = tokens.removeAt(0);

    switch (token.type) {
      case _TokenType.symbol:
        return SymbolNode(symbol: token.value);
      case _TokenType.dot:
        return const DotNode();
      case _TokenType.epsilon:
        return const EpsilonNode();
      case _TokenType.emptySet:
        return const _EmptySetNode();
      case _TokenType.charClass:
        return SetNode(symbols: _parseCharClass(token.value));
      case _TokenType.charShortcut:
        return ShortcutNode(code: token.value);
      case _TokenType.leftParen:
        final node = _parseExpression(tokens);
        if (tokens.isEmpty || tokens.removeAt(0).type != _TokenType.rightParen) {
          return null;
        }
        return node;
      default:
        return null;
    }
  }

  /// Parses character class content
  static Set<String> _parseCharClass(String content) {
    final symbols = <String>{};
    int i = 0;
    while (i < content.length) {
      if (i + 2 < content.length && content[i + 1] == '-') {
        final start = content[i].codeUnitAt(0);
        final end = content[i + 2].codeUnitAt(0);
        for (int u = start; u <= end; u++) {
          symbols.add(String.fromCharCode(u));
        }
        i += 3;
        continue;
      }
      symbols.add(content[i]);
      i++;
    }
    return symbols;
  }

  /// Computes star height from AST by recursive traversal
  ///
  /// Star height is defined recursively:
  /// - h(ε) = h(∅) = h(a) = 0 for symbol a
  /// - h(r|s) = max(h(r), h(s))
  /// - h(rs) = max(h(r), h(s))
  /// - h(r*) = h(r) + 1
  static int _computeStarHeight(RegexNode node) {
    return switch (node) {
      EpsilonNode() => 0,
      SymbolNode() => 0,
      DotNode() => 0,
      SetNode() => 0,
      ShortcutNode() => 0,
      _EmptySetNode() => 0,
      UnionNode(:final left, :final right) =>
        math.max(_computeStarHeight(left), _computeStarHeight(right)),
      ConcatenationNode(:final left, :final right) =>
        math.max(_computeStarHeight(left), _computeStarHeight(right)),
      KleeneStarNode(:final child) => _computeStarHeight(child) + 1,
      PlusNode(:final child) => _computeStarHeight(child) + 1,
      QuestionNode(:final child) => _computeStarHeight(child),
      _ => 0,
    };
  }

  /// Computes nesting depth from the raw regex string
  ///
  /// Uses a simple counter algorithm:
  /// - Increment for each '('
  /// - Decrement for each ')'
  /// - Track maximum depth reached
  static int _computeNestingDepth(String regex) {
    int maxDepth = 0;
    int currentDepth = 0;

    for (int i = 0; i < regex.length; i++) {
      if (regex[i] == '(') {
        currentDepth++;
        if (currentDepth > maxDepth) {
          maxDepth = currentDepth;
        }
      } else if (regex[i] == ')') {
        currentDepth--;
      }
    }

    return maxDepth;
  }

  /// Counts operators by traversing the AST
  ///
  /// Returns a map with counts for:
  /// - 'union': number of UnionNode instances
  /// - 'concatenation': number of ConcatenationNode instances
  /// - 'star': number of KleeneStarNode instances
  /// - 'plus': number of PlusNode instances
  /// - 'question': number of QuestionNode instances
  static Map<String, int> _countOperatorsFromAst(RegexNode node) {
    final counts = <String, int>{
      'union': 0,
      'concatenation': 0,
      'star': 0,
      'plus': 0,
      'question': 0,
    };

    _countOperatorsRecursive(node, counts);
    return counts;
  }

  /// Recursive helper for counting operators
  static void _countOperatorsRecursive(RegexNode node, Map<String, int> counts) {
    switch (node) {
      case UnionNode(:final left, :final right):
        counts['union'] = (counts['union'] ?? 0) + 1;
        _countOperatorsRecursive(left, counts);
        _countOperatorsRecursive(right, counts);
        break;
      case ConcatenationNode(:final left, :final right):
        counts['concatenation'] = (counts['concatenation'] ?? 0) + 1;
        _countOperatorsRecursive(left, counts);
        _countOperatorsRecursive(right, counts);
        break;
      case KleeneStarNode(:final child):
        counts['star'] = (counts['star'] ?? 0) + 1;
        _countOperatorsRecursive(child, counts);
        break;
      case PlusNode(:final child):
        counts['plus'] = (counts['plus'] ?? 0) + 1;
        _countOperatorsRecursive(child, counts);
        break;
      case QuestionNode(:final child):
        counts['question'] = (counts['question'] ?? 0) + 1;
        _countOperatorsRecursive(child, counts);
        break;
      default:
        // Terminal nodes have no operators to count
        break;
    }
  }

  /// Extracts the alphabet (set of symbols) from the AST
  ///
  /// Traverses the AST and collects all terminal symbols,
  /// excluding epsilon and empty set.
  static Set<String> _extractAlphabet(RegexNode node) {
    final alphabet = <String>{};
    _extractAlphabetRecursive(node, alphabet);
    return alphabet;
  }

  /// Recursive helper for extracting alphabet
  static void _extractAlphabetRecursive(RegexNode node, Set<String> alphabet) {
    switch (node) {
      case SymbolNode(:final symbol):
        alphabet.add(symbol);
        break;
      case SetNode(:final symbols):
        alphabet.addAll(symbols);
        break;
      case ShortcutNode(:final code):
        // Expand shortcut to symbols
        alphabet.addAll(_expandShortcut(code));
        break;
      case DotNode():
        // Dot matches any symbol - add common alphabet
        alphabet.addAll({'a', 'b', 'c'});
        break;
      case UnionNode(:final left, :final right):
        _extractAlphabetRecursive(left, alphabet);
        _extractAlphabetRecursive(right, alphabet);
        break;
      case ConcatenationNode(:final left, :final right):
        _extractAlphabetRecursive(left, alphabet);
        _extractAlphabetRecursive(right, alphabet);
        break;
      case KleeneStarNode(:final child):
        _extractAlphabetRecursive(child, alphabet);
        break;
      case PlusNode(:final child):
        _extractAlphabetRecursive(child, alphabet);
        break;
      case QuestionNode(:final child):
        _extractAlphabetRecursive(child, alphabet);
        break;
      default:
        // EpsilonNode and EmptySetNode don't contribute to alphabet
        break;
    }
  }

  /// Expands character shortcuts to their full set
  static Set<String> _expandShortcut(String code) {
    switch (code) {
      case 'd':
      case 'D':
        return {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};
      case 'w':
      case 'W':
        return {
          '_',
          ...List.generate(26, (i) => String.fromCharCode('a'.codeUnitAt(0) + i)),
          ...List.generate(26, (i) => String.fromCharCode('A'.codeUnitAt(0) + i)),
          ...List.generate(10, (i) => String.fromCharCode('0'.codeUnitAt(0) + i)),
        };
      case 's':
      case 'S':
        return {' '};
      default:
        return {};
    }
  }

  /// Determines if the regex accepts the empty string
  ///
  /// A regex accepts ε if:
  /// - It is ε
  /// - It is r* (Kleene star always accepts ε)
  /// - It is r? (optional always accepts ε)
  /// - It is r|s where either r or s accepts ε
  /// - It is rs where both r and s accept ε
  static bool _acceptsEmptyString(RegexNode node) {
    return switch (node) {
      EpsilonNode() => true,
      _EmptySetNode() => false,
      SymbolNode() => false,
      DotNode() => false,
      SetNode() => false,
      ShortcutNode() => false,
      KleeneStarNode() => true, // r* always accepts ε
      QuestionNode() => true, // r? always accepts ε
      PlusNode(:final child) => _acceptsEmptyString(child),
      UnionNode(:final left, :final right) =>
        _acceptsEmptyString(left) || _acceptsEmptyString(right),
      ConcatenationNode(:final left, :final right) =>
        _acceptsEmptyString(left) && _acceptsEmptyString(right),
      _ => false,
    };
  }

  // ============================================================
  // Sample String Generation Helpers
  // ============================================================

  /// Generates a random sample string from an AST node
  ///
  /// Returns null if the node represents an empty language (∅).
  /// Uses randomization to produce varied samples.
  static String? _generateSampleFromNode(RegexNode node, int maxLength) {
    return _generateSampleRecursive(node, maxLength, 0);
  }

  /// Recursive helper for sample generation with depth tracking
  static String? _generateSampleRecursive(
    RegexNode node,
    int maxLength,
    int currentLength,
  ) {
    // Stop if we've exceeded max length
    if (currentLength > maxLength) {
      return null;
    }

    switch (node) {
      case EpsilonNode():
        return '';

      case _EmptySetNode():
        // Empty set has no valid strings
        return null;

      case SymbolNode(:final symbol):
        return symbol;

      case DotNode():
        // Return a random common character for 'any' match
        const commonChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
        return commonChars[_random.nextInt(commonChars.length)];

      case SetNode(:final symbols):
        if (symbols.isEmpty) return null;
        final symbolList = symbols.toList();
        return symbolList[_random.nextInt(symbolList.length)];

      case ShortcutNode(:final code):
        final expanded = _expandShortcut(code);
        if (expanded.isEmpty) return null;
        final expandedList = expanded.toList();
        return expandedList[_random.nextInt(expandedList.length)];

      case UnionNode(:final left, :final right):
        // Randomly choose one branch
        final choice = _random.nextBool();
        final first = choice ? left : right;
        final second = choice ? right : left;

        // Try first choice, fallback to second if it fails
        final result = _generateSampleRecursive(first, maxLength, currentLength);
        if (result != null) return result;
        return _generateSampleRecursive(second, maxLength, currentLength);

      case ConcatenationNode(:final left, :final right):
        final leftStr = _generateSampleRecursive(left, maxLength, currentLength);
        if (leftStr == null) return null;

        final rightStr = _generateSampleRecursive(
          right,
          maxLength,
          currentLength + leftStr.length,
        );
        if (rightStr == null) return null;

        return leftStr + rightStr;

      case KleeneStarNode(:final child):
        // Generate 0-3 repetitions randomly, biased toward shorter
        final repetitions = _biasedRepetitions(0, 3);
        if (repetitions == 0) return '';

        final buffer = StringBuffer();
        var totalLength = currentLength;

        for (int i = 0; i < repetitions; i++) {
          final part = _generateSampleRecursive(child, maxLength, totalLength);
          if (part == null) {
            // If we can't generate more, return what we have (at least 0 repetitions)
            break;
          }
          buffer.write(part);
          totalLength += part.length;

          // Stop if we're getting too long
          if (totalLength > maxLength) break;
        }

        return buffer.toString();

      case PlusNode(:final child):
        // Generate 1-4 repetitions randomly, biased toward shorter
        final repetitions = _biasedRepetitions(1, 4);

        final buffer = StringBuffer();
        var totalLength = currentLength;

        for (int i = 0; i < repetitions; i++) {
          final part = _generateSampleRecursive(child, maxLength, totalLength);
          if (part == null) {
            // For plus, we need at least one, so fail if first fails
            if (i == 0) return null;
            break;
          }
          buffer.write(part);
          totalLength += part.length;

          // Stop if we're getting too long
          if (totalLength > maxLength) break;
        }

        // Plus requires at least one repetition
        if (buffer.isEmpty) return null;
        return buffer.toString();

      case QuestionNode(:final child):
        // 50% chance of empty, 50% chance of child
        if (_random.nextBool()) {
          return '';
        }
        return _generateSampleRecursive(child, maxLength, currentLength);

      default:
        return null;
    }
  }

  /// Returns a biased random number of repetitions favoring lower values
  static int _biasedRepetitions(int min, int max) {
    // Use exponential distribution to bias toward lower values
    final range = max - min + 1;
    final r = _random.nextDouble();
    // Bias toward min: probability decreases exponentially
    final biased = (range * (1 - math.sqrt(r))).floor();
    return min + biased.clamp(0, max - min);
  }

  /// Finds the shortest string that matches the regex
  ///
  /// Returns null if the regex matches no strings (empty language).
  static String? _findShortestString(RegexNode node) {
    switch (node) {
      case EpsilonNode():
        return '';

      case _EmptySetNode():
        return null;

      case SymbolNode(:final symbol):
        return symbol;

      case DotNode():
        return 'a'; // Any single character

      case SetNode(:final symbols):
        if (symbols.isEmpty) return null;
        // Return the first symbol (arbitrary but consistent)
        return symbols.first;

      case ShortcutNode(:final code):
        final expanded = _expandShortcut(code);
        if (expanded.isEmpty) return null;
        return expanded.first;

      case UnionNode(:final left, :final right):
        final leftShortest = _findShortestString(left);
        final rightShortest = _findShortestString(right);

        if (leftShortest == null) return rightShortest;
        if (rightShortest == null) return leftShortest;

        // Return the shorter of the two
        return leftShortest.length <= rightShortest.length
            ? leftShortest
            : rightShortest;

      case ConcatenationNode(:final left, :final right):
        final leftShortest = _findShortestString(left);
        final rightShortest = _findShortestString(right);

        if (leftShortest == null || rightShortest == null) return null;

        return leftShortest + rightShortest;

      case KleeneStarNode():
        // Kleene star can always produce empty string
        return '';

      case PlusNode(:final child):
        // Plus requires at least one repetition
        return _findShortestString(child);

      case QuestionNode():
        // Optional can always produce empty string
        return '';

      default:
        return null;
    }
  }
}

/// Token type for internal parsing
enum _TokenType {
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
  emptySet,
}

/// Token for internal parsing
class _RegexToken {
  final _TokenType type;
  final String value;

  const _RegexToken({required this.type, required this.value});
}

/// Internal AST node for empty set (∅)
class _EmptySetNode extends RegexNode {
  const _EmptySetNode();
}
