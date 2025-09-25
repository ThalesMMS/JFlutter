// Interactive demonstrations for JFlutter playground
// Provides hands-on examples for learning automata theory

import 'package:core_fa/models/finite_automaton.dart';
import 'package:core_fa/models/state.dart';
import 'package:core_fa/models/transition.dart';
import 'package:core_fa/models/alphabet.dart';
import 'package:core_fa/models/automaton_metadata.dart';
import 'package:core_pda/models/pushdown_automaton.dart';
import 'package:core_tm/models/turing_machine.dart';
import 'package:core_regex/models/context_free_grammar.dart';
import 'package:core_regex/models/regular_expression.dart';
import 'basic_examples.dart';

/// Interactive demonstrations for JFlutter playground
class InteractiveDemos {
  
  // ===== FINITE AUTOMATA DEMOS =====
  
  /// Demo 1: Step-by-step NFA to DFA conversion
  static Map<String, dynamic> get nfaToDfaDemo {
    return {
      'title': 'NFA to DFA Conversion Demo',
      'description': 'Learn how to convert a non-deterministic finite automaton to a deterministic one',
      'steps': [
        {
          'step': 1,
          'title': 'Original NFA',
          'description': 'Start with an NFA that accepts strings containing "aa" or "bb"',
          'automaton': BasicExamples.containsAaOrBbNfa,
          'explanation': 'This NFA has multiple paths for the same input, making it non-deterministic.'
        },
        {
          'step': 2,
          'title': 'Subset Construction',
          'description': 'Apply subset construction algorithm',
          'explanation': 'Create new states representing sets of NFA states. Each DFA state corresponds to a possible set of NFA states.'
        },
        {
          'step': 3,
          'title': 'Resulting DFA',
          'description': 'The final deterministic automaton',
          'explanation': 'The DFA has a unique transition for each input symbol from each state.'
        }
      ],
      'testStrings': ['aa', 'bb', 'aab', 'bba', 'ab', 'ba', 'a', 'b'],
      'learningObjectives': [
        'Understand the difference between NFA and DFA',
        'Learn the subset construction algorithm',
        'Practice state minimization techniques'
      ]
    };
  }

  /// Demo 2: DFA minimization
  static Map<String, dynamic> get dfaMinimizationDemo {
    return {
      'title': 'DFA Minimization Demo',
      'description': 'Learn how to minimize a deterministic finite automaton',
      'steps': [
        {
          'step': 1,
          'title': 'Original DFA',
          'description': 'Start with a DFA that may have redundant states',
          'automaton': _createRedundantDfa(),
          'explanation': 'This DFA has more states than necessary.'
        },
        {
          'step': 2,
          'title': 'Find Equivalent States',
          'description': 'Identify states that behave identically',
          'explanation': 'Two states are equivalent if they accept the same language from that point.'
        },
        {
          'step': 3,
          'title': 'Merge Equivalent States',
          'description': 'Combine equivalent states into single states',
          'explanation': 'Replace equivalent states with a single representative state.'
        },
        {
          'step': 4,
          'title': 'Minimized DFA',
          'description': 'The final minimized automaton',
          'explanation': 'The minimized DFA has the minimum number of states while accepting the same language.'
        }
      ],
      'testStrings': ['ab', 'aab', 'abab', 'a', 'b', 'aa', 'bb'],
      'learningObjectives': [
        'Understand state equivalence',
        'Learn minimization algorithms',
        'Practice identifying redundant states'
      ]
    };
  }

