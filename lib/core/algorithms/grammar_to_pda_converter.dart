import '../models/grammar.dart';
import '../models/pda.dart';
import '../models/state.dart';
import '../models/pda_transition.dart';
import '../result.dart';

/// Converts context-free grammars to pushdown automata
class GrammarToPDAConverter {
  /// Converts a grammar to a PDA
  static Result<PDA> convertGrammarToPDA(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(grammar);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return Result.failure('Cannot convert empty grammar to PDA');
      }

      // Handle grammar with no start symbol
      if (grammar.startSymbol == null) {
        return Result.failure('Grammar must have a start symbol');
      }

      // Convert the grammar to PDA
      final result = _convertGrammarToPDA(grammar, timeout);
      stopwatch.stop();
      
      return Result.success(result);
    } catch (e) {
      return Result.failure('Error converting grammar to PDA: $e');
    }
  }

  /// Validates the input grammar
  static Result<void> _validateInput(Grammar grammar) {
    if (grammar.productions.isEmpty) {
      return Result.failure('Grammar must have at least one production');
    }
    
    if (grammar.startSymbol == null) {
      return Result.failure('Grammar must have a start symbol');
    }
    
    if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
      return Result.failure('Start symbol must be a non-terminal');
    }
    
    return Result.success(null);
  }

  /// Converts the grammar to PDA
  static PDA _convertGrammarToPDA(
    Grammar grammar,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // Create states
    final states = <State>{
      State(id: 'q0', name: 'Initial'),
      State(id: 'q1', name: 'Processing'),
      State(id: 'q2', name: 'Accepting'),
    };
    
    // Create initial state
    final initialState = states.first;
    
    // Create accepting states
    final acceptingStates = {states.last};
    
    // Create alphabet (terminals)
    final alphabet = grammar.terminals.toSet();
    
    // Create stack alphabet (terminals + non-terminals)
    final stackAlphabet = <String>{
      ...grammar.terminals,
      ...grammar.nonTerminals,
    };
    
    // Create initial stack symbol
    const initialStackSymbol = 'Z';
    
    // Create transitions
    final transitions = <PDATransition>[];
    
    // Transition from q0 to q1: push start symbol
    transitions.add(PDATransition(
      fromState: initialState,
      toState: states.elementAt(1),
      readSymbol: '',
      stackPop: '',
      stackPush: grammar.startSymbol!,
    ));
    
    // Transitions for each production
    for (final production in grammar.productions) {
      // Transition from q1 to q1: replace non-terminal with right side
      transitions.add(PDATransition(
        fromState: states.elementAt(1),
        toState: states.elementAt(1),
        readSymbol: '',
        stackPop: production.leftSide,
        stackPush: production.rightSide.join(''),
      ));
    }
    
    // Transitions for terminals
    for (final terminal in grammar.terminals) {
      // Transition from q1 to q1: read terminal and pop it from stack
      transitions.add(PDATransition(
        fromState: states.elementAt(1),
        toState: states.elementAt(1),
        readSymbol: terminal,
        stackPop: terminal,
        stackPush: '',
      ));
    }
    
    // Transition from q1 to q2: pop initial stack symbol
    transitions.add(PDATransition(
      fromState: states.elementAt(1),
      toState: states.elementAt(2),
      readSymbol: '',
      stackPop: initialStackSymbol,
      stackPush: '',
    ));
    
    // Create PDA
    return PDA(
      states: states,
      alphabet: alphabet,
      stackAlphabet: stackAlphabet,
      initialState: initialState,
      initialStackSymbol: initialStackSymbol,
      acceptingStates: acceptingStates,
      transitions: transitions,
    );
  }

  /// Converts a grammar to a PDA using the standard construction
  static Result<PDA> convertGrammarToPDAStandard(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(grammar);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return Result.failure('Cannot convert empty grammar to PDA');
      }

      // Handle grammar with no start symbol
      if (grammar.startSymbol == null) {
        return Result.failure('Grammar must have a start symbol');
      }

      // Convert the grammar to PDA using standard construction
      final result = _convertGrammarToPDAStandard(grammar, timeout);
      stopwatch.stop();
      
      return Result.success(result);
    } catch (e) {
      return Result.failure('Error converting grammar to PDA (standard): $e');
    }
  }

  /// Converts the grammar to PDA using standard construction
  static PDA _convertGrammarToPDAStandard(
    Grammar grammar,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // Create states
    final states = <State>{
      State(id: 'q0', name: 'Initial'),
      State(id: 'q1', name: 'Processing'),
      State(id: 'q2', name: 'Accepting'),
    };
    
    // Create initial state
    final initialState = states.first;
    
    // Create accepting states
    final acceptingStates = {states.last};
    
    // Create alphabet (terminals)
    final alphabet = grammar.terminals.toSet();
    
    // Create stack alphabet (terminals + non-terminals)
    final stackAlphabet = <String>{
      ...grammar.terminals,
      ...grammar.nonTerminals,
    };
    
    // Create initial stack symbol
    const initialStackSymbol = 'Z';
    
    // Create transitions
    final transitions = <PDATransition>[];
    
    // Transition from q0 to q1: push start symbol
    transitions.add(PDATransition(
      fromState: initialState,
      toState: states.elementAt(1),
      readSymbol: '',
      stackPop: '',
      stackPush: grammar.startSymbol!,
    ));
    
    // Transitions for each production
    for (final production in grammar.productions) {
      // Transition from q1 to q1: replace non-terminal with right side
      transitions.add(PDATransition(
        fromState: states.elementAt(1),
        toState: states.elementAt(1),
        readSymbol: '',
        stackPop: production.leftSide,
        stackPush: production.rightSide.join(''),
      ));
    }
    
    // Transitions for terminals
    for (final terminal in grammar.terminals) {
      // Transition from q1 to q1: read terminal and pop it from stack
      transitions.add(PDATransition(
        fromState: states.elementAt(1),
        toState: states.elementAt(1),
        readSymbol: terminal,
        stackPop: terminal,
        stackPush: '',
      ));
    }
    
    // Transition from q1 to q2: pop initial stack symbol
    transitions.add(PDATransition(
      fromState: states.elementAt(1),
      toState: states.elementAt(2),
      readSymbol: '',
      stackPop: initialStackSymbol,
      stackPush: '',
    ));
    
    // Create PDA
    return PDA(
      states: states,
      alphabet: alphabet,
      stackAlphabet: stackAlphabet,
      initialState: initialState,
      initialStackSymbol: initialStackSymbol,
      acceptingStates: acceptingStates,
      transitions: transitions,
    );
  }

  /// Converts a grammar to a PDA using the Greibach normal form construction
  static Result<PDA> convertGrammarToPDAGreibach(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(grammar);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return Result.failure('Cannot convert empty grammar to PDA');
      }

      // Handle grammar with no start symbol
      if (grammar.startSymbol == null) {
        return Result.failure('Grammar must have a start symbol');
      }

      // Convert grammar to Greibach normal form
      final greibachGrammar = _convertToGreibachNormalForm(grammar, timeout);
      
      // Convert Greibach grammar to PDA
      final result = _convertGreibachGrammarToPDA(greibachGrammar, timeout);
      stopwatch.stop();
      
      return Result.success(result);
    } catch (e) {
      return Result.failure('Error converting grammar to PDA (Greibach): $e');
    }
  }

  /// Converts grammar to Greibach normal form
  static Grammar _convertToGreibachNormalForm(
    Grammar grammar,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // This is a simplified conversion - in practice, this would be more complex
    final productions = <Production>[];
    
    for (final production in grammar.productions) {
      if (production.rightSide.length == 1 && grammar.terminals.contains(production.rightSide[0])) {
        // Production is already in Greibach normal form
        productions.add(production);
      } else if (production.rightSide.length == 2 && 
                 grammar.terminals.contains(production.rightSide[0]) &&
                 grammar.nonTerminals.contains(production.rightSide[1])) {
        // Production is already in Greibach normal form
        productions.add(production);
      } else {
        // Convert to Greibach normal form (simplified)
        final newProductions = _convertProductionToGreibach(production, grammar);
        productions.addAll(newProductions);
      }
    }
    
    return Grammar(
      productions: productions,
      startSymbol: grammar.startSymbol,
      nonTerminals: grammar.nonTerminals,
      terminals: grammar.terminals,
    );
  }

  /// Converts a production to Greibach normal form
  static List<Production> _convertProductionToGreibach(
    Production production,
    Grammar grammar,
  ) {
    final newProductions = <Production>[];
    
    if (production.rightSide.length == 1 && grammar.terminals.contains(production.rightSide[0])) {
      // Already in Greibach normal form
      newProductions.add(production);
    } else if (production.rightSide.length == 2 && 
               grammar.terminals.contains(production.rightSide[0]) &&
               grammar.nonTerminals.contains(production.rightSide[1])) {
      // Already in Greibach normal form
      newProductions.add(production);
    } else {
      // Convert to Greibach normal form (simplified)
      // This is a very basic conversion - in practice, this would be more complex
      final newNonTerminal = '${production.leftSide}_new';
      newProductions.add(Production(
        leftSide: production.leftSide,
        rightSide: [production.rightSide[0], newNonTerminal],
      ));
      newProductions.add(Production(
        leftSide: newNonTerminal,
        rightSide: production.rightSide.sublist(1),
      ));
    }
    
    return newProductions;
  }

  /// Converts Greibach grammar to PDA
  static PDA _convertGreibachGrammarToPDA(
    Grammar greibachGrammar,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // Create states
    final states = <State>{
      State(id: 'q0', name: 'Initial'),
      State(id: 'q1', name: 'Processing'),
      State(id: 'q2', name: 'Accepting'),
    };
    
    // Create initial state
    final initialState = states.first;
    
    // Create accepting states
    final acceptingStates = {states.last};
    
    // Create alphabet (terminals)
    final alphabet = greibachGrammar.terminals.toSet();
    
    // Create stack alphabet (terminals + non-terminals)
    final stackAlphabet = <String>{
      ...greibachGrammar.terminals,
      ...greibachGrammar.nonTerminals,
    };
    
    // Create initial stack symbol
    const initialStackSymbol = 'Z';
    
    // Create transitions
    final transitions = <PDATransition>[];
    
    // Transition from q0 to q1: push start symbol
    transitions.add(PDATransition(
      fromState: initialState,
      toState: states.elementAt(1),
      readSymbol: '',
      stackPop: '',
      stackPush: greibachGrammar.startSymbol!,
    ));
    
    // Transitions for each production in Greibach normal form
    for (final production in greibachGrammar.productions) {
      if (production.rightSide.length == 1 && greibachGrammar.terminals.contains(production.rightSide[0])) {
        // Production A -> a
        transitions.add(PDATransition(
          fromState: states.elementAt(1),
          toState: states.elementAt(1),
          readSymbol: production.rightSide[0],
          stackPop: production.leftSide,
          stackPush: '',
        ));
      } else if (production.rightSide.length == 2 && 
                 greibachGrammar.terminals.contains(production.rightSide[0]) &&
                 greibachGrammar.nonTerminals.contains(production.rightSide[1])) {
        // Production A -> aB
        transitions.add(PDATransition(
          fromState: states.elementAt(1),
          toState: states.elementAt(1),
          readSymbol: production.rightSide[0],
          stackPop: production.leftSide,
          stackPush: production.rightSide[1],
        ));
      }
    }
    
    // Transition from q1 to q2: pop initial stack symbol
    transitions.add(PDATransition(
      fromState: states.elementAt(1),
      toState: states.elementAt(2),
      readSymbol: '',
      stackPop: initialStackSymbol,
      stackPush: '',
    ));
    
    // Create PDA
    return PDA(
      states: states,
      alphabet: alphabet,
      stackAlphabet: stackAlphabet,
      initialState: initialState,
      initialStackSymbol: initialStackSymbol,
      acceptingStates: acceptingStates,
      transitions: transitions,
    );
  }

  /// Tests if a grammar can be converted to a PDA
  static Result<bool> canConvertToPDA(Grammar grammar) {
    try {
      // Check if grammar is context-free
      if (!_isContextFree(grammar)) {
        return Result.failure('Grammar is not context-free');
      }
      
      // Check if grammar has a start symbol
      if (grammar.startSymbol == null) {
        return Result.failure('Grammar must have a start symbol');
      }
      
      // Check if start symbol is a non-terminal
      if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
        return Result.failure('Start symbol must be a non-terminal');
      }
      
      return Result.success(true);
    } catch (e) {
      return Result.failure('Error checking if grammar can be converted to PDA: $e');
    }
  }

  /// Checks if a grammar is context-free
  static bool _isContextFree(Grammar grammar) {
    // A grammar is context-free if all productions have exactly one non-terminal on the left side
    for (final production in grammar.productions) {
      if (production.leftSide.length != 1 || !grammar.nonTerminals.contains(production.leftSide)) {
        return false;
      }
    }
    
    return true;
  }

  /// Analyzes the conversion from grammar to PDA
  static Result<GrammarToPDAAnalysis> analyzeConversion(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(grammar);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return Result.failure('Cannot analyze conversion of empty grammar');
      }

      // Handle grammar with no start symbol
      if (grammar.startSymbol == null) {
        return Result.failure('Grammar must have a start symbol');
      }

      // Analyze the conversion
      final result = _analyzeConversion(grammar, timeout);
      stopwatch.stop();
      
      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);
      
      return Result.success(finalResult);
    } catch (e) {
      return Result.failure('Error analyzing grammar to PDA conversion: $e');
    }
  }

  /// Analyzes the conversion
  static GrammarToPDAAnalysis _analyzeConversion(
    Grammar grammar,
    Duration timeout,
  ) {
    final startTime = DateTime.now();
    
    // Analyze grammar
    final grammarAnalysis = _analyzeGrammar(grammar);
    
    // Analyze PDA
    final pda = _convertGrammarToPDA(grammar, timeout);
    final pdaAnalysis = _analyzePDA(pda);
    
    // Analyze conversion
    final conversionAnalysis = _analyzeConversionProcess(grammar, pda);
    
    return GrammarToPDAAnalysis(
      grammarAnalysis: grammarAnalysis,
      pdaAnalysis: pdaAnalysis,
      conversionAnalysis: conversionAnalysis,
      executionTime: DateTime.now().difference(startTime),
    );
  }

  /// Analyzes the grammar
  static GrammarAnalysis _analyzeGrammar(Grammar grammar) {
    final totalProductions = grammar.productions.length;
    final terminalProductions = grammar.productions.where((p) => 
        p.rightSide.length == 1 && grammar.terminals.contains(p.rightSide[0])).length;
    final nonTerminalProductions = grammar.productions.where((p) => 
        p.rightSide.any((s) => grammar.nonTerminals.contains(s))).length;
    
    return GrammarAnalysis(
      totalProductions: totalProductions,
      terminalProductions: terminalProductions,
      nonTerminalProductions: nonTerminalProductions,
    );
  }

  /// Analyzes the PDA
  static PDAAnalysis _analyzePDA(PDA pda) {
    final totalStates = pda.states.length;
    final totalTransitions = pda.transitions.length;
    final stackOperations = pda.transitions.whereType<PDATransition>().length;
    
    return PDAAnalysis(
      totalStates: totalStates,
      totalTransitions: totalTransitions,
      stackOperations: stackOperations,
    );
  }

  /// Analyzes the conversion process
  static ConversionAnalysis _analyzeConversionProcess(Grammar grammar, PDA pda) {
    final grammarComplexity = grammar.productions.length;
    final pdaComplexity = pda.transitions.length;
    final conversionRatio = pdaComplexity / grammarComplexity;
    
    return ConversionAnalysis(
      grammarComplexity: grammarComplexity,
      pdaComplexity: pdaComplexity,
      conversionRatio: conversionRatio,
    );
  }
}

