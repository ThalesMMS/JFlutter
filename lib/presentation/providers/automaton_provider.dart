import 'dart:math';
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
import '../../core/models/pda.dart';
import '../../core/models/simulation_result.dart' as sim_result;
import '../../core/models/tm.dart';
import '../../core/repositories/automaton_repository.dart';
import '../../core/result.dart';
import '../../core/use_cases/automaton_use_cases.dart';
import '../../core/entities/automaton_entity.dart';
import '../../data/repositories/automaton_repository_impl.dart';
import '../../data/services/automaton_service.dart';
import '../../data/services/conversion_service.dart';
import '../../data/services/simulation_service.dart';
import '../../features/layout/layout_repository_impl.dart';

/// Provider for automaton state management
class AutomatonProvider extends StateNotifier<AutomatonState> {
  final AutomatonService _automatonService;
  final SimulationService _simulationService;
  final ConversionService _conversionService;
  final LayoutRepository _layoutRepository;

  AutomatonProvider({
    required AutomatonService automatonService,
    required SimulationService simulationService,
    required ConversionService conversionService,
    required CreateAutomatonUseCase createAutomatonUseCase,
    required LoadAutomatonUseCase loadAutomatonUseCase,
    required LayoutRepository layoutRepository,
  })  : _automatonService = automatonService,
        _simulationService = simulationService,
        _conversionService = conversionService,
        _layoutRepository = layoutRepository,
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
          states: [
            StateData(
              id: 'q0',
              name: 'q0',
              position: Point(100, 100),
              isInitial: true,
              isAccepting: false,
            ),
          ],
          transitions: [],
          alphabet: alphabet,
          bounds: Rect(0, 0, 400, 300),
        ),
      );

      if (result.isSuccess) {
        state = state.copyWith(
          currentAutomaton: result.data,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
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
      final result = AutomatonSimulator.simulate(
        state.currentAutomaton!,
        inputString,
        stepByStep: true,
        timeout: const Duration(seconds: 5),
      );

      if (result.isSuccess) {
        state = state.copyWith(
          simulationResult: result.data,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
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
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
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
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
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
      state = state.copyWith(
        isLoading: false,
        grammarResult: result,
      );
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
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error applying auto layout: $e',
      );
    }
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
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
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
        state = state.copyWith(
          regexResult: result.data,
          isLoading: false,
        );
        return result.data;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
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
      final areEquivalent =
          EquivalenceChecker.areEquivalent(state.currentAutomaton!, other);
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
    state = state.copyWith(error: null);
  }

  /// Converts FSA to AutomatonEntity
  AutomatonEntity _convertFsaToEntity(FSA fsa) {
    final states = fsa.states.map((s) => StateEntity(
      id: s.id,
      name: s.label,
      x: s.position.x,
      y: s.position.y,
      isInitial: s.isInitial,
      isFinal: s.isAccepting,
    )).toList();

    // Build transitions map from FSA transitions
    final transitions = <String, List<String>>{};
    for (final transition in fsa.transitions.whereType<FSATransition>()) {
      final symbols = <String>{};
      if (transition.lambdaSymbol != null) {
        symbols.add(transition.lambdaSymbol!);
      } else {
        symbols.addAll(transition.inputSymbols);
      }

      for (final symbol in symbols) {
        final key = '${transition.fromState.id}|$symbol';
        transitions.putIfAbsent(key, () => <String>[]).add(transition.toState.id);
      }
    }

    final type = fsa.hasEpsilonTransitions
        ? AutomatonType.nfaLambda
        : fsa.isDeterministic
            ? AutomatonType.dfa
            : AutomatonType.nfa;

    return AutomatonEntity(
      id: fsa.id,
      name: fsa.name,
      alphabet: fsa.alphabet,
      states: states,
      transitions: transitions,
      initialId: fsa.initialState?.id,
      nextId: states.length + 1,
      type: type,
    );
  }

  /// Converts AutomatonEntity to FSA
  FSA _convertEntityToFsa(AutomatonEntity entity) {
    final states = entity.states.map((s) => State(
      id: s.id,
      label: s.name,
      position: Vector2(s.x, s.y),
      isInitial: s.isInitial,
      isAccepting: s.isFinal,
    )).toSet();

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
        
        final isLambda =
            symbol == 'λ' || symbol == 'ε' || symbol.toLowerCase() == 'lambda';

        for (final toStateId in entry.value) {
          final toState = states.firstWhere((s) => s.id == toStateId);
          transitions.add(FSATransition(
            id: 't${transitionId++}',
            fromState: fromState,
            toState: toState,
            label: symbol,
            inputSymbols: isLambda ? <String>{} : {symbol},
            lambdaSymbol: isLambda ? symbol : null,
          ));
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
      bounds: Rectangle(0, 0, 800, 600),
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

  const AutomatonState({
    this.currentAutomaton,
    this.simulationResult,
    this.regexResult,
    this.grammarResult,
    this.equivalenceResult,
    this.equivalenceDetails,
    this.isLoading = false,
    this.error,
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
  }) {
    return AutomatonState(
      currentAutomaton: currentAutomaton == _unset
          ? this.currentAutomaton
          : currentAutomaton as FSA?,
      simulationResult: simulationResult == _unset
          ? this.simulationResult
          : simulationResult as sim_result.SimulationResult?,
      regexResult:
          regexResult == _unset ? this.regexResult : regexResult as String?,
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
    );
  }
}

/// Provider instances
final automatonProvider = StateNotifierProvider<AutomatonProvider, AutomatonState>((ref) {
  return AutomatonProvider(
    automatonService: AutomatonService(),
    simulationService: SimulationService(),
    conversionService: ConversionService(),
    createAutomatonUseCase: CreateAutomatonUseCase(AutomatonRepositoryImpl(AutomatonService())),
    loadAutomatonUseCase: LoadAutomatonUseCase(AutomatonRepositoryImpl(AutomatonService())),
    layoutRepository: LayoutRepositoryImpl(),
  );
});
