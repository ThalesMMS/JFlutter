import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/automaton.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/data/services/conversion_service.dart';

/// Contract tests for conversion algorithms
/// These tests MUST fail before implementation and MUST pass after implementation
void main() {
  group('Conversion Service Contract Tests', () {
    late AutomatonService automatonService;
    late ConversionService conversionService;

    setUp(() {
      automatonService = AutomatonService();
      conversionService = ConversionService();
    });

    group('NFA to DFA Conversion', () {
      test('should convert simple NFA to DFA', () async {
        // Arrange
        final nfa = await createSimpleNFA();
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(nfa.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(AutomatonType.fsa));
        
        // Verify DFA properties
        final dfa = result.data!;
        expect(dfa.states, isNotEmpty);
        expect(dfa.transitions, isNotEmpty);
        
        // Verify determinism
        for (final state in dfa.states) {
          final outgoingTransitions = dfa.transitions
              .where((t) => t.fromState.id == state.id);
          final inputSymbols = outgoingTransitions
              .map((t) => (t as FSATransition).inputSymbols)
              .expand((symbols) => symbols);
          expect(inputSymbols.toSet().length, equals(inputSymbols.length));
        }
      });

      test('should handle NFA with lambda transitions', () async {
        // Arrange
        final nfa = await createNFAWithLambda();
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(nfa.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        
        // Verify no lambda transitions in result
        final dfa = result.data!;
        for (final transition in dfa.transitions) {
          final fsaTransition = transition as FSATransition;
          expect(fsaTransition.lambdaSymbol, isNull);
        }
      });

      test('should preserve language acceptance', () async {
        // Arrange
        final nfa = await createNFA();
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(nfa.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        
        // Test that both automata accept/reject the same strings
        final testStrings = ['a', 'ab', 'aa', 'b', 'ba', ''];
        for (final testString in testStrings) {
          final nfaResult = await conversionService.simulateString(nfa.id, testString);
          final dfaResult = await conversionService.simulateString(result.data!.id, testString);
          expect(nfaResult.data, equals(dfaResult.data));
        }
      });
    });

    group('DFA Minimization', () {
      test('should minimize simple DFA', () async {
        // Arrange
        final dfa = await createMinimizableDFA();
        final request = ConversionRequest(
          conversionType: ConversionType.minimizeDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(dfa.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        
        // Verify minimization reduced states
        expect(result.data!.states.length, lessThanOrEqualTo(dfa.states.length));
        
        // Verify language preservation
        final testStrings = ['a', 'ab', 'aa', 'b', 'ba', ''];
        for (final testString in testStrings) {
          final originalResult = await conversionService.simulateString(dfa.id, testString);
          final minimizedResult = await conversionService.simulateString(result.data!.id, testString);
          expect(originalResult.data, equals(minimizedResult.data));
        }
      });

      test('should handle already minimal DFA', () async {
        // Arrange
        final dfa = await createMinimalDFA();
        final request = ConversionRequest(
          conversionType: ConversionType.minimizeDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(dfa.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data!.states.length, equals(dfa.states.length));
      });
    });

    group('Regular Expression to NFA', () {
      test('should convert simple regex to NFA', () async {
        // Arrange
        const regex = 'a*b+';
        final request = ConversionRequest(
          conversionType: ConversionType.regexToNfa,
          parameters: {'regex': regex},
        );

        // Act
        final result = await conversionService.convertRegex(regex, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(AutomatonType.fsa));
        expect(result.data!.states, isNotEmpty);
        expect(result.data!.transitions, isNotEmpty);
      });

      test('should handle complex regex patterns', () async {
        // Arrange
        const regex = '(a|b)*c+';
        final request = ConversionRequest(
          conversionType: ConversionType.regexToNfa,
          parameters: {'regex': regex},
        );

        // Act
        final result = await conversionService.convertRegex(regex, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        
        // Test regex acceptance
        final testCases = [
          ('c', true),
          ('cc', true),
          ('ac', true),
          ('bc', true),
          ('abc', true),
          ('aabbcc', true),
          ('d', false),
          ('', false),
        ];
        
        for (final (testString, expected) in testCases) {
          final simulationResult = await conversionService.simulateString(result.data!.id, testString);
          expect(simulationResult.data, equals(expected));
        }
      });

      test('should handle empty regex', () async {
        // Arrange
        const regex = '';
        final request = ConversionRequest(
          conversionType: ConversionType.regexToNfa,
          parameters: {'regex': regex},
        );

        // Act
        final result = await conversionService.convertRegex(regex, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.states, hasLength(1));
        expect(result.data!.transitions, isEmpty);
      });

      test('should handle invalid regex', () async {
        // Arrange
        const regex = 'a**'; // Invalid regex
        final request = ConversionRequest(
          conversionType: ConversionType.regexToNfa,
          parameters: {'regex': regex},
        );

        // Act
        final result = await conversionService.convertRegex(regex, request);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('invalid regex'));
      });
    });

    group('FA to Regular Expression', () {
      test('should convert simple DFA to regex', () async {
        // Arrange
        final dfa = await createSimpleDFA();
        final request = ConversionRequest(
          conversionType: ConversionType.faToRegex,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(dfa.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data, isA<String>());
        
        final regex = result.data as String;
        expect(regex, isNotEmpty);
        
        // Verify regex accepts same language
        final testStrings = ['a', 'ab', 'aa', 'b', 'ba', ''];
        for (final testString in testStrings) {
          final dfaResult = await conversionService.simulateString(dfa.id, testString);
          final regexResult = await conversionService.testRegex(regex, testString);
          expect(dfaResult.data, equals(regexResult.data));
        }
      });
    });

    group('Grammar to Automaton Conversions', () {
      test('should convert right-linear grammar to FA', () async {
        // Arrange
        final grammar = await createRightLinearGrammar();
        final request = ConversionRequest(
          conversionType: ConversionType.rightLinearToFa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convertGrammar(grammar.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(AutomatonType.fsa));
      });

      test('should convert CFG to PDA (LL method)', () async {
        // Arrange
        final grammar = await createCFG();
        final request = ConversionRequest(
          conversionType: ConversionType.cfgToPdaLl,
          parameters: {},
        );

        // Act
        final result = await conversionService.convertGrammar(grammar.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(AutomatonType.pda));
      });

      test('should convert CFG to PDA (LR method)', () async {
        // Arrange
        final grammar = await createCFG();
        final request = ConversionRequest(
          conversionType: ConversionType.cfgToPdaLr,
          parameters: {},
        );

        // Act
        final result = await conversionService.convertGrammar(grammar.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(AutomatonType.pda));
      });

      test('should convert PDA to CFG', () async {
        // Arrange
        final pda = await createPDA();
        final request = ConversionRequest(
          conversionType: ConversionType.pdaToCfg,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(pda.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data, isA<Grammar>());
      });
    });

    group('Error Handling', () {
      test('should return error for non-existent automaton', () async {
        // Arrange
        const nonExistentId = 'non-existent-id';
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(nonExistentId, request);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('not found'));
      });

      test('should return error for invalid conversion type', () async {
        // Arrange
        final automaton = await createSimpleNFA();
        final request = ConversionRequest(
          conversionType: ConversionType.minimizeDfa, // Wrong type for NFA
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(automaton.id, request);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('invalid conversion'));
      });
    });

    group('Performance', () {
      test('should complete conversion within time limit', () async {
        // Arrange
        final largeNFA = await createLargeNFA();
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await conversionService.convert(largeNFA.id, request);
        stopwatch.stop();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 second limit
      });
    });
  });

  // Helper methods to create test automata and grammars
  Future<Automaton> createSimpleNFA() async {
    throw UnimplementedError('Simple NFA creation not implemented yet');
  }

  Future<Automaton> createNFAWithLambda() async {
    throw UnimplementedError('NFA with lambda creation not implemented yet');
  }

  Future<Automaton> createNFA() async {
    throw UnimplementedError('NFA creation not implemented yet');
  }

  Future<Automaton> createMinimizableDFA() async {
    throw UnimplementedError('Minimizable DFA creation not implemented yet');
  }

  Future<Automaton> createMinimalDFA() async {
    throw UnimplementedError('Minimal DFA creation not implemented yet');
  }

  Future<Automaton> createSimpleDFA() async {
    throw UnimplementedError('Simple DFA creation not implemented yet');
  }

  Future<Grammar> createRightLinearGrammar() async {
    throw UnimplementedError('Right-linear grammar creation not implemented yet');
  }

  Future<Grammar> createCFG() async {
    throw UnimplementedError('CFG creation not implemented yet');
  }

  Future<Automaton> createPDA() async {
    throw UnimplementedError('PDA creation not implemented yet');
  }

  Future<Automaton> createLargeNFA() async {
    throw UnimplementedError('Large NFA creation not implemented yet');
  }
}
