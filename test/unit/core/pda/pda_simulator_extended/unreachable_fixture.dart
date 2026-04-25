part of '../pda_simulator_extended_test.dart';

final _pdaUnreachableTimestamp = DateTime.utc(2026, 1, 1);

/// PDA with an unreachable state
PDA _pdaWithUnreachableState() {
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
  final qUnreachable = State(id: 'qU', label: 'qU', position: Vector2(200, 0));

  final transitions = <PDATransition>{
    PDATransition(
      id: 't0',
      fromState: q0,
      toState: q1,
      inputSymbol: 'a',
      popSymbol: '',
      pushSymbol: '',
      label: 'a,ε/ε',
    ),
    // qUnreachable -> q1 (not reachable from q0)
    PDATransition(
      id: 't1',
      fromState: qUnreachable,
      toState: q1,
      inputSymbol: 'b',
      popSymbol: '',
      pushSymbol: '',
      label: 'b,ε/ε',
    ),
  };

  return PDA(
    id: 'pda_unreachable',
    name: 'PDA with unreachable state',
    states: {q0, q1, qUnreachable},
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    stackAlphabet: {'Z'},
    initialStackSymbol: 'Z',
    created: _pdaUnreachableTimestamp,
    modified: _pdaUnreachableTimestamp,
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}
