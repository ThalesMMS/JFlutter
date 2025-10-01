import '../models/simulation_result.dart';
import '../models/simulation_step.dart';
import 'trace_persistence_service.dart';

/// Service for navigating between simulation traces and managing trace state
class TraceNavigationService {
  final TracePersistenceService _persistenceService;

  SimulationResult? _currentTrace;
  int _currentStepIndex = -1;
  List<TraceHistoryEntry> _traceHistory = [];
  int _currentTraceIndex = -1;

  TraceNavigationService(this._persistenceService);

  /// Gets the current trace being navigated
  SimulationResult? get currentTrace => _currentTrace;

  /// Gets the current step index in the current trace
  int get currentStepIndex => _currentStepIndex;

  /// Gets the index of the active trace in history.
  int get currentTraceIndex => _currentTraceIndex;

  /// Gets whether there is a current trace
  bool get hasCurrentTrace => _currentTrace != null;

  /// Gets whether there are previous steps to navigate to
  bool get canGoToPreviousStep => _currentStepIndex > 0;

  /// Gets whether there are next steps to navigate to
  bool get canGoToNextStep =>
      _currentTrace != null &&
      _currentStepIndex < _currentTrace!.steps.length - 1;

  /// Gets the current step being viewed
  SimulationStep? get currentStep {
    if (_currentTrace == null || _currentStepIndex < 0) return null;
    if (_currentStepIndex >= _currentTrace!.steps.length) return null;
    return _currentTrace!.steps[_currentStepIndex];
  }

  /// Gets the total number of steps in the current trace
  int get totalSteps => _currentTrace?.steps.length ?? 0;

  /// Gets the progress percentage (0.0 to 1.0)
  double get progress {
    if (_currentTrace == null || _currentTrace!.steps.isEmpty) return 0.0;
    return (_currentStepIndex + 1) / _currentTrace!.steps.length;
  }

  /// Gets whether we can navigate to the previous trace
  bool get canGoToPreviousTrace => _currentTraceIndex > 0;

  /// Gets whether we can navigate to the next trace
  bool get canGoToNextTrace =>
      _currentTraceIndex >= 0 && _currentTraceIndex < _traceHistory.length - 1;

  /// Loads a trace and sets it as current
  Future<void> loadTrace(SimulationResult trace) async {
    _currentTrace = trace;
    _currentStepIndex = trace.steps.isEmpty ? -1 : 0;

    // Save to persistence
    await _persistenceService.saveTrace(trace);

    // Refresh history
    await _refreshHistory();

    if (_traceHistory.isNotEmpty) {
      _currentTraceIndex = 0;
    }
  }

  /// Loads a trace by ID from history
  Future<void> loadTraceById(String traceId) async {
    try {
      final trace = await _persistenceService.loadTraceById(traceId);
      if (trace != null) {
        await loadTrace(trace);
        _currentTraceIndex = _traceHistory.indexWhere(
          (entry) => entry.id == traceId,
        );
      }
    } catch (e) {
      throw TraceNavigationException('Failed to load trace by ID: $e');
    }
  }

  /// Navigates to the previous step in the current trace
  bool goToPreviousStep() {
    if (!canGoToPreviousStep) return false;
    _currentStepIndex--;
    return true;
  }

  /// Navigates to the next step in the current trace
  bool goToNextStep() {
    if (!canGoToNextStep) return false;
    _currentStepIndex++;
    return true;
  }

  /// Navigates to a specific step by index
  bool goToStep(int stepIndex) {
    if (_currentTrace == null) return false;
    if (stepIndex < 0 || stepIndex >= _currentTrace!.steps.length) return false;

    _currentStepIndex = stepIndex;
    return true;
  }

  /// Navigates to the first step
  bool goToFirstStep() {
    if (_currentTrace == null || _currentTrace!.steps.isEmpty) return false;
    _currentStepIndex = 0;
    return true;
  }

  /// Navigates to the last step
  bool goToLastStep() {
    if (_currentTrace == null || _currentTrace!.steps.isEmpty) return false;
    _currentStepIndex = _currentTrace!.steps.length - 1;
    return true;
  }

  /// Navigates to the previous trace in history
  Future<bool> goToPreviousTrace() async {
    if (!canGoToPreviousTrace) return false;

    try {
      _currentTraceIndex--;
      final entry = _traceHistory[_currentTraceIndex];
      _currentTrace = entry.trace;
      _currentStepIndex = entry.trace.steps.isEmpty ? -1 : 0;
      return true;
    } catch (e) {
      throw TraceNavigationException(
        'Failed to navigate to previous trace: $e',
      );
    }
  }

