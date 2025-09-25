// Learning paths for JFlutter playground
// Provides structured learning experiences for different skill levels

import 'basic_examples.dart';
import 'interactive_demos.dart';

/// Learning paths for JFlutter playground
class LearningPaths {
  
  // ===== BEGINNER PATHS =====
  
  /// Path 1: Introduction to Finite Automata
  static Map<String, dynamic> get finiteAutomataIntro {
    return {
      'title': 'Introduction to Finite Automata',
      'level': 'beginner',
      'duration': '2-3 hours',
      'description': 'Learn the basics of finite automata and how they work',
      'prerequisites': ['Basic understanding of sets and functions'],
      'learningObjectives': [
        'Understand what finite automata are',
        'Learn the difference between DFA and NFA',
        'Practice reading and creating automata',
        'Understand acceptance and rejection'
      ],
      'modules': [
        {
          'title': 'What are Finite Automata?',
          'duration': '30 minutes',
          'content': [
            'Definition and purpose',
            'Real-world applications',
            'Basic components (states, transitions, alphabet)'
          ],
          'examples': [BasicExamples.endsWithAbDfa],
          'exercises': [
            'Identify states and transitions in a given automaton',
            'Determine if a string is accepted by an automaton'
          ]
        },
        {
          'title': 'Deterministic vs Non-deterministic',
          'duration': '45 minutes',
          'content': [
            'DFA characteristics',
            'NFA characteristics',
            'When to use each type'
          ],
          'examples': [BasicExamples.endsWithAbDfa, BasicExamples.containsAaOrBbNfa],
          'exercises': [
            'Convert between DFA and NFA representations',
            'Identify determinism in automata'
          ]
        },
        {
          'title': 'Building Your First Automaton',
          'duration': '60 minutes',
          'content': [
            'Step-by-step construction',
            'Testing with sample strings',
            'Common patterns and techniques'
          ],
          'examples': [BasicExamples.evenNumberOfAsDfa],
          'exercises': [
            'Build an automaton for a given language',
            'Test your automaton with various inputs'
          ]
        }
      ],
      'assessment': {
        'type': 'practical',
        'description': 'Create an automaton that accepts strings with exactly two "a"s',
        'criteria': [
          'Correctly identifies the language',
          'Uses appropriate number of states',
          'Handles all test cases correctly'
        ]
      }
    };
  }

  /// Path 2: Regular Expressions
  static Map<String, dynamic> get regularExpressionsIntro {
    return {
      'title': 'Regular Expressions',
      'level': 'beginner',
      'duration': '2-3 hours',
      'description': 'Learn how to use regular expressions and convert them to automata',
      'prerequisites': ['Introduction to Finite Automata'],
      'learningObjectives': [
        'Understand regex syntax and operators',
        'Learn regex to automaton conversion',
        'Practice writing regular expressions',
        'Understand language equivalence'
      ],
      'modules': [
        {
          'title': 'Regex Basics',
          'duration': '45 minutes',
          'content': [
            'Basic symbols and operators',
            'Concatenation, union, and Kleene star',
            'Precedence and grouping'
          ],
          'examples': [BasicExamples.endsWithAbRegex],
          'exercises': [
            'Write regex for simple patterns',
            'Match strings with given regex'
          ]
        },
        {
          'title': 'Regex to Automaton',
          'duration': '60 minutes',
          'content': [
            'Thompson construction algorithm',
            'Step-by-step conversion process',
            'Optimization techniques'
          ],
          'examples': [InteractiveDemos.regexToNfaDemo],
          'exercises': [
            'Convert regex to NFA',
            'Convert NFA to DFA'
          ]
        },
        {
          'title': 'Automaton to Regex',
          'duration': '60 minutes',
          'content': [
            'State elimination method',
            'Handling complex automata',
            'Simplification techniques'
          ],
          'examples': [BasicExamples.evenNumberOfAsRegex],
          'exercises': [
            'Convert DFA to regex',
            'Simplify complex expressions'
          ]
        }
      ],
      'assessment': {
        'type': 'practical',
        'description': 'Create a regex for strings that start and end with the same symbol',
        'criteria': [
          'Correctly matches the language',
          'Uses appropriate operators',
          'Handles edge cases'
        ]
      }
    };
  }

  // ===== INTERMEDIATE PATHS =====

