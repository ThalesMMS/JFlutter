//
//  pda_examples.dart
//  JFlutter
//
//  Fornece exemplos prontos de autômatos de pilha para fins educacionais,
//  cobrindo casos clássicos como parênteses balanceados, palíndromos e
//  linguagens do tipo a^n b^n, com estados e transições pré-configurados.
//
//  Thales Matheus Mendonça Santos - January 2025
//

import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../../core/models/pda.dart';
import '../../core/models/pda_transition.dart';
import '../../core/models/state.dart';

/// Provides pre-configured example PDAs for educational purposes
class PDAExamples {
  /// Creates a PDA that recognizes balanced parentheses
  ///
  /// Accepts strings with balanced parentheses like: (), (()), (())(), etc.
  /// Uses stack to track opening parentheses and pops on closing parentheses.
  ///
  /// Language: { w ∈ {(,)}* | w has balanced parentheses }
  ///
  /// States:
  /// - q0: Initial state (processing input)
  /// - q1: Accepting state (reached when stack is empty)
  ///
  /// Transitions:
  /// - On '(' with Z on stack: push 'Z(' (first opening paren)
  /// - On '(' with '(' on stack: push '((' (subsequent opening parens)
  /// - On ')' with '(' on stack: pop '(' (matching closing paren)
  /// - On ε with Z on stack: move to accepting state (stack is empty)
  static PDA balancedParentheses({
    String? id,
    String? name,
    math.Rectangle? bounds,
  }) {
    final now = DateTime.now();

    // Define states
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(150, 150),
      isInitial: true,
      isAccepting: false,
    );

    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(350, 150),
      isInitial: false,
      isAccepting: true,
    );

    // Define transitions
    final transitions = {
      // Push '(' onto stack when reading '(' with Z (initial stack symbol)
      PDATransition.readAndStack(
        id: 't1',
        fromState: q0,
        toState: q0,
        inputSymbol: '(',
        popSymbol: 'Z',
        pushSymbol: 'Z(',
        label: '(,Z→Z(',
      ),

      // Push '(' onto stack when reading '(' with '(' on top
      PDATransition.readAndStack(
        id: 't2',
        fromState: q0,
        toState: q0,
        inputSymbol: '(',
        popSymbol: '(',
        pushSymbol: '((',
        label: '(,(→((',
      ),

      // Pop '(' from stack when reading ')' with '(' on top
      PDATransition.readAndStack(
        id: 't3',
        fromState: q0,
        toState: q0,
        inputSymbol: ')',
        popSymbol: '(',
        pushSymbol: '',
        label: '),(→ε',
      ),

      // Accept when stack is empty (only Z remains)
      PDATransition.readAndStack(
        id: 't4',
        fromState: q0,
        toState: q1,
        inputSymbol: '',
        popSymbol: 'Z',
        pushSymbol: '',
        label: 'ε,Z→ε',
      ),
    };

    return PDA(
      id: id ?? 'pda_balanced_parens',
      name: name ?? 'Balanced Parentheses',
      states: {q0, q1},
      transitions: transitions,
      alphabet: {'(', ')'},
      initialState: q0,
      acceptingStates: {q1},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 600, 400),
      stackAlphabet: {'Z', '('},
      initialStackSymbol: 'Z',
    );
  }

  /// Creates a PDA that recognizes palindromes over {a, b}*
  ///
  /// Accepts strings that are palindromes like: aba, abba, aabaa, etc.
  /// Uses non-deterministic transition to guess the middle of the string.
  ///
  /// Language: { w ∈ {a,b}* | w = w^R }
  ///
  /// States:
  /// - q0: Initial state (pushing symbols onto stack)
  /// - q1: Middle state (non-deterministically guessed middle)
  /// - q2: Accepting state (popping and matching symbols)
  ///
  /// Strategy:
  /// 1. Push all symbols onto stack in q0
  /// 2. Non-deterministically transition to q1 (guessing middle)
  /// 3. Pop symbols from stack matching input in q1/q2
  static PDA palindrome({String? id, String? name, math.Rectangle? bounds}) {
    final now = DateTime.now();

    // Define states
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100, 150),
      isInitial: true,
      isAccepting: false,
    );

    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(250, 150),
      isInitial: false,
      isAccepting: false,
    );

    final q2 = State(
      id: 'q2',
      label: 'q2',
      position: Vector2(400, 150),
      isInitial: false,
      isAccepting: true,
    );

    // Define transitions
    final transitions = {
      // Push 'a' onto stack
      PDATransition.readAndStack(
        id: 't1',
        fromState: q0,
        toState: q0,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'Za',
        label: 'a,Z→Za',
      ),

      PDATransition.readAndStack(
        id: 't2',
        fromState: q0,
        toState: q0,
        inputSymbol: 'a',
        popSymbol: 'a',
        pushSymbol: 'aa',
        label: 'a,a→aa',
      ),

      PDATransition.readAndStack(
        id: 't3',
        fromState: q0,
        toState: q0,
        inputSymbol: 'a',
        popSymbol: 'b',
        pushSymbol: 'ba',
        label: 'a,b→ba',
      ),

      // Push 'b' onto stack
      PDATransition.readAndStack(
        id: 't4',
        fromState: q0,
        toState: q0,
        inputSymbol: 'b',
        popSymbol: 'Z',
        pushSymbol: 'Zb',
        label: 'b,Z→Zb',
      ),

      PDATransition.readAndStack(
        id: 't5',
        fromState: q0,
        toState: q0,
        inputSymbol: 'b',
        popSymbol: 'a',
        pushSymbol: 'ab',
        label: 'b,a→ab',
      ),

      PDATransition.readAndStack(
        id: 't6',
        fromState: q0,
        toState: q0,
        inputSymbol: 'b',
        popSymbol: 'b',
        pushSymbol: 'bb',
        label: 'b,b→bb',
      ),

      // Non-deterministically guess middle (even-length palindrome)
      PDATransition.readAndStack(
        id: 't7',
        fromState: q0,
        toState: q1,
        inputSymbol: '',
        popSymbol: 'Z',
        pushSymbol: 'Z',
        label: 'ε,Z→Z',
      ),

      PDATransition.readAndStack(
        id: 't8',
        fromState: q0,
        toState: q1,
        inputSymbol: '',
        popSymbol: 'a',
        pushSymbol: 'a',
        label: 'ε,a→a',
      ),

      PDATransition.readAndStack(
        id: 't9',
        fromState: q0,
        toState: q1,
        inputSymbol: '',
        popSymbol: 'b',
        pushSymbol: 'b',
        label: 'ε,b→b',
      ),

      // Odd-length palindrome: skip middle character
      PDATransition.readAndStack(
        id: 't10',
        fromState: q0,
        toState: q1,
        inputSymbol: 'a',
        popSymbol: 'a',
        pushSymbol: 'a',
        label: 'a,a→a',
      ),

      PDATransition.readAndStack(
        id: 't11',
        fromState: q0,
        toState: q1,
        inputSymbol: 'b',
        popSymbol: 'b',
        pushSymbol: 'b',
        label: 'b,b→b',
      ),

      // Pop 'a' when reading 'a'
      PDATransition.readAndStack(
        id: 't12',
        fromState: q1,
        toState: q1,
        inputSymbol: 'a',
        popSymbol: 'a',
        pushSymbol: '',
        label: 'a,a→ε',
      ),

      // Pop 'b' when reading 'b'
      PDATransition.readAndStack(
        id: 't13',
        fromState: q1,
        toState: q1,
        inputSymbol: 'b',
        popSymbol: 'b',
        pushSymbol: '',
        label: 'b,b→ε',
      ),

      // Accept when stack is empty
      PDATransition.readAndStack(
        id: 't14',
        fromState: q1,
        toState: q2,
        inputSymbol: '',
        popSymbol: 'Z',
        pushSymbol: '',
        label: 'ε,Z→ε',
      ),
    };

    return PDA(
      id: id ?? 'pda_palindrome',
      name: name ?? 'Palindrome (w w^R)',
      states: {q0, q1, q2},
      transitions: transitions,
      alphabet: {'a', 'b'},
      initialState: q0,
      acceptingStates: {q2},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 600, 400),
      stackAlphabet: {'Z', 'a', 'b'},
      initialStackSymbol: 'Z',
    );
  }

  /// Creates a PDA that recognizes the language a^n b^n
  ///
  /// Accepts strings with equal numbers of 'a's followed by 'b's.
  /// Examples: ab, aabb, aaabbb, etc.
  ///
  /// Language: { a^n b^n | n ≥ 1 }
  ///
  /// States:
  /// - q0: Initial state (reading 'a's and pushing to stack)
  /// - q1: Middle state (reading 'b's and popping from stack)
  /// - q2: Accepting state (reached when all 'b's matched)
  ///
  /// Strategy:
  /// 1. Push each 'a' onto stack in q0
  /// 2. Transition to q1 on first 'b'
  /// 3. Pop one 'a' for each 'b' in q1
  /// 4. Accept when stack is empty
  static PDA aNbN({String? id, String? name, math.Rectangle? bounds}) {
    final now = DateTime.now();

    // Define states
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100, 150),
      isInitial: true,
      isAccepting: false,
    );

    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(250, 150),
      isInitial: false,
      isAccepting: false,
    );

    final q2 = State(
      id: 'q2',
      label: 'q2',
      position: Vector2(400, 150),
      isInitial: false,
      isAccepting: true,
    );

    // Define transitions
    final transitions = {
      // Push 'a' onto stack with Z (first 'a')
      PDATransition.readAndStack(
        id: 't1',
        fromState: q0,
        toState: q0,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'Za',
        label: 'a,Z→Za',
      ),

      // Push 'a' onto stack with 'a' on top
      PDATransition.readAndStack(
        id: 't2',
        fromState: q0,
        toState: q0,
        inputSymbol: 'a',
        popSymbol: 'a',
        pushSymbol: 'aa',
        label: 'a,a→aa',
      ),

      // First 'b': transition to q1 and pop one 'a'
      PDATransition.readAndStack(
        id: 't3',
        fromState: q0,
        toState: q1,
        inputSymbol: 'b',
        popSymbol: 'a',
        pushSymbol: '',
        label: 'b,a→ε',
      ),

      // Continue reading 'b's and popping 'a's
      PDATransition.readAndStack(
        id: 't4',
        fromState: q1,
        toState: q1,
        inputSymbol: 'b',
        popSymbol: 'a',
        pushSymbol: '',
        label: 'b,a→ε',
      ),

      // Accept when all 'a's are popped (only Z remains)
      PDATransition.readAndStack(
        id: 't5',
        fromState: q1,
        toState: q2,
        inputSymbol: '',
        popSymbol: 'Z',
        pushSymbol: '',
        label: 'ε,Z→ε',
      ),
    };

    return PDA(
      id: id ?? 'pda_anbn',
      name: name ?? 'a^n b^n',
      states: {q0, q1, q2},
      transitions: transitions,
      alphabet: {'a', 'b'},
      initialState: q0,
      acceptingStates: {q2},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 600, 400),
      stackAlphabet: {'Z', 'a'},
      initialStackSymbol: 'Z',
    );
  }

  /// Returns a list of all available example PDAs
  static List<PDA> getAllExamples() {
    return [balancedParentheses(), palindrome(), aNbN()];
  }

  /// Returns a map of example names to their factory functions
  static Map<String, PDA Function()> getExampleFactories() {
    return {
      'Balanced Parentheses': balancedParentheses,
      'Palindrome (w w^R)': palindrome,
      'a^n b^n': aNbN,
    };
  }

  /// Gets an example PDA by name
  static PDA? getExampleByName(String name) {
    final factories = getExampleFactories();
    final factory = factories[name];
    return factory?.call();
  }
}
