//
//  trace_persistence_service.dart
//  JFlutter
//
//  Administra o salvamento, carregamento e exportação de rastros de simulação,
//  combinando SharedPreferences e arquivos locais para preservar histórico entre
//  sessões. Controla limites de armazenamento, gera identificadores exclusivos
//  para cada execução e oferece utilitários para buscar, excluir e limpar
//  registros. Define ainda modelos auxiliares e exceções que padronizam erros de
//  persistência expostos à interface.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';

/// Service for persisting and managing simulation traces across app sessions
class TracePersistenceService {
  static const String _traceHistoryKey = 'simulation_trace_history';
  static const String _currentTraceKey = 'current_simulation_trace';
  static const String _maxHistorySize = 'max_trace_history_size';
  static const int _defaultMaxHistory = 50;

  /// Saves a simulation trace to persistent storage
  Future<void> saveTrace(SimulationResult trace, {String? customId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final traceId = customId ?? _generateTraceId(trace);

      // Save to history
      await _addToHistory(traceId, trace);

      // Save as current trace
      await prefs.setString(_currentTraceKey, jsonEncode(trace.toJson()));

      // Clean up old traces if history is too large
      await _cleanupHistory();
    } catch (e) {
      throw TracePersistenceException('Failed to save trace: $e');
    }
  }

  /// Loads the current simulation trace from persistent storage
  Future<SimulationResult?> loadCurrentTrace() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final traceJson = prefs.getString(_currentTraceKey);

      if (traceJson == null) return null;

      final traceData = jsonDecode(traceJson) as Map<String, dynamic>;
      return SimulationResult.fromJson(traceData);
    } catch (e) {
      throw TracePersistenceException('Failed to load current trace: $e');
    }
  }

  /// Loads trace history from persistent storage
  Future<List<TraceHistoryEntry>> loadTraceHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_traceHistoryKey);

      if (historyJson == null) return [];

      final historyData = jsonDecode(historyJson) as List<dynamic>;
      return historyData
          .map(
            (entry) =>
                TraceHistoryEntry.fromJson(entry as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw TracePersistenceException('Failed to load trace history: $e');
    }
  }

  /// Loads a specific trace by ID
  Future<SimulationResult?> loadTraceById(String traceId) async {
    try {
      final history = await loadTraceHistory();
      final entry = history.firstWhere(
        (entry) => entry.id == traceId,
        orElse: () => throw TraceNotFoundException('Trace not found: $traceId'),
      );

      return entry.trace;
    } catch (e) {
      if (e is TraceNotFoundException) rethrow;
      throw TracePersistenceException('Failed to load trace by ID: $e');
    }
  }

  /// Exports trace to file
  Future<String> exportTraceToFile(
    SimulationResult trace, {
    String? fileName,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final traceDir = Directory('${directory.path}/traces');

      if (!await traceDir.exists()) {
        await traceDir.create(recursive: true);
      }

      final actualFileName =
          fileName ?? 'trace_${_generateTraceId(trace)}.json';
      final file = File('${traceDir.path}/$actualFileName');

      await file.writeAsString(jsonEncode(trace.toJson()));
      return file.path;
    } catch (e) {
      throw TracePersistenceException('Failed to export trace to file: $e');
    }
  }

  /// Imports trace from file
  Future<SimulationResult> importTraceFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw TracePersistenceException('File does not exist: $filePath');
      }

      final content = await file.readAsString();
      final traceData = jsonDecode(content) as Map<String, dynamic>;

      return SimulationResult.fromJson(traceData);
    } catch (e) {
      throw TracePersistenceException('Failed to import trace from file: $e');
    }
  }

  /// Deletes a trace from history
  Future<void> deleteTrace(String traceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await loadTraceHistory();

      final updatedHistory = history
          .where((entry) => entry.id != traceId)
          .toList();

      await prefs.setString(
        _traceHistoryKey,
        jsonEncode(updatedHistory.map((entry) => entry.toJson()).toList()),
      );
    } catch (e) {
      throw TracePersistenceException('Failed to delete trace: $e');
    }
  }

  /// Clears all trace history
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_traceHistoryKey);
      await prefs.remove(_currentTraceKey);
    } catch (e) {
      throw TracePersistenceException('Failed to clear history: $e');
    }
  }

  /// Sets the maximum number of traces to keep in history
  Future<void> setMaxHistorySize(int maxSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_maxHistorySize, maxSize);
    } catch (e) {
      throw TracePersistenceException('Failed to set max history size: $e');
    }
  }

  /// Gets the maximum number of traces to keep in history
  Future<int> getMaxHistorySize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_maxHistorySize) ?? _defaultMaxHistory;
    } catch (e) {
      return _defaultMaxHistory;
    }
  }

  /// Adds a trace to the history
  Future<void> _addToHistory(String traceId, SimulationResult trace) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadTraceHistory();

    final entry = TraceHistoryEntry(
      id: traceId,
      trace: trace,
      timestamp: DateTime.now(),
      inputString: trace.inputString,
      accepted: trace.accepted,
      stepCount: trace.stepCount,
    );

    // Add to beginning of list (most recent first)
    history.insert(0, entry);

    await prefs.setString(
      _traceHistoryKey,
      jsonEncode(history.map((entry) => entry.toJson()).toList()),
    );
  }

  /// Cleans up old traces if history exceeds maximum size
  Future<void> _cleanupHistory() async {
    final maxSize = await getMaxHistorySize();
    final history = await loadTraceHistory();

    if (history.length > maxSize) {
      final trimmedHistory = history.take(maxSize).toList();
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _traceHistoryKey,
        jsonEncode(trimmedHistory.map((entry) => entry.toJson()).toList()),
      );
    }
  }

  /// Generates a unique ID for a trace
  String _generateTraceId(SimulationResult trace) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final inputHash = trace.inputString.hashCode;
    final resultHash = trace.accepted ? 1 : 0;
    return 'trace_${timestamp}_${inputHash}_$resultHash';
  }
}

/// Represents a trace history entry with metadata
class TraceHistoryEntry {
  final String id;
  final SimulationResult trace;
  final DateTime timestamp;
  final String inputString;
  final bool accepted;
  final int stepCount;

  const TraceHistoryEntry({
    required this.id,
    required this.trace,
    required this.timestamp,
    required this.inputString,
    required this.accepted,
    required this.stepCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trace': trace.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'inputString': inputString,
      'accepted': accepted,
      'stepCount': stepCount,
    };
  }

  factory TraceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TraceHistoryEntry(
      id: json['id'] as String,
      trace: SimulationResult.fromJson(json['trace'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
      inputString: json['inputString'] as String,
      accepted: json['accepted'] as bool,
      stepCount: json['stepCount'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TraceHistoryEntry &&
        other.id == id &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(id, timestamp);

  @override
  String toString() {
    return 'TraceHistoryEntry(id: $id, input: $inputString, accepted: $accepted, steps: $stepCount, timestamp: $timestamp)';
  }
}

/// Exception thrown when trace persistence operations fail
class TracePersistenceException implements Exception {
  final String message;
  const TracePersistenceException(this.message);

  @override
  String toString() => 'TracePersistenceException: $message';
}

/// Exception thrown when a trace is not found
class TraceNotFoundException implements Exception {
  final String message;
  const TraceNotFoundException(this.message);

  @override
  String toString() => 'TraceNotFoundException: $message';
}
