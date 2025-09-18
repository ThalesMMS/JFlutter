import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/core/algorithms/grammar_parser.dart';

void main() {
  group('Simple Grammar Tests', () {
    test('should create context-free grammar with productions', () async {
      // Arrange
      final grammar = Grammar(
        id: 'test-grammar-1',
        name: 'Test Grammar',
        terminals: {'a', 'b'},
        nonterminals: {'S', 'A'},
        startSymbol: 'S',
        productions: {
          Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['a', 'A'],
            order: 1,
          ),
          Production(
            id: 'p2',
            leftSide: ['A'],
            rightSide: ['b', 'A'],
            order: 2,
          ),
          Production(
            id: 'p3',
            leftSide: ['A'],
            rightSide: [],
            isLambda: true,
            order: 3,
          ),
        },
        type: GrammarType.contextFree,
        created: DateTime.now(),
        modified: DateTime.now(),
      );
      
      // Act & Assert
      expect(grammar.id, equals('test-grammar-1'));
      expect(grammar.name, equals('Test Grammar'));
      expect(grammar.terminals, equals({'a', 'b'}));
      expect(grammar.nonterminals, equals({'S', 'A'}));
      expect(grammar.startSymbol, equals('S'));
      expect(grammar.productions.length, equals(3));
      expect(grammar.type, equals(GrammarType.contextFree));
    });
    
    test('should validate grammar properties', () async {
      // Arrange
      final grammar = Grammar(
        id: 'valid-grammar',
        name: 'Valid Grammar',
        terminals: {'a', 'b'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['a', 'S', 'b'],
            order: 1,
          ),
          Production(
            id: 'p2',
            leftSide: ['S'],
            rightSide: [],
            isLambda: true,
            order: 2,
          ),
        },
        type: GrammarType.contextFree,
        created: DateTime.now(),
        modified: DateTime.now(),
      );
      
      // Act
      final validationErrors = grammar.validate();
      
      // Assert
      expect(validationErrors.isEmpty, isTrue);
      expect(grammar.isValid, isTrue);
    });
    
    test('should detect invalid grammar with undefined symbols', () async {
      // Arrange
      final grammar = Grammar(
        id: 'invalid-grammar',
        name: 'Invalid Grammar',
        terminals: {'a'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['a', 'X'], // X is not defined
            order: 1,
          ),
        },
        type: GrammarType.contextFree,
        created: DateTime.now(),
        modified: DateTime.now(),
      );
      
      // Act
      final validationErrors = grammar.validate();
      
      // Assert
      expect(validationErrors.isNotEmpty, isTrue);
      expect(validationErrors.any((error) => error.contains('undefined')), isTrue);
      expect(grammar.isValid, isFalse);
    });
    
    test('should handle grammar with lambda productions', () async {
      // Arrange - Grammar with lambda: S -> aS | ε
      final grammar = Grammar(
        id: 'lambda-grammar',
        name: 'Lambda Grammar',
        terminals: {'a'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['a', 'S'],
            order: 1,
          ),
          Production(
            id: 'p2',
            leftSide: ['S'],
            rightSide: [],
            isLambda: true,
            order: 2,
          ),
        },
        type: GrammarType.contextFree,
        created: DateTime.now(),
        modified: DateTime.now(),
      );
      
      // Act
      final validationErrors = grammar.validate();
      
      // Assert
      expect(validationErrors.isEmpty, isTrue);
      expect(grammar.isValid, isTrue);
      expect(grammar.productions.length, equals(2));
    });
  });
}
