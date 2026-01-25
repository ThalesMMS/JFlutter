//
//  regex_pipeline_test.dart
//  JFlutter
//
//  Testes que validam o pipeline de expressões regulares até a construção de
//  autômatos finitos não determinísticos, avaliando literais, concatenação,
//  união, estrela de Kleene e operadores opcionais, além de assegurar o
//  tratamento adequado de entradas inválidas pelo parser.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/algorithm_operations.dart';
import 'package:jflutter/core/algorithms/regex_to_nfa_converter.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/result.dart';

Future<bool> _accepts(FSA nfa, String input) async {
  final sim = await AlgorithmOperations.simulateNfa(nfa, input);
  if (!sim.isSuccess) return false;
  return sim.data!.accepted;
}

void main() {
  group('Regex→AST→Thompson NFA pipeline', () {
    test('Literal symbol', () async {
      final res = RegexToNFAConverter.convert('a');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, ''), false);
      expect(await _accepts(nfa, 'b'), false);
    });

    test('Concatenation', () async {
      final res = RegexToNFAConverter.convert('ab');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'ab'), true);
      expect(await _accepts(nfa, 'a'), false);
      expect(await _accepts(nfa, 'b'), false);
    });

    test('Union', () async {
      final res = RegexToNFAConverter.convert('a|b');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, 'b'), true);
      expect(await _accepts(nfa, 'ab'), false);
    });

    test('Kleene star', () async {
      final res = RegexToNFAConverter.convert('a*');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, ''), true);
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, 'aaaa'), true);
      expect(await _accepts(nfa, 'b'), false);
    });

    test('Plus and Question', () async {
      final res = RegexToNFAConverter.convert('a+b?');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, 'ab'), true);
      expect(await _accepts(nfa, 'aaab'), true);
      expect(await _accepts(nfa, ''), false);
      expect(await _accepts(nfa, 'b'), false);
    });

    test('Parentheses and precedence', () async {
      final res = RegexToNFAConverter.convert('(ab|c)d');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'abd'), true);
      expect(await _accepts(nfa, 'cd'), true);
      expect(await _accepts(nfa, 'ad'), false);
    });

    test('Epsilon literal', () async {
      final res = RegexToNFAConverter.convert('ε');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, ''), true);
      expect(await _accepts(nfa, 'a'), false);
    });

    test('Character class', () async {
      final res = RegexToNFAConverter.convert('[abc]');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, 'b'), true);
      expect(await _accepts(nfa, 'c'), true);
      expect(await _accepts(nfa, 'd'), false);
    });

    test('Dot any symbol with default alphabet', () async {
      final res = RegexToNFAConverter.convert('.');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, 'b'), true);
      expect(await _accepts(nfa, 'c'), true);
      expect(await _accepts(nfa, 'd'), false);
    });

    test('Complex expression (a|bc)*d', () async {
      final res = RegexToNFAConverter.convert('(a|bc)*d');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'd'), true);
      expect(await _accepts(nfa, 'ad'), true);
      expect(await _accepts(nfa, 'bcd'), true);
      expect(await _accepts(nfa, 'abcad'), true);
      expect(await _accepts(nfa, 'ab'), false);
    });

    test('Integrates via AlgorithmOperations', () async {
      final Result<FSA> res = AlgorithmOperations.convertRegexToNfa('a(b|c)*');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, 'ab'), true);
      expect(await _accepts(nfa, 'accc'), true);
      expect(await _accepts(nfa, ''), false);
    });
  });
}
