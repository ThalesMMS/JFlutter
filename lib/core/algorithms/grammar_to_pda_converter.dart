import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../models/grammar.dart';
import '../models/pda.dart';
import '../models/pda_transition.dart';
import '../models/production.dart';
import '../models/state.dart';
import '../models/transition.dart';
import '../result.dart';

/// Converts context-free grammars to pushdown automata
class GrammarToPDAConverter {
  /// Checks if a grammar can be converted to PDA
  static bool canConvertToPDA(Grammar grammar) {
    try {
      // Basic validation
      if (grammar.productions.isEmpty) return false;
      if (grammar.startSymbol.isEmpty) return false;
      
      // Check if all productions are valid for PDA conversion
      for (final production in grammar.productions) {
        if (production.leftSide.isEmpty) return false;
        // Additional validation can be added here
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Analyzes the conversion process
  static Result<GrammarToPDAAnalysis> analyzeConversion(Grammar grammar) {
    try {
      final canConvert = canConvertToPDA(grammar);
      final productionCount = grammar.productions.length;
      final nonTerminalCount = grammar.nonTerminals.length;
      final terminalCount = grammar.terminals.length;
      
      final analysis = GrammarToPDAAnalysis(
        canConvert: canConvert,
        productionCount: productionCount,
        nonTerminalCount: nonTerminalCount,
        terminalCount: terminalCount,
        estimatedStateCount: productionCount + 2, // Rough estimate
        estimatedTransitionCount: productionCount * 2, // Rough estimate
      );
      
      return ResultFactory.success(analysis);
    } catch (e) {
      return ResultFactory.failure('Error analyzing conversion: $e');
    }
  }

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
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return ResultFactory.failure('Cannot convert empty grammar to PDA');
      }

      // Check if grammar has start symbol
      if (grammar.startSymbol.isEmpty) {
        return ResultFactory.failure('Grammar must have a start symbol');
      }

      // Build PDA using the standard construction
      final result = _buildStandardPDA(grammar);
      
      stopwatch.stop();
      if (stopwatch.elapsed > timeout) {
        return ResultFactory.failure('Conversion timed out');
      }

      return ResultFactory.success(result);
    } catch (e) {
      return ResultFactory.failure('Error converting grammar to PDA: $e');
    }
  }

  /// Validates input grammar
  static Result<void> _validateInput(Grammar grammar) {
    if (grammar.productions.isEmpty) {
      return ResultFactory.failure('Grammar must have at least one production');
    }

    if (grammar.startSymbol.isEmpty) {
      return ResultFactory.failure('Grammar must have a start symbol');
    }

    if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
      return ResultFactory.failure('Start symbol must be a non-terminal');
    }

