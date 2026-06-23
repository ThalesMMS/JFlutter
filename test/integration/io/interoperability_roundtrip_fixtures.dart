part of 'interoperability_roundtrip_test.dart';

/// Helper functions to create serializable test automata.

Map<String, dynamic> _createTestDFA() {
  return _automatonData(
    id: 'test_dfa',
    name: 'Test DFA',
    type: 'dfa',
    alphabet: const ['0', '1'],
    states: [
      _stateData('q0', isInitial: true),
      _stateData('q1', x: 100, isFinal: true),
    ],
    transitions: const {
      'q0|0': ['q1'],
    },
    initialId: 'q0',
    nextId: 2,
  );
}

Map<String, dynamic> _createTestNFA() {
  return _automatonData(
    id: 'test_nfa',
    name: 'Test NFA',
    type: 'nfa',
    alphabet: const ['0', '1'],
    states: [
      _stateData('q0', isInitial: true),
      _stateData('q1', x: 100, isFinal: true),
    ],
    transitions: const {
      'q0|0': ['q1'],
    },
    initialId: 'q0',
    nextId: 2,
  );
}

Map<String, dynamic> _createEpsilonNFA() {
  return _automatonData(
    id: 'test_epsilon_nfa',
    name: 'Test Epsilon NFA',
    type: 'nfa',
    alphabet: const ['a', 'b'],
    states: [
      _stateData('q0', isInitial: true),
      _stateData('q1', x: 100, isFinal: true),
    ],
    transitions: const {
      'q0|ε': ['q1'],
    },
    initialId: 'q0',
    nextId: 2,
  );
}

Map<String, dynamic> _createComplexDFA() {
  return _automatonData(
    id: 'complex_dfa',
    name: 'Complex DFA',
    type: 'dfa',
    alphabet: const ['0', '1'],
    states: [
      _stateData('q0', isInitial: true),
      _stateData('q1', x: 100),
      _stateData('q2', x: 200, isFinal: true),
    ],
    transitions: const {
      'q0|0': ['q1'],
      'q1|1': ['q2'],
    },
    initialId: 'q0',
    nextId: 3,
  );
}

Map<String, dynamic> _createEmptyAutomaton() {
  return _automatonData(
    id: 'empty_automaton',
    name: 'Empty Automaton',
    type: 'dfa',
    alphabet: const [],
    states: const [],
    transitions: const {},
    nextId: 0,
  );
}

Map<String, dynamic> _createSingleStateAutomaton() {
  return _automatonData(
    id: 'single_state_automaton',
    name: 'Single State Automaton',
    type: 'dfa',
    alphabet: const ['a'],
    states: [
      _stateData('q0', isInitial: true, isFinal: true),
    ],
    transitions: const {},
    initialId: 'q0',
    nextId: 1,
  );
}

Map<String, dynamic> _createNoTransitionsAutomaton() {
  return _automatonData(
    id: 'no_transitions_automaton',
    name: 'No Transitions Automaton',
    type: 'dfa',
    alphabet: const ['a'],
    states: [
      _stateData('q0', isInitial: true),
      _stateData('q1', x: 100, isFinal: true),
    ],
    transitions: const {},
    initialId: 'q0',
    nextId: 2,
  );
}

Map<String, dynamic> _createLargeAutomaton() {
  final states = <Map<String, dynamic>>[];
  final transitions = <String, List<String>>{};

  for (var i = 0; i < 50; i++) {
    states.add(
      _stateData(
        'q$i',
        x: (i * 20).toDouble(),
        isInitial: i == 0,
        isFinal: i == 49,
      ),
    );

    if (i < 49) {
      transitions['q$i|0'] = ['q${i + 1}'];
    }
  }

  return _automatonData(
    id: 'large_automaton',
    name: 'Large Automaton',
    type: 'dfa',
    alphabet: const ['0', '1'],
    states: states,
    transitions: transitions,
    initialId: 'q0',
    nextId: 50,
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

Map<String, dynamic> _automatonData({
  required String id,
  required String name,
  required String type,
  required List<String> alphabet,
  required List<Map<String, dynamic>> states,
  required Map<String, List<String>> transitions,
  String? initialId,
  required int nextId,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'type': type,
    'alphabet': alphabet,
    'states': states,
    'transitions': transitions,
    'initialId': initialId,
    'nextId': nextId,
  };
}

Map<String, dynamic> _stateData(
  String id, {
  double x = 0,
  double y = 0,
  bool isInitial = false,
  bool isFinal = false,
}) {
  return <String, dynamic>{
    'id': id,
    'name': id,
    'x': x,
    'y': y,
    'isInitial': isInitial,
    'isFinal': isFinal,
  };
}

Map<String, dynamic> _copyAutomatonData(Map<String, dynamic> data) {
  return _normalizeAutomatonJson(data);
}

FSA _fsaFromData(Map<String, dynamic> data) {
  final normalized = _normalizeAutomatonJson(data);
  final states = (normalized['states'] as List)
      .cast<Map<String, dynamic>>()
      .map(
        (state) => automata.State(
          id: state['id'] as String,
          label: state['name'] as String,
          position: Vector2(
            (state['x'] as num).toDouble(),
            (state['y'] as num).toDouble(),
          ),
          isInitial: state['isInitial'] as bool,
          isAccepting: state['isFinal'] as bool,
        ),
      )
      .toSet();
  final statesById = {for (final state in states) state.id: state};
  final transitions = <FSATransition>{};

  final transitionData = normalized['transitions'] as Map<String, List<String>>;
  for (final entry in transitionData.entries) {
    final separatorIndex = entry.key.indexOf('|');
    final fromStateId = separatorIndex == -1
        ? entry.key
        : entry.key.substring(0, separatorIndex);
    final symbol =
        separatorIndex == -1 ? '' : entry.key.substring(separatorIndex + 1);
    final fromState = statesById[fromStateId];
    if (fromState == null) {
      continue;
    }

    for (final targetStateId in entry.value) {
      final targetState = statesById[targetStateId];
      if (targetState == null) {
        continue;
      }
      final isEpsilon = _isEpsilonSymbol(symbol);
      transitions.add(
        FSATransition(
          id: 't${transitions.length}',
          fromState: fromState,
          toState: targetState,
          inputSymbols: isEpsilon ? const <String>{} : {symbol},
          lambdaSymbol: isEpsilon ? 'ε' : null,
        ),
      );
    }
  }

  final acceptingStates = states.where((state) => state.isAccepting).toSet();
  return FSA(
    id: normalized['id'] as String,
    name: normalized['name'] as String,
    states: states,
    transitions: transitions,
    alphabet: (normalized['alphabet'] as List).cast<String>().toSet(),
    initialState: statesById[normalized['initialId'] as String?],
    acceptingStates: acceptingStates,
    created: DateTime(2025),
    modified: DateTime(2025),
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
  );
}

bool _isEpsilonSymbol(String symbol) {
  return symbol.isEmpty || symbol == 'ε' || symbol == 'λ' || symbol == 'vazio';
}
