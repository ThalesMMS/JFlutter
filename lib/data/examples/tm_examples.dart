//
//  tm_examples.dart
//  JFlutter
//
//  Fornece exemplos prontos de Máquinas de Turing para fins educacionais,
//  alinhados ao conjunto embarcado do Examples v1 para a release Apple,
//  cobrindo conversão binário→unário, cópia de strings, incremento binário e
//  verificação de palíndromos.
//
//  Thales Matheus Mendonça Santos - February 2026
//

import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../../core/models/state.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';

/// Provides pre-configured example TMs for educational purposes
class TMExamples {
  /// Creates a TM that rewrites a binary string into unary marks on the tape.
  static TM binaryToUnary({
    String? id,
    String? name,
    math.Rectangle? bounds,
  }) {
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

  /// Creates a TM that increments a binary number by 1
  ///
  /// Input: binary number on tape (e.g., "101")
  /// Output: binary number + 1 (e.g., "110")
  ///
  /// States:
  /// - q0: Move right to end of input
  /// - q1: Carry propagation (moving left)
  /// - q2: Halt (accepting state)
  static TM binaryIncrement({
    String? id,
    String? name,
    math.Rectangle? bounds,
  }) {
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

  /// Creates a TM that copies a binary string to a second tape region.
  static TM copyString({
    String? id,
    String? name,
    math.Rectangle? bounds,
  }) {
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
      position: Vector2(250, 100),
      isInitial: false,
      isAccepting: false,
    );
    final q2 = State(
      id: 'q2',
      label: 'q2',
      position: Vector2(250, 300),
      isInitial: false,
      isAccepting: false,
    );
    final q3 = State(
      id: 'q3',
      label: 'q3',
      position: Vector2(400, 100),
      isInitial: false,
      isAccepting: false,
    );
    final q4 = State(
      id: 'q4',
      label: 'q4',
      position: Vector2(400, 300),
      isInitial: false,
      isAccepting: false,
    );
    final q5 = State(
      id: 'q5',
      label: 'q5',
      position: Vector2(550, 200),
      isInitial: false,
      isAccepting: false,
    );
    final q6 = State(
      id: 'q6',
      label: 'q6',
      position: Vector2(700, 200),
      isInitial: false,
      isAccepting: false,
    );
    final qAccept = State(
      id: 'qAccept',
      label: 'qAccept',
      position: Vector2(850, 200),
      isInitial: false,
      isAccepting: true,
    );

    final transitions = <TMTransition>{
      TMTransition(
        id: 't1',
        fromState: q0,
        toState: q1,
        label: '0→X,R',
        readSymbol: '0',
        writeSymbol: 'X',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't2',
        fromState: q0,
        toState: q2,
        label: '1→X,R',
        readSymbol: '1',
        writeSymbol: 'X',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't3',
        fromState: q0,
        toState: q0,
        label: 'X→X,R',
        readSymbol: 'X',
        writeSymbol: 'X',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't4',
        fromState: q0,
        toState: q6,
        label: 'B→#,R',
        readSymbol: 'B',
        writeSymbol: '#',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't5',
        fromState: q1,
        toState: q1,
        label: '0→0,R',
        readSymbol: '0',
        writeSymbol: '0',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't6',
        fromState: q1,
        toState: q1,
        label: '1→1,R',
        readSymbol: '1',
        writeSymbol: '1',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't7',
        fromState: q1,
        toState: q1,
        label: 'X→X,R',
        readSymbol: 'X',
        writeSymbol: 'X',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't8',
        fromState: q1,
        toState: q3,
        label: '#→#,R',
        readSymbol: '#',
        writeSymbol: '#',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't8b',
        fromState: q1,
        toState: q3,
        label: 'B→#,R',
        readSymbol: 'B',
        writeSymbol: '#',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't9',
        fromState: q2,
        toState: q2,
        label: '0→0,R',
        readSymbol: '0',
        writeSymbol: '0',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't10',
        fromState: q2,
        toState: q2,
        label: '1→1,R',
        readSymbol: '1',
        writeSymbol: '1',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't11',
        fromState: q2,
        toState: q2,
        label: 'X→X,R',
        readSymbol: 'X',
        writeSymbol: 'X',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't12',
        fromState: q2,
        toState: q4,
        label: '#→#,R',
        readSymbol: '#',
        writeSymbol: '#',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't12b',
        fromState: q2,
        toState: q4,
        label: 'B→#,R',
        readSymbol: 'B',
        writeSymbol: '#',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't13',
        fromState: q3,
        toState: q3,
        label: '0→0,R',
        readSymbol: '0',
        writeSymbol: '0',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't14',
        fromState: q3,
        toState: q3,
        label: '1→1,R',
        readSymbol: '1',
        writeSymbol: '1',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't15',
        fromState: q3,
        toState: q5,
        label: 'B→0,L',
        readSymbol: 'B',
        writeSymbol: '0',
        direction: TapeDirection.left,
      ),
      TMTransition(
        id: 't16',
        fromState: q4,
        toState: q4,
        label: '0→0,R',
        readSymbol: '0',
        writeSymbol: '0',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't17',
        fromState: q4,
        toState: q4,
        label: '1→1,R',
        readSymbol: '1',
        writeSymbol: '1',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't18',
        fromState: q4,
        toState: q5,
        label: 'B→1,L',
        readSymbol: 'B',
        writeSymbol: '1',
        direction: TapeDirection.left,
      ),
      TMTransition(
        id: 't19',
        fromState: q5,
        toState: q5,
        label: '0→0,L',
        readSymbol: '0',
        writeSymbol: '0',
        direction: TapeDirection.left,
      ),
      TMTransition(
        id: 't20',
        fromState: q5,
        toState: q5,
        label: '1→1,L',
        readSymbol: '1',
        writeSymbol: '1',
        direction: TapeDirection.left,
      ),
      TMTransition(
        id: 't21',
        fromState: q5,
        toState: q5,
        label: '#→#,L',
        readSymbol: '#',
        writeSymbol: '#',
        direction: TapeDirection.left,
      ),
      TMTransition(
        id: 't22',
        fromState: q5,
        toState: q0,
        label: 'X→X,R',
        readSymbol: 'X',
        writeSymbol: 'X',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't23',
        fromState: q0,
        toState: q6,
        label: '#→#,R',
        readSymbol: '#',
        writeSymbol: '#',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't24',
        fromState: q6,
        toState: q6,
        label: '0→0,R',
        readSymbol: '0',
        writeSymbol: '0',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't25',
        fromState: q6,
        toState: q6,
        label: '1→1,R',
        readSymbol: '1',
        writeSymbol: '1',
        direction: TapeDirection.right,
      ),
      TMTransition(
        id: 't26',
        fromState: q6,
        toState: qAccept,
        label: 'B→B,R',
        readSymbol: 'B',
        writeSymbol: 'B',
        direction: TapeDirection.right,
      ),
    };

    return TM(
      id: id ?? 'tm_copy_string',
      name: name ?? 'MT - Cópia de string',
      states: {q0, q1, q2, q3, q4, q5, q6, qAccept},
      transitions: transitions,
      alphabet: {'0', '1'},
      initialState: q0,
      acceptingStates: {qAccept},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 1000, 700),
      tapeAlphabet: {'0', '1', 'X', '#', 'B'},
      blankSymbol: 'B',
    );
  }

