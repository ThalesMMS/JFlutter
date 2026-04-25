part of '../tm_examples.dart';

TM _binaryToUnaryExample({String? id, String? name, math.Rectangle? bounds}) {
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
    position: Vector2(300, 200),
    isInitial: false,
    isAccepting: false,
  );

  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(500, 200),
    isInitial: false,
    isAccepting: true,
  );

  // q0: mark each input symbol while scanning to the right.
  final t1 = TMTransition(
    id: 't1',
    fromState: q0,
    toState: q0,
    label: '1→X,R',
    readSymbol: '1',
    writeSymbol: 'X',
    direction: TapeDirection.right,
  );

  final t2 = TMTransition(
    id: 't2',
    fromState: q0,
    toState: q0,
    label: '0→X,R',
    readSymbol: '0',
    writeSymbol: 'X',
    direction: TapeDirection.right,
  );

  final t3 = TMTransition(
    id: 't3',
    fromState: q0,
    toState: q1,
    label: 'B→B,L',
    readSymbol: 'B',
    writeSymbol: 'B',
    direction: TapeDirection.left,
  );

  // q1: convert the markers into unary symbols while rewinding left.
  final t4 = TMTransition(
    id: 't4',
    fromState: q1,
    toState: q1,
    label: 'X→1,L',
    readSymbol: 'X',
    writeSymbol: '1',
    direction: TapeDirection.left,
  );

  final t5 = TMTransition(
    id: 't5',
    fromState: q1,
    toState: q1,
    label: '1→1,L',
    readSymbol: '1',
    writeSymbol: '1',
    direction: TapeDirection.left,
  );

  final t6 = TMTransition(
    id: 't6',
    fromState: q1,
    toState: q2,
    label: 'B→B,R',
    readSymbol: 'B',
    writeSymbol: 'B',
    direction: TapeDirection.right,
  );

  return TM(
    id: id ?? 'tm_binary_to_unary',
    name: name ?? 'MT - Binário para unário',
    states: {q0, q1, q2},
    transitions: {t1, t2, t3, t4, t5, t6},
    alphabet: {'0', '1'},
    initialState: q0,
    acceptingStates: {q2},
    created: now,
    modified: now,
    bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
    tapeAlphabet: {'0', '1', 'X', 'B'},
    blankSymbol: 'B',
  );
}
