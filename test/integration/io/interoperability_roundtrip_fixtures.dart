part of 'interoperability_roundtrip_test.dart';

/// Helper functions to create test automatons

AutomatonEntity _createTestDFA() {
  return const AutomatonEntity(
    id: 'test_dfa',
    name: 'Test DFA',
    alphabet: {'0', '1'},
    states: [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0.0,
        y: 0.0,
        isInitial: true,
        isFinal: false,
      ),
      StateEntity(
        id: 'q1',
        name: 'q1',
        x: 100.0,
        y: 0.0,
        isInitial: false,
        isFinal: true,
      ),
    ],
    transitions: {
      'q0|0': ['q1'],
    },
    initialId: 'q0',
    nextId: 2,
    type: AutomatonType.dfa,
  );
}

AutomatonEntity _createTestNFA() {
  return const AutomatonEntity(
    id: 'test_nfa',
    name: 'Test NFA',
    alphabet: {'0', '1'},
    states: [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0.0,
        y: 0.0,
        isInitial: true,
        isFinal: false,
      ),
      StateEntity(
        id: 'q1',
        name: 'q1',
        x: 100.0,
        y: 0.0,
        isInitial: false,
        isFinal: true,
      ),
    ],
    transitions: {
      'q0|0': ['q1'],
    },
    initialId: 'q0',
    nextId: 2,
    type: AutomatonType.nfa,
  );
}

AutomatonEntity _createEpsilonNFA() {
  return const AutomatonEntity(
    id: 'test_epsilon_nfa',
    name: 'Test Epsilon NFA',
    alphabet: {'a', 'b'},
    states: [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0.0,
        y: 0.0,
        isInitial: true,
        isFinal: false,
      ),
      StateEntity(
        id: 'q1',
        name: 'q1',
        x: 100.0,
        y: 0.0,
        isInitial: false,
        isFinal: true,
      ),
    ],
    transitions: {
      'q0|ε': ['q1'],
    },
    initialId: 'q0',
    nextId: 2,
    type: AutomatonType.nfa,
  );
}

AutomatonEntity _createComplexDFA() {
  return const AutomatonEntity(
    id: 'complex_dfa',
    name: 'Complex DFA',
    alphabet: {'0', '1'},
    states: [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0.0,
        y: 0.0,
        isInitial: true,
        isFinal: false,
      ),
      StateEntity(
        id: 'q1',
        name: 'q1',
        x: 100.0,
        y: 0.0,
        isInitial: false,
        isFinal: false,
      ),
      StateEntity(
        id: 'q2',
        name: 'q2',
        x: 200.0,
        y: 0.0,
        isInitial: false,
        isFinal: true,
      ),
    ],
    transitions: {
      'q0|0': ['q1'],
      'q1|1': ['q2'],
    },
    initialId: 'q0',
    nextId: 3,
    type: AutomatonType.dfa,
  );
}

AutomatonEntity _createEmptyAutomaton() {
  return const AutomatonEntity(
    id: 'empty_automaton',
    name: 'Empty Automaton',
    alphabet: {},
    states: [],
    transitions: {},
    initialId: null,
    nextId: 0,
    type: AutomatonType.dfa,
  );
}

AutomatonEntity _createSingleStateAutomaton() {
  return const AutomatonEntity(
    id: 'single_state_automaton',
    name: 'Single State Automaton',
    alphabet: {'a'},
    states: [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0.0,
        y: 0.0,
        isInitial: true,
        isFinal: true,
      ),
    ],
    transitions: {},
    initialId: 'q0',
    nextId: 1,
    type: AutomatonType.dfa,
  );
}