  /// Creates a TM that recognizes a^n b^n (equal numbers of a's then b's)
  ///
  /// Language: { a^n b^n | n >= 1 }
  ///
  /// Strategy: Cross off one 'a' and one 'b' at a time.
  /// - Replace leftmost 'a' with 'X', scan right to find leftmost 'b',
  ///   replace with 'Y', scan left to find next 'a'.
  /// - When no more 'a' remains, verify no 'b' remains.
  static TM aNbN({
    String? id,
    String? name,
    math.Rectangle? bounds,
  }) {
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
      position: Vector2(300, 300),
      isInitial: false,
      isAccepting: false,
    );

    final q4 = State(
      id: 'q4',
      label: 'q4',
      position: Vector2(700, 200),
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

    // q0: Skip over 'Y', check if done
    final t2 = TMTransition(
      id: 't2',
      fromState: q0,
      toState: q4,
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

    // q4: Verify all Y's consumed (skip Y's)
    final t9 = TMTransition(
      id: 't9',
      fromState: q4,
      toState: q4,
      label: 'Y→Y,R',
      readSymbol: 'Y',
      writeSymbol: 'Y',
      direction: TapeDirection.right,
    );

    return TM(
      id: id ?? 'tm_anbn',
      name: name ?? 'a^n b^n',
      states: {q0, q1, q2, q3, q4},
      transitions: {t1, t2, t3, t4, t5, t6, t7, t8, t9},
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

  /// Creates a TM that checks if a binary input is a palindrome.
  ///
  /// Language: { w ∈ {0,1}* | w = w^R }
  ///
  /// Strategy: Compare first and last characters, cross them off,
  /// repeat until string is empty or single character.
  static TM palindrome({
    String? id,
    String? name,
    math.Rectangle? bounds,
  }) {
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
      id: 'q5',
      label: 'q5',
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

    // If blank or X: accept (empty or single char palindrome)
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
      toState: qAccept,
      label: 'X→X,S',
      readSymbol: 'X',
      writeSymbol: 'X',
      direction: TapeDirection.stay,
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

    // q3: If we find X (single char case after marking), accept
    // Actually q3 finding X means first=last (single unmatched), go left to q0
    // Let's handle q0 seeing X -> accept

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

  /// Returns a list of all available example TMs
  static List<TM> getAllExamples() {
    return [
      binaryToUnary(),
      copyString(),
      binaryIncrement(),
      palindrome(),
    ];
  }

  /// Returns a map of example names to their factory functions
  static Map<String, TM Function()> getExampleFactories() {
    return {
      'MT - Binário para unário': binaryToUnary,
      'MT - Cópia de string': copyString,
      'MT - Incremento binário': binaryIncrement,
      'MT - Verificador de palíndromo': palindrome,
    };
  }

  /// Gets an example TM by name
  static TM? getExampleByName(String name) {
    final factories = getExampleFactories();
    final factory = factories[name];
    return factory?.call();
  }
}
