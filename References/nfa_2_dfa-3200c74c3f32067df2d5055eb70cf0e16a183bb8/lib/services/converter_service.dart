import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import '../models/nfa.dart';
import '../models/state_model.dart';
import '../models/dfa.dart';


class NFAToDFAConverter {

  final Map<String, ConversionResult> _resultCache = {};

  // Progress tracking
  final StreamController<ConversionProgress> _progressController =
  StreamController<ConversionProgress>.broadcast();

  // Configuration
  final ConverterConfig _config;

  // Performance metrics
  ConversionMetrics? _lastMetrics;

  NFAToDFAConverter({ConverterConfig? config})
      : _config = config ?? ConverterConfig.defaultConfig();

  Stream<ConversionProgress> get progressStream => _progressController.stream;

  Future<ConversionResult> convert(
      NFA nfa, {
        ConversionOptions? options,
      }) async {
    final opts = options ?? const ConversionOptions();
    final stopwatch = Stopwatch()..start();

    try {
      // Check cache first
      if (opts.useCache) {
        final cached = _getCachedResult(nfa);
        if (cached != null) {
          _emitProgress(ConversionProgress.fromCache());
          return cached;
        }
      }

      // Validate NFA
      final validation = await _validateInput(nfa);
      if (!validation.isValid) {
        return ConversionResult.error(
          'NFA validation failed',
          errors: validation.errors,
        );
      }

      // Complexity analysis
      final complexity = analyzeComplexity(nfa);
      _emitProgress(ConversionProgress.started(nfa, complexity));

      // Choose conversion strategy based on complexity
      ConversionResult result;
      if (complexity.shouldUseParallel && opts.allowParallel) {
        result = await _convertParallel(nfa, opts);
      } else {
        result = await _convertSequential(nfa, opts);
      }

      // Minimize if requested
      if(result.isSuccess && result.dfa != null && opts.minimizeResult) {
        result = result.copyWith(dfa: await minimizeDFA(result.dfa!));
      }

      // Cache result if successful
      if (result.isSuccess && opts.useCache) {
        _cacheResult(nfa, result);
      }

      // Record metrics
      stopwatch.stop();
      _lastMetrics = ConversionMetrics(
        conversionTime: stopwatch.elapsed,
        nfaStates: nfa.stateCount,
        dfaStates: result.dfa?.stateCount ?? 0,
        memoryUsage: _estimateMemoryUsage(result),
        cacheHit: false,
      );

      _emitProgress(ConversionProgress.completed(result, _lastMetrics!));
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      final error = ConversionResult.error(
        'Conversion failed: ${e.toString()}',
        stackTrace: stackTrace,
      );
      _emitProgress(ConversionProgress.error(e.toString()));
      return error;
    }
  }

  /// Sequential conversion (original algorithm with optimizations)
  Future<ConversionResult> _convertSequential(
      NFA nfa,
      ConversionOptions options,
      ) async {
    final converter = _SequentialConverter(
      nfa: nfa,
      options: options,
      config: _config,
      onProgress: _emitProgress,
    );
    return await converter.execute();
  }

  /// Parallel conversion for complex NFAs
  Future<ConversionResult> _convertParallel(
      NFA nfa,
      ConversionOptions options,
      ) async {
    final converter = _ParallelConverter(
      nfa: nfa,
      options: options,
      config: _config,
      onProgress: _emitProgress,
    );
    return await converter.execute();
  }

