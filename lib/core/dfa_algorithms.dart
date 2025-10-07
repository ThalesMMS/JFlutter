//
//  dfa_algorithms.dart
//  JFlutter
//
//  Reúne as principais ferramentas voltadas a autômatos determinísticos,
//  reexportando minimização, simulação e complementação para consumo externo
//  sem expor a estrutura detalhada do diretório de algoritmos.
//  Facilita o acesso centralizado a rotinas de DFA para widgets e casos de uso.
//
//  Thales Matheus Mendonça Santos - October 2025
//
// Re-export DFA-specific algorithms
export 'algorithms/dfa_minimizer.dart';
export 'algorithms/automaton_simulator.dart';
export 'algorithms/dfa_completer.dart';
