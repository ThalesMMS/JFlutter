import 'dart:collection';
import 'dart:async';
import 'dart:math';
import '../models/nfa.dart';
import '../models/dfa.dart';
import '../models/state_model.dart';

class UnionResult {
  final DFA resultDfa;
  final AutomatonMetrics metrics;
  final Duration processingTime;
  final int statesReduced;
  final bool wasOptimized;

  const UnionResult({
    required this.resultDfa,
    required this.metrics,
    required this.processingTime,
    this.statesReduced = 0,
    this.wasOptimized = false,
  });
}

class IntersectionResult {
  final DFA resultDfa;
  final AutomatonMetrics metrics;
  final Duration processingTime;
  final int originalStatesCount;
  final bool isEmpty;

  const IntersectionResult({
    required this.resultDfa,
    required this.metrics,
    required this.processingTime,
    this.originalStatesCount = 0,
    this.isEmpty = false,
  });
}

class ConcatenationResult {
  final NFA resultNfa;
  final Duration processingTime;
  final int epsilonTransitionsAdded;
  final bool hasOptimizedPath;

  const ConcatenationResult({
    required this.resultNfa,
    required this.processingTime,
    this.epsilonTransitionsAdded = 0,
    this.hasOptimizedPath = false,
  });
}

class KleeneStarResult {
  final NFA resultNfa;
  final Duration processingTime;
  final bool hasCycleDetection;
  final int cyclesFound;

  const KleeneStarResult({
    required this.resultNfa,
    required this.processingTime,
    this.hasCycleDetection = false,
    this.cyclesFound = 0,
  });
}

class ComplementResult {
  final DFA complementDfa;
  final AutomatonMetrics originalMetrics;
  final AutomatonMetrics complementMetrics;
  final Duration processingTime;
  final int trapStatesAdded;

  const ComplementResult({
    required this.complementDfa,
    required this.originalMetrics,
    required this.complementMetrics,
    required this.processingTime,
    this.trapStatesAdded = 0,
  });
}

class PerformanceMonitor {
  static final Map<String, List<Duration>> _operationTimes = {};

  static void recordOperation(String operation, Duration time) {
    _operationTimes.putIfAbsent(operation, () => []).add(time);
  }

  static Duration getAverageTime(String operation) {
    final times = _operationTimes[operation] ?? [];
    if (times.isEmpty) return Duration.zero;

    final totalMs =
        times.fold<int>(0, (sum, time) => sum + time.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ times.length);
  }

  static void clearHistory() => _operationTimes.clear();
}

// --- Cache System ---

class AutomatonCache {
  static final Map<String, DFA> _dfaCache = {};
  static final Map<String, Set<String>> _epsilonClosureCache = {};
  static const int maxCacheSize = 100;

  static String _generateNfaHash(NFA nfa) {
    return '${nfa.states.length}_${nfa.alphabet.length}_${nfa.startState}_${nfa.finalStates.length}';
  }

  static DFA? getCachedDfa(NFA nfa) {
    final hash = _generateNfaHash(nfa);
    return _dfaCache[hash];
  }

  static void cacheDfa(NFA nfa, DFA dfa) {
    if (_dfaCache.length >= maxCacheSize) {
      _dfaCache.remove(_dfaCache.keys.first);
    }
    final hash = _generateNfaHash(nfa);
    _dfaCache[hash] = dfa;
  }

  static Set<String>? getCachedEpsilonClosure(String state) {
    return _epsilonClosureCache[state];
  }

  static void cacheEpsilonClosure(String state, Set<String> closure) {
    if (_epsilonClosureCache.length >= maxCacheSize * 2) {
      _epsilonClosureCache.remove(_epsilonClosureCache.keys.first);
    }
    _epsilonClosureCache[state] = Set.from(closure);
  }

  static void clearCache() {
    _dfaCache.clear();
    _epsilonClosureCache.clear();
  }
}

