//
//  automaton_provider.dart
//  JFlutter
//
//  Centraliza a gestão reativa dos autômatos exibidos no editor visual,
//  integrando serviços de domínio, algoritmos e persistência para manter
//  estados, transições, layouts e indicadores de carregamento coerentes com as
//  interações do usuário, incluindo operações de simulação e conversão.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
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
import '../../core/utils/epsilon_utils.dart';
import '../../core/constants/automaton_canvas.dart';
import '../../core/models/grammar.dart';
import '../../core/models/simulation_result.dart' as sim_result;
import '../../core/entities/automaton_entity.dart';
import '../../data/services/automaton_service.dart';
import '../../core/repositories/automaton_repository.dart';
import '../../core/services/trace_persistence_service.dart';
import '../../features/layout/layout_repository_impl.dart';
import '../../features/canvas/graphview/graphview_canvas_controller.dart';
import 'automaton_state_provider.dart';

part 'automaton_provider_helpers.dart';
part 'automaton_provider_state.dart';
part 'automaton_provider_history.dart';

/// Provider for automaton state management
@Deprecated(
  'Use automatonStateProvider, automatonLayoutProvider, and the GraphView canvas '
  'controllers for new code. Migrate state reads from AutomatonState to the '
  'newer focused notifiers before removing this legacy StateNotifier.',
)
class AutomatonProvider extends StateNotifier<AutomatonState> {
  final AutomatonService _automatonService;
  final LayoutRepository _layoutRepository;
  final TracePersistenceService? _tracePersistenceService;
  int _graphViewMutationCounter = 0;

  AutomatonProvider({
    required AutomatonService automatonService,
    required LayoutRepository layoutRepository,
    TracePersistenceService? tracePersistenceService,
  })  : _automatonService = automatonService,
        _layoutRepository = layoutRepository,
        _tracePersistenceService = tracePersistenceService,
        super(const AutomatonState());

  void _traceGraphView(String operation, [Map<String, Object?>? metadata]) {
    if (!kDebugMode) {
      return;
    }

    final buffer = StringBuffer('[AutomatonProvider] $operation');
    if (metadata != null && metadata.isNotEmpty) {
      final formatted = metadata.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join(', ');
      buffer.write(' {$formatted}');
    }

    debugPrint(buffer.toString());
  }

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
    _traceGraphView('addState', {
      'id': id,
      'label': label,
      'x': x.toStringAsFixed(2),
      'y': y.toStringAsFixed(2),
      'initial': isInitial,
      'accepting': isAccepting,
    });
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
              normalizedStates.firstWhereOrNull((state) => state.isInitial)?.id;
      final initialState =
          initialStateId != null ? statesById[initialStateId] : null;

      final acceptingStates =
          statesById.values.where((state) => state.isAccepting).toSet();

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
    _traceGraphView('moveState', {
      'id': id,
      'x': x.toStringAsFixed(2),
      'y': y.toStringAsFixed(2),
    });
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
      final acceptingStates =
          statesById.values.where((state) => state.isAccepting).toSet();

