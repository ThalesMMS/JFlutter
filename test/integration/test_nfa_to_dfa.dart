import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/automaton.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/data/services/conversion_service.dart';
import 'package:jflutter/data/services/simulation_service.dart';

/// Integration tests for NFA to DFA conversion
/// These tests verify end-to-end conversion functionality
void main() {
  group('NFA to DFA Conversion Integration Tests', () {
    late AutomatonService automatonService;
    late ConversionService conversionService;
    late SimulationService simulationService;

    setUp(() {
      automatonService = AutomatonService();
      conversionService = ConversionService();
      simulationService = SimulationService();
    });

    group('Simple NFA to DFA Conversion', () {
      test('should convert simple NFA to equivalent DFA', () async {
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
        
        final dfa = result.data!;
        expect(dfa.states, isNotEmpty);
        expect(dfa.transitions, isNotEmpty);
        
        // Verify determinism
        await verifyDeterminism(dfa);
        
        // Verify language equivalence
        await verifyLanguageEquivalence(nfa, dfa);
      });

      test('should handle NFA with multiple transitions from same state', () async {
        // Arrange
        final nfa = await createNFAWithMultipleTransitions();
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(nfa.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        
        final dfa = result.data!;
        await verifyDeterminism(dfa);
        await verifyLanguageEquivalence(nfa, dfa);
      });
    });

    group('NFA with Lambda Transitions', () {
      test('should convert NFA with lambda transitions to DFA', () async {
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
        
        final dfa = result.data!;
        
        // Verify no lambda transitions in DFA
        for (final transition in dfa.transitions) {
          final fsaTransition = transition as FSATransition;
          expect(fsaTransition.lambdaSymbol, isNull);
        }
        
        await verifyDeterminism(dfa);
        await verifyLanguageEquivalence(nfa, dfa);
      });

      test('should handle lambda closure correctly', () async {
        // Arrange
        final nfa = await createNFAWithLambdaClosure();
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(nfa.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        
        final dfa = result.data!;
        await verifyDeterminism(dfa);
        await verifyLanguageEquivalence(nfa, dfa);
      });
    });

    group('Complex NFA Conversions', () {
      test('should convert NFA with multiple accepting states', () async {
        // Arrange
        final nfa = await createNFAWithMultipleAcceptingStates();
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(nfa.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        
        final dfa = result.data!;
        await verifyDeterminism(dfa);
        await verifyLanguageEquivalence(nfa, dfa);
      });

      test('should convert NFA with self-loops', () async {
        // Arrange
        final nfa = await createNFAWithSelfLoops();
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(nfa.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        
        final dfa = result.data!;
        await verifyDeterminism(dfa);
        await verifyLanguageEquivalence(nfa, dfa);
      });
    });

    group('Language Equivalence Verification', () {
      test('should preserve language for simple patterns', () async {
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
        
        final dfa = result.data!;
        final testStrings = ['a', 'b', 'ab', 'ba', 'aa', 'bb', ''];
        
        for (final testString in testStrings) {
          final nfaResult = await simulationService.simulate(nfa.id, SimulationRequest(
            inputString: testString,
            stepByStep: false,
          ));
          final dfaResult = await simulationService.simulate(dfa.id, SimulationRequest(
            inputString: testString,
            stepByStep: false,
          ));
          
          expect(nfaResult.data!.accepted, equals(dfaResult.data!.accepted),
            reason: 'Language mismatch for string "$testString"');
        }
      });

      test('should preserve language for complex patterns', () async {
        // Arrange
        final nfa = await createComplexNFA();
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(nfa.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        
        final dfa = result.data!;
        final testStrings = [
          'a', 'b', 'c',
          'ab', 'ac', 'ba', 'bc', 'ca', 'cb',
          'abc', 'acb', 'bac', 'bca', 'cab', 'cba',
          'aa', 'bb', 'cc',
          'aab', 'abb', 'aac', 'acc',
          '', 'aaa', 'bbb', 'ccc'
        ];
        
        for (final testString in testStrings) {
          final nfaResult = await simulationService.simulate(nfa.id, SimulationRequest(
            inputString: testString,
            stepByStep: false,
          ));
          final dfaResult = await simulationService.simulate(dfa.id, SimulationRequest(
            inputString: testString,
            stepByStep: false,
          ));
          
          expect(nfaResult.data!.accepted, equals(dfaResult.data!.accepted),
            reason: 'Language mismatch for string "$testString"');
        }
      });
    });

    group('Performance Tests', () {
      test('should convert large NFA within time limit', () async {
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
        
        final dfa = result.data!;
        await verifyDeterminism(dfa);
        await verifyLanguageEquivalence(largeNFA, dfa);
      });

      test('should handle exponential state explosion gracefully', () async {
        // Arrange
        final exponentialNFA = await createExponentialNFA();
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await conversionService.convert(exponentialNFA.id, request);
        stopwatch.stop();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // 15 second limit
        
        final dfa = result.data!;
        expect(dfa.states.length, greaterThan(exponentialNFA.states.length));
        await verifyDeterminism(dfa);
      });
    });

    group('Error Handling', () {
      test('should handle invalid NFA gracefully', () async {
        // Arrange
        final invalidNFA = await createInvalidNFA();
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(invalidNFA.id, request);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('invalid'));
      });

      test('should handle empty NFA', () async {
        // Arrange
        final emptyNFA = await createEmptyNFA();
        final request = ConversionRequest(
          conversionType: ConversionType.nfaToDfa,
          parameters: {},
        );

        // Act
        final result = await conversionService.convert(emptyNFA.id, request);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('empty'));
      });
    });
  });

  // Helper methods
  Future<void> verifyDeterminism(Automaton dfa) async {
    for (final state in dfa.states) {
      final outgoingTransitions = dfa.transitions
          .where((t) => t.fromState.id == state.id);
      
      final inputSymbols = <String>{};
      for (final transition in outgoingTransitions) {
        final fsaTransition = transition as FSATransition;
        for (final symbol in fsaTransition.inputSymbols) {
          expect(inputSymbols.contains(symbol), isFalse,
            reason: 'Non-deterministic transition found for state ${state.id} and symbol $symbol');
          inputSymbols.add(symbol);
        }
      }
    }
  }

  Future<void> verifyLanguageEquivalence(Automaton nfa, Automaton dfa) async {
    final testStrings = generateTestStrings(nfa.alphabet, 3);
    
    for (final testString in testStrings) {
      final nfaResult = await simulationService.simulate(nfa.id, SimulationRequest(
        inputString: testString,
        stepByStep: false,
      ));
      final dfaResult = await simulationService.simulate(dfa.id, SimulationRequest(
        inputString: testString,
        stepByStep: false,
      ));
      
      expect(nfaResult.data!.accepted, equals(dfaResult.data!.accepted),
        reason: 'Language mismatch for string "$testString"');
    }
  }

  List<String> generateTestStrings(Set<String> alphabet, int maxLength) {
    final strings = <String>[''];
    final queue = [''];
    
    while (queue.isNotEmpty && queue.first.length < maxLength) {
      final current = queue.removeAt(0);
      
      for (final symbol in alphabet) {
        final newString = current + symbol;
        strings.add(newString);
        queue.add(newString);
      }
    }
    
    return strings;
  }

  // NFA creation helper methods
  Future<Automaton> createSimpleNFA() async {
    throw UnimplementedError('Simple NFA creation not implemented yet');
  }

  Future<Automaton> createNFAWithMultipleTransitions() async {
    throw UnimplementedError('NFA with multiple transitions creation not implemented yet');
  }

  Future<Automaton> createNFAWithLambda() async {
    throw UnimplementedError('NFA with lambda creation not implemented yet');
  }

  Future<Automaton> createNFAWithLambdaClosure() async {
    throw UnimplementedError('NFA with lambda closure creation not implemented yet');
  }

  Future<Automaton> createNFAWithMultipleAcceptingStates() async {
    throw UnimplementedError('NFA with multiple accepting states creation not implemented yet');
  }

  Future<Automaton> createNFAWithSelfLoops() async {
    throw UnimplementedError('NFA with self loops creation not implemented yet');
  }

  Future<Automaton> createComplexNFA() async {
    throw UnimplementedError('Complex NFA creation not implemented yet');
  }

  Future<Automaton> createLargeNFA() async {
    throw UnimplementedError('Large NFA creation not implemented yet');
  }

  Future<Automaton> createExponentialNFA() async {
    throw UnimplementedError('Exponential NFA creation not implemented yet');
  }

  Future<Automaton> createInvalidNFA() async {
    throw UnimplementedError('Invalid NFA creation not implemented yet');
  }

  Future<Automaton> createEmptyNFA() async {
    throw UnimplementedError('Empty NFA creation not implemented yet');
  }
}
