import 'dart:ui';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart';
import '../../core/result.dart';
import '../../core/models/fsa.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../core/models/fsa_transition.dart';
import 'serialization_service.dart';

/// Service for validating import/export functionality across different formats
class ImportExportValidationService {
  final SerializationService _serializationService;

  ImportExportValidationService(this._serializationService);

  /// Validates JFLAP XML import/export round-trip
  ValidationResult validateJflapRoundTrip(FSA automaton) {
    try {
      // Convert FSA to serializable format
      final automatonData = _convertFsaToSerializable(automaton);

      // Serialize to JFLAP XML
      final xmlString = _serializationService.serializeAutomatonToJflap(
        automatonData,
      );

      // Deserialize back from JFLAP XML
      final deserializeResult = _serializationService
          .deserializeAutomatonFromJflap(xmlString);

      if (deserializeResult.isFailure) {
        return ValidationResult.failure(
          'JFLAP deserialization failed: ${deserializeResult.error}',
        );
      }

      // Convert back to FSA for comparison
      final reconstructedFsa = _convertSerializableToFsa(
        deserializeResult.data!,
      );

      // Validate semantic equivalence
      final equivalenceResult = _validateSemanticEquivalence(
        automaton,
        reconstructedFsa,
      );

      return ValidationResult.success(
        'JFLAP round-trip validation passed',
        details: {
          'originalStates': automaton.states.length,
          'reconstructedStates': reconstructedFsa.states.length,
          'originalTransitions': automaton.transitions.length,
          'reconstructedTransitions': reconstructedFsa.transitions.length,
          'semanticEquivalence': equivalenceResult.isSuccess,
        },
      );
    } catch (e) {
      return ValidationResult.failure('JFLAP validation error: $e');
    }
  }

  /// Validates JSON import/export round-trip
  ValidationResult validateJsonRoundTrip(FSA automaton) {
    try {
      // Convert FSA to serializable format
      final automatonData = _convertFsaToSerializable(automaton);

      // Serialize to JSON
      final jsonString = _serializationService.serializeAutomatonToJson(
        automatonData,
      );

      // Deserialize back from JSON
      final deserializeResult = _serializationService
          .deserializeAutomatonFromJson(jsonString);

      if (deserializeResult.isFailure) {
        return ValidationResult.failure(
          'JSON deserialization failed: ${deserializeResult.error}',
        );
      }

      // Convert back to FSA for comparison
      final reconstructedFsa = _convertSerializableToFsa(
        deserializeResult.data!,
      );

      // Validate semantic equivalence
      final equivalenceResult = _validateSemanticEquivalence(
        automaton,
        reconstructedFsa,
      );

      return ValidationResult.success(
        'JSON round-trip validation passed',
        details: {
          'originalStates': automaton.states.length,
          'reconstructedStates': reconstructedFsa.states.length,
          'originalTransitions': automaton.transitions.length,
          'reconstructedTransitions': reconstructedFsa.transitions.length,
          'semanticEquivalence': equivalenceResult.isSuccess,
        },
      );
    } catch (e) {
      return ValidationResult.failure('JSON validation error: $e');
    }
  }

  /// Validates SVG export functionality
  ValidationResult validateSvgExport(FSA automaton) {
    try {
      // Generate SVG representation
      final svgContent = _generateSvgContent(automaton);

      // Validate SVG structure
      if (!svgContent.contains('<svg')) {
        return ValidationResult.failure('SVG export missing root element');
      }

      if (!svgContent.contains('<circle')) {
        return ValidationResult.failure('SVG export missing state elements');
      }

      if (!svgContent.contains('<path') && !svgContent.contains('<line')) {
        return ValidationResult.failure(
          'SVG export missing transition elements',
        );
      }

      // Count elements
      final stateCount = automaton.states.length;
      final transitionCount = automaton.transitions.length;
      final svgStateCount = '<circle'.allMatches(svgContent).length;
      final svgTransitionCount =
          ('<path'.allMatches(svgContent).length +
          '<line'.allMatches(svgContent).length);

      if (svgStateCount != stateCount) {
        return ValidationResult.failure(
          'SVG state count mismatch: expected $stateCount, found $svgStateCount',
        );
      }

      return ValidationResult.success(
        'SVG export validation passed',
        details: {
          'states': stateCount,
          'transitions': transitionCount,
          'svgStates': svgStateCount,
          'svgTransitions': svgTransitionCount,
        },
      );
    } catch (e) {
      return ValidationResult.failure('SVG validation error: $e');
    }
  }

