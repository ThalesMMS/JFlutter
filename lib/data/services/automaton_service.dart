import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';
import 'package:conversions/conversions.dart';
import 'package:serializers/serializers.dart';

/// Service for automaton API operations
class AutomatonService {
  /// Default API endpoint used when a caller does not provide an explicit
  /// backend URL. This keeps legacy tests working while allowing the value to
  /// be overridden through dependency injection.
  static const String _defaultBaseUrl = 'https://api.jflutter.dev';

  final String baseUrl;
  final http.Client _client;

  AutomatonService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? _defaultBaseUrl,
        _client = client ?? http.Client();

  /// Get all automata
  Future<List<FiniteAutomaton>> getAllAutomata() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/automata'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => FiniteAutomaton.fromJson(json)).toList();
      } else {
        throw AutomatonServiceException('Failed to get automata: ${response.statusCode}');
      }
    } catch (e) {
      throw AutomatonServiceException('Error getting automata: $e');
    }
  }

  /// Get automaton by ID
  Future<FiniteAutomaton> getAutomatonById(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/automata/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return FiniteAutomaton.fromJson(json);
      } else if (response.statusCode == 404) {
        throw AutomatonNotFoundException('Automaton with id $id not found');
      } else {
        throw AutomatonServiceException('Failed to get automaton: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AutomatonNotFoundException) rethrow;
      throw AutomatonServiceException('Error getting automaton: $e');
    }
  }

  /// Create new automaton
  Future<FiniteAutomaton> createAutomaton(FiniteAutomaton automaton) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/automata'),
        headers: _getHeaders(),
        body: jsonEncode(automaton.toJson()),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return FiniteAutomaton.fromJson(json);
      } else {
        throw AutomatonServiceException('Failed to create automaton: ${response.statusCode}');
      }
    } catch (e) {
      throw AutomatonServiceException('Error creating automaton: $e');
    }
  }

  /// Update automaton
  Future<FiniteAutomaton> updateAutomaton(String id, FiniteAutomaton automaton) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/automata/$id'),
        headers: _getHeaders(),
        body: jsonEncode(automaton.toJson()),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return FiniteAutomaton.fromJson(json);
      } else if (response.statusCode == 404) {
        throw AutomatonNotFoundException('Automaton with id $id not found');
      } else {
        throw AutomatonServiceException('Failed to update automaton: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AutomatonNotFoundException) rethrow;
      throw AutomatonServiceException('Error updating automaton: $e');
    }
  }

  /// Delete automaton
  Future<void> deleteAutomaton(String id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/automata/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw AutomatonNotFoundException('Automaton with id $id not found');
      } else {
        throw AutomatonServiceException('Failed to delete automaton: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AutomatonNotFoundException) rethrow;
      throw AutomatonServiceException('Error deleting automaton: $e');
    }
  }

  /// Simulate automaton
  Future<SimulationResult> simulateAutomaton(String id, String input) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/automata/$id/simulate'),
        headers: _getHeaders(),
        body: jsonEncode({'input': input}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SimulationResult.fromJson(json);
      } else if (response.statusCode == 404) {
        throw AutomatonNotFoundException('Automaton with id $id not found');
      } else {
        throw AutomatonServiceException('Failed to simulate automaton: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AutomatonNotFoundException) rethrow;
      throw AutomatonServiceException('Error simulating automaton: $e');
    }
  }

  /// Run algorithm on automaton
  Future<AlgorithmResult> runAlgorithm(String id, String algorithm, Map<String, dynamic> parameters) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/automata/$id/algorithms'),
        headers: _getHeaders(),
        body: jsonEncode({
          'algorithm': algorithm,
          'parameters': parameters,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return AlgorithmResult.fromJson(json);
      } else if (response.statusCode == 404) {
        throw AutomatonNotFoundException('Automaton with id $id not found');
      } else {
        throw AutomatonServiceException('Failed to run algorithm: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AutomatonNotFoundException) rethrow;
      throw AutomatonServiceException('Error running algorithm: $e');
    }
  }

  /// Perform automaton operations
  Future<FiniteAutomaton> performOperation(String operation, List<String> automatonIds, Map<String, dynamic> parameters) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/automata/operations'),
        headers: _getHeaders(),
        body: jsonEncode({
          'operation': operation,
          'automatonIds': automatonIds,
          'parameters': parameters,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return FiniteAutomaton.fromJson(json);
      } else {
        throw AutomatonServiceException('Failed to perform operation: ${response.statusCode}');
      }
    } catch (e) {
      throw AutomatonServiceException('Error performing operation: $e');
    }
  }

  /// Import JFLAP file
  Future<FiniteAutomaton> importJFLAP(String fileContent) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/import/jff'),
        headers: _getHeaders(),
        body: jsonEncode({'content': fileContent}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return FiniteAutomaton.fromJson(json);
      } else {
        throw AutomatonServiceException('Failed to import JFLAP file: ${response.statusCode}');
      }
    } catch (e) {
      throw AutomatonServiceException('Error importing JFLAP file: $e');
    }
  }

  /// Export automaton to JFLAP
  Future<String> exportToJFLAP(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/export/$id/jff'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 404) {
        throw AutomatonNotFoundException('Automaton with id $id not found');
      } else {
        throw AutomatonServiceException('Failed to export to JFLAP: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AutomatonNotFoundException) rethrow;
      throw AutomatonServiceException('Error exporting to JFLAP: $e');
    }
  }

  /// Export automaton to JSON
  Future<Map<String, dynamic>> exportToJSON(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/export/$id/json'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw AutomatonNotFoundException('Automaton with id $id not found');
      } else {
        throw AutomatonServiceException('Failed to export to JSON: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AutomatonNotFoundException) rethrow;
      throw AutomatonServiceException('Error exporting to JSON: $e');
    }
  }

  /// Get headers for requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Dispose the service
  void dispose() {
    _client.close();
  }
}

/// Simulation result
class SimulationResult {
  final bool isAccepted;
  final List<String> finalStates;
  final int steps;
  final List<SimulationStep> trace;

  const SimulationResult({
    required this.isAccepted,
    required this.finalStates,
    required this.steps,
    required this.trace,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    return SimulationResult(
      isAccepted: json['isAccepted'] ?? false,
      finalStates: List<String>.from(json['finalStates'] ?? []),
      steps: json['steps'] ?? 0,
      trace: (json['trace'] as List<dynamic>?)
          ?.map((step) => SimulationStep.fromJson(step))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAccepted': isAccepted,
      'finalStates': finalStates,
      'steps': steps,
      'trace': trace.map((step) => step.toJson()).toList(),
    };
  }
}

/// Simulation step
class SimulationStep {
  final String state;
  final String? inputSymbol;
  final String? outputSymbol;
  final Map<String, dynamic> metadata;

  const SimulationStep({
    required this.state,
    this.inputSymbol,
    this.outputSymbol,
    this.metadata = const {},
  });

  factory SimulationStep.fromJson(Map<String, dynamic> json) {
    return SimulationStep(
      state: json['state'] ?? '',
      inputSymbol: json['inputSymbol'],
      outputSymbol: json['outputSymbol'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'inputSymbol': inputSymbol,
      'outputSymbol': outputSymbol,
      'metadata': metadata,
    };
  }
}

/// Service exceptions
class AutomatonServiceException implements Exception {
  final String message;
  AutomatonServiceException(this.message);
  
  @override
  String toString() => 'AutomatonServiceException: $message';
}

class AutomatonNotFoundException extends AutomatonServiceException {
  AutomatonNotFoundException(String message) : super(message);
  
  @override
  String toString() => 'AutomatonNotFoundException: $message';
}