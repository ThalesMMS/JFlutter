part of '../tm_examples.dart';

TM _aNbNExample({String? id, String? name, math.Rectangle? bounds}) {
  final now = DateTime.now();

  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(100, 200),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(300, 100),
    isInitial: false,
    isAccepting: false,
  );

  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(500, 200),
    isInitial: false,
    isAccepting: false,
  );

  final q3 = State(
    id: 'q3',
    label: 'q3',
    position: Vector2(650, 200),
    isInitial: false,
    isAccepting: false,
  );

  final q4 = State(
    id: 'q4',
    label: 'q4',
    position: Vector2(800, 200),
    isInitial: false,
    isAccepting: true,
  );

  // q0: Replace 'a' with 'X', go right to find 'b'
  final t1 = TMTransition(
    id: 't1',
    fromState: q0,
    toState: q1,
    label: 'a→X,R',
    readSymbol: 'a',
    writeSymbol: 'X',
    direction: TapeDirection.right,
  );

  // q0: Skip over 'Y', then verify no unmatched b's remain
  final t2 = TMTransition(
    id: 't2',
    fromState: q0,
    toState: q3,
    label: 'Y→Y,R',
    readSymbol: 'Y',
    writeSymbol: 'Y',
    direction: TapeDirection.right,
  );

  // q1: Skip over 'a' and 'Y' while scanning right
  final t3 = TMTransition(
    id: 't3',
    fromState: q1,
    toState: q1,
    label: 'a→a,R',
    readSymbol: 'a',
    writeSymbol: 'a',
    direction: TapeDirection.right,
  );

  final t4 = TMTransition(
    id: 't4',
    fromState: q1,
    toState: q1,
    label: 'Y→Y,R',
    readSymbol: 'Y',
    writeSymbol: 'Y',
    direction: TapeDirection.right,
  );

  // q1: Found 'b', replace with 'Y', go left
  final t5 = TMTransition(
    id: 't5',
    fromState: q1,
    toState: q2,
    label: 'b→Y,L',
    readSymbol: 'b',
    writeSymbol: 'Y',
    direction: TapeDirection.left,
  );

  // q2: Scan left past 'a' and 'Y' to find 'X'
  final t6 = TMTransition(
    id: 't6',
    fromState: q2,
    toState: q2,
    label: 'a→a,L',
    readSymbol: 'a',
    writeSymbol: 'a',
    direction: TapeDirection.left,
  );

  final t7 = TMTransition(
    id: 't7',
    fromState: q2,
    toState: q2,
    label: 'Y→Y,L',
    readSymbol: 'Y',
    writeSymbol: 'Y',
    direction: TapeDirection.left,
  );

  // q2: Found 'X', move right to start next iteration
  final t8 = TMTransition(
    id: 't8',
    fromState: q2,
    toState: q0,
    label: 'X→X,R',
    readSymbol: 'X',
    writeSymbol: 'X',
    direction: TapeDirection.right,
  );

  // q3: Verify all Y's consumed (skip Y's)
  final t9 = TMTransition(
    id: 't9',
    fromState: q3,
    toState: q3,
    label: 'Y→Y,R',
    readSymbol: 'Y',
    writeSymbol: 'Y',
    direction: TapeDirection.right,
  );

  final t10 = TMTransition(
    id: 't10',
    fromState: q0,
    toState: q4,
    label: 'B→B,S',
    readSymbol: 'B',
    writeSymbol: 'B',
    direction: TapeDirection.stay,
  );

  final t11 = TMTransition(
    id: 't11',
    fromState: q3,
    toState: q4,
    label: 'B→B,S',
    readSymbol: 'B',
    writeSymbol: 'B',
    direction: TapeDirection.stay,
  );

  return TM(
    id: id ?? 'tm_anbn',
    name: name ?? 'a^n b^n',
    states: {q0, q1, q2, q3, q4},
    transitions: {t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11},
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q4},
    created: now,
    modified: now,
    bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
    tapeAlphabet: {'a', 'b', 'X', 'Y', 'B'},
    blankSymbol: 'B',
  );
}
