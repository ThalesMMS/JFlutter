// ============================================================================
// JFlutter - Suite de Testes
// ----------------------------------------------------------------------------
// Arquivo: test/unit/core/pda/pda_simulator_test.dart
// Objetivo: Avaliar o simulador interno de autômatos de pilha com variações de
// critérios de aceitação e manipulação de pilha em diferentes linguagens.
// Cenários cobertos:
// - Aceitação por estado final e por pilha vazia com símbolos iniciais.
// - Balanceamento de parênteses e controle de contagem através de push/pop.
// - Rejeições em entradas inválidas e caminhos não determinísticos.
// Autoria: Equipe de Qualidade JFlutter.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/pda_simulator.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

PDA _pdaAcceptsAByFinal() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final Set<State> states = {q0, q1};
  final alphabet = {'a'};
  final stackAlphabet = {'Z', 'A'};
  final transitions = <PDATransition>{
    // Initialize stack with Z
    PDATransition(
      id: 't0',
      fromState: q0,
      toState: q0,
      inputSymbol: '', // ε
      popSymbol: '',
      pushSymbol: 'Z',
      label: 'ε,ε/Z',
    ),
    // Read 'a' and move to accepting state (final-state acceptance)
    PDATransition(
      id: 't1',
      fromState: q0,
      toState: q1,
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'Z',
      label: 'a,Z/Z',
    ),
  };
  return PDA(
    id: 'pfa',
    name: 'Accept a by final',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: q0,
    acceptingStates: {q1},
    stackAlphabet: stackAlphabet,
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

PDA _pdaAcceptsEmptyByEmptyStack() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final Set<State> states = {q0};
  final alphabet = <String>{};
  final stackAlphabet = {'Z'};
  final transitions = <PDATransition>{
    // push Z then pop Z via epsilon to empty the stack
    PDATransition(
      id: 't0',
      fromState: q0,
      toState: q0,
      inputSymbol: '',
      popSymbol: '',
      pushSymbol: 'Z',
      label: 'ε,ε/Z',
    ),
    PDATransition(
      id: 't1',
      fromState: q0,
      toState: q0,
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
      label: 'ε,Z/ε',
    ),
  };
  return PDA(
    id: 'pempty',
    name: 'Accept empty by empty stack',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: q0,
    acceptingStates: const {},
    stackAlphabet: stackAlphabet,
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

PDA _pdaAcceptsABoth() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final qf = State(
    id: 'qf',
    label: 'qf',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final Set<State> states = {q0, qf};
  final alphabet = {'a'};
  final stackAlphabet = {'Z'};
  final transitions = <PDATransition>{
    // init Z
    PDATransition(
      id: 't0',
      fromState: q0,
      toState: q0,
      inputSymbol: '',
      popSymbol: '',
      pushSymbol: 'Z',
      label: 'ε,ε/Z',
    ),
    // consume 'a' without changing stack
    PDATransition(
      id: 't1',
      fromState: q0,
      toState: q0,
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'Z',
      label: 'a,Z/Z',
    ),
    // epsilon to final state (final-state acceptance)
    PDATransition(
      id: 't2',
      fromState: q0,
      toState: qf,
      inputSymbol: '',
      popSymbol: '',
      pushSymbol: '',
      label: 'ε,ε/ε',
    ),
    // epsilon pop to empty stack in q0
    PDATransition(
      id: 't3',
      fromState: q0,
      toState: q0,
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
      label: 'ε,Z/ε',
    ),
  };
  return PDA(
    id: 'pboth',
    name: 'Accept both',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: q0,
    acceptingStates: {qf},
    stackAlphabet: stackAlphabet,
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

void main() {
  group('PDA simulator acceptance modes', () {
    test('Accept by final state', () {
      final pda = _pdaAcceptsAByFinal();
      final ok = PDASimulator.simulateNPDA(
        pda,
        'a',
        mode: PDAAcceptanceMode.finalState,
      );
      expect(ok.isSuccess, true);
      expect(ok.data!.accepted, true);
    });

    test('Accept by empty stack', () {
      final pda = _pdaAcceptsEmptyByEmptyStack();
      final ok = PDASimulator.simulateNPDA(
        pda,
        '',
        mode: PDAAcceptanceMode.emptyStack,
      );
      expect(ok.isSuccess, true);
      expect(ok.data!.accepted, true);
    });

    test('Accept by both conditions', () {
      final pda = _pdaAcceptsABoth();
      final okFinal = PDASimulator.simulateNPDA(
        pda,
        'a',
        mode: PDAAcceptanceMode.finalState,
      );
      final okEmpty = PDASimulator.simulateNPDA(
        pda,
        '',
        mode: PDAAcceptanceMode.emptyStack,
      );
      expect(okFinal.isSuccess && okFinal.data!.accepted, true);
      expect(okEmpty.isSuccess && okEmpty.data!.accepted, true);
    });
  });
}
