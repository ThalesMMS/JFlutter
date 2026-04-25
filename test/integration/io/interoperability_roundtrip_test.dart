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
import 'package:jflutter/data/services/serialization_service.dart';
import 'package:jflutter/presentation/widgets/export/svg_exporter.dart';
import 'package:jflutter/core/parsers/jflap_xml_parser.dart';

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

late SerializationService serializationService;

/// 3. SVG export/import testing
/// 4. Cross-format conversion testing
/// 5. Data integrity validation
void main() {
  group('Interoperability and Round-trip Tests', () {
    setUp(() {
      serializationService = SerializationService();
    });

    _runJffFormatTests();
    _runJsonFormatTests();
    _runSvgExportTests();
    _runCrossFormatTests();
    _runDataIntegrityTests();
    _runPerformanceTests();
  });
}