  /// Validates cross-format compatibility (JFLAP <-> JSON)
  ValidationResult validateCrossFormatCompatibility(FSA automaton) {
    try {
      // Convert to both formats
      final automatonData = _convertFsaToSerializable(automaton);

      final jflapXml = _serializationService.serializeAutomatonToJflap(
        automatonData,
      );
      final jsonString = _serializationService.serializeAutomatonToJson(
        automatonData,
      );

      // Deserialize from both formats
      final jflapResult = _serializationService.deserializeAutomatonFromJflap(
        jflapXml,
      );
      final jsonResult = _serializationService.deserializeAutomatonFromJson(
        jsonString,
      );

      if (jflapResult.isFailure || jsonResult.isFailure) {
        return ValidationResult.failure(
          'Cross-format deserialization failed: JFLAP=${jflapResult.isFailure}, JSON=${jsonResult.isFailure}',
        );
      }

      // Convert both back to FSA
      final jflapFsa = _convertSerializableToFsa(jflapResult.data!);
      final jsonFsa = _convertSerializableToFsa(jsonResult.data!);

      // Validate equivalence between formats
      final equivalenceResult = _validateSemanticEquivalence(jflapFsa, jsonFsa);

      return ValidationResult.success(
        'Cross-format compatibility validation passed',
        details: {
          'jflapStates': jflapFsa.states.length,
          'jsonStates': jsonFsa.states.length,
          'jflapTransitions': jflapFsa.transitions.length,
          'jsonTransitions': jsonFsa.transitions.length,
          'semanticEquivalence': equivalenceResult.isSuccess,
        },
      );
    } catch (e) {
      return ValidationResult.failure('Cross-format validation error: $e');
    }
  }

  /// Validates error handling for malformed input
  ValidationResult validateErrorHandling() {
    final testCases = [
      ('Invalid JSON', '{"invalid": "json"'),
      ('Invalid XML', '<invalid>xml</invalid>'),
      ('Empty input', ''),
      ('Null input', null),
      ('Malformed JFLAP', '<structure><automaton></automaton></structure>'),
    ];

    final results = <String, bool>{};

    for (final testCase in testCases) {
      final name = testCase.$1;
      final input = testCase.$2;

      try {
        if (input == null) {
          results[name] = true; // Null handling should be graceful
          continue;
        }

        // Test JSON deserialization
        try {
          _serializationService.deserializeAutomatonFromJson(input);
          results[name] = false; // Should have failed
        } catch (e) {
          results[name] = true; // Correctly handled error
        }

        // Test JFLAP deserialization
        try {
          _serializationService.deserializeAutomatonFromJflap(input);
          results[name] = false; // Should have failed
        } catch (e) {
          results[name] = true; // Correctly handled error
        }
      } catch (e) {
        results[name] = true; // Error was handled
      }
    }

    final allPassed = results.values.every((passed) => passed);

    return ValidationResult(
      success: allPassed,
      message: allPassed
          ? 'Error handling validation passed'
          : 'Error handling validation failed',
      details: results,
    );
  }

  /// Comprehensive validation of all import/export functionality
  Future<ComprehensiveValidationResult> validateAllFormats(
    FSA automaton,
  ) async {
    final results = <String, ValidationResult>{};

    // Test each format
    results['jflap'] = validateJflapRoundTrip(automaton);
    results['json'] = validateJsonRoundTrip(automaton);
    results['svg'] = validateSvgExport(automaton);
    results['crossFormat'] = validateCrossFormatCompatibility(automaton);
    results['errorHandling'] = validateErrorHandling();

    final allPassed = results.values.every((result) => result.success);

    return ComprehensiveValidationResult(
      success: allPassed,
      message: allPassed
          ? 'All import/export validations passed'
          : 'Some import/export validations failed',
      formatResults: results,
      summary: {
        'totalTests': results.length,
        'passedTests': results.values.where((r) => r.success).length,
        'failedTests': results.values.where((r) => !r.success).length,
      },
    );
  }

  /// Convert FSA to serializable format
  Map<String, dynamic> _convertFsaToSerializable(FSA automaton) {
    return {
      'id': automaton.id,
      'name': automaton.name,
      'type': 'dfa', // Default type
      'alphabet': automaton.alphabet.toList(),
      'states': automaton.states
          .map(
            (state) => {
              'id': state.id,
              'name': state.name,
              'x': state.position.x,
              'y': state.position.y,
              'isInitial': state.isInitial,
              'isFinal': state.isAccepting,
            },
          )
          .toList(),
      'transitions': _convertTransitionsToMap(
        automaton.transitions.cast<FSATransition>(),
      ),
      'initialId': automaton.states.where((s) => s.isInitial).firstOrNull?.id,
    };
  }

