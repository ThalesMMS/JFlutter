import 'package:flutter/foundation.dart';
import '../../core/algo_log.dart';
import '../../core/run.dart';
import '../../core/entities/automaton_entity.dart';

/// Provider for managing algorithm execution and visualization
class AlgorithmExecutionProvider extends ChangeNotifier {
  final List<String> _logLines = [];
  final Set<String> _highlightedStates = {};
  bool _isRunning = false;
  int _currentStep = 0;
  double _playbackSpeed = 1.0;
  StepByStepRun? _stepByStepRun;
  String? _currentAlgorithm;

  // Getters
  List<String> get logLines => List.unmodifiable(_logLines);
  Set<String> get highlightedStates => Set.unmodifiable(_highlightedStates);
  bool get isRunning => _isRunning;
  int get currentStep => _currentStep;
  double get playbackSpeed => _playbackSpeed;
  StepByStepRun? get stepByStepRun => _stepByStepRun;
  String? get currentAlgorithm => _currentAlgorithm;

  /// Initialize the provider with AlgoLog listeners
  void initialize() {
    AlgoLog.lines.addListener(_onLogLinesChanged);
    AlgoLog.events.addListener(_onEventsChanged);
    AlgoLog.highlights.addListener(_onHighlightsChanged);
  }

  /// Dispose the provider and remove listeners
  @override
  void dispose() {
    AlgoLog.lines.removeListener(_onLogLinesChanged);
    AlgoLog.events.removeListener(_onEventsChanged);
    AlgoLog.highlights.removeListener(_onHighlightsChanged);
    super.dispose();
  }

  void _onLogLinesChanged() {
    _logLines.clear();
    _logLines.addAll(AlgoLog.lines.value);
    notifyListeners();
  }

  void _onEventsChanged() {
    // Update current step based on events
    _currentStep = AlgoLog.events.value.length;
    notifyListeners();
  }

  void _onHighlightsChanged() {
    _highlightedStates.clear();
    _highlightedStates.addAll(AlgoLog.highlights.value);
    notifyListeners();
  }

  /// Start algorithm execution
  void startAlgorithm(String algorithmName) {
    _currentAlgorithm = algorithmName;
    _isRunning = true;
    _currentStep = 0;
    notifyListeners();
  }

  /// Pause algorithm execution
  void pause() {
    _isRunning = false;
    notifyListeners();
  }

  /// Resume algorithm execution
  void resume() {
    _isRunning = true;
    notifyListeners();
  }

  /// Reset algorithm execution
  void reset() {
    _logLines.clear();
    _highlightedStates.clear();
    _currentStep = 0;
    _isRunning = false;
    _currentAlgorithm = null;
    _stepByStepRun = null;
    AlgoLog.clear();
    notifyListeners();
  }

  /// Set playback speed
  void setSpeed(double speed) {
    _playbackSpeed = speed;
    notifyListeners();
  }

  /// Go to next step
  void nextStep() {
    if (_currentStep < _logLines.length - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  /// Go to previous step
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  /// Start step-by-step simulation
  void startStepByStepSimulation(StepByStepRun run) {
    _stepByStepRun = run;
    _logLines.clear();
    _highlightedStates.clear();
    _currentStep = 0;
    _isRunning = true;
    _logLines.add('Iniciando simulação passo-a-passo da palavra: ${run.word}');
    notifyListeners();
  }

  /// Clear step-by-step simulation
  void clearStepByStepSimulation() {
    _stepByStepRun = null;
    _logLines.clear();
    _highlightedStates.clear();
    _currentStep = 0;
    _isRunning = false;
    notifyListeners();
  }

  /// Execute algorithm with real-time visualization
  Future<T?> executeAlgorithm<T>(
    String algorithmName,
    Future<T> Function() algorithm,
  ) async {
    startAlgorithm(algorithmName);
    
    try {
      final result = await algorithm();
      pause();
      return result;
    } catch (e) {
      pause();
      rethrow;
    }
  }
}