    return ResultFactory.success(null);
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
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return ResultFactory.failure('Cannot convert empty grammar to PDA');
      }

      // Check if grammar has start symbol
      if (grammar.startSymbol.isEmpty) {
        return ResultFactory.failure('Grammar must have a start symbol');
      }

      final result = _buildStandardPDA(grammar);
      
      stopwatch.stop();
      if (stopwatch.elapsed > timeout) {
        return ResultFactory.failure('Conversion timed out');
      }

      return ResultFactory.success(result);
    } catch (e) {
      return ResultFactory.failure('Error converting grammar to PDA (standard): $e');
    }
  }

  /// Converts a grammar to a PDA using Greibach normal form
  static Result<PDA> convertGrammarToPDAGreibach(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(grammar);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return ResultFactory.failure('Cannot convert empty grammar to PDA');
      }

      // Check if grammar has start symbol
      if (grammar.startSymbol.isEmpty) {
        return ResultFactory.failure('Grammar must have a start symbol');
      }

      final result = _buildGreibachPDA(grammar);
      
      stopwatch.stop();
      if (stopwatch.elapsed > timeout) {
        return ResultFactory.failure('Conversion timed out');
      }

      return ResultFactory.success(result);
    } catch (e) {
      return ResultFactory.failure('Error converting grammar to PDA (Greibach): $e');
    }
  }

  /// Checks if a grammar can be converted to a PDA
  static Result<bool> canConvertGrammarToPDA(Grammar grammar) {
    try {
      // Validate input
      final validationResult = _validateInput(grammar);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Check if grammar is context-free
      if (grammar.productions.any((p) => p.leftSide.length > 1)) {
        return ResultFactory.failure('Grammar is not context-free');
      }

      if (grammar.startSymbol.isEmpty) {
        return ResultFactory.failure('Grammar must have a start symbol');
      }

      if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
        return ResultFactory.failure('Start symbol must be a non-terminal');
      }

      return ResultFactory.success(true);
    } catch (e) {
      return ResultFactory.failure('Error checking if grammar can be converted to PDA: $e');
    }
  }

  /// Analyzes the conversion of a grammar to PDA
  static Result<Map<String, dynamic>> analyzeGrammarToPDAConversion(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Validate input
      final validationResult = _validateInput(grammar);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return ResultFactory.failure('Cannot analyze conversion of empty grammar');
      }

      // Check if grammar has start symbol
      if (grammar.startSymbol.isEmpty) {
        return ResultFactory.failure('Grammar must have a start symbol');
      }

      // Create analysis result
      final finalResult = <String, dynamic>{
        'grammar': grammar.toJson(),
        'canConvert': true,
        'complexity': 'O(n)',
        'steps': [
          'Validate grammar',
          'Create initial state',
          'Create processing state',
          'Create accepting state',
          'Add transitions',
        ],
        'timeout': timeout.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      stopwatch.stop();
      if (stopwatch.elapsed > timeout) {
        return ResultFactory.failure('Analysis timed out');
      }

      return ResultFactory.success(finalResult);
    } catch (e) {
      return ResultFactory.failure('Error analyzing grammar to PDA conversion: $e');
    }
  }

  static PDA _buildStandardPDA(Grammar grammar) {
    _ensureContextFree(grammar);

    final now = DateTime.now();
    final states = _createCanonicalStates();
    final transitions = <PDATransition>[];
    final bottomSymbol = _initialStackSymbol;

    var transitionCounter = 0;

    transitions.add(_initialPushTransition(
      states: states,
      startSymbol: grammar.startSymbol,
      transitionId: 'init_${transitionCounter++}',
    ));

    for (final production in grammar.productions) {
      final leftSide = production.leftSide;
      if (leftSide.length != 1) {
        throw ArgumentError('Standard PDA conversion requires CFG productions with a single left-hand symbol.');
      }

      final leftSymbol = leftSide.first;
      final rightSymbols = production.isLambda ? <String>[] : production.rightSide;
      final pushSymbols = rightSymbols.reversed.toList();

      transitions.add(
        PDATransition(
          id: 'expand_${transitionCounter++}',
          fromState: states.processing,
          toState: states.processing,
          label: 'ε,$leftSymbol/${pushSymbols.isEmpty ? 'ε' : pushSymbols.join(' ')}',
          inputSymbol: '',
          popSymbol: leftSymbol,
          pushSymbol: pushSymbols.join(' '),
          isLambdaInput: true,
          isLambdaPush: pushSymbols.isEmpty,
        ),
      );
    }

    for (final terminal in grammar.terminals) {
      transitions.add(
        PDATransition(
          id: 'read_${transitionCounter++}_$terminal',
          fromState: states.processing,
          toState: states.processing,
          label: '$terminal,$terminal/ε',
          inputSymbol: terminal,
          popSymbol: terminal,
          pushSymbol: '',
          isLambdaPush: true,
        ),
      );
    }

    transitions.add(
      _acceptanceTransition(
        states: states,
        transitionId: 'accept_${transitionCounter++}',
        bottomSymbol: bottomSymbol,
      ),
    );

    return PDA(
      id: 'pda_${DateTime.now().millisecondsSinceEpoch}',
      name: 'PDA from ${grammar.name}',
      states: {states.start, states.processing, states.accepting},
      transitions: transitions.map<Transition>((t) => t).toSet(),
      alphabet: grammar.terminals,
      initialState: states.start,
      acceptingStates: {states.accepting},
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
      stackAlphabet: {
        ...grammar.terminals,
        ...grammar.nonTerminals,
        bottomSymbol,
      },
      initialStackSymbol: bottomSymbol,
    );
  }

  static PDA _buildGreibachPDA(Grammar grammar) {
    _ensureContextFree(grammar);

    final now = DateTime.now();
    final states = _createCanonicalStates();
    final transitions = <PDATransition>[];
    var transitionCounter = 0;

    transitions.add(_initialPushTransition(
      states: states,
      startSymbol: grammar.startSymbol,
      transitionId: 'init_${transitionCounter++}',
    ));

    for (final production in grammar.productions) {
      final leftSide = production.leftSide;
      if (leftSide.length != 1) {
        throw ArgumentError('Greibach conversion requires CFG productions with a single left-hand symbol.');
      }

      final leftSymbol = leftSide.first;
      if (production.isLambda || production.rightSide.isEmpty) {
        transitions.add(
          PDATransition(
            id: 'gnf_eps_${transitionCounter++}',
            fromState: states.processing,
            toState: states.processing,
            label: 'ε,$leftSymbol/ε',
            inputSymbol: '',
            popSymbol: leftSymbol,
            pushSymbol: '',
            isLambdaInput: true,
            isLambdaPush: true,
          ),
        );
        continue;
      }

      final firstSymbol = production.rightSide.first;
      if (!grammar.terminals.contains(firstSymbol)) {
        throw ArgumentError(
          'Greibach conversion expects productions to begin with a terminal. Found "$firstSymbol" in ${production.stringRepresentation}.',
        );
      }

      final remainingSymbols = production.rightSide.skip(1).toList();
      final pushSymbols = remainingSymbols.reversed.toList();

      transitions.add(
        PDATransition(
          id: 'gnf_${transitionCounter++}',
          fromState: states.processing,
          toState: states.processing,
          label: '${firstSymbol},$leftSymbol/${pushSymbols.isEmpty ? 'ε' : pushSymbols.join(' ')}',
          inputSymbol: firstSymbol,
          popSymbol: leftSymbol,
          pushSymbol: pushSymbols.join(' '),
          isLambdaPush: pushSymbols.isEmpty,
        ),
      );
    }

    transitions.add(
      _acceptanceTransition(
        states: states,
        transitionId: 'accept_${transitionCounter++}',
        bottomSymbol: _initialStackSymbol,
      ),
    );

    return PDA(
      id: 'pda_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Greibach PDA from ${grammar.name}',
      states: {states.start, states.processing, states.accepting},
      transitions: transitions.map<Transition>((t) => t).toSet(),
      alphabet: grammar.terminals,
      initialState: states.start,
      acceptingStates: {states.accepting},
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
      stackAlphabet: {
        ...grammar.terminals,
        ...grammar.nonTerminals,
        _initialStackSymbol,
      },
      initialStackSymbol: _initialStackSymbol,
    );
  }

  static _PDAStates _createCanonicalStates() {
    final start = State(
      id: 'q_start',
      label: 'Start',
      position: Vector2(100, 200),
      isInitial: true,
    );

    final processing = State(
      id: 'q_process',
      label: 'Process',
      position: Vector2(300, 200),
    );

    final accepting = State(
      id: 'q_accept',
      label: 'Accept',
      position: Vector2(520, 200),
      isAccepting: true,
    );

    return _PDAStates(start: start, processing: processing, accepting: accepting);
  }

  static PDATransition _initialPushTransition({
    required _PDAStates states,
    required String startSymbol,
    required String transitionId,
  }) {
    final pushSymbols = [_initialStackSymbol, startSymbol];
    return PDATransition(
      id: transitionId,
      fromState: states.start,
      toState: states.processing,
      label: 'ε,$_initialStackSymbol/${pushSymbols.join(' ')}',
      inputSymbol: '',
      popSymbol: _initialStackSymbol,
      pushSymbol: pushSymbols.join(' '),
      isLambdaInput: true,
    );
  }

  static PDATransition _acceptanceTransition({
    required _PDAStates states,
    required String transitionId,
    required String bottomSymbol,
  }) {
    return PDATransition(
      id: transitionId,
      fromState: states.processing,
      toState: states.accepting,
      label: 'ε,$bottomSymbol/ε',
      inputSymbol: '',
      popSymbol: bottomSymbol,
      pushSymbol: '',
      isLambdaInput: true,
      isLambdaPush: true,
    );
  }

  static void _ensureContextFree(Grammar grammar) {
    final hasInvalidProduction =
        grammar.productions.any((production) => production.leftSide.length != 1);
    if (hasInvalidProduction) {
      throw ArgumentError('Grammar must be context-free (single-symbol left side) for PDA conversion.');
    }
  }
}

