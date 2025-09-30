import 'dart:convert';
import 'package:xml/xml.dart';
import '../../core/result.dart';
import '../models/automaton_dto.dart';

/// Service for serializing and deserializing automata
class SerializationService {
  /// Serializes automaton to JFLAP XML format
  String serializeAutomatonToJflap(Map<String, dynamic> automatonData) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element(
      'structure',
      nest: () {
        builder.attribute('type', 'fa');
        builder.element(
          'automaton',
          nest: () {
            // Add states
            final states = automatonData['states'] as List<dynamic>? ?? [];
            for (final state in states) {
              final stateMap = state as Map<String, dynamic>;
              builder.element(
                'state',
                nest: () {
                  builder.attribute('id', stateMap['id'] as String);
                  builder.attribute(
                    'name',
                    stateMap['name'] as String? ?? stateMap['id'] as String,
                  );
                  if (stateMap['isInitial'] == true) {
                    builder.element('initial');
                  }
                  if (stateMap['isFinal'] == true) {
                    builder.element('final');
                  }
                },
              );
            }

            // Add transitions
            final transitions =
                automatonData['transitions'] as Map<String, dynamic>? ?? {};
            for (final transition in transitions.entries) {
              final from = transition.key;
              final targets = transition.value as List<dynamic>? ?? [];
              for (final target in targets) {
                builder.element(
                  'transition',
                  nest: () {
                    builder.element('from', nest: from);
                    builder.element('to', nest: target as String);
                    builder.element(
                      'read',
                      nest: '',
                    ); // JFLAP uses empty string for epsilon
                  },
                );
              }
            }
          },
        );
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Deserializes automaton from JFLAP XML format
  Result<Map<String, dynamic>> deserializeAutomatonFromJflap(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final automatonElement = document.findAllElements('automaton').first;

      final states = <Map<String, dynamic>>[];
      final transitions = <String, List<String>>{};
      String? initialState;

      // Parse states
      for (final stateElement in automatonElement.findAllElements('state')) {
        final id = stateElement.getAttribute('id')!;
        final name = stateElement.getAttribute('name') ?? id;
        final isInitial = stateElement.findElements('initial').isNotEmpty;
        final isFinal = stateElement.findElements('final').isNotEmpty;

        final state = {
          'id': id,
          'name': name,
          'isInitial': isInitial,
          'isFinal': isFinal,
        };
        states.add(state);

        if (isInitial) {
          initialState = id;
        }
      }

      // Parse transitions
      for (final transitionElement in automatonElement.findAllElements(
        'transition',
      )) {
        final from = transitionElement.findElements('from').first.innerText;
        final to = transitionElement.findElements('to').first.innerText;

        transitions.putIfAbsent(from, () => []);
        transitions[from]!.add(to);
      }

      final automatonData = {
        'states': states,
        'transitions': transitions,
        'initialId': initialState,
        'type': 'dfa',
      };

      return Success(automatonData);
    } catch (e) {
      return Failure('Failed to deserialize JFLAP automaton: $e');
    }
  }

  /// Serializes automaton to JSON format
  String serializeAutomatonToJson(Map<String, dynamic> automatonData) {
    final dto = AutomatonDto(
      id:
          automatonData['id'] as String? ??
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
          x: 0.0, // Default position
          y: 0.0,
          isInitial: stateMap['isInitial'] as bool? ?? false,
          isFinal: stateMap['isFinal'] as bool? ?? false,
        );
      }).toList(),
      transitions:
          automatonData['transitions'] as Map<String, List<String>>? ?? {},
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
