import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/grammar/grammar_definition_parser.dart';

void main() {
  group('GrammarDefinitionParser', () {
    test('parses simple CFG with epsilon production', () {
      const source = '''
S -> 'a' S 'b' | ε
A -> 'a' | 'b'
''';

      final result = GrammarDefinitionParser.parse(source);

      expect(result.isSuccess, isTrue);
      final analysis = result.data!;
      expect(analysis.errors, isEmpty);
      final ast = analysis.ast;
      expect(ast.startSymbol, 'S');
      expect(ast.productions.length, 2);
      expect(ast.terminals.contains('a'), isTrue);
      expect(ast.nonTerminals.contains('A'), isTrue);
    });

    test('detects references to undefined non-terminals', () {
      const source = 'S -> A';
      final result = GrammarDefinitionParser.parse(source);

      expect(result.isSuccess, isTrue);
      final analysis = result.data!;
      expect(analysis.errors, isNotEmpty);
    });

    test('fails on malformed productions', () {
      const source = 'S -> | a';
      final result = GrammarDefinitionParser.parse(source);
      expect(result.isFailure, isTrue);
    });
  });
}