/// کلاس پیشرفته برای عملیات اتوماتا با قابلیت‌های بهینه‌سازی و مانیتورینگ
class EnhancedAutomatonOperations {
  // --- تنظیمات بهینه‌سازی ---
  static bool enableCaching = true;
  static bool enableParallelProcessing = true;
  static bool enableMinimization = true;
  static int maxProcessingTime = 30000; // milliseconds

  /// الگوریتم پیشرفته تبدیل NFA به DFA با کش و بهینه‌سازی
  DFA _convertNfaToDfaAdvanced(NFA nfa) {
    // بررسی کش
    if (enableCaching) {
      final cachedDfa = AutomatonCache.getCachedDfa(nfa);
      if (cachedDfa != null) return cachedDfa;
    }

    final stopwatch = Stopwatch()..start();
    final dfa = DFA.empty();

    // بررسی‌های اولیه
    if (nfa.startState.isEmpty) {
      stopwatch.stop();
      return dfa;
    }

    try {
      dfa.addSymbols(nfa.alphabet);

      final stateQueue = Queue<Set<String>>();
      final visitedStates = <String, Set<String>>{}; // بهینه‌سازی مقایسه
      final dfaStates = <String, StateSet>{};

      // ایجاد حالت شروع
      final startStateNFA = _getEpsilonClosureOptimized(nfa, nfa.startState);
      final startStateKey = _generateStateKey(startStateNFA);
      final startStateDFA = _createStateSet(startStateNFA);

      dfa.addState(startStateDFA);
      dfa.setStartState(startStateDFA);

      stateQueue.add(startStateNFA);
      visitedStates[startStateKey] = startStateNFA;
      dfaStates[startStateKey] = startStateDFA;

      // الگوریتم اصلی با بهینه‌سازی
      while (stateQueue.isNotEmpty &&
          stopwatch.elapsedMilliseconds < maxProcessingTime) {
        final currentNfaStates = stateQueue.removeFirst();
        final currentStateKey = _generateStateKey(currentNfaStates);
        final currentDfaState = dfaStates[currentStateKey]!;

        // تنظیم حالت‌های پایانی
        if (_containsFinalState(nfa, currentNfaStates)) {
          dfa.setFinalState(currentDfaState, true);
        }

        // پردازش transition ها
        for (final symbol in nfa.alphabet) {
          final nextStates = _computeNextStates(nfa, currentNfaStates, symbol);

          if (nextStates.isNotEmpty) {
            final nextStatesClosure =
                _getEpsilonClosureOptimized(nfa, nextStates);
            final nextStateKey = _generateStateKey(nextStatesClosure);

            if (!visitedStates.containsKey(nextStateKey)) {
              stateQueue.add(nextStatesClosure);
              visitedStates[nextStateKey] = nextStatesClosure;

              final nextDfaState = _createStateSet(nextStatesClosure);
              dfa.addState(nextDfaState);
              dfaStates[nextStateKey] = nextDfaState;
            }

            dfa.addTransition(
                currentDfaState, symbol, dfaStates[nextStateKey]!);
          }
        }
      }

      final completeDfa = dfa.complete();

      // ذخیره در کش
      if (enableCaching) {
        AutomatonCache.cacheDfa(nfa, completeDfa);
      }

      stopwatch.stop();
      PerformanceMonitor.recordOperation('nfa_to_dfa', stopwatch.elapsed);

      return completeDfa;
    } catch (e) {
      stopwatch.stop();

      return DFA.empty();
    }
  }

  /// بهینه‌سازی محاسبه epsilon closure با کش
  Set<String> _getEpsilonClosureOptimized(NFA nfa, dynamic state) {
    if (state is String) {
      final cached = AutomatonCache.getCachedEpsilonClosure(state);
      if (cached != null && enableCaching) return cached;

      final closure = nfa.epsilonClosureOfState(state);

      if (enableCaching) {
        AutomatonCache.cacheEpsilonClosure(state, closure);
      }

      return closure;
    } else if (state is Set<String>) {
      return nfa.epsilonClosure(state);
    }

    return <String>{};
  }

