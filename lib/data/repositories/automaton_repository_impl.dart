import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';
import 'package:serializers/serializers.dart';
import '../services/automaton_service.dart';
import '../storage/automaton_storage.dart';

/// Repository implementation for automaton operations
class AutomatonRepositoryImpl {
  final AutomatonService _service;
  final AutomatonStorage _storage;

  AutomatonRepositoryImpl({
    required AutomatonService service,
    required AutomatonStorage storage,
  }) : _service = service, _storage = storage;

  /// Get all automata
  Future<List<FiniteAutomaton>> getAllAutomata() async {
    try {
      // Try to get from cache first
      final cachedAutomata = await _storage.getAllAutomata();
      if (cachedAutomata.isNotEmpty) {
        return cachedAutomata;
      }

      // Fetch from API
      final automata = await _service.getAllAutomata();
      
      // Cache the results
      await _storage.saveAutomata(automata);
      
      return automata;
    } catch (e) {
      // Fallback to cached data if available
      final cachedAutomata = await _storage.getAllAutomata();
      if (cachedAutomata.isNotEmpty) {
        return cachedAutomata;
      }
      rethrow;
    }
  }

  /// Get automaton by ID
  Future<FiniteAutomaton> getAutomatonById(String id) async {
    try {
      // Try to get from cache first
      final cachedAutomaton = await _storage.getAutomatonById(id);
      if (cachedAutomaton != null) {
        return cachedAutomaton;
      }

      // Fetch from API
      final automaton = await _service.getAutomatonById(id);
      
      // Cache the result
      await _storage.saveAutomaton(automaton);
      
      return automaton;
    } catch (e) {
      // Fallback to cached data if available
      final cachedAutomaton = await _storage.getAutomatonById(id);
      if (cachedAutomaton != null) {
        return cachedAutomaton;
      }
      rethrow;
    }
  }

  /// Create new automaton
  Future<FiniteAutomaton> createAutomaton(FiniteAutomaton automaton) async {
    try {
      // Create via API
      final createdAutomaton = await _service.createAutomaton(automaton);
      
      // Cache the result
      await _storage.saveAutomaton(createdAutomaton);
      
      return createdAutomaton;
    } catch (e) {
      rethrow;
    }
  }

