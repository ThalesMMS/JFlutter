import 'dart:math';
import 'package:collection/collection.dart';
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
import '../../core/models/transition.dart';
import '../../core/models/grammar.dart';
import '../../core/models/simulation_result.dart' as sim_result;
import '../../core/entities/automaton_entity.dart';
import '../../data/services/automaton_service.dart';
import '../../core/repositories/automaton_repository.dart';
import '../../core/services/trace_persistence_service.dart';
import '../../features/layout/layout_repository_impl.dart';
import '../../features/canvas/graphview/graphview_canvas_controller.dart';

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

  /// Adds a new state or updates an existing one using coordinates supplied by
  /// the GraphView canvas controllers.
  void addState({
    required String id,
    required String label,
    required double x,
    required double y,
    bool? isInitial,
    bool? isAccepting,
  }) {
    _mutateAutomaton((current) {
      final List<State> updatedStates = [];
      bool found = false;

      for (final state in current.states) {
        if (state.id == id) {
          updatedStates.add(
            state.copyWith(
              label: label,
              position: Vector2(x, y),
              isInitial: isInitial ?? state.isInitial,
              isAccepting: isAccepting ?? state.isAccepting,
            ),
          );
          found = true;
        } else {
          updatedStates.add(state);
        }
      }

      if (!found) {
        updatedStates.add(
          State(
            id: id,
            label: label,
            position: Vector2(x, y),
            isInitial: isInitial ?? current.states.isEmpty,
            isAccepting: isAccepting ?? false,
          ),
        );
      }

      List<State> normalizedStates = updatedStates;
      if (isInitial == true) {
        normalizedStates = updatedStates
            .map(
              (state) => state.id == id
                  ? state.copyWith(isInitial: true)
                  : state.copyWith(isInitial: false),
            )
            .toList();
      } else if (isInitial == false) {
        normalizedStates = updatedStates
            .map(
              (state) =>
                  state.id == id ? state.copyWith(isInitial: false) : state,
            )
            .toList();
      }

      final statesById = {
        for (final state in normalizedStates) state.id: state,
      };
      final updatedTransitions = _rebindTransitions(
        current.transitions.whereType<FSATransition>(),
        statesById,
      );

      final initialStateId = isInitial == true
          ? id
          : current.initialState?.id ??
                normalizedStates
                    .firstWhereOrNull((state) => state.isInitial)
                    ?.id;
      final initialState = initialStateId != null
          ? statesById[initialStateId]
          : null;

      final acceptingStates = statesById.values
          .where((state) => state.isAccepting)
          .toSet();

      return current.copyWith(
        states: statesById.values.toSet(),
        transitions: updatedTransitions.map<Transition>((t) => t).toSet(),
        initialState: initialState,
        acceptingStates: acceptingStates,
        modified: DateTime.now(),
      );
    });
  }

  /// Moves a state to a new position on the canvas.
  void moveState({required String id, required double x, required double y}) {
    _mutateAutomaton((current) {
      final updatedStates = current.states
          .map(
            (state) => state.id == id
                ? state.copyWith(position: Vector2(x, y))
                : state,
          )
          .toList();
      final statesById = {for (final state in updatedStates) state.id: state};
      final updatedTransitions = _rebindTransitions(
        current.transitions.whereType<FSATransition>(),
        statesById,
      );

      final initialStateId = current.initialState?.id;
      final acceptingStates = statesById.values
          .where((state) => state.isAccepting)
          .toSet();

      return current.copyWith(
        states: statesById.values.toSet(),
        transitions: updatedTransitions.map<Transition>((t) => t).toSet(),
        initialState: initialStateId != null
            ? statesById[initialStateId]
            : null,
        acceptingStates: acceptingStates,
        modified: DateTime.now(),
      );
    });
  }

  /// Removes the state identified by [id] along with connected transitions.
  void removeState({required String id}) {
    _mutateAutomaton((current) {
      if (current.states.every((state) => state.id != id)) {
        return current;
      }

      final remainingStates = current.states
          .where((state) => state.id != id)
          .toList(growable: false);

      if (remainingStates.isEmpty) {
        return current.copyWith(
          states: <State>{},
          transitions: <Transition>{},
          initialState: null,
          acceptingStates: <State>{},
          modified: DateTime.now(),
        );
      }

      final initialCandidate = remainingStates.firstWhereOrNull(
        (state) => state.id == current.initialState?.id,
      );
      final resolvedInitial = initialCandidate ?? remainingStates.first;

      final normalizedStates = remainingStates
          .map(
            (state) => state.copyWith(
              isInitial: state.id == resolvedInitial.id,
              isAccepting: current.acceptingStates.any(
                (accepting) => accepting.id == state.id,
              ),
            ),
          )
          .toList();

      State? updatedInitial = normalizedStates.firstWhereOrNull(
        (state) => state.isInitial,
      );
      if (updatedInitial == null && normalizedStates.isNotEmpty) {
        final fallback = normalizedStates.first.copyWith(isInitial: true);
        normalizedStates[0] = fallback;
        updatedInitial = fallback;
      }

      final statesById = {
        for (final state in normalizedStates) state.id: state,
      };
      final filteredTransitions = current.transitions
          .whereType<FSATransition>()
          .where(
            (transition) =>
                transition.fromState.id != id && transition.toState.id != id,
          )
          .toList();

      final reboundTransitions = _rebindTransitions(
        filteredTransitions,
        statesById,
      );
      final acceptingStates = statesById.values
          .where((state) => state.isAccepting)
          .toSet();

      return current.copyWith(
        states: statesById.values.toSet(),
        transitions: reboundTransitions.map<Transition>((t) => t).toSet(),
        initialState: updatedInitial,
        acceptingStates: acceptingStates,
        modified: DateTime.now(),
      );
    });
  }

  /// Adds or updates a transition in the automaton.
  void addOrUpdateTransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    required String label,
    double? controlPointX,
    double? controlPointY,
  }) {
    _mutateAutomaton((current) {
      final statesById = {for (final state in current.states) state.id: state};
      final fromState = statesById[fromStateId];
      final toState = statesById[toStateId];
      if (fromState == null || toState == null) {
        return current;
      }

      final parsedLabel = _parseTransitionLabel(label);
      final transitions = current.transitions
          .whereType<FSATransition>()
          .toList();
      final existingIndex = transitions.indexWhere(
        (transition) => transition.id == id,
      );

      final controlPoint = controlPointX != null && controlPointY != null
          ? Vector2(controlPointX, controlPointY)
          : null;

      if (existingIndex >= 0) {
        final existing = transitions[existingIndex];
        transitions[existingIndex] = existing.copyWith(
          fromState: fromState,
          toState: toState,
          label: label,
          controlPoint: controlPoint ?? existing.controlPoint,
          inputSymbols: parsedLabel.symbols,
          lambdaSymbol: parsedLabel.lambdaSymbol,
        );
      } else {
        transitions.add(
          FSATransition(
            id: id,
            fromState: fromState,
            toState: toState,
            label: label,
            controlPoint: controlPoint,
            inputSymbols: parsedLabel.symbols,
            lambdaSymbol: parsedLabel.lambdaSymbol,
          ),
        );
      }

      final updatedAlphabet = _mergeAlphabet(
        current.alphabet,
        parsedLabel.symbols,
      );

      return current.copyWith(
        transitions: transitions.map<Transition>((t) => t).toSet(),
        alphabet: updatedAlphabet,
        modified: DateTime.now(),
      );
    });
  }

  /// Removes the transition identified by [id] from the automaton.
  void removeTransition({required String id}) {
    _mutateAutomaton((current) {
      final transitions = current.transitions
          .whereType<FSATransition>()
          .toList();
      final index = transitions.indexWhere((transition) => transition.id == id);
      if (index < 0) {
        return current;
      }

      transitions.removeAt(index);

      return current.copyWith(
        transitions: transitions.map<Transition>((t) => t).toSet(),
        modified: DateTime.now(),
      );
    });
  }

  /// Updates the label of an existing state.
  void updateStateLabel({required String id, required String label}) {
    _mutateAutomaton((current) {
      final updatedStates = current.states
          .map((state) => state.id == id ? state.copyWith(label: label) : state)
          .toList();
      final statesById = {for (final state in updatedStates) state.id: state};
      final updatedTransitions = _rebindTransitions(
        current.transitions.whereType<FSATransition>(),
        statesById,
      );

      final initialStateId = current.initialState?.id;
      final acceptingStates = statesById.values
          .where((state) => state.isAccepting)
          .toSet();

      return current.copyWith(
        states: statesById.values.toSet(),
        transitions: updatedTransitions.map<Transition>((t) => t).toSet(),
        initialState: initialStateId != null
            ? statesById[initialStateId]
            : null,
        acceptingStates: acceptingStates,
        modified: DateTime.now(),
      );
    });
  }

  /// Updates the flag metadata for the state matching [id].
  void updateStateFlags({
    required String id,
    bool? isInitial,
    bool? isAccepting,
  }) {
    if (isInitial == null && isAccepting == null) {
      return;
    }

    _mutateAutomaton((current) {
      if (current.states.every((state) => state.id != id)) {
        return current;
      }

      final updatedStates = current.states.map((state) {
        var newInitial = state.isInitial;
        var newAccepting = state.isAccepting;

        if (state.id == id) {
          newInitial = isInitial ?? state.isInitial;
          newAccepting = isAccepting ?? state.isAccepting;
        } else if (isInitial == true) {
          newInitial = false;
        }

        return state.copyWith(isInitial: newInitial, isAccepting: newAccepting);
      }).toList();

      if (!updatedStates.any((state) => state.isInitial) &&
          updatedStates.isNotEmpty) {
        updatedStates[0] = updatedStates[0].copyWith(isInitial: true);
      }

      final statesById = {for (final state in updatedStates) state.id: state};
      final updatedTransitions = _rebindTransitions(
        current.transitions.whereType<FSATransition>(),
        statesById,
      );

      final initialState = updatedStates.firstWhereOrNull(
        (state) => state.isInitial,
      );
      final acceptingStates = statesById.values
          .where((state) => state.isAccepting)
          .toSet();

      return current.copyWith(
        states: statesById.values.toSet(),
        transitions: updatedTransitions.map<Transition>((t) => t).toSet(),
        initialState: initialState,
        acceptingStates: acceptingStates,
        modified: DateTime.now(),
      );
    });
  }

  /// Updates the label (and symbol set) of an existing transition.
  void updateTransitionLabel({required String id, required String label}) {
    _mutateAutomaton((current) {
      final transitions = current.transitions
          .whereType<FSATransition>()
          .toList();
      final index = transitions.indexWhere((transition) => transition.id == id);
      if (index < 0) {
        return current;
      }

      final parsedLabel = _parseTransitionLabel(label);
      final existing = transitions[index];
      transitions[index] = existing.copyWith(
        label: label,
        inputSymbols: parsedLabel.symbols,
        lambdaSymbol: parsedLabel.lambdaSymbol,
      );

      final updatedAlphabet = _mergeAlphabet(
        current.alphabet,
        parsedLabel.symbols,
      );

      return current.copyWith(
        transitions: transitions.map<Transition>((t) => t).toSet(),
        alphabet: updatedAlphabet,
        modified: DateTime.now(),
      );
    });
  }

  void _mutateAutomaton(FSA Function(FSA current) transform) {
    final current = state.currentAutomaton ?? _createEmptyAutomaton();
    final updated = transform(current);
    if (identical(updated, state.currentAutomaton)) {
      return;
    }

    state = state.copyWith(
      currentAutomaton: updated,
      simulationResult: null,
      regexResult: null,
      grammarResult: null,
      equivalenceResult: null,
      equivalenceDetails: null,
      error: null,
    );
  }

  Set<FSATransition> _rebindTransitions(
    Iterable<FSATransition> transitions,
    Map<String, State> statesById,
  ) {
    return transitions
        .map(
          (transition) => transition.copyWith(
            fromState:
                statesById[transition.fromState.id] ?? transition.fromState,
            toState: statesById[transition.toState.id] ?? transition.toState,
          ),
        )
        .toSet();
  }

  ({Set<String> symbols, String? lambdaSymbol}) _parseTransitionLabel(
    String label,
  ) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      return (symbols: <String>{}, lambdaSymbol: null);
    }

    final normalized = trimmed.replaceAll(RegExp(r'\s+'), '');
    final lower = normalized.toLowerCase();
    if (lower == 'ε' || lower == 'lambda' || lower == 'λ') {
      return (symbols: <String>{}, lambdaSymbol: 'ε');
    }

    final parts = normalized
        .split(',')
        .map((symbol) => symbol.trim())
        .where((symbol) => symbol.isNotEmpty)
        .toSet();
    return (symbols: parts, lambdaSymbol: null);
  }

  Set<String> _mergeAlphabet(Set<String> alphabet, Set<String> additions) {
    final filtered = additions
        .map((symbol) => symbol.trim())
        .where(
          (symbol) =>
              symbol.isNotEmpty &&
              symbol != 'ε' &&
              symbol != 'λ' &&
              symbol.toLowerCase() != 'lambda',
        )
        .toSet();
    return {...alphabet, ...filtered};
  }

  FSA _createEmptyAutomaton() {
    final now = DateTime.now();
    return FSA(
      id: 'automaton_${now.microsecondsSinceEpoch}',
      name: 'Untitled Automaton',
      states: <State>{},
      transitions: <Transition>{},
      alphabet: <String>{},
      initialState: null,
      acceptingStates: <State>{},
      created: now,
      modified: now,
      bounds: const Rectangle<double>(0, 0, 800, 600),
      panOffset: Vector2.zero(),
      zoomLevel: 1.0,
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

/// Provides a lazily constructed GraphView canvas controller for automata.
final graphViewCanvasControllerProvider = Provider<GraphViewCanvasController>((
  ref,
) {
  final automatonNotifier = ref.read(automatonProvider.notifier);
  final controller = GraphViewCanvasController(
    automatonProvider: automatonNotifier,
  );
  ref.onDispose(controller.dispose);
  controller.synchronize(automatonNotifier.state.currentAutomaton);
  return controller;
});
