import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/data/services/grammar_service.dart';
import 'package:jflutter/data/services/parsing_service.dart';

/// Integration tests for grammar creation and parsing
/// These tests verify end-to-end grammar functionality
void main() {
  group('Grammar Creation and Parsing Integration Tests', () {
    late GrammarService grammarService;
    late ParsingService parsingService;

    setUp(() {
      grammarService = GrammarService();
      parsingService = ParsingService();
    });

    group('Grammar Creation Workflow', () {
      test('should create regular grammar', () async {
        // Arrange
        final request = CreateGrammarRequest(
          name: 'Test Regular Grammar',
          type: GrammarType.regular,
        );

        // Act
        final result = await grammarService.createGrammar(request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.name, equals('Test Regular Grammar'));
        expect(result.data!.type, equals(GrammarType.regular));
        expect(result.data!.id, isNotEmpty);
        expect(result.data!.terminals, isEmpty);
        expect(result.data!.nonterminals, isEmpty);
        expect(result.data!.productions, isEmpty);
      });

      test('should create context-free grammar', () async {
        // Arrange
        final request = CreateGrammarRequest(
          name: 'Test CFG',
          type: GrammarType.contextFree,
        );

        // Act
        final result = await grammarService.createGrammar(request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(GrammarType.contextFree));
      });

      test('should create unrestricted grammar', () async {
        // Arrange
        final request = CreateGrammarRequest(
          name: 'Test Unrestricted Grammar',
          type: GrammarType.unrestricted,
        );

        // Act
        final result = await grammarService.createGrammar(request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(GrammarType.unrestricted));
      });
    });

    group('Grammar Production Management', () {
      test('should add productions to grammar', () async {
        // Arrange
        final grammar = await createSimpleGrammar();
        final production1 = Production(
          id: 'p1',
          leftSide: ['S'],
          rightSide: ['a', 'A'],
          isLambda: false,
          order: 1,
        );
        final production2 = Production(
          id: 'p2',
          leftSide: ['A'],
          rightSide: ['b'],
          isLambda: false,
          order: 2,
        );

        // Act
        grammar.productions.addAll([production1, production2]);
        grammar.terminals.addAll(['a', 'b']);
        grammar.nonterminals.addAll(['S', 'A']);
        grammar.startSymbol = 'S';
        
        final result = await grammarService.updateGrammar(grammar);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data!.productions, hasLength(2));
        expect(result.data!.terminals, containsAll(['a', 'b']));
        expect(result.data!.nonterminals, containsAll(['S', 'A']));
        expect(result.data!.startSymbol, equals('S'));
      });

      test('should handle lambda productions', () async {
        // Arrange
        final grammar = await createSimpleGrammar();
        final lambdaProduction = Production(
          id: 'p1',
          leftSide: ['S'],
          rightSide: [],
          isLambda: true,
          order: 1,
        );

        // Act
        grammar.productions.add(lambdaProduction);
        grammar.nonterminals.add('S');
        grammar.startSymbol = 'S';
        
        final result = await grammarService.updateGrammar(grammar);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data!.productions, hasLength(1));
        expect(result.data!.productions.first.isLambda, isTrue);
        expect(result.data!.productions.first.rightSide, isEmpty);
      });

      test('should validate grammar consistency', () async {
        // Arrange
        final grammar = await createInconsistentGrammar();

        // Act
        final result = await grammarService.validateGrammar(grammar);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('inconsistent'));
      });
    });

    group('LL Parsing', () {
      test('should parse string with LL(1) grammar', () async {
        // Arrange
        final grammar = await createLL1Grammar();
        final request = ParsingRequest(
          inputString: 'ab',
          parsingType: ParsingType.ll,
          parameters: {'lookahead': 1},
        );

        // Act
        final result = await parsingService.parse(grammar.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
        expect(result.data!.inputString, equals('ab'));
        expect(result.data!.derivation, isNotEmpty);
        expect(result.data!.parseTree, isNotNull);
      });

      test('should reject invalid string with LL(1) grammar', () async {
        // Arrange
        final grammar = await createLL1Grammar();
        final request = ParsingRequest(
          inputString: 'ba',
          parsingType: ParsingType.ll,
          parameters: {'lookahead': 1},
        );

        // Act
        final result = await parsingService.parse(grammar.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isFalse);
        expect(result.data!.errorMessage, isNotEmpty);
      });

      test('should handle LL(2) parsing', () async {
        // Arrange
        final grammar = await createLL2Grammar();
        final request = ParsingRequest(
          inputString: 'aabb',
          parsingType: ParsingType.ll,
          parameters: {'lookahead': 2},
        );

        // Act
        final result = await parsingService.parse(grammar.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
      });

      test('should detect LL conflicts', () async {
        // Arrange
        final grammar = await createAmbiguousGrammar();
        final request = ParsingRequest(
          inputString: 'ab',
          parsingType: ParsingType.ll,
          parameters: {'lookahead': 1},
        );

        // Act
        final result = await parsingService.parse(grammar.id, request);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('LL conflict'));
      });
    });

    group('LR Parsing', () {
      test('should parse string with LR(1) grammar', () async {
        // Arrange
        final grammar = await createLR1Grammar();
        final request = ParsingRequest(
          inputString: 'ab',
          parsingType: ParsingType.lr,
          parameters: {'lookahead': 1},
        );

        // Act
        final result = await parsingService.parse(grammar.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
        expect(result.data!.derivation, isNotEmpty);
        expect(result.data!.parseTable, isNotNull);
      });

      test('should handle SLR parsing', () async {
        // Arrange
        final grammar = await createSLRGrammar();
        final request = ParsingRequest(
          inputString: 'aabb',
          parsingType: ParsingType.slr,
          parameters: {},
        );

        // Act
        final result = await parsingService.parse(grammar.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
      });

      test('should handle LALR parsing', () async {
        // Arrange
        final grammar = await createLALRGrammar();
        final request = ParsingRequest(
          inputString: 'aabb',
          parsingType: ParsingType.lalr,
          parameters: {},
        );

        // Act
        final result = await parsingService.parse(grammar.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
      });

      test('should detect LR conflicts', () async {
        // Arrange
        final grammar = await createAmbiguousGrammar();
        final request = ParsingRequest(
          inputString: 'ab',
          parsingType: ParsingType.lr,
          parameters: {'lookahead': 1},
        );

        // Act
        final result = await parsingService.parse(grammar.id, request);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('LR conflict'));
      });
    });

    group('CYK Parsing', () {
      test('should parse string with CYK algorithm', () async {
        // Arrange
        final grammar = await createCNFGrammar();
        final request = ParsingRequest(
          inputString: 'ab',
          parsingType: ParsingType.cyk,
          parameters: {},
        );

        // Act
        final result = await parsingService.parse(grammar.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
        expect(result.data!.cykTable, isNotNull);
      });

      test('should handle long strings with CYK', () async {
        // Arrange
        final grammar = await createCNFGrammar();
        final request = ParsingRequest(
          inputString: 'a' * 10 + 'b' * 10,
          parsingType: ParsingType.cyk,
          parameters: {},
        );

        // Act
        final result = await parsingService.parse(grammar.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
      });
    });

    group('Brute Force Parsing', () {
      test('should parse string with brute force for unrestricted grammar', () async {
        // Arrange
        final grammar = await createUnrestrictedGrammar();
        final request = ParsingRequest(
          inputString: 'ab',
          parsingType: ParsingType.bruteForce,
          parameters: {'maxSteps': 1000},
        );

        // Act
        final result = await parsingService.parse(grammar.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
      });

      test('should handle timeout for complex unrestricted grammar', () async {
        // Arrange
        final grammar = await createComplexUnrestrictedGrammar();
        final request = ParsingRequest(
          inputString: 'complex',
          parsingType: ParsingType.bruteForce,
          parameters: {'maxSteps': 100},
        );

        // Act
        final result = await parsingService.parse(grammar.id, request);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('timeout'));
      });
    });

    group('Parse Table Generation', () {
      test('should generate LL parse table', () async {
        // Arrange
        final grammar = await createLL1Grammar();

        // Act
        final result = await parsingService.generateParseTable(grammar.id, ParsingType.ll);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.actionTable, isNotEmpty);
        expect(result.data!.type, equals(ParsingType.ll));
      });

      test('should generate LR parse table', () async {
        // Arrange
        final grammar = await createLR1Grammar();

        // Act
        final result = await parsingService.generateParseTable(grammar.id, ParsingType.lr);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.actionTable, isNotEmpty);
        expect(result.data!.gotoTable, isNotEmpty);
        expect(result.data!.type, equals(ParsingType.lr));
      });

      test('should detect conflicts in parse table', () async {
        // Arrange
        final grammar = await createAmbiguousGrammar();

        // Act
        final result = await parsingService.generateParseTable(grammar.id, ParsingType.lr);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('conflict'));
      });
    });

    group('Grammar Transformations', () {
      test('should convert grammar to CNF', () async {
        // Arrange
        final grammar = await createNonCNFGrammar();

        // Act
        final result = await parsingService.transformToCNF(grammar.id);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        
        final cnfGrammar = result.data!;
        for (final production in cnfGrammar.productions) {
          expect(production.leftSide, hasLength(1));
          expect(production.rightSide.length <= 2, isTrue);
        }
      });

      test('should remove left recursion', () async {
        // Arrange
        final grammar = await createLeftRecursiveGrammar();

        // Act
        final result = await parsingService.removeLeftRecursion(grammar.id);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        
        final transformedGrammar = result.data!;
        for (final production in transformedGrammar.productions) {
          expect(production.leftSide.first != production.rightSide.first, isTrue);
        }
      });

      test('should left factor grammar', () async {
        // Arrange
        final grammar = await createLeftFactoredGrammar();

        // Act
        final result = await parsingService.leftFactor(grammar.id);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        
        // Verify left factoring was applied
        final transformedGrammar = result.data!;
        expect(transformedGrammar.productions.length, greaterThan(grammar.productions.length));
      });
    });

    group('Performance Tests', () {
      test('should parse long strings within time limit', () async {
        // Arrange
        final grammar = await createCNFGrammar();
        final request = ParsingRequest(
          inputString: 'a' * 50 + 'b' * 50,
          parsingType: ParsingType.cyk,
          parameters: {},
        );

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await parsingService.parse(grammar.id, request);
        stopwatch.stop();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 second limit
      });

      test('should handle large grammars efficiently', () async {
        // Arrange
        final grammar = await createLargeGrammar();

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await parsingService.generateParseTable(grammar.id, ParsingType.lr);
        stopwatch.stop();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 second limit
      });
    });
  });

  // Helper methods for creating test grammars
  Future<Grammar> createSimpleGrammar() async {
    final request = CreateGrammarRequest(
      name: 'Simple Grammar',
      type: GrammarType.contextFree,
    );
    final result = await GrammarService().createGrammar(request);
    return result.data!;
  }

  Future<Grammar> createInconsistentGrammar() async {
    final grammar = await createSimpleGrammar();
    // Add inconsistent productions
    grammar.productions.add(Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a', 'B'], // B is not defined
      isLambda: false,
      order: 1,
    ));
    return grammar;
  }

  Future<Grammar> createLL1Grammar() async {
    throw UnimplementedError('LL(1) grammar creation not implemented yet');
  }

  Future<Grammar> createLL2Grammar() async {
    throw UnimplementedError('LL(2) grammar creation not implemented yet');
  }

  Future<Grammar> createAmbiguousGrammar() async {
    throw UnimplementedError('Ambiguous grammar creation not implemented yet');
  }

  Future<Grammar> createLR1Grammar() async {
    throw UnimplementedError('LR(1) grammar creation not implemented yet');
  }

  Future<Grammar> createSLRGrammar() async {
    throw UnimplementedError('SLR grammar creation not implemented yet');
  }

  Future<Grammar> createLALRGrammar() async {
    throw UnimplementedError('LALR grammar creation not implemented yet');
  }

  Future<Grammar> createCNFGrammar() async {
    throw UnimplementedError('CNF grammar creation not implemented yet');
  }

  Future<Grammar> createUnrestrictedGrammar() async {
    throw UnimplementedError('Unrestricted grammar creation not implemented yet');
  }

  Future<Grammar> createComplexUnrestrictedGrammar() async {
    throw UnimplementedError('Complex unrestricted grammar creation not implemented yet');
  }

  Future<Grammar> createNonCNFGrammar() async {
    throw UnimplementedError('Non-CNF grammar creation not implemented yet');
  }

  Future<Grammar> createLeftRecursiveGrammar() async {
    throw UnimplementedError('Left recursive grammar creation not implemented yet');
  }

  Future<Grammar> createLeftFactoredGrammar() async {
    throw UnimplementedError('Left factored grammar creation not implemented yet');
  }

  Future<Grammar> createLargeGrammar() async {
    throw UnimplementedError('Large grammar creation not implemented yet');
  }
}
