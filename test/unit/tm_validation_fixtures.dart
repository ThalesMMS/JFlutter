part of 'tm_validation_test.dart';

/// Helper functions to create test TMs

TM _createBinaryToUnaryTM() {
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
    // Read '0', write '1', move right
    TMTransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '0→1,R',
      readSymbol: '0',
      writeSymbol: '1',
      direction: TapeDirection.right,
    ),
    // Read '1', write '1', move right
    TMTransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q0'),
      label: '1→1,R',
      readSymbol: '1',
      writeSymbol: '1',
      direction: TapeDirection.right,
    ),
    // Read blank, stay, accept
    TMTransition(
      id: 't3',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q2'),
      label: 'B→B,S',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.stay,
    ),
  };

  return TM(
    id: 'binary_to_unary',
    name: 'Binary to Unary',
    states: states,
    transitions: transitions,
    alphabet: {'0', '1'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    tapeAlphabet: {'0', '1', 'B'},
    blankSymbol: 'B',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 600, 400),
  );
}

TM _createSimplePalindromeDTM() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(100.0, 200.0),
    isInitial: true,
    isAccepting: false,
  );
  final qRightA = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(260.0, 160.0),
    isInitial: false,
    isAccepting: false,
  );
  final qLeftA = State(
    id: 'q1L',
    label: 'q1L',
    position: Vector2(420.0, 160.0),
    isInitial: false,
    isAccepting: false,
  );
  final qRightB = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(260.0, 240.0),
    isInitial: false,
    isAccepting: false,
  );
  final qLeftB = State(
    id: 'q2L',
    label: 'q2L',
    position: Vector2(420.0, 240.0),
    isInitial: false,
    isAccepting: false,
  );
  final qBack = State(
    id: 'q3',
    label: 'q3',
    position: Vector2(580.0, 200.0),
    isInitial: false,
    isAccepting: false,
  );
  final qAccept = State(
    id: 'qa',
    label: 'qa',
    position: Vector2(740.0, 200.0),
    isInitial: false,
    isAccepting: true,
  );

  final states = {q0, qRightA, qLeftA, qRightB, qLeftB, qBack, qAccept};

  final transitions = {
    // q0: if blank, accept
    TMTransition(
      id: 't0',
      fromState: q0,
      toState: qAccept,
      label: 'B→B,S',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.stay,
    ),
    // q0: skip markers
    TMTransition(
      id: 't0x',
      fromState: q0,
      toState: q0,
      label: 'X→X,R',
      readSymbol: 'X',
      writeSymbol: 'X',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't0y',
      fromState: q0,
      toState: q0,
      label: 'Y→Y,R',
      readSymbol: 'Y',
      writeSymbol: 'Y',
      direction: TapeDirection.right,
    ),
    // q0: on a -> mark X, go find matching a to the right
    TMTransition(
      id: 't1',
      fromState: q0,
      toState: qRightA,
      label: 'a→X,R',
      readSymbol: 'a',
      writeSymbol: 'X',
      direction: TapeDirection.right,
    ),
    // q0: on b -> mark Y, go find matching b to the right
    TMTransition(
      id: 't2',
      fromState: q0,
      toState: qRightB,
      label: 'b→Y,R',
      readSymbol: 'b',
      writeSymbol: 'Y',
      direction: TapeDirection.right,
    ),

    // qRightA: move right until blank
    TMTransition(
      id: 't1r_a',
      fromState: qRightA,
      toState: qRightA,
      label: 'a→a,R',
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't1r_b',
      fromState: qRightA,
      toState: qRightA,
      label: 'b→b,R',
      readSymbol: 'b',
      writeSymbol: 'b',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't1r_x',
      fromState: qRightA,
      toState: qRightA,
      label: 'X→X,R',
      readSymbol: 'X',
      writeSymbol: 'X',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't1r_y',
      fromState: qRightA,
      toState: qRightA,
      label: 'Y→Y,R',
      readSymbol: 'Y',
      writeSymbol: 'Y',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't1r_B',
      fromState: qRightA,
      toState: qLeftA,
      label: 'B→B,L',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.left,
    ),

    // qLeftA: move left skipping markers until find 'a'; mismatch on 'b'
    TMTransition(
      id: 't1l_a',
      fromState: qLeftA,
      toState: qBack,
      label: 'a→X,L',
      readSymbol: 'a',
      writeSymbol: 'X',
      direction: TapeDirection.left,
    ),
    TMTransition(
      id: 't1l_x',
      fromState: qLeftA,
      toState: qLeftA,
      label: 'X→X,L',
      readSymbol: 'X',
      writeSymbol: 'X',
      direction: TapeDirection.left,
    ),
    TMTransition(
      id: 't1l_y',
      fromState: qLeftA,
      toState: qLeftA,
      label: 'Y→Y,L',
      readSymbol: 'Y',
      writeSymbol: 'Y',
      direction: TapeDirection.left,
    ),
    TMTransition(
      id: 't1l_B',
      fromState: qLeftA,
      toState: q0,
      label: 'B→B,R',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.right,
    ),

    // qRightB: move right until blank
    TMTransition(
      id: 't2r_a',
      fromState: qRightB,
      toState: qRightB,
      label: 'a→a,R',
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't2r_b',
      fromState: qRightB,
      toState: qRightB,
      label: 'b→b,R',
      readSymbol: 'b',
      writeSymbol: 'b',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't2r_x',
      fromState: qRightB,
      toState: qRightB,
      label: 'X→X,R',
      readSymbol: 'X',
      writeSymbol: 'X',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't2r_y',
      fromState: qRightB,
      toState: qRightB,
      label: 'Y→Y,R',
      readSymbol: 'Y',
      writeSymbol: 'Y',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't2r_B',
      fromState: qRightB,
      toState: qLeftB,
      label: 'B→B,L',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.left,
    ),

    // qLeftB: move left skipping markers until find 'b'; mismatch on 'a'
    TMTransition(
      id: 't2l_b',
      fromState: qLeftB,
      toState: qBack,
      label: 'b→Y,L',
      readSymbol: 'b',
      writeSymbol: 'Y',
      direction: TapeDirection.left,
    ),
    TMTransition(
      id: 't2l_y',
      fromState: qLeftB,
      toState: qLeftB,
      label: 'Y→Y,L',
      readSymbol: 'Y',
      writeSymbol: 'Y',
      direction: TapeDirection.left,
    ),
    TMTransition(
      id: 't2l_x',
      fromState: qLeftB,
      toState: qLeftB,
      label: 'X→X,L',
      readSymbol: 'X',
      writeSymbol: 'X',
      direction: TapeDirection.left,
    ),
    TMTransition(
      id: 't2l_B',
      fromState: qLeftB,
      toState: q0,
      label: 'B→B,R',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.right,
    ),

    // qBack: move left to start, then head right one into q0
    TMTransition(
      id: 't3l_a',
      fromState: qBack,
      toState: qBack,
      label: 'a→a,L',
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.left,
    ),
    TMTransition(
      id: 't3l_b',
      fromState: qBack,
      toState: qBack,
      label: 'b→b,L',
      readSymbol: 'b',
      writeSymbol: 'b',
      direction: TapeDirection.left,
    ),
    TMTransition(
      id: 't3l_x',
      fromState: qBack,
      toState: qBack,
      label: 'X→X,L',
      readSymbol: 'X',
      writeSymbol: 'X',
      direction: TapeDirection.left,
    ),
    TMTransition(
      id: 't3l_y',
      fromState: qBack,
      toState: qBack,
      label: 'Y→Y,L',
      readSymbol: 'Y',
      writeSymbol: 'Y',
      direction: TapeDirection.left,
    ),
    TMTransition(
      id: 't3l_B',
      fromState: qBack,
      toState: q0,
      label: 'B→B,R',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.right,
    ),
  };

  return TM(
    id: 'palindrome',
    name: 'Palindrome',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {qAccept},
    tapeAlphabet: {'a', 'b', 'B', 'X', 'Y'},
    blankSymbol: 'B',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 800, 400),
  );
}

