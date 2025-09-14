import 'package:flutter_test/flutter_test.dart';
import '../lib/core/regex.dart';
import '../lib/core/automaton.dart';

void main() {
  group('Regex to NFA Conversion', () {
    test('Basic character', () {
      final nfa = automatonFromRegex('a');
      expect(nfa.states.length, 2); // Start and end states
      expect(nfa.transitions.length, 1); // Single transition on 'a'
      expect(nfa.accepts('a'), isTrue);
      expect(nfa.accepts('b'), isFalse);
      expect(nfa.accepts(''), isFalse);
      expect(nfa.accepts('aa'), isFalse);
    });

    test('Concatenation', () {
      final nfa = automatonFromRegex('ab');
      expect(nfa.states.length, 3); // Start, middle, and end states
      expect(nfa.accepts('ab'), isTrue);
      expect(nfa.accepts('a'), isFalse);
      expect(nfa.accepts('b'), isFalse);
      expect(nfa.accepts('abc'), isFalse);
    });

    test('Alternation', () {
      final nfa = automatonFromRegex('a|b');
      expect(nfa.states.length, 4); // Start, two middle states, and end
      expect(nfa.accepts('a'), isTrue);
      expect(nfa.accepts('b'), isTrue);
      expect(nfa.accepts('ab'), isFalse);
      expect(nfa.accepts(''), isFalse);
    });

    test('Kleene star', () {
      final nfa = automatonFromRegex('a*');
      expect(nfa.accepts(''), isTrue);
      expect(nfa.accepts('a'), isTrue);
      expect(nfa.accepts('aa'), isTrue);
      expect(nfa.accepts('aaa'), isTrue);
      expect(nfa.accepts('b'), isFalse);
      expect(nfa.accepts('aab'), isFalse);
    });

    test('One or more', () {
      final nfa = automatonFromRegex('a+');
      expect(nfa.accepts(''), isFalse);
      expect(nfa.accepts('a'), isTrue);
      expect(nfa.accepts('aa'), isTrue);
      expect(nfa.accepts('aaa'), isTrue);
      expect(nfa.accepts('b'), isFalse);
    });

    test('Zero or one', () {
      final nfa = automatonFromRegex('a?');
      expect(nfa.accepts(''), isTrue);
      expect(nfa.accepts('a'), isTrue);
      expect(nfa.accepts('aa'), isFalse);
      expect(nfa.accepts('b'), isFalse);
    });

    test('Character class', () {
      final nfa = automatonFromRegex('[a-c]');
      expect(nfa.accepts('a'), isTrue);
      expect(nfa.accepts('b'), isTrue);
      expect(nfa.accepts('c'), isTrue);
      expect(nfa.accepts('d'), isFalse);
      expect(nfa.accepts(''), isFalse);
      expect(nfa.accepts('ab'), isFalse);
    });

    test('Character class with range', () {
      final nfa = automatonFromRegex('[0-9]');
      for (var i = 0; i <= 9; i++) {
        expect(nfa.accepts(i.toString()), isTrue);
      }
      expect(nfa.accepts('a'), isFalse);
      expect(nfa.accepts(''), isFalse);
      expect(nfa.accepts('10'), isFalse);
    });

    test('Complex expression', () {
      final nfa = automatonFromRegex('(a|b)*c');
      expect(nfa.accepts('c'), isTrue);
      expect(nfa.accepts('ac'), isTrue);
      expect(nfa.accepts('bc'), isTrue);
      expect(nfa.accepts('aabbac'), isTrue);
      expect(nfa.accepts(''), isFalse);
      expect(nfa.accepts('a'), isFalse);
      expect(nfa.accepts('ab'), isFalse);
      expect(nfa.accepts('abca'), isFalse);
    });

    test('Complex expression with character class', () {
      final nfa = automatonFromRegex('[0-9]+(\\.[0-9]+)?');
      expect(nfa.accepts('0'), isTrue);
      expect(nfa.accepts('123'), isTrue);
      expect(nfa.accepts('3.14'), isTrue);
      expect(nfa.accepts('0.123'), isTrue);
      expect(nfa.accepts(''), isFalse);
      expect(nfa.accepts('.'), isFalse);
      expect(nfa.accepts('abc'), isFalse);
      expect(nfa.accepts('123.'), isFalse);
      expect(nfa.accepts('.456'), isFalse);
    });
  });
}
