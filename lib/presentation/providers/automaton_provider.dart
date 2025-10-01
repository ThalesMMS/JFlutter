import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';
import '../../core/algorithms/automaton_simulator.dart';
import '../../core/algorithms/dfa_completer.dart';
import '../../core/algorithms/dfa_minimizer.dart';
import '../../core/algorithms/equivalence_checker.dart';
import '../../core/algorithms/fa_to_regex_converter.dart';
import '../../core/algorithms/fsa_to_grammar_converter.dart';
import '../../core/algorithms/nfa_to_dfa_converter.dart';
import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/state.dart';
import '../../core/models/grammar.dart';
import '../../core/models/simulation_result.dart' as sim_result;
import '../../core/entities/automaton_entity.dart';
import '../../data/services/automaton_service.dart';
import '../../core/repositories/automaton_repository.dart';
import '../../features/layout/layout_repository_impl.dart';
import '../../core/services/trace_persistence_service.dart';

/// Provider for automaton state management
class AutomatonProvider extends StateNotifier<AutomatonState> {
  final AutomatonService _automatonService;
  final LayoutRepository _layoutRepository;
  final TracePersistenceService? _tracePersistenceService;

  AutomatonProvider({
    required AutomatonService automatonService,
    required LayoutRepository layoutRepository,
    TracePersistenceService? tracePersistenceService,
  }) : _automatonService = automatonService,
       _layoutRepository = layoutRepository,
       _tracePersistenceService = tracePersistenceService,
       super(const AutomatonState());

