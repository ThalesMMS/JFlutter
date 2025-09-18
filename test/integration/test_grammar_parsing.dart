import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/core/algorithms/grammar_parser.dart';

void main() {
  group('Grammar Creation and Parsing Integration Tests', () {
    late GrammarParser parser;
    
    setUp(() {
      parser = GrammarParser();
    });
    
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
    
    test('should parse valid string with CYK algorithm', () async {
      // Arrange - Grammar for balanced parentheses: S -> (S)S | ε
      final grammar = Grammar(
        id: 'balanced-parens',
        name: 'Balanced Parentheses',
        terminals: {'(', ')'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['(', 'S', ')', 'S'],
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
      final parseResult = parser.parseWithCYK(grammar, '()');
      
      // Assert
      expect(parseResult.isSuccess, isTrue);
      expect(parseResult.data!.accepted, isTrue);
      expect(parseResult.data!.inputString, equals('()'));
    });
    
    test('should reject invalid string with CYK algorithm', () async {
      // Arrange - Same grammar as above
      final grammar = Grammar(
        id: 'balanced-parens',
        name: 'Balanced Parentheses',
        terminals: {'(', ')'},
        nonterminals: {'S'},
        startSymbol: 'S',
        productions: {
          Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['(', 'S', ')', 'S'],
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
      final parseResult = parser.parseWithCYK(grammar, '(()');
      
      // Assert
      expect(parseResult.isSuccess, isTrue);
      expect(parseResult.data!.accepted, isFalse);
      expect(parseResult.data!.inputString, equals('(()'));
    });
    
    test('should generate parse table for LL grammar', () async {
      // Arrange - Simple LL grammar: S -> aS | b
      final grammar = Grammar(
        id: 'll-grammar',
        name: 'LL Grammar',
        terminals: {'a', 'b'},
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
            rightSide: ['b'],
            order: 2,
          ),
        },
        type: GrammarType.contextFree,
        created: DateTime.now(),
        modified: DateTime.now(),
      );
      
      // Act
      final tableResult = parser.generateLLParseTable(grammar);
      
      // Assert
      expect(tableResult.isSuccess, isTrue);
      final parseTable = tableResult.data!;
      expect(parseTable.grammar, equals(grammar));
      expect(parseTable.type, equals(ParseType.ll));
      expect(parseTable.actionTable.isNotEmpty, isTrue);
    });
    
    test('should generate parse table for LR grammar', () async {
      // Arrange - Simple LR grammar: S -> aSb | ab
      final grammar = Grammar(
        id: 'lr-grammar',
        name: 'LR Grammar',
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
            rightSide: ['a', 'b'],
            order: 2,
          ),
        },
        type: GrammarType.contextFree,
        created: DateTime.now(),
        modified: DateTime.now(),
      );
      
      // Act
      final tableResult = parser.generateLRParseTable(grammar);
      
      // Assert
      expect(tableResult.isSuccess, isTrue);
      final parseTable = tableResult.data!;
      expect(parseTable.grammar, equals(grammar));
      expect(parseTable.type, equals(ParseType.lr));
      expect(parseTable.actionTable.isNotEmpty, isTrue);
      expect(parseTable.gotoTable.isNotEmpty, isTrue);
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
      final parseResult = parser.parseWithCYK(grammar, '');
      
      // Assert
      expect(parseResult.isSuccess, isTrue);
      expect(parseResult.data!.accepted, isTrue);
      expect(parseResult.data!.inputString, equals(''));
    });
    
    test('should handle complex grammar with multiple nonterminals', () async {
      // Arrange - Grammar: S -> aA, A -> bA | b
      final grammar = Grammar(
        id: 'complex-grammar',
        name: 'Complex Grammar',
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
            rightSide: ['b'],
            order: 3,
          ),
        },
        type: GrammarType.contextFree,
        created: DateTime.now(),
        modified: DateTime.now(),
      );
      
      // Act
      final parseResult = parser.parseWithCYK(grammar, 'abb');
      
      // Assert
      expect(parseResult.isSuccess, isTrue);
      expect(parseResult.data!.accepted, isTrue);
      expect(parseResult.data!.inputString, equals('abb'));
    });
  });
}
