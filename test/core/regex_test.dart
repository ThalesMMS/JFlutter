import 'package:test/test.dart';
import 'package:jflutter/core/regex.dart';

void main() {
  group('Regex to Postfix Conversion', () {
    test('Basic character', () {
      expect(regexToPostfix('a'), equals(['a']));
    });

    test('Concatenation', () {
      expect(regexToPostfix('ab'), equals(['a', 'b', '.']));
    });

    test('Alternation', () {
      expect(regexToPostfix('a|b'), equals(['a', 'b', '|']));
    });

    test('Kleene star', () {
      expect(regexToPostfix('a*'), equals(['a', '*']));
    });

    test('One or more', () {
      expect(regexToPostfix('a+'), equals(['a', '+']));
    });

    test('Zero or one', () {
      expect(regexToPostfix('a?'), equals(['a', 'λ', '|']));
    });

    test('Character class', () {
      expect(regexToPostfix('[a-c]'), equals(['[a-c]']));
    });

    test('Complex expression', () {
      expect(
        regexToPostfix('(a|b)*c'),
        equals(['a', 'b', '|', '*', 'c', '.']),
      );
    });
  });
}