  /// Creates a new automaton
  Future<void> createAutomaton({
    required String name,
    String? description,
    required List<String> alphabet,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Create a simple automaton with one state
      final result = _automatonService.createAutomaton(
        CreateAutomatonRequest(
          name: name,
          description: description,
          states: const [
            StateData(
              id: 'q0',
              name: 'q0',
              position: Point(100, 100),
              isInitial: true,
              isAccepting: false,
            ),
          ],
          transitions: const [],
          alphabet: alphabet,
          bounds: const Rect(0, 0, 400, 300),
        ),
      );

      if (result.isSuccess) {
        state = state.copyWith(currentAutomaton: result.data, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error creating automaton: $e',
      );
    }
  }

  /// Updates the current automaton
  void updateAutomaton(FSA automaton) {
    state = state.copyWith(
      currentAutomaton: automaton,
      equivalenceResult: null,
      equivalenceDetails: null,
    );
  }

  /// Simulates the current automaton with input string
  Future<void> simulateAutomaton(String inputString) async {
    if (state.currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      // Use the core algorithm directly
      final result = await AutomatonSimulator.simulate(
        state.currentAutomaton!,
        inputString,
        stepByStep: true,
        timeout: const Duration(seconds: 5),
      );

      if (result.isSuccess) {
        _addSimulationToHistory(result.data!);
        state = state.copyWith(simulationResult: result.data, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error simulating automaton: $e',
      );
    }
  }

  /// Converts NFA to DFA
  Future<void> convertNfaToDfa() async {
    if (state.currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      // Use the core algorithm directly
      final result = NFAToDFAConverter.convert(state.currentAutomaton!);

      if (result.isSuccess) {
        state = state.copyWith(
          currentAutomaton: result.data,
          isLoading: false,
          simulationResult: null,
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting NFA to DFA: $e',
      );
    }
  }

  /// Minimizes DFA
  Future<void> minimizeDfa() async {
    if (state.currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      // Use the core algorithm directly
      final result = DFAMinimizer.minimize(state.currentAutomaton!);

      if (result.isSuccess) {
        state = state.copyWith(
          currentAutomaton: result.data,
          isLoading: false,
          simulationResult: null,
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error minimizing DFA: $e',
      );
    }
  }

  /// Completes DFA
  Future<void> completeDfa() async {
    if (state.currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final result = DFACompleter.complete(state.currentAutomaton!);
      state = state.copyWith(
        currentAutomaton: result,
        isLoading: false,
        simulationResult: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error completing DFA: $e',
      );
    }
  }

  /// Converts FSA to Grammar
  Future<Grammar?> convertFsaToGrammar() async {
    if (state.currentAutomaton == null) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = FSAToGrammarConverter.convert(state.currentAutomaton!);
      state = state.copyWith(isLoading: false, grammarResult: result);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting FSA to Grammar: $e',
      );
      return null;
    }
  }

  /// Applies auto layout
  Future<void> applyAutoLayout() async {
    if (state.currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      // Convert FSA to AutomatonEntity for layout repository
      final automatonEntity = _convertFsaToEntity(state.currentAutomaton!);
      final result = await _layoutRepository.applyAutoLayout(automatonEntity);

      if (result.isSuccess) {
        // Convert back to FSA
        final updatedFsa = _convertEntityToFsa(result.data!);
        state = state.copyWith(
          currentAutomaton: updatedFsa,
          isLoading: false,
          simulationResult: null,
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error applying auto layout: $e',
      );
    }
  }

  /// Returns the current automaton as a domain entity when available.
  AutomatonEntity? get currentAutomatonEntity {
    final current = state.currentAutomaton;
    if (current == null) return null;
    return _convertFsaToEntity(current);
  }

  /// Converts the provided FSA to its [AutomatonEntity] representation.
  AutomatonEntity convertFsaToEntity(FSA automaton) {
    return _convertFsaToEntity(automaton);
  }

  /// Converts the provided [AutomatonEntity] back to an [FSA].
  FSA convertEntityToFsa(AutomatonEntity entity) {
    return _convertEntityToFsa(entity);
  }

  /// Replaces the current automaton with the one represented by [entity].
  void replaceCurrentAutomaton(AutomatonEntity entity) {
    final updated = _convertEntityToFsa(entity);
    state = state.copyWith(
      currentAutomaton: updated,
      simulationResult: null,
      regexResult: null,
      grammarResult: null,
      equivalenceResult: null,
      equivalenceDetails: null,
      error: null,
      isLoading: false,
    );
  }

  /// Converts regex to NFA
  Future<void> convertRegexToNfa(String regex) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      // Use the core algorithm directly
      final result = RegexToNFAConverter.convert(regex);

      if (result.isSuccess) {
        state = state.copyWith(
          currentAutomaton: result.data,
          isLoading: false,
          simulationResult: null,
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting regex to NFA: $e',
      );
    }
  }

  /// Converts FA to regex
  Future<String?> convertFaToRegex() async {
    if (state.currentAutomaton == null) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use the core algorithm directly
      final result = FAToRegexConverter.convert(state.currentAutomaton!);

      if (result.isSuccess) {
        // Store the regex result in state
        state = state.copyWith(regexResult: result.data, isLoading: false);
        return result.data;
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting FA to regex: $e',
      );
      return null;
    }
  }

  /// Compares the current automaton with another automaton for equivalence
  Future<bool?> compareEquivalence(FSA other) async {
    if (state.currentAutomaton == null) return null;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final areEquivalent = EquivalenceChecker.areEquivalent(
        state.currentAutomaton!,
        other,
      );
      state = state.copyWith(
        isLoading: false,
        equivalenceResult: areEquivalent,
        equivalenceDetails: areEquivalent
            ? 'The automata accept the same language.'
            : 'A distinguishing string was found between the automata.',
      );
      return areEquivalent;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        equivalenceResult: null,
        equivalenceDetails: 'Error comparing automata: $e',
        error: 'Error comparing automata: $e',
      );
      return null;
    }
  }

  /// Clears the current automaton
  void clearAutomaton() {
    state = state.copyWith(
      currentAutomaton: null,
      simulationResult: null,
      regexResult: null,
      grammarResult: null,
      equivalenceResult: null,
      equivalenceDetails: null,
      error: null,
    );
  }

  /// Clears any error messages
  void clearError() {
    state = state.clearError();
  }

  /// Clear all state and reset to initial
  void clearAll() {
    state = state.clear();
  }

  /// Clear simulation results
  void clearSimulation() {
    state = state.clearSimulation();
  }

  /// Clear algorithm results
  void clearAlgorithmResults() {
    state = state.clearAlgorithmResults();
  }

  /// Add simulation result to history
  void _addSimulationToHistory(sim_result.SimulationResult result) {
    final newHistory = [...state.simulationHistory, result];
    state = state.copyWith(simulationHistory: newHistory);

    // Also save to trace persistence service if available
    _tracePersistenceService?.saveTrace(result).catchError((error) {
      // Silently fail - trace persistence is a nice-to-have feature
      debugPrint('Failed to persist simulation trace: $error');
    });
  }

  /// Get automaton from history
  FSA? getAutomatonFromHistory(int index) {
    if (index < 0 || index >= state.automatonHistory.length) return null;
    return state.automatonHistory[index];
  }

  /// Get simulation result from history
  sim_result.SimulationResult? getSimulationFromHistory(int index) {
    if (index < 0 || index >= state.simulationHistory.length) return null;
    return state.simulationHistory[index];
  }

  /// Converts FSA to AutomatonEntity
  AutomatonEntity _convertFsaToEntity(FSA fsa) {
    final states = fsa.states
        .map(
          (s) => StateEntity(
            id: s.id,
            name: s.label,
            x: s.position.x,
            y: s.position.y,
            isInitial: s.isInitial,
            isFinal: s.isAccepting,
          ),
        )
        .toList();

    // Build transitions map from FSA transitions
    final transitions = <String, List<String>>{};
    for (final transition in fsa.transitions) {
      if (transition is FSATransition) {
        for (final symbol in transition.inputSymbols) {
          final key = '${transition.fromState.id}|$symbol';
          if (!transitions.containsKey(key)) {
            transitions[key] = [];
          }
          transitions[key]!.add(transition.toState.id);
        }
      }
    }

    return AutomatonEntity(
      id: fsa.id,
      name: fsa.name,
      alphabet: fsa.alphabet,
      states: states,
      transitions: transitions,
      initialId: fsa.initialState?.id,
      nextId: states.length + 1,
      type: AutomatonType.dfa, // Default to DFA
    );
  }

  /// Converts AutomatonEntity to FSA
  FSA _convertEntityToFsa(AutomatonEntity entity) {
    final states = entity.states
        .map(
          (s) => State(
            id: s.id,
            label: s.name,
            position: Vector2(s.x, s.y),
            isInitial: s.isInitial,
            isAccepting: s.isFinal,
          ),
        )
        .toSet();

    final initialState = states.where((s) => s.isInitial).firstOrNull;
    final acceptingStates = states.where((s) => s.isAccepting).toSet();

    // Build FSA transitions from transitions map
    final transitions = <FSATransition>{};
    int transitionId = 1;

    for (final entry in entity.transitions.entries) {
      final parts = entry.key.split('|');
      if (parts.length == 2) {
        final fromStateId = parts[0];
        final symbol = parts[1];
        final fromState = states.firstWhere((s) => s.id == fromStateId);

        for (final toStateId in entry.value) {
          final toState = states.firstWhere((s) => s.id == toStateId);
          transitions.add(
            FSATransition(
              id: 't${transitionId++}',
              fromState: fromState,
              toState: toState,
              label: symbol,
              inputSymbols: {symbol},
            ),
          );
        }
      }
    }

    return FSA(
      id: entity.id,
      name: entity.name,
      states: states,
      transitions: transitions,
      alphabet: entity.alphabet,
      initialState: initialState,
      acceptingStates: acceptingStates,
      created: DateTime.now(),
      modified: DateTime.now(),
      bounds: const Rectangle(0, 0, 800, 600),
    );
  }
}

