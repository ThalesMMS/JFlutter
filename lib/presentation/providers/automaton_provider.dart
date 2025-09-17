import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/tm.dart';
import '../../core/result.dart';
import '../../core/algorithms/automaton_simulator.dart';
import '../../core/models/simulation_result.dart' as sim_result;
import '../../core/algorithms/nfa_to_dfa_converter.dart';
import '../../core/algorithms/dfa_minimizer.dart';
import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/algorithms/fa_to_regex_converter.dart';
import '../../data/services/automaton_service.dart';
import '../../data/repositories/automaton_repository_impl.dart';
import '../../core/repositories/automaton_repository.dart';
import '../../data/services/simulation_service.dart';
import '../../data/services/conversion_service.dart';
import '../../core/use_cases/automaton_use_cases.dart';

/// Provider for automaton state management
class AutomatonProvider extends StateNotifier<AutomatonState> {
  final AutomatonService _automatonService;
  final SimulationService _simulationService;
  final ConversionService _conversionService;

  AutomatonProvider({
    required AutomatonService automatonService,
    required SimulationService simulationService,
    required ConversionService conversionService,
    required CreateAutomatonUseCase createAutomatonUseCase,
  })  : _automatonService = automatonService,
        _simulationService = simulationService,
        _conversionService = conversionService,
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
    state = state.copyWith(currentAutomaton: automaton);
  }

  /// Simulates the current automaton with input string
  Future<void> simulateAutomaton(String inputString) async {
    if (state.currentAutomaton == null) return;

    state = state.copyWith(isLoading: true, error: null);

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

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use the core algorithm directly
      final result = NFAToDFAConverter.convert(state.currentAutomaton!);

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
        error: 'Error converting NFA to DFA: $e',
      );
    }
  }

  /// Minimizes DFA
  Future<void> minimizeDfa() async {
    if (state.currentAutomaton == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use the core algorithm directly
      final result = DFAMinimizer.minimize(state.currentAutomaton!);

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
        error: 'Error minimizing DFA: $e',
      );
    }
  }

  /// Converts regex to NFA
  Future<void> convertRegexToNfa(String regex) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use the core algorithm directly
      final result = RegexToNFAConverter.convert(regex);

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
        error: 'Error converting regex to NFA: $e',
      );
    }
  }

  /// Converts FA to regex
  Future<void> convertFaToRegex() async {
    if (state.currentAutomaton == null) return;

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
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting FA to regex: $e',
      );
    }
  }

  /// Clears the current automaton
  void clearAutomaton() {
    state = state.copyWith(
      currentAutomaton: null,
      simulationResult: null,
      regexResult: null,
      error: null,
    );
  }

  /// Clears any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// State class for automaton provider
class AutomatonState {
  final FSA? currentAutomaton;
  final sim_result.SimulationResult? simulationResult;
  final String? regexResult;
  final bool isLoading;
  final String? error;

  const AutomatonState({
    this.currentAutomaton,
    this.simulationResult,
    this.regexResult,
    this.isLoading = false,
    this.error,
  });

  AutomatonState copyWith({
    FSA? currentAutomaton,
    sim_result.SimulationResult? simulationResult,
    String? regexResult,
    bool? isLoading,
    String? error,
  }) {
    return AutomatonState(
      currentAutomaton: currentAutomaton ?? this.currentAutomaton,
      simulationResult: simulationResult ?? this.simulationResult,
      regexResult: regexResult ?? this.regexResult,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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
  );
});
