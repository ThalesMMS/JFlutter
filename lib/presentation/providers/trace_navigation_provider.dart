import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/simulation_result.dart';
import '../../core/models/simulation_step.dart';
import '../../core/services/trace_persistence_service.dart';
import '../../core/services/trace_navigation_service.dart';

/// State for trace navigation
class TraceNavigationState {
  final SimulationResult? currentTrace;
  final int currentStepIndex;
  final bool isLoading;
  final String? error;
  final List<TraceHistoryEntry> traceHistory;
  final int currentTraceIndex;
  final bool canGoToPreviousStep;
  final bool canGoToNextStep;
  final bool canGoToPreviousTrace;
  final bool canGoToNextTrace;

  const TraceNavigationState({
    this.currentTrace,
    this.currentStepIndex = -1,
    this.isLoading = false,
    this.error,
    this.traceHistory = const [],
    this.currentTraceIndex = -1,
    this.canGoToPreviousStep = false,
    this.canGoToNextStep = false,
    this.canGoToPreviousTrace = false,
    this.canGoToNextTrace = false,
  });

  TraceNavigationState copyWith({
    SimulationResult? currentTrace,
    int? currentStepIndex,
    bool? isLoading,
    String? error,
    List<TraceHistoryEntry>? traceHistory,
    int? currentTraceIndex,
    bool? canGoToPreviousStep,
    bool? canGoToNextStep,
    bool? canGoToPreviousTrace,
    bool? canGoToNextTrace,
  }) {
    return TraceNavigationState(
      currentTrace: currentTrace ?? this.currentTrace,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      traceHistory: traceHistory ?? this.traceHistory,
      currentTraceIndex: currentTraceIndex ?? this.currentTraceIndex,
      canGoToPreviousStep: canGoToPreviousStep ?? this.canGoToPreviousStep,
      canGoToNextStep: canGoToNextStep ?? this.canGoToNextStep,
      canGoToPreviousTrace: canGoToPreviousTrace ?? this.canGoToPreviousTrace,
      canGoToNextTrace: canGoToNextTrace ?? this.canGoToNextTrace,
    );
  }

  /// Gets the current step being viewed
  SimulationStep? get currentStep {
    if (currentTrace == null || currentStepIndex < 0) return null;
    if (currentStepIndex >= currentTrace!.steps.length) return null;
    return currentTrace!.steps[currentStepIndex];
  }

  /// Gets the total number of steps in the current trace
  int get totalSteps => currentTrace?.steps.length ?? 0;

  /// Gets the progress percentage (0.0 to 1.0)
  double get progress {
    if (currentTrace == null || currentTrace!.steps.isEmpty) return 0.0;
    return (currentStepIndex + 1) / currentTrace!.steps.length;
  }

  /// Gets whether there is a current trace
  bool get hasCurrentTrace => currentTrace != null;

  /// Gets the current trace history entry
  TraceHistoryEntry? get currentTraceEntry {
    if (currentTraceIndex < 0 || currentTraceIndex >= traceHistory.length) {
      return null;
    }
    return traceHistory[currentTraceIndex];
  }

  /// Gets a navigation summary
  String get navigationSummary {
    if (currentTrace == null) {
      return 'No trace loaded';
    }

    final totalSteps = currentTrace!.steps.length;
    final currentStep = currentStepIndex + 1;
    final progressPercent = (progress * 100).toStringAsFixed(1);

    return 'Trace: ${currentTrace!.inputString} | Step: $currentStep/$totalSteps ($progressPercent%)';
  }
}

/// Provider for trace navigation service
final traceNavigationServiceProvider = Provider<TraceNavigationService>((ref) {
  final persistenceService = TracePersistenceService();
  return TraceNavigationService(persistenceService);
});

/// Provider for trace navigation state
class TraceNavigationNotifier extends StateNotifier<TraceNavigationState> {
  final TraceNavigationService _navigationService;

  TraceNavigationNotifier(this._navigationService)
    : super(const TraceNavigationState()) {
    _initializeState();
  }

