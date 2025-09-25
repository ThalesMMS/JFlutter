// Property-based tests for algorithms
// Tests algorithmic properties and invariants using random data

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/automaton.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/core/models/alphabet.dart';
import 'package:jflutter/core/models/automaton_metadata.dart';
import 'package:jflutter/core/algorithms/automaton_simulator.dart';
import 'package:jflutter/core/algorithms/nfa_to_dfa_converter.dart';
import 'package:jflutter/core/algorithms/dfa_minimizer.dart';
import 'package:jflutter/core/algorithms/fa_to_regex_converter.dart';
import 'package:jflutter/core/algorithms/regex_to_nfa_converter.dart';
import 'dart:math';

void main() {
  group('Algorithm Property Tests', () {
    late Random random;

    setUp(() {
      random = Random(42); // Fixed seed for reproducible tests
    });

    test('NFA to DFA conversion preserves language', () {
      // Generate random NFAs and verify that NFA->DFA conversion preserves language
      for (int testCase = 0; testCase < 100; testCase++) {
        final nfa = _generateRandomNFA(random);
        final dfa = NfaToDfaConverter().convert(nfa);
        
        // Test with random strings
        for (int i = 0; i < 50; i++) {
          final testString = _generateRandomString(random, nfa.alphabet.symbols);
          final nfaResult = AutomatonSimulator().simulate(nfa, testString);
          final dfaResult = AutomatonSimulator().simulate(dfa, testString);
          
          expect(nfaResult.isAccepted, equals(dfaResult.isAccepted),
            reason: 'NFA and DFA should accept the same strings. '
                   'String: $testString, NFA: ${nfaResult.isAccepted}, DFA: ${dfaResult.isAccepted}');
        }
      }
    });

    test('DFA minimization preserves language', () {
      // Generate random DFAs and verify that minimization preserves language
      for (int testCase = 0; testCase < 100; testCase++) {
        final originalDfa = _generateRandomDFA(random);
        final minimizedDfa = DfaMinimizer().minimize(originalDfa);
        
        // Test with random strings
        for (int i = 0; i < 50; i++) {
          final testString = _generateRandomString(random, originalDfa.alphabet.symbols);
          final originalResult = AutomatonSimulator().simulate(originalDfa, testString);
          final minimizedResult = AutomatonSimulator().simulate(minimizedDfa, testString);
          
          expect(originalResult.isAccepted, equals(minimizedResult.isAccepted),
            reason: 'Original and minimized DFA should accept the same strings. '
                   'String: $testString, Original: ${originalResult.isAccepted}, Minimized: ${minimizedResult.isAccepted}');
        }
      }
    });

    test('FA to Regex conversion preserves language', () {
      // Generate random FAs and verify that FA->Regex conversion preserves language
      for (int testCase = 0; testCase < 50; testCase++) {
        final fa = _generateRandomDFA(random);
        final regex = FaToRegexConverter().convert(fa);
        
        // Test with random strings
        for (int i = 0; i < 30; i++) {
          final testString = _generateRandomString(random, fa.alphabet.symbols);
          final faResult = AutomatonSimulator().simulate(fa, testString);
          final regexResult = _testRegexMatch(regex.pattern, testString);
          
          expect(faResult.isAccepted, equals(regexResult),
            reason: 'FA and Regex should accept the same strings. '
                   'String: $testString, FA: ${faResult.isAccepted}, Regex: $regexResult');
        }
      }
    });

    test('Regex to NFA conversion preserves language', () {
      // Generate random regex patterns and verify that Regex->NFA conversion preserves language
      for (int testCase = 0; testCase < 50; testCase++) {
        final regexPattern = _generateRandomRegex(random);
        final nfa = RegexToNfaConverter().convert(regexPattern);
        
        // Test with random strings
        for (int i = 0; i < 30; i++) {
          final testString = _generateRandomString(random, ['a', 'b']); // Binary alphabet
          final nfaResult = AutomatonSimulator().simulate(nfa, testString);
          final regexResult = _testRegexMatch(regexPattern, testString);
          
          expect(nfaResult.isAccepted, equals(regexResult),
            reason: 'Regex and NFA should accept the same strings. '
                   'String: $testString, Regex: $regexResult, NFA: ${nfaResult.isAccepted}');
        }
      }
    });

    test('DFA minimization reduces state count', () {
      // Verify that minimization actually reduces the number of states
      for (int testCase = 0; testCase < 100; testCase++) {
        final originalDfa = _generateRandomDFA(random);
        final minimizedDfa = DfaMinimizer().minimize(originalDfa);
        
        expect(minimizedDfa.states.length, lessThanOrEqualTo(originalDfa.states.length),
          reason: 'Minimized DFA should have fewer or equal states than original');
      }
    });

    test('NFA to DFA conversion is deterministic', () {
      // Verify that NFA->DFA conversion produces a deterministic automaton
      for (int testCase = 0; testCase < 50; testCase++) {
        final nfa = _generateRandomNFA(random);
        final dfa = NfaToDfaConverter().convert(nfa);
        
        // Check that each state has at most one transition per symbol
        for (final state in dfa.states) {
          final transitionsBySymbol = <String, List<Transition>>{};
          
          for (final transition in dfa.transitions) {
            if (transition.fromState == state.id) {
              transitionsBySymbol.putIfAbsent(transition.symbol, () => []).add(transition);
            }
          }
          
          for (final symbol in dfa.alphabet.symbols) {
            final transitions = transitionsBySymbol[symbol] ?? [];
            expect(transitions.length, lessThanOrEqualTo(1),
              reason: 'DFA should be deterministic - state ${state.id} has ${transitions.length} transitions for symbol $symbol');
          }
        }
      }
    });

    test('Algorithm idempotency properties', () {
      // Test that applying algorithms multiple times doesn't change results
      for (int testCase = 0; testCase < 50; testCase++) {
        final originalDfa = _generateRandomDFA(random);
        
        // Minimize twice - should be idempotent
        final minimizedOnce = DfaMinimizer().minimize(originalDfa);
        final minimizedTwice = DfaMinimizer().minimize(minimizedOnce);
        
        expect(minimizedOnce.states.length, equals(minimizedTwice.states.length),
          reason: 'DFA minimization should be idempotent');
        
        // Test language preservation
        for (int i = 0; i < 20; i++) {
          final testString = _generateRandomString(random, originalDfa.alphabet.symbols);
          final onceResult = AutomatonSimulator().simulate(minimizedOnce, testString);
          final twiceResult = AutomatonSimulator().simulate(minimizedTwice, testString);
          
          expect(onceResult.isAccepted, equals(twiceResult.isAccepted),
            reason: 'Double minimization should preserve language');
        }
      }
    });

    test('Edge cases and boundary conditions', () {
      // Test algorithms with edge cases
      
      // Empty automaton
      final emptyAutomaton = Automaton(
        id: 'empty',
        name: 'Empty Automaton',
        type: AutomatonType.DFA,
        states: [],
        transitions: [],
        alphabet: Alphabet(symbols: ['a']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'property-test',
        ),
      );
      
      final emptyResult = AutomatonSimulator().simulate(emptyAutomaton, 'a');
      expect(emptyResult.isAccepted, isFalse);
      
      // Single state automaton
      final singleState = State(
        id: 'q0',
        name: 'q0',
        position: Position(x: 100, y: 100),
        isInitial: true,
        isAccepting: true,
      );
      
      final singleStateAutomaton = Automaton(
        id: 'single',
        name: 'Single State Automaton',
        type: AutomatonType.DFA,
        states: [singleState],
        transitions: [],
        alphabet: Alphabet(symbols: ['a']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'property-test',
        ),
      );
      
      final singleResult = AutomatonSimulator().simulate(singleStateAutomaton, '');
      expect(singleResult.isAccepted, isTrue);
    });
  });

  // Helper functions for generating random test data

  Automaton _generateRandomNFA(Random random) {
    final stateCount = random.nextInt(10) + 2; // 2-11 states
    final alphabetSize = random.nextInt(3) + 1; // 1-3 symbols
    final symbols = List.generate(alphabetSize, (i) => String.fromCharCode(97 + i));
    
    final states = <State>[];
    final transitions = <Transition>[];
    
    // Create states
    for (int i = 0; i < stateCount; i++) {
      states.add(State(
        id: 'q$i',
        name: 'q$i',
        position: Position(x: random.nextDouble() * 400, y: random.nextDouble() * 400),
        isInitial: i == 0,
        isAccepting: random.nextBool(),
      ));
    }
    
    // Create random transitions
    final transitionCount = random.nextInt(stateCount * alphabetSize) + stateCount;
    for (int i = 0; i < transitionCount; i++) {
      final fromState = states[random.nextInt(stateCount)];
      final toState = states[random.nextInt(stateCount)];
      final symbol = symbols[random.nextInt(symbols.length)];
      
      transitions.add(Transition(
        id: 't$i',
        fromState: fromState.id,
        toState: toState.id,
        symbol: symbol,
      ));
    }
    
    return Automaton(
      id: 'random-nfa',
      name: 'Random NFA',
      type: AutomatonType.NFA,
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: symbols),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'property-test',
      ),
    );
  }

  Automaton _generateRandomDFA(Random random) {
    final stateCount = random.nextInt(8) + 2; // 2-9 states
    final alphabetSize = random.nextInt(3) + 1; // 1-3 symbols
    final symbols = List.generate(alphabetSize, (i) => String.fromCharCode(97 + i));
    
    final states = <State>[];
    final transitions = <Transition>[];
    
    // Create states
    for (int i = 0; i < stateCount; i++) {
      states.add(State(
        id: 'q$i',
        name: 'q$i',
        position: Position(x: random.nextDouble() * 400, y: random.nextDouble() * 400),
        isInitial: i == 0,
        isAccepting: random.nextBool(),
      ));
    }
    
    // Create deterministic transitions
    for (final state in states) {
      for (final symbol in symbols) {
        final toState = states[random.nextInt(stateCount)];
        transitions.add(Transition(
          id: 't_${state.id}_$symbol',
          fromState: state.id,
          toState: toState.id,
          symbol: symbol,
        ));
      }
    }
    
    return Automaton(
      id: 'random-dfa',
      name: 'Random DFA',
      type: AutomatonType.DFA,
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: symbols),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'property-test',
      ),
    );
  }

  String _generateRandomString(Random random, List<String> alphabet) {
    final length = random.nextInt(10) + 1; // 1-10 characters
    final buffer = StringBuffer();
    
    for (int i = 0; i < length; i++) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }
    
    return buffer.toString();
  }

  String _generateRandomRegex(Random random) {
    final patterns = [
      'a*',
      'b*',
      'ab',
      'a+b',
      'a*b*',
      '(ab)*',
      'a+b*',
      'a*b+',
      '(a+b)*',
      'a*b*',
    ];
    
    return patterns[random.nextInt(patterns.length)];
  }

  bool _testRegexMatch(String pattern, String input) {
    // Simple regex matching for basic patterns
    // This is a simplified implementation for testing
    try {
      final regex = RegExp('^$pattern\$');
      return regex.hasMatch(input);
    } catch (e) {
      return false;
    }
  }
}
