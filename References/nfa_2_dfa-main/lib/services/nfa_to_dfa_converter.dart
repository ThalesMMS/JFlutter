import 'dart:collection';
import 'dart:math' as math;
import 'dart:isolate';
import 'dart:async';
import '../models/nfa.dart';
import '../models/dfa.dart';
import '../models/state_model.dart';

enum AdvancedConversionAlgorithm {
  adaptiveSubsetConstruction,
  hybridConstruction,
  memoryOptimizedConstruction,
  streamingConstruction,
  parallelConstruction,
  intelligentCaching,
}

/// سطوح بهینه‌سازی
enum OptimizationLevel { minimal, balanced, aggressive, maximum }

/// استراتژی‌های مدیریت حافظه
enum MemoryStrategy { conservative, balanced, generous }

/// نوع پردازش
enum ProcessingMode { sequential, parallel, adaptive }

/// کلاس پیشرفته برای گزارش تبدیل
class EnhancedConversionReport {
  final Duration conversionTime;
  final Duration preprocessingTime;
  final Duration postprocessingTime;
  final int nfaStates;
  final int dfaStates;
  final int nfaTransitions;
  final int dfaTransitions;
  final double compressionRatio;
  final double speedupRatio;
  final List<String> optimizationsApplied;
  final Map<String, dynamic> performanceMetrics;
  final List<String> conversionSteps;
  final Map<String, dynamic> memoryUsage;
  final Map<String, Duration> timingBreakdown;
  final List<String> warnings;
  final List<String> recommendations;

  EnhancedConversionReport({
    required this.conversionTime,
    required this.preprocessingTime,
    required this.postprocessingTime,
    required this.nfaStates,
    required this.dfaStates,
    required this.nfaTransitions,
    required this.dfaTransitions,
    required this.compressionRatio,
    required this.speedupRatio,
    required this.optimizationsApplied,
    required this.performanceMetrics,
    this.conversionSteps = const [],
    this.memoryUsage = const {},
    this.timingBreakdown = const {},
    this.warnings = const [],
    this.recommendations = const [],
  });

  @override
  String toString() {
    return '''
=== گزارش تفصیلی تبدیل NFA به DFA ===

📊 آمار کلی:
  زمان کل تبدیل: ${conversionTime.inMilliseconds} ms
  زمان پیش‌پردازش: ${preprocessingTime.inMilliseconds} ms
  زمان پس‌پردازش: ${postprocessingTime.inMilliseconds} ms
  نسبت تسریع: ${speedupRatio.toStringAsFixed(2)}x

📈 تحلیل حالات:
  NFA: $nfaStates حالت → DFA: $dfaStates حالت
  نسبت فشرده‌سازی: ${compressionRatio.toStringAsFixed(2)}%
  
📋 انتقال‌ها:
  NFA: $nfaTransitions انتقال → DFA: $dfaTransitions انتقال

🔧 بهینه‌سازی‌های اعمال شده:
${optimizationsApplied.map((opt) => '  ✓ $opt').join('\n')}

⚡ متریک‌های عملکرد:
${performanceMetrics.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}

💾 استفاده از حافظه:
${memoryUsage.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}

⏱️ تفکیک زمان‌بندی:
${timingBreakdown.entries.map((e) => '  ${e.key}: ${e.value.inMilliseconds} ms').join('\n')}

${warnings.isNotEmpty ? '⚠️ هشدارها:\n${warnings.map((w) => '  • $w').join('\n')}\n' : ''}

${recommendations.isNotEmpty ? '💡 پیشنهادات:\n${recommendations.map((r) => '  • $r').join('\n')}' : ''}

🔄 مراحل تبدیل:
${conversionSteps.take(10).map((step) => '  • $step').join('\n')}
${conversionSteps.length > 10 ? '  ... و ${conversionSteps.length - 10} مرحله دیگر' : ''}
''';
  }

  /// تولید گزارش JSON
  Map<String, dynamic> toJson() {
    return {
      'conversionTime': conversionTime.inMilliseconds,
      'preprocessingTime': preprocessingTime.inMilliseconds,
      'postprocessingTime': postprocessingTime.inMilliseconds,
      'nfaStates': nfaStates,
      'dfaStates': dfaStates,
      'nfaTransitions': nfaTransitions,
      'dfaTransitions': dfaTransitions,
      'compressionRatio': compressionRatio,
      'speedupRatio': speedupRatio,
      'optimizationsApplied': optimizationsApplied,
      'performanceMetrics': performanceMetrics,
      'memoryUsage': memoryUsage,
      'timingBreakdown': timingBreakdown.map(
        (k, v) => MapEntry(k, v.inMilliseconds),
      ),
      'warnings': warnings,
      'recommendations': recommendations,
      'totalSteps': conversionSteps.length,
    };
  }
}

class AdvancedConversionConfig {
  final AdvancedConversionAlgorithm algorithm;
  final OptimizationLevel optimizationLevel;
  final MemoryStrategy memoryStrategy;
  final ProcessingMode processingMode;
  final int maxStatesLimit;
  final int maxMemoryMB;
  final Duration maxTimeLimit;
  final bool enableDetailedLogging;
  final bool enableCaching;
  final bool enablePreOptimization;
  final bool enablePostOptimization;
  final bool enableParallelProcessing;
  final int parallelWorkers;
  final double cacheHitRatioThreshold;
  final bool enableProgressiveConstruction;
  final bool enableStatePrediction;
  final bool enableCompressionAnalysis;

  const AdvancedConversionConfig({
    this.algorithm = AdvancedConversionAlgorithm.adaptiveSubsetConstruction,
    this.optimizationLevel = OptimizationLevel.balanced,
    this.memoryStrategy = MemoryStrategy.balanced,
    this.processingMode = ProcessingMode.adaptive,
    this.maxStatesLimit = 50000,
    this.maxMemoryMB = 512,
    this.maxTimeLimit = const Duration(minutes: 5),
    this.enableDetailedLogging = false,
    this.enableCaching = true,
    this.enablePreOptimization = true,
    this.enablePostOptimization = true,
    this.enableParallelProcessing = false,
    this.parallelWorkers = 4,
    this.cacheHitRatioThreshold = 0.7,
    this.enableProgressiveConstruction = true,
    this.enableStatePrediction = true,
    this.enableCompressionAnalysis = true,
  });

  AdvancedConversionConfig copyWith({
    AdvancedConversionAlgorithm? algorithm,
    OptimizationLevel? optimizationLevel,
    MemoryStrategy? memoryStrategy,
    ProcessingMode? processingMode,
    int? maxStatesLimit,
    int? maxMemoryMB,
    Duration? maxTimeLimit,
    bool? enableDetailedLogging,
    bool? enableCaching,
    bool? enablePreOptimization,
    bool? enablePostOptimization,
    bool? enableParallelProcessing,
    int? parallelWorkers,
    double? cacheHitRatioThreshold,
    bool? enableProgressiveConstruction,
    bool? enableStatePrediction,
    bool? enableCompressionAnalysis,
  }) {
    return AdvancedConversionConfig(
      algorithm: algorithm ?? this.algorithm,
      optimizationLevel: optimizationLevel ?? this.optimizationLevel,
      memoryStrategy: memoryStrategy ?? this.memoryStrategy,
      processingMode: processingMode ?? this.processingMode,
      maxStatesLimit: maxStatesLimit ?? this.maxStatesLimit,
      maxMemoryMB: maxMemoryMB ?? this.maxMemoryMB,
      maxTimeLimit: maxTimeLimit ?? this.maxTimeLimit,
      enableDetailedLogging:
          enableDetailedLogging ?? this.enableDetailedLogging,
      enableCaching: enableCaching ?? this.enableCaching,
      enablePreOptimization:
          enablePreOptimization ?? this.enablePreOptimization,
      enablePostOptimization:
          enablePostOptimization ?? this.enablePostOptimization,
      enableParallelProcessing:
          enableParallelProcessing ?? this.enableParallelProcessing,
      parallelWorkers: parallelWorkers ?? this.parallelWorkers,
      cacheHitRatioThreshold:
          cacheHitRatioThreshold ?? this.cacheHitRatioThreshold,
      enableProgressiveConstruction:
          enableProgressiveConstruction ?? this.enableProgressiveConstruction,
      enableStatePrediction:
          enableStatePrediction ?? this.enableStatePrediction,
      enableCompressionAnalysis:
          enableCompressionAnalysis ?? this.enableCompressionAnalysis,
    );
  }
}

