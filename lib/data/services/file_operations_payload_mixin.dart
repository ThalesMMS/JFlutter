import 'dart:convert';
import 'dart:typed_data';

import '../../core/entities/automaton_entity.dart';
import '../../core/entities/grammar_entity.dart';
import '../../core/entities/turing_machine_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/parsers/grammar_xml_codec.dart';
import '../../core/parsers/jflap_xml_codec.dart';
import '../../core/result.dart';
import '../../presentation/widgets/export/svg_exporter.dart';

/// Shared platform-independent payload helpers for file operations.
mixin FileOperationsPayloadMixin {
  /// Creates the JFLAP XML payload without writing it to disk.
  String serializeAutomatonToJFLAPString(FSA automaton) {
    return const JflapXmlCodec().encodeFsa(automaton);
  }

  /// Creates the JSON payload without writing it to disk.
  String serializeAutomatonToJsonString(FSA automaton) {
    return jsonEncode(automaton.toJson());
  }

  /// Creates the grammar JFLAP payload without writing it to disk.
  String serializeGrammarToJFLAPString(Grammar grammar) {
    return const GrammarXmlCodec().encodeGrammar(grammar);
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

  /// Loads automaton from in-memory bytes (JFLAP XML format).
  Future<Result<FSA>> loadAutomatonFromBytes(Uint8List bytes) async {
    try {
      final xmlString = utf8.decode(bytes);
      return const JflapXmlCodec().decodeFsaXml(xmlString);
    } catch (e) {
      return Failure('Failed to load automaton from provided data: $e');
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

  /// Loads grammar from in-memory bytes (JFLAP XML format).
  Future<Result<Grammar>> loadGrammarFromBytes(Uint8List bytes) async {
    try {
      final xmlString = utf8.decode(bytes);
      final result = const GrammarXmlCodec().decodeGrammarXml(xmlString);
      if (result.isFailure) {
        return Failure(
            'Failed to load grammar from provided data: ${result.error}');
      }
      return result;
    } catch (e) {
      return Failure('Failed to load grammar from provided data: $e');
    }
  }
}