const String _initialStackSymbol = 'Z';

class _PDAStates {
  final State start;
  final State processing;
  final State accepting;

  const _PDAStates({
    required this.start,
    required this.processing,
    required this.accepting,
  });
}

/// Analysis result for grammar to PDA conversion
class GrammarToPDAAnalysis {
  /// Whether the grammar can be converted to PDA
  final bool canConvert;
  
  /// Number of productions in the grammar
  final int productionCount;
  
  /// Number of non-terminals
  final int nonTerminalCount;
  
  /// Number of terminals
  final int terminalCount;
  
  /// Estimated number of states in the resulting PDA
  final int estimatedStateCount;
  
  /// Estimated number of transitions in the resulting PDA
  final int estimatedTransitionCount;

  const GrammarToPDAAnalysis({
    required this.canConvert,
    required this.productionCount,
    required this.nonTerminalCount,
    required this.terminalCount,
    required this.estimatedStateCount,
    required this.estimatedTransitionCount,
  });

  @override
  String toString() {
    return 'GrammarToPDAAnalysis(canConvert: $canConvert, '
        'productionCount: $productionCount, '
        'nonTerminalCount: $nonTerminalCount, '
        'terminalCount: $terminalCount, '
        'estimatedStateCount: $estimatedStateCount, '
        'estimatedTransitionCount: $estimatedTransitionCount)';
  }
}