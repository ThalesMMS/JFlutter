//
//  serialization_service.dart
//  JFlutter
//
//  Implementa serialização e desserialização de autômatos entre estruturas internas e XML JFLAP, tratando estados, transições e mapeamento seguro de dados.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';
import '../../core/parsers/jflap_xml_codec.dart';
import '../../core/result.dart';
import '../models/automaton_dto.dart';

/// Service for serializing and deserializing automata
class SerializationService {
  /// Serializes automaton to JFLAP XML format
  String serializeAutomatonToJflap(Map<String, dynamic> automatonData) {
    return const JflapXmlCodec().encodeSerializableAutomaton(automatonData);
  }

  /// Deserializes automaton from JFLAP XML format
  Result<Map<String, dynamic>> deserializeAutomatonFromJflap(String xmlString) {
    return const JflapXmlCodec().decodeSerializableAutomaton(xmlString);
  }

  /// Serializes automaton to JSON format
  String serializeAutomatonToJson(Map<String, dynamic> automatonData) {
    final dto = AutomatonDto(
      id: automatonData['id'] as String? ??
          'automaton_${DateTime.now().millisecondsSinceEpoch}',
      name: automatonData['name'] as String? ?? 'Automaton',
      type: automatonData['type'] as String? ?? 'dfa',
      alphabet: (automatonData['alphabet'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      states: (automatonData['states'] as List<dynamic>? ?? []).map((s) {
        final stateMap = s as Map<String, dynamic>;
        return StateDto(
          id: stateMap['id'] as String,
          name: stateMap['name'] as String? ?? stateMap['id'] as String,
          x: (stateMap['x'] as num?)?.toDouble() ?? 0.0,
          y: (stateMap['y'] as num?)?.toDouble() ?? 0.0,
          isInitial: stateMap['isInitial'] as bool? ?? false,
          isFinal: stateMap['isFinal'] as bool? ?? false,
        );
      }).toList(),
      transitions: Map<String, List<String>>.from(
        automatonData['transitions'] as Map<String, dynamic>? ?? {},
      ),
      initialId: automatonData['initialId'] as String?,
      nextId: (automatonData['states'] as List<dynamic>? ?? []).length,
    );

    return jsonEncode(dto.toJson());
  }

  /// Deserializes automaton from JSON format
  Result<Map<String, dynamic>> deserializeAutomatonFromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final dto = AutomatonDto.fromJson(json);

      final automatonData = {
        'id': dto.id,
        'name': dto.name,
        'type': dto.type,
        'alphabet': dto.alphabet,
        'states': dto.states.map((s) => s.toJson()).toList(),
        'transitions': dto.transitions,
        'initialId': dto.initialId,
        'nextId': dto.nextId,
      };

      return Success(automatonData);
    } catch (e) {
      return Failure('Failed to deserialize JSON automaton: $e');
    }
  }

  /// Round-trip test: serialize to format then deserialize back
  Result<Map<String, dynamic>> roundTripTest(
    Map<String, dynamic> automatonData,
    SerializationFormat format,
  ) {
    try {
      String serialized;
      Result<Map<String, dynamic>> deserialized;

      switch (format) {
        case SerializationFormat.jflap:
          serialized = serializeAutomatonToJflap(automatonData);
          deserialized = deserializeAutomatonFromJflap(serialized);
          break;
        case SerializationFormat.json:
          serialized = serializeAutomatonToJson(automatonData);
          deserialized = deserializeAutomatonFromJson(serialized);
          break;
      }

      if (deserialized.isFailure) {
        return Failure('Deserialization failed: ${deserialized.error}');
      }

      return Success(deserialized.data!);
    } catch (e) {
      return Failure('Round-trip test failed: $e');
    }
  }

  /// Validates that serialized data can be deserialized back correctly
  bool validateRoundTrip(
    Map<String, dynamic> original,
    Map<String, dynamic> roundTripped,
  ) {
    // Basic validation - in a real implementation, you'd do deep comparison
    return original['states']?.length == roundTripped['states']?.length &&
        original['transitions']?.length == roundTripped['transitions']?.length;
  }
}

/// Supported serialization formats
enum SerializationFormat {
  jflap('JFLAP XML'),
  json('JSON');

  const SerializationFormat(this.displayName);

  final String displayName;
}