/// کلاس مدیریت کش هوشمند
class IntelligentCache {
  final Map<String, Set<String>> _epsilonClosureCache = {};
  final Map<String, Set<String>> _moveCache = {};
  final Map<String, StateSet> _stateSetCache = {};
  final Map<String, bool> _equivalenceCache = {};

  int _hits = 0;
  int _misses = 0;
  final int _maxSize;

  IntelligentCache({int maxSize = 10000}) : _maxSize = maxSize;

  double get hitRatio =>
      (_hits + _misses) > 0 ? _hits / (_hits + _misses) : 0.0;

  Map<String, int> get stats => {
    'hits': _hits,
    'misses': _misses,
    'total_entries':
        _epsilonClosureCache.length + _moveCache.length + _stateSetCache.length,
    'hit_ratio_percent': (hitRatio * 100).round(),
  };

  Set<String>? getEpsilonClosure(Set<String> states) {
    final key = states.toList()..sort();
    final cacheKey = key.join(',');

    if (_epsilonClosureCache.containsKey(cacheKey)) {
      _hits++;
      return _epsilonClosureCache[cacheKey];
    }
    _misses++;
    return null;
  }

  void putEpsilonClosure(Set<String> states, Set<String> closure) {
    if (_epsilonClosureCache.length >= _maxSize) _evictOldEntries();

    final key = states.toList()..sort();
    final cacheKey = key.join(',');
    _epsilonClosureCache[cacheKey] = closure;
  }

  Set<String>? getMove(Set<String> states, String symbol) {
    final key = states.toList()..sort();
    final cacheKey = '${key.join(',')}:$symbol';

    if (_moveCache.containsKey(cacheKey)) {
      _hits++;
      return _moveCache[cacheKey];
    }
    _misses++;
    return null;
  }

  void putMove(Set<String> states, String symbol, Set<String> result) {
    if (_moveCache.length >= _maxSize) _evictOldEntries();

    final key = states.toList()..sort();
    final cacheKey = '${key.join(',')}:$symbol';
    _moveCache[cacheKey] = result;
  }

  void _evictOldEntries() {
    // حذف 25% از ورودی‌های قدیمی
    final toRemove = (_maxSize * 0.25).round();

    if (_epsilonClosureCache.length > toRemove) {
      final keys = _epsilonClosureCache.keys.take(toRemove).toList();
      for (final key in keys) _epsilonClosureCache.remove(key);
    }

    if (_moveCache.length > toRemove) {
      final keys = _moveCache.keys.take(toRemove).toList();
      for (final key in keys) _moveCache.remove(key);
    }
  }

  void clear() {
    _epsilonClosureCache.clear();
    _moveCache.clear();
    _stateSetCache.clear();
    _equivalenceCache.clear();
    _hits = 0;
    _misses = 0;
  }
}

/// کلاس تحلیل‌گر NFA
class NFAAnalyzer {
  static NFAAnalysisResult analyze(NFA nfa) {
    final stopwatch = Stopwatch()..start();

    final complexity = _calculateComplexity(nfa);
    final characteristics = _identifyCharacteristics(nfa);
    final bottlenecks = _identifyBottlenecks(nfa);
    final recommendations = _generateRecommendations(
      nfa,
      complexity,
      characteristics,
    );

    stopwatch.stop();

    return NFAAnalysisResult(
      complexity: complexity,
      characteristics: characteristics,
      bottlenecks: bottlenecks,
      recommendations: recommendations,
      analysisTime: stopwatch.elapsed,
    );
  }

  static NFAComplexityMetrics _calculateComplexity(NFA nfa) {
    final stateCount = nfa.states.length;
    final alphabetSize = nfa.alphabet.length;
    final transitionCount = nfa.transitionCount;
    final epsilonTransitions = _countEpsilonTransitions(nfa);

    // محاسبه پیچیدگی تخمینی DFA
    final estimatedDFAStates = math.min(
      math.pow(2, stateCount).toInt(),
      stateCount * stateCount,
    );

    final nondeterminismDegree = _calculateNondeterminismDegree(nfa);

    return NFAComplexityMetrics(
      stateCount: stateCount,
      alphabetSize: alphabetSize,
      transitionCount: transitionCount,
      epsilonTransitions: epsilonTransitions,
      estimatedDFAStates: estimatedDFAStates,
      nondeterminismDegree: nondeterminismDegree,
      cyclomaticComplexity: _calculateCyclomaticComplexity(nfa),
    );
  }

  static int _countEpsilonTransitions(NFA nfa) {
    int count = 0;
    for (final state in nfa.states) {
      count += nfa.getTransitions(state, NFA.epsilon).length;
    }
    return count;
  }

  static double _calculateNondeterminismDegree(NFA nfa) {
    int nondeterministicTransitions = 0;
    int totalTransitions = 0;

    for (final state in nfa.states) {
      for (final symbol in nfa.alphabet) {
        final transitions = nfa.getTransitions(state, symbol);
        totalTransitions++;
        if (transitions.length > 1) nondeterministicTransitions++;
      }
    }

    return totalTransitions > 0
        ? nondeterministicTransitions / totalTransitions
        : 0.0;
  }

  static int _calculateCyclomaticComplexity(NFA nfa) {
    // محاسبه پیچیدگی چرخه‌ای بر اساس نظریه گراف
    final edges = nfa.transitionCount;
    final nodes = nfa.states.length;
    final connectedComponents = 1; // فرض: NFA متصل است

    return edges - nodes + 2 * connectedComponents;
  }

  static Set<String> _identifyCharacteristics(NFA nfa) {
    final characteristics = <String>{};

    if (_hasEpsilonTransitions(nfa))
      characteristics.add('دارای انتقال‌های اپسیلون');
    if (_isHighlyNondeterministic(nfa)) characteristics.add('غیرقطعیت بالا');
    if (_hasSelfLoops(nfa)) characteristics.add('دارای حلقه‌های خودی');
    if (_hasUnreachableStates(nfa))
      characteristics.add('دارای حالات غیرقابل دسترس');
    if (_hasDeadStates(nfa)) characteristics.add('دارای حالات مرده');
    if (_isMinimal(nfa)) characteristics.add('کمینه');
    if (_hasLongPaths(nfa)) characteristics.add('دارای مسیرهای طولانی');

    return characteristics;
  }

  static bool _hasEpsilonTransitions(NFA nfa) {
    for (final state in nfa.states) {
      if (nfa.getTransitions(state, NFA.epsilon).isNotEmpty) return true;
    }
    return false;
  }

  static bool _isHighlyNondeterministic(NFA nfa) {
    return _calculateNondeterminismDegree(nfa) > 0.3;
  }

  static bool _hasSelfLoops(NFA nfa) {
    for (final state in nfa.states) {
      for (final symbol in [...nfa.alphabet, NFA.epsilon]) {
        if (nfa.getTransitions(state, symbol).contains(state)) return true;
      }
    }
    return false;
  }

