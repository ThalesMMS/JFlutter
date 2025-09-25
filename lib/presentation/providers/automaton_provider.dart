import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';
import 'package:conversions/conversions.dart';
import 'package:serializers/serializers.dart';

/// Provider for current automaton state
final automatonProvider = StateNotifierProvider<AutomatonNotifier, AutomatonState>((ref) {
  return AutomatonNotifier();
});

/// Provider for automaton operations
final automatonOperationsProvider = Provider<AutomatonOperations>((ref) {
  return AutomatonOperations();
});

/// Provider for file operations
final fileOperationsProvider = Provider<FileOperations>((ref) {
  return FileOperations();
});

/// Provider for visualization state
final visualizationProvider = StateNotifierProvider<VisualizationNotifier, VisualizationState>((ref) {
  return VisualizationNotifier();
});

/// Provider for algorithm execution
final algorithmProvider = StateNotifierProvider<AlgorithmNotifier, AlgorithmState>((ref) {
  return AlgorithmNotifier();
});

/// Automaton state
class AutomatonState {
  final FiniteAutomaton? currentFA;
  final PushdownAutomaton? currentPDA;
  final TuringMachine? currentTM;
  final ContextFreeGrammar? currentCFG;
  final RegularExpression? currentRegex;
  final String? selectedState;
  final Transition? selectedTransition;
  final bool isLoading;
  final String? error;

  const AutomatonState({
    this.currentFA,
    this.currentPDA,
    this.currentTM,
    this.currentCFG,
    this.currentRegex,
    this.selectedState,
    this.selectedTransition,
    this.isLoading = false,
    this.error,
  });

