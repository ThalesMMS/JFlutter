import 'package:test/test.dart';

import 'package:automata_theory/abstractions/constants.dart';
import 'package:automata_theory/abstractions/states.dart';
import 'package:automata_theory/implementations/dfa.dart';

void main() {
  group('DFA over the set {a, b} that contains the substring "aabb"', () {
    final q0 = DeterministicState(name: 'q0', isInitial: true);
    final q1 = DeterministicState(name: 'q1');
    final q2 = DeterministicState(name: 'q2');
    final q3 = DeterministicState(name: 'q3');
    final q4 = DeterministicState(name: 'q4', isFinal: true);

    q0.setTransitions([MapEntry('a', q1), MapEntry('b', q0)]);

    q1.setTransitions([MapEntry('a', q2), MapEntry('b', q0)]);

    q2.setTransitions([MapEntry('a', q2), MapEntry('b', q3)]);

    q3.setTransitions([MapEntry('a', q1), MapEntry('b', q4)]);

    q4.setTransition(MapEntry(epsilon, q4));

    final dfa1 = DFA(states: {q0, q1, q2, q3, q4}, alphabet: {'a', 'b'});

    test('Should accept the string "aabb"', () {
      final result = dfa1.evaluate('aabb');
      expect(result, true);
    });
    test('Should accept the string "aaabb"', () {
      final result = dfa1.evaluate('aaabb');
      expect(result, true);
    });
    test('Should accept the string "aaabbb"', () {
      final result = dfa1.evaluate('aaabbb');
      expect(result, true);
    });
    test('Should accept the string "aaaababbbaaabb"', () {
      final result = dfa1.evaluate('aaaababbbaaabb');
      expect(result, true);
    });
    test('Should accept the string "ababaababbbbaaabba"', () {
      final result = dfa1.evaluate('ababaababbbbaaabba');
      expect(result, true);
    });
    test('Should reject the empty string', () {
      final result = dfa1.evaluate('');
      expect(result, false);
    });
    test('Should reject the string "a"', () {
      final result = dfa1.evaluate('a');
      expect(result, false);
    });
    test('Should reject the string "ab"', () {
      final result = dfa1.evaluate('ab');
      expect(result, false);
    });
    test('Should reject the string "ba"', () {
      final result = dfa1.evaluate('ba');
      expect(result, false);
    });
    test('Should reject the string "bab"', () {
      final result = dfa1.evaluate('bab');
      expect(result, false);
    });
    test('Should reject the string "baba"', () {
      final result = dfa1.evaluate('baba');
      expect(result, false);
    });
    test('Should reject the string "b"', () {
      final result = dfa1.evaluate('b');
      expect(result, false);
    });
    test('Should reject the string "abab"', () {
      final result = dfa1.evaluate('abab');
      expect(result, false);
    });
    test('Should reject the string "bbaa"', () {
      final result = dfa1.evaluate('bbaa');
      expect(result, false);
    });
    test('Should reject the string "abababbababbbab"', () {
      final result = dfa1.evaluate('abababbababbbab');
      expect(result, false);
    });
  });

  group(
    'DFA over the set {a, b} that does not contains the substring "aabb"',
    () {
      final q0 = DeterministicState(name: 'q0', isFinal: true, isInitial: true);
      final q1 = DeterministicState(name: 'q1', isFinal: true);
      final q2 = DeterministicState(name: 'q2', isFinal: true);
      final q3 = DeterministicState(name: 'q3', isFinal: true);
      final q4 = DeterministicState(name: 'q4');

      q0.setTransitions([MapEntry('a', q1), MapEntry('b', q0)]);

      q1.setTransitions([MapEntry('a', q2), MapEntry('b', q0)]);

      q2.setTransitions([MapEntry('a', q2), MapEntry('b', q3)]);

      q3.setTransitions([MapEntry('a', q1), MapEntry('b', q4)]);

      q4.setTransition(MapEntry(epsilon, q4));

      final dfa2 = DFA(states: {q0, q1, q2, q3, q4}, alphabet: {'a', 'b'});

      test('Should reject the string "aabb"', () {
        final result = dfa2.evaluate('aabb');
        expect(result, false);
      });
      test('Should reject the string "aaabb"', () {
        final result = dfa2.evaluate('aaabb');
        expect(result, false);
      });
      test('Should reject the string "aaabbb"', () {
        final result = dfa2.evaluate('aaabbb');
        expect(result, false);
      });
      test('Should reject the string "aaaababbbaaabb"', () {
        final result = dfa2.evaluate('aaaababbbaaabb');
        expect(result, false);
      });
      test('Should reject the string "ababaababbbbaaabba"', () {
        final result = dfa2.evaluate('ababaababbbbaaabba');
        expect(result, false);
      });
      test('Should accept the empty string', () {
        final result = dfa2.evaluate('');
        expect(result, true);
      });
      test('Should accept the string "a"', () {
        final result = dfa2.evaluate('a');
        expect(result, true);
      });
      test('Should accept the string "ab"', () {
        final result = dfa2.evaluate('ab');
        expect(result, true);
      });
      test('Should accept the string "ba"', () {
        final result = dfa2.evaluate('ba');
        expect(result, true);
      });
      test('Should accept the string "bab"', () {
        final result = dfa2.evaluate('bab');
        expect(result, true);
      });
      test('Should accept the string "baba"', () {
        final result = dfa2.evaluate('baba');
        expect(result, true);
      });
      test('Should accept the string "b"', () {
        final result = dfa2.evaluate('b');
        expect(result, true);
      });
      test('Should accept the string "abab"', () {
        final result = dfa2.evaluate('abab');
        expect(result, true);
      });
      test('Should accept the string "bbaa"', () {
        final result = dfa2.evaluate('bbaa');
        expect(result, true);
      });
      test('Should accept the string "abababbababbbab"', () {
        final result = dfa2.evaluate('abababbababbbab');
        expect(result, true);
      });
    },
  );
}