/// Analysis result of grammar to PDA conversion
class GrammarToPDAAnalysis {
  final GrammarAnalysis grammarAnalysis;
  final PDAAnalysis pdaAnalysis;
  final ConversionAnalysis conversionAnalysis;
  final Duration executionTime;

  const GrammarToPDAAnalysis({
    required this.grammarAnalysis,
    required this.pdaAnalysis,
    required this.conversionAnalysis,
    required this.executionTime,
  });

  GrammarToPDAAnalysis copyWith({
    GrammarAnalysis? grammarAnalysis,
    PDAAnalysis? pdaAnalysis,
    ConversionAnalysis? conversionAnalysis,
    Duration? executionTime,
  }) {
    return GrammarToPDAAnalysis(
      grammarAnalysis: grammarAnalysis ?? this.grammarAnalysis,
      pdaAnalysis: pdaAnalysis ?? this.pdaAnalysis,
      conversionAnalysis: conversionAnalysis ?? this.conversionAnalysis,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}

/// Analysis of grammar
class GrammarAnalysis {
  final int totalProductions;
  final int terminalProductions;
  final int nonTerminalProductions;

  const GrammarAnalysis({
    required this.totalProductions,
    required this.terminalProductions,
    required this.nonTerminalProductions,
  });
}

/// Analysis of PDA
class PDAAnalysis {
  final int totalStates;
  final int totalTransitions;
  final int stackOperations;

  const PDAAnalysis({
    required this.totalStates,
    required this.totalTransitions,
    required this.stackOperations,
  });
}

/// Analysis of conversion process
class ConversionAnalysis {
  final int grammarComplexity;
  final int pdaComplexity;
  final double conversionRatio;

  const ConversionAnalysis({
    required this.grammarComplexity,
    required this.pdaComplexity,
    required this.conversionRatio,
  });
}
