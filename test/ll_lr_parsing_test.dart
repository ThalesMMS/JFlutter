import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/cfg.dart';
import 'package:jflutter/core/ll_parsing.dart';
import 'package:jflutter/core/lr_parsing.dart';

void main() {
  group('LL Parsing Tests', () {
    test('Calculate FIRST sets for simple grammar', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final firstSets = LLParsing.calculateFirstSets(grammar);
      
      expect(firstSets['S'], contains('a'));
      expect(firstSets['S'], contains('λ'));
      expect(firstSets['a'], contains('a'));
    });

    test('Calculate FOLLOW sets for simple grammar', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final followSets = LLParsing.calculateFollowSets(grammar);
      
      expect(followSets['S'], contains('\$'));
      expect(followSets['S'], contains('b'));
    });

    test('Generate LL(1) parse table for simple grammar', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final table = LLParsing.generateParseTable(grammar);
      
      expect(table.getEntries('S', 'a'), contains('aSb'));
      expect(table.getEntries('S', 'b'), contains('λ'));
      expect(table.getEntries('S', '\$'), contains('λ'));
      expect(table.hasConflicts(), isFalse);
    });

    test('Check if grammar is LL(1)', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      expect(LLParsing.isLL1(grammar), isTrue);
    });

    test('Parse string with LL(1) parser', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final result = LLParsing.parseString(grammar, 'aabb');
      
      expect(result.accepted, isTrue);
      expect(result.derivation.length, greaterThan(0));
    });

    test('Parse empty string with LL(1) parser', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final result = LLParsing.parseString(grammar, '');
      
      expect(result.accepted, isTrue);
    });

    test('Reject invalid string with LL(1) parser', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final result = LLParsing.parseString(grammar, 'ba');
      
      expect(result.accepted, isFalse);
    });

    test('Handle non-LL(1) grammar', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aS | a
      ''');
      
      final table = LLParsing.generateParseTable(grammar);
      
      expect(table.hasConflicts(), isTrue);
      expect(LLParsing.isLL1(grammar), isFalse);
    });
  });

  group('LR Parsing Tests', () {
    test('Create augmented grammar', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final augmented = LRParsing.createAugmentedGrammar(grammar);
      
      expect(augmented.startVariable, equals('SPrime'));
      expect(augmented.productions.length, equals(grammar.productions.length + 1));
      expect(augmented.productions.first.leftHandSide, equals('SPrime'));
    });

    test('Calculate closure of LR items', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final augmented = LRParsing.createAugmentedGrammar(grammar);
      final initialItem = LRItem(
        lhs: 'SPrime',
        rhs: 'S',
        dotPosition: 0,
        lookahead: '\$',
      );
      
      final closure = LRParsing.closure({initialItem}, augmented);
      
      expect(closure.length, greaterThan(1));
      expect(closure.any((item) => item.lhs == 'S' && item.dotPosition == 0), isTrue);
    });

    test('Calculate goto for LR items', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final augmented = LRParsing.createAugmentedGrammar(grammar);
      final initialItem = LRItem(
        lhs: 'SPrime',
        rhs: 'S',
        dotPosition: 0,
        lookahead: '\$',
      );
      
      final closure = LRParsing.closure({initialItem}, augmented);
      final goto = LRParsing.goto(closure, 'S', augmented);
      
      expect(goto.isNotEmpty, isTrue);
    });

    test('Build LR(1) automaton', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final states = LRParsing.buildLRAutomaton(grammar);
      
      expect(states.length, greaterThan(0));
      expect(states.containsKey(0), isTrue);
    });

    test('Generate LR(1) parse table', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final table = LRParsing.generateParseTable(grammar);
      
      expect(table.states.length, greaterThan(0));
      expect(table.productions.length, greaterThan(0));
    });

    test('Parse string with LR(1) parser', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final result = LRParsing.parseString(grammar, 'aabb');
      
      expect(result.accepted, isTrue);
      expect(result.derivation.length, greaterThan(0));
    });

    test('Parse empty string with LR(1) parser', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final result = LRParsing.parseString(grammar, '');
      
      expect(result.accepted, isTrue);
    });

    test('Reject invalid string with LR(1) parser', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → aSb | λ
      ''');
      
      final result = LRParsing.parseString(grammar, 'ba');
      
      expect(result.accepted, isFalse);
    });
  });

  group('Complex Grammar Tests', () {
    test('LL(1) parsing for arithmetic expressions', () {
      final grammar = ContextFreeGrammar.fromString('''
        E → TE'
        E' → +TE' | λ
        T → FT'
        T' → *FT' | λ
        F → (E) | id
      ''');
      
      expect(LLParsing.isLL1(grammar), isTrue);
      
      final result = LLParsing.parseString(grammar, 'id+id*id');
      expect(result.accepted, isTrue);
    });

    test('LR(1) parsing for arithmetic expressions', () {
      final grammar = ContextFreeGrammar.fromString('''
        E → E+T | T
        T → T*F | F
        F → (E) | id
      ''');
      
      final result = LRParsing.parseString(grammar, 'id+id*id');
      expect(result.accepted, isTrue);
    });

    test('LL(1) parsing for balanced parentheses', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → (S)S | λ
      ''');
      
      expect(LLParsing.isLL1(grammar), isTrue);
      
      final result = LLParsing.parseString(grammar, '(()())');
      expect(result.accepted, isTrue);
    });

    test('LR(1) parsing for balanced parentheses', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → (S)S | λ
      ''');
      
      final result = LRParsing.parseString(grammar, '(()())');
      expect(result.accepted, isTrue);
    });
  });

  group('Edge Cases', () {
    test('LL(1) parsing with lambda productions', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → A
        A → aA | λ
      ''');
      
      expect(LLParsing.isLL1(grammar), isTrue);
      
      final result = LLParsing.parseString(grammar, 'aaa');
      expect(result.accepted, isTrue);
    });

    test('LR(1) parsing with lambda productions', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → A
        A → aA | λ
      ''');
      
      final result = LRParsing.parseString(grammar, 'aaa');
      expect(result.accepted, isTrue);
    });

    test('LL(1) parsing with unit productions', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → A
        A → B
        B → a
      ''');
      
      expect(LLParsing.isLL1(grammar), isTrue);
      
      final result = LLParsing.parseString(grammar, 'a');
      expect(result.accepted, isTrue);
    });

    test('LR(1) parsing with unit productions', () {
      final grammar = ContextFreeGrammar.fromString('''
        S → A
        A → B
        B → a
      ''');
      
      final result = LRParsing.parseString(grammar, 'a');
      expect(result.accepted, isTrue);
    });
  });
}