  /// Navigates to the next trace in history
  Future<bool> goToNextTrace() async {
    if (!canGoToNextTrace) return false;

    try {
      _currentTraceIndex++;
      final entry = _traceHistory[_currentTraceIndex];
      _currentTrace = entry.trace;
      _currentStepIndex = entry.trace.steps.isEmpty ? -1 : 0;
      return true;
    } catch (e) {
      throw TraceNavigationException('Failed to navigate to next trace: $e');
    }
  }

  /// Loads trace history
  Future<void> loadTraceHistory() async {
    await _refreshHistory();
  }

  /// Gets the trace history
  List<TraceHistoryEntry> get traceHistory => List.unmodifiable(_traceHistory);

  /// Gets the current trace history entry
  TraceHistoryEntry? get currentTraceEntry {
    if (_currentTraceIndex < 0 || _currentTraceIndex >= _traceHistory.length) {
      return null;
    }
    return _traceHistory[_currentTraceIndex];
  }

  /// Exports the current trace to a file
  Future<String> exportCurrentTrace({String? fileName}) async {
    if (_currentTrace == null) {
      throw TraceNavigationException('No current trace to export');
    }

    return await _persistenceService.exportTraceToFile(
      _currentTrace!,
      fileName: fileName,
    );
  }

  /// Imports a trace from a file and loads it
  Future<void> importTraceFromFile(String filePath) async {
    try {
      final trace = await _persistenceService.importTraceFromFile(filePath);
      await loadTrace(trace);
    } catch (e) {
      throw TraceNavigationException('Failed to import trace from file: $e');
    }
  }

  /// Deletes the current trace from history
  Future<void> deleteCurrentTrace() async {
    if (_currentTrace == null) return;

    try {
      final currentEntry = currentTraceEntry;
      if (currentEntry != null) {
        await _persistenceService.deleteTrace(currentEntry.id);
        await _refreshHistory();

        // Navigate to the next available trace or clear current
        if (_traceHistory.isNotEmpty) {
          if (_currentTraceIndex >= _traceHistory.length) {
            _currentTraceIndex = _traceHistory.length - 1;
          }
          if (_currentTraceIndex >= 0) {
            final entry = _traceHistory[_currentTraceIndex];
            _currentTrace = entry.trace;
            _currentStepIndex = entry.trace.steps.isEmpty ? -1 : 0;
          }
        } else {
          _currentTrace = null;
          _currentStepIndex = -1;
          _currentTraceIndex = -1;
        }
      }
    } catch (e) {
      throw TraceNavigationException('Failed to delete current trace: $e');
    }
  }

  /// Clears all traces and navigation state
  Future<void> clearAllTraces() async {
    await _persistenceService.clearHistory();
    _currentTrace = null;
    _currentStepIndex = -1;
    _currentTraceIndex = -1;
    _traceHistory.clear();
  }

  /// Refreshes the trace history from persistence
  Future<void> _refreshHistory() async {
    try {
      _traceHistory = await _persistenceService.loadTraceHistory();
    } catch (e) {
      throw TraceNavigationException('Failed to refresh trace history: $e');
    }
  }

  /// Gets navigation state as a map for serialization
  Map<String, dynamic> getNavigationState() {
    return {
      'currentStepIndex': _currentStepIndex,
      'currentTraceIndex': _currentTraceIndex,
      'hasCurrentTrace': _currentTrace != null,
      'currentTraceId': currentTraceEntry?.id,
    };
  }

  /// Restores navigation state from a map
  Future<void> restoreNavigationState(Map<String, dynamic> state) async {
    _currentStepIndex = state['currentStepIndex'] as int? ?? -1;
    _currentTraceIndex = state['currentTraceIndex'] as int? ?? -1;

    final traceId = state['currentTraceId'] as String?;
    if (traceId != null) {
      try {
        await loadTraceById(traceId);
      } catch (e) {
        // If trace loading fails, reset to safe state
        _currentTrace = null;
        _currentStepIndex = -1;
        _currentTraceIndex = -1;
      }
    }
  }

  /// Gets a summary of the current navigation state
  String getNavigationSummary() {
    if (_currentTrace == null) {
      return 'No trace loaded';
    }

    final totalSteps = _currentTrace!.steps.length;
    final currentStep = _currentStepIndex + 1;
    final progressPercent = (progress * 100).toStringAsFixed(1);

    return 'Trace: ${_currentTrace!.inputString} | Step: $currentStep/$totalSteps ($progressPercent%)';
  }
}

/// Exception thrown when trace navigation operations fail
class TraceNavigationException implements Exception {
  final String message;
  const TraceNavigationException(this.message);

  @override
  String toString() => 'TraceNavigationException: $message';
}
