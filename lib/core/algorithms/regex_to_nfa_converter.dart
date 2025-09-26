import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../result.dart';

/// Converts Regular Expressions to Non-deterministic Finite Automata (NFA)
class RegexToNFAConverter {
  /// Converts a regular expression to an equivalent NFA
  static Result<FSA> convert(String regex, {Set<String>? contextAlphabet}) {
    try {
      // Validate input
      final validationResult = _validateRegex(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Parse the regular expression
      final parsedRegex = _parseRegex(regex);
      if (parsedRegex == null) {
        return ResultFactory.failure('Invalid regular expression syntax');
      }

      // Convert to NFA using Thompson's construction
      final nfa = _thompsonConstruction(parsedRegex, contextAlphabet: contextAlphabet);
      
      return ResultFactory.success(nfa);
    } catch (e) {
      return ResultFactory.failure('Error converting regex to NFA: $e');
    }
  }

  /// Validates the regular expression
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
          return ResultFactory.failure('Unbalanced parentheses in regular expression');
        }
      }
    }
    
    if (parenCount != 0) {
      return ResultFactory.failure('Unbalanced parentheses in regular expression');
    }

    // Check for invalid characters
    final validChars = RegExp(r'[a-zA-Z0-9\(\)\|\*\+\?\.]');
    for (int i = 0; i < regex.length; i++) {
      if (!validChars.hasMatch(regex[i])) {
        return ResultFactory.failure('Invalid character in regular expression: ${regex[i]}');
      }
    }

    return ResultFactory.success(null);
  }

  /// Parses the regular expression into an abstract syntax tree
  static RegexNode? _parseRegex(String regex) {
    try {
      final tokens = _tokenize(regex);
      return _parseExpression(tokens);
    } catch (e) {
      return null;
    }
  }

  /// Tokenizes the regular expression
  static List<RegexToken> _tokenize(String regex) {
    final tokens = <RegexToken>[];
    int i = 0;
    
    while (i < regex.length) {
      final char = regex[i];
      
      switch (char) {
        case '(':
          tokens.add(RegexToken(type: TokenType.leftParen, value: char));
          break;
        case ')':
          tokens.add(RegexToken(type: TokenType.rightParen, value: char));
          break;
        case '|':
          tokens.add(RegexToken(type: TokenType.union, value: char));
          break;
        case '*':
          tokens.add(RegexToken(type: TokenType.kleeneStar, value: char));
          break;
        case '+':
          tokens.add(RegexToken(type: TokenType.plus, value: char));
          break;
        case '?':
          tokens.add(RegexToken(type: TokenType.question, value: char));
          break;
        case '.':
          tokens.add(RegexToken(type: TokenType.dot, value: char));
          break;
        case '[':
          // Character class until ']'
          int j = i + 1;
          final buf = StringBuffer();
          while (j < regex.length && regex[j] != ']') {
            // handle escaped chars inside class
            if (regex[j] == '\\' && j + 1 < regex.length && regex[j + 1] != ']') {
              buf.write(regex[j + 1]);
              j += 2;
              continue;
            }
            buf.write(regex[j]);
            j++;
          }
          if (j >= regex.length || regex[j] != ']') {
            // Unclosed class → treat '[' literal
            tokens.add(RegexToken(type: TokenType.symbol, value: char));
          } else {
            tokens.add(RegexToken(type: TokenType.charClass, value: buf.toString()));
            i = j; // will be incremented by i++ at end
          }
          break;
        case '\\':
          if (i + 1 < regex.length) {
            final next = regex[i + 1];
            // common shortcuts
            if ('dDsSwW'.contains(next)) {
              tokens.add(RegexToken(type: TokenType.charShortcut, value: next));
              i++;
              break;
            }
            // escaped metachar -> literal
            tokens.add(RegexToken(type: TokenType.symbol, value: next));
            i++;
          } else {
            tokens.add(RegexToken(type: TokenType.symbol, value: char));
          }
          break;
        default:
          tokens.add(RegexToken(type: TokenType.symbol, value: char));
          break;
      }
      
      i++;
    }
    
    return tokens;
  }

  /// Parses the expression from tokens
  static RegexNode? _parseExpression(List<RegexToken> tokens) {
    if (tokens.isEmpty) return null;
    
    final node = _parseUnion(tokens);
    return node;
  }

  /// Parses union expressions (|)
  static RegexNode? _parseUnion(List<RegexToken> tokens) {
    var node = _parseConcatenation(tokens);
    
    while (tokens.isNotEmpty && tokens.first.type == TokenType.union) {
      tokens.removeAt(0); // Remove |
      final right = _parseConcatenation(tokens);
      if (right == null) return null;
      node = UnionNode(left: node!, right: right);
    }
    
    return node;
  }

  /// Parses concatenation expressions
  static RegexNode? _parseConcatenation(List<RegexToken> tokens) {
    var node = _parseUnary(tokens);
    
    while (tokens.isNotEmpty && 
           tokens.first.type != TokenType.union &&
           tokens.first.type != TokenType.rightParen) {
      final right = _parseUnary(tokens);
      if (right == null) return null;
      node = ConcatenationNode(left: node!, right: right);
    }
    
    return node;
  }

  /// Parses unary expressions (*, +, ?)
  static RegexNode? _parseUnary(List<RegexToken> tokens) {
    var node = _parsePrimary(tokens);
    
    while (tokens.isNotEmpty) {
      final token = tokens.first;
      switch (token.type) {
        case TokenType.kleeneStar:
          tokens.removeAt(0);
          node = KleeneStarNode(child: node!);
          break;
        case TokenType.plus:
          tokens.removeAt(0);
          node = PlusNode(child: node!);
          break;
        case TokenType.question:
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
  static RegexNode? _parsePrimary(List<RegexToken> tokens) {
    if (tokens.isEmpty) return null;
    
    final token = tokens.removeAt(0);
    
    switch (token.type) {
      case TokenType.symbol:
        return SymbolNode(symbol: token.value);
      case TokenType.dot:
        return DotNode();
      case TokenType.charClass:
        return SetNode(symbols: _parseCharClass(token.value));
      case TokenType.charShortcut:
        return ShortcutNode(code: token.value);
      case TokenType.leftParen:
        final node = _parseExpression(tokens);
        if (tokens.isEmpty || tokens.removeAt(0).type != TokenType.rightParen) {
          return null;
        }
        return node;
      default:
        return null;
    }
  }

  /// Converts regex node to NFA using Thompson's construction
  static FSA _thompsonConstruction(RegexNode node, {Set<String>? contextAlphabet}) {
    final nfa = _buildNFA(node, contextAlphabet: contextAlphabet);
    return nfa;
  }

  /// Builds NFA from regex node
  static FSA _buildNFA(RegexNode node, {Set<String>? contextAlphabet}) {
    switch (node.runtimeType) {
      case SymbolNode:
        return _buildSymbolNFA((node as SymbolNode).symbol);
      case DotNode:
        return _buildDotNFA(contextAlphabet: contextAlphabet);
      case UnionNode:
        return _buildUnionNFA((node as UnionNode).left, (node as UnionNode).right, contextAlphabet: contextAlphabet);
      case ConcatenationNode:
        return _buildConcatenationNFA((node as ConcatenationNode).left, (node as ConcatenationNode).right, contextAlphabet: contextAlphabet);
      case KleeneStarNode:
        return _buildKleeneStarNFA((node as KleeneStarNode).child, contextAlphabet: contextAlphabet);
      case PlusNode:
        return _buildPlusNFA((node as PlusNode).child, contextAlphabet: contextAlphabet);
      case QuestionNode:
        return _buildQuestionNFA((node as QuestionNode).child, contextAlphabet: contextAlphabet);
      case SetNode:
        return _buildSetNFA((node as SetNode).symbols);
      case ShortcutNode:
        return _buildSetNFA(_expandShortcut((node as ShortcutNode).code, contextAlphabet));
      default:
        throw ArgumentError('Unknown regex node type: ${node.runtimeType}');
    }
  }

  /// Builds NFA for a single symbol
  static FSA _buildSymbolNFA(String symbol) {
    final now = DateTime.now();
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100, 100),
      isInitial: true,
      isAccepting: false,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(200, 100),
      isInitial: false,
      isAccepting: true,
    );
    
    final transition = FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: symbol,
    );
    
    return FSA(
      id: 'symbol_${symbol}_${now.millisecondsSinceEpoch}',
      name: 'Symbol $symbol',
      states: {q0, q1},
      transitions: {transition},
      alphabet: {symbol},
      initialState: q0,
      acceptingStates: {q1},
      created: now,
      modified: now,
              bounds: math.Rectangle(0, 0, 800, 600),
    );
  }

  /// Builds NFA for dot (any symbol)
  static FSA _buildDotNFA({Set<String>? contextAlphabet}) {
    final now = DateTime.now();
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100, 100),
      isInitial: true,
      isAccepting: false,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(200, 100),
      isInitial: false,
      isAccepting: true,
    );
    
    final transition = FSATransition(
      id: 't1',
      fromState: q0,
      toState: q1,
      label: '.',
      inputSymbols: contextAlphabet != null && contextAlphabet.isNotEmpty
          ? contextAlphabet
          : {'a', 'b', 'c'},
    );
    
    return FSA(
      id: 'dot_${now.millisecondsSinceEpoch}',
      name: 'Dot (Any Symbol)',
      states: {q0, q1},
      transitions: {transition},
      alphabet: contextAlphabet != null && contextAlphabet.isNotEmpty
          ? contextAlphabet
          : {'a', 'b', 'c'},
      initialState: q0,
      acceptingStates: {q1},
      created: now,
      modified: now,
              bounds: math.Rectangle(0, 0, 800, 600),
    );
  }

  /// Builds NFA for union (|)
  static FSA _buildUnionNFA(RegexNode left, RegexNode right, {Set<String>? contextAlphabet}) {
    final leftNFA = _buildNFA(left, contextAlphabet: contextAlphabet);
    final rightNFA = _buildNFA(right, contextAlphabet: contextAlphabet);
    
    // Create new initial and final states
    final now = DateTime.now();
    final newInitial = State(
      id: 'q_initial',
      label: 'q_initial',
      position: Vector2(50, 100),
      isInitial: true,
      isAccepting: false,
    );
    final newFinal = State(
      id: 'q_final',
      label: 'q_final',
      position: Vector2(350, 100),
      isInitial: false,
      isAccepting: true,
    );
    
    // Combine states and transitions
    final allStates = {newInitial, newFinal};
    allStates.addAll(leftNFA.states);
    allStates.addAll(rightNFA.states);
    
    final allTransitions = <FSATransition>{};
    allTransitions.addAll(leftNFA.fsaTransitions);
    allTransitions.addAll(rightNFA.fsaTransitions);
    
    // Add epsilon transitions
    allTransitions.add(FSATransition.epsilon(
      id: 't_eps1',
      fromState: newInitial,
      toState: leftNFA.initialState!,
    ));
    allTransitions.add(FSATransition.epsilon(
      id: 't_eps2',
      fromState: newInitial,
      toState: rightNFA.initialState!,
    ));
    
    for (final acceptingState in leftNFA.acceptingStates) {
      allTransitions.add(FSATransition.epsilon(
        id: 't_eps3_${acceptingState.id}',
        fromState: acceptingState,
        toState: newFinal,
      ));
    }
    
    for (final acceptingState in rightNFA.acceptingStates) {
      allTransitions.add(FSATransition.epsilon(
        id: 't_eps4_${acceptingState.id}',
        fromState: acceptingState,
        toState: newFinal,
      ));
    }
    
    return FSA(
      id: 'union_${now.millisecondsSinceEpoch}',
      name: 'Union',
      states: allStates,
      transitions: allTransitions,
      alphabet: leftNFA.alphabet.union(rightNFA.alphabet),
      initialState: newInitial,
      acceptingStates: {newFinal},
      created: now,
      modified: now,
              bounds: math.Rectangle(0, 0, 800, 600),
    );
  }

  /// Builds NFA for concatenation
  static FSA _buildConcatenationNFA(RegexNode left, RegexNode right, {Set<String>? contextAlphabet}) {
    final leftNFA = _buildNFA(left, contextAlphabet: contextAlphabet);
    final rightNFA = _buildNFA(right, contextAlphabet: contextAlphabet);

    return _concatenateAutomata(leftNFA, rightNFA);
  }

  /// Builds NFA for Kleene star (*)
  static FSA _buildKleeneStarNFA(RegexNode child, {Set<String>? contextAlphabet}) {
    final childNFA = _buildNFA(child, contextAlphabet: contextAlphabet);
    
    // Create new initial and final states
    final now = DateTime.now();
    final newInitial = State(
      id: 'q_initial',
      label: 'q_initial',
      position: Vector2(50, 100),
      isInitial: true,
      isAccepting: true, // Accept empty string
    );
    final newFinal = State(
      id: 'q_final',
      label: 'q_final',
      position: Vector2(350, 100),
      isInitial: false,
      isAccepting: true,
    );
    
    // Combine states and transitions
    final allStates = {newInitial, newFinal};
    allStates.addAll(childNFA.states);
    
    final allTransitions = <FSATransition>{};
    allTransitions.addAll(childNFA.fsaTransitions);
    
    // Add epsilon transitions
    allTransitions.add(FSATransition.epsilon(
      id: 't_eps1',
      fromState: newInitial,
      toState: childNFA.initialState!,
    ));
    
    for (final acceptingState in childNFA.acceptingStates) {
      allTransitions.add(FSATransition.epsilon(
        id: 't_eps2_${acceptingState.id}',
        fromState: acceptingState,
        toState: newFinal,
      ));
      allTransitions.add(FSATransition.epsilon(
        id: 't_eps3_${acceptingState.id}',
        fromState: acceptingState,
        toState: childNFA.initialState!,
      ));
    }
    
    return FSA(
      id: 'kleene_${now.millisecondsSinceEpoch}',
      name: 'Kleene Star',
      states: allStates,
      transitions: allTransitions,
      alphabet: childNFA.alphabet,
      initialState: newInitial,
      acceptingStates: {newFinal},
      created: now,
      modified: now,
              bounds: math.Rectangle(0, 0, 800, 600),
    );
  }

  /// Builds NFA for plus (+)
  static FSA _buildPlusNFA(RegexNode child, {Set<String>? contextAlphabet}) {
    // Plus is equivalent to concatenation of child and Kleene star of child
    final childNFA = _buildNFA(child, contextAlphabet: contextAlphabet);
    final kleeneNFA = _buildKleeneStarNFA(child, contextAlphabet: contextAlphabet);

    return _concatenateAutomata(childNFA, kleeneNFA);
  }

  /// Concatenates two pre-built NFAs
  static FSA _concatenateAutomata(FSA leftNFA, FSA rightNFA) {
    final rightInitial = rightNFA.initialState;
    if (rightInitial == null) {
      throw ArgumentError('Right automaton must have an initial state for concatenation');
    }

    final allStates = <State>{...leftNFA.states, ...rightNFA.states};
    final allTransitions = <FSATransition>{
      ...leftNFA.fsaTransitions,
      ...rightNFA.fsaTransitions,
    };

    int epsilonIndex = 0;
    for (final acceptingState in leftNFA.acceptingStates) {
      allTransitions.add(
        FSATransition.epsilon(
          id:
              't_eps_concat_${acceptingState.id}_${rightInitial.id}_${epsilonIndex++}',
          fromState: acceptingState,
          toState: rightInitial,
        ),
      );
    }

    final created = leftNFA.created.isBefore(rightNFA.created)
        ? leftNFA.created
        : rightNFA.created;
    final modified = leftNFA.modified.isAfter(rightNFA.modified)
        ? leftNFA.modified
        : rightNFA.modified;
    final bounds = _combineBounds(leftNFA.bounds, rightNFA.bounds);

    return FSA(
      id: 'concat_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Concatenation',
      states: allStates,
      transitions: allTransitions,
      alphabet: leftNFA.alphabet.union(rightNFA.alphabet),
      initialState: leftNFA.initialState,
      acceptingStates: Set<State>.from(rightNFA.acceptingStates),
      created: created,
      modified: modified,
      bounds: bounds,
    );
  }

  static math.Rectangle<double> _combineBounds(
    math.Rectangle leftBounds,
    math.Rectangle rightBounds,
  ) {
    final left = math.min(leftBounds.left.toDouble(), rightBounds.left.toDouble());
    final top = math.min(leftBounds.top.toDouble(), rightBounds.top.toDouble());
    final right = math.max(leftBounds.right.toDouble(), rightBounds.right.toDouble());
    final bottom =
        math.max(leftBounds.bottom.toDouble(), rightBounds.bottom.toDouble());

    return math.Rectangle<double>(
      left,
      top,
      right - left,
      bottom - top,
    );
  }

  /// Builds NFA for question (?)
  static FSA _buildQuestionNFA(RegexNode child, {Set<String>? contextAlphabet}) {
    // Question is equivalent to union of child and epsilon
    final childNFA = _buildNFA(child, contextAlphabet: contextAlphabet);
    
    // Create new initial and final states
    final now = DateTime.now();
    final newInitial = State(
      id: 'q_initial',
      label: 'q_initial',
      position: Vector2(50, 100),
      isInitial: true,
      isAccepting: true, // Accept empty string
    );
    final newFinal = State(
      id: 'q_final',
      label: 'q_final',
      position: Vector2(350, 100),
      isInitial: false,
      isAccepting: true,
    );
    
    // Combine states and transitions
    final allStates = {newInitial, newFinal};
    allStates.addAll(childNFA.states);
    
    final allTransitions = <FSATransition>{};
    allTransitions.addAll(childNFA.fsaTransitions);
    
    // Add epsilon transitions
    allTransitions.add(FSATransition.epsilon(
      id: 't_eps1',
      fromState: newInitial,
      toState: childNFA.initialState!,
    ));
    allTransitions.add(FSATransition.epsilon(
      id: 't_eps2',
      fromState: newInitial,
      toState: newFinal,
    ));
    
    for (final acceptingState in childNFA.acceptingStates) {
      allTransitions.add(FSATransition.epsilon(
        id: 't_eps3_${acceptingState.id}',
        fromState: acceptingState,
        toState: newFinal,
      ));
    }
    
    return FSA(
      id: 'question_${now.millisecondsSinceEpoch}',
      name: 'Question',
      states: allStates,
      transitions: allTransitions,
      alphabet: childNFA.alphabet,
      initialState: newInitial,
      acceptingStates: {newFinal},
      created: now,
      modified: now,
              bounds: math.Rectangle(0, 0, 800, 600),
    );
  }

  /// Builds NFA for a set of symbols (character class)
  static FSA _buildSetNFA(Set<String> symbols) {
    final now = DateTime.now();
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100, 100),
      isInitial: true,
      isAccepting: false,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(200, 100),
      isInitial: false,
      isAccepting: true,
    );
    final t = FSATransition(
      id: 't',
      fromState: q0,
      toState: q1,
      label: '[…]',
      inputSymbols: symbols,
    );
    return FSA(
      id: 'set_${now.millisecondsSinceEpoch}',
      name: 'Class',
      states: {q0, q1},
      transitions: {t},
      alphabet: symbols,
      initialState: q0,
      acceptingStates: {q1},
      created: now,
      modified: now,
      bounds: math.Rectangle(0, 0, 800, 600),
    );
  }

  static Set<String> _parseCharClass(String content) {
    final symbols = <String>{};
    int i = 0;
    while (i < content.length) {
      final c = content[i];
      if (i + 2 < content.length && content[i + 1] == '-') {
        final start = content[i].codeUnitAt(0);
        final end = content[i + 2].codeUnitAt(0);
        for (int u = start; u <= end; u++) {
          symbols.add(String.fromCharCode(u));
        }
        i += 3;
        continue;
      }
      symbols.add(c);
      i++;
    }
    return symbols;
  }

  static Set<String> _expandShortcut(String code, Set<String>? contextAlphabet) {
    switch (code) {
      case 'd':
      case 'D':
        return {'0','1','2','3','4','5','6','7','8','9'};
      case 'w':
      case 'W':
        return {
          '_',
          ...List.generate(26, (i) => String.fromCharCode('a'.codeUnitAt(0) + i)),
          ...List.generate(26, (i) => String.fromCharCode('A'.codeUnitAt(0) + i)),
          ...List.generate(10, (i) => String.fromCharCode('0'.codeUnitAt(0) + i)),
        }.toSet();
      case 's':
      case 'S':
        return {' '};
      default:
        return contextAlphabet ?? {};
    }
  }
}

