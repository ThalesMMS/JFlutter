import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/entities/automaton_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/simulation_result.dart' as sim_result;
import '../../core/result.dart';
import '../../core/use_cases/algorithm_use_cases.dart';
import '../../core/use_cases/automaton_use_cases.dart';
import '../../core/utils/automaton_entity_mapper.dart';
import '../../data/repositories/algorithm_repository_impl.dart';
import '../../data/repositories/automaton_repository_impl.dart';
import '../../data/services/automaton_service.dart';
import '../../features/layout/layout_repository_impl.dart';

/// Provider for automaton state management
class AutomatonProvider extends StateNotifier<AutomatonState> {
  final CreateAutomatonUseCase _createAutomatonUseCase;
  final AddStateUseCase _addStateUseCase;
  final NfaToDfaUseCase _nfaToDfaUseCase;
  final MinimizeDfaUseCase _minimizeDfaUseCase;
  final CompleteDfaUseCase _completeDfaUseCase;
  final RegexToNfaUseCase _regexToNfaUseCase;
  final DfaToRegexUseCase _dfaToRegexUseCase;
  final FsaToGrammarUseCase _fsaToGrammarUseCase;
  final CheckEquivalenceUseCase _checkEquivalenceUseCase;
  final SimulateWordUseCase _simulateWordUseCase;
  final ApplyAutoLayoutUseCase _applyAutoLayoutUseCase;

  AutomatonProvider({
    required CreateAutomatonUseCase createAutomatonUseCase,
    required AddStateUseCase addStateUseCase,
    required NfaToDfaUseCase nfaToDfaUseCase,
    required MinimizeDfaUseCase minimizeDfaUseCase,
    required CompleteDfaUseCase completeDfaUseCase,
    required RegexToNfaUseCase regexToNfaUseCase,
    required DfaToRegexUseCase dfaToRegexUseCase,
    required FsaToGrammarUseCase fsaToGrammarUseCase,
    required CheckEquivalenceUseCase checkEquivalenceUseCase,
    required SimulateWordUseCase simulateWordUseCase,
    required ApplyAutoLayoutUseCase applyAutoLayoutUseCase,
  })  : _createAutomatonUseCase = createAutomatonUseCase,
        _addStateUseCase = addStateUseCase,
        _nfaToDfaUseCase = nfaToDfaUseCase,
        _minimizeDfaUseCase = minimizeDfaUseCase,
        _completeDfaUseCase = completeDfaUseCase,
        _regexToNfaUseCase = regexToNfaUseCase,
        _dfaToRegexUseCase = dfaToRegexUseCase,
        _fsaToGrammarUseCase = fsaToGrammarUseCase,
        _checkEquivalenceUseCase = checkEquivalenceUseCase,
        _simulateWordUseCase = simulateWordUseCase,
        _applyAutoLayoutUseCase = applyAutoLayoutUseCase,
        super(const AutomatonState());

  /// Creates a new automaton
  Future<void> createAutomaton({
    required String name,
    required List<String> alphabet,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final createResult = await _createAutomatonUseCase.execute(
        name: name,
        type: AutomatonType.dfa,
        alphabet: alphabet.toSet(),
      );

      if (createResult.isFailure) {
        state = state.copyWith(
          isLoading: false,
          error: createResult.error,
        );
        return;
      }

      var automatonEntity = createResult.data!;
      final addInitialStateResult = await _addStateUseCase.execute(
        automaton: automatonEntity,
        name: 'q0',
        x: 100,
        y: 100,
        isInitial: true,
        isFinal: false,
      );

      if (addInitialStateResult.isFailure) {
        state = state.copyWith(
          isLoading: false,
          error: addInitialStateResult.error,
        );
        return;
      }

      automatonEntity = addInitialStateResult.data!;

      state = state.copyWith(
        currentAutomaton: automatonEntityToFsa(automatonEntity),
        isLoading: false,
      );
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
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _simulateWordUseCase.execute(
        automatonEntity,
        inputString,
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
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _nfaToDfaUseCase.execute(automatonEntity);

      if (result.isSuccess) {
        state = state.copyWith(
          currentAutomaton: automatonEntityToFsa(result.data!),
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
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _minimizeDfaUseCase.execute(automatonEntity);

      if (result.isSuccess) {
        state = state.copyWith(
          currentAutomaton: automatonEntityToFsa(result.data!),
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
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _completeDfaUseCase.execute(automatonEntity);

      if (result.isSuccess) {
        state = state.copyWith(
          currentAutomaton: automatonEntityToFsa(result.data!),
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
        error: 'Error completing DFA: $e',
      );
    }
  }

  /// Converts FSA to Grammar
  Future<Grammar?> convertFsaToGrammar() async {
    if (state.currentAutomaton == null) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _fsaToGrammarUseCase.execute(automatonEntity);

      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          grammarResult: result.data,
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
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _applyAutoLayoutUseCase.execute(automatonEntity);

      if (result.isSuccess) {
        state = state.copyWith(
          currentAutomaton: automatonEntityToFsa(result.data!),
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
      final result = await _regexToNfaUseCase.execute(regex);

      if (result.isSuccess) {
        state = state.copyWith(
          currentAutomaton: automatonEntityToFsa(result.data!),
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
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _dfaToRegexUseCase.execute(automatonEntity);

      if (result.isSuccess) {
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
      final currentEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final otherEntity = fsaToAutomatonEntity(other);
      final result = await _checkEquivalenceUseCase.execute(
        currentEntity,
        otherEntity,
      );

      if (result.isSuccess) {
        final areEquivalent = result.data!;
        state = state.copyWith(
          isLoading: false,
          equivalenceResult: areEquivalent,
          equivalenceDetails: areEquivalent
              ? 'The automata accept the same language.'
              : 'A distinguishing string was found between the automata.',
        );
        return areEquivalent;
      } else {
        state = state.copyWith(
          isLoading: false,
          equivalenceResult: null,
          equivalenceDetails: result.error,
          error: result.error,
        );
        return null;
      }
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
final automatonProvider =
    StateNotifierProvider<AutomatonProvider, AutomatonState>((ref) {
  final automatonService = AutomatonService();
  final automatonRepository = AutomatonRepositoryImpl(automatonService);
  final algorithmRepository = AlgorithmRepositoryImpl();
  final layoutRepository = LayoutRepositoryImpl();

  return AutomatonProvider(
    createAutomatonUseCase: CreateAutomatonUseCase(automatonRepository),
    addStateUseCase: AddStateUseCase(automatonRepository),
    nfaToDfaUseCase: NfaToDfaUseCase(algorithmRepository),
    minimizeDfaUseCase: MinimizeDfaUseCase(algorithmRepository),
    completeDfaUseCase: CompleteDfaUseCase(algorithmRepository),
    regexToNfaUseCase: RegexToNfaUseCase(algorithmRepository),
    dfaToRegexUseCase: DfaToRegexUseCase(algorithmRepository),
    fsaToGrammarUseCase: FsaToGrammarUseCase(algorithmRepository),
    checkEquivalenceUseCase: CheckEquivalenceUseCase(algorithmRepository),
    simulateWordUseCase: SimulateWordUseCase(algorithmRepository),
    applyAutoLayoutUseCase: ApplyAutoLayoutUseCase(layoutRepository),
  );
});
