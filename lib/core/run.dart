//
//  run.dart
//  JFlutter
//
//  Agrupa exportações das rotinas de simulação utilizadas para executar
//  autômatos finitos, pushdown automata e máquinas de Turing, permitindo que
//  módulos consumidores acessem execuções e traços a partir de um único ponto
//  de importação.
//
//  Thales Matheus Mendonça Santos - October 2025
//
// Re-export simulation and running algorithms
export 'algorithms/automaton_simulator.dart';
export 'algorithms/pda_simulator.dart';
export 'algorithms/tm_simulator.dart';
