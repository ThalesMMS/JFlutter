//
//  pda_simulator_extended_test.dart
//  JFlutter
//
//  Testes que cobrem as funcionalidades adicionais do simulador de autômatos de
//  pilha introduzidas pela refatoração em arquivos part: analisePDA, geração de
//  cadeias aceitas e rejeitadas, simplificação, e os modelos de resultado
//  PDASimulationResult, PDAAnalysis e PDASimplificationSummary.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/pda_simulator.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;
part 'pda_simulator_extended/anbn_fixture.dart';
part 'pda_simulator_extended/accepts_a_fixture.dart';
part 'pda_simulator_extended/unreachable_fixture.dart';
part 'pda_simulator_extended/model_tests.dart';
part 'pda_simulator_extended/analysis_tests.dart';
part 'pda_simulator_extended/simplify_tests.dart';
part 'pda_simulator_extended/simulation_tests.dart';

void main() {
  _runPdaModelTests();
  _runPdaAnalysisTests();
  _runPdaSimplifyTests();
  _runPdaSimulationTests();
}