  /// Initialize the navigation state
  Future<void> _initializeState() async {
    state = state.copyWith(isLoading: true);

    try {
      await _navigationService.loadTraceHistory();
      final currentTrace = _navigationService.currentTrace;

      if (currentTrace != null) {
        state = state.copyWith(
          currentTrace: currentTrace,
          currentStepIndex: _navigationService.currentStepIndex,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      await _updateNavigationCapabilities();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize trace navigation: $e',
      );
    }
  }

  /// Loads a trace and sets it as current
  Future<void> loadTrace(SimulationResult trace) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _navigationService.loadTrace(trace);
      await _updateStateFromService();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load trace: $e',
      );
    }
  }

  /// Navigates to the previous step
  Future<void> goToPreviousStep() async {
    if (!state.canGoToPreviousStep) return;

    try {
      _navigationService.goToPreviousStep();
      await _updateStateFromService();
    } catch (e) {
      state = state.copyWith(error: 'Failed to navigate to previous step: $e');
    }
  }

  /// Navigates to the next step
  Future<void> goToNextStep() async {
    if (!state.canGoToNextStep) return;

    try {
      _navigationService.goToNextStep();
      await _updateStateFromService();
    } catch (e) {
      state = state.copyWith(error: 'Failed to navigate to next step: $e');
    }
  }

  /// Navigates to a specific step
  Future<void> goToStep(int stepIndex) async {
    try {
      if (_navigationService.goToStep(stepIndex)) {
        await _updateStateFromService();
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to navigate to step $stepIndex: $e',
      );
    }
  }

  /// Navigates to the first step
  Future<void> goToFirstStep() async {
    try {
      if (_navigationService.goToFirstStep()) {
        await _updateStateFromService();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to navigate to first step: $e');
    }
  }

  /// Navigates to the last step
  Future<void> goToLastStep() async {
    try {
      if (_navigationService.goToLastStep()) {
        await _updateStateFromService();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to navigate to last step: $e');
    }
  }

  /// Navigates to the previous trace
  Future<void> goToPreviousTrace() async {
    if (!state.canGoToPreviousTrace) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _navigationService.goToPreviousTrace();
      await _updateStateFromService();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to navigate to previous trace: $e',
      );
    }
  }

  /// Navigates to the next trace
  Future<void> goToNextTrace() async {
    if (!state.canGoToNextTrace) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _navigationService.goToNextTrace();
      await _updateStateFromService();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to navigate to next trace: $e',
      );
    }
  }

  /// Loads trace history
  Future<void> loadTraceHistory() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _navigationService.loadTraceHistory();
      await _updateStateFromService();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load trace history: $e',
      );
    }
  }

  /// Exports the current trace
  Future<String?> exportCurrentTrace({String? fileName}) async {
    try {
      return await _navigationService.exportCurrentTrace(fileName: fileName);
    } catch (e) {
      state = state.copyWith(error: 'Failed to export trace: $e');
      return null;
    }
  }

  /// Imports a trace from file
  Future<void> importTraceFromFile(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _navigationService.importTraceFromFile(filePath);
      await _updateStateFromService();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to import trace: $e',
      );
    }
  }

  /// Deletes the current trace
  Future<void> deleteCurrentTrace() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _navigationService.deleteCurrentTrace();
      await _updateStateFromService();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete trace: $e',
      );
    }
  }

  /// Clears all traces
  Future<void> clearAllTraces() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _navigationService.clearAllTraces();
      state = const TraceNavigationState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to clear traces: $e',
      );
    }
  }

  /// Clears any error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Updates the state from the navigation service
  Future<void> _updateStateFromService() async {
    final currentTrace = _navigationService.currentTrace;
    final currentStepIndex = _navigationService.currentStepIndex;
    final traceHistory = _navigationService.traceHistory;
    final currentTraceIndex = _navigationService.currentStepIndex;

    state = state.copyWith(
      currentTrace: currentTrace,
      currentStepIndex: currentStepIndex,
      traceHistory: traceHistory,
      currentTraceIndex: currentTraceIndex,
      isLoading: false,
      error: null,
    );

    await _updateNavigationCapabilities();
  }

  /// Updates navigation capabilities based on current state
  Future<void> _updateNavigationCapabilities() async {
    final canGoToPreviousStep = _navigationService.canGoToPreviousStep;
    final canGoToNextStep = _navigationService.canGoToNextStep;
    final canGoToPreviousTrace = _navigationService.canGoToPreviousTrace;
    final canGoToNextTrace = _navigationService.canGoToNextTrace;

    state = state.copyWith(
      canGoToPreviousStep: canGoToPreviousStep,
      canGoToNextStep: canGoToNextStep,
      canGoToPreviousTrace: canGoToPreviousTrace,
      canGoToNextTrace: canGoToNextTrace,
    );
  }
}

/// Provider for trace navigation notifier
final traceNavigationProvider =
    StateNotifierProvider<TraceNavigationNotifier, TraceNavigationState>((ref) {
      final navigationService = ref.watch(traceNavigationServiceProvider);
      return TraceNavigationNotifier(navigationService);
    });