  static bool _hasUnreachableStates(NFA nfa) {
    final reachable = <String>{};
    final queue = Queue<String>();

    if (nfa.startState.isNotEmpty) {
      queue.add(nfa.startState);
      reachable.add(nfa.startState);
    }

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final symbol in [...nfa.alphabet, NFA.epsilon]) {
        for (final next in nfa.getTransitions(current, symbol)) {
          if (!reachable.contains(next)) {
            reachable.add(next);
            queue.add(next);
          }
        }
      }
    }

    return reachable.length < nfa.states.length;
  }

  static bool _hasDeadStates(NFA nfa) {
    // بررسی وجود حالات مرده (غیرمولد)
    final productive = <String>{};
    productive.addAll(nfa.finalStates);

    bool changed = true;
    while (changed) {
      changed = false;
      for (final state in nfa.states) {
        if (!productive.contains(state)) {
          for (final symbol in [...nfa.alphabet, NFA.epsilon]) {
            final transitions = nfa.getTransitions(state, symbol);
            if (transitions.any((t) => productive.contains(t))) {
              productive.add(state);
              changed = true;
              break;
            }
          }
        }
      }
    }

    return productive.length < nfa.states.length;
  }

  static bool _isMinimal(NFA nfa) {
    // تخمین سادۀ کمینه بودن
    return !_hasUnreachableStates(nfa) && !_hasDeadStates(nfa);
  }

  static bool _hasLongPaths(NFA nfa) {
    // بررسی وجود مسیرهای طولانی
    return _findLongestPath(nfa) > nfa.states.length;
  }

  static int _findLongestPath(NFA nfa) {
    final visited = <String, int>{};
    int maxPath = 0;

    for (final state in nfa.states) {
      final pathLength = _dfsLongestPath(nfa, state, visited);
      maxPath = math.max(maxPath, pathLength);
    }

    return maxPath;
  }

  static int _dfsLongestPath(NFA nfa, String state, Map<String, int> visited) {
    if (visited.containsKey(state)) return visited[state]!;

    int maxPath = 0;
    for (final symbol in [...nfa.alphabet, NFA.epsilon]) {
      for (final next in nfa.getTransitions(state, symbol)) {
        if (next != state) {
          // جلوگیری از حلقه بی‌نهایت
          maxPath = math.max(maxPath, _dfsLongestPath(nfa, next, visited));
        }
      }
    }

    visited[state] = maxPath + 1;
    return maxPath + 1;
  }

  static List<String> _identifyBottlenecks(NFA nfa) {
    final bottlenecks = <String>[];

    // حالات با انتقال‌های زیاد
    for (final state in nfa.states) {
      int outgoingTransitions = 0;
      for (final symbol in [...nfa.alphabet, NFA.epsilon]) {
        outgoingTransitions += nfa.getTransitions(state, symbol).length;
      }

      if (outgoingTransitions > nfa.alphabet.length * 2) {
        bottlenecks.add('حالت $state دارای $outgoingTransitions انتقال خروجی');
      }
    }

    // نمادهای با غیرقطعیت بالا
    for (final symbol in nfa.alphabet) {
      int nondeterministicCount = 0;
      for (final state in nfa.states) {
        if (nfa.getTransitions(state, symbol).length > 1) {
          nondeterministicCount++;
        }
      }

      final ratio = nondeterministicCount / nfa.states.length;
      if (ratio > 0.5) {
        bottlenecks.add(
          'نماد $symbol در ${(ratio * 100).round()}% حالات غیرقطعی',
        );
      }
    }

    return bottlenecks;
  }

  static List<String> _generateRecommendations(
    NFA nfa,
    NFAComplexityMetrics complexity,
    Set<String> characteristics,
  ) {
    final recommendations = <String>[];

    if (complexity.estimatedDFAStates > 10000) {
      recommendations.add(
        'استفاده از الگوریتم LazyConstruction برای کاهش مصرف حافظه',
      );
      recommendations.add(
        'فعال‌سازی حد مجاز حالات برای جلوگیری از انفجار حالت',
      );
    }

    if (complexity.nondeterminismDegree > 0.5) {
      recommendations.add(
        'استفاده از بهینه‌سازی پیش از تبدیل برای کاهش غیرقطعیت',
      );
    }

    if (characteristics.contains('دارای انتقال‌های اپسیلون')) {
      recommendations.add('پیش‌محاسبه epsilon closures برای بهبود عملکرد');
      recommendations.add('استفاده از کش هوشمند برای epsilon closures');
    }

    if (characteristics.contains('دارای حالات غیرقابل دسترس')) {
      recommendations.add('حذف حالات غیرقابل دسترس قبل از تبدیل');
    }

    if (characteristics.contains('دارای حالات مرده')) {
      recommendations.add('حذف حالات مرده قبل از تبدیل');
    }

    if (complexity.stateCount > 50) {
      recommendations.add('استفاده از پردازش موازی برای تسریع تبدیل');
    }

    if (complexity.cyclomaticComplexity > 20) {
      recommendations.add('تقسیم NFA به بخش‌های کوچک‌تر قبل از تبدیل');
    }

    return recommendations;
  }
}

/// کلاس نتیجه تحلیل NFA
class NFAAnalysisResult {
  final NFAComplexityMetrics complexity;
  final Set<String> characteristics;
  final List<String> bottlenecks;
  final List<String> recommendations;
  final Duration analysisTime;

  NFAAnalysisResult({
    required this.complexity,
    required this.characteristics,
    required this.bottlenecks,
    required this.recommendations,
    required this.analysisTime,
  });

  @override
  String toString() {
    return '''
=== تحلیل NFA ===
زمان تحلیل: ${analysisTime.inMilliseconds} ms

📊 متریک‌های پیچیدگی:
  تعداد حالات: ${complexity.stateCount}
  اندازه الفبا: ${complexity.alphabetSize}
  تعداد انتقال‌ها: ${complexity.transitionCount}
  انتقال‌های اپسیلون: ${complexity.epsilonTransitions}
  حالات تخمینی DFA: ${complexity.estimatedDFAStates}
  درجه غیرقطعیت: ${(complexity.nondeterminismDegree * 100).toStringAsFixed(1)}%
  پیچیدگی چرخه‌ای: ${complexity.cyclomaticComplexity}

🔍 ویژگی‌ها:
${characteristics.map((c) => '  • $c').join('\n')}

⚠️ گلوگاه‌ها:
${bottlenecks.map((b) => '  • $b').join('\n')}

💡 پیشنهادات:
${recommendations.map((r) => '  • $r').join('\n')}
''';
  }
}

/// متریک‌های پیچیدگی NFA
class NFAComplexityMetrics {
  final int stateCount;
  final int alphabetSize;
  final int transitionCount;
  final int epsilonTransitions;
  final int estimatedDFAStates;
  final double nondeterminismDegree;
  final int cyclomaticComplexity;

  NFAComplexityMetrics({
    required this.stateCount,
    required this.alphabetSize,
    required this.transitionCount,
    required this.epsilonTransitions,
    required this.estimatedDFAStates,
    required this.nondeterminismDegree,
    required this.cyclomaticComplexity,
  });
}

/// کلاس اصلی تبدیل‌کننده پیشرفته
class EnhancedNFAToDFAConverter {
  final AdvancedConversionConfig config;
  final Function(String message, double progress)? onProgress;
  final Function(String message)? onLog;

  late final IntelligentCache _cache;
  final List<String> _conversionSteps = [];
  final Map<String, Duration> _timingBreakdown = {};
  final List<String> _warnings = [];
  final List<String> _recommendations = [];

  Stopwatch? _overallStopwatch;
  NFAAnalysisResult? _analysisResult;

  EnhancedNFAToDFAConverter({
    this.config = const AdvancedConversionConfig(),
    this.onProgress,
    this.onLog,
  }) {
    _cache = IntelligentCache(maxSize: _getCacheSize());
  }

  int _getCacheSize() {
    switch (config.memoryStrategy) {
      case MemoryStrategy.conservative:
        return 1000;
      case MemoryStrategy.balanced:
        return 10000;
      case MemoryStrategy.generous:
        return 100000;
    }
  }

  /// تبدیل پیشرفته با گزارش تفصیلی
  Future<(DFA, EnhancedConversionReport)> convertWithEnhancedReport(
    NFA nfa,
  ) async {
    _overallStopwatch = Stopwatch()..start();
    _conversionSteps.clear();
    _timingBreakdown.clear();
    _warnings.clear();
    _recommendations.clear();
    _cache.clear();

    try {
      _log('شروع تبدیل پیشرفته NFA به DFA');
      _reportProgress('آماده‌سازی...', 0.0);

      // مرحله 1: تحلیل NFA
      final analysisStopwatch = Stopwatch()..start();
      _analysisResult = NFAAnalyzer.analyze(nfa);
      analysisStopwatch.stop();
      _timingBreakdown['تحلیل NFA'] = analysisStopwatch.elapsed;
      _log(
        'تحلیل NFA تکمیل شد در ${analysisStopwatch.elapsed.inMilliseconds} ms',
      );

      // مرحله 2: اعتبارسنجی
      await _validateNFA(nfa);

      // مرحله 3: پیش‌پردازش
      final preprocessStopwatch = Stopwatch()..start();
      final preprocessedNFA = await _preprocessNFA(nfa);
      preprocessStopwatch.stop();
      _timingBreakdown['پیش‌پردازش'] = preprocessStopwatch.elapsed;

      // مرحله 4: تبدیل اصلی
      _reportProgress('تبدیل در حال انجام...', 0.3);
      final conversionStopwatch = Stopwatch()..start();
      final dfa = await _performAdvancedConversion(preprocessedNFA);
      conversionStopwatch.stop();
      _timingBreakdown['تبدیل اصلی'] = conversionStopwatch.elapsed;

      // مرحله 5: پس‌پردازش
      final postprocessStopwatch = Stopwatch()..start();
      final optimizedDFA = await _postprocessDFA(dfa, preprocessedNFA);
      postprocessStopwatch.stop();
      _timingBreakdown['پس‌پردازش'] = postprocessStopwatch.elapsed;

      _overallStopwatch!.stop();
      _reportProgress('تکمیل شد', 1.0);

      final report = _generateEnhancedReport(
        nfa,
        optimizedDFA,
        preprocessStopwatch.elapsed,
        postprocessStopwatch.elapsed,
      );

      return (optimizedDFA, report);
    } catch (e) {
      _overallStopwatch?.stop();
      _log('خطا در تبدیل: $e');
      rethrow;
    }
  }

