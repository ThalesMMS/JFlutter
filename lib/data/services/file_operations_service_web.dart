//
//  file_operations_service_web.dart
//  JFlutter
//
//  Web-friendly implementation of the FileOperationsService that relies on
//  in-memory representations instead of direct filesystem access. Only
//  operations that can be executed without `dart:io` are supported; attempts to
//  interact with the local filesystem return explicit failures so the UI can
//  surface clear feedback to the user.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/entities/grammar_entity.dart';
import '../../core/entities/turing_machine_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/production.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../core/models/fsa_transition.dart';
import '../../core/result.dart';
import '../../presentation/widgets/export/svg_exporter.dart';

/// Service for file operations tailored for web environments.
class FileOperationsService {
  Future<StringResult> saveAutomatonToJFLAP(
    FSA automaton,
    String filePath,
  ) async {
    return Failure('Saving JFLAP files is not supported on web.');
  }

  Future<Result<FSA>> loadAutomatonFromJFLAP(String filePath) async {
    return Failure('Loading JFLAP files from a path is not supported on web.');
  }

  Future<Result<FSA>> loadAutomatonFromBytes(Uint8List bytes) async {
    try {
      final xmlString = utf8.decode(bytes);
      final document = XmlDocument.parse(xmlString);
      final automaton = _parseJFLAPXML(document);
      return Success(automaton);
    } catch (e) {
      return Failure('Failed to load automaton from provided data: $e');
    }
  }

  Future<StringResult> saveGrammarToJFLAP(
    Grammar grammar,
    String filePath,
  ) async {
    return Failure('Saving grammars is not supported on web.');
  }

  Future<Result<Grammar>> loadGrammarFromJFLAP(String filePath) async {
    return Failure('Loading grammars from a path is not supported on web.');
  }

  Future<Result<Grammar>> loadGrammarFromBytes(Uint8List bytes) async {
    try {
      final xmlString = utf8.decode(bytes);
      final document = XmlDocument.parse(xmlString);
      final grammar = _parseGrammarXML(document);
      return Success(grammar);
    } catch (e) {
      return Failure('Failed to load grammar from provided data: $e');
    }
  }

  Future<StringResult> exportAutomatonToPNG(
    FSA automaton,
    String filePath,
  ) async {
    return Failure('PNG export is not supported on web.');
  }

  Future<StringResult> exportAutomatonToSVG(
    AutomatonEntity automaton,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    return Failure('SVG export is not supported on web.');
  }

  Future<StringResult> exportGrammarToSVG(
    GrammarEntity grammar,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    return Failure('SVG export is not supported on web.');
  }

  Future<StringResult> exportTuringMachineToSVG(
    TuringMachineEntity machine,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    return Failure('SVG export is not supported on web.');
  }

  Future<StringResult> exportLegacyAutomatonToSVG(
    FSA automaton,
    String filePath,
  ) async {
    return Failure('Legacy SVG export is not supported on web.');
  }

  Future<StringResult> getDocumentsDirectory() async {
    return Failure('Documents directory is not available on web.');
  }

  Future<StringResult> createUniqueFile(
    String baseName,
    String extension,
  ) async {
    return Failure('File creation is not supported on web.');
  }

  Future<ListResult<String>> listFiles(String extension) async {
    return Failure('Listing files is not supported on web.');
  }

  Future<BoolResult> deleteFile(String filePath) async {
    return Failure('Deleting files is not supported on web.');
  }

  FSA _parseJFLAPXML(XmlDocument document) {
    final automatonElement = document.findAllElements('automaton').first;
    final states = <automaton_state.State>[];
    final transitions = <FSATransition>[];

    for (final stateElement in automatonElement.findAllElements('state')) {
      final id = stateElement.getAttribute('id')!;
      final name = stateElement.getAttribute('name') ?? id;
      final x = double.parse(stateElement.findElements('x').first.text);
      final y = double.parse(stateElement.findElements('y').first.text);
      final isInitial = stateElement.findElements('initial').isNotEmpty;
      final isAccepting = stateElement.findElements('final').isNotEmpty;

      states.add(
        automaton_state.State(
          id: id,
          label: name,
          position: Vector2(x, y),
          isInitial: isInitial,
          isAccepting: isAccepting,
        ),
      );
    }

    for (final transitionElement in automatonElement.findAllElements(
      'transition',
    )) {
      final fromId = transitionElement.findElements('from').first.text;
      final toId = transitionElement.findElements('to').first.text;
      final symbol = transitionElement.findElements('read').first.text;

      final fromState = states.firstWhere((s) => s.id == fromId);
      final toState = states.firstWhere((s) => s.id == toId);

      transitions.add(
        FSATransition(
          id: 't${transitions.length}',
          fromState: fromState,
          toState: toState,
          label: symbol,
          inputSymbols: {symbol},
        ),
      );
    }

    return FSA(
      id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Imported Automaton',
      states: states.toSet(),
      transitions: transitions.toSet(),
      alphabet: transitions.map((t) => t.symbol).toSet(),
      initialState: states.firstWhere(
        (s) => s.isInitial,
        orElse: () => states.first,
      ),
      acceptingStates: states.where((s) => s.isAccepting).toSet(),
      bounds: const math.Rectangle(0, 0, 400, 300),
      created: DateTime.now(),
      modified: DateTime.now(),
    );
  }

  Grammar _parseGrammarXML(XmlDocument document) {
    final grammarElement = document.findAllElements('grammar').first;
    final startSymbol = grammarElement.findElements('start').first.text;
    final productions = <Production>{};

    for (final productionElement in grammarElement.findAllElements(
      'production',
    )) {
      final leftSide = productionElement
          .findElements('left')
          .first
          .text
          .split(' ');
      final rightSide = productionElement
          .findElements('right')
          .first
          .text
          .split(' ');

      productions.add(
        Production(
          id: 'p${productions.length}',
          leftSide: leftSide,
          rightSide: rightSide,
          order: productions.length,
        ),
      );
    }

    return Grammar(
      id: 'imported_grammar_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Imported Grammar',
      terminals: productions
          .expand((p) => p.rightSide)
          .where((s) => s.isNotEmpty)
          .toSet(),
      nonterminals: productions.expand((p) => p.leftSide).toSet(),
      startSymbol: startSymbol,
      productions: productions,
      type: GrammarType.contextFree,
      created: DateTime.now(),
      modified: DateTime.now(),
    );
  }
}
