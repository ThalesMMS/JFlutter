part of 'language_comparator_test.dart';

/// Helper functions to create test automata

/// DFA that accepts strings ending in 'a'
FSA _createDFAEndingInA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q0,
      toState: q0,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q1,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't4',
      fromState: q1,
      toState: q0,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'dfa_ending_a',
    name: 'DFA Ending in A',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Alternative DFA that accepts strings ending in 'a' (different structure)
FSA _createDFAEndingInAAlternative() {
  final s0 = State(
    id: 's0',
    label: 's0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final s1 = State(
    id: 's1',
    label: 's1',
    position: Vector2(100, 100),
    isInitial: false,
    isAccepting: true,
  );

  final states = {s0, s1};

  final transitions = {
    FSATransition.deterministic(
      id: 'ta1',
      fromState: s0,
      toState: s1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'ta2',
      fromState: s0,
      toState: s0,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 'ta3',
      fromState: s1,
      toState: s1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'ta4',
      fromState: s1,
      toState: s0,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'dfa_ending_a_alt',
    name: 'DFA Ending in A (Alternative)',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: s0,
    acceptingStates: {s1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// DFA that accepts strings ending in 'b'
FSA _createDFAEndingInB() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q0,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q0,
      toState: q1,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q1,
      toState: q0,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't4',
      fromState: q1,
      toState: q1,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'dfa_ending_b',
    name: 'DFA Ending in B',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// NFA that accepts strings containing 'ab'
FSA _createNFAContainingAB() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: false,
  );

  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(200, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1, q2};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q0,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q0,
      toState: q0,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't4',
      fromState: q1,
      toState: q2,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 't5',
      fromState: q2,
      toState: q2,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't6',
      fromState: q2,
      toState: q2,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'nfa_containing_ab',
    name: 'NFA Containing AB',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q2},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Alternative NFA that accepts strings containing 'ab'
FSA _createNFAContainingABAlternative() {
  final s0 = State(
    id: 's0',
    label: 's0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final s1 = State(
    id: 's1',
    label: 's1',
    position: Vector2(100, 100),
    isInitial: false,
    isAccepting: false,
  );

  final s2 = State(
    id: 's2',
    label: 's2',
    position: Vector2(200, 100),
    isInitial: false,
    isAccepting: true,
  );

  final states = {s0, s1, s2};

  final transitions = {
    FSATransition.deterministic(
      id: 'ta1',
      fromState: s0,
      toState: s0,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'ta2',
      fromState: s0,
      toState: s0,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 'ta3',
      fromState: s0,
      toState: s1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'ta4',
      fromState: s1,
      toState: s2,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 'ta5',
      fromState: s2,
      toState: s2,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'ta6',
      fromState: s2,
      toState: s2,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'nfa_containing_ab_alt',
    name: 'NFA Containing AB (Alternative)',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: s0,
    acceptingStates: {s2},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// NFA that accepts strings starting with 'a'
FSA _createNFAStartingWithA() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q1,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q1,
      toState: q1,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'nfa_starting_a',
    name: 'NFA Starting with A',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// NFA that accepts strings ending in 'a' (for cross-type comparison)
FSA _createNFAEndingInA() {
  final q0 = State(
    id: 'nq0',
    label: 'nq0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'nq1',
    label: 'nq1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 'nt1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'nt2',
      fromState: q0,
      toState: q0,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 'nt3',
      fromState: q1,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 'nt4',
      fromState: q1,
      toState: q0,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'nfa_ending_a',
    name: 'NFA Ending in A',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// DFA that accepts only the empty string
FSA _createDFAAcceptingEmpty() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: true,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: false,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q0,
      toState: q1,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q1,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't4',
      fromState: q1,
      toState: q1,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'dfa_empty',
    name: 'DFA Accepting Empty',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q0},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// DFA that rejects the empty string
FSA _createDFARejectingEmpty() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, q1};

  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q0,
      toState: q1,
      symbol: 'b',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q1,
      toState: q1,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't4',
      fromState: q1,
      toState: q1,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'dfa_reject_empty',
    name: 'DFA Rejecting Empty',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Simple DFA for minimal distinguishing string test