  /// Enhanced complexity analysis
  ComplexityAnalysis analyzeComplexity(NFA nfa) {
    final states = nfa.stateCount;
    final alphabet = nfa.alphabet.length;
    final transitions = nfa.getTransitionCount();
    final epsilonTransitions = nfa.getEpsilonTransitionCount();

    final baseComplexity = (states > 0 && alphabet > 0) ? (states * alphabet).toDouble() : 1.0;
    final epsilonFactor = epsilonTransitions * 1.5;
    final transitionDensity = nfa.getTransitionDensity();

    final adjustedComplexity = (baseComplexity + epsilonFactor) * (transitionDensity > 0 ? transitionDensity : 1);

    final level = _determineComplexityLevel(adjustedComplexity);
    final shouldUseParallel =
        level.index >= ComplexityLevel.high.index && states > _config.parallelThreshold;

    return ComplexityAnalysis(
      nfaStates: states,
      alphabetSize: alphabet,
      transitionCount: transitions,
      epsilonTransitions: epsilonTransitions,
      maxPossibleDfaStates: _calculateMaxDfaStates(states),
      estimatedDfaStates: _estimateDfaStates(nfa),
      complexityScore: adjustedComplexity,
      complexityLevel: level,
      shouldUseParallel: shouldUseParallel,
      estimatedTime: _estimateConversionTime(adjustedComplexity),
      estimatedMemory: _estimateMemoryRequirement(states, alphabet),
    );
  }

  /// Optimized DFA minimization
  Future<DFA> minimizeDFA(DFA dfa) async {
    final minimizer = _DFAMinimizer(dfa, _config);
    return await minimizer.minimize();
  }

  /// Export conversion to various formats
  Future<String> exportConversion(
      ConversionResult result,
      ExportFormat format,
      ) async {
    final exporter = _ConversionExporter(result, _config);
    return await exporter.export(format);
  }

  /// Generate detailed analysis report
  String generateAdvancedReport(ConversionResult result) {
    final reporter = _AdvancedReporter(result, _lastMetrics, _config);
    return reporter.generate();
  }

  Future<NFA> optimizeNFA(NFA nfa) async {
    final optimizer = _NFAOptimizer(nfa, _config);
    return await optimizer.optimize();
  }

  /// Batch conversion with progress tracking
  Future<List<ConversionResult>> convertBatch(
      List<NFA> nfas, {
        ConversionOptions? options,
      }) async {
    final results = <ConversionResult>[];
    final totalCount = nfas.length;

    for (int i = 0; i < nfas.length; i++) {
      _emitProgress(ConversionProgress.batchProgress(i + 1, totalCount));
      final result = await convert(nfas[i], options: options);
      results.add(result);
      await Future.delayed(Duration.zero);
    }

    return results;
  }

  // Cache management
  ConversionResult? _getCachedResult(NFA nfa) {
    final key = _generateCacheKey(nfa);
    return _resultCache[key];
  }

  void _cacheResult(NFA nfa, ConversionResult result) {
    if (_resultCache.length >= _config.maxCacheSize) {
      _clearOldestCacheEntry();
    }
    final key = _generateCacheKey(nfa);
    _resultCache[key] = result;
  }

  String _generateCacheKey(NFA nfa) {
    return '${nfa.hashCode}_${nfa.stateCount}_${nfa.alphabet.length}';
  }

  void _clearOldestCacheEntry() {
    if (_resultCache.isNotEmpty) {
      final oldestKey = _resultCache.keys.first;
      _resultCache.remove(oldestKey);
    }
  }