TM _createAcceptAllTM() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: true,
    ),
  };

  final transitions = {
    // Read any symbol, write same, move right
    TMTransition(
      id: 't1',
      fromState: states.first,
      toState: states.first,
      label: 'a→a,R',
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't2',
      fromState: states.first,
      toState: states.first,
      label: 'b→b,R',
      readSymbol: 'b',
      writeSymbol: 'b',
      direction: TapeDirection.right,
    ),
    // Extend to cover letters 'c' and 'd' for tests that use 'abc'
    TMTransition(
      id: 't1c',
      fromState: states.first,
      toState: states.first,
      label: 'c→c,R',
      readSymbol: 'c',
      writeSymbol: 'c',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't1d',
      fromState: states.first,
      toState: states.first,
      label: 'd→d,R',
      readSymbol: 'd',
      writeSymbol: 'd',
      direction: TapeDirection.right,
    ),
    // Read blank, stay, accept
    TMTransition(
      id: 't3',
      fromState: states.first,
      toState: states.first,
      label: 'B→B,S',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.stay,
    ),
  };

  return TM(
    id: 'accept_all',
    name: 'Accept All',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b', 'c', 'd'},
    initialState: states.first,
    acceptingStates: states,
    tapeAlphabet: {'a', 'b', 'B'},
    blankSymbol: 'B',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 300, 300),
  );
}

