part of 'dfa_minimization_validation_test.dart';

/// Helper functions to create test DFAs

FSA _createBasicDFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(200, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '1',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '1',
    ),
    FSATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '0',
    ),
    FSATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'basic_dfa',
    name: 'Basic DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q2')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 300, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createComplexDFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(200, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q3',
      label: 'q3',
      position: Vector2(300, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q4',
      label: 'q4',
      position: Vector2(400, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q5',
      label: 'q5',
      position: Vector2(500, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '1',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q4'),
      symbol: '1',
    ),
    FSATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      symbol: '0',
    ),
    FSATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q4'),
      symbol: '1',
    ),
    FSATransition(
      id: 't7',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '0',
    ),
    FSATransition(
      id: 't8',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '1',
    ),
    FSATransition(
      id: 't9',
      fromState: states.firstWhere((s) => s.id == 'q4'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '0',
    ),
    FSATransition(
      id: 't10',
      fromState: states.firstWhere((s) => s.id == 'q4'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '1',
    ),
    FSATransition(
      id: 't11',
      fromState: states.firstWhere((s) => s.id == 'q5'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '0',
    ),
    FSATransition(
      id: 't12',
      fromState: states.firstWhere((s) => s.id == 'q5'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'complex_dfa',
    name: 'Complex DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q5')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createMinimalDFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '1',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      symbol: '0',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'minimal_dfa',
    name: 'Minimal DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createNoFinalStatesDFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: false,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '1',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'no_final_states_dfa',
    name: 'No Final States DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createRedundantStatesDFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(200, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q3',
      label: 'q3',
      position: Vector2(300, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q4',
      label: 'q4',
      position: Vector2(400, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q5',
      label: 'q5',
      position: Vector2(500, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q6',
      label: 'q6',
      position: Vector2(600, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q7',
      label: 'q7',
      position: Vector2(700, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    FSATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      symbol: '0',
    ),
    FSATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      symbol: '1',
    ),
    FSATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      symbol: '0',
    ),
    FSATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q4'),
      symbol: '1',
    ),
    FSATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q3'),
      symbol: '0',
    ),
    FSATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q2'),
      toState: states.firstWhere((s) => s.id == 'q4'),
      symbol: '1',
    ),
    FSATransition(
      id: 't7',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '0',
    ),
    FSATransition(
      id: 't8',
      fromState: states.firstWhere((s) => s.id == 'q3'),
      toState: states.firstWhere((s) => s.id == 'q6'),
      symbol: '1',
    ),
    FSATransition(
      id: 't9',
      fromState: states.firstWhere((s) => s.id == 'q4'),
      toState: states.firstWhere((s) => s.id == 'q5'),
      symbol: '0',
    ),
    FSATransition(
      id: 't10',
      fromState: states.firstWhere((s) => s.id == 'q4'),
      toState: states.firstWhere((s) => s.id == 'q6'),
      symbol: '1',
    ),
    FSATransition(
      id: 't11',
      fromState: states.firstWhere((s) => s.id == 'q5'),
      toState: states.firstWhere((s) => s.id == 'q7'),
      symbol: '0',
    ),
    FSATransition(
      id: 't12',
      fromState: states.firstWhere((s) => s.id == 'q5'),
      toState: states.firstWhere((s) => s.id == 'q7'),
      symbol: '1',
    ),
    FSATransition(
      id: 't13',
      fromState: states.firstWhere((s) => s.id == 'q6'),
      toState: states.firstWhere((s) => s.id == 'q7'),
      symbol: '0',
    ),
    FSATransition(
      id: 't14',
      fromState: states.firstWhere((s) => s.id == 'q6'),
      toState: states.firstWhere((s) => s.id == 'q7'),
      symbol: '1',
    ),
    FSATransition(
      id: 't15',
      fromState: states.firstWhere((s) => s.id == 'q7'),
      toState: states.firstWhere((s) => s.id == 'q7'),
      symbol: '0',
    ),
    FSATransition(
      id: 't16',
      fromState: states.firstWhere((s) => s.id == 'q7'),
      toState: states.firstWhere((s) => s.id == 'q7'),
      symbol: '1',
    ),
  };

  return FSA(
    id: 'redundant_states_dfa',
    name: 'Redundant States DFA',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.id == 'q0'),
    acceptingStates: {states.firstWhere((s) => s.id == 'q7')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 800, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createEmptyDFA() {
  return FSA(
    id: 'empty_dfa',
    name: 'Empty DFA',
    states: {},
    transitions: {},
    alphabet: {},
    initialState: null,
    acceptingStates: {},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 0, 0),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createNoInitialDFA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(0, 0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(100, 0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  return FSA(
    id: 'no_initial_dfa',
    name: 'No Initial DFA',
    states: states,
    transitions: {},
    alphabet: {'a'},
    initialState: null,
    acceptingStates: {states.firstWhere((s) => s.id == 'q1')},
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 200, 100),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}