  // Progress reporting
  void _emitProgress(ConversionProgress progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  // Input validation
  Future<ValidationResult> _validateInput(NFA nfa) async {
    final validator = _NFAValidator(nfa, _config);
    return await validator.validate();
  }

  // Utility methods
  ComplexityLevel _determineComplexityLevel(double score) {
    if (score <= 50) return ComplexityLevel.low;
    if (score <= 200) return ComplexityLevel.medium;
    if (score <= 1000) return ComplexityLevel.high;
    return ComplexityLevel.veryHigh;
  }

  int _calculateMaxDfaStates(int nfaStates) => 1 << nfaStates;

  int _estimateDfaStates(NFA nfa) {
    final density = nfa.getTransitionDensity();
    return (nfa.stateCount * (1.0 + density)).round();
  }

  Duration _estimateConversionTime(double complexity) {
    final milliseconds = (complexity * _config.timeComplexityFactor).round();
    return Duration(milliseconds: milliseconds);
  }

  int _estimateMemoryRequirement(int states, int alphabet) {
    return states * alphabet * 64; // Rough estimate
  }

  int _estimateMemoryUsage(ConversionResult result) {
    if (!result.isSuccess || result.dfa == null) return 0;
    return result.dfa!.stateCount * result.dfa!.alphabet.length * 32;
  }

  // Cleanup
  void dispose() {
    _progressController.close();
    _resultCache.clear();
  }

  // Getters
  ConversionMetrics? get lastMetrics => _lastMetrics;
  int get cacheSize => _resultCache.length;
  ConverterConfig get config => _config;
}

/// Sequential converter implementation
class _SequentialConverter {
  final NFA nfa;
  final ConversionOptions options;
  final ConverterConfig config;
  final Function(ConversionProgress) onProgress;
  final Map<String, Set<String>> _epsilonClosureCache = {};

  _SequentialConverter({
    required this.nfa,
    required this.options,
    required this.config,
    required this.onProgress,
  });

