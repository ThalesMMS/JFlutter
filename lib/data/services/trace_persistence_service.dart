//
//  trace_persistence_service.dart
//  JFlutter
//
//  Gerencia o armazenamento de históricos de simulação via SharedPreferences, preservando metadados, seleção atual e consultas segmentadas por autômato ou tipo.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/simulation_result.dart';

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
      if (kDebugMode) {
        debugPrint('Failed to save trace: $e');
      }
    }
  }

  /// Get all trace history
  Future<List<Map<String, dynamic>>> getTraceHistory() async {
    try {
      final historyJson = _prefs.getString(_traceHistoryKey);
      if (historyJson == null) return [];

      final decoded = jsonDecode(historyJson);
      if (decoded is! List) {
        return [];
      }

      return _sanitizeTraceList(decoded);
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
      if (kDebugMode) {
        debugPrint('Failed to save current trace: $e');
      }
    }
  }

  /// Get current trace
  Future<Map<String, dynamic>?> getCurrentTrace() async {
    try {
      final currentTraceJson = _prefs.getString(_currentTraceKey);
      if (currentTraceJson == null) return null;

      final decoded = _asStringKeyedMap(jsonDecode(currentTraceJson));
      if (decoded == null) {
        return null;
      }

      final trace = _asStringKeyedMap(decoded['trace']);
      if (trace == null) {
        return null;
      }

      final rawStepIndex = decoded['currentStepIndex'];
      final currentStepIndex = rawStepIndex is int
          ? rawStepIndex
          : rawStepIndex is num
              ? rawStepIndex.toInt()
              : 0;

      return <String, dynamic>{
        ...decoded,
        'trace': trace,
        'currentStepIndex': currentStepIndex,
      };
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
      if (kDebugMode) {
        debugPrint('Failed to save trace metadata: $e');
      }
    }
  }

  /// Get trace metadata
  Future<Map<String, Map<String, dynamic>>> getTraceMetadata() async {
    try {
      final metadataJson = _prefs.getString(_traceMetadataKey);
      if (metadataJson == null) return {};

      return _sanitizeMetadataMap(jsonDecode(metadataJson));
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
      if (kDebugMode) {
        debugPrint('Failed to delete trace: $e');
      }
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
      final traces = _sanitizeTraceList(data['traces']);
      final metadata = _sanitizeMetadataMap(data['metadata']);

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
      final type = trace['automatonType'] as String;
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

  List<Map<String, dynamic>> _sanitizeTraceList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    final traces = <Map<String, dynamic>>[];
    for (final entry in raw) {
      final map = _asStringKeyedMap(entry);
      if (map == null) {
        continue;
      }

      final nestedTrace = _asStringKeyedMap(map['trace']);
      if (nestedTrace == null) {
        continue;
      }

      traces.add(<String, dynamic>{
        ...map,
        'automatonType':
            map['automatonType'] is String ? map['automatonType'] : 'unknown',
        'trace': nestedTrace,
      });
    }
    return traces;
  }

  Map<String, Map<String, dynamic>> _sanitizeMetadataMap(dynamic raw) {
    if (raw is! Map) {
      return const {};
    }

    final metadata = <String, Map<String, dynamic>>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      if (key is! String) {
        continue;
      }

      final value = _asStringKeyedMap(entry.value);
      if (value != null) {
        metadata[key] = value;
      }
    }
    return metadata;
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is! Map) {
      return null;
    }

    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        return null;
      }
      result[key] = entry.value;
    }
    return result;
  }
}
