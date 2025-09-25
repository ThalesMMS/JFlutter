import '../models/fsa.dart';
import '../models/pda.dart';
import '../models/tm.dart';
import '../models/grammar.dart';
import '../models/pumping_lemma_game.dart' as models;
import '../models/pumping_attempt.dart';
import '../models/simulation_result.dart';
import '../models/tm_analysis.dart';
import '../result.dart';
import '../packages/core_pda/simulation.dart';
import 'nfa_to_dfa_converter.dart';
import 'dfa_minimizer.dart';
import 'regex_to_nfa_converter.dart';
import 'fa_to_regex_converter.dart';
import 'automaton_simulator.dart';
import 'grammar_parser.dart';
import 'pumping_lemma_prover.dart';
import 'pda_simulator.dart';
import 'tm_simulator.dart';
import 'grammar_to_pda_converter.dart';
import 'pumping_lemma_game.dart';

/// Provides high-level operations for all algorithms
class AlgorithmOperations {
  /// Converts an NFA to a DFA
  static Result<FSA> convertNfaToDfa(FSA nfa) {
    try {
      return NFAToDFAConverter.convert(nfa);
    } catch (e) {
      return ResultFactory.failure('Error converting NFA to DFA: $e');
    }
  }

  /// Minimizes a DFA
  static Result<FSA> minimizeDfa(FSA dfa) {
    try {
      return DFAMinimizer.minimize(dfa);
    } catch (e) {
      return ResultFactory.failure('Error minimizing DFA: $e');
    }
  }

  /// Converts a regular expression to an NFA
  static Result<FSA> convertRegexToNfa(String regex) {
    try {
      return RegexToNFAConverter.convert(regex);
    } catch (e) {
      return ResultFactory.failure('Error converting regex to NFA: $e');
    }
  }

  /// Converts a finite automaton to a regular expression
  static Result<String> convertFaToRegex(FSA fa) {
    try {
      return FAToRegexConverter.convert(fa);
    } catch (e) {
      return ResultFactory.failure('Error converting FA to regex: $e');
    }
  }

  /// Simulates a finite automaton
  static Result<SimulationResult> simulateAutomaton(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      return AutomatonSimulator.simulate(automaton, inputString, stepByStep: stepByStep, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error simulating automaton: $e');
    }
  }

  /// Simulates an NFA with epsilon transitions
  static Result<SimulationResult> simulateNfa(
    FSA nfa,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      return AutomatonSimulator.simulateNFA(nfa, inputString, stepByStep: stepByStep, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error simulating NFA: $e');
    }
  }

  /// Parses a string using a grammar
  static Result<ParseResult> parseString(
    Grammar grammar,
    String inputString, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      return GrammarParser.parse(grammar, inputString, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error parsing string: $e');
    }
  }

