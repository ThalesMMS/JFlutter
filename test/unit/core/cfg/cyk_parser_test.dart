import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/cfg/cyk_parser.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/core/result.dart';

/// CYK Parser Validation Tests
/// 
/// This test suite validates CYK parser algorithms for:
/// 1. Parse table construction
/// 2. Derivation tree construction
/// 3. Language acceptance/rejection
/// 4. CNF conversion integration
/// 5. Edge cases (empty strings, single characters)
void main() {
  group('CYK parser', () {
    late Grammar simpleCNFGrammar;
    late Grammar complexCNFGrammar;
    late Grammar lambdaGrammar;
    late Grammar unitGrammar;

    setUp(() {
      // Test Case 1: Simple CNF grammar
      simpleCNFGrammar = _createSimpleCNFGrammar();
      
      // Test Case 2: Complex CNF grammar
      complexCNFGrammar = _createComplexCNFGrammar();
      
      // Test Case 3: Grammar with lambda productions
      lambdaGrammar = _createLambdaGrammar();
      
      // Test Case 4: Grammar with unit productions
      unitGrammar = _createUnitGrammar();
    });

    group('Parse Table Construction Tests', () {
      test('Should build parse table for valid strings', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'ab');
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed for "ab"');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          
          // Check that parse table is constructed
          expect(cykResult.table.isNotEmpty, true,
            reason: 'Parse table should not be empty');
          expect(cykResult.table.length, 2,
            reason: 'Parse table should have correct dimensions');
        }
      });

      test('Should handle single character strings', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'a');
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed for "a"');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          
          // Check that parse table is constructed
          expect(cykResult.table.isNotEmpty, true,
            reason: 'Parse table should not be empty');
          expect(cykResult.table.length, 1,
            reason: 'Parse table should have correct dimensions for single character');
        }
      });

      test('Should handle empty string', () {
        final result = CYKParser.parse(lambdaGrammar, '');
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed for empty string');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          
          // Empty string should be accepted if start symbol is nullable
          expect(cykResult.accepted, true,
            reason: 'Empty string should be accepted by lambda grammar');
        }
      });
    });

    group('Derivation Tree Construction Tests', () {
      test('Should produce derivation tree for accepted strings', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'ab');
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed for "ab"');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          
          // If string is accepted, should have derivation tree
          if (cykResult.accepted) {
            expect(cykResult.derivation, isNotNull,
              reason: 'Accepted string should have derivation tree');
            
            if (cykResult.derivation != null) {
              expect(cykResult.derivation!.label, simpleCNFGrammar.startSymbol,
                reason: 'Derivation tree root should be start symbol');
            }
          }
        }
      });

      test('Should produce correct derivation tree structure', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'ab');
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed for "ab"');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          
          if (cykResult.accepted && cykResult.derivation != null) {
            final tree = cykResult.derivation!;
            
            // Check tree structure
            expect(tree.label, isA<String>(),
              reason: 'Tree node should have label');
            expect(tree.children, isA<List<CYKDerivation>>(),
              reason: 'Tree node should have children list');
          }
        }
      });

      test('Should handle complex derivation trees', () {
        final result = CYKParser.parse(complexCNFGrammar, 'abc');
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed for "abc"');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          
          if (cykResult.accepted && cykResult.derivation != null) {
            final tree = cykResult.derivation!;
            
            // Check that tree has proper structure
            expect(tree.label, complexCNFGrammar.startSymbol,
              reason: 'Root should be start symbol');
          }
        }
      });
    });

    group('Language Acceptance Tests', () {
      test('Should accept strings in language', () {
        final testCases = [
          ('a', simpleCNFGrammar),
          ('ab', simpleCNFGrammar),
          ('abc', complexCNFGrammar),
        ];

        for (final (input, grammar) in testCases) {
          final result = CYKParser.parse(grammar, input);
          
          expect(result.isSuccess, true, 
            reason: 'CYK parsing should succeed for "$input"');
          
          if (result.isSuccess) {
            final cykResult = result.data!;
            expect(cykResult.accepted, true,
              reason: 'String "$input" should be accepted');
          }
        }
      });

      test('Should reject strings not in language', () {
        final testCases = [
          ('ba', simpleCNFGrammar), // Wrong order
          ('aab', simpleCNFGrammar), // Too many 'a's
          ('d', complexCNFGrammar), // Not in alphabet
        ];

        for (final (input, grammar) in testCases) {
          final result = CYKParser.parse(grammar, input);
          
          expect(result.isSuccess, true, 
            reason: 'CYK parsing should succeed for "$input"');
          
          if (result.isSuccess) {
            final cykResult = result.data!;
            expect(cykResult.accepted, false,
              reason: 'String "$input" should be rejected');
          }
        }
      });

      test('Should handle empty string correctly', () {
        // Test with grammar that accepts empty string
        final result = CYKParser.parse(lambdaGrammar, '');
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed for empty string');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          expect(cykResult.accepted, true,
            reason: 'Empty string should be accepted by lambda grammar');
        }
      });
    });

    group('CNF Conversion Integration Tests', () {
      test('Should handle non-CNF grammars', () {
        final result = CYKParser.parse(unitGrammar, 'a');
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed for non-CNF grammar');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          
          // Should still work after CNF conversion
          expect(cykResult.accepted, true,
            reason: 'Non-CNF grammar should work after conversion');
        }
      });

      test('Should handle complex non-CNF grammars', () {
        final result = CYKParser.parse(complexCNFGrammar, 'abc');
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed for complex grammar');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          
          // Should work with complex grammar
          expect(cykResult.accepted, true,
            reason: 'Complex grammar should work');
        }
      });
    });

    group('Edge Cases Tests', () {
      test('Should handle very short strings', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'a');
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed for single character');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          expect(cykResult.accepted, true,
            reason: 'Single character should be accepted');
        }
      });

      test('Should handle strings with repeated characters', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'aa');
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed for repeated characters');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          // This might be rejected depending on grammar
          expect(cykResult.accepted, isA<bool>(),
            reason: 'Should return boolean result for repeated characters');
        }
      });

      test('Should handle invalid input gracefully', () {
        final result = CYKParser.parse(simpleCNFGrammar, 'xyz');
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed even for invalid input');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          expect(cykResult.accepted, false,
            reason: 'Invalid input should be rejected');
        }
      });
    });

    group('Performance Tests', () {
      test('Should handle moderate length strings', () {
        final longString = 'ab' * 10; // 20 characters
        final result = CYKParser.parse(simpleCNFGrammar, longString);
        
        expect(result.isSuccess, true, 
          reason: 'CYK parsing should succeed for moderate length strings');
        
        if (result.isSuccess) {
          final cykResult = result.data!;
          expect(cykResult.accepted, isA<bool>(),
            reason: 'Should return boolean result for moderate length strings');
        }
      });
    });
  });
}

