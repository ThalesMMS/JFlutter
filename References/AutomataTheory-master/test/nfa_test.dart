import 'package:test/test.dart';

import 'package:automata_theory/abstractions/constants.dart';
import 'package:automata_theory/abstractions/states.dart';
import 'package:automata_theory/implementations/nfa.dart';

void main() {
  group('NFA over the set {0, 1} that starts with the substring "10"', () {
    final q0 = NonDeterministicState(name: 'q0', isInitial: true);
    final q1 = NonDeterministicState(name: 'q1');
    final q2 = NonDeterministicState(name: 'q2', isFinal: true);

    q0.setTransition(MapEntry('1', {q1}));

    q1.setTransition(MapEntry('0', {q2}));

    q2.setTransition(MapEntry(epsilon, {q2}));

    final nfa1 = NFA(states: {q0, q1, q2}, alphabet: {'0', '1'});

    test('Should accept the string "10"', () {
      final result = nfa1.evaluate('10');
      expect(result, true);
    });
    test('Should accept the string "10100101111011111"', () {
      final result = nfa1.evaluate('10100101111011111');
      expect(result, true);
    });
    test('Should accept the string "10000"', () {
      final result = nfa1.evaluate('10000');
      expect(result, true);
    });
    test('Should accept the string "101111"', () {
      final result = nfa1.evaluate('101111');
      expect(result, true);
    });
    test('Should accept the string "1010001"', () {
      final result = nfa1.evaluate('1010001');
      expect(result, true);
    });
    test('Should reject the string "01"', () {
      final result = nfa1.evaluate('01');
      expect(result, false);
    });
    test('Should reject the string "0000"', () {
      final result = nfa1.evaluate('0000');
      expect(result, false);
    });
    test('Should reject the empty string', () {
      final result = nfa1.evaluate('');
      expect(result, false);
    });
    test('Should reject the string "01011101100"', () {
      final result = nfa1.evaluate('01011101100');
      expect(result, false);
    });
    test('Should reject the string "111101101"', () {
      final result = nfa1.evaluate('111101101');
      expect(result, false);
    });
    test('Should reject the string "1101010"', () {
      final result = nfa1.evaluate('1101010');
      expect(result, false);
    });
  });

  group('NFA over the set {0, 1} that ends with the substring "11"', () {
    final q0 = NonDeterministicState(name: 'q0', isInitial: true);
    final q1 = NonDeterministicState(name: 'q1');
    final q2 = NonDeterministicState(name: 'q2', isFinal: true);

    q0.setTransitions([
      MapEntry('0', {q0}),
      MapEntry('1', {q0, q1}),
    ]);

    q1.setTransition(MapEntry('1', {q2}));

    final nfa2 = NFA(states: {q0, q1, q2}, alphabet: {'0', '1'});

    test('Should accept the string "11"', () {
      final result = nfa2.evaluate('11');
      expect(result, true);
    });
    test('Should accept the string "1011"', () {
      final result = nfa2.evaluate('1011');
      expect(result, true);
    });
    test('Should accept the string "1100111011"', () {
      final result = nfa2.evaluate('1100111011');
      expect(result, true);
    });
    test('Should accept the string "0000011"', () {
      final result = nfa2.evaluate('0000011');
      expect(result, true);
    });
    test('Should accept the string "11011011011"', () {
      final result = nfa2.evaluate('11011011011');
      expect(result, true);
    });
    test('Should accept the string "1011101110111"', () {
      final result = nfa2.evaluate('1011101110111');
      expect(result, true);
    });
    test('Should accept the string "1111111"', () {
      final result = nfa2.evaluate('1111111');
      expect(result, true);
    });
    test('Should accept the string "00011000111"', () {
      final result = nfa2.evaluate('00011000111');
      expect(result, true);
    });
    test('Should accept the string "1011011101101011"', () {
      final result = nfa2.evaluate('1011011101101011');
      expect(result, true);
    });
    test('Should reject the empty string', () {
      final result = nfa2.evaluate('');
      expect(result, false);
    });
    test('Should reject the string "0"', () {
      final result = nfa2.evaluate('0');
      expect(result, false);
    });
    test('Should reject the string "1"', () {
      final result = nfa2.evaluate('1');
      expect(result, false);
    });
    test('Should reject the string "10"', () {
      final result = nfa2.evaluate('10');
      expect(result, false);
    });
    test('Should reject the string "01"', () {
      final result = nfa2.evaluate('01');
      expect(result, false);
    });
    test('Should reject the string "1001010"', () {
      final result = nfa2.evaluate('1001010');
      expect(result, false);
    });
    test('Should reject the string "1110110"', () {
      final result = nfa2.evaluate('1110110');
      expect(result, false);
    });
    test('Should reject the string "000110001"', () {
      final result = nfa2.evaluate('000110001');
      expect(result, false);
    });
    test('Should reject the string "0001100010"', () {
      final result = nfa2.evaluate('0001100010');
      expect(result, false);
    });
    test('Should reject the string "0000000"', () {
      final result = nfa2.evaluate('0000000');
      expect(result, false);
    });
    test('Should reject the string "101010101001"', () {
      final result = nfa2.evaluate('101010101001');
      expect(result, false);
    });
    test('Should reject the string "1010110"', () {
      final result = nfa2.evaluate('1010110');
      expect(result, false);
    });
    test('Should reject the string "1110"', () {
      final result = nfa2.evaluate('1110');
      expect(result, false);
    });
  });

  group('NFA over the set {a, b} that ends with the substring "bba"', () {
    final q0 = NonDeterministicState(name: 'q0', isInitial: true);
    final q1 = NonDeterministicState(name: 'q1');
    final q2 = NonDeterministicState(name: 'q2');
    final q3 = NonDeterministicState(name: 'q2', isFinal: true);

    q0.setTransitions([
      MapEntry('a', {q0}),
      MapEntry('b', {q0, q1}),
    ]);

    q1.setTransition(MapEntry('b', {q2}));

    q2.setTransition(MapEntry('a', {q3}));

    final nfa3 = NFA(states: {q0, q1, q2, q3}, alphabet: {'a', 'b'});

    test('Should accept the string "bba"', () {
      final result = nfa3.evaluate('bba');
      expect(result, true);
    });
    test('Should accept the string "abba"', () {
      final result = nfa3.evaluate('abba');
      expect(result, true);
    });
    test('Should accept the string "bbbba"', () {
      final result = nfa3.evaluate('bbbba');
      expect(result, true);
    });
    test('Should accept the string "bababba"', () {
      final result = nfa3.evaluate('bababba');
      expect(result, true);
    });
    test('Should accept the string "bbbaaaabba"', () {
      final result = nfa3.evaluate('bbbaaaabba');
      expect(result, true);
    });
    test('Should reject the empty string', () {
      final result = nfa3.evaluate('');
      expect(result, false);
    });
    test('Should reject the string "a"', () {
      final result = nfa3.evaluate('a');
      expect(result, false);
    });
    test('Should reject the string "b"', () {
      final result = nfa3.evaluate('b');
      expect(result, false);
    });
    test('Should reject the string "ab"', () {
      final result = nfa3.evaluate('ab');
      expect(result, false);
    });
    test('Should reject the string "ba"', () {
      final result = nfa3.evaluate('ba');
      expect(result, false);
    });
    test('Should reject the string "baa"', () {
      final result = nfa3.evaluate('baa');
      expect(result, false);
    });
    test('Should reject the string "abb"', () {
      final result = nfa3.evaluate('abb');
      expect(result, false);
    });
    test('Should reject the string "bab"', () {
      final result = nfa3.evaluate('bab');
      expect(result, false);
    });
    test('Should reject the string "aba"', () {
      final result = nfa3.evaluate('aba');
      expect(result, false);
    });
    test('Should reject the string "abab"', () {
      final result = nfa3.evaluate('abab');
      expect(result, false);
    });
    test('Should reject the string "baba"', () {
      final result = nfa3.evaluate('baba');
      expect(result, false);
    });
  });
}
