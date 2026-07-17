import '../models/simulation_result.dart';

abstract interface class TraceRepository {
  Future<void> saveTraceToHistory(
    SimulationResult trace, {
    String? automatonType,
    String? automatonId,
  });
  Future<List<Map<String, dynamic>>> getTraceHistory();
  Future<Map<String, dynamic>?> getTraceById(String traceId);
  Future<void> saveCurrentTrace(
    SimulationResult trace,
    int currentStepIndex,
  );
  Future<Map<String, dynamic>?> getCurrentTrace();
  Future<void> clearCurrentTrace();
  Future<void> clearAllTraces();
  Future<String> exportTraceHistory();
  Future<void> importTraceHistory(String jsonData);
  Future<Map<String, dynamic>> getTraceStatistics();
}