  /// تولید کلید یکتا برای مجموعه حالت‌ها
  String _generateStateKey(Set<String> states) {
    final sortedStates = states.toList()..sort();
    return sortedStates.join('_');
  }

  /// ایجاد StateSet از مجموعه نام حالت‌ها
  StateSet _createStateSet(Set<String> stateNames) {
    return StateSet(stateNames.map((name) => StateModel(name: name)).toSet());
  }

  /// بررسی وجود حالت پایانی
  bool _containsFinalState(NFA nfa, Set<String> states) {
    return states.any((state) => nfa.finalStates.contains(state));
  }

  /// محاسبه حالت‌های بعدی برای یک نماد
  Set<String> _computeNextStates(
      NFA nfa, Set<String> currentStates, String symbol) {
    final nextStates = <String>{};
    for (final state in currentStates) {
      nextStates.addAll(nfa.getTransitions(state, symbol));
    }
    return nextStates;
  }

  /// دریافت نام حالت با توجه به نوع آن
  String _getStateName(dynamic state) {
    if (state is StateModel) return state.name;
    if (state is String) return state;
    return state.toString();
  }

  /// عملیات اجتماع با بهینه‌سازی کامل
  Future<UnionResult> unionWithOptimization(NFA nfa1, NFA nfa2) async {
    final stopwatch = Stopwatch()..start();

    try {
      // تبدیل به DFA با کش
      final dfa1Future = Future.value(_convertNfaToDfaAdvanced(nfa1));
      final dfa2Future = Future.value(_convertNfaToDfaAdvanced(nfa2));

      final results = await Future.wait([dfa1Future, dfa2Future]);
      final dfa1 = results[0];
      final dfa2 = results[1];

      // انجام عملیات اجتماع
      final unionDfa = DFA.union(dfa1, dfa2);
      final originalStates = unionDfa.states.length;

      // بهینه‌سازی (minimization)
      DFA finalDfa = unionDfa;
      int statesReduced = 0;
      bool wasOptimized = false;

      if (enableMinimization) {
        finalDfa = unionDfa.minimize();
        statesReduced = originalStates - finalDfa.states.length;
        wasOptimized = statesReduced > 0;
      }

      stopwatch.stop();
      PerformanceMonitor.recordOperation('union', stopwatch.elapsed);

      return UnionResult(
        resultDfa: finalDfa,
        metrics: finalDfa.getMetrics(),
        processingTime: stopwatch.elapsed,
        statesReduced: statesReduced,
        wasOptimized: wasOptimized,
      );
    } catch (e) {
      stopwatch.stop();
      // در صورت خطا، DFA خالی برگردان
      final emptyDfa = DFA.empty();
      return UnionResult(
        resultDfa: emptyDfa,
        metrics: emptyDfa.getMetrics(),
        processingTime: stopwatch.elapsed,
      );
    }
  }

  /// عملیات اشتراک با پردازش پیشرفته
  Future<IntersectionResult> intersectionWithParallelProcessing(
      NFA nfa1, NFA nfa2) async {
    final stopwatch = Stopwatch()..start();

    try {
      final dfa1 = _convertNfaToDfaAdvanced(nfa1);
      final dfa2 = _convertNfaToDfaAdvanced(nfa2);

      final originalStatesCount = dfa1.states.length * dfa2.states.length;

      final intersectionDfa = DFA.intersection(dfa1, dfa2);
      final isEmpty = intersectionDfa.finalStates.isEmpty;

      DFA finalDfa = intersectionDfa;
      if (enableMinimization && !isEmpty) {
        finalDfa = intersectionDfa.minimize();
      }

      stopwatch.stop();
      PerformanceMonitor.recordOperation('intersection', stopwatch.elapsed);

      return IntersectionResult(
        resultDfa: finalDfa,
        metrics: finalDfa.getMetrics(),
        processingTime: stopwatch.elapsed,
        originalStatesCount: originalStatesCount,
        isEmpty: isEmpty,
      );
    } catch (e) {
      stopwatch.stop();
      final emptyDfa = DFA.empty();
      return IntersectionResult(
        resultDfa: emptyDfa,
        metrics: emptyDfa.getMetrics(),
        processingTime: stopwatch.elapsed,
        isEmpty: true,
      );
    }
  }