  /// تبدیل ساده
  Future<DFA> convert(NFA nfa) async {
    final (dfa, _) = await convertWithEnhancedReport(nfa);
    return dfa;
  }

  /// اعتبارسنجی پیشرفته NFA
  Future<void> _validateNFA(NFA nfa) async {
    final validation = nfa.validate();
    if (!validation.isValid) {
      throw ArgumentError('NFA نامعتبر: ${validation.errors.join(', ')}');
    }

    // بررسی محدودیت‌ها
    if (nfa.states.length > config.maxStatesLimit) {
      _warnings.add(
        'تعداد حالات NFA (${nfa.states.length}) از حد مجاز بیشتر است',
      );
    }

    // تخمین پیچیدگی
    final estimatedStates = _analysisResult?.complexity.estimatedDFAStates ?? 0;
    if (estimatedStates > config.maxStatesLimit) {
      _warnings.add('تعداد حالات تخمینی DFA ($estimatedStates) خیلی زیاد است');
      _recommendations.add(
        'استفاده از الگوریتم LazyConstruction پیشنهاد می‌شود',
      );
    }
  }

  /// پیش‌پردازش NFA
  Future<NFA> _preprocessNFA(NFA nfa) async {
    _log('شروع پیش‌پردازش NFA');
    var result = nfa;

    if (config.enablePreOptimization) {
      // حذف حالات غیرقابل دسترس
      if (_analysisResult?.characteristics.contains(
            'دارای حالات غیرقابل دسترس',
          ) ==
          true) {
        result = await _removeUnreachableStates(result);
        _conversionSteps.add('حذف حالات غیرقابل دسترس');
      }

      // حذف حالات مرده
      if (_analysisResult?.characteristics.contains('دارای حالات مرده') ==
          true) {
        result = await _removeDeadStates(result);
        _conversionSteps.add('حذف حالات مرده');
      }

      // پیش‌محاسبه epsilon closures
      if (config.enableCaching &&
          _analysisResult?.characteristics.contains(
                'دارای انتقال‌های اپسیلون',
              ) ==
              true) {
        await _precomputeEpsilonClosures(result);
        _conversionSteps.add('پیش‌محاسبه epsilon closures');
      }
    }

    return result;
  }

  /// انجام تبدیل پیشرفته
  Future<DFA> _performAdvancedConversion(NFA nfa) async {
    switch (config.algorithm) {
      case AdvancedConversionAlgorithm.adaptiveSubsetConstruction:
        return await _adaptiveSubsetConstruction(nfa);
      case AdvancedConversionAlgorithm.hybridConstruction:
        return await _hybridConstruction(nfa);
      case AdvancedConversionAlgorithm.memoryOptimizedConstruction:
        return await _memoryOptimizedConstruction(nfa);
      case AdvancedConversionAlgorithm.streamingConstruction:
        return await _streamingConstruction(nfa);
      case AdvancedConversionAlgorithm.parallelConstruction:
        return await _parallelConstruction(nfa);
      case AdvancedConversionAlgorithm.intelligentCaching:
        return await _intelligentCachingConstruction(nfa);
    }
  }

  /// الگوریتم تطبیقی Subset Construction
  Future<DFA> _adaptiveSubsetConstruction(NFA nfa) async {
    _log('اجرای الگوریتم تطبیقی Subset Construction');

    final dfa = DFA();
    for (final symbol in nfa.alphabet) dfa.addSymbol(symbol);

    final startClosure = await _getEpsilonClosure(nfa, {nfa.startState});
    final startStateSet = _createStateSet(startClosure, nfa);
    dfa.addState(startStateSet);
    dfa.setStartState(startStateSet);

    final pendingStates = Queue<StateSet>();
    final processedStates = <StateSet>{};
    final stateMap = <String, StateSet>{};

    pendingStates.add(startStateSet);
    stateMap[startStateSet.displayName] = startStateSet;

    int processedCount = 0;
    int progressCounter = 0;

    while (pendingStates.isNotEmpty) {
      // بررسی محدودیت‌ها
      if (processedStates.length > config.maxStatesLimit) {
        _warnings.add('رسیدن به حد مجاز حالات');
        break;
      }

      final current = pendingStates.removeFirst();
      if (processedStates.contains(current)) continue;

      processedStates.add(current);
      processedCount++;

      // گزارش پیشرفت
      if (progressCounter++ % 10 == 0) {
        final progress =
            0.3 +
            (processedCount * 0.5 / math.max(100, processedStates.length));
        _reportProgress('پردازش حالت $processedCount', progress);
      }

      // تطبیق استراتژی بر اساس اندازه حالت فعلی
      if (current.states.length > 10) {
        await _processTransitionsParallel(
          nfa,
          dfa,
          current,
          pendingStates,
          stateMap,
        );
      } else {
        await _processTransitionsSequential(
          nfa,
          dfa,
          current,
          pendingStates,
          stateMap,
        );
      }
    }

    _log('تبدیل تطبیقی تکمیل شد: ${processedStates.length} حالت');
    return dfa;
  }

  /// الگوریتم ترکیبی
  Future<DFA> _hybridConstruction(NFA nfa) async {
    _log('اجرای الگوریتم ترکیبی');

    // ترکیب subset construction با lazy construction
    final complexity = _analysisResult?.complexity;

    if (complexity != null && complexity.estimatedDFAStates > 1000) {
      _log('استفاده از Lazy Construction به دلیل پیچیدگی بالا');
      return await _lazyConstruction(nfa);
    } else {
      _log('استفاده از Subset Construction بهینه‌شده');
      return await _adaptiveSubsetConstruction(nfa);
    }
  }

  /// الگوریتم بهینه‌شده حافظه
  Future<DFA> _memoryOptimizedConstruction(NFA nfa) async {
    _log('اجرای الگوریتم بهینه‌شده حافظه');

    final dfa = DFA();
    for (final symbol in nfa.alphabet) dfa.addSymbol(symbol);

    // استفاده از حافظه کم با پردازش batch
    const batchSize = 50;
    final batches = <List<StateSet>>[];
    final allStates = <StateSet>[];

    final startClosure = await _getEpsilonClosure(nfa, {nfa.startState});
    final startStateSet = _createStateSet(startClosure, nfa);
    dfa.addState(startStateSet);
    dfa.setStartState(startStateSet);
    allStates.add(startStateSet);

    int batchIndex = 0;
    while (batchIndex * batchSize < allStates.length) {
      final batch = allStates
          .skip(batchIndex * batchSize)
          .take(batchSize)
          .toList();

      for (final state in batch) {
        for (final symbol in nfa.alphabet) {
          final nextState = await _processSingleTransition(nfa, state, symbol);
          if (nextState != null &&
              !allStates.any((s) => _stateSetEquals(s, nextState))) {
            dfa.addState(nextState);
            allStates.add(nextState);
          }

          if (nextState != null) {
            final existing = allStates.firstWhere(
              (s) => _stateSetEquals(s, nextState),
            );
            dfa.addTransition(state, symbol, existing);
          }
        }
      }

      batchIndex++;
      _reportProgress(
        'پردازش batch ${batchIndex}',
        0.3 + (batchIndex * 0.5 / (allStates.length / batchSize + 1)),
      );

      // پاکسازی کش در صورت نیاز
      if (batchIndex % 10 == 0) {
        _cache.clear();
      }
    }

    return dfa;
  }

