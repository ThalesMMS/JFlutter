import 'dart:math' as math;

import 'package:petitparser/petitparser.dart' as pp;
import 'package:vector_math/vector_math_64.dart';

import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/state.dart';
import '../result.dart';
import '../algorithms/regex_to_nfa_converter.dart'
    show
        RegexNode,
        SymbolNode,
        DotNode,
        UnionNode,
        ConcatenationNode,
        KleeneStarNode,
        PlusNode,
        QuestionNode;

/// Parses a regex to an AST (RegexNode) using petitparser and builds an NFA
/// via Thompson's construction.
class RegexPipeline {
  /// Full pipeline: parse → AST → NFA (Thompson)
  static Result<FSA> run(String pattern) {
    try {
      final astResult = parse(pattern);
      switch (astResult) {
        case Success<RegexNode>(data: final RegexNode ast):
          final fsa = _buildFromAst(ast);
          return ResultFactory.success(fsa);
        case Failure<RegexNode>(message: final message):
          return ResultFactory.failure(message);
      }
    } catch (e) {
      return ResultFactory.failure('Regex pipeline error: $e');
    }
  }

  /// Parses a regex string into an AST.
  static Result<RegexNode> parse(String pattern) {
    if (pattern.isEmpty) {
      return ResultFactory.failure('Regular expression cannot be empty');
    }
    try {
      final parser = _buildParser();
      final pp.Result<RegexNode> result = parser.end().parse(pattern);
      switch (result) {
        case pp.Success<RegexNode>(value: final ast):
          return ResultFactory.success(ast);
        case pp.Failure(position: final position):
          return ResultFactory.failure(
              'Invalid regular expression at $position');
      }
    } catch (e) {
      return ResultFactory.failure('Regex parse error: $e');
    }
  }

  /// Builds the petitparser for regex with precedence and implicit concatenation.
  static pp.Parser<RegexNode> _buildParser() {
    // Tokens
    final lparen = pp.char('(');
    final rparen = pp.char(')');
    final union = pp.char('|');
    final star = pp.char('*');
    final plus = pp.char('+');
    final question = pp.char('?');

    // Escaped character: \\ or \( etc.
    final escape = (pp.char('\\') & pp.any()).map((values) => values[1] as String);

    // Literal symbol: any char except metacharacters
    final pp.Parser<RegexNode> literal = (escape | pp.pattern('[^()|*+?.]'))
        .map<RegexNode>((value) => SymbolNode(symbol: value as String));

    // Primary: group | dot | literal
    final primaryRef = pp.undefined<RegexNode>();
    final pp.Parser<RegexNode> dotParser =
        pp.char('.').map<RegexNode>((_) => const DotNode());
    final pp.Parser<RegexNode> groupParser = (lparen & primaryRef & rparen).map<RegexNode>((v) => v[1] as RegexNode);
    final pp.Parser<RegexNode> primary =
        pp.choice<RegexNode>([groupParser, dotParser, literal]);

    // Unary: primary followed by postfix operators (*, +, ?), multiple allowed
    final pp.Parser<RegexNode> unary =
        (primary & (star | plus | question).star()).map<RegexNode>((values) {
      RegexNode node = values[0] as RegexNode;
      final ops = values[1] as List<String>;
      for (final op in ops) {
        switch (op) {
          case '*':
            node = KleeneStarNode(child: node);
            break;
          case '+':
            node = PlusNode(child: node);
            break;
          case '?':
            node = QuestionNode(child: node);
            break;
        }
      }
      return node;
    });

    // Concatenation: one or more unary, folded left-associative
    final pp.Parser<RegexNode> concat = unary.plus().map<RegexNode>((list) {
      final nodes = List<RegexNode>.from(list);
      RegexNode node = nodes.first;
      for (final next in nodes.skip(1)) {
        node = ConcatenationNode(left: node, right: next);
      }
      return node;
    });

    // Union: concatenation separated by |
    final pp.Parser<RegexNode> expression =
        (concat & (union & concat).star()).map<RegexNode>((values) {
      RegexNode node = values[0] as RegexNode;
      final rest = values[1] as List;
      for (final pair in rest) {
        final right = pair[1] as RegexNode; // pair = ['|', concat]
        node = UnionNode(left: node, right: right);
      }
      return node;
    });

    primaryRef.set(expression);
    return expression; // top-level
  }

  /// Thompson construction from AST → FSA. Independent from the older converter.
  static FSA _buildFromAst(RegexNode node) {
    switch (node.runtimeType) {
      case SymbolNode:
        return _buildSymbol((node as SymbolNode).symbol);
      case DotNode:
        return _buildDot();
      case UnionNode:
        return _buildUnion(
            _buildFromAst((node as UnionNode).left), _buildFromAst(node.right));
      case ConcatenationNode:
        return _concatenate(_buildFromAst((node as ConcatenationNode).left),
            _buildFromAst(node.right));
      case KleeneStarNode:
        return _kleene(_buildFromAst((node as KleeneStarNode).child));
      case PlusNode:
        final child = _buildFromAst((node as PlusNode).child);
        return _concatenate(child, _kleene(child));
      case QuestionNode:
        final child = _buildFromAst((node as QuestionNode).child);
        return _union(_epsilon(), child);
      default:
        throw ArgumentError('Unknown regex node: ${node.runtimeType}');
    }
  }

  static FSA _epsilon() {
    final now = DateTime.now();
    final q0 = State(
        id: 'q0', label: 'q0', position: Vector2(100, 100), isInitial: true);
    // Accept empty string, single state accepting
    return FSA(
      id: 'eps_${now.millisecondsSinceEpoch}',
      name: 'ε',
      states: {q0},
      transitions: {},
      alphabet: {},
      initialState: q0,
      acceptingStates: {q0},
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
    );
  }

