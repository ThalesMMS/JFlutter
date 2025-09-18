import '../entities/automaton_entity.dart';
import '../result.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';

/// Repository interface for automaton operations
/// This defines the contract that all automaton repositories must implement
abstract class AutomatonRepository {
  /// Saves an automaton
  Future<AutomatonResult> saveAutomaton(AutomatonEntity automaton);
  
  /// Loads an automaton by ID
  Future<AutomatonResult> loadAutomaton(String id);
  
  /// Loads all saved automatons
  Future<ListResult<AutomatonEntity>> loadAllAutomatons();
  
  /// Deletes an automaton by ID
  Future<BoolResult> deleteAutomaton(String id);
  
  /// Exports an automaton to JSON string
  Future<StringResult> exportAutomaton(AutomatonEntity automaton);
  
  /// Imports an automaton from JSON string
  Future<AutomatonResult> importAutomaton(String jsonString);
  
  /// Validates an automaton
  Future<BoolResult> validateAutomaton(AutomatonEntity automaton);
}

/// Repository interface for algorithm operations
abstract class AlgorithmRepository {
  /// Converts NFA to DFA
  Future<AutomatonResult> nfaToDfa(AutomatonEntity nfa);
  
  /// Removes lambda transitions from NFA
  Future<AutomatonResult> removeLambdaTransitions(AutomatonEntity nfa);
  
  /// Minimizes a DFA
  Future<AutomatonResult> minimizeDfa(AutomatonEntity dfa);
  
  /// Completes a DFA by adding trap state
  Future<AutomatonResult> completeDfa(AutomatonEntity dfa);
  
  /// Creates complement of a DFA
  Future<AutomatonResult> complementDfa(AutomatonEntity dfa);
  
  /// Creates union of two DFAs
  Future<AutomatonResult> unionDfa(AutomatonEntity a, AutomatonEntity b);
  
  /// Creates intersection of two DFAs
  Future<AutomatonResult> intersectionDfa(AutomatonEntity a, AutomatonEntity b);
  
  /// Creates difference of two DFAs (A \ B)
  Future<AutomatonResult> differenceDfa(AutomatonEntity a, AutomatonEntity b);
  
  /// Creates prefix closure of a DFA
  Future<AutomatonResult> prefixClosureDfa(AutomatonEntity dfa);
  
  /// Creates suffix closure of a DFA
  Future<AutomatonResult> suffixClosureDfa(AutomatonEntity dfa);
  
  /// Converts regex to NFA
  Future<AutomatonResult> regexToNfa(String regex);
  
  /// Converts DFA to regex
  Future<StringResult> dfaToRegex(AutomatonEntity dfa, {bool allowLambda = false});

  /// Converts FSA to regular grammar
  Future<GrammarResult> fsaToGrammar(AutomatonEntity fsa);
  
  /// Checks if two DFAs are equivalent
  Future<BoolResult> areEquivalent(AutomatonEntity a, AutomatonEntity b);
  
  /// Runs word simulation on an automaton
  Future<Result<SimulationResult>> simulateWord(AutomatonEntity automaton, String word);
  
  /// Runs step-by-step simulation
  Future<Result<List<SimulationStep>>> createStepByStepSimulation(
    AutomatonEntity automaton, 
    String word
  );
}

/// Repository interface for examples
abstract class ExamplesRepository {
  /// Loads all available examples
  Future<ListResult<ExampleEntity>> loadExamples();
  
  /// Loads a specific example by name
  Future<AutomatonResult> loadExample(String name);
}

/// Repository interface for layout operations
abstract class LayoutRepository {
  /// Applies compact layout to automaton
  Future<AutomatonResult> applyCompactLayout(AutomatonEntity automaton);
  
  /// Applies balanced layout to automaton
  Future<AutomatonResult> applyBalancedLayout(AutomatonEntity automaton);
  
  /// Applies spread layout to automaton
  Future<AutomatonResult> applySpreadLayout(AutomatonEntity automaton);
  
  /// Applies hierarchical layout to automaton
  Future<AutomatonResult> applyHierarchicalLayout(AutomatonEntity automaton);
  
  /// Applies auto layout to automaton
  Future<AutomatonResult> applyAutoLayout(AutomatonEntity automaton);
  
  /// Centers automaton in view
  Future<AutomatonResult> centerAutomaton(AutomatonEntity automaton);
}


/// Example entity
class ExampleEntity {
  final String name;
  final String description;
  final String category;
  final AutomatonEntity automaton;

  const ExampleEntity({
    required this.name,
    required this.description,
    required this.category,
    required this.automaton,
  });
}
