import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';

import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/state.dart' as automaton_state;
import '../result.dart';
import '../utils/automaton_id_utils.dart';
import '../utils/epsilon_utils.dart';

/// Shared JFLAP XML codec for finite automata.
class JflapXmlCodec {
  const JflapXmlCodec();

  /// Encodes an [FSA] into JFLAP XML for file-operation exports.
  String encodeFsa(FSA automaton) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'structure',
      nest: () {
        builder.attribute('type', 'fa');
        builder.element(
          'automaton',
          nest: () {
            for (final state in automaton.states) {
              _writeFsaState(builder, state);
            }

            for (final transition in automaton.transitions) {
              if (transition is! FSATransition) continue;
              for (final symbol in _symbolsForTransition(transition)) {
                _writeTransition(
                  builder,
                  from: transition.fromState.id,
                  to: transition.toState.id,
                  symbol: symbol,
                );
              }
            }
          },
        );
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Decodes JFLAP XML into an [FSA] for file-operation imports.
  Result<FSA> decodeFsaXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    return decodeFsaDocument(document);
  }

  /// Decodes a parsed JFLAP document into an [FSA].
  Result<FSA> decodeFsaDocument(XmlDocument document) {
    final automatonElement = document.findAllElements('automaton').firstOrNull;
    if (automatonElement == null) {
      return const Failure('JFLAP import is missing the <automaton> element.');
    }

    final states = <automaton_state.State>[];
    final transitions = <FSATransition>[];
    final alphabet = <String>{};

    for (final stateElement in automatonElement.findAllElements('state')) {
      final id = stateElement.getAttribute('id');
      final name = stateElement.getAttribute('name');
      final idOrName = id ?? name;
      if (idOrName == null || idOrName.isEmpty) {
        continue;
      }

      states.add(
        automaton_state.State(
          id: idOrName,
          label: name ?? idOrName,
          position: _readPosition(stateElement),
          isInitial: stateElement.findElements('initial').isNotEmpty,
          isAccepting: stateElement.findElements('final').isNotEmpty,
        ),
      );
    }

    if (states.isEmpty) {
      return const Failure(
        'JFLAP import does not contain any states. Empty automata cannot be loaded into the editor.',
      );
    }

    for (final transitionElement in automatonElement.findAllElements(
      'transition',
    )) {
      final fromId =
          transitionElement.findElements('from').firstOrNull?.innerText.trim();
      final toId =
          transitionElement.findElements('to').firstOrNull?.innerText.trim();
      if (fromId == null || fromId.isEmpty || toId == null || toId.isEmpty) {
        return const Failure(
          'JFLAP import contains a transition without valid origin and destination states.',
        );
      }

      final symbol = normalizeToEpsilon(
        transitionElement.findElements('read').firstOrNull?.innerText,
      );
      final fromState = _findState(states, fromId);
      final toState = _findState(states, toId);
      if (fromState == null || toState == null) {
        return Failure(
          'JFLAP import references an unknown state in transition $fromId -> $toId.',
        );
      }

      final isEpsilon = isEpsilonSymbol(symbol);
      if (!isEpsilon && symbol.isNotEmpty) {
        alphabet.add(symbol);
      }

      transitions.add(
        FSATransition(
          id: 't${transitions.length}',
          fromState: fromState,
          toState: toState,
          label: symbol,
          inputSymbols: isEpsilon ? const {} : {symbol},
          lambdaSymbol: isEpsilon ? kEpsilonSymbol : null,
        ),
      );
    }

    final now = DateTime.now();
    return Success(
      FSA(
        id: 'imported_${now.millisecondsSinceEpoch}',
        name: 'Imported Automaton',
        states: states.toSet(),
        transitions: transitions.toSet(),
        alphabet: alphabet,
        initialState: states.firstWhere(
          (s) => s.isInitial,
          orElse: () => states.first,
        ),
        acceptingStates: states.where((s) => s.isAccepting).toSet(),
        bounds: const math.Rectangle(0, 0, 400, 300),
        created: now,
        modified: now,
      ),
    );
  }

