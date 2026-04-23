//
//  file_operations_service_io.dart
//  JFlutter
//
//  Centraliza a leitura e escrita de autômatos e gramáticas nos formatos JFLAP, além de gerar exportações em PNG e SVG desenhando o canvas com ajustes visuais consistentes.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
import '../../core/utils/epsilon_utils.dart';
import '../../presentation/widgets/export/svg_exporter.dart';

/// Service for file operations including JFLAP format support
class FileOperationsService {
  static const _writeAccessRetryMessage =
      'JFlutter could not write to the selected location. The file may be outside the app sandbox or no longer writable. Choose a destination again from the system save dialog and try again.';
  static const _readAccessRetryMessage =
      'JFlutter could not read the selected file. The file may be outside the app sandbox or no longer readable. Pick the file again from the system dialog and try again.';
  static const _missingSaveLocationMessage =
      'The selected save location is no longer available. Choose a different destination and try again.';
  static const _missingReadLocationMessage =
      'The selected file is no longer available. Pick the file again and try again.';

  /// Creates the JFLAP XML payload without writing it to disk.
  String serializeAutomatonToJFLAPString(FSA automaton) {
    return _buildJFLAPXML(automaton);
  }

  /// Creates the JSON payload without writing it to disk.
  String serializeAutomatonToJsonString(FSA automaton) {
    return jsonEncode(automaton.toJson());
  }

  /// Creates the grammar JFLAP payload without writing it to disk.
  String serializeGrammarToJFLAPString(Grammar grammar) {
    return _buildGrammarXML(grammar);
  }

  /// Creates the SVG payload without writing it to disk.
  String exportAutomatonToSvgString(
    AutomatonEntity automaton, {
    SvgExportOptions? options,
  }) {
    return SvgExporter.exportAutomatonToSvg(automaton, options: options);
  }

  /// Creates the grammar SVG payload without writing it to disk.
  String exportGrammarToSvgString(
    GrammarEntity grammar, {
    SvgExportOptions? options,
  }) {
    return SvgExporter.exportGrammarToSvg(grammar, options: options);
  }

  /// Creates the Turing machine SVG payload without writing it to disk.
  String exportTuringMachineToSvgString(
    TuringMachineEntity tm, {
    SvgExportOptions? options,
  }) {
    return SvgExporter.exportTuringMachineToSvg(tm, options: options);
  }

  /// Creates the legacy FSA SVG payload without writing it to disk.
  String exportLegacyAutomatonToSvgString(FSA automaton) {
    return _buildSVG(automaton);
  }

  /// Renders the PNG payload without writing it to disk.
  Future<Result<Uint8List>> exportAutomatonToPngBytes(FSA automaton) async {
    ui.Picture? picture;
    ui.Image? image;
    try {
      const size = Size(_kCanvasWidth, _kCanvasHeight);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = _kBackgroundColor,
      );

      final drawingData = _prepareDrawingData(automaton);
      final painter = _AutomatonPainter(drawingData);
      painter.paint(canvas, size);

      picture = recorder.endRecording();
      image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return const Failure('Failed to encode PNG data');
      }