  /// عملیات الحاق با بهینه‌سازی مسیر
  Future<ConcatenationResult> concatenateWithOptimization(
      NFA nfa1, NFA nfa2) async {
    final stopwatch = Stopwatch()..start();

    try {
      int epsilonTransitionsCount = 0;
      bool hasOptimizedPath = false;

      // شمارش epsilon transition های اولیه
      final initialEpsilonCount =
          _countEpsilonTransitions(nfa1) + _countEpsilonTransitions(nfa2);

      final result = nfa1.concatenation(nfa2);

      if (result.success && result.result != null) {
        final finalEpsilonCount = _countEpsilonTransitions(result.result!);
        epsilonTransitionsCount = finalEpsilonCount - initialEpsilonCount;

        // بررسی بهینه‌سازی مسیر
        hasOptimizedPath = _hasDirectPath(nfa1, nfa2);

        stopwatch.stop();
        PerformanceMonitor.recordOperation('concatenation', stopwatch.elapsed);

        return ConcatenationResult(
          resultNfa: result.result!,
          processingTime: stopwatch.elapsed,
          epsilonTransitionsAdded: epsilonTransitionsCount,
          hasOptimizedPath: hasOptimizedPath,
        );
      }

      // در صورت شکست
      stopwatch.stop();
      return ConcatenationResult(
        resultNfa: NFA.empty(),
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return ConcatenationResult(
        resultNfa: NFA.empty(),
        processingTime: stopwatch.elapsed,
      );
    }
  }

  /// عملیات ستاره کلینی با تشخیص چرخه
  Future<KleeneStarResult> kleeneStarWithCycleDetection(NFA nfa) async {
    final stopwatch = Stopwatch()..start();

    try {
      // تشخیص چرخه‌های موجود
      final cyclesDetected = _detectCycles(nfa);
      final hasCycleDetection = cyclesDetected.isNotEmpty;

      final result = nfa.kleeneStar();

      if (result.success && result.result != null) {
        stopwatch.stop();
        PerformanceMonitor.recordOperation('kleene_star', stopwatch.elapsed);

        return KleeneStarResult(
          resultNfa: result.result!,
          processingTime: stopwatch.elapsed,
          hasCycleDetection: hasCycleDetection,
          cyclesFound: cyclesDetected.length,
        );
      }

      stopwatch.stop();
      return KleeneStarResult(
        resultNfa: NFA.empty(),
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return KleeneStarResult(
        resultNfa: NFA.empty(),
        processingTime: stopwatch.elapsed,
      );
    }
  }

  /// عملیات مکمل با اندازه‌گیری دقیق
  Future<ComplementResult> complementWithMetrics(NFA nfa) async {
    final stopwatch = Stopwatch()..start();

    try {
      final dfa = _convertNfaToDfaAdvanced(nfa);
      final originalMetrics = dfa.getMetrics();

      final complementDfa = dfa.complement();
      final complementMetrics = complementDfa.getMetrics();

      final trapStatesAdded =
          complementMetrics.stateCount - originalMetrics.stateCount;

      stopwatch.stop();
      PerformanceMonitor.recordOperation('complement', stopwatch.elapsed);

      return ComplementResult(
        complementDfa: complementDfa,
        originalMetrics: originalMetrics,
        complementMetrics: complementMetrics,
        processingTime: stopwatch.elapsed,
        trapStatesAdded: max(0, trapStatesAdded),
      );
    } catch (e) {
      stopwatch.stop();
      final emptyDfa = DFA.empty();
      final emptyMetrics = emptyDfa.getMetrics();

      return ComplementResult(
        complementDfa: emptyDfa,
        originalMetrics: emptyMetrics,
        complementMetrics: emptyMetrics,
        processingTime: stopwatch.elapsed,
      );
    }
  }

  /// شمارش epsilon transition ها
  int _countEpsilonTransitions(NFA nfa) {
    int count = 0;
    for (final state in nfa.states) {
      final stateName = _getStateName(state);
      count += nfa.getTransitions(stateName, '').length;
    }
    return count;
  }

  /// بررسی وجود مسیر مستقیم بین دو NFA
  bool _hasDirectPath(NFA nfa1, NFA nfa2) {
    return nfa1.finalStates.contains(nfa2.startState);
  }

  /// تشخیص چرخه‌ها در NFA با الگوریتم DFS
  List<List<String>> _detectCycles(NFA nfa) {
    final cycles = <List<String>>[];
    final visited = <String>{};
    final recursionStack = <String>{};
    final currentPath = <String>[];

    void dfs(String state) {
      if (recursionStack.contains(state)) {
        // پیدا کردن چرخه
        final cycleStart = currentPath.indexOf(state);
        if (cycleStart != -1) {
          cycles.add(currentPath.sublist(cycleStart) + [state]);
        }
        return;
      }

      if (visited.contains(state)) return;

      visited.add(state);
      recursionStack.add(state);
      currentPath.add(state);

      // بررسی تمام transition ها
      for (final symbol in nfa.alphabet) {
        final nextStates = nfa.getTransitions(state, symbol);
        for (final nextState in nextStates) {
          dfs(nextState);
        }
      }

      recursionStack.remove(state);
      currentPath.removeLast();
    }

    // شروع DFS از تمام حالت‌ها
    for (final state in nfa.states) {
      final stateName = _getStateName(state);
      if (!visited.contains(stateName)) {
        dfs(stateName);
      }
    }

    return cycles;
  }

  /// تنظیم پیکربندی بهینه‌سازی
  static void configureOptimization({
    bool? caching,
    bool? parallelProcessing,
    bool? minimization,
    int? maxTime,
  }) {
    if (caching != null) enableCaching = caching;
    if (parallelProcessing != null)
      enableParallelProcessing = parallelProcessing;
    if (minimization != null) enableMinimization = minimization;
    if (maxTime != null) maxProcessingTime = maxTime;
  }

  /// گزارش عملکرد سیستم
  static Map<String, dynamic> getPerformanceReport() {
    return {
      'average_times': {
        'nfa_to_dfa':
            PerformanceMonitor.getAverageTime('nfa_to_dfa').inMilliseconds,
        'union': PerformanceMonitor.getAverageTime('union').inMilliseconds,
        'intersection':
            PerformanceMonitor.getAverageTime('intersection').inMilliseconds,
        'concatenation':
            PerformanceMonitor.getAverageTime('concatenation').inMilliseconds,
        'kleene_star':
            PerformanceMonitor.getAverageTime('kleene_star').inMilliseconds,
        'complement':
            PerformanceMonitor.getAverageTime('complement').inMilliseconds,
      },
      'cache_size': AutomatonCache._dfaCache.length,
      'epsilon_cache_size': AutomatonCache._epsilonClosureCache.length,
      'configuration': {
        'caching_enabled': enableCaching,
        'parallel_processing': enableParallelProcessing,
        'minimization_enabled': enableMinimization,
        'max_processing_time': maxProcessingTime,
      }
    };
  }

  /// پاک کردن تمام کش‌ها و آمار عملکرد
  static void resetSystem() {
    AutomatonCache.clearCache();
    PerformanceMonitor.clearHistory();
  }
}