  /// Update automaton
  Future<FiniteAutomaton> updateAutomaton(String id, FiniteAutomaton automaton) async {
    try {
      // Update via API
      final updatedAutomaton = await _service.updateAutomaton(id, automaton);
      
      // Update cache
      await _storage.saveAutomaton(updatedAutomaton);
      
      return updatedAutomaton;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete automaton
  Future<void> deleteAutomaton(String id) async {
    try {
      // Delete via API
      await _service.deleteAutomaton(id);
      
      // Remove from cache
      await _storage.deleteAutomaton(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Simulate automaton
  Future<SimulationResult> simulateAutomaton(String id, String input) async {
    try {
      // Try to get from cache first
      final cachedResult = await _storage.getSimulationResult(id, input);
      if (cachedResult != null) {
        return cachedResult;
      }

      // Simulate via API
      final result = await _service.simulateAutomaton(id, input);
      
      // Cache the result
      await _storage.saveSimulationResult(id, input, result);
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Run algorithm on automaton
  Future<AlgorithmResult> runAlgorithm(String id, String algorithm, Map<String, dynamic> parameters) async {
    try {
      // Try to get from cache first
      final cachedResult = await _storage.getAlgorithmResult(id, algorithm, parameters);
      if (cachedResult != null) {
        return cachedResult;
      }

      // Run via API
      final result = await _service.runAlgorithm(id, algorithm, parameters);
      
      // Cache the result
      await _storage.saveAlgorithmResult(id, algorithm, parameters, result);
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Perform automaton operations
  Future<FiniteAutomaton> performOperation(String operation, List<String> automatonIds, Map<String, dynamic> parameters) async {
    try {
      // Try to get from cache first
      final cachedResult = await _storage.getOperationResult(operation, automatonIds, parameters);
      if (cachedResult != null) {
        return cachedResult;
      }

      // Perform via API
      final result = await _service.performOperation(operation, automatonIds, parameters);
      
      // Cache the result
      await _storage.saveOperationResult(operation, automatonIds, parameters, result);
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Import JFLAP file
  Future<FiniteAutomaton> importJFLAP(String fileContent) async {
    try {
      // Import via API
      final automaton = await _service.importJFLAP(fileContent);
      
      // Cache the result
      await _storage.saveAutomaton(automaton);
      
      return automaton;
    } catch (e) {
      rethrow;
    }
  }

  /// Export automaton to JFLAP
  Future<String> exportToJFLAP(String id) async {
    try {
      // Try to get from cache first
      final cachedExport = await _storage.getJFLAPExport(id);
      if (cachedExport != null) {
        return cachedExport;
      }

      // Export via API
      final export = await _service.exportToJFLAP(id);
      
      // Cache the result
      await _storage.saveJFLAPExport(id, export);
      
      return export;
    } catch (e) {
      rethrow;
    }
  }

  /// Export automaton to JSON
  Future<Map<String, dynamic>> exportToJSON(String id) async {
    try {
      // Try to get from cache first
      final cachedExport = await _storage.getJSONExport(id);
      if (cachedExport != null) {
        return cachedExport;
      }

      // Export via API
      final export = await _service.exportToJSON(id);
      
      // Cache the result
      await _storage.saveJSONExport(id, export);
      
      return export;
    } catch (e) {
      rethrow;
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _storage.clearAll();
  }

  /// Get cache statistics
  Future<CacheStatistics> getCacheStatistics() async {
    return await _storage.getStatistics();
  }
}

/// Cache statistics
class CacheStatistics {
  final int automatonCount;
  final int simulationCount;
  final int algorithmCount;
  final int operationCount;
  final int exportCount;
  final int totalSize;
  final DateTime lastUpdated;

  const CacheStatistics({
    required this.automatonCount,
    required this.simulationCount,
    required this.algorithmCount,
    required this.operationCount,
    required this.exportCount,
    required this.totalSize,
    required this.lastUpdated,
  });
}

/// Repository interface
abstract class AutomatonRepository {
  Future<List<FiniteAutomaton>> getAllAutomata();
  Future<FiniteAutomaton> getAutomatonById(String id);
  Future<FiniteAutomaton> createAutomaton(FiniteAutomaton automaton);
  Future<FiniteAutomaton> updateAutomaton(String id, FiniteAutomaton automaton);
  Future<void> deleteAutomaton(String id);
  Future<SimulationResult> simulateAutomaton(String id, String input);
  Future<AlgorithmResult> runAlgorithm(String id, String algorithm, Map<String, dynamic> parameters);
  Future<FiniteAutomaton> performOperation(String operation, List<String> automatonIds, Map<String, dynamic> parameters);
  Future<FiniteAutomaton> importJFLAP(String fileContent);
  Future<String> exportToJFLAP(String id);
  Future<Map<String, dynamic>> exportToJSON(String id);
  Future<void> clearCache();
  Future<CacheStatistics> getCacheStatistics();
}

/// Repository factory
class AutomatonRepositoryFactory {
  static AutomatonRepository create({
    required AutomatonService service,
    required AutomatonStorage storage,
  }) {
    return AutomatonRepositoryImpl(
      service: service,
      storage: storage,
    );
  }
}

/// Repository configuration
class RepositoryConfig {
  final bool enableCaching;
  final Duration cacheExpiration;
  final int maxCacheSize;
  final bool enableOfflineMode;

  const RepositoryConfig({
    this.enableCaching = true,
    this.cacheExpiration = const Duration(hours: 24),
    this.maxCacheSize = 100,
    this.enableOfflineMode = true,
  });
}

/// Repository manager
class RepositoryManager {
  final AutomatonRepository _repository;
  final RepositoryConfig _config;

  RepositoryManager({
    required AutomatonRepository repository,
    required RepositoryConfig config,
  }) : _repository = repository, _config = config;

  /// Get repository
  AutomatonRepository get repository => _repository;

  /// Get configuration
  RepositoryConfig get config => _config;

  /// Initialize repository
  Future<void> initialize() async {
    if (_config.enableCaching) {
      // Initialize cache
      await _repository.clearCache();
    }
  }

  /// Dispose repository
  Future<void> dispose() async {
    // Cleanup resources
  }
}