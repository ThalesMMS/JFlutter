part of 'language_comparator_test.dart';

FSA _createSimpleDFA1() {
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
  };

  return FSA(
    id: 'simple1',
    name: 'Simple DFA 1',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Simple DFA that differs at 'aa'
FSA _createSimpleDFA2() {
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

  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(200, 0),
    isInitial: false,
    isAccepting: false,
  );

  final states = {q0, q1, q2};

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
      toState: q2,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q2,
      toState: q2,
      symbol: 'a',
    ),
  };

  return FSA(
    id: 'simple2',
    name: 'Simple DFA 2',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// DFA with specific alphabet
FSA _createDFAWithAlphabet(Set<String> alphabet) {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: true,
  );

  final states = {q0};

  final transitions = alphabet
      .map(
        (symbol) => FSATransition.deterministic(
          id: 't_$symbol',
          fromState: q0,
          toState: q0,
          symbol: symbol,
        ),
      )
      .toSet();

  return FSA(
    id: 'dfa_${alphabet.join('')}',
    name: 'DFA with alphabet ${alphabet.join('')}',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: q0,
    acceptingStates: {q0},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// NFA with epsilon transitions
FSA _createNFAWithEpsilon() {
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
      toState: q1,
      symbol: 'ε',
    ),
    FSATransition.deterministic(
      id: 't2',
      fromState: q1,
      toState: q2,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't3',
      fromState: q2,
      toState: q2,
      symbol: 'a',
    ),
    FSATransition.deterministic(
      id: 't4',
      fromState: q2,
      toState: q2,
      symbol: 'b',
    ),
  };

  return FSA(
    id: 'nfa_epsilon',
    name: 'NFA with Epsilon',
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

/// Single state accepting automaton
FSA _createSingleStateAccepting() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: true,
  );

  final states = {q0};

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
  };

  return FSA(
    id: 'single_accepting',
    name: 'Single State Accepting',
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

/// Single state rejecting automaton
FSA _createSingleStateRejecting() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: true,
    isAccepting: false,
  );

  final states = {q0};

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
  };

  return FSA(
    id: 'single_rejecting',
    name: 'Single State Rejecting',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Empty automaton (no states)
FSA _createEmptyAutomaton() {
  return FSA(
    id: 'empty',
    name: 'Empty Automaton',
    states: {},
    transitions: {},
    alphabet: {'a', 'b'},
    initialState: null,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Automaton without initial state
FSA _createNoInitialStateAutomaton() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: false,
    isAccepting: false,
  );

  final states = {q0};

  return FSA(
    id: 'no_initial',
    name: 'No Initial State',
    states: states,
    transitions: {},
    alphabet: {'a', 'b'},
    initialState: null,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Automaton with invalid initial state
FSA _createInvalidInitialStateAutomaton() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(0, 0),
    isInitial: false,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isInitial: true,
    isAccepting: false,
  );

  final states = {q0};

  return FSA(
    id: 'invalid_initial',
    name: 'Invalid Initial State',
    states: states,
    transitions: {},
    alphabet: {'a', 'b'},
    initialState: q1, // q1 is not in states
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Incomplete DFA (missing some transitions)
FSA _createIncompleteDFA() {
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

  // Missing transition from q0 on 'b' and from q1 on both symbols
  final transitions = {
    FSATransition.deterministic(
      id: 't1',
      fromState: q0,
      toState: q1,
      symbol: 'a',
    ),
  };

  return FSA(
    id: 'incomplete_dfa',
    name: 'Incomplete DFA',
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

/// Large DFA for performance testing
FSA _createLargeDFA(int stateCount) {
  final states = <State>{};
  final transitions = <FSATransition>{};

  // Create states in a chain
  for (var i = 0; i < stateCount; i++) {
    states.add(
      State(
        id: 'q$i',
        label: 'q$i',
        position: Vector2(i * 100.0, 0),
        isInitial: i == 0,
        isAccepting: i == stateCount - 1,
      ),
    );
  }

  final stateList = states.toList();

  // Create transitions
  for (var i = 0; i < stateCount; i++) {
    final fromState = stateList[i];
    final toState = stateList[(i + 1) % stateCount];

    transitions.add(
      FSATransition.deterministic(
        id: 't${i}_a',
        fromState: fromState,
        toState: toState,
        symbol: 'a',
      ),
    );

    transitions.add(
      FSATransition.deterministic(
        id: 't${i}_b',
        fromState: fromState,
        toState: fromState,
        symbol: 'b',
      ),
    );
  }

  return FSA(
    id: 'large_dfa_$stateCount',
    name: 'Large DFA ($stateCount states)',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: stateList[0],
    acceptingStates: {stateList[stateCount - 1]},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 500, 400),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}
