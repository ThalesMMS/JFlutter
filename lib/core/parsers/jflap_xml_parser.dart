//
//  jflap_xml_parser.dart
//  JFlutter
//
//  Parser dedicado a arquivos JFLAP em XML que valida a estrutura, identifica o tipo
//  de autômato e instancia entidades internas a partir de estados, transições e
//  alfabetos extraídos do documento.
//  Atualmente cobre autômatos finitos, convertendo dados em AutomatonEntity e
//  retornando Result para sinalizar erros de leitura ou formatos não suportados.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:xml/xml.dart';
import '../entities/automaton_entity.dart';
import '../result.dart';

/// Parser para arquivos JFLAP (.jff) em formato XML
class JFLAPXMLParser {
  /// Parse um arquivo JFLAP XML e retorna o autômato correspondente
  static Result<dynamic> parseJFLAPFile(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final root = document.rootElement;

      // Verificar se é um arquivo JFLAP válido
      if (root.name.local != 'structure') {
        return const Failure('Arquivo não é um formato JFLAP válido');
      }

      // Obter o tipo do autômato
      final typeElement = root.findElements('type').firstOrNull;
      if (typeElement == null) {
        return const Failure('Tipo de autômato não especificado');
      }

      final type = typeElement.innerText.trim();

      // Parse baseado no tipo
      switch (type) {
        case 'fa':
          return _parseFSA(root);
        default:
          return Failure('Tipo de autômato não suportado: $type');
      }
    } catch (e) {
      return Failure('Erro ao parsear arquivo JFLAP: $e');
    }
  }

  /// Parse um autômato finito (FSA)
  static Result<AutomatonEntity> _parseFSA(XmlElement root) {
    try {
      final states = <StateEntity>[];
      final transitions = <String, List<String>>{};
      final alphabet = <String>{};
      String? initialId;
      int nextId = 0;

      // Parse estados
      final stateElements = root.findElements('state');
      final stateMap = <String, String>{};

      for (final stateElement in stateElements) {
        final id = stateElement.getAttribute('id') ?? '';
        final name = stateElement.getAttribute('name') ?? id;
        final x = double.tryParse(stateElement.getAttribute('x') ?? '0') ?? 0.0;
        final y = double.tryParse(stateElement.getAttribute('y') ?? '0') ?? 0.0;

        // Verificar se é estado inicial
        final initial = stateElement.findElements('initial').isNotEmpty;

        // Verificar se é estado final
        final finalState = stateElement.findElements('final').isNotEmpty;

        final state = StateEntity(
          id: name,
          name: name,
          x: x,
          y: y,
          isInitial: initial,
          isFinal: finalState,
        );

        states.add(state);
        stateMap[id] = name;

        if (initial) {
          initialId = name;
        }

        nextId++;
      }

      // Parse transições
      final transitionElements = root.findElements('transition');
      for (final transitionElement in transitionElements) {
        final fromId =
            transitionElement
                .findElements('from')
                .firstOrNull
                ?.innerText
                .trim() ??
            '';
        final toId =
            transitionElement
                .findElements('to')
                .firstOrNull
                ?.innerText
                .trim() ??
            '';
        final read =
            transitionElement
                .findElements('read')
                .firstOrNull
                ?.innerText
                .trim() ??
            '';

        final fromState = stateMap[fromId];
        final toState = stateMap[toId];
        final symbol = read.isEmpty ? 'λ' : read;

        if (fromState != null && toState != null) {
          alphabet.add(symbol);
          final key = '$fromState|$symbol';
          transitions[key] = transitions[key] ?? <String>[];
          transitions[key]!.add(toState);
        }
      }

      final automaton = AutomatonEntity(
        id: 'parsed_automaton',
        name: 'Parsed Automaton',
        alphabet: alphabet,
        states: states,
        transitions: transitions,
        initialId: initialId,
        nextId: nextId,
        type: AutomatonType.nfa,
      );

      return Success(automaton);
    } catch (e) {
      return Failure('Erro ao parsear FSA: $e');
    }
  }
}
