import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/cfg.dart';
import 'package:jflutter/core/lr_parsing.dart';

void main() {
  test('Debug rejection of invalid string', () {
    final grammar = ContextFreeGrammar.fromString('''
      S → aSb | λ
    ''');
    
    // Test string "ab" which should be rejected
    final result = LRParsing.parseString(grammar, 'ab');
    print('Parsing "ab":');
    print('Accepted: ${result.accepted}');
    print('Explanation: ${result.explanation}');
    print('Steps:');
    for (final step in result.steps) {
      print('  $step');
    }
    
    expect(result.accepted, isFalse);
  });
}
