import 'package:test/test.dart';

import 'package:automata_theory/abstractions/constants.dart';
import 'package:automata_theory/abstractions/states.dart';
import 'package:automata_theory/implementations/episilon_nfa.dart';

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

  final eNfa = EpsilonNFA(
    states: {q0, q1, q2, q3, q4, q5, q6, q7},
    alphabet: {'a', 'b', 'c'},
  );

  group(
    'eNFA over the set {a, b, c} that is exactly the substring "abc" or ends with the substring "cc"',
    () {
      test('Should accept the string "abc"', () {
        final result = eNfa.evaluate('abc');
        expect(result, true);
      });
      test('Should accept the string "cc"', () {
        final result = eNfa.evaluate('cc');
        expect(result, true);
      });
      test('Should accept the string "abccc"', () {
        final result = eNfa.evaluate('abccc');
        expect(result, true);
      });
      test('Should accept the string "aabbcc"', () {
        final result = eNfa.evaluate('aabbcc');
        expect(result, true);
      });
      test('Should accept the string "bbaacc"', () {
        final result = eNfa.evaluate('bbaacc');
        expect(result, true);
      });
      test('Should accept the string "cccccc"', () {
        final result = eNfa.evaluate('cccccc');
        expect(result, true);
      });
      test('Should accept the string "abababacc"', () {
        final result = eNfa.evaluate('abababacc');
        expect(result, true);
      });
      test('Should accept the string "cbcbcbccc"', () {
        final result = eNfa.evaluate('cbcbcbccc');
        expect(result, true);
      });
      test('Should reject the empty string', () {
        final result = eNfa.evaluate('');
        expect(result, false);
      });
      test('Should reject the string "abca"', () {
        final result = eNfa.evaluate('abca');
        expect(result, false);
      });
      test('Should reject the string "a"', () {
        final result = eNfa.evaluate('a');
        expect(result, false);
      });
      test('Should reject the string "b"', () {
        final result = eNfa.evaluate('b');
        expect(result, false);
      });
      test('Should reject the string "c"', () {
        final result = eNfa.evaluate('c');
        expect(result, false);
      });
      test('Should reject the string "aa"', () {
        final result = eNfa.evaluate('aa');
        expect(result, false);
      });
      test('Should reject the string "bb"', () {
        final result = eNfa.evaluate('bb');
        expect(result, false);
      });
      test('Should reject the string "aba"', () {
        final result = eNfa.evaluate('aba');
        expect(result, false);
      });
      test('Should reject the string "abaaabb"', () {
        final result = eNfa.evaluate('abaaabb');
        expect(result, false);
      });
      test('Should reject the string "bbabbabbabbbacca"', () {
        final result = eNfa.evaluate('bbabbabbabbbacca');
        expect(result, false);
      });
      test('Should reject the string "babacabacaba"', () {
        final result = eNfa.evaluate('babacabacaba');
        expect(result, false);
      });
    },
  );
}