/// State class for automaton provider
class AutomatonState {
  final FSA? currentAutomaton;
  final sim_result.SimulationResult? simulationResult;
  final String? regexResult;
  final Grammar? grammarResult;
  final bool? equivalenceResult;
  final String? equivalenceDetails;
  final bool isLoading;
  final String? error;
  final List<FSA> automatonHistory; // persistent history of automatons
  final List<sim_result.SimulationResult>
  simulationHistory; // persistent simulation history

  const AutomatonState({
    this.currentAutomaton,
    this.simulationResult,
    this.regexResult,
    this.grammarResult,
    this.equivalenceResult,
    this.equivalenceDetails,
    this.isLoading = false,
    this.error,
    this.automatonHistory = const [],
    this.simulationHistory = const [],
  });

  static const _unset = Object();

  AutomatonState copyWith({
    Object? currentAutomaton = _unset,
    Object? simulationResult = _unset,
    Object? regexResult = _unset,
    Object? grammarResult = _unset,
    Object? equivalenceResult = _unset,
    Object? equivalenceDetails = _unset,
    bool? isLoading,
    Object? error = _unset,
    List<FSA>? automatonHistory,
    List<sim_result.SimulationResult>? simulationHistory,
  }) {
    return AutomatonState(
      currentAutomaton: currentAutomaton == _unset
          ? this.currentAutomaton
          : currentAutomaton as FSA?,
      simulationResult: simulationResult == _unset
          ? this.simulationResult
          : simulationResult as sim_result.SimulationResult?,
      regexResult: regexResult == _unset
          ? this.regexResult
          : regexResult as String?,
      grammarResult: grammarResult == _unset
          ? this.grammarResult
          : grammarResult as Grammar?,
      equivalenceResult: equivalenceResult == _unset
          ? this.equivalenceResult
          : equivalenceResult as bool?,
      equivalenceDetails: equivalenceDetails == _unset
          ? this.equivalenceDetails
          : equivalenceDetails as String?,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
      automatonHistory: automatonHistory ?? this.automatonHistory,
      simulationHistory: simulationHistory ?? this.simulationHistory,
    );
  }

  /// Clear all state and reset to initial
  AutomatonState clear() {
    return const AutomatonState();
  }

  /// Clear only error state
  AutomatonState clearError() {
    return copyWith(error: null);
  }

  /// Clear simulation results
  AutomatonState clearSimulation() {
    return copyWith(simulationResult: null, simulationHistory: []);
  }

  /// Clear algorithm results
  AutomatonState clearAlgorithmResults() {
    return copyWith(
      regexResult: null,
      grammarResult: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );
  }
}

/// Provider instances
final automatonProvider =
    StateNotifierProvider<AutomatonProvider, AutomatonState>((ref) {
      final automatonService = AutomatonService();

      return AutomatonProvider(
        automatonService: automatonService,
        layoutRepository: LayoutRepositoryImpl(),
      );
    });