  static FSA _buildSymbol(String symbol) {
    final now = DateTime.now();
    final q0 = State(
        id: 'q0', label: 'q0', position: Vector2(100, 100), isInitial: true);
    final q1 = State(
        id: 'q1', label: 'q1', position: Vector2(200, 100), isAccepting: true);
    final t = FSATransition.deterministic(
        id: 't', fromState: q0, toState: q1, symbol: symbol);
    return FSA(
      id: 'sym_${symbol}_${now.millisecondsSinceEpoch}',
      name: 'Symbol $symbol',
      states: {q0, q1},
      transitions: {t},
      alphabet: {symbol},
      initialState: q0,
      acceptingStates: {q1},
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
    );
  }

  static FSA _buildDot() {
    // For now, treat dot as accepting any of a small demo alphabet; can be extended.
    final now = DateTime.now();
    final q0 = State(
        id: 'q0', label: 'q0', position: Vector2(100, 100), isInitial: true);
    final q1 = State(
        id: 'q1', label: 'q1', position: Vector2(200, 100), isAccepting: true);
    final t = FSATransition(
        id: 't',
        fromState: q0,
        toState: q1,
        label: '.',
        inputSymbols: {'a', 'b', 'c'});
    return FSA(
      id: 'dot_${now.millisecondsSinceEpoch}',
      name: 'Dot',
      states: {q0, q1},
      transitions: {t},
      alphabet: {'a', 'b', 'c'},
      initialState: q0,
      acceptingStates: {q1},
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
    );
  }

  static FSA _union(FSA a, FSA b) {
    final now = DateTime.now();
    final s =
        State(id: 's', label: 's', position: Vector2(50, 100), isInitial: true);
    final f = State(
        id: 'f', label: 'f', position: Vector2(350, 100), isAccepting: true);
    final states = <State>{s, f, ...a.states, ...b.states};
    final transitions = <FSATransition>{
      ...a.fsaTransitions,
      ...b.fsaTransitions,
      FSATransition.epsilon(id: 'e1', fromState: s, toState: a.initialState!),
      FSATransition.epsilon(id: 'e2', fromState: s, toState: b.initialState!),
      ...a.acceptingStates.map((q) =>
          FSATransition.epsilon(id: 'ea_${q.id}', fromState: q, toState: f)),
      ...b.acceptingStates.map((q) =>
          FSATransition.epsilon(id: 'eb_${q.id}', fromState: q, toState: f)),
    };
    return FSA(
      id: 'union_${now.millisecondsSinceEpoch}',
      name: 'Union',
      states: states,
      transitions: transitions,
      alphabet: a.alphabet.union(b.alphabet),
      initialState: s,
      acceptingStates: {f},
      created: now,
      modified: now,
      bounds: _combineBounds(a.bounds, b.bounds),
    );
  }

  static FSA _buildUnion(FSA left, FSA right) => _union(left, right);

  static FSA _concatenate(FSA a, FSA b) {
    final transitions = <FSATransition>{
      ...a.fsaTransitions,
      ...b.fsaTransitions
    };
    int i = 0;
    for (final q in a.acceptingStates) {
      transitions.add(FSATransition.epsilon(
          id: 'ec_$i', fromState: q, toState: b.initialState!));
      i++;
    }
    return FSA(
      id: 'concat_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Concat',
      states: {...a.states, ...b.states},
      transitions: transitions,
      alphabet: a.alphabet.union(b.alphabet),
      initialState: a.initialState,
      acceptingStates: {...b.acceptingStates},
      created: a.created.isBefore(b.created) ? a.created : b.created,
      modified: a.modified.isAfter(b.modified) ? a.modified : b.modified,
      bounds: _combineBounds(a.bounds, b.bounds),
    );
  }

  static FSA _kleene(FSA a) {
    final now = DateTime.now();
    final s = State(
        id: 's',
        label: 's',
        position: Vector2(50, 100),
        isInitial: true,
        isAccepting: true);
    final f = State(
        id: 'f', label: 'f', position: Vector2(350, 100), isAccepting: true);
    final transitions = <FSATransition>{
      ...a.fsaTransitions,
      FSATransition.epsilon(id: 'ek1', fromState: s, toState: a.initialState!),
      ...a.acceptingStates.map((q) =>
          FSATransition.epsilon(id: 'ek2_${q.id}', fromState: q, toState: f)),
      ...a.acceptingStates.map((q) => FSATransition.epsilon(
          id: 'ek3_${q.id}', fromState: q, toState: a.initialState!)),
    };
    return FSA(
      id: 'kleene_${now.millisecondsSinceEpoch}',
      name: 'Kleene',
      states: {s, f, ...a.states},
      transitions: transitions,
      alphabet: a.alphabet,
      initialState: s,
      acceptingStates: {f},
      created: now,
      modified: now,
      bounds: a.bounds,
    );
  }

  static math.Rectangle<double> _combineBounds(
    math.Rectangle leftBounds,
    math.Rectangle rightBounds,
  ) {
    final left =
        math.min(leftBounds.left.toDouble(), rightBounds.left.toDouble());
    final top = math.min(leftBounds.top.toDouble(), rightBounds.top.toDouble());
    final right =
        math.max(leftBounds.right.toDouble(), rightBounds.right.toDouble());
    final bottom =
        math.max(leftBounds.bottom.toDouble(), rightBounds.bottom.toDouble());
    return math.Rectangle<double>(left, top, right - left, bottom - top);
  }
}
