part of 'automaton_provider.dart';

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
  return AutomatonProvider(
    automatonService: _registeredAutomatonService(),
    layoutRepository: _registeredLayoutRepository(),
    tracePersistenceService: _registeredTracePersistenceService(),
  );
});

AutomatonService _registeredAutomatonService() {
  final serviceLocator = GetIt.instance;
  if (!serviceLocator.isRegistered<AutomatonService>()) {
    return AutomatonService();
  }
  return serviceLocator<AutomatonService>();
}

LayoutRepository _registeredLayoutRepository() {
  final serviceLocator = GetIt.instance;
  if (serviceLocator.isRegistered<LayoutRepository>()) {
    return serviceLocator<LayoutRepository>();
  }
  if (serviceLocator.isRegistered<LayoutRepositoryImpl>()) {
    return serviceLocator<LayoutRepositoryImpl>();
  }
  return LayoutRepositoryImpl();
}

TracePersistenceService? _registeredTracePersistenceService() {
  final serviceLocator = GetIt.instance;
  if (!serviceLocator.isRegistered<TracePersistenceService>()) {
    return null;
  }
  return serviceLocator<TracePersistenceService>();
}

/// Provides a lazily constructed GraphView canvas controller for automata.
final graphViewCanvasControllerProvider = Provider<GraphViewCanvasController>((
  ref,
) {
  final automatonNotifier = ref.read(automatonStateProvider.notifier);
  final controller = GraphViewCanvasController(
    automatonStateNotifier: automatonNotifier,
  );
  ref.onDispose(controller.dispose);
  controller.synchronize(automatonNotifier.state.currentAutomaton);
  return controller;
});
