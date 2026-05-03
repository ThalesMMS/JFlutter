//
//  grammar_diagnostics_report.dart
//  JFlutter
//
//  Typed container for grammar diagnostics emitted by non-crashing analysis
//  routines.
//

import 'grammar_diagnostic.dart';

class GrammarDiagnosticsReport {
  final List<GrammarDiagnostic> diagnostics;

  const GrammarDiagnosticsReport({this.diagnostics = const []});
}