  /// Proves the pumping lemma for a regular language
  static Result<PumpingLemmaProof> provePumpingLemma(
    FSA automaton, {
    int maxPumpingLength = 100,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return PumpingLemmaProver.provePumpingLemma(automaton, maxPumpingLength: maxPumpingLength, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error proving pumping lemma: $e');
    }
  }

  /// Disproves the pumping lemma for a non-regular language
  static Result<PumpingLemmaDisproof> disprovePumpingLemma(
    FSA automaton, {
    int maxPumpingLength = 100,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return PumpingLemmaProver.disprovePumpingLemma(automaton, maxPumpingLength: maxPumpingLength, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error disproving pumping lemma: $e');
    }
  }

  /// Tests if a language is regular using the pumping lemma
  static Result<bool> isLanguageRegular(
    FSA automaton, {
    int maxPumpingLength = 100,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return PumpingLemmaProver.isLanguageRegular(automaton, maxPumpingLength: maxPumpingLength, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error testing language regularity: $e');
    }
  }


  /// Simulates a PDA
  static Result<PDASimulationResult> simulatePda(
    PDA pda,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
    int maxAcceptedPaths = 5,
  }) {
    try {
      return PDASimulator.simulate(
        pda,
        inputString,
        stepByStep: stepByStep,
        timeout: timeout,
        maxAcceptedPaths: maxAcceptedPaths,
      );
    } catch (e) {
      return ResultFactory.failure('Error simulating PDA: $e');
    }
  }

  /// Simulates a Turing machine
  static Result<TMSimulationResult> simulateTm(
    TM tm,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      return TMSimulator.simulate(tm, inputString, stepByStep: stepByStep, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error simulating Turing machine: $e');
    }
  }

  /// Creates a pumping lemma game
  static Result<models.PumpingLemmaGame> createPumpingLemmaGame(
    FSA automaton, {
    int maxPumpingLength = 100,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return PumpingLemmaGame.createGame(automaton, maxPumpingLength: maxPumpingLength, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error creating pumping lemma game: $e');
    }
  }

  /// Validates a pumping attempt
  static Result<PumpingAttemptResult> validatePumpingAttempt(
    models.PumpingLemmaGame game,
    PumpingAttempt attempt, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      return PumpingLemmaGame.validateAttempt(game, attempt, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error validating pumping attempt: $e');
    }
  }

  /// Updates a pumping lemma game
  static Result<models.PumpingLemmaGame> updatePumpingLemmaGame(
    models.PumpingLemmaGame game,
    PumpingAttempt attempt, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      return PumpingLemmaGame.updateGame(game, attempt, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error updating pumping lemma game: $e');
    }
  }

  /// Generates a hint for a pumping lemma game
  static Result<String> generatePumpingLemmaHint(
    models.PumpingLemmaGame game, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      return PumpingLemmaGame.generateHint(game, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error generating pumping lemma hint: $e');
    }
  }

  /// Analyzes a pumping lemma game
  static Result<GameAnalysis> analyzePumpingLemmaGame(
    models.PumpingLemmaGame game, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      return PumpingLemmaGame.analyzeGame(game, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error analyzing pumping lemma game: $e');
    }
  }


  /// Tests if an automaton accepts a specific string
  static Result<bool> accepts(FSA automaton, String inputString) {
    try {
      return AutomatonSimulator.accepts(automaton, inputString);
    } catch (e) {
      return ResultFactory.failure('Error testing acceptance: $e');
    }
  }

  /// Tests if an automaton rejects a specific string
  static Result<bool> rejects(FSA automaton, String inputString) {
    try {
      return AutomatonSimulator.rejects(automaton, inputString);
    } catch (e) {
      return ResultFactory.failure('Error testing rejection: $e');
    }
  }

  /// Tests if a grammar can generate a specific string
  static Result<bool> canGenerate(Grammar grammar, String inputString) {
    try {
      return GrammarParser.canGenerate(grammar, inputString);
    } catch (e) {
      return ResultFactory.failure('Error testing generation: $e');
    }
  }

  /// Tests if a grammar cannot generate a specific string
  static Result<bool> cannotGenerate(Grammar grammar, String inputString) {
    try {
      return GrammarParser.cannotGenerate(grammar, inputString);
    } catch (e) {
      return ResultFactory.failure('Error testing non-generation: $e');
    }
  }

  /// Finds all strings of a given length that an automaton accepts
  static Result<Set<String>> findAcceptedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      return AutomatonSimulator.findAcceptedStrings(automaton, maxLength, maxResults: maxResults);
    } catch (e) {
      return ResultFactory.failure('Error finding accepted strings: $e');
    }
  }

  /// Finds all strings of a given length that an automaton rejects
  static Result<Set<String>> findRejectedStrings(
    FSA automaton,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      return AutomatonSimulator.findRejectedStrings(automaton, maxLength, maxResults: maxResults);
    } catch (e) {
      return ResultFactory.failure('Error finding rejected strings: $e');
    }
  }

  /// Finds all strings of a given length that a grammar can generate
  static Result<Set<String>> findGeneratedStrings(
    Grammar grammar,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      return GrammarParser.findGeneratedStrings(grammar, maxLength, maxResults: maxResults);
    } catch (e) {
      return ResultFactory.failure('Error finding generated strings: $e');
    }
  }
}
