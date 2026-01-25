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
import 'dart:html' as html;
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
    try {
      final xml = _buildJFLAPXML(automaton);
      return _downloadText(filePath, 'application/xml', xml);
    } catch (e) {
      return Failure('Failed to prepare automaton download: $e');
    }
  }

  Future<Result<FSA>> loadAutomatonFromJFLAP(String filePath) async {
    return const Failure(
      'Loading JFLAP files from a path is not supported on web.',
    );
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
    try {
      final xml = _buildGrammarXML(grammar);
      return _downloadText(filePath, 'application/xml', xml);
    } catch (e) {
      return Failure('Failed to prepare grammar download: $e');
    }
  }

  Future<Result<Grammar>> loadGrammarFromJFLAP(String filePath) async {
    return const Failure(
      'Loading grammars from a path is not supported on web.',
    );
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
    return const Failure('PNG export is not supported on web.');
  }

  Future<StringResult> exportAutomatonToSVG(
    AutomatonEntity automaton,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    try {
      final svg = SvgExporter.exportAutomatonToSvg(automaton, options: options);
      return _downloadText(filePath, 'image/svg+xml', svg);
    } catch (e) {
      return Failure('Failed to export automaton: $e');
    }
  }

  Future<StringResult> exportGrammarToSVG(
    GrammarEntity grammar,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    try {
      final svg = SvgExporter.exportGrammarToSvg(grammar, options: options);
      return _downloadText(filePath, 'image/svg+xml', svg);
    } catch (e) {
      return Failure('Failed to export grammar: $e');
    }
  }

  Future<StringResult> exportTuringMachineToSVG(
    TuringMachineEntity machine,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    try {
      final svg = SvgExporter.exportTuringMachineToSvg(
        machine,
        options: options,
      );
      return _downloadText(filePath, 'image/svg+xml', svg);
    } catch (e) {
      return Failure('Failed to export Turing machine: $e');
    }
  }

  Future<StringResult> exportLegacyAutomatonToSVG(
    FSA automaton,
    String filePath,
  ) async {
    try {
      final svg = _buildLegacySVG(automaton);
      return _downloadText(filePath, 'image/svg+xml', svg);
    } catch (e) {
      return Failure('Failed to export automaton: $e');
    }
  }

  Future<StringResult> getDocumentsDirectory() async {
    return const Failure('Documents directory is not available on web.');
  }

  Future<StringResult> createUniqueFile(
    String baseName,
    String extension,
  ) async {
    return const Failure('File creation is not supported on web.');
  }

  Future<ListResult<String>> listFiles(String extension) async {
    return const Failure('Listing files is not supported on web.');
  }

  Future<BoolResult> deleteFile(String filePath) async {
    return const Failure('Deleting files is not supported on web.');
  }

  String _buildJFLAPXML(FSA automaton) {
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

            for (final transition in automaton.transitions) {
              if (transition is! FSATransition) continue;
              builder.element(
                'transition',
                nest: () {
                  builder.element('from', nest: transition.fromState.id);
                  builder.element('to', nest: transition.toState.id);
                  builder.element('read', nest: transition.symbol);
                },
              );
            }
          },
        );
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  String _buildGrammarXML(Grammar grammar) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'structure',
      nest: () {
        builder.attribute('type', 'grammar');
        builder.element(
          'grammar',
          nest: () {
            builder.attribute('type', grammar.type.name);
            builder.element('start', nest: grammar.startSymbol);

            for (final production in grammar.productions) {
              builder.element(
                'production',
                nest: () {
                  builder.element('left', nest: production.leftSide.join(' '));
                  builder.element(
                    'right',
                    nest: production.rightSide.join(' '),
                  );
                },
              );
            }
          },
        );
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  String _buildLegacySVG(FSA automaton) {
    final states = automaton.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final transitions =
        automaton.transitions.whereType<FSATransition>().toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$_kCanvasWidth" height="$_kCanvasHeight">',
    );

    for (final transition in transitions) {
      final from = transition.fromState.position;
      final to = transition.toState.position;
      buffer.writeln(
        '  <line x1="${from.x}" y1="${from.y}" x2="${to.x}" y2="${to.y}" stroke="$_kStrokeColor" stroke-width="$_kDefaultStrokeWidth"/>',
      );

      final midX = (from.x + to.x) / 2;
      final midY = (from.y + to.y) / 2;
      buffer.writeln(
        '  <text x="$midX" y="$midY" text-anchor="middle" font-family="Arial" font-size="12" fill="$_kTextColor">${transition.label}</text>',
      );
    }

    for (final state in states) {
      final strokeColor = state.isInitial
          ? _kInitialStrokeColor
          : _kStrokeColor;
      final strokeWidth = state.isInitial
          ? _kInitialStrokeWidth
          : _kDefaultStrokeWidth;
      final fillColor = state.isAccepting
          ? _kAcceptingFillColor
          : _kDefaultFillColor;
      buffer.writeln(
        '  <circle cx="${state.position.x}" cy="${state.position.y}" r="$_kStateRadius" fill="$fillColor" stroke="$strokeColor" stroke-width="$strokeWidth"/>',
      );
      buffer.writeln(
        '  <text x="${state.position.x}" y="${state.position.y + 5}" text-anchor="middle" font-family="Arial" font-size="14" fill="$_kTextColor">${state.label}</text>',
      );
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  Future<StringResult> _downloadText(
    String fileName,
    String mimeType,
    String contents,
  ) async {
    final bytes = Uint8List.fromList(utf8.encode(contents));
    return _downloadBytes(fileName, mimeType, bytes);
  }

  Future<StringResult> _downloadBytes(
    String fileName,
    String mimeType,
    Uint8List bytes,
  ) async {
    try {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      return Success(fileName);
    } catch (e) {
      return Failure('Failed to start download: $e');
    }
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

const double _kCanvasWidth = 800;
const double _kCanvasHeight = 600;
const double _kStateRadius = 30;
const double _kDefaultStrokeWidth = 2;
const double _kInitialStrokeWidth = 3;

const String _kDefaultFillColor = '#ffffff';
const String _kAcceptingFillColor = '#add8e6';
const String _kStrokeColor = '#000000';
const String _kInitialStrokeColor = '#ff0000';
const String _kTextColor = '#000000';
