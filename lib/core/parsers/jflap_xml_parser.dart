//
//  jflap_xml_parser.dart
//  JFlutter
//
//  Parser dedicado a arquivos JFLAP em XML que valida a estrutura, identifica o
//  tipo de autômato e reconstrói a estrutura serializável usada pelos serviços
//  de importação/exportação.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:collection/collection.dart';
import 'package:xml/xml.dart';
import '../result.dart';
import '../utils/automaton_id_utils.dart';
import '../utils/epsilon_utils.dart';

/// Parser para arquivos JFLAP (.jff) em formato XML
class JFLAPXMLParser {
  /// Parse um arquivo JFLAP XML e retorna o mapa estruturado correspondente
  static Result<Map<String, dynamic>> parseJFLAPFile(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final root = document.rootElement;

      // Verificar se é um arquivo JFLAP válido
      if (root.name.local != 'structure') {
        return const Failure('Arquivo não é um formato JFLAP válido');
      }

      // Obter o tipo do autômato (elemento <type> ou atributo type)
      final typeElement = root.findElements('type').firstOrNull;
      final typeAttribute = root.getAttribute('type');
      final type = ((typeElement?.innerText ?? typeAttribute ?? 'fa').trim())
          .toLowerCase();

      // Parse baseado no tipo
      switch (type) {
        case 'fa':
        case 'dfa':
        case 'nfa':
          return _parseFsa(root, sourceType: type);
        default:
          return Failure('Tipo de autômato não suportado: $type');
      }
    } catch (e) {
      return Failure('Erro ao parsear arquivo JFLAP: $e');
    }
  }

  /// Parse um autômato finito (FSA) para a estrutura de dados interna
  static Result<Map<String, dynamic>> _parseFsa(
    XmlElement root, {
    required String sourceType,
  }) {
    try {
      final automatonElement = root.findElements('automaton').firstOrNull;
      if (automatonElement == null) {
        return const Failure('Elemento <automaton> não encontrado');
      }

      final states = <Map<String, dynamic>>[];
      final transitions = <String, List<String>>{};
      final alphabet = <String>{};
      String? initialId;
      var hasEpsilonTransition = false;
      var hasNondeterministicTransition = false;

      // Tabela para mapear IDs (numéricos ou rótulos) para o identificador final
      final idLookup = <String, String>{};

      for (final stateElement in automatonElement.findElements('state')) {
        final id = stateElement.getAttribute('id') ??
            stateElement.getAttribute('name');
        if (id == null || id.isEmpty) {
          // Ignora estados sem identificador
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

        states.add({
          'id': id,
          'name': name,
          'x': x,
          'y': y,
          'isInitial': isInitial,
          'isFinal': isFinal,
        });

        idLookup[id] = id;
        idLookup[name] = id;

        if (isInitial && initialId == null) {
          initialId = id;
        }
      }

      for (final transitionElement in automatonElement.findElements(
        'transition',
      )) {
        final rawFrom = transitionElement
                .findElements('from')
                .firstOrNull
                ?.innerText
                .trim() ??
            '';
        final rawTo = transitionElement
                .findElements('to')
                .firstOrNull
                ?.innerText
                .trim() ??
            '';
        final rawRead =
            transitionElement.findElements('read').firstOrNull?.innerText ?? '';

        if (!idLookup.containsKey(rawFrom) || !idLookup.containsKey(rawTo)) {
          return Failure(
            'Transicao referencia estado desconhecido: $rawFrom -> $rawTo',
          );
        }
        final fromId = idLookup[rawFrom]!;
        final toId = idLookup[rawTo]!;

        final symbol = normalizeToEpsilon(rawRead);
        final key = '$fromId|$symbol';
        transitions.putIfAbsent(key, () => <String>[]);
        if (!transitions[key]!.contains(toId)) {
          transitions[key]!.add(toId);
        }
        hasEpsilonTransition = hasEpsilonTransition || isEpsilonSymbol(symbol);
        hasNondeterministicTransition =
            hasNondeterministicTransition || transitions[key]!.length > 1;

        // Only add non-epsilon symbols to the alphabet.
        // Epsilon is a special transition symbol, not part of the input alphabet.
        if (symbol.isNotEmpty && !isEpsilonSymbol(symbol)) {
          alphabet.add(symbol);
        }
      }

      final parsed = <String, dynamic>{
        'id': 'parsed_automaton',
        'name': 'Parsed Automaton',
        'type': _deriveFsaType(
          sourceType: sourceType,
          hasEpsilonTransition: hasEpsilonTransition,
          hasNondeterministicTransition: hasNondeterministicTransition,
        ),
        'alphabet': alphabet.toList(),
        'states': states,
        'transitions': transitions.map(
          (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
        ),
        'initialId':
            initialId ?? (states.isNotEmpty ? states.first['id'] : null),
        'nextId': AutomatonIdUtils.calculateNextAutomatonId(states),
      };

      return Success(parsed);
    } catch (e) {
      return Failure('Erro ao parsear FSA: $e');
    }
  }

  static String _deriveFsaType({
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
