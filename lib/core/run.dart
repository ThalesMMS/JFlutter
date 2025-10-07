//
//  run.dart
//  JFlutter
//
//  Disponibiliza reexportações focadas em execução e simulação de autômatos,
//  PDAs e máquinas de Turing para que consumidores externos acionem rotinas de
//  processamento sem conhecer a organização interna. Funciona como atalho
//  semântico para cenários de execução unificada no app.
//
//  Thales Matheus Mendonça Santos - October 2025
//

// Re-export simulation and running algorithms
export 'algorithms/automaton_simulator.dart';
export 'algorithms/pda_simulator.dart';
export 'algorithms/tm_simulator.dart';
