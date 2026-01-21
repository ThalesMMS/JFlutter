//
//  regex_simplifier_test.dart
//  JFlutter
//
//  Testes que validam a simplificação de expressões regulares através da
//  aplicação de identidades algébricas e remoção de parênteses desnecessários,
//  assegurando que as transformações preservam a semântica da expressão original.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/regex_simplifier.dart';
import 'package:jflutter/core/result.dart';

void main() {
  group('RegexSimplifier - parentheses removal', () {
    test('removes outer parentheses from simple expression', () {
      final result = RegexSimplifier.simplify('(a)');
      expect(result.isSuccess, true);
      expect(result.data, 'a');
    });

    test('removes nested parentheses', () {
      final result = RegexSimplifier.simplify('((a))');
      expect(result.isSuccess, true);
      expect(result.data, 'a');
    });

    test('removes multiple levels of nested parentheses', () {
      final result = RegexSimplifier.simplify('(((a)))');
      expect(result.isSuccess, true);
      expect(result.data, 'a');
    });

    test('preserves necessary parentheses in union', () {
      final result = RegexSimplifier.simplify('(a|b)c');
      expect(result.isSuccess, true);
      expect(result.data, '(a|b)c');
    });

    test('removes redundant parentheses around single symbols', () {
      final result = RegexSimplifier.simplify('(a)(b)');
      expect(result.isSuccess, true);
      expect(result.data, 'ab');
    });

    test('removes outer parentheses from complex expression', () {
      final result = RegexSimplifier.simplify('(a|b)');
      expect(result.isSuccess, true);
      expect(result.data, 'a|b');
    });

    test('handles parentheses with Kleene star correctly', () {
      final result = RegexSimplifier.simplify('(a)*');
      expect(result.isSuccess, true);
      expect(result.data, 'a*');
    });

    test('preserves parentheses needed for grouping with star', () {
      final result = RegexSimplifier.simplify('(ab)*');
      expect(result.isSuccess, true);
      expect(result.data, '(ab)*');
    });

    test('removes redundant nested parentheses in concatenation', () {
      final result = RegexSimplifier.simplify('(a)(b)(c)');
      expect(result.isSuccess, true);
      expect(result.data, 'abc');
    });

    test('handles mixed redundant and necessary parentheses', () {
      final result = RegexSimplifier.simplify('((a|b))c');
      expect(result.isSuccess, true);
      expect(result.data, '(a|b)c');
    });

    test('returns error for unbalanced parentheses', () {
      final result = RegexSimplifier.simplify('(a');
      expect(result.isSuccess, false);
      expect(result.error, contains('Unbalanced'));
    });

    test('returns error for mismatched closing parenthesis', () {
      final result = RegexSimplifier.simplify('a)');
      expect(result.isSuccess, false);
      expect(result.error, contains('Unbalanced'));
    });

    test('handles empty parentheses correctly', () {
      final result = RegexSimplifier.simplify('()');
      expect(result.isSuccess, true);
      // Empty parens should be removed or handled gracefully
    });

    test('preserves operator precedence without unnecessary parens', () {
      final result = RegexSimplifier.simplify('a|(b)');
      expect(result.isSuccess, true);
      expect(result.data, 'a|b');
    });

    test('handles concatenation after removing outer parentheses', () {
      final result = RegexSimplifier.simplify('(a)b(c)');
      expect(result.isSuccess, true);
      expect(result.data, 'abc');
    });
  });
}
