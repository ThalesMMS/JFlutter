import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/simulation_result.dart';
import '../../core/models/simulation_step.dart';

/// Service for persisting and managing traces across different automaton types
class TracePersistenceService {
  static const String _traceHistoryKey = 'trace_history';
  static const String _currentTraceKey = 'current_trace';
  static const String _traceMetadataKey = 'trace_metadata';
  static const int _maxHistorySize = 50; // Limit trace history size

  final SharedPreferences _prefs;

  TracePersistenceService(this._prefs);

  /// Save a trace to history
  Future<void> saveTraceToHistory(
    SimulationResult trace, {
    String? automatonType,
    String? automatonId,
  }) async {
    try {
      final traceData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'automatonType': automatonType ?? 'unknown',
        'automatonId': automatonId,
        'trace': trace.toJson(),
      };

      final history = await getTraceHistory();
      history.insert(0, traceData); // Add to beginning

      // Limit history size
      if (history.length > _maxHistorySize) {
        history.removeRange(_maxHistorySize, history.length);
      }

      await _prefs.setString(_traceHistoryKey, jsonEncode(history));
    } catch (e) {
      // Silently fail - trace persistence is not critical
      print('Failed to save trace: $e');
    }
  }

  /// Get all trace history
  Future<List<Map<String, dynamic>>> getTraceHistory() async {
    try {
      final historyJson = _prefs.getString(_traceHistoryKey);
      if (historyJson == null) return [];

      final history = jsonDecode(historyJson) as List;
      return history.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Get traces for a specific automaton type
  Future<List<Map<String, dynamic>>> getTracesForType(
    String automatonType,
  ) async {
    final history = await getTraceHistory();
    return history
        .where((trace) => trace['automatonType'] == automatonType)
        .toList();
  }

  /// Get traces for a specific automaton
  Future<List<Map<String, dynamic>>> getTracesForAutomaton(
    String automatonId,
  ) async {
    final history = await getTraceHistory();
    return history
        .where((trace) => trace['automatonId'] == automatonId)
        .toList();
  }

  /// Save current trace (for step-by-step navigation)
  Future<void> saveCurrentTrace(
    SimulationResult trace,
    int currentStepIndex,
  ) async {
    try {
      final currentTraceData = {
        'trace': trace.toJson(),
        'currentStepIndex': currentStepIndex,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _prefs.setString(_currentTraceKey, jsonEncode(currentTraceData));
    } catch (e) {
      print('Failed to save current trace: $e');
    }
  }

  /// Get current trace
  Future<Map<String, dynamic>?> getCurrentTrace() async {
    try {
      final currentTraceJson = _prefs.getString(_currentTraceKey);
      if (currentTraceJson == null) return null;

      return jsonDecode(currentTraceJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Clear current trace
  Future<void> clearCurrentTrace() async {
    await _prefs.remove(_currentTraceKey);
  }

  /// Save trace metadata (for cross-simulator navigation)
  Future<void> saveTraceMetadata({
    required String traceId,
    required String automatonType,
    String? automatonId,
    String? inputString,
    bool? accepted,
    int? stepCount,
    Duration? executionTime,
  }) async {
    try {
      final metadata = {
        'traceId': traceId,
        'automatonType': automatonType,
        'automatonId': automatonId,
        'inputString': inputString,
        'accepted': accepted,
        'stepCount': stepCount,
        'executionTime': executionTime?.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final existingMetadata = await getTraceMetadata();
      existingMetadata[traceId] = metadata;

      await _prefs.setString(_traceMetadataKey, jsonEncode(existingMetadata));
    } catch (e) {
      print('Failed to save trace metadata: $e');
    }
  }

  /// Get trace metadata
  Future<Map<String, Map<String, dynamic>>> getTraceMetadata() async {
    try {
      final metadataJson = _prefs.getString(_traceMetadataKey);
      if (metadataJson == null) return {};

      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
      return metadata.map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
    } catch (e) {
      return {};
    }
  }

  /// Get trace by ID
  Future<Map<String, dynamic>?> getTraceById(String traceId) async {
    final history = await getTraceHistory();
    return history
            .firstWhere(
              (trace) => trace['id'] == traceId,
              orElse: () => <String, dynamic>{},
            )
            .isEmpty
        ? null
        : history.firstWhere((trace) => trace['id'] == traceId);
  }

  /// Delete a trace from history
  Future<void> deleteTrace(String traceId) async {
    try {
      final history = await getTraceHistory();
      history.removeWhere((trace) => trace['id'] == traceId);
      await _prefs.setString(_traceHistoryKey, jsonEncode(history));
    } catch (e) {
      print('Failed to delete trace: $e');
    }
  }

  /// Clear all trace history
  Future<void> clearAllTraces() async {
    await _prefs.remove(_traceHistoryKey);
    await _prefs.remove(_currentTraceKey);
    await _prefs.remove(_traceMetadataKey);
  }

  /// Export trace history as JSON
  Future<String> exportTraceHistory() async {
    final history = await getTraceHistory();
    final metadata = await getTraceMetadata();

    return jsonEncode({
      'traces': history,
      'metadata': metadata,
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Import trace history from JSON
  Future<void> importTraceHistory(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final traces = data['traces'] as List? ?? [];
      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

      await _prefs.setString(_traceHistoryKey, jsonEncode(traces));
      await _prefs.setString(_traceMetadataKey, jsonEncode(metadata));
    } catch (e) {
      throw Exception('Failed to import trace history: $e');
    }
  }

  /// Get trace statistics
  Future<Map<String, dynamic>> getTraceStatistics() async {
    final history = await getTraceHistory();
    final metadata = await getTraceMetadata();

    final typeCounts = <String, int>{};
    final totalTraces = history.length;
    final acceptedCount = history.where((trace) {
      final traceData = trace['trace'] as Map<String, dynamic>;
      return traceData['accepted'] == true;
    }).length;

    for (final trace in history) {
      final type = trace['automatonType'] as String? ?? 'unknown';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    return {
      'totalTraces': totalTraces,
      'acceptedTraces': acceptedCount,
      'rejectedTraces': totalTraces - acceptedCount,
      'typeCounts': typeCounts,
      'metadataCount': metadata.length,
    };
  }
}
