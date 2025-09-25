import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/regex/ast.dart';
import 'package:jflutter/core/regex/parser.dart';

void main() {
  group('RegexExpressionParser', () {
    test('parses alternation with concatenation precedence', () {
      final result = RegexExpressionParser.parse('ab|c');

      expect(result.isSuccess, isTrue);
      final ast = result.data!;
      final root = ast.root;

      expect(root, isA<RegexAlternationNode>());
      final alternation = root as RegexAlternationNode;
      expect(alternation.left, isA<RegexConcatenationNode>());
      expect(alternation.right, isA<RegexLiteralNode>());
    });

    test('supports counted quantifiers', () {
      final result = RegexExpressionParser.parse('a{2,3}');

      expect(result.isSuccess, isTrue);
      final ast = result.data!;
      final root = ast.root as RegexQuantifierNode;
      expect(root.min, 2);
      expect(root.max, 3);
    });

    test('fails on malformed expressions', () {
      final result = RegexExpressionParser.parse('a|');
      expect(result.isFailure, isTrue);
    });
  });
}
