part of 'pda_validation_test.dart';

/// Helper functions to create test PDAs

PDA _createBalancedParenthesesPDA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    // Read '(', push 'X', stay in q0
    PDATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '(,Z→XZ',
      inputSymbol: '(',
      popSymbol: 'Z',
      pushSymbol: 'XZ',
    ),
    // Read '(', push 'X', stay in q0 (when X is on top)
    PDATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '(,X→XX',
      inputSymbol: '(',
      popSymbol: 'X',
      pushSymbol: 'XX',
    ),
    // Read ')', pop 'X', stay in q0
    PDATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '),X→ε',
      inputSymbol: ')',
      popSymbol: 'X',
      pushSymbol: '',
    ),
    // Read empty, pop 'Z', go to q1 (accept)
    PDATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,Z→ε',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
    ),
  };

  return PDA(
    id: 'balanced_parentheses',
    name: 'Balanced Parentheses',
    states: states,
    transitions: transitions,
    alphabet: {'(', ')'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    stackAlphabet: {'X', 'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

PDA _createPalindromePDA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(500.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    // Read 'a', push 'A', stay in q0
    PDATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,Z→AZ',
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'AZ',
    ),
    // Read 'a', push 'A', stay in q0 (when A is on top)
    PDATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,A→AA',
      inputSymbol: 'a',
      popSymbol: 'A',
      pushSymbol: 'AA',
    ),
    // Read 'a' when B is on top: push A above B
    PDATransition(
      id: 't2b',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,B→AB',
      inputSymbol: 'a',
      popSymbol: 'B',
      pushSymbol: 'AB',
    ),
    // Switch to matching phase on reading 'a' with top A (pop A)
    PDATransition(
      id: 't2_switch_a',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a,A→ε',
      inputSymbol: 'a',
      popSymbol: 'A',
      pushSymbol: '',
    ),
    // Read 'b', push 'B', stay in q0
    PDATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'b,Z→BZ',
      inputSymbol: 'b',
      popSymbol: 'Z',
      pushSymbol: 'BZ',
    ),
    // Read 'b', push 'B', stay in q0 (when B is on top)
    PDATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'b,B→BB',
      inputSymbol: 'b',
      popSymbol: 'B',
      pushSymbol: 'BB',
    ),
    // Read 'b' when A is on top: push B above A
    PDATransition(
      id: 't4a',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'b,A→BA',
      inputSymbol: 'b',
      popSymbol: 'A',
      pushSymbol: 'BA',
    ),
    // Switch to matching phase on reading 'b' with top B (pop B)
    PDATransition(
      id: 't4_switch_b',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'b, B→ε',
      inputSymbol: 'b',
      popSymbol: 'B',
      pushSymbol: '',
    ),
    // Read empty on Z, go to q1 (even-length guess)
    PDATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,Z→Z',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: 'Z',
    ),
    // Odd-length guess: epsilon pop top (A/B) and switch to q1
    PDATransition(
      id: 't5a_eps',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,A→ε',
      inputSymbol: '',
      popSymbol: 'A',
      pushSymbol: '',
    ),
    PDATransition(
      id: 't5b_eps',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,B→ε',
      inputSymbol: '',
      popSymbol: 'B',
      pushSymbol: '',
    ),
    // Read 'a', pop 'A', stay in q1
    PDATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a,A→ε',
      inputSymbol: 'a',
      popSymbol: 'A',
      pushSymbol: '',
    ),
    // Read 'b', pop 'B', stay in q1
    PDATransition(
      id: 't7',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'b,B→ε',
      inputSymbol: 'b',
      popSymbol: 'B',
      pushSymbol: '',
    ),
    // Read empty, pop 'Z', go to q2 (accept)
    PDATransition(
      id: 't8',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'ε,Z→ε',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
    ),
  };

  return PDA(
    id: 'palindrome',
    name: 'Palindrome',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    stackAlphabet: {'A', 'B', 'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 300),
  );
}