  Future<ConversionResult> execute() async {
    final steps = <DetailedStep>[];
    final stopwatch = Stopwatch()..start();

    // Initialize DFA
    final dfa = DFA();
    dfa.addSymbols(nfa.alphabet);

    if (nfa.startState.isEmpty) {
      return ConversionResult.error("NFA start state is not defined.");
    }

    // Calculate start state closure
    onProgress(ConversionProgress.epsilonClosureCalculation());
    final startClosure = _getEpsilonClosure({nfa.startState});
    final startStateSet = _getOrCreateStateSet(startClosure);

    dfa.addState(startStateSet, customName: 'q0');
    dfa.setStartState(startStateSet);

    // Subset construction
    onProgress(ConversionProgress.subsetConstruction());
    final processed = <StateSet>{};
    final queue = Queue<StateSet>()..add(startStateSet);
    int stepCounter = 1;

    while (queue.isNotEmpty) {
      final currentSet = queue.removeFirst();
      if (processed.contains(currentSet)) continue;
      processed.add(currentSet);

      onProgress(ConversionProgress.processingState(
        dfa.getStateName(currentSet),
        stepCounter,
        processed.length,
        queue.length,
      ));

      final step = DetailedStep(
        stepNumber: stepCounter++,
        currentState: currentSet,
        stateName: dfa.getStateName(currentSet),
        transitions: {},
        newStates: [],
        processingTime: stopwatch.elapsed,
      );

      // Process each symbol
      for (final symbol in nfa.alphabet) {
        final reachable = _getReachableStates(currentSet, symbol);
        if (reachable.isNotEmpty) {
          final closure = _getEpsilonClosure(reachable);
          final newStateSet = _getOrCreateStateSet(closure);
          if (!dfa.states.contains(newStateSet)) {
            dfa.addState(newStateSet);
            queue.add(newStateSet);
            step.newStates.add(newStateSet);
          }
          dfa.addTransition(currentSet, symbol, newStateSet);
          step.transitions[symbol] = newStateSet;
        } else if (options.includeDeadStates) {
          final deadState = _getOrCreateDeadState(dfa);
          dfa.addTransition(currentSet, symbol, deadState);
          step.transitions[symbol] = deadState;
        }
      }
      steps.add(step);

      if (stepCounter % config.yieldInterval == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    onProgress(ConversionProgress.finalizingDFA());
    _setFinalStates(dfa);

    final validation = dfa.validate();

    return ConversionResult.success(
      nfa: nfa,
      dfa: dfa,
      steps: steps,
      warnings: validation.warnings,
      processingTime: stopwatch.elapsed,
      algorithmUsed: ConversionAlgorithm.sequential,
    );
  }

  Set<String> _getEpsilonClosure(Set<String> states) {
    final key = (states.toList()..sort()).join(',');
    if (_epsilonClosureCache.containsKey(key)) {
      return _epsilonClosureCache[key]!;
    }
    final closure = nfa.epsilonClosure(states);
    _epsilonClosureCache[key] = closure;
    return closure;
  }

  Set<String> _getReachableStates(StateSet stateSet, String symbol) {
    final reachable = <String>{};
    for (final stateModel in stateSet.states) {
      reachable.addAll(nfa.getTransitions(stateModel.name, symbol));
    }
    return reachable;
  }

  StateSet _getOrCreateStateSet(Set<String> stateNames) {
    final stateModels = stateNames.map((name) => StateModel(
      name: name,
      isFinal: nfa.finalStates.contains(name),
    )).toSet();
    return StateSet(stateModels);
  }

  StateSet _getOrCreateDeadState(DFA dfa) {
    final deadState = StateSet({const StateModel(name: '∅', isFinal: false)});
    if (!dfa.states.contains(deadState)) {
      dfa.addState(deadState, customName: '∅');
      for (final symbol in dfa.alphabet) {
        dfa.addTransition(deadState, symbol, deadState);
      }
    }
    return deadState;
  }

  void _setFinalStates(DFA dfa) {
    for (final state in dfa.states) {
      if (state.isFinal) {
        dfa.setFinalState(state, true);
      }
    }
  }
}

/// Parallel converter for complex NFAs
class _ParallelConverter {
  final NFA nfa;
  final ConversionOptions options;
  final ConverterConfig config;
  final Function(ConversionProgress) onProgress;

  _ParallelConverter({
    required this.nfa,
    required this.options,
    required this.config,
    required this.onProgress,
  });

  Future<ConversionResult> execute() async {
    onProgress(ConversionProgress.message('Parallel conversion not yet implemented, falling back to sequential.'));
    final sequential = _SequentialConverter(
      nfa: nfa,
      options: options,
      config: config,
      onProgress: onProgress,
    );
    final result = await sequential.execute();
    return result.copyWith(algorithmUsed: ConversionAlgorithm.parallel);
  }
}

/// Enhanced configuration class
class ConverterConfig {
  final int maxCacheSize;
  final int parallelThreshold;
  final int yieldInterval;
  final double timeComplexityFactor;
  final bool enableOptimizations;
  final bool enableProfiling;

  const ConverterConfig({
    this.maxCacheSize = 100,
    this.parallelThreshold = 20,
    this.yieldInterval = 10,
    this.timeComplexityFactor = 0.1,
    this.enableOptimizations = true,
    this.enableProfiling = false,
  });

  factory ConverterConfig.defaultConfig() => const ConverterConfig();
  factory ConverterConfig.performance() => const ConverterConfig(
    maxCacheSize: 500,
    parallelThreshold: 10,
    yieldInterval: 5,
    enableOptimizations: true,
  );
  factory ConverterConfig.memory() => const ConverterConfig(
    maxCacheSize: 50,
    yieldInterval: 20,
    enableOptimizations: false,
  );
}

/// Enhanced conversion options
class ConversionOptions {
  final bool useCache;
  final bool allowParallel;
  final bool includeDeadStates;
  final bool minimizeResult;
  final bool trackDetailedSteps;

  const ConversionOptions({
    this.useCache = true,
    this.allowParallel = true,
    this.includeDeadStates = false,
    this.minimizeResult = false,
    this.trackDetailedSteps = true,
  });
}

/// Enhanced progress tracking
class ConversionProgress {
  final ConversionProgressType type;
  final String message;
  final double? percentage;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  ConversionProgress._(this.type, this.message, {this.percentage, this.data = const {}})
      : timestamp = DateTime.now();

  factory ConversionProgress.started(NFA nfa, ComplexityAnalysis complexity) =>
      ConversionProgress._(
        ConversionProgressType.started,
        'شروع تبدیل NFA (${complexity.complexityLevel.description})',
        percentage: 0.0,
        data: {'complexity': complexity.toString()},
      );
  factory ConversionProgress.epsilonClosureCalculation() =>
      ConversionProgress._(
        ConversionProgressType.epsilonClosure,
        'محاسبه Epsilon Closure',
        percentage: 10.0,
      );
  factory ConversionProgress.subsetConstruction() =>
      ConversionProgress._(
        ConversionProgressType.subsetConstruction,
        'الگوریتم Subset Construction',
        percentage: 20.0,
      );
  factory ConversionProgress.processingState(String stateName, int step, int processed, int remaining) {
    final total = processed + remaining;
    final percentage = total > 0 ? (processed / total) * 60 + 20 : 50.0;
    return ConversionProgress._(
      ConversionProgressType.processingState,
      'پردازش $stateName (مرحله $step)',
      percentage: percentage,
      data: {'stateName': stateName, 'step': step, 'processed': processed, 'remaining': remaining},
    );
  }
  factory ConversionProgress.finalizingDFA() =>
      ConversionProgress._(ConversionProgressType.finalizing, 'تکمیل DFA', percentage: 90.0);
  factory ConversionProgress.completed(ConversionResult result, ConversionMetrics metrics) =>
      ConversionProgress._(
        ConversionProgressType.completed,
        'تبدیل کامل شد در ${metrics.conversionTime.inMilliseconds}ms',
        percentage: 100.0,
        data: {'result': result.toString(), 'metrics': metrics.toString()},
      );
  factory ConversionProgress.fromCache() =>
      ConversionProgress._(ConversionProgressType.completed, 'نتیجه از کش دریافت شد', percentage: 100.0);
  factory ConversionProgress.batchProgress(int current, int total) =>
      ConversionProgress._(
        ConversionProgressType.batchProgress,
        'پردازش $current از $total',
        percentage: (current / total) * 100,
        data: {'current': current, 'total': total},
      );
  factory ConversionProgress.error(String error) =>
      ConversionProgress._(ConversionProgressType.error, 'خطا: $error', data: {'error': error});
  factory ConversionProgress.message(String message) =>
      ConversionProgress._(ConversionProgressType.message, message);
}

enum ConversionProgressType {
  started, epsilonClosure, subsetConstruction, processingState, finalizing,
  completed, batchProgress, error, message,
}

/// Enhanced complexity analysis
class ComplexityAnalysis {
  final int nfaStates, alphabetSize, transitionCount, epsilonTransitions;
  final int maxPossibleDfaStates, estimatedDfaStates, estimatedMemory;
  final double complexityScore;
  final ComplexityLevel complexityLevel;
  final bool shouldUseParallel;
  final Duration estimatedTime;

  ComplexityAnalysis({
    required this.nfaStates, required this.alphabetSize, required this.transitionCount,
    required this.epsilonTransitions, required this.maxPossibleDfaStates,
    required this.estimatedDfaStates, required this.complexityScore,
    required this.complexityLevel, required this.shouldUseParallel,
    required this.estimatedTime, required this.estimatedMemory,
  });
}

enum ComplexityLevel {
  low('پیچیدگی پایین'), medium('پیچیدگی متوسط'),
  high('پیچیدگی بالا'), veryHigh('پیچیدگی خیلی بالا');
  const ComplexityLevel(this.description);
  final String description;
}

/// Performance metrics
class ConversionMetrics {
  final Duration conversionTime;
  final int nfaStates, dfaStates, memoryUsage;
  final bool cacheHit;
  final DateTime timestamp;

  ConversionMetrics({
    required this.conversionTime, required this.nfaStates, required this.dfaStates,
    required this.memoryUsage, required this.cacheHit,
  }) : timestamp = DateTime.now();

  double get compressionRatio => dfaStates > 0 ? nfaStates / dfaStates : 0;
  double get timePerState => nfaStates > 0 ? conversionTime.inMicroseconds / nfaStates : 0;
}

/// Enhanced conversion result
class ConversionResult {
  final bool isSuccess;
  final String? errorMessage;
  final List<String> errors, warnings;
  final NFA? nfa;
  final DFA? dfa;
  final List<DetailedStep>? steps;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Duration? processingTime;
  final ConversionAlgorithm? algorithmUsed;

  ConversionResult._({
    required this.isSuccess, this.errorMessage, this.errors = const [],
    this.warnings = const [], this.nfa, this.dfa, this.steps, this.stackTrace,
    this.processingTime, this.algorithmUsed,
  }) : timestamp = DateTime.now();

  factory ConversionResult.success({
    required NFA nfa, required DFA dfa, required List<DetailedStep> steps,
    List<String> warnings = const [], Duration? processingTime,
    ConversionAlgorithm? algorithmUsed,
  }) => ConversionResult._(
    isSuccess: true, nfa: nfa, dfa: dfa, steps: steps, warnings: warnings,
    processingTime: processingTime, algorithmUsed: algorithmUsed,
  );

  factory ConversionResult.error(String message, {List<String> errors = const [], StackTrace? stackTrace}) =>
      ConversionResult._(isSuccess: false, errorMessage: message, errors: errors, stackTrace: stackTrace);

  ConversionResult copyWith({
    DFA? dfa,
    ConversionAlgorithm? algorithmUsed,
  }) => ConversionResult._(
    isSuccess: isSuccess, errorMessage: errorMessage, errors: errors, warnings: warnings,
    nfa: nfa, dfa: dfa ?? this.dfa, steps: steps, stackTrace: stackTrace,
    processingTime: processingTime, algorithmUsed: algorithmUsed ?? this.algorithmUsed,
  );
}

enum ConversionAlgorithm { sequential, parallel }

/// Enhanced detailed step with timing info
class DetailedStep {
  final int stepNumber;
  final StateSet currentState;
  final String stateName;
  final Map<String, StateSet> transitions;
  final List<StateSet> newStates;
  final Duration processingTime;

  DetailedStep({
    required this.stepNumber, required this.currentState, required this.stateName,
    required this.transitions, required this.newStates, required this.processingTime,
  });
}

enum ExportFormat { json, xml, dot, latex, csv }

class _DFAMinimizer {
  final DFA _dfa;
  final ConverterConfig _config;
  _DFAMinimizer(this._dfa, this._config);

  Future<DFA> minimize() async {
    return _dfa.minimize();
  }
}

class _ConversionExporter {
  final ConversionResult _result;
  final ConverterConfig _config;
  _ConversionExporter(this._result, this._config);

  Future<String> export(ExportFormat format) async {
    if (!_result.isSuccess || _result.dfa == null) {
      return 'Error: Cannot export failed conversion.';
    }
    switch(format) {
      case ExportFormat.json:
        return _result.dfa!.toJson().toString();
      case ExportFormat.dot:
        return 'DOT format not implemented in provided DFA.';
      default:
        return 'Export format ${format.name} is not supported.';
    }
  }
}

class _AdvancedReporter {
  final ConversionResult _result;
  final ConversionMetrics? _metrics;
  final ConverterConfig _config;
  _AdvancedReporter(this._result, this._metrics, this._config);

  String generate() {
    if (!_result.isSuccess || _result.dfa == null) {
      return 'Advanced Report: Conversion Failed.\nError: ${_result.errorMessage}';
    }
    return _result.dfa!.generateReport();
  }
}

class _NFAOptimizer {
  final NFA _nfa;
  final ConverterConfig _config;
  _NFAOptimizer(this._nfa, this._config);

  Future<NFA> optimize() async {
    print("Warning: NFAOptimizer.optimize is a placeholder.");
    return _nfa;
  }
}

class _NFAValidator {
  final NFA _nfa;
  final ConverterConfig _config;
  _NFAValidator(this._nfa, this._config);

  Future<ValidationResult> validate() async {
    return _nfa.validate();
  }
}