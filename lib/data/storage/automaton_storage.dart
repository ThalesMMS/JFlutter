import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';
import '../services/automaton_service.dart';
import '../repositories/automaton_repository_impl.dart';

/// Storage interface for automaton data
abstract class AutomatonStorage {
  Future<List<FiniteAutomaton>> getAllAutomata();
  Future<FiniteAutomaton?> getAutomatonById(String id);
  Future<void> saveAutomaton(FiniteAutomaton automaton);
  Future<void> saveAutomata(List<FiniteAutomaton> automata);
  Future<void> deleteAutomaton(String id);
  Future<void> clearAll();
  Future<CacheStatistics> getStatistics();
  
  // Simulation results
  Future<SimulationResult?> getSimulationResult(String id, String input);
  Future<void> saveSimulationResult(String id, String input, SimulationResult result);
  
  // Algorithm results
  Future<AlgorithmResult?> getAlgorithmResult(String id, String algorithm, Map<String, dynamic> parameters);
  Future<void> saveAlgorithmResult(String id, String algorithm, Map<String, dynamic> parameters, AlgorithmResult result);
  
  // Operation results
  Future<FiniteAutomaton?> getOperationResult(String operation, List<String> automatonIds, Map<String, dynamic> parameters);
  Future<void> saveOperationResult(String operation, List<String> automatonIds, Map<String, dynamic> parameters, FiniteAutomaton result);
  
  // Export results
  Future<String?> getJFLAPExport(String id);
  Future<void> saveJFLAPExport(String id, String export);
  Future<Map<String, dynamic>?> getJSONExport(String id);
  Future<void> saveJSONExport(String id, Map<String, dynamic> export);
}

/// In-memory storage implementation
class InMemoryAutomatonStorage implements AutomatonStorage {
  final Map<String, FiniteAutomaton> _automata = {};
  final Map<String, SimulationResult> _simulations = {};
  final Map<String, AlgorithmResult> _algorithms = {};
  final Map<String, FiniteAutomaton> _operations = {};
  final Map<String, String> _jflapExports = {};
  final Map<String, Map<String, dynamic>> _jsonExports = {};
  
  @override
  Future<List<FiniteAutomaton>> getAllAutomata() async {
    return _automata.values.toList();
  }
  
  @override
  Future<FiniteAutomaton?> getAutomatonById(String id) async {
    return _automata[id];
  }
  
  @override
  Future<void> saveAutomaton(FiniteAutomaton automaton) async {
    _automata[automaton.id] = automaton;
  }
  
  @override
  Future<void> saveAutomata(List<FiniteAutomaton> automata) async {
    for (final automaton in automata) {
      _automata[automaton.id] = automaton;
    }
  }
  
  @override
  Future<void> deleteAutomaton(String id) async {
    _automata.remove(id);
  }
  
  @override
  Future<void> clearAll() async {
    _automata.clear();
    _simulations.clear();
    _algorithms.clear();
    _operations.clear();
    _jflapExports.clear();
    _jsonExports.clear();
  }
  
  @override
  Future<CacheStatistics> getStatistics() async {
    return CacheStatistics(
      automatonCount: _automata.length,
      simulationCount: _simulations.length,
      algorithmCount: _algorithms.length,
      operationCount: _operations.length,
      exportCount: _jflapExports.length + _jsonExports.length,
      totalSize: _automata.length + _simulations.length + _algorithms.length + _operations.length + _jflapExports.length + _jsonExports.length,
      lastUpdated: DateTime.now(),
    );
  }
  
  @override
  Future<SimulationResult?> getSimulationResult(String id, String input) async {
    final key = '${id}_$input';
    return _simulations[key];
  }
  
  @override
  Future<void> saveSimulationResult(String id, String input, SimulationResult result) async {
    final key = '${id}_$input';
    _simulations[key] = result;
  }
  
  @override
  Future<AlgorithmResult?> getAlgorithmResult(String id, String algorithm, Map<String, dynamic> parameters) async {
    final key = '${id}_${algorithm}_${parameters.toString()}';
    return _algorithms[key];
  }
  
  @override
  Future<void> saveAlgorithmResult(String id, String algorithm, Map<String, dynamic> parameters, AlgorithmResult result) async {
    final key = '${id}_${algorithm}_${parameters.toString()}';
    _algorithms[key] = result;
  }
  
  @override
  Future<FiniteAutomaton?> getOperationResult(String operation, List<String> automatonIds, Map<String, dynamic> parameters) async {
    final key = '${operation}_${automatonIds.join('_')}_${parameters.toString()}';
    return _operations[key];
  }
  
  @override
  Future<void> saveOperationResult(String operation, List<String> automatonIds, Map<String, dynamic> parameters, FiniteAutomaton result) async {
    final key = '${operation}_${automatonIds.join('_')}_${parameters.toString()}';
    _operations[key] = result;
  }
  
  @override
  Future<String?> getJFLAPExport(String id) async {
    return _jflapExports[id];
  }
  
  @override
  Future<void> saveJFLAPExport(String id, String export) async {
    _jflapExports[id] = export;
  }
  
  @override
  Future<Map<String, dynamic>?> getJSONExport(String id) async {
    return _jsonExports[id];
  }
  
  @override
  Future<void> saveJSONExport(String id, Map<String, dynamic> export) async {
    _jsonExports[id] = export;
  }
}

/// Storage factory
class AutomatonStorageFactory {
  static AutomatonStorage createInMemory() {
    return InMemoryAutomatonStorage();
  }
  
  static AutomatonStorage createPersistent() {
    // This would implement persistent storage (e.g., SQLite, Hive, etc.)
    // For now, return in-memory storage
    return InMemoryAutomatonStorage();
  }
}