  /// Encodes the serializable automaton map used by data services.
  String encodeSerializableAutomaton(Map<String, dynamic> automatonData) {
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
            builder.text('\n');

            final states = automatonData['states'] as List<dynamic>? ?? [];
            for (final state in states) {
              _writeSerializableState(
                builder,
                state as Map<String, dynamic>,
              );
            }

            final transitions =
                automatonData['transitions'] as Map<String, dynamic>? ?? {};
            for (final transition in transitions.entries) {
              final keyParts = transition.key.split('|');
              final fromState =
                  keyParts.isNotEmpty ? keyParts.first.trim() : transition.key;
              final rawSymbol =
                  keyParts.length > 1 ? keyParts.sublist(1).join('|') : null;
              final readSymbol = normalizeToEpsilon(rawSymbol);
              final targets = transition.value as List<dynamic>? ?? [];

              for (final target in targets) {
                final toStateId =
                    target is String ? target : target?.toString() ?? '';
                if (fromState.isEmpty || toStateId.isEmpty) {
                  continue;
                }
                _writeTransition(
                  builder,
                  from: fromState,
                  to: toStateId,
                  symbol: readSymbol,
                );
              }
            }
          },
        );
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Decodes JFLAP XML into the serializable automaton map used by services.
  Result<Map<String, dynamic>> decodeSerializableAutomaton(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final root = document.rootElement;
      if (root.name.local != 'structure') {
        return const Failure(
          'Failed to deserialize JFLAP automaton: Root element must be <structure>',
        );
      }

      final automatonElement =
          document.findAllElements('automaton').firstOrNull;
      if (automatonElement == null) {
        return const Failure(
          'Failed to deserialize JFLAP automaton: No <automaton> element found',
        );
      }

      return _decodeSerializableRoot(root, automatonElement);
    } catch (e) {
      return Failure('Failed to deserialize JFLAP automaton: $e');
    }
  }

  Result<Map<String, dynamic>> _decodeSerializableRoot(
    XmlElement root,
    XmlElement automatonElement,
  ) {
    final typeElement = root.getElement('type');
    final typeAttribute = root.getAttribute('type');
    final sourceType = (typeElement?.innerText.trim().isNotEmpty ?? false)
        ? typeElement!.innerText.trim()
        : (typeAttribute ?? 'fa');

    final states = <Map<String, dynamic>>[];
    final transitions = <String, List<String>>{};
    final alphabet = <String>{};
    final idLookup = <String, String>{};
    String? initialState;
    var hasEpsilonTransition = false;
    var hasNondeterministicTransition = false;

    for (final stateElement in automatonElement.findAllElements('state')) {
      final id = stateElement.getAttribute('id') ??
          stateElement.getAttribute('name') ??
          '';
      if (id.isEmpty) {
        continue;
      }

      final name = stateElement.getAttribute('name') ?? id;
      final position = _readPosition(stateElement);
      final isInitial = stateElement.findElements('initial').isNotEmpty;
      final isFinal = stateElement.findElements('final').isNotEmpty;

      states.add({
        'id': id,
        'name': name,
        'x': position.x,
        'y': position.y,
        'isInitial': isInitial,
        'isFinal': isFinal,
      });
      idLookup[id] = id;
      idLookup[name] = id;

      if (isInitial) {
        initialState = id;
      }
    }

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
      final rawSymbol =
          transitionElement.findElements('read').firstOrNull?.innerText;
      final symbol = normalizeToEpsilon(rawSymbol);
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

    return Success({
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
    });
  }

  void _writeFsaState(XmlBuilder builder, automaton_state.State state) {
    builder.element(
      'state',
      nest: () {
        builder.attribute('id', state.id);
        builder.attribute('name', state.label);
        if (state.isInitial) {
          builder.element('initial');
        }
        if (state.isAccepting) {
          builder.element('final');
        }
        builder.element('x', nest: state.position.x.toString());
        builder.element('y', nest: state.position.y.toString());
      },
    );
  }

  void _writeSerializableState(
    XmlBuilder builder,
    Map<String, dynamic> stateMap,
  ) {
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

  void _writeTransition(
    XmlBuilder builder, {
    required String from,
    required String to,
    required String symbol,
  }) {
    builder.element(
      'transition',
      nest: () {
        builder.element('from', nest: from);
        builder.element('to', nest: to);
        if (isEpsilonSymbol(symbol)) {
          builder.element('read', isSelfClosing: true);
        } else {
          builder.element('read', nest: symbol);
        }
      },
    );
  }

  Iterable<String> _symbolsForTransition(FSATransition transition) {
    if (transition.inputSymbols.isEmpty) {
      return {transition.symbol};
    }
    return transition.inputSymbols;
  }

  Vector2 _readPosition(XmlElement stateElement) {
    final xText = stateElement.getAttribute('x') ??
        stateElement.findElements('x').firstOrNull?.innerText ??
        '0.0';
    final yText = stateElement.getAttribute('y') ??
        stateElement.findElements('y').firstOrNull?.innerText ??
        '0.0';
    return Vector2(
      double.tryParse(xText) ?? 0.0,
      double.tryParse(yText) ?? 0.0,
    );
  }

  automaton_state.State? _findState(
    List<automaton_state.State> states,
    String idOrLabel,
  ) {
    return states.firstWhereOrNull(
      (s) => s.id == idOrLabel || s.label == idOrLabel,
    );
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
}
