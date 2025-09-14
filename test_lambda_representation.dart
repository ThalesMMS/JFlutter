import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/cfg.dart';
import 'package:jflutter/core/lr_parsing.dart';

void main() {
  test('Debug lambda representation', () {
    final grammar = ContextFreeGrammar.fromString('''
      S → aSb | λ
    ''');
    
    print('Grammar productions:');
    for (final prod in grammar.productions) {
      print('  $prod');
      print('    RHS: "${prod.rightHandSide}"');
      print('    RHS length: ${prod.rightHandSide.length}');
    }
    
    final augmentedGrammar = LRParsing.createAugmentedGrammar(grammar);
    print('\nAugmented grammar productions:');
    for (final prod in augmentedGrammar.productions) {
      print('  $prod');
      print('    RHS: "${prod.rightHandSide}"');
      print('    RHS length: ${prod.rightHandSide.length}');
    }
  });
}
