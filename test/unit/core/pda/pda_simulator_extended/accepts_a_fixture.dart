part of '../pda_simulator_extended_test.dart';

final _pdaAcceptsATimestamp = DateTime.utc(2026, 1, 1);

/// PDA accepting only 'a' by final state (simple, single-symbol)
PDA _pdaAcceptsA() {
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

  final transitions = <PDATransition>{
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
    id: 'pda_a',
    name: 'Accept a',
    states: {q0, q1},
    transitions: transitions,
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q1},
    stackAlphabet: {'Z'},
    initialStackSymbol: 'Z',
    created: _pdaAcceptsATimestamp,
    modified: _pdaAcceptsATimestamp,
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}
