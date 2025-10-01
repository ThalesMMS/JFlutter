import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../../core/models/simulation_result.dart';
import '../../core/models/simulation_step.dart';
import '../../data/services/trace_persistence_service.dart' as data_trace;
import '../../injection/dependency_injection.dart';

/// Unified trace state that can handle traces from any automaton type
class UnifiedTraceState {
  final SimulationResult? currentTrace;
  final int currentStepIndex;
  final bool isRunning;
  final bool stepByStep;
  final String lastInput;
  final String? automatonType;
  final String? automatonId;
  final List<Map<String, dynamic>> traceHistory;
  final String? errorMessage;
  final Map<String, dynamic> traceStatistics;

  const UnifiedTraceState({
    this.currentTrace,
    this.currentStepIndex = 0,
    this.isRunning = false,
    this.stepByStep = false,
    this.lastInput = '',
    this.automatonType,
    this.automatonId,
    this.traceHistory = const [],
    this.errorMessage,
    this.traceStatistics = const {},
  });

  UnifiedTraceState copyWith({
    SimulationResult? currentTrace,
    int? currentStepIndex,
    bool? isRunning,
    bool? stepByStep,
    String? lastInput,
    String? automatonType,
    String? automatonId,
    List<Map<String, dynamic>>? traceHistory,
    String? errorMessage,
    Map<String, dynamic>? traceStatistics,
  }) {
    return UnifiedTraceState(
      currentTrace: currentTrace ?? this.currentTrace,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isRunning: isRunning ?? this.isRunning,
      stepByStep: stepByStep ?? this.stepByStep,
      lastInput: lastInput ?? this.lastInput,
      automatonType: automatonType ?? this.automatonType,
      automatonId: automatonId ?? this.automatonId,
      traceHistory: traceHistory ?? this.traceHistory,
      errorMessage: errorMessage ?? this.errorMessage,
      traceStatistics: traceStatistics ?? this.traceStatistics,
    );
  }

  /// Navigate to a specific step in the current simulation
  UnifiedTraceState navigateToStep(int stepIndex) {
    if (currentTrace == null ||
        stepIndex < 0 ||
        stepIndex >= currentTrace!.steps.length) {
      return this;
    }
    return copyWith(currentStepIndex: stepIndex);
  }

  /// Navigate to the next step
  UnifiedTraceState nextStep() {
    if (currentTrace == null) return this;
    final nextIndex = currentStepIndex + 1;
    if (nextIndex >= currentTrace!.steps.length) return this;
    return copyWith(currentStepIndex: nextIndex);
  }

  /// Navigate to the previous step
  UnifiedTraceState previousStep() {
    final prevIndex = currentStepIndex - 1;
    if (prevIndex < 0) return this;
    return copyWith(currentStepIndex: prevIndex);
  }

  /// Navigate to the first step
  UnifiedTraceState firstStep() => copyWith(currentStepIndex: 0);

  /// Navigate to the last step
  UnifiedTraceState lastStep() {
    if (currentTrace == null) return this;
    return copyWith(currentStepIndex: currentTrace!.steps.length - 1);
  }

  /// Get the current simulation step
  SimulationStep? get currentStep {
    if (currentTrace == null || currentStepIndex >= currentTrace!.steps.length)
      return null;
    return currentTrace!.steps[currentStepIndex];
  }

  /// Check if we can navigate to the next step
  bool get canNavigateNext =>
      currentTrace != null && currentStepIndex < currentTrace!.steps.length - 1;

  /// Check if we can navigate to the previous step
  bool get canNavigatePrevious => currentStepIndex > 0;

  /// Get traces for current automaton type
  List<Map<String, dynamic>> get tracesForCurrentType {
    if (automatonType == null) return traceHistory;
    return traceHistory
        .where((trace) => trace['automatonType'] == automatonType)
        .toList();
  }

  /// Get traces for current automaton
  List<Map<String, dynamic>> get tracesForCurrentAutomaton {
    if (automatonId == null) return traceHistory;
    return traceHistory
        .where((trace) => trace['automatonId'] == automatonId)
        .toList();
  }
}

/// Unified trace notifier that handles traces across different automaton types
class UnifiedTraceNotifier extends StateNotifier<UnifiedTraceState> {
  final data_trace.TracePersistenceService _persistenceService;

  UnifiedTraceNotifier(this._persistenceService)
    : super(const UnifiedTraceState()) {
    _loadTraceHistory();
    _loadTraceStatistics();
  }

  /// Set the current automaton context
  void setAutomatonContext({
    required String automatonType,
    String? automatonId,
  }) {
    state = state.copyWith(
      automatonType: automatonType,
      automatonId: automatonId,
    );
    _loadTraceHistory();
  }

  /// Set step-by-step mode
  void setStepByStep(bool enabled) {
    state = state.copyWith(stepByStep: enabled);
  }

