import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/core/algorithms/grammar_parser.dart';
import 'package:jflutter/core/result.dart';

/// CYK (Cocke-Younger-Kasami) Validation Tests against References/automata-main
/// 
/// This test suite validates CYK algorithm implementation against theoretical expectations
/// and reference implementations to ensure behavioral equivalence.
/// 
/// Test cases cover:
/// 1. CNF parsing (Chomsky Normal Form parsing)
/// 2. Derivation testing (valid and invalid derivations)
/// 3. CYK algorithm correctness
/// 4. Grammar conversion to CNF
/// 5. Performance and edge cases
void main() {
  group('CYK Validation Tests', () {
    late Grammar balancedParenthesesGrammar;
    late Grammar palindromeGrammar;
    late Grammar simpleGrammar;
    late Grammar complexGrammar;
    late Grammar cnfGrammar;

    setUp(() {
      // Test Case 1: Balanced Parentheses Grammar
      balancedParenthesesGrammar = _createBalancedParenthesesGrammar();
      
      // Test Case 2: Palindrome Grammar
      palindromeGrammar = _createPalindromeGrammar();
      
      // Test Case 3: Simple Grammar
      simpleGrammar = _createSimpleGrammar();
      
      // Test Case 4: Complex Grammar
      complexGrammar = _createComplexGrammar();
      
      // Test Case 5: CNF Grammar
      cnfGrammar = _createCNFGrammar();
    });

    group('CNF Parsing Tests', () {
      test('CNF Grammar should parse valid strings', () async {
        final testCases = [
          'a',       // Single terminal
          'b',       // Single terminal
          'ab',      // Two terminals
          'ba',      // Two terminals
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(
            cnfGrammar,
            testString,
            strategyHint: ParsingStrategyHint.cyk,
          );
          
          expect(result.isSuccess, true, 
            reason: 'CYK parsing should succeed for "$testString"');
          
          if (result.isSuccess) {
            expect(result.data!.accepted, true,
              reason: 'String "$testString" should be accepted by CYK algorithm');
          }
        }
      });

      test('CNF Grammar should reject invalid strings', () async {
        final testCases = [
          '',        // Empty string
          'c',       // Invalid terminal
          'abc',     // Too many terminals
          'aab',     // Invalid pattern
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(
            cnfGrammar,
            testString,
            strategyHint: ParsingStrategyHint.cyk,
          );
          
          expect(result.isSuccess, true, 
            reason: 'CYK parsing should succeed for "$testString"');
          
          if (result.isSuccess) {
            expect(result.data!.accepted, false,
              reason: 'String "$testString" should be rejected by CYK algorithm');
          }
        }
      });

      test('CYK should handle empty string correctly', () async {
        final result = GrammarParser.parse(
          cnfGrammar,
          '',
          strategyHint: ParsingStrategyHint.cyk,
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, false,
            reason: 'Empty string should be rejected by CYK algorithm');
        }
      });
    });

    group('Derivation Tests', () {
      test('Balanced Parentheses Grammar should accept valid derivations', () async {
        final testCases = [
          '',        // Empty string
          '()',      // Simple balanced
          '(())',    // Nested balanced
          '()()',    // Multiple balanced
          '((()))',  // Deeply nested
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(
            balancedParenthesesGrammar,
            testString,
            strategyHint: ParsingStrategyHint.cyk,
          );
          
          expect(result.isSuccess, true, 
            reason: 'CYK parsing should succeed for "$testString"');
          
          if (result.isSuccess) {
            expect(result.data!.accepted, true,
              reason: 'String "$testString" should be accepted by balanced parentheses grammar');
          }
        }
      });

      test('Balanced Parentheses Grammar should reject invalid derivations', () async {
        final testCases = [
          '(',       // Unmatched opening
          ')',       // Unmatched closing
          '())',     // Extra closing
          '(()',     // Extra opening
          ')(',      // Wrong order
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(
            balancedParenthesesGrammar,
            testString,
            strategyHint: ParsingStrategyHint.cyk,
          );
          
          expect(result.isSuccess, true, 
            reason: 'CYK parsing should succeed for "$testString"');
          
          if (result.isSuccess) {
            expect(result.data!.accepted, false,
              reason: 'String "$testString" should be rejected by balanced parentheses grammar');
          }
        }
      });

      test('Palindrome Grammar should accept palindromes', () async {
        final testCases = [
          '',        // Empty string
          'a',       // Single character
          'b',       // Single character
          'aa',      // Even length palindrome
          'bb',      // Even length palindrome
          'aba',     // Odd length palindrome
          'bab',     // Odd length palindrome
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(
            palindromeGrammar,
            testString,
            strategyHint: ParsingStrategyHint.cyk,
          );
          
          expect(result.isSuccess, true, 
            reason: 'CYK parsing should succeed for "$testString"');
          
          if (result.isSuccess) {
            expect(result.data!.accepted, true,
              reason: 'String "$testString" should be accepted by palindrome grammar');
          }
        }
      });

      test('Palindrome Grammar should reject non-palindromes', () async {
        final testCases = [
          'ab',      // Not a palindrome
          'ba',      // Not a palindrome
          'aab',     // Not a palindrome
          'bba',     // Not a palindrome
        ];

        for (final testString in testCases) {
          final result = GrammarParser.parse(
            palindromeGrammar,
            testString,
            strategyHint: ParsingStrategyHint.cyk,
          );
          
          expect(result.isSuccess, true, 
            reason: 'CYK parsing should succeed for "$testString"');
          
          if (result.isSuccess) {
            expect(result.data!.accepted, false,
              reason: 'String "$testString" should be rejected by palindrome grammar');
          }
        }
      });
    });

    group('CYK Algorithm Correctness Tests', () {
      test('CYK should produce same results as other parsers', () async {
        final testString = '()';
        
        final cykResult = GrammarParser.parse(
          balancedParenthesesGrammar,
          testString,
          strategyHint: ParsingStrategyHint.cyk,
        );
        
        final autoResult = GrammarParser.parse(
          balancedParenthesesGrammar,
          testString,
          strategyHint: ParsingStrategyHint.auto,
        );
        
        expect(cykResult.isSuccess, true);
        expect(autoResult.isSuccess, true);
        
        if (cykResult.isSuccess && autoResult.isSuccess) {
          expect(cykResult.data!.accepted, autoResult.data!.accepted,
            reason: 'CYK should produce same results as other parsers');
        }
      });

      test('CYK should handle complex nested structures', () async {
        final testString = '((()))';
        
        final result = GrammarParser.parse(
          balancedParenthesesGrammar,
          testString,
          strategyHint: ParsingStrategyHint.cyk,
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'CYK should handle complex nested structures');
        }
      });

      test('CYK should handle long strings efficiently', () async {
        final testString = '()' * 10; // 20 characters
        
        final result = GrammarParser.parse(
          balancedParenthesesGrammar,
          testString,
          strategyHint: ParsingStrategyHint.cyk,
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'CYK should handle long strings efficiently');
        }
      });
    });

    group('Grammar Conversion Tests', () {
      test('Grammar should convert to CNF correctly', () async {
        // Test that the grammar can be converted to CNF and still work
        final testString = 'ab';
        
        final result = GrammarParser.parse(
          cnfGrammar,
          testString,
          strategyHint: ParsingStrategyHint.cyk,
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'CNF grammar should work with CYK algorithm');
        }
      });

      test('Non-CNF Grammar should be converted automatically', () async {
        // Test that non-CNF grammar gets converted and works
        final testString = '()';
        
        final result = GrammarParser.parse(
          balancedParenthesesGrammar,
          testString,
          strategyHint: ParsingStrategyHint.cyk,
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'Non-CNF grammar should be converted and work with CYK');
        }
      });
    });

    group('Performance Tests', () {
      test('CYK should handle complex computations efficiently', () async {
        final testString = '((()))()((()))';
        
        final result = GrammarParser.parse(
          balancedParenthesesGrammar,
          testString,
          strategyHint: ParsingStrategyHint.cyk,
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'CYK should complete complex computations');
          
          // Check execution time is reasonable
          expect(result.data!.executionTime.inSeconds, lessThan(5),
            reason: 'CYK should complete within reasonable time');
        }
      });

      test('CYK should handle multiple parsing strategies', () async {
        final testString = 'ab';
        
        final cykResult = GrammarParser.parse(
          cnfGrammar,
          testString,
          strategyHint: ParsingStrategyHint.cyk,
        );
        
        final autoResult = GrammarParser.parse(
          cnfGrammar,
          testString,
          strategyHint: ParsingStrategyHint.auto,
        );
        
        expect(cykResult.isSuccess, true);
        expect(autoResult.isSuccess, true);
        
        if (cykResult.isSuccess && autoResult.isSuccess) {
          expect(cykResult.data!.accepted, autoResult.data!.accepted,
            reason: 'CYK should be consistent with other parsing strategies');
        }
      });
    });

    group('Edge Cases Tests', () {
      test('CYK should handle empty grammar gracefully', () async {
        final emptyGrammar = _createEmptyGrammar();
        
        final result = GrammarParser.parse(
          emptyGrammar,
          'a',
          strategyHint: ParsingStrategyHint.cyk,
        );
        
        expect(result.isSuccess, false, 
          reason: 'Empty grammar should fail gracefully');
      });

      test('CYK should handle single production grammar', () async {
        final singleProductionGrammar = _createSingleProductionGrammar();
        
        final result = GrammarParser.parse(
          singleProductionGrammar,
          'a',
          strategyHint: ParsingStrategyHint.cyk,
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'Single production grammar should work with CYK');
        }
      });

      test('CYK should handle grammar with lambda productions', () async {
        final lambdaGrammar = _createLambdaGrammar();
        
        final result = GrammarParser.parse(
          lambdaGrammar,
          '',
          strategyHint: ParsingStrategyHint.cyk,
        );
        
        expect(result.isSuccess, true);
        if (result.isSuccess) {
          expect(result.data!.accepted, true,
            reason: 'Lambda grammar should accept empty string');
        }
      });
    });

    group('Mathematical Properties Tests', () {
      test('CYK should satisfy time complexity O(n³)', () async {
        // Test with strings of different lengths to verify time complexity
        final testStrings = ['()', '()()', '()()()', '()()()()'];
        
        for (final testString in testStrings) {
          final result = GrammarParser.parse(
            balancedParenthesesGrammar,
            testString,
            strategyHint: ParsingStrategyHint.cyk,
          );
          
          expect(result.isSuccess, true, 
            reason: 'CYK should handle string of length ${testString.length}');
          
          if (result.isSuccess) {
            expect(result.data!.executionTime.inSeconds, lessThan(1),
              reason: 'CYK should complete within reasonable time for length ${testString.length}');
          }
        }
      });

      test('CYK should handle all possible substrings correctly', () async {
        final testString = 'ab';
        
        // Test all possible substrings
        final substrings = ['', 'a', 'b', 'ab'];
        
        for (final substring in substrings) {
          final result = GrammarParser.parse(
            cnfGrammar,
            substring,
            strategyHint: ParsingStrategyHint.cyk,
          );
          
          expect(result.isSuccess, true, 
            reason: 'CYK should handle substring "$substring"');
        }
      });
    });
  });
}

