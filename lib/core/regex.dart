//
//  regex.dart
//  JFlutter
//
//  Reúne utilidades de expressões regulares ao exportar conversores e o
//  pipeline de análise responsável por transformá-las em autômatos
//  equivalentes. Viabiliza que widgets e serviços consumam essas operações com
//  um único import sem acoplamento adicional.
//
//  Thales Matheus Mendonça Santos - October 2025
//

// Re-export regex-related algorithms
export 'algorithms/regex_to_nfa_converter.dart';
export 'algorithms/fa_to_regex_converter.dart';
export 'algorithms/regex_simplifier.dart';
export 'algorithms/regex_analyzer.dart';
export 'regex/regex_pipeline.dart';

// Re-export regex-related models
export 'models/regex_simplification_step.dart';
export 'models/regex_analysis.dart';