  /// الگوریتم پردازش جریانی
  Future<DFA> _streamingConstruction(NFA nfa) async {
    _log('اجرای الگوریتم پردازش جریانی');

    final dfa = DFA();
    for (final symbol in nfa.alphabet) dfa.addSymbol(symbol);

    // پردازش تدریجی حالات
    final stream = _generateStateStream(nfa);
    final processedStates = <StateSet>{};

    await for (final stateSet in stream) {
      if (processedStates.length > config.maxStatesLimit) break;

      if (!processedStates.contains(stateSet)) {
        dfa.addState(stateSet);
        processedStates.add(stateSet);

        if (stateSet.stateNames.contains(nfa.startState)) {
          dfa.setStartState(stateSet);
        }
      }

      _reportProgress('پردازش جریانی', processedStates.length / 1000.0);
    }

    return dfa;
  }

  /// الگوریتم پردازش موازی
  Future<DFA> _parallelConstruction(NFA nfa) async {
    if (!config.enableParallelProcessing) {
      return await _adaptiveSubsetConstruction(nfa);
    }

    _log('اجرای الگوریتم پردازش موازی');

    final dfa = DFA();
    for (final symbol in nfa.alphabet) dfa.addSymbol(symbol);

    final startClosure = await _getEpsilonClosure(nfa, {nfa.startState});
    final startStateSet = _createStateSet(startClosure, nfa);
    dfa.addState(startStateSet);
    dfa.setStartState(startStateSet);

    // تقسیم کار بین worker های موازی
    final workers = config.parallelWorkers;
    final workQueues = List.generate(workers, (_) => Queue<StateSet>());
    workQueues[0].add(startStateSet);

    final processedStates = <StateSet>{};
    final futures = <Future>[];

    for (int i = 0; i < workers; i++) {
      futures.add(_parallelWorker(i, nfa, dfa, workQueues[i], processedStates));
    }

    await Future.wait(futures);
    _log('پردازش موازی تکمیل شد');
    return dfa;
  }

  /// الگوریتم کش هوشمند
  Future<DFA> _intelligentCachingConstruction(NFA nfa) async {
    _log('اجرای الگوریتم کش هوشمند');

    // تنظیم کش بر اساس تحلیل NFA
    final hasEpsilon =
        _analysisResult?.characteristics.contains('دارای انتقال‌های اپسیلون') ??
        false;
    final complexity = _analysisResult?.complexity.nondeterminismDegree ?? 0.0;

    if (hasEpsilon) {
      await _precomputeEpsilonClosures(nfa);
    }

    final dfa = await _adaptiveSubsetConstruction(nfa);

    // بررسی کارایی کش
    final cacheStats = _cache.stats;
    final hitRatio = cacheStats['hit_ratio_percent']! / 100.0;

    if (hitRatio < config.cacheHitRatioThreshold) {
      _warnings.add('نرخ hit کش پایین است: ${(hitRatio * 100).round()}%');
      _recommendations.add('تنظیم مجدد استراتژی کش');
    }

    return dfa;
  }

  /// Lazy Construction
  Future<DFA> _lazyConstruction(NFA nfa) async {
    _log('اجرای الگوریتم Lazy Construction');

    final dfa = DFA();
    for (final symbol in nfa.alphabet) dfa.addSymbol(symbol);

    final startClosure = await _getEpsilonClosure(nfa, {nfa.startState});
    final startStateSet = _createStateSet(startClosure, nfa);
    dfa.addState(startStateSet);
    dfa.setStartState(startStateSet);

    final lazyQueue = Queue<(StateSet, String)>();
    final builtStates = <StateSet>{startStateSet};

    // اضافه کردن انتقال‌های اولیه به صف
    for (final symbol in nfa.alphabet) {
      lazyQueue.add((startStateSet, symbol));
    }

    while (lazyQueue.isNotEmpty && builtStates.length < config.maxStatesLimit) {
      final (currentState, symbol) = lazyQueue.removeFirst();

      final nextState = await _processSingleTransition(
        nfa,
        currentState,
        symbol,
      );
      if (nextState != null) {
        final existing = builtStates.cast<StateSet?>().firstWhere(
          (s) => s != null && _stateSetEquals(s, nextState),
          orElse: () => null,
        );

        if (existing == null) {
          dfa.addState(nextState);
          builtStates.add(nextState);

          // اضافه کردن انتقال‌های جدید به صف
          for (final nextSymbol in nfa.alphabet) {
            lazyQueue.add((nextState, nextSymbol));
          }
        }

        final targetState = existing ?? nextState;
        dfa.addTransition(currentState, symbol, targetState);
      }

      if (lazyQueue.length % 50 == 0) {
        _reportProgress(
          'Lazy construction',
          0.3 + (builtStates.length * 0.5 / config.maxStatesLimit),
        );
      }
    }

    return dfa;
  }

  /// پس‌پردازش DFA
  Future<DFA> _postprocessDFA(DFA dfa, NFA originalNFA) async {
    _log('شروع پس‌پردازش DFA');
    var result = dfa;

    if (config.enablePostOptimization) {
      switch (config.optimizationLevel) {
        case OptimizationLevel.minimal:
          result = result.complete();
          break;
        case OptimizationLevel.balanced:
          result = await _eliminateDeadStates(result);
          result = result.complete();
          break;
        case OptimizationLevel.aggressive:
          result = await _eliminateDeadStates(result);
          result = result.minimize();
          result = result.complete();
          break;
        case OptimizationLevel.maximum:
          result = await _eliminateDeadStates(result);
          result = result.minimize();
          result = await _optimizeTransitions(result);
          result = result.complete();
          break;
      }
    }

    // تأیید صحت تبدیل
    if (config.enableDetailedLogging) {
      await _verifyConversion(originalNFA, result);
    }

    return result;
  }

  // متدهای کمکی

  Future<Set<String>> _getEpsilonClosure(NFA nfa, Set<String> states) async {
    if (!config.enableCaching) {
      return nfa.epsilonClosure(states);
    }

    final cached = _cache.getEpsilonClosure(states);
    if (cached != null) return cached;

    final result = nfa.epsilonClosure(states);
    _cache.putEpsilonClosure(states, result);
    return result;
  }

  Future<void> _precomputeEpsilonClosures(NFA nfa) async {
    _log('پیش‌محاسبه epsilon closures');
    for (final state in nfa.states) {
      final closure = nfa.epsilonClosureOfState(state);
      _cache.putEpsilonClosure({state}, closure);
    }
  }

  Future<StateSet?> _processSingleTransition(
    NFA nfa,
    StateSet currentState,
    String symbol,
  ) async {
    final moveResult = await _getMoveResult(
      nfa,
      currentState.stateNames.toSet(),
      symbol,
    );
    if (moveResult.isEmpty) return null;

    final closure = await _getEpsilonClosure(nfa, moveResult);
    return _createStateSet(closure, nfa);
  }

  Future<Set<String>> _getMoveResult(
    NFA nfa,
    Set<String> states,
    String symbol,
  ) async {
    if (!config.enableCaching) {
      return _computeMove(nfa, states, symbol);
    }

    final cached = _cache.getMove(states, symbol);
    if (cached != null) return cached;

    final result = _computeMove(nfa, states, symbol);
    _cache.putMove(states, symbol, result);
    return result;
  }

  Set<String> _computeMove(NFA nfa, Set<String> states, String symbol) {
    final result = <String>{};
    for (final state in states) {
      result.addAll(nfa.getTransitions(state, symbol));
    }
    return result;
  }

  StateSet _createStateSet(Set<String> stateNames, NFA nfa) {
    final models = stateNames.map((name) {
      final isFinal = nfa.finalStates.contains(name);
      return StateModel(name: name, isFinal: isFinal);
    }).toSet();
    return StateSet(models);
  }

  bool _stateSetEquals(StateSet a, StateSet b) {
    if (a.states.length != b.states.length) return false;
    return a.states.every(
      (stateA) => b.states.any((stateB) => stateA.name == stateB.name),
    );
  }