  /// Path 3: Pushdown Automata
  static Map<String, dynamic> get pushdownAutomataIntermediate {
    return {
      'title': 'Pushdown Automata',
      'level': 'intermediate',
      'duration': '3-4 hours',
      'description': 'Learn about pushdown automata and context-free languages',
      'prerequisites': ['Introduction to Finite Automata', 'Regular Expressions'],
      'learningObjectives': [
        'Understand stack-based computation',
        'Learn PDA acceptance conditions',
        'Practice PDA construction',
        'Understand context-free languages'
      ],
      'modules': [
        {
          'title': 'Stack Operations',
          'duration': '45 minutes',
          'content': [
            'Push and pop operations',
            'Stack alphabet and initial symbol',
            'Reading from stack'
          ],
          'examples': [BasicExamples.balancedParenthesesPda],
          'exercises': [
            'Trace PDA execution with given inputs',
            'Identify stack operations in PDA transitions'
          ]
        },
        {
          'title': 'PDA Construction',
          'duration': '90 minutes',
          'content': [
            'Designing PDAs for specific languages',
            'Handling multiple stack symbols',
            'Acceptance modes (final state vs empty stack)'
          ],
          'examples': [BasicExamples.anbnPda],
          'exercises': [
            'Build PDA for a^n b^n',
            'Build PDA for balanced parentheses'
          ]
        },
        {
          'title': 'PDA Simulation',
          'duration': '60 minutes',
          'content': [
            'Step-by-step simulation',
            'Stack state tracking',
            'Acceptance determination'
          ],
          'examples': [InteractiveDemos.pdaSimulationDemo],
          'exercises': [
            'Simulate PDA execution',
            'Determine acceptance for given inputs'
          ]
        }
      ],
      'assessment': {
        'type': 'practical',
        'description': 'Create a PDA that accepts strings with equal numbers of "a" and "b"',
        'criteria': [
          'Correctly handles the language',
          'Uses appropriate stack operations',
          'Handles all test cases'
        ]
      }
    };
  }

  /// Path 4: Context-Free Grammars
  static Map<String, dynamic> get contextFreeGrammarsIntermediate {
    return {
      'title': 'Context-Free Grammars',
      'level': 'intermediate',
      'duration': '3-4 hours',
      'description': 'Learn about context-free grammars and their relationship to PDAs',
      'prerequisites': ['Pushdown Automata'],
      'learningObjectives': [
        'Understand grammar rules and derivations',
        'Learn CFG to PDA conversion',
        'Practice grammar construction',
        'Understand parse trees'
      ],
      'modules': [
        {
          'title': 'Grammar Basics',
          'duration': '60 minutes',
          'content': [
            'Variables and terminals',
            'Production rules',
            'Derivations and parse trees'
          ],
          'examples': [BasicExamples.balancedParenthesesCfg],
          'exercises': [
            'Write derivations for given strings',
            'Construct parse trees'
          ]
        },
        {
          'title': 'CFG to PDA Conversion',
          'duration': '90 minutes',
          'content': [
            'Standard construction algorithm',
            'Handling different rule types',
            'Optimization techniques'
          ],
          'examples': [BasicExamples.anbnCfg],
          'exercises': [
            'Convert CFG to PDA',
            'Test PDA with grammar strings'
          ]
        },
        {
          'title': 'Grammar Analysis',
          'duration': '60 minutes',
          'content': [
            'Identifying grammar properties',
            'Common grammar patterns',
            'Grammar simplification'
          ],
          'examples': [InteractiveDemos.cfgParsingDemo],
          'exercises': [
            'Analyze grammar properties',
            'Simplify complex grammars'
          ]
        }
      ],
      'assessment': {
        'type': 'practical',
        'description': 'Create a CFG for strings with "a" followed by "b" followed by "c"',
        'criteria': [
          'Correctly generates the language',
          'Uses appropriate rules',
          'Handles all test cases'
        ]
      }
    };
  }

  // ===== ADVANCED PATHS =====

