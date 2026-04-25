part of '../tm_examples.dart';

TM _binaryIncrementExample({String? id, String? name, math.Rectangle? bounds}) {
  final now = DateTime.now();

  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(150, 200),
    isInitial: true,
    isAccepting: false,
  );

  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(350, 200),
    isInitial: false,
    isAccepting: false,
  );

  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(550, 200),
    isInitial: false,
    isAccepting: true,
  );

  // q0: Move right past all digits
  final t1 = TMTransition(
    id: 't1',
    fromState: q0,
    toState: q0,
    label: '0→0,R',
    readSymbol: '0',
    writeSymbol: '0',
    direction: TapeDirection.right,
  );

  final t2 = TMTransition(
    id: 't2',
    fromState: q0,
    toState: q0,
    label: '1→1,R',
    readSymbol: '1',
    writeSymbol: '1',
    direction: TapeDirection.right,
  );

  // q0: Hit blank, go back left to start carry
  final t3 = TMTransition(
    id: 't3',
    fromState: q0,
    toState: q1,
    label: 'B→B,L',
    readSymbol: 'B',
    writeSymbol: 'B',
    direction: TapeDirection.left,
  );

  // q1: Carry propagation
  final t4 = TMTransition(
    id: 't4',
    fromState: q1,
    toState: q2,
    label: '0→1,S',
    readSymbol: '0',
    writeSymbol: '1',
    direction: TapeDirection.stay,
  );

  final t5 = TMTransition(
    id: 't5',
    fromState: q1,
    toState: q1,
    label: '1→0,L',
    readSymbol: '1',
    writeSymbol: '0',
    direction: TapeDirection.left,
  );

  // q1: Overflow (all 1s become 0s, write 1 at front)
  final t6 = TMTransition(
    id: 't6',
    fromState: q1,
    toState: q2,
    label: 'B→1,S',
    readSymbol: 'B',
    writeSymbol: '1',
    direction: TapeDirection.stay,
  );

  return TM(
    id: id ?? 'tm_binary_increment',
    name: name ?? 'MT - Incremento binário',
    states: {q0, q1, q2},
    transitions: {t1, t2, t3, t4, t5, t6},
    alphabet: {'0', '1'},
    initialState: q0,
    acceptingStates: {q2},
    created: now,
    modified: now,
    bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
    tapeAlphabet: {'0', '1', 'B'},
    blankSymbol: 'B',
  );
}
