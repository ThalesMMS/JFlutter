//
//  grammar.dart
//  JFlutter
//
//  Centralizes exports of grammar-related models and algorithms,
//  allowing other parts of the application to import a single point to
//  access entities, parsers, converters to PDA and automata
//  associated with formal language theory functionalities.
//
//  Thales Matheus Mendonça Santos - October 2025
//
// Re-export grammar-related models and algorithms
export 'models/grammar.dart';
export 'algorithms/grammar_parser.dart';
export 'algorithms/grammar_to_pda_converter.dart';