TM _createRejectAllTM() {
  final states = {
    State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100.0, 200.0),
      isInitial: true,
      isAccepting: false,
    ),
  };

  final transitions = {
    // Read any symbol, write same, move right (no accepting state)
    TMTransition(
      id: 't1',
      fromState: states.first,
      toState: states.first,
      label: 'a→a,R',
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't2',
      fromState: states.first,
      toState: states.first,
      label: 'b→b,R',
      readSymbol: 'b',
      writeSymbol: 'b',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't1c',
      fromState: states.first,
      toState: states.first,
      label: 'c→c,R',
      readSymbol: 'c',
      writeSymbol: 'c',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 't1d',
      fromState: states.first,
      toState: states.first,
      label: 'd→d,R',
      readSymbol: 'd',
      writeSymbol: 'd',
      direction: TapeDirection.right,
    ),
    // Read blank, stay, reject
    TMTransition(
      id: 't3',
      fromState: states.first,
      toState: states.first,
      label: 'B→B,S',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.stay,
    ),
  };

  return TM(
    id: 'reject_all',
    name: 'Reject All',
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b', 'c', 'd'},
    initialState: states.first,
    acceptingStates: {},
    tapeAlphabet: {'a', 'b', 'B'},
    blankSymbol: 'B',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 300, 300),
  );
}

TM _createLoopDetectionTM() {
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
    // Read 'a', write 'a', move right, go to q1
    TMTransition(
      id: 't1',
      fromState: states.firstWhere((s) => s.id == 'q0'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'a→a,R',
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.right,
    ),
    // Read blank, stay, accept
    TMTransition(
      id: 't2',
      fromState: states.firstWhere((s) => s.id == 'q1'),
      toState: states.firstWhere((s) => s.id == 'q1'),
      label: 'B→B,S',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.stay,
    ),
  };

  return TM(
    id: 'loop_detection',
    name: 'Loop Detection',
    states: states,
    transitions: transitions,
    alphabet: {'a'},
    initialState: states.firstWhere((s) => s.isInitial),
    acceptingStates: states.where((s) => s.isAccepting).toSet(),
    tapeAlphabet: {'a', 'B'},
    blankSymbol: 'B',
    created: DateTime.now(),
    modified: DateTime.now(),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}