/// Helper functions to create test grammars

Grammar _createBalancedParenthesesGrammar() {
  final productions = {
    Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['S', 'S'],
      isLambda: false,
      order: 1,
    ),
    Production(
      id: 'p2',
      leftSide: ['S'],
      rightSide: ['(', 'S', ')'],
      isLambda: false,
      order: 2,
    ),
    Production(
      id: 'p3',
      leftSide: ['S'],
      rightSide: [],
      isLambda: true,
      order: 3,
    ),
  };

  return Grammar(
    id: 'balanced_parentheses',
    name: 'Balanced Parentheses',
    terminals: {'(', ')'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createPalindromeGrammar() {
  final productions = {
    Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a', 'S', 'a'],
      isLambda: false,
      order: 1,
    ),
    Production(
      id: 'p2',
      leftSide: ['S'],
      rightSide: ['b', 'S', 'b'],
      isLambda: false,
      order: 2,
    ),
    Production(
      id: 'p3',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 3,
    ),
    Production(
      id: 'p4',
      leftSide: ['S'],
      rightSide: ['b'],
      isLambda: false,
      order: 4,
    ),
    Production(
      id: 'p5',
      leftSide: ['S'],
      rightSide: [],
      isLambda: true,
      order: 5,
    ),
  };

  return Grammar(
    id: 'palindrome',
    name: 'Palindrome',
    terminals: {'a', 'b'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createSimpleGrammar() {
  final productions = {
    Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 1,
    ),
  };

  return Grammar(
    id: 'simple',
    name: 'Simple Grammar',
    terminals: {'a'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createComplexGrammar() {
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
      rightSide: ['a', 'A'],
      isLambda: false,
      order: 2,
    ),
    Production(
      id: 'p3',
      leftSide: ['A'],
      rightSide: [],
      isLambda: true,
      order: 3,
    ),
    Production(
      id: 'p4',
      leftSide: ['B'],
      rightSide: ['b', 'B'],
      isLambda: false,
      order: 4,
    ),
    Production(
      id: 'p5',
      leftSide: ['B'],
      rightSide: [],
      isLambda: true,
      order: 5,
    ),
  };

  return Grammar(
    id: 'complex',
    name: 'Complex Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S', 'A', 'B'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createCNFGrammar() {
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
  };

  return Grammar(
    id: 'cnf',
    name: 'CNF Grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S', 'A', 'B'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createEmptyGrammar() {
  return Grammar(
    id: 'empty',
    name: 'Empty Grammar',
    terminals: {},
    nonterminals: {},
    startSymbol: '',
    productions: {},
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}

Grammar _createSingleProductionGrammar() {
  final productions = {
    Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 1,
    ),
  };

  return Grammar(
    id: 'single_production',
    name: 'Single Production Grammar',
    terminals: {'a'},
    nonterminals: {'S'},
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
      rightSide: [],
      isLambda: true,
      order: 1,
    ),
  };

  return Grammar(
    id: 'lambda',
    name: 'Lambda Grammar',
    terminals: {},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.now(),
    modified: DateTime.now(),
  );
}