      return Success(byteData.buffer.asUint8List());
    } catch (e) {
      return Failure('Failed to export automaton to PNG: $e');
    } finally {
      image?.dispose();
      picture?.dispose();
    }
  }

  static String describeFileAccessFailure(
    Object error, {
    required bool isWrite,
  }) {
    if (error is! FileSystemException) {
      return error.toString();
    }

    final errorCode = error.osError?.errorCode;
    final normalized = [
      error.message,
      error.osError?.message,
      error.path,
    ].whereType<String>().join(' ').toLowerCase();

    final isPermissionDenied = errorCode == 1 ||
        errorCode == 13 ||
        normalized.contains('operation not permitted') ||
        normalized.contains('permission denied') ||
        normalized.contains('access is denied') ||
        normalized.contains('not permitted');
    if (isPermissionDenied) {
      return isWrite ? _writeAccessRetryMessage : _readAccessRetryMessage;
    }

    final isMissingPath = errorCode == 2 ||
        normalized.contains('no such file') ||
        normalized.contains('cannot find the path') ||
        normalized.contains('does not exist');
    if (isMissingPath) {
      return isWrite
          ? _missingSaveLocationMessage
          : _missingReadLocationMessage;
    }

    final osMessage = error.osError?.message.trim();
    if (osMessage != null && osMessage.isNotEmpty) {
      return osMessage;
    }

    return error.message;
  }

  /// Saves automaton to JFLAP XML format (.jff)
  Future<StringResult> saveAutomatonToJFLAP(
    FSA automaton,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      await file.writeAsString(serializeAutomatonToJFLAPString(automaton));
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to save automaton to JFLAP format: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to save automaton to JFLAP format: $e');
    }
  }

  /// Loads automaton from JFLAP XML format (.jff)
  Future<Result<FSA>> loadAutomatonFromJFLAP(String filePath) async {
    try {
      final file = File(filePath);
      final xmlString = await file.readAsString();
      final document = XmlDocument.parse(xmlString);
      return _parseJFLAPXML(document);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to load automaton from JFLAP format: ${describeFileAccessFailure(e, isWrite: false)}',
      );
    } catch (e) {
      return Failure('Failed to load automaton from JFLAP format: $e');
    }
  }

  /// Loads automaton from in-memory bytes (JFLAP XML format)
  Future<Result<FSA>> loadAutomatonFromBytes(Uint8List bytes) async {
    try {
      final xmlString = utf8.decode(bytes);
      final document = XmlDocument.parse(xmlString);
      return _parseJFLAPXML(document);
    } catch (e) {
      return Failure('Failed to load automaton from provided data: $e');
    }
  }

  /// Saves automaton to JSON format.
  Future<StringResult> saveAutomatonToJson(
    FSA automaton,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      await file.writeAsString(serializeAutomatonToJsonString(automaton));
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to save automaton to JSON format: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to save automaton to JSON format: $e');
    }
  }

  /// Loads automaton from JSON format.
  Future<Result<FSA>> loadAutomatonFromJson(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const Failure('Invalid automaton JSON format');
      }
      return Success(FSA.fromJson(decoded));
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to load automaton from JSON format: ${describeFileAccessFailure(e, isWrite: false)}',
      );
    } catch (e) {
      return Failure('Failed to load automaton from JSON format: $e');
    }
  }

  /// Loads automaton from in-memory bytes (JSON format).
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

  /// Saves grammar to JFLAP XML format (.cfg)
  Future<StringResult> saveGrammarToJFLAP(
    Grammar grammar,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      await file.writeAsString(serializeGrammarToJFLAPString(grammar));
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to save grammar to JFLAP format: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to save grammar to JFLAP format: $e');
    }
  }

  /// Loads grammar from JFLAP XML format (.cfg)
  Future<Result<Grammar>> loadGrammarFromJFLAP(String filePath) async {
    try {
      final file = File(filePath);
      final xmlString = await file.readAsString();
      final document = XmlDocument.parse(xmlString);
      final grammar = _parseGrammarXML(document);
      return Success(grammar);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to load grammar from JFLAP format: ${describeFileAccessFailure(e, isWrite: false)}',
      );
    } catch (e) {
      return Failure('Failed to load grammar from JFLAP format: $e');
    }
  }

  /// Loads grammar from in-memory bytes (JFLAP XML format)
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

  /// Exports automaton to PNG image
  Future<StringResult> exportAutomatonToPNG(
    FSA automaton,
    String filePath,
  ) async {
    try {
      final pngBytesResult = await exportAutomatonToPngBytes(automaton);
      if (pngBytesResult.isFailure) {
        return Failure(pngBytesResult.error!);
      }
      return writePngBytesToPath(pngBytesResult.data!, filePath);
    } catch (e) {
      return Failure('Failed to export automaton to PNG: $e');
    }
  }

  /// Writes previously rendered PNG bytes to disk.
  Future<StringResult> writePngBytesToPath(
    Uint8List bytes,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to export automaton to PNG: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to export automaton to PNG: $e');
    }
  }

  /// Exports automaton to SVG format (enhanced version)
  Future<StringResult> exportAutomatonToSVG(
    AutomatonEntity automaton,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportAutomatonToSvgString(automaton, options: options),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to export automaton to SVG: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to export automaton to SVG: $e');
    }
  }

  /// Exports grammar to SVG format (as state diagram)
  Future<StringResult> exportGrammarToSVG(
    GrammarEntity grammar,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportGrammarToSvgString(grammar, options: options),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to export grammar to SVG: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to export grammar to SVG: $e');
    }
  }

  /// Exports Turing machine to SVG format
  Future<StringResult> exportTuringMachineToSVG(
    TuringMachineEntity tm,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportTuringMachineToSvgString(tm, options: options),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to export Turing machine to SVG: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to export Turing machine to SVG: $e');
    }
  }

  /// Exports automaton to SVG format (legacy FSA support)
  Future<StringResult> exportLegacyAutomatonToSVG(
    FSA automaton,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      await file.writeAsString(exportLegacyAutomatonToSvgString(automaton));
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to export automaton to SVG: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to export automaton to SVG: $e');
    }
  }

  /// Gets the default documents directory
  Future<StringResult> getDocumentsDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return Success(directory.path);
    } catch (e) {
      return Failure('Failed to get documents directory: $e');
    }
  }

  /// Creates a new file with unique name
  Future<StringResult> createUniqueFile(
    String baseName,
    String extension,
  ) async {
    try {
      final dirResult = await getDocumentsDirectory();
      if (!dirResult.isSuccess) return Failure(dirResult.error!);

      final directory = Directory(dirResult.data!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${baseName}_$timestamp.$extension';
      final filePath = '${directory.path}/$fileName';

      return Success(filePath);
    } catch (e) {
      return Failure('Failed to create unique file: $e');
    }
  }

  /// Lists all files with specific extension in documents directory
  Future<ListResult<String>> listFiles(String extension) async {
    try {
      final dirResult = await getDocumentsDirectory();
      if (!dirResult.isSuccess) return Failure(dirResult.error!);

      final directory = Directory(dirResult.data!);
      final files = directory
          .listSync()
          .where((file) => file.path.endsWith('.$extension'))
          .map((file) => file.path)
          .toList();

      return Success(files);
    } catch (e) {
      return Failure('Failed to list files: $e');
    }
  }

  /// Deletes a file
  Future<BoolResult> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return const Success(true);
      }
      return const Failure('File does not exist');
    } catch (e) {
      return Failure('Failed to delete file: $e');
    }
  }

  /// Builds JFLAP XML for automaton
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
            // Add states
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

            // Add transitions
            for (final transition in automaton.transitions) {
              if (transition is FSATransition) {
                builder.element(
                  'transition',
                  nest: () {
                    builder.element('from', nest: transition.fromState.id);
                    builder.element('to', nest: transition.toState.id);
                    if (isEpsilonSymbol(transition.symbol)) {
                      builder.element('read', isSelfClosing: true);
                    } else {
                      builder.element('read', nest: transition.symbol);
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

  /// Parses JFLAP XML to create automaton
  Result<FSA> _parseJFLAPXML(XmlDocument document) {
    final automatonElement = document.findAllElements('automaton').firstOrNull;
    if (automatonElement == null) {
      return const Failure('JFLAP import is missing the <automaton> element.');
    }
    final states = <automaton_state.State>[];
    final transitions = <FSATransition>[];
    final alphabet = <String>{};

    // Parse states
    for (final stateElement in automatonElement.findAllElements('state')) {
      final id = stateElement.getAttribute('id');
      if (id == null || id.isEmpty) {
        continue;
      }
      final name = stateElement.getAttribute('name') ?? id;
      final xText = stateElement.getAttribute('x') ??
          stateElement.findElements('x').firstOrNull?.innerText ??
          '0.0';
      final yText = stateElement.getAttribute('y') ??
          stateElement.findElements('y').firstOrNull?.innerText ??
          '0.0';
      final x = double.tryParse(xText) ?? 0.0;
      final y = double.tryParse(yText) ?? 0.0;
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

    if (states.isEmpty) {
      return const Failure(
        'JFLAP import does not contain any states. Empty automata cannot be loaded into the editor.',
      );
    }

    // Parse transitions
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

      final fromState = states.firstWhereOrNull((s) => s.id == fromId);
      final toState = states.firstWhereOrNull((s) => s.id == toId);
      if (fromState == null || toState == null) {
        return Failure(
          'JFLAP import references an unknown state in transition $fromId -> $toId.',
        );
      }

      if (!isEpsilonSymbol(symbol) && symbol.isNotEmpty) {
        alphabet.add(symbol);
      }

      transitions.add(
        FSATransition(
          id: 't${transitions.length}',
          fromState: fromState,
          toState: toState,
          label: symbol,
          inputSymbols: isEpsilonSymbol(symbol) ? const {} : {symbol},
          lambdaSymbol: isEpsilonSymbol(symbol) ? symbol : null,
        ),
      );
    }

    return Success(
      FSA(
        id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
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
        created: DateTime.now(),
        modified: DateTime.now(),
      ),
    );
  }

  /// Builds grammar XML
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

  /// Parses grammar XML
  Grammar _parseGrammarXML(XmlDocument document) {
    final grammarElement = document.findAllElements('grammar').first;
    final startSymbol = grammarElement.findElements('start').first.innerText;
    final productions = <Production>{};

    for (final productionElement in grammarElement.findAllElements(
      'production',
    )) {
      final leftSide = _splitGrammarSymbols(
        productionElement.findElements('left').first.innerText,
      );
      final rightSide = _splitGrammarSymbols(
        productionElement.findElements('right').first.innerText,
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

  /// Builds SVG representation of automaton
  String _buildSVG(FSA automaton) {
    final drawingData = _prepareDrawingData(automaton);
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$_kCanvasWidth" height="$_kCanvasHeight">',
    );

    // Draw transitions first (so they appear behind states)
    for (final transition in drawingData.transitions) {
      final from = transition.from;
      final to = transition.to;
      buffer.writeln(
        '  <line x1="${from.dx}" y1="${from.dy}" x2="${to.dx}" y2="${to.dy}" stroke="${_colorToHex(_kStrokeColor)}" stroke-width="$_kDefaultStrokeWidth"/>',
      );

      // Draw transition label
      final midX = (from.dx + to.dx) / 2;
      final midY = (from.dy + to.dy) / 2;
      buffer.writeln(
        '  <text x="$midX" y="$midY" text-anchor="middle" font-family="Arial" font-size="12" fill="${_colorToHex(_kTextColor)}">${transition.label}</text>',
      );
    }

    // Draw states
    for (final state in drawingData.states) {
      final x = state.center.dx;
      final y = state.center.dy;
      buffer.writeln(
        '  <circle cx="$x" cy="$y" r="$_kStateRadius" fill="${_colorToHex(state.fillColor)}" stroke="${_colorToHex(state.strokeColor)}" stroke-width="${state.strokeWidth}"/>',
      );
      buffer.writeln(
        '  <text x="$x" y="${y + 5}" text-anchor="middle" font-family="Arial" font-size="14" fill="${_colorToHex(_kTextColor)}">${state.label}</text>',
      );
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  _AutomatonDrawingData _prepareDrawingData(FSA automaton) {
    final states = automaton.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final transitions = automaton.transitions
        .whereType<FSATransition>()
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final drawableStates = states
        .map(
          (state) => _DrawableState(
            center: Offset(state.position.x, state.position.y),
            label: state.label,
            fillColor:
                state.isAccepting ? _kAcceptingFillColor : _kDefaultFillColor,
            strokeColor: state.isInitial ? _kInitialStrokeColor : _kStrokeColor,
            strokeWidth:
                state.isInitial ? _kInitialStrokeWidth : _kDefaultStrokeWidth,
          ),
        )
        .toList();

    final drawableTransitions = transitions
        .map(
          (transition) => _DrawableTransition(
            from: Offset(
              transition.fromState.position.x,
              transition.fromState.position.y,
            ),
            to: Offset(
              transition.toState.position.x,
              transition.toState.position.y,
            ),
            label: transition.symbol,
          ),
        )
        .toList();

    return _AutomatonDrawingData(
      states: drawableStates,
      transitions: drawableTransitions,
    );
  }
}

const double _kCanvasWidth = 800;
const double _kCanvasHeight = 600;
const double _kStateRadius = 30;
const double _kDefaultStrokeWidth = 2;
const double _kInitialStrokeWidth = 3;

const Color _kBackgroundColor = Color(0xFFFFFFFF);
const Color _kDefaultFillColor = Color(0xFFFFFFFF);
const Color _kAcceptingFillColor = Color(0xFFADD8E6);
const Color _kStrokeColor = Color(0xFF000000);
const Color _kInitialStrokeColor = Color(0xFFFF0000);
const Color _kTextColor = Color(0xFF000000);

String _colorToHex(Color color) {
  final value = ((color.r * 255).round() << 16) |
      ((color.g * 255).round() << 8) |
      (color.b * 255).round();
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}

class _AutomatonDrawingData {
  const _AutomatonDrawingData({
    required this.states,
    required this.transitions,
  });

  final List<_DrawableState> states;
  final List<_DrawableTransition> transitions;
}

class _DrawableState {
  const _DrawableState({
    required this.center,
    required this.label,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  final Offset center;
  final String label;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
}

class _DrawableTransition {
  const _DrawableTransition({
    required this.from,
    required this.to,
    required this.label,
  });

  final Offset from;
  final Offset to;
  final String label;
}

class _AutomatonPainter extends CustomPainter {
  _AutomatonPainter(this.data);

  final _AutomatonDrawingData data;

  @override
  void paint(Canvas canvas, Size size) {
    final transitionPaint = Paint()
      ..color = _kStrokeColor
      ..strokeWidth = _kDefaultStrokeWidth
      ..style = PaintingStyle.stroke;

    for (final transition in data.transitions) {
      canvas.drawLine(transition.from, transition.to, transitionPaint);

      if (transition.label.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: transition.label,
            style: const TextStyle(
              color: _kTextColor,
              fontSize: 12,
              fontFamily: 'Arial',
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();

        final midPoint = Offset(
          (transition.from.dx + transition.to.dx) / 2,
          (transition.from.dy + transition.to.dy) / 2,
        );

        final textOffset = Offset(
          midPoint.dx - (textPainter.width / 2),
          midPoint.dy - (textPainter.height / 2),
        );

        textPainter.paint(canvas, textOffset);
      }
    }

    for (final state in data.states) {
      final fillPaint = Paint()
        ..color = state.fillColor
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = state.strokeColor
        ..strokeWidth = state.strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(state.center, _kStateRadius, fillPaint);
      canvas.drawCircle(state.center, _kStateRadius, strokePaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: state.label,
          style: const TextStyle(
            color: _kTextColor,
            fontSize: 14,
            fontFamily: 'Arial',
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        state.center.dx - (textPainter.width / 2),
        state.center.dy - (textPainter.height / 2),
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _AutomatonPainter oldDelegate) => false;
}
