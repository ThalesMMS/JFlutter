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
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:xml/xml.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/entities/grammar_entity.dart';
import '../../core/entities/turing_machine_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/production.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/parsers/jflap_xml_codec.dart';
import '../../core/result.dart';
import '../../presentation/widgets/export/svg_exporter.dart';

/// Service for file operations tailored for web environments.
class FileOperationsService {
  /// Creates the JFLAP XML payload without starting a download.
  String serializeAutomatonToJFLAPString(FSA automaton) {
    return const JflapXmlCodec().encodeFsa(automaton);
  }

  /// Creates the JSON payload without starting a download.
  String serializeAutomatonToJsonString(FSA automaton) {
    return jsonEncode(automaton.toJson());
  }

  /// Creates the grammar JFLAP payload without starting a download.
  String serializeGrammarToJFLAPString(Grammar grammar) {
    return _buildGrammarXML(grammar);
  }

  /// Creates the SVG payload without starting a download.
  String exportAutomatonToSvgString(
    AutomatonEntity automaton, {
    SvgExportOptions? options,
  }) {
    return SvgExporter.exportAutomatonToSvg(automaton, options: options);
  }

  /// Creates the grammar SVG payload without starting a download.
  String exportGrammarToSvgString(
    GrammarEntity grammar, {
    SvgExportOptions? options,
  }) {
    return SvgExporter.exportGrammarToSvg(grammar, options: options);
  }

  /// Creates the Turing machine SVG payload without starting a download.
  String exportTuringMachineToSvgString(
    TuringMachineEntity machine, {
    SvgExportOptions? options,
  }) {
    return SvgExporter.exportTuringMachineToSvg(machine, options: options);
  }

  /// Creates the legacy FSA SVG payload without starting a download.
  String exportLegacyAutomatonToSvgString(FSA automaton) {
    return _buildLegacySVG(automaton);
  }

  /// PNG rendering is not available in the web service implementation.
  Future<Result<Uint8List>> exportAutomatonToPngBytes(FSA automaton) async {
    return const Failure<Uint8List>('PNG export is not supported on web.');
  }

  /// Starts a PNG download from previously rendered bytes.
  Future<StringResult> writePngBytesToPath(
    Uint8List bytes,
    String filePath,
  ) {
    return _downloadBytes(filePath, 'image/png', bytes);
  }

  Future<StringResult> saveAutomatonToJFLAP(
    FSA automaton,
    String filePath,
  ) async {
    try {
      final xml = serializeAutomatonToJFLAPString(automaton);
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
      return const JflapXmlCodec().decodeFsaDocument(document);
    } catch (e) {
      return Failure('Failed to load automaton from provided data: $e');
    }
  }

  Future<StringResult> saveAutomatonToJson(
    FSA automaton,
    String filePath,
  ) async {
    try {
      final jsonString = serializeAutomatonToJsonString(automaton);
      return _downloadText(filePath, 'application/json', jsonString);
    } catch (e) {
      return Failure('Failed to prepare automaton JSON download: $e');
    }
  }

  Future<Result<FSA>> loadAutomatonFromJson(String filePath) async {
    return const Failure(
      'Loading automaton JSON files from a path is not supported on web.',
    );
  }

  Future<Result<FSA>> loadAutomatonFromJsonBytes(Uint8List bytes) async {
    try {
      final jsonString = utf8.decode(bytes);
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const Failure('Invalid automaton JSON format');
      }
      return Success(FSA.fromJson(decoded));
    } catch (e) {
      return Failure('Failed to load automaton from provided JSON data: $e');
    }
  }

  Future<StringResult> saveGrammarToJFLAP(
    Grammar grammar,
    String filePath,
  ) async {
    try {
      final xml = serializeGrammarToJFLAPString(grammar);
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
      final svg = exportAutomatonToSvgString(automaton, options: options);
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
      final svg = exportGrammarToSvgString(grammar, options: options);
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
      final svg = exportTuringMachineToSvgString(
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
      final svg = exportLegacyAutomatonToSvgString(automaton);
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
    final transitions = automaton.transitions
        .whereType<FSATransition>()
        .toList()
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
      final strokeColor =
          state.isInitial ? _kInitialStrokeColor : _kStrokeColor;
      final strokeWidth =
          state.isInitial ? _kInitialStrokeWidth : _kDefaultStrokeWidth;
      final fillColor =
          state.isAccepting ? _kAcceptingFillColor : _kDefaultFillColor;
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

  Grammar _parseGrammarXML(XmlDocument document) {
    final grammarElement = document.findAllElements('grammar').firstOrNull;
    if (grammarElement == null) {
      throw const FormatException(
        'JFLAP grammar import is missing the <grammar> element.',
      );
    }

    final startElement = grammarElement.findElements('start').firstOrNull;
    if (startElement == null) {
      throw const FormatException(
        'JFLAP grammar import is missing the <start> element.',
      );
    }
    final startSymbols = _splitGrammarSymbols(startElement.innerText);
    if (startSymbols.isEmpty) {
      throw const FormatException(
        'JFLAP grammar import has an empty <start> element.',
      );
    }
    if (startSymbols.length != 1) {
      throw const FormatException(
        'JFLAP grammar import must declare exactly one start symbol.',
      );
    }
    final startSymbol = startSymbols.single;
    final productions = <Production>{};

    for (final productionElement in grammarElement.findAllElements(
      'production',
    )) {
      final leftElement = productionElement.findElements('left').firstOrNull;
      final rightElement = productionElement.findElements('right').firstOrNull;
      if (leftElement == null || rightElement == null) {
        throw const FormatException(
          'JFLAP grammar import has a <production> without <left> or <right>.',
        );
      }
      final leftSide = _splitGrammarSymbols(
        leftElement.innerText,
      );
      final rightSide = _splitGrammarSymbols(
        rightElement.innerText,
      );

      productions.add(
        Production(
          id: 'p${productions.length}',
          leftSide: leftSide,
          rightSide: rightSide,
          isLambda: rightSide.isEmpty,
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

  List<String> _splitGrammarSymbols(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }
    return trimmed.split(RegExp(r'\s+'));
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