  /// Demo 3: Regular expression to NFA conversion
  static Map<String, dynamic> get regexToNfaDemo {
    return {
      'title': 'Regular Expression to NFA Demo',
      'description': 'Learn how to convert regular expressions to finite automata',
      'steps': [
        {
          'step': 1,
          'title': 'Regular Expression',
          'description': 'Start with a regular expression pattern',
          'regex': '(a+b)*ab',
          'explanation': 'This regex matches strings that end with "ab".'
        },
        {
          'step': 2,
          'title': 'Parse Expression',
          'description': 'Break down the regex into components',
          'explanation': 'Identify operators: concatenation, union, and Kleene star.'
        },
        {
          'step': 3,
          'title': 'Thompson Construction',
          'description': 'Build NFA using Thompson construction',
          'explanation': 'Create basic automata for each symbol and combine them using operations.'
        },
        {
          'step': 4,
          'title': 'Resulting NFA',
          'description': 'The final NFA that accepts the same language',
          'explanation': 'The NFA accepts exactly the strings matched by the original regex.'
        }
      ],
      'testStrings': ['ab', 'aab', 'bab', 'abab', 'aabab', 'a', 'b', 'aa', 'bb'],
      'learningObjectives': [
        'Understand regular expression syntax',
        'Learn Thompson construction algorithm',
        'Practice regex to automaton conversion'
      ]
    };
  }

  // ===== PUSHDOWN AUTOMATA DEMOS =====

  /// Demo 4: PDA simulation for balanced parentheses
  static Map<String, dynamic> get pdaSimulationDemo {
    return {
      'title': 'PDA Simulation Demo',
      'description': 'Learn how pushdown automata work with stack operations',
      'steps': [
        {
          'step': 1,
          'title': 'PDA Definition',
          'description': 'Start with a PDA for balanced parentheses',
          'automaton': BasicExamples.balancedParenthesesPda,
          'explanation': 'This PDA uses a stack to track nesting depth.'
        },
        {
          'step': 2,
          'title': 'Stack Operations',
          'description': 'Understand push and pop operations',
          'explanation': 'Push "(" onto stack when encountered, pop "(" when ")" is seen.'
        },
        {
          'step': 3,
          'title': 'Simulation Steps',
          'description': 'Trace through input string step by step',
          'explanation': 'Show how the stack changes with each input symbol.'
        },
        {
          'step': 4,
          'title': 'Acceptance',
          'description': 'Determine if string is accepted',
          'explanation': 'String is accepted if we end in a final state with empty stack.'
        }
      ],
      'testStrings': ['()', '(())', '()()', '((()))', '(', ')', '())', '(()'],
      'learningObjectives': [
        'Understand stack-based computation',
        'Learn PDA acceptance conditions',
        'Practice stack manipulation'
      ]
    };
  }

  // ===== TURING MACHINE DEMOS =====

  /// Demo 5: TM computation for a^n b^n c^n
  static Map<String, dynamic> get tmComputationDemo {
    return {
      'title': 'Turing Machine Computation Demo',
      'description': 'Learn how Turing machines work with tape operations',
      'steps': [
        {
          'step': 1,
          'title': 'TM Definition',
          'description': 'Start with a TM for a^n b^n c^n',
          'automaton': BasicExamples.anbncnTm,
          'explanation': 'This TM recognizes strings with equal numbers of a, b, and c.'
        },
        {
          'step': 2,
          'title': 'Tape Operations',
          'description': 'Understand read, write, and move operations',
          'explanation': 'TM can read/write symbols and move left/right on the tape.'
        },
        {
          'step': 3,
          'title': 'Computation Steps',
          'description': 'Trace through computation step by step',
          'explanation': 'Show how the tape changes with each transition.'
        },
        {
          'step': 4,
          'title': 'Acceptance',
          'description': 'Determine if string is accepted',
          'explanation': 'String is accepted if TM reaches a final state.'
        }
      ],
      'testStrings': ['abc', 'aabbcc', 'aaabbbccc', 'ab', 'abcabc', 'a', 'b', 'c'],
      'learningObjectives': [
        'Understand tape-based computation',
        'Learn TM transition functions',
        'Practice computation tracing'
      ]
    };
  }

  // ===== CONTEXT-FREE GRAMMAR DEMOS =====

