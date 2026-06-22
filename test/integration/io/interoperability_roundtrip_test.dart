//
//  interoperability_roundtrip_test.dart
//  JFlutter
//
//  Examina a interoperabilidade entre formatos JFLAP, JSON e SVG garantindo round-trips sem perdas
//  estruturais. Verifica conversões, serializações e exportações para assegurar compatibilidade
//  entre o editor e ferramentas externas.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/entities/turing_machine_entity.dart';
import 'package:jflutter/core/parsers/jflap_xml_codec.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/data/models/automaton_dto.dart';
import 'package:jflutter/presentation/widgets/export/svg_exporter.dart';

part 'interoperability_roundtrip_fixtures.dart';
part 'interoperability_roundtrip/jff_format_tests.dart';
part 'interoperability_roundtrip/json_format_tests.dart';
part 'interoperability_roundtrip/svg_export_tests.dart';
part 'interoperability_roundtrip/cross_format_tests.dart';
part 'interoperability_roundtrip/data_integrity_tests.dart';
part 'interoperability_roundtrip/performance_tests.dart';

RegExp _viewBoxPattern(num width, num height) => RegExp(
      'viewBox="0 0 ${width.toInt()}(?:\\.0+)? ${height.toInt()}(?:\\.0+)?"',
    );

String _serializeAutomatonToJflap(Map<String, dynamic> automatonData) {
  return const JflapXmlCodec().encodeSerializableAutomaton(automatonData);
}

Result<Map<String, dynamic>> _deserializeAutomatonFromJflap(String xmlString) {
  return const JflapXmlCodec().decodeSerializableAutomaton(xmlString);
}

String _serializeAutomatonToJson(Map<String, dynamic> automatonData) {
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

Result<Map<String, dynamic>> _deserializeAutomatonFromJson(String jsonString) {
  try {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final dto = AutomatonDto.fromJson(json);

    return Success({
      'id': dto.id,
      'name': dto.name,
      'type': dto.type,
      'alphabet': dto.alphabet,
      'states': dto.states.map((s) => s.toJson()).toList(),
      'transitions': dto.transitions,
      'initialId': dto.initialId,
      'nextId': dto.nextId,
    });
  } catch (e) {
    return Failure('Failed to deserialize JSON automaton: $e');
  }
}

/// 3. SVG export/import testing
/// 4. Cross-format conversion testing
/// 5. Data integrity validation
void main() {
  group('Interoperability and Round-trip Tests', () {
    _runJffFormatTests();
    _runJsonFormatTests();
    _runSvgExportTests();
    _runCrossFormatTests();
    _runDataIntegrityTests();
    _runPerformanceTests();
  });
}