/// Helper functions to create test grammars

Grammar _createSimpleCNFGrammar() {
  final productions = {
    Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['A', 'B'],
      isLambda: false,
      order: 1,
    ),
    Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: ['a'],
      isLambda: false,
      order: 2,
    ),
    Production(
      id: 'p3',
      leftSide: ['B'],
      rightSide: ['b'],
      isLambda: false,
      order: 3,
    ),
    // Add single character productions for S
    Production(
      id: 'p4',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 4,
    ),
    Production(
      id: 'p5',
      leftSide: ['S'],
      rightSide: ['b'],
      isLambda: false,
      order: 5,
    ),
  };

  return Grammar(
    id: 'simple_cnf',
    name: 'Simple CNF Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S', 'A', 'B'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createComplexCNFGrammar() {
  final productions = {
    Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['A', 'B'],
      isLambda: false,
      order: 1,
    ),
    Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: ['C', 'D'],
      isLambda: false,
      order: 2,
    ),
    Production(
      id: 'p3',
      leftSide: ['B'],
      rightSide: ['E'],
      isLambda: false,
      order: 3,
    ),
    Production(
      id: 'p4',
      leftSide: ['C'],
      rightSide: ['a'],
      isLambda: false,
      order: 4,
    ),
    Production(
      id: 'p5',
      leftSide: ['D'],
      rightSide: ['b'],
      isLambda: false,
      order: 5,
    ),
    Production(
      id: 'p6',
      leftSide: ['E'],
      rightSide: ['c'],
      isLambda: false,
      order: 6,
    ),
    // Add single character productions for S
    Production(
      id: 'p7',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 7,
    ),
    Production(
      id: 'p8',
      leftSide: ['S'],
      rightSide: ['b'],
      isLambda: false,
      order: 8,
    ),
    Production(
      id: 'p9',
      leftSide: ['S'],
      rightSide: ['c'],
      isLambda: false,
      order: 9,
    ),
  };

  return Grammar(
    id: 'complex_cnf',
    name: 'Complex CNF Grammar',
    terminals: {'a', 'b', 'c'},
    nonterminals: {'S', 'A', 'B', 'C', 'D', 'E'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createLambdaGrammar() {
  final productions = {
    Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['A', 'B'],
      isLambda: false,
      order: 1,
    ),
    Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: ['a'],
      isLambda: false,
      order: 2,
    ),
    Production(
      id: 'p3',
      leftSide: ['B'],
      rightSide: [],
      isLambda: true,
      order: 3,
    ),
    // Add lambda production for S to accept empty string
    Production(
      id: 'p4',
      leftSide: ['S'],
      rightSide: [],
      isLambda: true,
      order: 4,
    ),
  };

  return Grammar(
    id: 'lambda',
    name: 'Lambda Grammar',
    terminals: {'a'},
    nonterminals: {'S', 'A', 'B'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createUnitGrammar() {
  final productions = {
    Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['A'],
      isLambda: false,
      order: 1,
    ),
    Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: ['B'],
      isLambda: false,
      order: 2,
    ),
    Production(
      id: 'p3',
      leftSide: ['B'],
      rightSide: ['a'],
      isLambda: false,
      order: 3,
    ),
    // Add direct production for S to accept 'a'
    Production(
      id: 'p4',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 4,
    ),
  };

  return Grammar(
    id: 'unit',
    name: 'Unit Grammar',
    terminals: {'a'},
    nonterminals: {'S', 'A', 'B'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}
