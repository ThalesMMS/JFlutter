//
//  serialization_service.dart
//  JFlutter
//
//  Implementa serialização e desserialização de autômatos entre estruturas internas e XML JFLAP, tratando estados, transições e mapeamento seguro de dados.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';
import 'package:xml/xml.dart';
import '../../core/result.dart';
import '../../core/utils/automaton_id_utils.dart';
import '../../core/utils/epsilon_utils.dart';
import '../models/automaton_dto.dart';

/// Service for serializing and deserializing automata
class SerializationService {
  /// Serializes automaton to JFLAP XML format
  String serializeAutomatonToJflap(Map<String, dynamic> automatonData) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    final rawType = (automatonData['type'] as String? ?? 'fa').toLowerCase();
    final automatonType =
        rawType == 'dfa' || rawType == 'nfa' || rawType == 'fa'
            ? 'fa'
            : rawType;

    builder.element(
      'structure',
      nest: () {
        builder.attribute('type', automatonType);
        builder.element('type', nest: automatonType);
        builder.element(
          'automaton',
          nest: () {
            // Force explicit open/close tags even when empty so consumers don't
            // receive self-closing <automaton/> nodes.
            builder.text('\n');

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
                  final x = (stateMap['x'] as num?)?.toDouble();
                  final y = (stateMap['y'] as num?)?.toDouble();
                  if (x != null) {
                    builder.element('x', nest: x.toString());
                  }
                  if (y != null) {
                    builder.element('y', nest: y.toString());
                  }
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
              final keyParts = transition.key.split('|');
              final fromState =
                  keyParts.isNotEmpty ? keyParts.first.trim() : transition.key;
              final rawSymbol =
                  keyParts.length > 1 ? keyParts.sublist(1).join('|') : null;
              final readSymbol = _normalizeTransitionSymbol(rawSymbol);
              final targets = transition.value as List<dynamic>? ?? [];

              for (final target in targets) {
                final toStateId =
                    target is String ? target : target?.toString() ?? '';
                if (fromState.isEmpty || toStateId.isEmpty) {
                  continue;
                }
                builder.element(
                  'transition',
                  nest: () {
                    builder.element('from', nest: fromState);
                    builder.element('to', nest: toStateId);
                    // JFLAP XML spec: epsilon transitions must use empty <read/>
                    // tags, not <read>ε</read>. See epsilon_utils.dart for
                    // canonical epsilon representation.
                    if (isEpsilonSymbol(readSymbol)) {
                      builder.element('read', isSelfClosing: true);
                    } else {
                      builder.element('read', nest: readSymbol);
                    }
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
      final root = document.rootElement;
      if (root.name.local != 'structure') {
        return const Failure(
          'Failed to deserialize JFLAP automaton: Root element must be <structure>',
        );
      }
      final automatonElements = document.findAllElements('automaton');
      final automatonElement =
          automatonElements.isEmpty ? null : automatonElements.first;

      if (automatonElement == null) {
        return const Failure(
          'Failed to deserialize JFLAP automaton: No <automaton> element found',
        );
      }

      final typeElement = root.getElement('type');
      final typeAttribute = root.getAttribute('type');
      final sourceType = (typeElement?.innerText.trim().isNotEmpty ?? false)
          ? typeElement!.innerText.trim()
          : (typeAttribute ?? 'fa');

      final states = <Map<String, dynamic>>[];
      final transitions = <String, List<String>>{};
      final alphabet = <String>{};
      String? initialState;
      var hasEpsilonTransition = false;
      var hasNondeterministicTransition = false;
      final idLookup = <String, String>{};

      // Parse states
      for (final stateElement in automatonElement.findAllElements('state')) {
        final id = stateElement.getAttribute('id') ??
            stateElement.getAttribute('name') ??
            '';
        if (id.isEmpty) {
          continue;
        }
        final name = stateElement.getAttribute('name') ?? id;
        final xText = stateElement.getAttribute('x') ??
            stateElement.getElement('x')?.innerText;
        final yText = stateElement.getAttribute('y') ??
            stateElement.getElement('y')?.innerText;
        final x = double.tryParse(xText ?? '') ?? 0.0;
        final y = double.tryParse(yText ?? '') ?? 0.0;
        final isInitial = stateElement.findElements('initial').isNotEmpty;
        final isFinal = stateElement.findElements('final').isNotEmpty;

        final state = {
          'id': id,
          'name': name,
          'x': x,
          'y': y,
          'isInitial': isInitial,
          'isFinal': isFinal,
        };
        states.add(state);
        idLookup[id] = id;
        idLookup[name] = id;

        if (isInitial) {
          initialState = id;
        }
      }

      // Parse transitions
      for (final transitionElement in automatonElement.findAllElements(
        'transition',
      )) {
        final fromElements = transitionElement.findElements('from');
        final toElements = transitionElement.findElements('to');
        if (fromElements.isEmpty || toElements.isEmpty) {
          continue;
        }

        final rawFrom = fromElements.first.innerText.trim();
        final rawTo = toElements.first.innerText.trim();
        if (!idLookup.containsKey(rawFrom) || !idLookup.containsKey(rawTo)) {
          return Failure(
            'Failed to deserialize JFLAP automaton: Transition references unknown state $rawFrom -> $rawTo',
          );
        }
        final from = idLookup[rawFrom]!;
        final to = idLookup[rawTo]!;
        final readElements = transitionElement.findElements('read');
        final rawSymbol =
            readElements.isEmpty ? null : readElements.first.innerText;
        final symbol = _normalizeTransitionSymbol(rawSymbol);
        final key = '$from|$symbol';

        transitions.putIfAbsent(key, () => <String>[]);
        if (!transitions[key]!.contains(to)) {
          transitions[key]!.add(to);
        }
        if (isEpsilonSymbol(symbol)) {
          hasEpsilonTransition = true;
        } else if (transitions[key]!.length > 1) {
          hasNondeterministicTransition = true;
        } else if (symbol.isNotEmpty) {
          alphabet.add(symbol);
        }
      }

      final automatonData = {
        'id': _generateImportedAutomatonId(),
        'name': 'Imported Automaton',
        'states': states,
        'transitions': transitions.map(
          (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
        ),
        'alphabet': alphabet.toList(),
        'initialId': initialState,
        'type': _deriveFsaType(
          sourceType: sourceType,
          hasEpsilonTransition: hasEpsilonTransition,
          hasNondeterministicTransition: hasNondeterministicTransition,
        ),
        'nextId': AutomatonIdUtils.calculateNextAutomatonId(states),
      };

      return Success(automatonData);
    } catch (e) {
      return Failure('Failed to deserialize JFLAP automaton: $e');
    }
  }

  /// Normalizes transition symbols to handle epsilon consistently.
  ///
  /// Converts all epsilon aliases (ε, λ, epsilon, empty, etc.) to the canonical
  /// epsilon symbol 'ε' for both serialization and deserialization.
  ///
  /// - During serialization: ensures epsilon transitions emit empty `<read/>`
  /// - During deserialization: ensures epsilon from XML becomes 'ε' in keys
  ///
  /// Delegates to [normalizeToEpsilon] from epsilon_utils for consistent handling.
  String _normalizeTransitionSymbol(String? symbol) {
    return normalizeToEpsilon(symbol);
  }

  String _generateImportedAutomatonId() {
    return 'imported_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _deriveFsaType({
    required String sourceType,
    required bool hasEpsilonTransition,
    required bool hasNondeterministicTransition,
  }) {
    final normalized = sourceType.trim().toLowerCase();
    if (hasEpsilonTransition || hasNondeterministicTransition) {
      return 'nfa';
    }
    if (normalized == 'nfa') {
      return 'nfa';
    }
    if (normalized == 'dfa') {
      return 'dfa';
    }
    if (normalized == 'fa') {
      return 'dfa';
    }
    return 'nfa';
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
