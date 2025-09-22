import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/use_cases/algorithm_use_cases.dart';
import '../../core/use_cases/automaton_use_cases.dart';
import '../../data/repositories/algorithm_repository_impl.dart';
import '../../data/repositories/automaton_repository_impl.dart';
import '../../data/services/automaton_service.dart';
import '../../features/layout/layout_repository_impl.dart';
import 'automaton/automaton_conversion_controller.dart';
import 'automaton/automaton_creation_controller.dart';
import 'automaton/automaton_layout_controller.dart';
import 'automaton/automaton_simulation_controller.dart';
import 'automaton/automaton_state.dart';

class AutomatonProvider extends StateNotifier<AutomatonState> {
  final AutomatonCreationController _creationController;
  final AutomatonSimulationController _simulationController;
  final AutomatonConversionController _conversionController;
  final AutomatonLayoutController _layoutController;

  AutomatonProvider({
    required AutomatonCreationController creationController,
    required AutomatonSimulationController simulationController,
    required AutomatonConversionController conversionController,
    required AutomatonLayoutController layoutController,
  })  : _creationController = creationController,
        _simulationController = simulationController,
        _conversionController = conversionController,
        _layoutController = layoutController,
        super(const AutomatonState());

  Future<void> createAutomaton({
    required String name,
    required List<String> alphabet,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    state = await _creationController.createAutomaton(
      state,
      name: name,
      alphabet: alphabet,
    );
  }

  void updateAutomaton(FSA automaton) {
    state = _creationController.updateAutomaton(state, automaton);
  }

  Future<void> simulateAutomaton(String inputString) async {
    if (state.currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    state = await _simulationController.simulate(state, inputString);
  }

  Future<void> convertNfaToDfa() async {
    if (state.currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    state = await _conversionController.convertNfaToDfa(state);
  }

  Future<void> minimizeDfa() async {
    if (state.currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    state = await _conversionController.minimizeDfa(state);
  }

  Future<void> completeDfa() async {
    if (state.currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    state = await _conversionController.completeDfa(state);
  }

  Future<Grammar?> convertFsaToGrammar() async {
    if (state.currentAutomaton == null) return null;

    state = state.copyWith(isLoading: true, error: null);
    state = await _conversionController.convertFsaToGrammar(state);
    return state.grammarResult;
  }

  Future<void> applyAutoLayout() async {
    if (state.currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    state = await _layoutController.applyAutoLayout(state);
  }

  Future<void> convertRegexToNfa(String regex) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    state = await _conversionController.convertRegexToNfa(state, regex);
  }

  Future<String?> convertFaToRegex() async {
    if (state.currentAutomaton == null) return null;

    state = state.copyWith(isLoading: true, error: null);
    state = await _conversionController.convertFaToRegex(state);
    return state.regexResult;
  }

  Future<bool?> compareEquivalence(FSA other) async {
    if (state.currentAutomaton == null) return null;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    state = await _conversionController.compareEquivalence(state, other);
    return state.equivalenceResult;
  }

  void clearAutomaton() {
    state = _creationController.clearAutomaton(state);
  }

  void clearError() {
    state = _creationController.clearError(state);
  }
}

final _automatonServiceProvider = Provider((ref) => AutomatonService());
final _automatonRepositoryProvider = Provider(
  (ref) => AutomatonRepositoryImpl(ref.read(_automatonServiceProvider)),
);
final _algorithmRepositoryProvider = Provider((ref) => AlgorithmRepositoryImpl());
final _layoutRepositoryProvider = Provider((ref) => LayoutRepositoryImpl());

final automatonCreationControllerProvider = Provider((ref) {
  final repository = ref.read(_automatonRepositoryProvider);
  return AutomatonCreationController(
    createAutomatonUseCase: CreateAutomatonUseCase(repository),
    addStateUseCase: AddStateUseCase(repository),
  );
});

final automatonSimulationControllerProvider = Provider((ref) {
  final algorithmRepository = ref.read(_algorithmRepositoryProvider);
  return AutomatonSimulationController(
    simulateWordUseCase: SimulateWordUseCase(algorithmRepository),
  );
});

final automatonConversionControllerProvider = Provider((ref) {
  final algorithmRepository = ref.read(_algorithmRepositoryProvider);
  return AutomatonConversionController(
    nfaToDfaUseCase: NfaToDfaUseCase(algorithmRepository),
    minimizeDfaUseCase: MinimizeDfaUseCase(algorithmRepository),
    completeDfaUseCase: CompleteDfaUseCase(algorithmRepository),
    regexToNfaUseCase: RegexToNfaUseCase(algorithmRepository),
    dfaToRegexUseCase: DfaToRegexUseCase(algorithmRepository),
    fsaToGrammarUseCase: FsaToGrammarUseCase(algorithmRepository),
    checkEquivalenceUseCase: CheckEquivalenceUseCase(algorithmRepository),
  );
});

final automatonLayoutControllerProvider = Provider((ref) {
  final layoutRepository = ref.read(_layoutRepositoryProvider);
  return AutomatonLayoutController(
    applyAutoLayoutUseCase: ApplyAutoLayoutUseCase(layoutRepository),
  );
});

final automatonProvider =
    StateNotifierProvider<AutomatonProvider, AutomatonState>((ref) {
  final creationController = ref.watch(automatonCreationControllerProvider);
  final simulationController = ref.watch(automatonSimulationControllerProvider);
  final conversionController = ref.watch(automatonConversionControllerProvider);
  final layoutController = ref.watch(automatonLayoutControllerProvider);

  return AutomatonProvider(
    creationController: creationController,
    simulationController: simulationController,
    conversionController: conversionController,
    layoutController: layoutController,
  );
});
