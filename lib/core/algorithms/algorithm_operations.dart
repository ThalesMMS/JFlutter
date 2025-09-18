import '../models/fsa.dart';
import '../models/pda.dart';
import '../models/tm.dart';
import '../models/grammar.dart';
import '../models/l_system.dart';
import '../models/l_system_parameters.dart';
import '../models/turtle_state.dart';
import '../models/building_block.dart';
import '../models/pumping_lemma_game.dart' as models;
import '../models/pumping_attempt.dart';
import '../models/simulation_result.dart';
import '../result.dart';
import 'nfa_to_dfa_converter.dart';
import 'dfa_minimizer.dart';
import 'regex_to_nfa_converter.dart';
import 'fa_to_regex_converter.dart';
import 'automaton_simulator.dart';
import 'grammar_parser.dart';
import 'pumping_lemma_prover.dart';
import 'l_system_generator.dart';
import 'mealy_machine_simulator.dart';
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

  /// Generates an L-system string
  static Result<String> generateLSystem(
    LSystem lSystem,
    int iterations, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return LSystemGenerator.generateLSystem(lSystem, iterations, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error generating L-system: $e');
    }
  }

  /// Generates a visual representation of an L-system
  static Result<List<TurtleState>> generateLSystemVisual(
    LSystem lSystem,
    int iterations,
    LSystemParameters parameters, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return LSystemGenerator.generateVisualRepresentation(lSystem, iterations, parameters, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error generating L-system visual: $e');
    }
  }

  /// Generates building blocks for an L-system
  static Result<List<BuildingBlock>> generateLSystemBuildingBlocks(
    LSystem lSystem,
    int iterations,
    LSystemParameters parameters, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return LSystemGenerator.generateBuildingBlocks(lSystem, iterations, parameters, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error generating L-system building blocks: $e');
    }
  }

  /// Simulates a Mealy machine
  static Result<MealySimulationResult> simulateMealyMachine(
    FSA automaton,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      return MealyMachineSimulator.simulate(automaton, inputString, stepByStep: stepByStep, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error simulating Mealy machine: $e');
    }
  }

  /// Simulates a PDA
  static Result<PDASimulationResult> simulatePda(
    PDA pda,
    String inputString, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      return PDASimulator.simulate(pda, inputString, stepByStep: stepByStep, timeout: timeout);
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

  /// Converts a grammar to a PDA
  static Result<PDA> convertGrammarToPda(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return GrammarToPDAConverter.convertGrammarToPDA(grammar, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error converting grammar to PDA: $e');
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

  /// Creates a predefined L-system
  static Result<LSystem> createPredefinedLSystem(String name) {
    try {
      return LSystemGenerator.createPredefinedLSystem(name);
    } catch (e) {
      return ResultFactory.failure('Error creating predefined L-system: $e');
    }
  }

  /// Creates predefined L-system parameters
  static Result<LSystemParameters> createPredefinedParameters(String name) {
    try {
      return LSystemGenerator.createPredefinedParameters(name);
    } catch (e) {
      return ResultFactory.failure('Error creating predefined parameters: $e');
    }
  }

  /// Analyzes an L-system
  static Result<LSystemAnalysis> analyzeLSystem(
    LSystem lSystem,
    int iterations, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return LSystemGenerator.analyzeLSystem(lSystem, iterations, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error analyzing L-system: $e');
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

  /// Gets the output string for a given input in a Mealy machine
  static Result<String> getMealyOutput(FSA automaton, String inputString) {
    try {
      return MealyMachineSimulator.getOutput(automaton, inputString);
    } catch (e) {
      return ResultFactory.failure('Error getting Mealy output: $e');
    }
  }

  /// Finds all input strings that produce a specific output in a Mealy machine
  static Result<Set<String>> findInputsForOutput(
    FSA automaton,
    String targetOutput, {
    int maxInputLength = 10,
    int maxResults = 100,
  }) {
    try {
      return MealyMachineSimulator.findInputsForOutput(automaton, targetOutput, maxInputLength: maxInputLength, maxResults: maxResults);
    } catch (e) {
      return ResultFactory.failure('Error finding inputs for output: $e');
    }
  }

  /// Finds all output strings that can be produced by a Mealy machine
  static Result<Set<String>> findPossibleOutputs(
    FSA automaton, {
    int maxInputLength = 10,
    int maxResults = 100,
  }) {
    try {
      return MealyMachineSimulator.findPossibleOutputs(automaton, maxInputLength: maxInputLength, maxResults: maxResults);
    } catch (e) {
      return ResultFactory.failure('Error finding possible outputs: $e');
    }
  }

  /// Analyzes a Mealy machine
  static Result<MealyAnalysis> analyzeMealyMachine(
    FSA automaton, {
    int maxInputLength = 10,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return MealyMachineSimulator.analyzeMealyMachine(automaton, maxInputLength: maxInputLength, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error analyzing Mealy machine: $e');
    }
  }

  /// Analyzes a PDA
  static Result<PDAAnalysis> analyzePda(
    PDA pda, {
    int maxInputLength = 10,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return PDASimulator.analyzePDA(pda, maxInputLength: maxInputLength, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error analyzing PDA: $e');
    }
  }

  /// Analyzes a Turing machine
  static Result<TMAnalysis> analyzeTm(
    TM tm, {
    int maxInputLength = 10,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return TMSimulator.analyzeTM(tm, maxInputLength: maxInputLength, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error analyzing Turing machine: $e');
    }
  }

  /// Tests if a grammar can be converted to a PDA
  static Result<bool> canConvertGrammarToPda(Grammar grammar) {
    try {
      final canConvert = GrammarToPDAConverter.canConvertToPDA(grammar);
      return ResultFactory.success(canConvert);
    } catch (e) {
      return ResultFactory.failure('Error testing grammar to PDA conversion: $e');
    }
  }

  /// Analyzes the conversion from grammar to PDA
  static Result<GrammarToPDAAnalysis> analyzeGrammarToPdaConversion(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return GrammarToPDAConverter.analyzeConversion(grammar);
    } catch (e) {
      return ResultFactory.failure('Error analyzing grammar to PDA conversion: $e');
    }
  }

  /// Converts a grammar to a PDA using the standard construction
  static Result<PDA> convertGrammarToPdaStandard(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return GrammarToPDAConverter.convertGrammarToPDAStandard(grammar, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error converting grammar to PDA (standard): $e');
    }
  }

  /// Converts a grammar to a PDA using the Greibach normal form construction
  static Result<PDA> convertGrammarToPdaGreibach(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      return GrammarToPDAConverter.convertGrammarToPDAGreibach(grammar, timeout: timeout);
    } catch (e) {
      return ResultFactory.failure('Error converting grammar to PDA (Greibach): $e');
    }
  }
}
