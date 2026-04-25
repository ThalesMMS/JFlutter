part of '../tm_examples.dart';

TM _palindromeExample({String? id, String? name, math.Rectangle? bounds}) {
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
    position: Vector2(300, 300),
    isInitial: false,
    isAccepting: false,
  );

  final q3 = State(
    id: 'q3',
    label: 'q3',
    position: Vector2(500, 100),
    isInitial: false,
    isAccepting: false,
  );

  final q4 = State(
    id: 'q4',
    label: 'q4',
    position: Vector2(500, 300),
    isInitial: false,
    isAccepting: false,
  );

  final qAccept = State(
    id: 'qAccept',
    label: 'qAccept',
    position: Vector2(700, 200),
    isInitial: false,
    isAccepting: true,
  );

  final qBackLeft = State(
    id: 'qBackLeft',
    label: 'qBackLeft',
    position: Vector2(500, 200),
    isInitial: false,
    isAccepting: false,
  );

  // q0: Read first character
  // If '0': mark as X, go right to find matching last '0'
  final t1 = TMTransition(
    id: 't1',
    fromState: q0,
    toState: q1,
    label: '0→X,R',
    readSymbol: '0',
    writeSymbol: 'X',
    direction: TapeDirection.right,
  );

  // If '1': mark as X, go right to find matching last '1'
  final t2 = TMTransition(
    id: 't2',
    fromState: q0,
    toState: q2,
    label: '1→X,R',
    readSymbol: '1',
    writeSymbol: 'X',
    direction: TapeDirection.right,
  );

  // If blank: accept (empty or fully matched palindrome)
  final t3 = TMTransition(
    id: 't3',
    fromState: q0,
    toState: qAccept,
    label: 'B→B,S',
    readSymbol: 'B',
    writeSymbol: 'B',
    direction: TapeDirection.stay,
  );

  final t3b = TMTransition(
    id: 't3b',
    fromState: q0,
    toState: q0,
    label: 'X→X,R',
    readSymbol: 'X',
    writeSymbol: 'X',
    direction: TapeDirection.right,
  );

  // q1: Looking for last '0' — skip 0's and 1's
  final t4 = TMTransition(
    id: 't4',
    fromState: q1,
    toState: q1,
    label: '0→0,R',
    readSymbol: '0',
    writeSymbol: '0',
    direction: TapeDirection.right,
  );

  final t5 = TMTransition(
    id: 't5',
    fromState: q1,
    toState: q1,
    label: '1→1,R',
    readSymbol: '1',
    writeSymbol: '1',
    direction: TapeDirection.right,
  );

  // q1: Hit blank or X, go left to check last char
  final t6 = TMTransition(
    id: 't6',
    fromState: q1,
    toState: q3,
    label: 'B→B,L',
    readSymbol: 'B',
    writeSymbol: 'B',
    direction: TapeDirection.left,
  );

  final t6b = TMTransition(
    id: 't6b',
    fromState: q1,
    toState: q3,
    label: 'X→X,L',
    readSymbol: 'X',
    writeSymbol: 'X',
    direction: TapeDirection.left,
  );

  // q3: Must find '0' at the end (matching the first '0')
  final t7 = TMTransition(
    id: 't7',
    fromState: q3,
    toState: qBackLeft,
    label: '0→X,L',
    readSymbol: '0',
    writeSymbol: 'X',
    direction: TapeDirection.left,
  );

  final t7b = TMTransition(
    id: 't7b',
    fromState: q3,
    toState: qBackLeft,
    label: 'X→X,L',
    readSymbol: 'X',
    writeSymbol: 'X',
    direction: TapeDirection.left,
  );

  // q3: Finding X means the right-side scan reached marked symbols. Move
  // through qBackLeft to return q0 to the left edge; q0 accepts only on blank.

  // q2: Looking for last '1' — skip 0's and 1's
  final t8 = TMTransition(
    id: 't8',
    fromState: q2,
    toState: q2,
    label: '0→0,R',
    readSymbol: '0',
    writeSymbol: '0',
    direction: TapeDirection.right,
  );

  final t9 = TMTransition(
    id: 't9',
    fromState: q2,
    toState: q2,
    label: '1→1,R',
    readSymbol: '1',
    writeSymbol: '1',
    direction: TapeDirection.right,
  );

  // q2: Hit blank or X, go left to check last char
  final t10 = TMTransition(
    id: 't10',
    fromState: q2,
    toState: q4,
    label: 'B→B,L',
    readSymbol: 'B',
    writeSymbol: 'B',
    direction: TapeDirection.left,
  );

  final t10b = TMTransition(
    id: 't10b',
    fromState: q2,
    toState: q4,
    label: 'X→X,L',
    readSymbol: 'X',
    writeSymbol: 'X',
    direction: TapeDirection.left,
  );

  // q4: Must find '1' at the end (matching the first '1')
  final t11 = TMTransition(
    id: 't11',
    fromState: q4,
    toState: qBackLeft,
    label: '1→X,L',
    readSymbol: '1',
    writeSymbol: 'X',
    direction: TapeDirection.left,
  );

  final t11b = TMTransition(
    id: 't11b',
    fromState: q4,
    toState: qBackLeft,
    label: 'X→X,L',
    readSymbol: 'X',
    writeSymbol: 'X',
    direction: TapeDirection.left,
  );

  final t12 = TMTransition(
    id: 't12',
    fromState: qBackLeft,
    toState: qBackLeft,
    label: '0→0,L',
    readSymbol: '0',
    writeSymbol: '0',
    direction: TapeDirection.left,
  );

  final t13 = TMTransition(
    id: 't13',
    fromState: qBackLeft,
    toState: qBackLeft,
    label: '1→1,L',
    readSymbol: '1',
    writeSymbol: '1',
    direction: TapeDirection.left,
  );

  final t14 = TMTransition(
    id: 't14',
    fromState: qBackLeft,
    toState: qBackLeft,
    label: 'X→X,L',
    readSymbol: 'X',
    writeSymbol: 'X',
    direction: TapeDirection.left,
  );

  final t15 = TMTransition(
    id: 't15',
    fromState: qBackLeft,
    toState: q0,
    label: 'B→B,R',
    readSymbol: 'B',
    writeSymbol: 'B',
    direction: TapeDirection.right,
  );

  return TM(
    id: id ?? 'tm_palindrome',
    name: name ?? 'MT - Verificador de palíndromo',
    states: {q0, q1, q2, q3, q4, qAccept, qBackLeft},
    transitions: {
      t1,
      t2,
      t3,
      t4,
      t5,
      t6,
      t6b,
      t7,
      t7b,
      t8,
      t9,
      t10,
      t10b,
      t11,
      t11b,
      t12,
      t13,
      t14,
      t15,
      t3b,
    },
    alphabet: {'0', '1'},
    initialState: q0,
    acceptingStates: {qAccept},
    created: now,
    modified: now,
    bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
    tapeAlphabet: {'0', '1', 'X', 'B'},
    blankSymbol: 'B',
  );
}
