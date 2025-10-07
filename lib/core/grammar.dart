//
//  grammar.dart
//  JFlutter
//
//  Centraliza as exportações de modelos e algoritmos relacionados a gramáticas,
//  permitindo que outras partes do aplicativo importem um único ponto para
//  acessar entidades, analisadores, conversores para PDA e automatos
//  associados às funcionalidades de teoria de linguagens formais.
//
//  Thales Matheus Mendonça Santos - October 2025
//
// Re-export grammar-related models and algorithms
export 'models/grammar.dart';
export 'algorithms/grammar_parser.dart';
export 'algorithms/grammar_to_pda_converter.dart';
