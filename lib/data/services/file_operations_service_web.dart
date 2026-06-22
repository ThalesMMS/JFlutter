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
import '../../core/entities/automaton_entity.dart';
import '../../core/entities/grammar_entity.dart';
import '../../core/entities/turing_machine_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/result.dart';
import '../../presentation/widgets/export/svg_exporter.dart';
import 'file_operations_payload_mixin.dart';

/// Service for file operations tailored for web environments.
class FileOperationsService with FileOperationsPayloadMixin {
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
