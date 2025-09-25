// Basic examples library for JFlutter
// Contains 10-20 canonical examples for learning automata theory

import 'package:core_fa/models/finite_automaton.dart';
import 'package:core_fa/models/state.dart';
import 'package:core_fa/models/transition.dart';
import 'package:core_fa/models/alphabet.dart';
import 'package:core_fa/models/automaton_metadata.dart';
import 'package:core_pda/models/pushdown_automaton.dart';
import 'package:core_tm/models/turing_machine.dart';
import 'package:core_regex/models/context_free_grammar.dart';
import 'package:core_regex/models/regular_expression.dart';

/// Basic examples library for JFlutter
class BasicExamples {
  
  // ===== FINITE AUTOMATA EXAMPLES =====
  
  /// Example 1: Simple DFA that accepts strings ending with "ab"
  static FiniteAutomaton get endsWithAbDfa {
    final states = [
      State(
        id: 'q0',
        name: 'q0',
        position: Position(x: 100, y: 100),
        isInitial: true,
      ),
      State(
        id: 'q1',
        name: 'q1',
        position: Position(x: 200, y: 100),
      ),
      State(
        id: 'q2',
        name: 'q2',
        position: Position(x: 300, y: 100),
        isAccepting: true,
      ),
    ];

    final transitions = [
      Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
      Transition(id: 't2', fromState: 'q0', toState: 'q0', symbol: 'b'),
      Transition(id: 't3', fromState: 'q1', toState: 'q2', symbol: 'b'),
      Transition(id: 't4', fromState: 'q1', toState: 'q0', symbol: 'a'),
      Transition(id: 't5', fromState: 'q2', toState: 'q0', symbol: 'a'),
      Transition(id: 't6', fromState: 'q2', toState: 'q1', symbol: 'b'),
    ];

    return FiniteAutomaton(
      id: 'ends-with-ab',
      name: 'Ends with "ab" DFA',
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: ['a', 'b']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  /// Example 2: NFA that accepts strings containing "aa" or "bb"
  static FiniteAutomaton get containsAaOrBbNfa {
    final states = [
      State(
        id: 'q0',
        name: 'q0',
        position: Position(x: 100, y: 100),
        isInitial: true,
      ),
      State(
        id: 'q1',
        name: 'q1',
        position: Position(x: 200, y: 100),
      ),
      State(
        id: 'q2',
        name: 'q2',
        position: Position(x: 300, y: 100),
        isAccepting: true,
      ),
      State(
        id: 'q3',
        name: 'q3',
        position: Position(x: 200, y: 200),
      ),
      State(
        id: 'q4',
        name: 'q4',
        position: Position(x: 300, y: 200),
        isAccepting: true,
      ),
    ];

    final transitions = [
      Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
      Transition(id: 't2', fromState: 'q0', toState: 'q3', symbol: 'b'),
      Transition(id: 't3', fromState: 'q1', toState: 'q2', symbol: 'a'),
      Transition(id: 't4', fromState: 'q3', toState: 'q4', symbol: 'b'),
      Transition(id: 't5', fromState: 'q0', toState: 'q0', symbol: 'a'),
      Transition(id: 't6', fromState: 'q0', toState: 'q0', symbol: 'b'),
      Transition(id: 't7', fromState: 'q2', toState: 'q2', symbol: 'a'),
      Transition(id: 't8', fromState: 'q2', toState: 'q2', symbol: 'b'),
      Transition(id: 't9', fromState: 'q4', toState: 'q4', symbol: 'a'),
      Transition(id: 't10', fromState: 'q4', toState: 'q4', symbol: 'b'),
    ];

    return FiniteAutomaton(
      id: 'contains-aa-or-bb',
      name: 'Contains "aa" or "bb" NFA',
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: ['a', 'b']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  /// Example 3: DFA for even number of 'a's
  static FiniteAutomaton get evenNumberOfAsDfa {
    final states = [
      State(
        id: 'q0',
        name: 'q0',
        position: Position(x: 100, y: 100),
        isInitial: true,
        isAccepting: true,
      ),
      State(
        id: 'q1',
        name: 'q1',
        position: Position(x: 200, y: 100),
      ),
    ];

    final transitions = [
      Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
      Transition(id: 't2', fromState: 'q1', toState: 'q0', symbol: 'a'),
      Transition(id: 't3', fromState: 'q0', toState: 'q0', symbol: 'b'),
      Transition(id: 't4', fromState: 'q1', toState: 'q1', symbol: 'b'),
    ];

    return FiniteAutomaton(
      id: 'even-number-of-as',
      name: 'Even Number of "a"s DFA',
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: ['a', 'b']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  /// Example 4: DFA for strings with length divisible by 3
  static FiniteAutomaton get lengthDivisibleBy3Dfa {
    final states = [
      State(
        id: 'q0',
        name: 'q0',
        position: Position(x: 100, y: 100),
        isInitial: true,
        isAccepting: true,
      ),
      State(
        id: 'q1',
        name: 'q1',
        position: Position(x: 200, y: 100),
      ),
      State(
        id: 'q2',
        name: 'q2',
        position: Position(x: 300, y: 100),
      ),
    ];

    final transitions = [
      Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
      Transition(id: 't2', fromState: 'q1', toState: 'q2', symbol: 'a'),
      Transition(id: 't3', fromState: 'q2', toState: 'q0', symbol: 'a'),
      Transition(id: 't4', fromState: 'q0', toState: 'q1', symbol: 'b'),
      Transition(id: 't5', fromState: 'q1', toState: 'q2', symbol: 'b'),
      Transition(id: 't6', fromState: 'q2', toState: 'q0', symbol: 'b'),
    ];

    return FiniteAutomaton(
      id: 'length-divisible-by-3',
      name: 'Length Divisible by 3 DFA',
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: ['a', 'b']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  /// Example 5: NFA with epsilon transitions for (a+b)*
  static FiniteAutomaton get kleeneStarNfa {
    final states = [
      State(
        id: 'q0',
        name: 'q0',
        position: Position(x: 100, y: 100),
        isInitial: true,
        isAccepting: true,
      ),
      State(
        id: 'q1',
        name: 'q1',
        position: Position(x: 200, y: 100),
      ),
      State(
        id: 'q2',
        name: 'q2',
        position: Position(x: 300, y: 100),
        isAccepting: true,
      ),
    ];

    final transitions = [
      Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
      Transition(id: 't2', fromState: 'q0', toState: 'q1', symbol: 'b'),
      Transition(id: 't3', fromState: 'q1', toState: 'q2', symbol: 'a'),
      Transition(id: 't4', fromState: 'q1', toState: 'q2', symbol: 'b'),
      Transition(id: 't5', fromState: 'q2', toState: 'q0', symbol: 'ε'),
    ];

    return FiniteAutomaton(
      id: 'kleene-star',
      name: 'Kleene Star NFA',
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: ['a', 'b', 'ε']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  // ===== PUSHDOWN AUTOMATA EXAMPLES =====

  /// Example 6: PDA for balanced parentheses
  static PushdownAutomaton get balancedParenthesesPda {
    final states = [
      State(
        id: 'q0',
        name: 'q0',
        position: Position(x: 100, y: 100),
        isInitial: true,
      ),
      State(
        id: 'q1',
        name: 'q1',
        position: Position(x: 200, y: 100),
        isAccepting: true,
      ),
    ];

    final transitions = [
      // Push '(' onto stack
      PDATransition(
        id: 't1',
        fromState: 'q0',
        toState: 'q0',
        inputSymbol: '(',
        stackSymbol: 'Z',
        nextStackSymbols: ['(', 'Z'],
      ),
      // Push '(' onto stack
      PDATransition(
        id: 't2',
        fromState: 'q0',
        toState: 'q0',
        inputSymbol: '(',
        stackSymbol: '(',
        nextStackSymbols: ['(', '('],
      ),
      // Pop ')' from stack
      PDATransition(
        id: 't3',
        fromState: 'q0',
        toState: 'q0',
        inputSymbol: ')',
        stackSymbol: '(',
        nextStackSymbols: [],
      ),
      // Accept with empty stack
      PDATransition(
        id: 't4',
        fromState: 'q0',
        toState: 'q1',
        inputSymbol: 'ε',
        stackSymbol: 'Z',
        nextStackSymbols: ['Z'],
      ),
    ];

    return PushdownAutomaton(
      id: 'balanced-parentheses',
      name: 'Balanced Parentheses PDA',
      states: states,
      transitions: transitions,
      inputAlphabet: Alphabet(symbols: ['(', ')']),
      stackAlphabet: Alphabet(symbols: ['Z', '(']),
      initialState: 'q0',
      finalStates: ['q1'],
      acceptanceMode: AcceptanceMode.emptyStack,
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  /// Example 7: PDA for a^n b^n
  static PushdownAutomaton get anbnPda {
    final states = [
      State(
        id: 'q0',
        name: 'q0',
        position: Position(x: 100, y: 100),
        isInitial: true,
      ),
      State(
        id: 'q1',
        name: 'q1',
        position: Position(x: 200, y: 100),
      ),
      State(
        id: 'q2',
        name: 'q2',
        position: Position(x: 300, y: 100),
        isAccepting: true,
      ),
    ];

    final transitions = [
      // Push 'a' onto stack
      PDATransition(
        id: 't1',
        fromState: 'q0',
        toState: 'q0',
        inputSymbol: 'a',
        stackSymbol: 'Z',
        nextStackSymbols: ['a', 'Z'],
      ),
      PDATransition(
        id: 't2',
        fromState: 'q0',
        toState: 'q0',
        inputSymbol: 'a',
        stackSymbol: 'a',
        nextStackSymbols: ['a', 'a'],
      ),
      // Move to state q1
      PDATransition(
        id: 't3',
        fromState: 'q0',
        toState: 'q1',
        inputSymbol: 'b',
        stackSymbol: 'a',
        nextStackSymbols: [],
      ),
      // Pop 'a' from stack
      PDATransition(
        id: 't4',
        fromState: 'q1',
        toState: 'q1',
        inputSymbol: 'b',
        stackSymbol: 'a',
        nextStackSymbols: [],
      ),
      // Accept with empty stack
      PDATransition(
        id: 't5',
        fromState: 'q1',
        toState: 'q2',
        inputSymbol: 'ε',
        stackSymbol: 'Z',
        nextStackSymbols: ['Z'],
      ),
    ];

    return PushdownAutomaton(
      id: 'an-bn',
      name: 'a^n b^n PDA',
      states: states,
      transitions: transitions,
      inputAlphabet: Alphabet(symbols: ['a', 'b']),
      stackAlphabet: Alphabet(symbols: ['Z', 'a']),
      initialState: 'q0',
      finalStates: ['q2'],
      acceptanceMode: AcceptanceMode.emptyStack,
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  // ===== TURING MACHINE EXAMPLES =====

  /// Example 8: TM for a^n b^n c^n
  static TuringMachine get anbncnTm {
    final states = [
      State(
        id: 'q0',
        name: 'q0',
        position: Position(x: 100, y: 100),
        isInitial: true,
      ),
      State(
        id: 'q1',
        name: 'q1',
        position: Position(x: 200, y: 100),
      ),
      State(
        id: 'q2',
        name: 'q2',
        position: Position(x: 300, y: 100),
      ),
      State(
        id: 'q3',
        name: 'q3',
        position: Position(x: 400, y: 100),
      ),
      State(
        id: 'q4',
        name: 'q4',
        position: Position(x: 500, y: 100),
        isAccepting: true,
      ),
    ];

    final transitions = [
      // Replace 'a' with 'X' and move right
      TMTransition(
        id: 't1',
        fromState: 'q0',
        toState: 'q1',
        inputSymbol: 'a',
        writeSymbol: 'X',
        moveDirection: TapeAction.right,
      ),
      // Move right over 'a's
      TMTransition(
        id: 't2',
        fromState: 'q1',
        toState: 'q1',
        inputSymbol: 'a',
        writeSymbol: 'a',
        moveDirection: TapeAction.right,
      ),
      // Move right over 'b's
      TMTransition(
        id: 't3',
        fromState: 'q1',
        toState: 'q2',
        inputSymbol: 'b',
        writeSymbol: 'Y',
        moveDirection: TapeAction.right,
      ),
      // Move right over 'b's
      TMTransition(
        id: 't4',
        fromState: 'q2',
        toState: 'q2',
        inputSymbol: 'b',
        writeSymbol: 'b',
        moveDirection: TapeAction.right,
      ),
      // Move right over 'c's
      TMTransition(
        id: 't5',
        fromState: 'q2',
        toState: 'q3',
        inputSymbol: 'c',
        writeSymbol: 'Z',
        moveDirection: TapeAction.left,
      ),
      // Move left over 'c's
      TMTransition(
        id: 't6',
        fromState: 'q3',
        toState: 'q3',
        inputSymbol: 'c',
        writeSymbol: 'c',
        moveDirection: TapeAction.left,
      ),
      // Move left over 'b's
      TMTransition(
        id: 't7',
        fromState: 'q3',
        toState: 'q3',
        inputSymbol: 'b',
        writeSymbol: 'b',
        moveDirection: TapeAction.left,
      ),
      // Move left over 'a's
      TMTransition(
        id: 't8',
        fromState: 'q3',
        toState: 'q3',
        inputSymbol: 'a',
        writeSymbol: 'a',
        moveDirection: TapeAction.left,
      ),
      // Move left over 'X's
      TMTransition(
        id: 't9',
        fromState: 'q3',
        toState: 'q0',
        inputSymbol: 'X',
        writeSymbol: 'X',
        moveDirection: TapeAction.right,
      ),
      // Accept if all symbols are replaced
      TMTransition(
        id: 't10',
        fromState: 'q0',
        toState: 'q4',
        inputSymbol: 'B',
        writeSymbol: 'B',
        moveDirection: TapeAction.right,
      ),
    ];

    return TuringMachine(
      id: 'an-bn-cn',
      name: 'a^n b^n c^n TM',
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: ['a', 'b', 'c', 'X', 'Y', 'Z']),
      initialState: 'q0',
      finalStates: ['q4'],
      blankSymbol: 'B',
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  // ===== CONTEXT-FREE GRAMMAR EXAMPLES =====

  /// Example 9: CFG for balanced parentheses
  static ContextFreeGrammar get balancedParenthesesCfg {
    final productions = [
      Production(
        id: 'p1',
        leftSide: 'S',
        rightSide: ['ε'],
      ),
      Production(
        id: 'p2',
        leftSide: 'S',
        rightSide: ['(', 'S', ')'],
      ),
      Production(
        id: 'p3',
        leftSide: 'S',
        rightSide: ['S', 'S'],
      ),
    ];

    return ContextFreeGrammar(
      id: 'balanced-parentheses-cfg',
      name: 'Balanced Parentheses CFG',
      variables: ['S'],
      terminals: ['(', ')'],
      productions: productions,
      startVariable: 'S',
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  /// Example 10: CFG for a^n b^n
  static ContextFreeGrammar get anbnCfg {
    final productions = [
      Production(
        id: 'p1',
        leftSide: 'S',
        rightSide: ['a', 'S', 'b'],
      ),
      Production(
        id: 'p2',
        leftSide: 'S',
        rightSide: ['ε'],
      ),
    ];

    return ContextFreeGrammar(
      id: 'an-bn-cfg',
      name: 'a^n b^n CFG',
      variables: ['S'],
      terminals: ['a', 'b'],
      productions: productions,
      startVariable: 'S',
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  // ===== REGULAR EXPRESSION EXAMPLES =====

  /// Example 11: Regex for strings ending with "ab"
  static RegularExpression get endsWithAbRegex {
    return RegularExpression(
      id: 'ends-with-ab-regex',
      name: 'Ends with "ab" Regex',
      pattern: '(a|b)*ab',
      alphabet: Alphabet(symbols: ['a', 'b']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  /// Example 12: Regex for even number of 'a's
  static RegularExpression get evenNumberOfAsRegex {
    return RegularExpression(
      id: 'even-number-of-as-regex',
      name: 'Even Number of "a"s Regex',
      pattern: 'b*(ab*ab*)*',
      alphabet: Alphabet(symbols: ['a', 'b']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  /// Example 13: Regex for strings with length divisible by 3
  static RegularExpression get lengthDivisibleBy3Regex {
    return RegularExpression(
      id: 'length-divisible-by-3-regex',
      name: 'Length Divisible by 3 Regex',
      pattern: '((a|b)(a|b)(a|b))*',
      alphabet: Alphabet(symbols: ['a', 'b']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  // ===== COMPLEX EXAMPLES =====

  /// Example 14: DFA for binary numbers divisible by 3
  static FiniteAutomaton get binaryDivisibleBy3Dfa {
    final states = [
      State(
        id: 'q0',
        name: 'q0',
        position: Position(x: 100, y: 100),
        isInitial: true,
        isAccepting: true,
      ),
      State(
        id: 'q1',
        name: 'q1',
        position: Position(x: 200, y: 100),
      ),
      State(
        id: 'q2',
        name: 'q2',
        position: Position(x: 300, y: 100),
      ),
    ];

    final transitions = [
      Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: '0'),
      Transition(id: 't2', fromState: 'q0', toState: 'q2', symbol: '1'),
      Transition(id: 't3', fromState: 'q1', toState: 'q0', symbol: '0'),
      Transition(id: 't4', fromState: 'q1', toState: 'q1', symbol: '1'),
      Transition(id: 't5', fromState: 'q2', toState: 'q1', symbol: '0'),
      Transition(id: 't6', fromState: 'q2', toState: 'q2', symbol: '1'),
    ];

    return FiniteAutomaton(
      id: 'binary-divisible-by-3',
      name: 'Binary Divisible by 3 DFA',
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: ['0', '1']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  /// Example 15: NFA for strings with "ab" as substring
  static FiniteAutomaton get containsAbNfa {
    final states = [
      State(
        id: 'q0',
        name: 'q0',
        position: Position(x: 100, y: 100),
        isInitial: true,
      ),
      State(
        id: 'q1',
        name: 'q1',
        position: Position(x: 200, y: 100),
      ),
      State(
        id: 'q2',
        name: 'q2',
        position: Position(x: 300, y: 100),
        isAccepting: true,
      ),
    ];

    final transitions = [
      Transition(id: 't1', fromState: 'q0', toState: 'q0', symbol: 'a'),
      Transition(id: 't2', fromState: 'q0', toState: 'q0', symbol: 'b'),
      Transition(id: 't3', fromState: 'q0', toState: 'q1', symbol: 'a'),
      Transition(id: 't4', fromState: 'q1', toState: 'q2', symbol: 'b'),
      Transition(id: 't5', fromState: 'q2', toState: 'q2', symbol: 'a'),
      Transition(id: 't6', fromState: 'q2', toState: 'q2', symbol: 'b'),
    ];

    return FiniteAutomaton(
      id: 'contains-ab',
      name: 'Contains "ab" NFA',
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: ['a', 'b']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'basic-examples',
      ),
    );
  }

  // ===== HELPER METHODS =====

  /// Get all finite automaton examples
  static List<FiniteAutomaton> get finiteAutomatonExamples => [
    endsWithAbDfa,
    containsAaOrBbNfa,
    evenNumberOfAsDfa,
    lengthDivisibleBy3Dfa,
    kleeneStarNfa,
    binaryDivisibleBy3Dfa,
    containsAbNfa,
  ];

  /// Get all pushdown automaton examples
  static List<PushdownAutomaton> get pushdownAutomatonExamples => [
    balancedParenthesesPda,
    anbnPda,
  ];

  /// Get all Turing machine examples
  static List<TuringMachine> get turingMachineExamples => [
    anbncnTm,
  ];

  /// Get all context-free grammar examples
  static List<ContextFreeGrammar> get contextFreeGrammarExamples => [
    balancedParenthesesCfg,
    anbnCfg,
  ];

  /// Get all regular expression examples
  static List<RegularExpression> get regularExpressionExamples => [
    endsWithAbRegex,
    evenNumberOfAsRegex,
    lengthDivisibleBy3Regex,
  ];

  /// Get all examples
  static Map<String, List<dynamic>> get allExamples => {
    'finite_automata': finiteAutomatonExamples,
    'pushdown_automata': pushdownAutomatonExamples,
    'turing_machines': turingMachineExamples,
    'context_free_grammars': contextFreeGrammarExamples,
    'regular_expressions': regularExpressionExamples,
  };
}