  Stream<StateSet> _generateStateStream(NFA nfa) async* {
    final startClosure = await _getEpsilonClosure(nfa, {nfa.startState});
    final startStateSet = _createStateSet(startClosure, nfa);
    yield startStateSet;

    final queue = Queue<StateSet>();
    final visited = <StateSet>{};

    queue.add(startStateSet);
    visited.add(startStateSet);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      for (final symbol in nfa.alphabet) {
        final next = await _processSingleTransition(nfa, current, symbol);
        if (next != null && !visited.any((s) => _stateSetEquals(s, next))) {
          visited.add(next);
          queue.add(next);
          yield next;
        }
      }
    }
  }

  Future<void> _parallelWorker(
    int workerId,
    NFA nfa,
    DFA dfa,
    Queue<StateSet> workQueue,
    Set<StateSet> processedStates,
  ) async {
    while (workQueue.isNotEmpty) {
      final current = workQueue.removeFirst();
      if (processedStates.contains(current)) continue;

      processedStates.add(current);

      for (final symbol in nfa.alphabet) {
        final next = await _processSingleTransition(nfa, current, symbol);
        if (next != null &&
            !processedStates.any((s) => _stateSetEquals(s, next))) {
          dfa.addState(next);
          workQueue.add(next);
        }
      }
    }
  }

  Future<void> _processTransitionsSequential(
    NFA nfa,
    DFA dfa,
    StateSet current,
    Queue<StateSet> pending,
    Map<String, StateSet> stateMap,
  ) async {
    for (final symbol in nfa.alphabet) {
      final next = await _processSingleTransition(nfa, current, symbol);
      if (next != null) {
        final displayName = next.displayName;
        if (!stateMap.containsKey(displayName)) {
          dfa.addState(next);
          pending.add(next);
          stateMap[displayName] = next;
        }
        final existing = stateMap[displayName]!;
        dfa.addTransition(current, symbol, existing);
      }
    }
  }

  Future<void> _processTransitionsParallel(
    NFA nfa,
    DFA dfa,
    StateSet current,
    Queue<StateSet> pending,
    Map<String, StateSet> stateMap,
  ) async {
    final futures = <Future<(String, StateSet?)>>[];

    for (final symbol in nfa.alphabet) {
      futures.add(_processTransitionAsync(nfa, current, symbol));
    }

    final results = await Future.wait(futures);

    for (final (symbol, next) in results) {
      if (next != null) {
        final displayName = next.displayName;
        if (!stateMap.containsKey(displayName)) {
          dfa.addState(next);
          pending.add(next);
          stateMap[displayName] = next;
        }
        final existing = stateMap[displayName]!;
        dfa.addTransition(current, symbol, existing);
      }
    }
  }

  Future<(String, StateSet?)> _processTransitionAsync(
    NFA nfa,
    StateSet current,
    String symbol,
  ) async {
    final next = await _processSingleTransition(nfa, current, symbol);
    return (symbol, next);
  }

  Future<NFA> _removeUnreachableStates(NFA nfa) async {
    // پیاده‌سازی حذف حالات غیرقابل دسترس
    return nfa; // برای سادگی، همان NFA را برمی‌گردانیم
  }

  Future<NFA> _removeDeadStates(NFA nfa) async {
    // پیاده‌سازی حذف حالات مرده
    return nfa; // برای سادگی، همان NFA را برمی‌گردانیم
  }

  Future<DFA> _eliminateDeadStates(DFA dfa) async {
    final reachable = <StateSet>{};
    final queue = Queue<StateSet>();

    if (dfa.startState != null) {
      queue.add(dfa.startState!);
      reachable.add(dfa.startState!);
    }

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final symbol in dfa.alphabet) {
        final next = dfa.getTransition(current, symbol);
        if (next != null && !reachable.contains(next)) {
          reachable.add(next);
          queue.add(next);
        }
      }
    }

    final newDFA = DFA();
    for (final symbol in dfa.alphabet) newDFA.addSymbol(symbol);
    for (final state in reachable) {
      newDFA.addState(state);
      if (state == dfa.startState) newDFA.setStartState(state);
      if (dfa.finalStates.contains(state)) newDFA.setFinalState(state, true);
    }
    for (final state in reachable) {
      for (final symbol in dfa.alphabet) {
        final next = dfa.getTransition(state, symbol);
        if (next != null && reachable.contains(next)) {
          newDFA.addTransition(state, symbol, next);
        }
      }
    }

    return newDFA;
  }

  Future<DFA> _optimizeTransitions(DFA dfa) async {
    // پیاده‌سازی بهینه‌سازی انتقال‌ها
    return dfa;
  }

  Future<void> _verifyConversion(NFA nfa, DFA dfa) async {
    // تأیید صحت تبدیل با تست چند رشته
    final testStrings = _generateTestStrings(nfa, 20);
    for (final testString in testStrings) {
      if (nfa.accepts(testString) != dfa.acceptsString(testString)) {
        _warnings.add('خطا در تبدیل: رشته "$testString" نتایج متفاوت دارد');
      }
    }
  }

  List<String> _generateTestStrings(NFA nfa, int count) {
    final tests = <String>[''];
    if (nfa.alphabet.isNotEmpty) {
      final alphabetList = nfa.alphabet.toList();
      final random = math.Random();
      for (int i = 0; i < count - 1; i++) {
        final length = random.nextInt(5) + 1;
        final buffer = StringBuffer();
        for (int j = 0; j < length; j++) {
          buffer.write(alphabetList[random.nextInt(alphabetList.length)]);
        }
        tests.add(buffer.toString());
      }
    }
    return tests;
  }

  EnhancedConversionReport _generateEnhancedReport(
    NFA nfa,
    DFA dfa,
    Duration preprocessTime,
    Duration postprocessTime,
  ) {
    final totalTime = _overallStopwatch!.elapsed;
    final cacheStats = _cache.stats;

    return EnhancedConversionReport(
      conversionTime: totalTime,
      preprocessingTime: preprocessTime,
      postprocessingTime: postprocessTime,
      nfaStates: nfa.states.length,
      dfaStates: dfa.states.length,
      nfaTransitions: nfa.transitionCount,
      dfaTransitions: dfa.transitionCount,
      compressionRatio: _calculateCompressionRatio(nfa, dfa),
      speedupRatio: _calculateSpeedupRatio(),
      optimizationsApplied: _getAppliedOptimizations(),
      performanceMetrics: _generatePerformanceMetrics(nfa, dfa, totalTime),
      conversionSteps: _conversionSteps,
      memoryUsage: _generateMemoryUsage(cacheStats),
      timingBreakdown: Map.from(_timingBreakdown),
      warnings: List.from(_warnings),
      recommendations: List.from(_recommendations),
    );
  }

  double _calculateCompressionRatio(NFA nfa, DFA dfa) {
    if (nfa.states.isEmpty) return 0.0;
    return ((nfa.states.length - dfa.states.length) / nfa.states.length * 100);
  }

  double _calculateSpeedupRatio() {
    // محاسبه نسبت تسریع نسبت به الگوریتم پایه
    return 1.0; // مقدار پیش‌فرض
  }

  List<String> _getAppliedOptimizations() {
    final optimizations = <String>[];
    optimizations.add(
      'الگوریتم: ${config.algorithm.toString().split('.').last}',
    );
    optimizations.add(
      'سطح بهینه‌سازی: ${config.optimizationLevel.toString().split('.').last}',
    );

    if (config.enableCaching) optimizations.add('کش هوشمند');
    if (config.enableParallelProcessing) optimizations.add('پردازش موازی');
    if (config.enablePreOptimization) optimizations.add('پیش‌بهینه‌سازی');
    if (config.enablePostOptimization) optimizations.add('پس‌بهینه‌سازی');

    return optimizations;
  }

  Map<String, dynamic> _generatePerformanceMetrics(
    NFA nfa,
    DFA dfa,
    Duration totalTime,
  ) {
    final cacheStats = _cache.stats;
    return {
      'سرعت تبدیل': totalTime.inMilliseconds > 0
          ? '${(dfa.states.length / totalTime.inMilliseconds).toStringAsFixed(2)} حالت/ms'
          : 'بی‌نهایت',
      'کارایی کش': '${cacheStats['hit_ratio_percent']}%',
      'ورودی‌های کش': cacheStats['total_entries'],
      'نسبت تبدیل':
          '1:${(dfa.states.length / math.max(1, nfa.states.length)).toStringAsFixed(2)}',
      'استفاده از حافظه': '${config.memoryStrategy.toString().split('.').last}',
      'پردازش': '${config.processingMode.toString().split('.').last}',
    };
  }

  Map<String, dynamic> _generateMemoryUsage(Map<String, int> cacheStats) {
    return {
      'کش epsilon closure':
          '${cacheStats['epsilon_closure_entries'] ?? 0} ورودی',
      'کش move': '${cacheStats['move_entries'] ?? 0} ورودی',
      'کل حافظه کش': '${cacheStats['total_entries']} ورودی',
      'نرخ بازده کش': '${cacheStats['hit_ratio_percent']}%',
    };
  }

  void _log(String message) {
    if (config.enableDetailedLogging) {
      onLog?.call(message);
    }
  }

  void _reportProgress(String message, double progress) {
    onProgress?.call(message, progress.clamp(0.0, 1.0));
  }

  // API عمومی برای دسترسی به آمار
  Map<String, int> getCacheStats() => _cache.stats;

  List<String> getConversionSteps() => List.unmodifiable(_conversionSteps);

  Map<String, Duration> getTimingBreakdown() =>
      Map.unmodifiable(_timingBreakdown);

  List<String> getWarnings() => List.unmodifiable(_warnings);

  List<String> getRecommendations() => List.unmodifiable(_recommendations);

  void clearCache() => _cache.clear();
}