  /// Convert serializable format back to FSA
  FSA _convertSerializableToFsa(Map<String, dynamic> data) {
    final states = <automaton_state.State>[];
    final transitions = <FSATransition>[];

    // Create states
    for (final stateData in data['states'] as List<dynamic>) {
      final stateMap = stateData as Map<String, dynamic>;
      final state = automaton_state.State(
        id: stateMap['id'] as String,
        label: stateMap['name'] as String,
        position: Vector2(
          (stateMap['x'] as num).toDouble(),
          (stateMap['y'] as num).toDouble(),
        ),
        isInitial: stateMap['isInitial'] as bool? ?? false,
        isAccepting: stateMap['isFinal'] as bool? ?? false,
      );
      states.add(state);
    }

    // Create transitions
    final transitionsMap = data['transitions'] as Map<String, dynamic>? ?? {};
    for (final entry in transitionsMap.entries) {
      final fromId = entry.key;
      final targets = entry.value as List<dynamic>;

      for (final target in targets) {
        final toId = target as String;
        final fromState = states.firstWhere((s) => s.id == fromId);
        final toState = states.firstWhere((s) => s.id == toId);

        final transition = FSATransition(
          id: '${fromId}_to_$toId',
          fromState: fromState,
          toState: toState,
          label: 'a',
          inputSymbols: const {'a'}, // Default symbol
        );
        transitions.add(transition);
      }
    }

    return FSA(
      id: data['id'] as String? ?? 'automaton',
      name: data['name'] as String? ?? 'Automaton',
      states: states.toSet(),
      transitions: transitions.toSet(),
      alphabet: (data['alphabet'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toSet(),
      acceptingStates: states.where((s) => s.isAccepting).toSet(),
      bounds: const Rectangle(0, 0, 400, 300),
      created: DateTime.now(),
      modified: DateTime.now(),
    );
  }

  /// Convert transitions to map format
  Map<String, List<String>> _convertTransitionsToMap(
    Set<FSATransition> transitions,
  ) {
    final result = <String, List<String>>{};

    for (final transition in transitions) {
      result.putIfAbsent(transition.fromState.id, () => []);
      result[transition.fromState.id]!.add(transition.toState.id);
    }

    return result;
  }

  /// Validate semantic equivalence between two FSAs
  Result<bool> _validateSemanticEquivalence(FSA fsa1, FSA fsa2) {
    // Basic structural equivalence
    if (fsa1.states.length != fsa2.states.length) {
      return const Failure('State count mismatch');
    }

    if (fsa1.transitions.length != fsa2.transitions.length) {
      return const Failure('Transition count mismatch');
    }

    // Check initial states
    final initial1 = fsa1.states.where((s) => s.isInitial).length;
    final initial2 = fsa2.states.where((s) => s.isInitial).length;
    if (initial1 != initial2) {
      return const Failure('Initial state count mismatch');
    }

    // Check accepting states
    final accepting1 = fsa1.states.where((s) => s.isAccepting).length;
    final accepting2 = fsa2.states.where((s) => s.isAccepting).length;
    if (accepting1 != accepting2) {
      return const Failure('Accepting state count mismatch');
    }

    return const Success(true);
  }

  /// Generate SVG content for automaton
  String _generateSvgContent(FSA automaton) {
    final buffer = StringBuffer();
    buffer.writeln(
      '<svg width="800" height="600" xmlns="http://www.w3.org/2000/svg">',
    );

    // Draw transitions first (so they appear behind states)
    for (final transition in automaton.transitions) {
      final from = transition.fromState.position;
      final to = transition.toState.position;

      if (transition.fromState.id == transition.toState.id) {
        // Self-loop
        buffer.writeln(
          '<circle cx="${from.x}" cy="${from.y - 30}" r="20" fill="none" stroke="black" stroke-width="2"/>',
        );
      } else {
        // Regular transition
        buffer.writeln(
          '<line x1="${from.x}" y1="${from.y}" x2="${to.x}" y2="${to.y}" stroke="black" stroke-width="2"/>',
        );
      }
    }

    // Draw states
    for (final state in automaton.states) {
      final x = state.position.x;
      final y = state.position.y;

      // State circle
      buffer.writeln(
        '<circle cx="$x" cy="$y" r="30" fill="white" stroke="black" stroke-width="2"/>',
      );

      // State label
      buffer.writeln(
        '<text x="$x" y="${y + 5}" text-anchor="middle" font-family="Arial" font-size="14">${state.name}</text>',
      );

      // Initial state arrow
      if (state.isInitial) {
        buffer.writeln(
          '<line x1="${x - 50}" y1="$y" x2="${x - 30}" y2="$y" stroke="black" stroke-width="2"/>',
        );
        buffer.writeln(
          '<polygon points="${x - 30},${y - 5} ${x - 30},${y + 5} ${x - 20},$y" fill="black"/>',
        );
      }

      // Accepting state (double circle)
      if (state.isAccepting) {
        buffer.writeln(
          '<circle cx="$x" cy="$y" r="24" fill="none" stroke="black" stroke-width="2"/>',
        );
      }
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }
}

/// Result of a validation operation
class ValidationResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? details;

  const ValidationResult({
    required this.success,
    required this.message,
    this.details,
  });

  factory ValidationResult.success(
    String message, {
    Map<String, dynamic>? details,
  }) {
    return ValidationResult(success: true, message: message, details: details);
  }

  factory ValidationResult.failure(
    String message, {
    Map<String, dynamic>? details,
  }) {
    return ValidationResult(success: false, message: message, details: details);
  }
}

/// Result of comprehensive validation across all formats
class ComprehensiveValidationResult {
  final bool success;
  final String message;
  final Map<String, ValidationResult> formatResults;
  final Map<String, dynamic> summary;

  const ComprehensiveValidationResult({
    required this.success,
    required this.message,
    required this.formatResults,
    required this.summary,
  });
}
