# Automata Theory

Implementations of some automatons in Dart.

### Created by Pedro Lemos ([@pedrolemoz](https://github.com/pedrolemoz)) in 22/07/2023

Current implementations:

- Deterministic Finite Automaton (DFA)
- Non-deterministic Finite Automaton (NFA)
- Non-deterministic Automaton with Epsilon transitions (eNFA)
- Adjacency Matrix for any Automaton

### Deterministic Finite Automaton

```dart
// DFA over the set {a, b} that contains the substring "aabb"
void main() {
  final q0 = DeterministicState(name: 'q0', isInitial: true);
  final q1 = DeterministicState(name: 'q1');
  final q2 = DeterministicState(name: 'q2');
  final q3 = DeterministicState(name: 'q3');
  final q4 = DeterministicState(name: 'q4', isFinal: true);

  q0.setTransitions(
    [
      MapEntry('a', q1),
      MapEntry('b', q0),
    ],
  );

  q1.setTransitions(
    [
      MapEntry('a', q2),
      MapEntry('b', q0),
    ],
  );

  q2.setTransitions(
    [
      MapEntry('a', q2),
      MapEntry('b', q3),
    ],
  );

  q3.setTransitions(
    [
      MapEntry('a', q1),
      MapEntry('b', q4),
    ],
  );

  q4.setTransition(MapEntry(epsilon, q4));

  final automaton = DFA(
    states: {q0, q1, q2, q3, q4},
    alphabet: {'a', 'b'},
  );

  print(automaton.evaluate('aaabbb')); // true
  print(automaton.evaluate('abab')); // false
}
```

### Non-deterministic Finite Automaton

```dart
// NFA over the set {0, 1} that starts with the substring "10"
void main() {
  final q0 = NonDeterministicState(name: 'q0', isInitial: true);
  final q1 = NonDeterministicState(name: 'q1');
  final q2 = NonDeterministicState(name: 'q2', isFinal: true);

  q0.setTransition(MapEntry('1', {q1}));

  q1.setTransition(MapEntry('0', {q2}));

  q2.setTransition(MapEntry(epsilon, {q2}));

  final automaton = NFA(
    states: {q0, q1, q2},
    alphabet: {'0', '1'},
  );

  print(automaton.evaluate('101111')); // true
  print(automaton.evaluate('110101')); // false
}
```

### Non-deterministic Automaton with Epsilon transitions

```dart
// eNFA over the set {a, b, c} that is exactly the substring "abc" or ends with the substring "cc"
void main() {
  final q0 = NonDeterministicState(name: 'q0', isInitial: true);
  final q1 = NonDeterministicState(name: 'q1');
  final q2 = NonDeterministicState(name: 'q2');
  final q3 = NonDeterministicState(name: 'q3');
  final q4 = NonDeterministicState(name: 'q4', isFinal: true);
  final q5 = NonDeterministicState(name: 'q5');
  final q6 = NonDeterministicState(name: 'q6');
  final q7 = NonDeterministicState(name: 'q7', isFinal: true);

  q0.setTransition(MapEntry(epsilon, {q1, q5}));

  q1.setTransition(MapEntry('a', {q2}));

  q2.setTransition(MapEntry('b', {q3}));

  q3.setTransition(MapEntry('c', {q4}));

  q5.setTransitions([
    MapEntry('a', {q5}),
    MapEntry('b', {q5}),
    MapEntry('c', {q5, q6}),
  ]);

  q6.setTransition(MapEntry('c', {q7}));

  final automaton = EpsilonNFA(
    states: {q0, q1, q2, q3, q4, q5, q6, q7},
    alphabet: {'a', 'b', 'c'},
  );

  print(automaton.evaluate('abccc')); // true
  print(automaton.evaluate('abaaabb')); // false
}
```