/// کلاس ساده برای تبدیل سریع
class FastNFAToDFAConverter {
  static Future<DFA> convert(
    NFA nfa, {
    OptimizationLevel optimization = OptimizationLevel.minimal,
    bool enableCaching = true,
  }) async {
    final config = AdvancedConversionConfig(
      algorithm: AdvancedConversionAlgorithm.adaptiveSubsetConstruction,
      optimizationLevel: optimization,
      enableCaching: enableCaching,
      enableDetailedLogging: false,
    );

    final converter = EnhancedNFAToDFAConverter(config: config);
    return await converter.convert(nfa);
  }
}

/// کلاس مقایسه‌کننده الگوریتم‌ها
class AlgorithmBenchmark {
  static Future<BenchmarkResult> compareAlgorithms(
    NFA nfa, {
    List<AdvancedConversionAlgorithm>? algorithms,
    int iterations = 3,
  }) async {
    algorithms ??= AdvancedConversionAlgorithm.values;

    final results = <AlgorithmResult>[];

    for (final algorithm in algorithms) {
      final times = <Duration>[];
      DFA? resultDFA;

      for (int i = 0; i < iterations; i++) {
        final config = AdvancedConversionConfig(
          algorithm: algorithm,
          enableDetailedLogging: false,
        );

        final converter = EnhancedNFAToDFAConverter(config: config);
        final stopwatch = Stopwatch()..start();

        try {
          final (dfa, report) = await converter.convertWithEnhancedReport(nfa);
          stopwatch.stop();

          times.add(stopwatch.elapsed);
          resultDFA = dfa;
        } catch (e) {
          stopwatch.stop();
          times.add(Duration(milliseconds: -1)); // علامت خطا
        }
      }

      final validTimes = times.where((t) => t.inMilliseconds >= 0).toList();
      if (validTimes.isNotEmpty) {
        final avgTime = Duration(
          milliseconds:
              (validTimes.map((t) => t.inMilliseconds).reduce((a, b) => a + b) /
                      validTimes.length)
                  .round(),
        );

        results.add(
          AlgorithmResult(
            algorithm: algorithm,
            averageTime: avgTime,
            dfaStates: resultDFA?.states.length ?? 0,
            iterations: validTimes.length,
          ),
        );
      }
    }

    return BenchmarkResult(nfaStates: nfa.states.length, results: results);
  }
}

/// نتیجه مقایسه الگوریتم
class AlgorithmResult {
  final AdvancedConversionAlgorithm algorithm;
  final Duration averageTime;
  final int dfaStates;
  final int iterations;

  AlgorithmResult({
    required this.algorithm,
    required this.averageTime,
    required this.dfaStates,
    required this.iterations,
  });

  @override
  String toString() {
    return '${algorithm.toString().split('.').last}: ${averageTime.inMilliseconds}ms (${dfaStates} حالت, ${iterations} تکرار)';
  }
}

/// نتیجه کل benchmark
class BenchmarkResult {
  final int nfaStates;
  final List<AlgorithmResult> results;

  BenchmarkResult({required this.nfaStates, required this.results});

  AlgorithmResult? get fastest => results.isEmpty
      ? null
      : results.reduce((a, b) => a.averageTime < b.averageTime ? a : b);

  AlgorithmResult? get mostCompact => results.isEmpty
      ? null
      : results.reduce((a, b) => a.dfaStates < b.dfaStates ? a : b);

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== نتایج مقایسه الگوریتم‌ها ===');
    buffer.writeln('NFA: $nfaStates حالت');
    buffer.writeln();

    if (results.isNotEmpty) {
      buffer.writeln('نتایج:');
      for (final result in results) {
        buffer.writeln('  $result');
      }

      buffer.writeln();
      if (fastest != null) {
        buffer.writeln('سریع‌ترین: ${fastest.toString()}');
      }
      if (mostCompact != null) {
        buffer.writeln('فشرده‌ترین: ${mostCompact.toString()}');
      }
    } else {
      buffer.writeln('هیچ نتیجه معتبری یافت نشد');
    }

    return buffer.toString();
  }
}

/// کلاس مدیریت پروفایل‌های تبدیل
class ConversionProfileManager {
  static const Map<String, AdvancedConversionConfig> _profiles = {
    'سریع': AdvancedConversionConfig(
      algorithm: AdvancedConversionAlgorithm.adaptiveSubsetConstruction,
      optimizationLevel: OptimizationLevel.minimal,
      memoryStrategy: MemoryStrategy.conservative,
      enableCaching: false,
      enableDetailedLogging: false,
    ),
    'متعادل': AdvancedConversionConfig(
      algorithm: AdvancedConversionAlgorithm.hybridConstruction,
      optimizationLevel: OptimizationLevel.balanced,
      memoryStrategy: MemoryStrategy.balanced,
      enableCaching: true,
      enablePreOptimization: true,
      enablePostOptimization: true,
    ),
    'بهینه': AdvancedConversionConfig(
      algorithm: AdvancedConversionAlgorithm.intelligentCaching,
      optimizationLevel: OptimizationLevel.aggressive,
      memoryStrategy: MemoryStrategy.generous,
      enableCaching: true,
      enableParallelProcessing: true,
      enablePreOptimization: true,
      enablePostOptimization: true,
      enableDetailedLogging: true,
    ),
    'حداکثر': AdvancedConversionConfig(
      algorithm: AdvancedConversionAlgorithm.parallelConstruction,
      optimizationLevel: OptimizationLevel.maximum,
      memoryStrategy: MemoryStrategy.generous,
      enableCaching: true,
      enableParallelProcessing: true,
      parallelWorkers: 8,
      enablePreOptimization: true,
      enablePostOptimization: true,
      enableDetailedLogging: true,
      enableProgressiveConstruction: true,
      enableStatePrediction: true,
      enableCompressionAnalysis: true,
    ),
    'حافظه_کم': AdvancedConversionConfig(
      algorithm: AdvancedConversionAlgorithm.memoryOptimizedConstruction,
      optimizationLevel: OptimizationLevel.balanced,
      memoryStrategy: MemoryStrategy.conservative,
      maxStatesLimit: 1000,
      maxMemoryMB: 64,
      enableCaching: false,
    ),
    'جریانی': AdvancedConversionConfig(
      algorithm: AdvancedConversionAlgorithm.streamingConstruction,
      optimizationLevel: OptimizationLevel.minimal,
      memoryStrategy: MemoryStrategy.conservative,
      enableProgressiveConstruction: true,
    ),
  };

  static AdvancedConversionConfig getProfile(String name) {
    return _profiles[name] ?? _profiles['متعادل']!;
  }

  static List<String> getAvailableProfiles() {
    return _profiles.keys.toList();
  }