AutomatonEntity _createNoTransitionsAutomaton() {
  return const AutomatonEntity(
    id: 'no_transitions_automaton',
    name: 'No Transitions Automaton',
    alphabet: {'a'},
    states: [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0.0,
        y: 0.0,
        isInitial: true,
        isFinal: false,
      ),
      StateEntity(
        id: 'q1',
        name: 'q1',
        x: 100.0,
        y: 0.0,
        isInitial: false,
        isFinal: true,
      ),
    ],
    transitions: {},
    initialId: 'q0',
    nextId: 2,
    type: AutomatonType.dfa,
  );
}

AutomatonEntity _createLargeAutomaton() {
  final states = <StateEntity>[];
  final transitions = <String, List<String>>{};

  // Create 50 states
  for (int i = 0; i < 50; i++) {
    states.add(
      StateEntity(
        id: 'q$i',
        name: 'q$i',
        x: (i * 20).toDouble(),
        y: 0.0,
        isInitial: i == 0,
        isFinal: i == 49,
      ),
    );

    if (i < 49) {
      transitions['q$i|0'] = ['q${i + 1}'];
    }
  }

  return AutomatonEntity(
    id: 'large_automaton',
    name: 'Large Automaton',
    alphabet: {'0', '1'},
    states: states,
    transitions: transitions,
    initialId: 'q0',
    nextId: 50,
    type: AutomatonType.dfa,
  );
}

TuringMachineEntity _createTestTuringMachine() {
  return const TuringMachineEntity(
    id: 'test_tm',
    name: 'Test TM',
    inputAlphabet: {'0', '1'},
    tapeAlphabet: {'0', '1', '□'},
    blankSymbol: '□',
    states: [
      TuringStateEntity(id: 'q0', name: 'q0', isInitial: true),
      TuringStateEntity(id: 'q1', name: 'q1', isAccepting: true),
    ],
    transitions: [
      TuringTransitionEntity(
        id: 't0',
        fromStateId: 'q0',
        toStateId: 'q1',
        readSymbol: '0',
        writeSymbol: '1',
        moveDirection: TuringMoveDirection.right,
      ),
      TuringTransitionEntity(
        id: 't1',
        fromStateId: 'q1',
        toStateId: 'q1',
        readSymbol: '1',
        writeSymbol: '1',
        moveDirection: TuringMoveDirection.stay,
      ),
    ],
    initialStateId: 'q0',
    acceptingStateIds: {'q1'},
    rejectingStateIds: <String>{},
    nextStateIndex: 2,
  );
}

/// Helper functions for data conversion

Map<String, dynamic> _convertEntityToData(AutomatonEntity entity) {
  return {
    'id': entity.id,
    'name': entity.name,
    'type': entity.type.name,
    'alphabet': entity.alphabet.toList(),
    'states': entity.states
        .map(
          (s) => {
            'id': s.id,
            'name': s.name,
            'x': s.x,
            'y': s.y,
            'isInitial': s.isInitial,
            'isFinal': s.isFinal,
          },
        )
        .toList(),
    'transitions': entity.transitions,
    'initialId': entity.initialId,
    'nextId': entity.nextId,
  };
}

AutomatonEntity _convertDataToEntity(Map<String, dynamic> data) {
  return AutomatonEntity(
    id: data['id'] as String,
    name: data['name'] as String,
    alphabet: (data['alphabet'] as List).cast<String>().toSet(),
    states: (data['states'] as List)
        .map(
          (s) => StateEntity(
            id: s['id'] as String,
            name: s['name'] as String,
            x: s['x'] as double,
            y: s['y'] as double,
            isInitial: s['isInitial'] as bool,
            isFinal: s['isFinal'] as bool,
          ),
        )
        .toList(),
    transitions: (data['transitions'] as Map).map(
      (key, value) => MapEntry(
        key as String,
        (value as List)
            .map((symbol) => symbol as String)
            .toList(growable: false),
      ),
    ),
    initialId: data['initialId'] as String?,
    nextId: data['nextId'] as int,
    type: AutomatonType.values.firstWhere(
      (t) => t.name == data['type'],
      orElse: () => AutomatonType.dfa,
    ),
  );
}
