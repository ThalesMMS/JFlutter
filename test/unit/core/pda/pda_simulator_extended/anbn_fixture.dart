part of '../pda_simulator_extended_test.dart';

/// Simple PDA accepting {a^n b^n | n >= 1} by final state
PDA _pdaAnBn() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
  );
  final q1 = State(id: 'q1', label: 'q1', position: Vector2(100, 0));
  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(200, 0),
    isAccepting: true,
  );

  final transitions = <PDATransition>{
    // q0: read 'a', push A
    PDATransition(
      id: 't0',
      fromState: q0,
      toState: q0,
      inputSymbol: 'a',
      popSymbol: '',
      pushSymbol: 'A',
      label: 'a,ε/A',
    ),
    // q0 -> q1: read at least one 'a', then start consuming b's.
    PDATransition(
      id: 't1',
      fromState: q0,
      toState: q1,
      inputSymbol: 'a',
      popSymbol: '',
      pushSymbol: 'A',
      label: 'a,ε/A',
    ),
    // q1: read 'b', pop A
    PDATransition(
      id: 't2',
      fromState: q1,
      toState: q1,
      inputSymbol: 'b',
      popSymbol: 'A',
      pushSymbol: '',
      label: 'b,A/ε',
    ),
    // q1 -> q2: accept only after all A markers have been consumed.
    PDATransition(
      id: 't3',
      fromState: q1,
      toState: q2,
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: 'Z',
      label: 'ε,Z/Z',
    ),
  };

  return PDA(
    id: 'pda_anbn',
    name: 'a^n b^n',
    states: {q0, q1, q2},
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q2},
    stackAlphabet: {'Z', 'A'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}