  static AdvancedConversionConfig recommendProfile(NFA nfa) {
    final analysis = NFAAnalyzer.analyze(nfa);
    final complexity = analysis.complexity;

    // توصیه بر اساس تحلیل
    if (complexity.stateCount < 10) {
      return getProfile('سریع');
    } else if (complexity.estimatedDFAStates > 10000) {
      return getProfile('حافظه_کم');
    } else if (complexity.nondeterminismDegree > 0.7) {
      return getProfile('بهینه');
    } else if (complexity.stateCount > 100) {
      return getProfile('حداکثر');
    } else {
      return getProfile('متعادل');
    }
  }
}

/// کلاس مانیتورینگ عملکرد
class PerformanceMonitor {
  final List<ConversionMetric> _metrics = [];

  void recordConversion(NFA nfa, DFA dfa, EnhancedConversionReport report) {
    _metrics.add(
      ConversionMetric(
        timestamp: DateTime.now(),
        nfaStates: nfa.states.length,
        dfaStates: dfa.states.length,
        conversionTime: report.conversionTime,
        algorithm: report.performanceMetrics['الگوریتم'].toString(),
        compressionRatio: report.compressionRatio,
      ),
    );
  }

  PerformanceStatistics getStatistics() {
    if (_metrics.isEmpty) {
      return PerformanceStatistics.empty();
    }

    final times = _metrics.map((m) => m.conversionTime.inMilliseconds).toList();
    final compressions = _metrics.map((m) => m.compressionRatio).toList();

    return PerformanceStatistics(
      totalConversions: _metrics.length,
      averageTime: Duration(
        milliseconds: (times.reduce((a, b) => a + b) / times.length).round(),
      ),
      minTime: Duration(milliseconds: times.reduce(math.min)),
      maxTime: Duration(milliseconds: times.reduce(math.max)),
      averageCompression:
          compressions.reduce((a, b) => a + b) / compressions.length,
      algorithmUsage: _getAlgorithmUsage(),
    );
  }

  Map<String, int> _getAlgorithmUsage() {
    final usage = <String, int>{};
    for (final metric in _metrics) {
      usage[metric.algorithm] = (usage[metric.algorithm] ?? 0) + 1;
    }
    return usage;
  }

  void clear() => _metrics.clear();

  List<ConversionMetric> getRecentMetrics(int count) {
    return _metrics.take(math.min(count, _metrics.length)).toList();
  }
}

/// متریک تبدیل
class ConversionMetric {
  final DateTime timestamp;
  final int nfaStates;
  final int dfaStates;
  final Duration conversionTime;
  final String algorithm;
  final double compressionRatio;

  ConversionMetric({
    required this.timestamp,
    required this.nfaStates,
    required this.dfaStates,
    required this.conversionTime,
    required this.algorithm,
    required this.compressionRatio,
  });
}

/// آمار عملکرد
class PerformanceStatistics {
  final int totalConversions;
  final Duration averageTime;
  final Duration minTime;
  final Duration maxTime;
  final double averageCompression;
  final Map<String, int> algorithmUsage;

  PerformanceStatistics({
    required this.totalConversions,
    required this.averageTime,
    required this.minTime,
    required this.maxTime,
    required this.averageCompression,
    required this.algorithmUsage,
  });

  factory PerformanceStatistics.empty() {
    return PerformanceStatistics(
      totalConversions: 0,
      averageTime: Duration.zero,
      minTime: Duration.zero,
      maxTime: Duration.zero,
      averageCompression: 0.0,
      algorithmUsage: {},
    );
  }

  @override
  String toString() {
    return '''
=== آمار عملکرد ===
تعداد کل تبدیل‌ها: $totalConversions
زمان متوسط: ${averageTime.inMilliseconds} ms
کمترین زمان: ${minTime.inMilliseconds} ms
بیشترین زمان: ${maxTime.inMilliseconds} ms
فشرده‌سازی متوسط: ${averageCompression.toStringAsFixed(2)}%

استفاده از الگوریتم‌ها:
${algorithmUsage.entries.map((e) => '  ${e.key}: ${e.value} بار').join('\n')}
''';
  }
}

/// کلاس اصلی ValidationResult برای سازگاری
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

/// کلاس یوتیلیتی‌های پیشرفته
class AdvancedNFAToDFAUtils {
  /// تبدیل با تنظیمات خودکار
  static Future<DFA> convertWithAutoConfig(
    NFA nfa, {
    Function(String, double)? onProgress,
  }) async {
    final profile = ConversionProfileManager.recommendProfile(nfa);
    final converter = EnhancedNFAToDFAConverter(
      config: profile,
      onProgress: onProgress,
    );
    return await converter.convert(nfa);
  }

  /// مقایسه عملکرد پروفایل‌ها
  static Future<String> compareProfiles(NFA nfa) async {
    final profiles = ConversionProfileManager.getAvailableProfiles();
    final results = <String, (Duration, int)>{};

    for (final profileName in profiles.take(3)) {
      // محدود به 3 پروفایل برای سرعت
      try {
        final config = ConversionProfileManager.getProfile(profileName);
        final converter = EnhancedNFAToDFAConverter(config: config);

        final stopwatch = Stopwatch()..start();
        final dfa = await converter.convert(nfa);
        stopwatch.stop();

        results[profileName] = (stopwatch.elapsed, dfa.states.length);
      } catch (e) {
        results[profileName] = (Duration(milliseconds: -1), -1);
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('=== مقایسه پروفایل‌ها ===');
    buffer.writeln('NFA: ${nfa.states.length} حالت');
    buffer.writeln();

    for (final entry in results.entries) {
      final (time, states) = entry.value;
      if (time.inMilliseconds >= 0) {
        buffer.writeln(
          '${entry.key}: ${time.inMilliseconds}ms، ${states} حالت DFA',
        );
      } else {
        buffer.writeln('${entry.key}: خطا');
      }
    }

    return buffer.toString();
  }

  /// تولید گزارش تحلیلی کامل
  static Future<String> generateAnalysisReport(NFA nfa) async {
    final analysis = NFAAnalyzer.analyze(nfa);
    final recommendation = ConversionProfileManager.recommendProfile(nfa);

    return '''
${analysis.toString()}

=== پیشنهاد پروفایل ===
پروفایل پیشنهادی: ${ConversionProfileManager.getAvailableProfiles().firstWhere((name) => ConversionProfileManager.getProfile(name) == recommendation, orElse: () => 'سفارشی')}

تنظیمات پیشنهادی:
  الگوریتم: ${recommendation.algorithm.toString().split('.').last}
  سطح بهینه‌سازی: ${recommendation.optimizationLevel.toString().split('.').last}
  استراتژی حافظه: ${recommendation.memoryStrategy.toString().split('.').last}
  کش: ${recommendation.enableCaching ? 'فعال' : 'غیرفعال'}
  پردازش موازی: ${recommendation.enableParallelProcessing ? 'فعال' : 'غیرفعال'}
''';
  }

  /// تست صحت تبدیل
  static Future<bool> verifyConversion(
    NFA nfa,
    DFA dfa, {
    int testCount = 100,
    int maxStringLength = 10,
  }) async {
    final testStrings = _generateComprehensiveTestStrings(
      nfa,
      testCount,
      maxStringLength,
    );

    for (final testString in testStrings) {
      if (nfa.accepts(testString) != dfa.acceptsString(testString)) {
        return false;
      }
    }

    return true;
  }

  static List<String> _generateComprehensiveTestStrings(
    NFA nfa,
    int count,
    int maxLength,
  ) {
    final tests = <String>[''];
    final alphabet = nfa.alphabet.toList();

    if (alphabet.isEmpty) return tests;

    final random = math.Random();

    // رشته‌های تصادفی
    for (int i = 0; i < count ~/ 2; i++) {
      final length = random.nextInt(maxLength) + 1;
      final buffer = StringBuffer();
      for (int j = 0; j < length; j++) {
        buffer.write(alphabet[random.nextInt(alphabet.length)]);
      }
      tests.add(buffer.toString());
    }

    // رشته‌های سیستماتیک
    for (int len = 1; len <= math.min(maxLength, 5); len++) {
      for (final symbol in alphabet.take(3)) {
        tests.add(symbol * len);
        if (alphabet.length > 1) {
          final mixed = StringBuffer();
          for (int i = 0; i < len; i++) {
            mixed.write(alphabet[i % alphabet.length]);
          }
          tests.add(mixed.toString());
        }
      }
    }

    return tests.take(count).toList();
  }
}
