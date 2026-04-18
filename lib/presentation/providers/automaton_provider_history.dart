part of 'automaton_provider.dart';

extension _AutomatonProviderHistory on AutomatonProvider {
  /// Clears the current automaton
  void clearAutomatonExtracted() {
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
  void clearErrorExtracted() {
    state = state.clearError();
  }

  /// Clear all state and reset to initial
  void clearAllExtracted() {
    state = state.clear();
  }

  /// Clear simulation results
  void clearSimulationExtracted() {
    state = state.clearSimulation();
  }

  /// Clear algorithm results
  void clearAlgorithmResultsExtracted() {
    state = state.clearAlgorithmResults();
  }

  /// Add simulation result to history
  void _addSimulationToHistoryExtracted(sim_result.SimulationResult result) {
    final newHistory = [...state.simulationHistory, result];
    state = state.copyWith(simulationHistory: newHistory);

    // Also save to trace persistence service if available
    _tracePersistenceService?.saveTrace(result).catchError((error) {
      // Silently fail - trace persistence is a nice-to-have feature
      debugPrint('Failed to persist simulation trace: $error');
    });
  }

  /// Get automaton from history
  FSA? getAutomatonFromHistoryExtracted(int index) {
    if (index < 0 || index >= state.automatonHistory.length) return null;
    return state.automatonHistory[index];
  }

  /// Get simulation result from history
  sim_result.SimulationResult? getSimulationFromHistoryExtracted(int index) {
    if (index < 0 || index >= state.simulationHistory.length) return null;
    return state.simulationHistory[index];
  }
}