  /// Load a trace from history
  Future<void> loadTraceFromHistory(String traceId) async {
    try {
      final traceData = await _persistenceService.getTraceById(traceId);
      if (traceData == null) return;

      final traceJson = traceData['trace'] as Map<String, dynamic>;
      final trace = SimulationResult.fromJson(traceJson);

      state = state.copyWith(
        currentTrace: trace,
        currentStepIndex: 0,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load trace: $e');
    }
  }

  /// Save current trace to history
  Future<void> saveCurrentTraceToHistory() async {
    if (state.currentTrace == null) return;

    try {
      await _persistenceService.saveTraceToHistory(
        state.currentTrace!,
        automatonType: state.automatonType,
        automatonId: state.automatonId,
      );
      await _loadTraceHistory();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save trace: $e');
    }
  }

  /// Set a new trace (from simulation)
  void setTrace(SimulationResult trace) {
    state = state.copyWith(
      currentTrace: trace,
      currentStepIndex: 0,
      errorMessage: null,
    );

    // Auto-save to history
    saveCurrentTraceToHistory();
  }

  /// Navigate to a specific step
  void navigateToStep(int stepIndex) {
    state = state.navigateToStep(stepIndex);
    _saveCurrentTrace();
  }

  /// Navigate to the next step
  void nextStep() {
    state = state.nextStep();
    _saveCurrentTrace();
  }

  /// Navigate to the previous step
  void previousStep() {
    state = state.previousStep();
    _saveCurrentTrace();
  }

  /// Navigate to the first step
  void firstStep() {
    state = state.firstStep();
    _saveCurrentTrace();
  }

  /// Navigate to the last step
  void lastStep() {
    state = state.lastStep();
    _saveCurrentTrace();
  }

  /// Clear the current trace
  void clearCurrentTrace() {
    state = state.copyWith(
      currentTrace: null,
      currentStepIndex: 0,
      errorMessage: null,
    );
    _persistenceService.clearCurrentTrace();
  }

  /// Clear all trace history
  Future<void> clearAllTraces() async {
    await _persistenceService.clearAllTraces();
    state = state.copyWith(
      traceHistory: [],
      currentTrace: null,
      currentStepIndex: 0,
      errorMessage: null,
    );
  }

  /// Export trace history
  Future<String> exportTraceHistory() async {
    return await _persistenceService.exportTraceHistory();
  }

  /// Import trace history
  Future<void> importTraceHistory(String jsonData) async {
    try {
      await _persistenceService.importTraceHistory(jsonData);
      await _loadTraceHistory();
      await _loadTraceStatistics();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to import traces: $e');
    }
  }

  /// Get trace statistics
  Future<void> refreshTraceStatistics() async {
    await _loadTraceStatistics();
  }

  /// Load trace history from persistence
  Future<void> _loadTraceHistory() async {
    try {
      final history = await _persistenceService.getTraceHistory();
      state = state.copyWith(traceHistory: history);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load trace history: $e');
    }
  }

  /// Load trace statistics
  Future<void> _loadTraceStatistics() async {
    try {
      final statistics = await _persistenceService.getTraceStatistics();
      state = state.copyWith(traceStatistics: statistics);
    } catch (e) {
      // Statistics loading failure is not critical
    }
  }

  /// Save current trace state for persistence
  void _saveCurrentTrace() {
    if (state.currentTrace != null) {
      _persistenceService.saveCurrentTrace(
        state.currentTrace!,
        state.currentStepIndex,
      );
    }
  }
}

/// Provider for trace persistence service (data layer version)
final dataTracePersistenceServiceProvider =
    Provider<data_trace.TracePersistenceService>((ref) {
      throw UnimplementedError('TracePersistenceService must be initialized');
    });

/// Provider for unified trace state
final unifiedTraceProvider =
    StateNotifierProvider<UnifiedTraceNotifier, UnifiedTraceState>((ref) {
      final persistenceService = ref.watch(dataTracePersistenceServiceProvider);
      return UnifiedTraceNotifier(persistenceService);
    });

/// Provider for trace statistics
final traceStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final traceState = ref.watch(unifiedTraceProvider);
  return traceState.traceStatistics;
});

/// Provider for current automaton traces
final currentAutomatonTracesProvider = Provider<List<Map<String, dynamic>>>((
  ref,
) {
  final traceState = ref.watch(unifiedTraceProvider);
  return traceState.tracesForCurrentAutomaton;
});

/// Provider for current automaton type traces
final currentTypeTracesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final traceState = ref.watch(unifiedTraceProvider);
  return traceState.tracesForCurrentType;
});

/// GetIt-based provider for unified trace notifier
UnifiedTraceNotifier getUnifiedTraceNotifier() {
  return getIt<UnifiedTraceNotifier>();
}

/// GetIt-based provider for trace statistics
Map<String, dynamic> getTraceStatistics() {
  final notifier = getIt<UnifiedTraceNotifier>();
  return notifier.state.traceStatistics;
}

/// GetIt-based provider for current automaton traces
List<Map<String, dynamic>> getCurrentAutomatonTraces() {
  final notifier = getIt<UnifiedTraceNotifier>();
  return notifier.state.tracesForCurrentAutomaton;
}

/// GetIt-based provider for current automaton type traces
List<Map<String, dynamic>> getCurrentTypeTraces() {
  final notifier = getIt<UnifiedTraceNotifier>();
  return notifier.state.tracesForCurrentType;
}