  AutomatonState copyWith({
    FiniteAutomaton? currentFA,
    PushdownAutomaton? currentPDA,
    TuringMachine? currentTM,
    ContextFreeGrammar? currentCFG,
    RegularExpression? currentRegex,
    String? selectedState,
    Transition? selectedTransition,
    bool? isLoading,
    String? error,
  }) {
    return AutomatonState(
      currentFA: currentFA ?? this.currentFA,
      currentPDA: currentPDA ?? this.currentPDA,
      currentTM: currentTM ?? this.currentTM,
      currentCFG: currentCFG ?? this.currentCFG,
      currentRegex: currentRegex ?? this.currentRegex,
      selectedState: selectedState ?? this.selectedState,
      selectedTransition: selectedTransition ?? this.selectedTransition,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Automaton notifier
class AutomatonNotifier extends StateNotifier<AutomatonState> {
  AutomatonNotifier() : super(const AutomatonState());

  /// Load finite automaton
  void loadFiniteAutomaton(FiniteAutomaton automaton) {
    state = state.copyWith(
      currentFA: automaton,
      currentPDA: null,
      currentTM: null,
      currentCFG: null,
      currentRegex: null,
      error: null,
    );
  }

  /// Load pushdown automaton
  void loadPushdownAutomaton(PushdownAutomaton automaton) {
    state = state.copyWith(
      currentFA: null,
      currentPDA: automaton,
      currentTM: null,
      currentCFG: null,
      currentRegex: null,
      error: null,
    );
  }

  /// Load Turing machine
  void loadTuringMachine(TuringMachine automaton) {
    state = state.copyWith(
      currentFA: null,
      currentPDA: null,
      currentTM: automaton,
      currentCFG: null,
      currentRegex: null,
      error: null,
    );
  }

  /// Load context-free grammar
  void loadContextFreeGrammar(ContextFreeGrammar grammar) {
    state = state.copyWith(
      currentFA: null,
      currentPDA: null,
      currentTM: null,
      currentCFG: grammar,
      currentRegex: null,
      error: null,
    );
  }

  /// Load regular expression
  void loadRegularExpression(RegularExpression regex) {
    state = state.copyWith(
      currentFA: null,
      currentPDA: null,
      currentTM: null,
      currentCFG: null,
      currentRegex: regex,
      error: null,
    );
  }

  /// Select state
  void selectState(String stateId) {
    state = state.copyWith(selectedState: stateId);
  }

  /// Select transition
  void selectTransition(Transition transition) {
    state = state.copyWith(selectedTransition: transition);
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(
      selectedState: null,
      selectedTransition: null,
    );
  }

  /// Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Set error
  void setError(String error) {
    state = state.copyWith(error: error);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Automaton operations
class AutomatonOperations {
  /// Convert NFA to DFA
  FiniteAutomaton convertNFAToDFA(FiniteAutomaton nfa) {
    return NFAToDFAConverter.convert(nfa);
  }

  /// Minimize DFA
  FiniteAutomaton minimizeDFA(FiniteAutomaton dfa) {
    return DFAMinimizer.minimize(dfa);
  }

  /// Union of two automata
  FiniteAutomaton union(FiniteAutomaton fa1, FiniteAutomaton fa2) {
    return LanguageOperations.union(fa1, fa2);
  }

  /// Intersection of two automata
  FiniteAutomaton intersection(FiniteAutomaton fa1, FiniteAutomaton fa2) {
    return LanguageOperations.intersection(fa1, fa2);
  }

  /// Complement of automaton
  FiniteAutomaton complement(FiniteAutomaton fa) {
    return LanguageOperations.complement(fa);
  }

  /// Concatenation of two automata
  FiniteAutomaton concatenation(FiniteAutomaton fa1, FiniteAutomaton fa2) {
    return LanguageOperations.concatenation(fa1, fa2);
  }

  /// Kleene star of automaton
  FiniteAutomaton kleeneStar(FiniteAutomaton fa) {
    return LanguageOperations.kleeneStar(fa);
  }

  /// Convert regex to NFA
  FiniteAutomaton convertRegexToNFA(RegularExpression regex) {
    return RegexToNFAConverter.convert(regex);
  }

  /// Convert FA to regex
  RegularExpression convertFAToRegex(FiniteAutomaton fa) {
    return FAToRegexConverter.convert(fa);
  }

  /// Convert CFG to PDA
  PushdownAutomaton convertCFGToPDA(ContextFreeGrammar cfg) {
    return CFGToPDAConverter.convert(cfg);
  }

  /// Convert PDA to CFG
  ContextFreeGrammar convertPDAToCFG(PushdownAutomaton pda) {
    return PDAToCFGConverter.convert(pda);
  }

  /// Check if automaton is empty
  bool isEmpty(FiniteAutomaton fa) {
    return PropertyChecker.isEmpty(fa);
  }

  /// Check if automaton is universal
  bool isUniversal(FiniteAutomaton fa) {
    return PropertyChecker.isUniversal(fa);
  }

  /// Check if automaton is finite
  bool isFinite(FiniteAutomaton fa) {
    return PropertyChecker.isFinite(fa);
  }

  /// Check if two automata are equivalent
  bool areEquivalent(FiniteAutomaton fa1, FiniteAutomaton fa2) {
    return PropertyChecker.areEquivalent(fa1, fa2);
  }

  /// Check if one automaton is subset of another
  bool isSubset(FiniteAutomaton fa1, FiniteAutomaton fa2) {
    return PropertyChecker.isSubset(fa1, fa2);
  }

  /// Simulate automaton on input
  bool simulate(FiniteAutomaton fa, String input) {
    return PropertyChecker.acceptsString(fa, input);
  }
}

/// File operations
class FileOperations {
  final AutomatonRepository _repository = AutomatonRepository();

  /// Import automaton from JSON
  Future<FiniteAutomaton> importFromJSON(String filePath) async {
    return await _repository.importFromJSON(filePath);
  }

  /// Export automaton to JSON
  Future<void> exportToJSON(FiniteAutomaton automaton, String filePath) async {
    await _repository.exportToJSON(automaton, filePath);
  }

  /// Import automaton from JFLAP
  Future<FiniteAutomaton> importFromJFLAP(String filePath) async {
    return await _repository.importFromJFLAP(filePath);
  }

  /// Export automaton to JFLAP
  Future<void> exportToJFLAP(FiniteAutomaton automaton, String filePath) async {
    await _repository.exportToJFLAP(automaton, filePath);
  }

  /// Import PDA from JSON
  Future<PushdownAutomaton> importPDAFromJSON(String filePath) async {
    return await _repository.importPDAFromJSON(filePath);
  }

  /// Export PDA to JSON
  Future<void> exportPDAToJSON(PushdownAutomaton automaton, String filePath) async {
    await _repository.exportPDAToJSON(automaton, filePath);
  }

  /// Import TM from JSON
  Future<TuringMachine> importTMFromJSON(String filePath) async {
    return await _repository.importTMFromJSON(filePath);
  }

  /// Export TM to JSON
  Future<void> exportTMToJSON(TuringMachine automaton, String filePath) async {
    await _repository.exportTMToJSON(automaton, filePath);
  }

  /// Import CFG from JSON
  Future<ContextFreeGrammar> importCFGFromJSON(String filePath) async {
    return await _repository.importCFGFromJSON(filePath);
  }

  /// Export CFG to JSON
  Future<void> exportCFGToJSON(ContextFreeGrammar grammar, String filePath) async {
    await _repository.exportCFGToJSON(grammar, filePath);
  }

  /// Import regex from JSON
  Future<RegularExpression> importRegexFromJSON(String filePath) async {
    return await _repository.importRegexFromJSON(filePath);
  }

  /// Export regex to JSON
  Future<void> exportRegexToJSON(RegularExpression regex, String filePath) async {
    await _repository.exportRegexToJSON(regex, filePath);
  }
}

/// Visualization state
class VisualizationState {
  final bool isPlaying;
  final int currentStep;
  final List<VisualizationStep> steps;
  final String? currentAlgorithm;
  final bool isPaused;

  const VisualizationState({
    this.isPlaying = false,
    this.currentStep = 0,
    this.steps = const [],
    this.currentAlgorithm,
    this.isPaused = false,
  });

  VisualizationState copyWith({
    bool? isPlaying,
    int? currentStep,
    List<VisualizationStep>? steps,
    String? currentAlgorithm,
    bool? isPaused,
  }) {
    return VisualizationState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentStep: currentStep ?? this.currentStep,
      steps: steps ?? this.steps,
      currentAlgorithm: currentAlgorithm ?? this.currentAlgorithm,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

/// Visualization notifier
class VisualizationNotifier extends StateNotifier<VisualizationState> {
  VisualizationNotifier() : super(const VisualizationState());

  /// Start visualization
  void startVisualization(List<VisualizationStep> steps, String algorithm) {
    state = state.copyWith(
      steps: steps,
      currentAlgorithm: algorithm,
      isPlaying: true,
      currentStep: 0,
      isPaused: false,
    );
  }

  /// Pause visualization
  void pauseVisualization() {
    state = state.copyWith(
      isPlaying: false,
      isPaused: true,
    );
  }

  /// Resume visualization
  void resumeVisualization() {
    state = state.copyWith(
      isPlaying: true,
      isPaused: false,
    );
  }

  /// Stop visualization
  void stopVisualization() {
    state = state.copyWith(
      isPlaying: false,
      currentStep: 0,
      isPaused: false,
    );
  }

  /// Next step
  void nextStep() {
    if (state.currentStep < state.steps.length - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Previous step
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Go to specific step
  void goToStep(int step) {
    if (step >= 0 && step < state.steps.length) {
      state = state.copyWith(currentStep: step);
    }
  }
}

/// Algorithm state
class AlgorithmState {
  final bool isRunning;
  final String? currentAlgorithm;
  final double progress;
  final String? result;
  final String? error;

  const AlgorithmState({
    this.isRunning = false,
    this.currentAlgorithm,
    this.progress = 0.0,
    this.result,
    this.error,
  });

  AlgorithmState copyWith({
    bool? isRunning,
    String? currentAlgorithm,
    double? progress,
    String? result,
    String? error,
  }) {
    return AlgorithmState(
      isRunning: isRunning ?? this.isRunning,
      currentAlgorithm: currentAlgorithm ?? this.currentAlgorithm,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

/// Algorithm notifier
class AlgorithmNotifier extends StateNotifier<AlgorithmState> {
  AlgorithmNotifier() : super(const AlgorithmState());

  /// Start algorithm
  void startAlgorithm(String algorithm) {
    state = state.copyWith(
      isRunning: true,
      currentAlgorithm: algorithm,
      progress: 0.0,
      error: null,
    );
  }

  /// Update progress
  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  /// Complete algorithm
  void completeAlgorithm(String result) {
    state = state.copyWith(
      isRunning: false,
      progress: 1.0,
      result: result,
    );
  }

  /// Set error
  void setError(String error) {
    state = state.copyWith(
      isRunning: false,
      error: error,
    );
  }

  /// Clear state
  void clear() {
    state = const AlgorithmState();
  }
}

/// Visualization step (imported from viz package)
class VisualizationStep {
  final int stepNumber;
  final String title;
  final String description;
  final FiniteAutomaton? automaton;
  final List<String> highlights;
  final List<String> annotations;

  const VisualizationStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.automaton,
    required this.highlights,
    required this.annotations,
  });
}