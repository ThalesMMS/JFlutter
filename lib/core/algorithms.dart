//
//  algorithms.dart
//  JFlutter
//
//  Agrega exportações de algoritmos centrais do projeto, incluindo simuladores
//  de autômatos e máquinas de Turing, conversores entre representações e
//  ferramentas para gramáticas e lema do bombeamento. Facilita o consumo
//  modular dessas rotinas pelas camadas de apresentação e casos de uso.
//
//  Thales Matheus Mendonça Santos - October 2025
//
// Re-export all algorithm operations
export 'algorithms/algorithm_operations.dart';
export 'algorithms/automaton_simulator.dart';
export 'algorithms/dfa_minimizer.dart';
export 'algorithms/dfa_operations.dart';
export 'algorithms/fa_to_regex_converter.dart';
export 'algorithms/nfa_to_dfa_converter.dart';
export 'algorithms/regex_to_nfa_converter.dart';
export 'algorithms/grammar_to_pda_converter.dart';
export 'algorithms/grammar_to_fsa_converter.dart';
export 'algorithms/grammar_parser.dart';
export 'algorithms/cfg/cfg_toolkit.dart';
export 'algorithms/cfg/cyk_parser.dart';
export 'algorithms/pda_simulator.dart';
export 'algorithms/pumping_lemma_game.dart';
export 'algorithms/pumping_lemma_prover.dart';
export 'algorithms/tm_simulator.dart';
