import 'dart:io';

import 'package:automata_theory/automatons.dart';

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

  stdout
    ..writeln(automaton.evaluate('abccc')) // true
    ..writeln(automaton.evaluate('abaaabb')); // false
}