  /// Path 5: Turing Machines
  static Map<String, dynamic> get turingMachinesAdvanced {
    return {
      'title': 'Turing Machines',
      'level': 'advanced',
      'duration': '4-5 hours',
      'description': 'Learn about Turing machines and computability',
      'prerequisites': ['Pushdown Automata', 'Context-Free Grammars'],
      'learningObjectives': [
        'Understand tape-based computation',
        'Learn TM construction techniques',
        'Practice TM simulation',
        'Understand computability concepts'
      ],
      'modules': [
        {
          'title': 'TM Basics',
          'duration': '60 minutes',
          'content': [
            'Tape and head operations',
            'Transition functions',
            'Acceptance and rejection'
          ],
          'examples': [BasicExamples.anbncnTm],
          'exercises': [
            'Trace TM execution',
            'Identify tape operations'
          ]
        },
        {
          'title': 'TM Construction',
          'duration': '120 minutes',
          'content': [
            'Designing TMs for specific problems',
            'Multi-tape TMs',
            'Universal TMs'
          ],
          'examples': [InteractiveDemos.tmComputationDemo],
          'exercises': [
            'Build TM for a^n b^n c^n',
            'Build TM for palindrome recognition'
          ]
        },
        {
          'title': 'Computability Theory',
          'duration': '90 minutes',
          'content': [
            'Decidable vs undecidable problems',
            'Halting problem',
            'Reduction techniques'
          ],
          'examples': [InteractiveDemos.pumpingLemmaDemo],
          'exercises': [
            'Prove languages are not regular',
            'Analyze problem decidability'
          ]
        }
      ],
      'assessment': {
        'type': 'theoretical',
        'description': 'Prove that the language {a^n b^n c^n | n ≥ 0} is not context-free',
        'criteria': [
          'Correctly applies pumping lemma',
          'Shows clear reasoning',
          'Handles all cases'
        ]
      }
    };
  }

  /// Path 6: Algorithm Design and Analysis
  static Map<String, dynamic> get algorithmDesignAdvanced {
    return {
      'title': 'Algorithm Design and Analysis',
      'level': 'advanced',
      'duration': '5-6 hours',
      'description': 'Learn advanced algorithms for automata theory',
      'prerequisites': ['Turing Machines'],
      'learningObjectives': [
        'Master NFA to DFA conversion',
        'Learn DFA minimization',
        'Practice algorithm implementation',
        'Understand complexity analysis'
      ],
      'modules': [
        {
          'title': 'NFA to DFA Conversion',
          'duration': '90 minutes',
          'content': [
            'Subset construction algorithm',
            'Epsilon closure computation',
            'Optimization techniques'
          ],
          'examples': [InteractiveDemos.nfaToDfaDemo],
          'exercises': [
            'Implement subset construction',
            'Optimize conversion algorithms'
          ]
        },
        {
          'title': 'DFA Minimization',
          'duration': '90 minutes',
          'content': [
            'State equivalence',
            'Partition refinement',
            'Hopcroft algorithm'
          ],
          'examples': [InteractiveDemos.dfaMinimizationDemo],
          'exercises': [
            'Implement minimization',
            'Analyze algorithm complexity'
          ]
        },
        {
          'title': 'Advanced Algorithms',
          'duration': '120 minutes',
          'content': [
            'Regex to automaton conversion',
            'Automaton to regex conversion',
            'Language operations'
          ],
          'examples': [InteractiveDemos.regexToNfaDemo],
          'exercises': [
            'Implement language operations',
            'Optimize conversion algorithms'
          ]
        }
      ],
      'assessment': {
        'type': 'implementation',
        'description': 'Implement a complete NFA to DFA converter with minimization',
        'criteria': [
          'Correctly implements algorithms',
          'Handles edge cases',
          'Optimizes for performance'
        ]
      }
    };
  }

  // ===== HELPER METHODS =====

  /// Get all learning paths
  static List<Map<String, dynamic>> get allPaths => [
    finiteAutomataIntro,
    regularExpressionsIntro,
    pushdownAutomataIntermediate,
    contextFreeGrammarsIntermediate,
    turingMachinesAdvanced,
    algorithmDesignAdvanced,
  ];

  /// Get paths by level
  static Map<String, List<Map<String, dynamic>>> get pathsByLevel => {
    'beginner': [finiteAutomataIntro, regularExpressionsIntro],
    'intermediate': [pushdownAutomataIntermediate, contextFreeGrammarsIntermediate],
    'advanced': [turingMachinesAdvanced, algorithmDesignAdvanced],
  };

  /// Get recommended path for skill level
  static Map<String, dynamic>? getRecommendedPath(String skillLevel) {
    switch (skillLevel.toLowerCase()) {
      case 'beginner':
        return finiteAutomataIntro;
      case 'intermediate':
        return pushdownAutomataIntermediate;
      case 'advanced':
        return turingMachinesAdvanced;
      default:
        return null;
    }
  }

  /// Get prerequisites for a path
  static List<String> getPrerequisites(String pathTitle) {
    final path = allPaths.firstWhere(
      (p) => p['title'] == pathTitle,
      orElse: () => {},
    );
    return path['prerequisites'] ?? [];
  }

  /// Get estimated completion time
  static String getEstimatedTime(String pathTitle) {
    final path = allPaths.firstWhere(
      (p) => p['title'] == pathTitle,
      orElse: () => {},
    );
    return path['duration'] ?? 'Unknown';
  }
}