/// Abstract base class for regex nodes
abstract class RegexNode {
  const RegexNode();
}

/// Symbol node
class SymbolNode extends RegexNode {
  final String symbol;
  const SymbolNode({required this.symbol});
}

/// Dot node (any symbol)
class DotNode extends RegexNode {
  const DotNode();
}

/// Set/character class node ([...])
class SetNode extends RegexNode {
  final Set<String> symbols;
  const SetNode({required this.symbols});
}

/// Shortcut class node (\d, \w, \s)
class ShortcutNode extends RegexNode {
  final String code;
  const ShortcutNode({required this.code});
}

/// Union node (|)
class UnionNode extends RegexNode {
  final RegexNode left;
  final RegexNode right;
  const UnionNode({required this.left, required this.right});
}

/// Concatenation node
class ConcatenationNode extends RegexNode {
  final RegexNode left;
  final RegexNode right;
  const ConcatenationNode({required this.left, required this.right});
}

/// Kleene star node (*)
class KleeneStarNode extends RegexNode {
  final RegexNode child;
  const KleeneStarNode({required this.child});
}

/// Plus node (+)
class PlusNode extends RegexNode {
  final RegexNode child;
  const PlusNode({required this.child});
}

/// Question node (?)
class QuestionNode extends RegexNode {
  final RegexNode child;
  const QuestionNode({required this.child});
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
}

/// Token for regex parsing
class RegexToken {
  final TokenType type;
  final String value;
  
  const RegexToken({required this.type, required this.value});
}