PDA _createSimplePDA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    // Read 'a', push 'X', stay in q0
    PDATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,Z→XZ',
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'XZ',
    ),
    // Read 'a', push 'X', stay in q0 (when X is on top)
    PDATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,X→XX',
      inputSymbol: 'a',
      popSymbol: 'X',
      pushSymbol: 'XX',
    ),
    // Allow epsilon pop of X to drain stack after input
    PDATransition(
      id: 't2c',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'ε,X→ε',
      inputSymbol: '',
      popSymbol: 'X',
      pushSymbol: '',
    ),
    // Allow consuming a matching 'a' by popping X in q0 (balance path)
    PDATransition(
      id: 't2b',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,X→ε',
      inputSymbol: 'a',
      popSymbol: 'X',
      pushSymbol: '',
    ),
    // Read empty, pop 'Z', go to q1 (accept)
    PDATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,Z→ε',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
    ),
  };

  return PDA(
    id: 'simple',
    name: 'Simple PDA',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    stackAlphabet: {'X', 'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

PDA _createComplexPDA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: false,
    ),
    State(
      id: 'q2',
      label: 'q2',
      position: Vector2(500.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    // Read 'a', push 'A', stay in q0
    PDATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'a,Z→AZ',
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'AZ',
    ),
    // Read 'b', push 'B', stay in q0
    PDATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: 'b,Z→BZ',
      inputSymbol: 'b',
      popSymbol: 'Z',
      pushSymbol: 'BZ',
    ),
    // Read empty, go to q1 (non-deterministic choice)
    PDATransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,Z→Z',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: 'Z',
    ),
    // Read 'a', pop 'A', stay in q1
    PDATransition(
      id: 't4',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a,A→ε',
      inputSymbol: 'a',
      popSymbol: 'A',
      pushSymbol: '',
    ),
    // Read 'b', pop 'B', stay in q1
    PDATransition(
      id: 't5',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'b,B→ε',
      inputSymbol: 'b',
      popSymbol: 'B',
      pushSymbol: '',
    ),
    // Read empty, pop 'Z', go to q2 (accept)
    PDATransition(
      id: 't6',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'ε,Z→ε',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
    ),
  };

  return PDA(
    id: 'complex',
    name: 'Complex PDA',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    stackAlphabet: {'A', 'B', 'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 300),
  );
}

PDA _createLambdaPDA() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
    State(
      id: 'q1',
      label: 'q1',
      position: Vector2(300.0, 200.0),
      isInitial: false,
      isAccepting: true,
    ),
  };

  final transitions = {
    // Read 'a', push 'X', go to q1
    PDATransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a,Z→XZ',
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'XZ',
    ),
    // Read empty, pop 'X', stay in q1 (lambda operation)
    PDATransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'ε,X→ε',
      inputSymbol: '',
      popSymbol: 'X',
      pushSymbol: '',
    ),
  };

  return PDA(
    id: 'lambda',
    name: 'Lambda PDA',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    stackAlphabet: {'X', 'Z'},
    initialStackSymbol: 'Z',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

/// Helper functions to create test grammars

Grammar _createTestGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a', 'S', 'b'],
      isLambda: false,
      order: 1,
    ),
    const Production(
      id: 'p2',
      leftSide: ['S'],
      rightSide: [],
      isLambda: true,
      order: 2,
    ),
  };

  return Grammar(
    id: 'test_grammar',
    name: 'Test Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createComplexGrammar() {
  final productions = {
    const Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['A', 'B'],
      isLambda: false,
      order: 1,
    ),
    const Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: ['a', 'A'],
      isLambda: false,
      order: 2,
    ),
    const Production(
      id: 'p3',
      leftSide: ['A'],
      rightSide: [],
      isLambda: true,
      order: 3,
    ),
    const Production(
      id: 'p4',
      leftSide: ['B'],
      rightSide: ['b', 'B'],
      isLambda: false,
      order: 4,
    ),
    const Production(
      id: 'p5',
      leftSide: ['B'],
      rightSide: [],
      isLambda: true,
      order: 5,
    ),
  };

  return Grammar(
    id: 'complex_grammar',
    name: 'Complex Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S', 'A', 'B'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}
