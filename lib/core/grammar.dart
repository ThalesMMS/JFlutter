//
//  grammar.dart
//  JFlutter
//
//  Centraliza as exportações relacionadas a gramáticas formais, reunindo
//  modelos, conversores e analisadores necessários para manipular GLCs dentro
//  do núcleo da aplicação. Facilita o consumo desses componentes pelas camadas
//  superiores sem depender de caminhos internos detalhados.
//
//  Thales Matheus Mendonça Santos - October 2025
//

// Re-export grammar-related models and algorithms
export 'models/grammar.dart';
export 'algorithms/grammar_parser.dart';
export 'algorithms/grammar_to_pda_converter.dart';