      return current.copyWith(
        states: statesById.values.toSet(),
        transitions: updatedTransitions.map<Transition>((t) => t).toSet(),
        initialState:
            initialStateId != null ? statesById[initialStateId] : null,
        acceptingStates: acceptingStates,
        modified: DateTime.now(),
      );
    });
  }

  /// Removes the state identified by [id] along with connected transitions.
  void removeState({required String id}) {
    _traceGraphView('removeState', {'id': id});
    _mutateAutomaton((current) {
      if (current.states.every((state) => state.id != id)) {
        _traceGraphView('removeState skipped', {
          'id': id,
          'reason': 'not-found',
        });
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
      final acceptingStates =
          statesById.values.where((state) => state.isAccepting).toSet();

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
    _traceGraphView('addOrUpdateTransition', {
      'id': id,
      'from': fromStateId,
      'to': toStateId,
      'label': label,
      'cpX': controlPointX?.toStringAsFixed(2),
      'cpY': controlPointY?.toStringAsFixed(2),
    });
    _mutateAutomaton((current) {
      final statesById = {for (final state in current.states) state.id: state};
      final fromState = statesById[fromStateId];
      final toState = statesById[toStateId];
      if (fromState == null || toState == null) {
        _traceGraphView('addOrUpdateTransition skipped', {
          'id': id,
          'missingFrom': fromState == null,
          'missingTo': toState == null,
        });
        return current;
      }

      final parsedLabel = _parseTransitionLabel(label);
      final resolvedLabel = _formatTransitionLabel(label, parsedLabel);
      final transitions =
          current.transitions.whereType<FSATransition>().toList();
      final existingIndex = transitions.indexWhere(
        (transition) => transition.id == id,
      );

      Vector2? controlPoint;
      if (controlPointX != null && controlPointY != null) {
        controlPoint = Vector2(controlPointX, controlPointY);
      }

      final isSelfLoop = fromState.id == toState.id;
      if (controlPoint == null && isSelfLoop) {
        controlPoint = _defaultLoopControlPoint(fromState);
      }

      if (existingIndex >= 0) {
        final existing = transitions[existingIndex];
        final existingControl = controlPoint ?? existing.controlPoint;
        final resolvedControlPoint =
            isSelfLoop && _isZeroVector(existingControl)
                ? _defaultLoopControlPoint(fromState)
                : existingControl;
        transitions[existingIndex] = existing.copyWith(
          fromState: fromState,
          toState: toState,
          label: resolvedLabel,
          controlPoint: resolvedControlPoint,
          inputSymbols: parsedLabel.symbols,
          lambdaSymbol: parsedLabel.lambdaSymbol,
        );
      } else {
        transitions.add(
          FSATransition(
            id: id,
            fromState: fromState,
            toState: toState,
            label: resolvedLabel,
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
    _traceGraphView('removeTransition', {'id': id});
    _mutateAutomaton((current) {
      final transitions =
          current.transitions.whereType<FSATransition>().toList();
      final index = transitions.indexWhere((transition) => transition.id == id);
      if (index < 0) {
        _traceGraphView('removeTransition skipped', {
          'id': id,
          'reason': 'not-found',
        });
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
    _traceGraphView('updateStateLabel', {'id': id, 'label': label});
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
      final acceptingStates =
          statesById.values.where((state) => state.isAccepting).toSet();

      return current.copyWith(
        states: statesById.values.toSet(),
        transitions: updatedTransitions.map<Transition>((t) => t).toSet(),
        initialState:
            initialStateId != null ? statesById[initialStateId] : null,
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

    _traceGraphView('updateStateFlags', {
      'id': id,
      'isInitial': isInitial,
      'isAccepting': isAccepting,
    });
    _mutateAutomaton((current) {
      if (current.states.every((state) => state.id != id)) {
        _traceGraphView('updateStateFlags skipped', {
          'id': id,
          'reason': 'not-found',
        });
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
      final acceptingStates =
          statesById.values.where((state) => state.isAccepting).toSet();

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
    _traceGraphView('updateTransitionLabel', {'id': id, 'label': label});
    _mutateAutomaton((current) {
      final transitions =
          current.transitions.whereType<FSATransition>().toList();
      final index = transitions.indexWhere((transition) => transition.id == id);
      if (index < 0) {
        _traceGraphView('updateTransitionLabel skipped', {
          'id': id,
          'reason': 'not-found',
        });
        return current;
      }

      final parsedLabel = _parseTransitionLabel(label);
      final resolvedLabel = _formatTransitionLabel(label, parsedLabel);
      final existing = transitions[index];
      final isSelfLoop = existing.fromState.id == existing.toState.id;
      final resolvedControlPoint =
          isSelfLoop && _isZeroVector(existing.controlPoint)
              ? _defaultLoopControlPoint(existing.fromState)
              : existing.controlPoint;
      transitions[index] = existing.copyWith(
        label: resolvedLabel,
        inputSymbols: parsedLabel.symbols,
        lambdaSymbol: parsedLabel.lambdaSymbol,
        controlPoint: resolvedControlPoint,
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
      _traceGraphView('mutation skipped', {'reason': 'identical-snapshot'});
      return;
    }

    _graphViewMutationCounter++;
    _traceGraphView('mutation applied', {
      'seq': _graphViewMutationCounter,
      'states': updated.states.length,
      'transitions': updated.transitions.length,
      'initial': updated.initialState?.id,
      'accepting': updated.acceptingStates.length,
      'alphabet': updated.alphabet.length,
    });

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

  void clearAutomaton() => clearAutomatonExtracted();

  void clearError() => clearErrorExtracted();

  void clearAll() => clearAllExtracted();

  void clearSimulation() => clearSimulationExtracted();

  void clearAlgorithmResults() => clearAlgorithmResultsExtracted();

  void _addSimulationToHistory(sim_result.SimulationResult result) =>
      _addSimulationToHistoryExtracted(result);

  FSA? getAutomatonFromHistory(int index) =>
      getAutomatonFromHistoryExtracted(index);

  sim_result.SimulationResult? getSimulationFromHistory(int index) =>
      getSimulationFromHistoryExtracted(index);
}
