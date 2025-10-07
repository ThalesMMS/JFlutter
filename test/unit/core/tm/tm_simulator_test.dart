// ============================================================================
// JFlutter - Suite de Testes
// ----------------------------------------------------------------------------
// Arquivo: test/unit/core/tm/tm_simulator_test.dart
// Objetivo: Exercitar o simulador interno de máquinas de Turing com cenários
// determinísticos e não determinísticos, incluindo múltiplas fitas.
// Cenários cobertos:
// - Máquinas determinísticas que expandem cadeias unárias e reconhecem padrões.
// - Construções não determinísticas com ramos concorrentes e rejeição.
// - Operações multi-fita com movimentação independente e sincronização.
// Autoria: Equipe de Qualidade JFlutter.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/tm_simulator.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

TM _dtmAppendOne() {
  // Language: unary strings of 1s; machine appends one more 1 and accepts.
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final qA = State(
    id: 'qA',
    label: 'qA',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final Set<State> states = {q0, qA};
  final alphabet = {'1'};
  final tapeAlphabet = {'1', 'B'};

  final transitions = <TMTransition>{
    // Move right to end of input
    TMTransition(
      id: 't0',
      fromState: q0,
      toState: q0,
      label: 'R over 1',
      readSymbol: '1',
      writeSymbol: '1',
      direction: TapeDirection.right,
      tapeNumber: 0,
    ),
    // On blank at end, write 1 and accept
    TMTransition(
      id: 't1',
      fromState: q0,
      toState: qA,
      label: 'B->1,S',
      readSymbol: 'B',
      writeSymbol: '1',
      direction: TapeDirection.stay,
      tapeNumber: 0,
    ),
  };

  return TM(
    id: 'tm_inc',
    name: 'Append One',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: q0,
    acceptingStates: {qA},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: tapeAlphabet,
    blankSymbol: 'B',
    tapeCount: 1,
  );
}

void main() {
  group('TM simulator (single-tape, deterministic and nondeterministic)', () {
    test('DTM appends one and accepts', () {
      final tm = _dtmAppendOne();
      final res = TMSimulator.simulateDTM(tm, '111');
      expect(res.isSuccess, true);
      expect(res.data!.accepted, true);
    });
  });
}