  /// Demo 6: CFG parsing for balanced parentheses
  static Map<String, dynamic> get cfgParsingDemo {
    return {
      'title': 'Context-Free Grammar Parsing Demo',
      'description': 'Learn how context-free grammars generate languages',
      'steps': [
        {
          'step': 1,
          'title': 'Grammar Definition',
          'description': 'Start with a CFG for balanced parentheses',
          'grammar': BasicExamples.balancedParenthesesCfg,
          'explanation': 'This grammar generates all strings of balanced parentheses.'
        },
        {
          'step': 2,
          'title': 'Derivation Rules',
          'description': 'Understand production rules',
          'explanation': 'Each rule shows how to replace variables with symbols.'
        },
        {
          'step': 3,
          'title': 'Derivation Process',
          'description': 'Show step-by-step derivation',
          'explanation': 'Start with start symbol and apply rules to generate strings.'
        },
        {
          'step': 4,
          'title': 'Parse Tree',
          'description': 'Visualize the derivation as a tree',
          'explanation': 'Parse tree shows the structure of the derivation.'
        }
      ],
      'testStrings': ['()', '(())', '()()', '((()))', '(', ')', '())', '(()'],
      'learningObjectives': [
        'Understand grammar rules',
        'Learn derivation processes',
        'Practice parse tree construction'
      ]
    };
  }

  // ===== ALGORITHM DEMOS =====

  /// Demo 7: Pumping lemma proof
  static Map<String, dynamic> get pumpingLemmaDemo {
    return {
      'title': 'Pumping Lemma Demo',
      'description': 'Learn how to use the pumping lemma to prove languages are not regular',
      'steps': [
        {
          'step': 1,
          'title': 'Language Definition',
          'description': 'Start with a language to analyze',
          'language': 'L = {a^n b^n | n ≥ 0}',
          'explanation': 'This language contains strings with equal numbers of a and b.'
        },
        {
          'step': 2,
          'title': 'Assume Regular',
          'description': 'Assume the language is regular',
          'explanation': 'If L is regular, it must satisfy the pumping lemma.'
        },
        {
          'step': 3,
          'title': 'Choose String',
          'description': 'Select a string that violates the lemma',
          'string': 'a^p b^p',
          'explanation': 'Choose a string long enough to guarantee pumping.'
        },
        {
          'step': 4,
          'title': 'Pump and Contradict',
          'description': 'Show that pumping leads to contradiction',
          'explanation': 'Pumping the string produces strings not in the language.'
        }
      ],
      'testStrings': ['ab', 'aabb', 'aaabbb', 'a', 'b', 'aa', 'bb'],
      'learningObjectives': [
        'Understand pumping lemma',
        'Learn proof techniques',
        'Practice language analysis'
      ]
    };
  }

  // ===== HELPER METHODS =====

  /// Create a DFA with redundant states for minimization demo
  static FiniteAutomaton _createRedundantDfa() {
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
        position: Position(x: 400, y: 100),
        isAccepting: true,
      ),
    ];

    final transitions = [
      Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
      Transition(id: 't2', fromState: 'q1', toState: 'q2', symbol: 'b'),
      Transition(id: 't3', fromState: 'q1', toState: 'q3', symbol: 'b'),
      Transition(id: 't4', fromState: 'q2', toState: 'q2', symbol: 'a'),
      Transition(id: 't5', fromState: 'q2', toState: 'q2', symbol: 'b'),
      Transition(id: 't6', fromState: 'q3', toState: 'q3', symbol: 'a'),
      Transition(id: 't7', fromState: 'q3', toState: 'q3', symbol: 'b'),
    ];

    return FiniteAutomaton(
      id: 'redundant-dfa',
      name: 'Redundant DFA',
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: ['a', 'b']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'interactive-demo',
      ),
    );
  }

  /// Get all interactive demos
  static List<Map<String, dynamic>> get allDemos => [
    nfaToDfaDemo,
    dfaMinimizationDemo,
    regexToNfaDemo,
    pdaSimulationDemo,
    tmComputationDemo,
    cfgParsingDemo,
    pumpingLemmaDemo,
  ];

  /// Get demos by category
  static Map<String, List<Map<String, dynamic>>> get demosByCategory => {
    'finite_automata': [nfaToDfaDemo, dfaMinimizationDemo, regexToNfaDemo],
    'pushdown_automata': [pdaSimulationDemo],
    'turing_machines': [tmComputationDemo],
    'context_free_grammars': [cfgParsingDemo],
    'algorithms': [pumpingLemmaDemo],
  };
}
