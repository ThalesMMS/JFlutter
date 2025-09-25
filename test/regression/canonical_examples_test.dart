// Regression tests based on canonical examples
// Tests known working examples to prevent regressions

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

void main() {
  group('Canonical Examples Regression Tests', () {
    
    test('Example 1: Simple DFA for strings ending with "ab"', () {
      // Create DFA that accepts strings ending with "ab"
      final states = [
        State(id: 'q0', name: 'q0', position: Position(x: 100, y: 100), isInitial: true),
        State(id: 'q1', name: 'q1', position: Position(x: 200, y: 100)),
        State(id: 'q2', name: 'q2', position: Position(x: 300, y: 100), isAccepting: true),
      ];
      
      final transitions = [
        Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
        Transition(id: 't2', fromState: 'q0', toState: 'q0', symbol: 'b'),
        Transition(id: 't3', fromState: 'q1', toState: 'q2', symbol: 'b'),
        Transition(id: 't4', fromState: 'q1', toState: 'q0', symbol: 'a'),
        Transition(id: 't5', fromState: 'q2', toState: 'q0', symbol: 'a'),
        Transition(id: 't6', fromState: 'q2', toState: 'q1', symbol: 'b'),
      ];
      
      final dfa = Automaton(
        id: 'ends-with-ab',
        name: 'Ends with "ab" DFA',
        type: AutomatonType.DFA,
        states: states,
        transitions: transitions,
        alphabet: Alphabet(symbols: ['a', 'b']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'regression-test',
        ),
      );
      
      final simulator = AutomatonSimulator();
      
      // Test cases
      expect(simulator.simulate(dfa, 'ab').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'aab').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'bab').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'abab').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'a').isAccepted, isFalse);
      expect(simulator.simulate(dfa, 'b').isAccepted, isFalse);
      expect(simulator.simulate(dfa, 'ba').isAccepted, isFalse);
      expect(simulator.simulate(dfa, 'aba').isAccepted, isFalse);
    });

    test('Example 2: NFA for strings containing "aa" or "bb"', () {
      // Create NFA that accepts strings containing "aa" or "bb"
      final states = [
        State(id: 'q0', name: 'q0', position: Position(x: 100, y: 100), isInitial: true),
        State(id: 'q1', name: 'q1', position: Position(x: 200, y: 100)),
        State(id: 'q2', name: 'q2', position: Position(x: 300, y: 100), isAccepting: true),
        State(id: 'q3', name: 'q3', position: Position(x: 200, y: 200)),
        State(id: 'q4', name: 'q4', position: Position(x: 300, y: 200), isAccepting: true),
      ];
      
      final transitions = [
        Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
        Transition(id: 't2', fromState: 'q0', toState: 'q3', symbol: 'b'),
        Transition(id: 't3', fromState: 'q1', toState: 'q2', symbol: 'a'),
        Transition(id: 't4', fromState: 'q3', toState: 'q4', symbol: 'b'),
        Transition(id: 't5', fromState: 'q0', toState: 'q0', symbol: 'a'),
        Transition(id: 't6', fromState: 'q0', toState: 'q0', symbol: 'b'),
        Transition(id: 't7', fromState: 'q2', toState: 'q2', symbol: 'a'),
        Transition(id: 't8', fromState: 'q2', toState: 'q2', symbol: 'b'),
        Transition(id: 't9', fromState: 'q4', toState: 'q4', symbol: 'a'),
        Transition(id: 't10', fromState: 'q4', toState: 'q4', symbol: 'b'),
      ];
      
      final nfa = Automaton(
        id: 'contains-aa-or-bb',
        name: 'Contains "aa" or "bb" NFA',
        type: AutomatonType.NFA,
        states: states,
        transitions: transitions,
        alphabet: Alphabet(symbols: ['a', 'b']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'regression-test',
        ),
      );
      
      final simulator = AutomatonSimulator();
      
      // Test cases
      expect(simulator.simulate(nfa, 'aa').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'bb').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'aab').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'bba').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'abab').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'a').isAccepted, isFalse);
      expect(simulator.simulate(nfa, 'b').isAccepted, isFalse);
      expect(simulator.simulate(nfa, 'ab').isAccepted, isFalse);
      expect(simulator.simulate(nfa, 'ba').isAccepted, isFalse);
    });

    test('Example 3: NFA to DFA conversion - Kleene star', () {
      // Create NFA for (a+b)*
      final states = [
        State(id: 'q0', name: 'q0', position: Position(x: 100, y: 100), isInitial: true, isAccepting: true),
        State(id: 'q1', name: 'q1', position: Position(x: 200, y: 100)),
        State(id: 'q2', name: 'q2', position: Position(x: 300, y: 100), isAccepting: true),
      ];
      
      final transitions = [
        Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
        Transition(id: 't2', fromState: 'q0', toState: 'q1', symbol: 'b'),
        Transition(id: 't3', fromState: 'q1', toState: 'q2', symbol: 'a'),
        Transition(id: 't4', fromState: 'q1', toState: 'q2', symbol: 'b'),
        Transition(id: 't5', fromState: 'q2', toState: 'q0', symbol: 'a'),
        Transition(id: 't6', fromState: 'q2', toState: 'q0', symbol: 'b'),
      ];
      
      final nfa = Automaton(
        id: 'kleene-star',
        name: 'Kleene Star NFA',
        type: AutomatonType.NFA,
        states: states,
        transitions: transitions,
        alphabet: Alphabet(symbols: ['a', 'b']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'regression-test',
        ),
      );
      
      // Convert to DFA
      final dfa = NfaToDfaConverter().convert(nfa);
      final simulator = AutomatonSimulator();
      
      // Test cases - should accept all strings over {a,b}
      expect(simulator.simulate(dfa, '').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'a').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'b').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'ab').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'ba').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'aab').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'abab').isAccepted, isTrue);
    });

    test('Example 4: DFA minimization - equivalent states', () {
      // Create DFA with equivalent states that should be merged
      final states = [
        State(id: 'q0', name: 'q0', position: Position(x: 100, y: 100), isInitial: true),
        State(id: 'q1', name: 'q1', position: Position(x: 200, y: 100)),
        State(id: 'q2', name: 'q2', position: Position(x: 300, y: 100), isAccepting: true),
        State(id: 'q3', name: 'q3', position: Position(x: 400, y: 100), isAccepting: true),
      ];
      
      final transitions = [
        Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
        Transition(id: 't2', fromState: 'q0', toState: 'q0', symbol: 'b'),
        Transition(id: 't3', fromState: 'q1', toState: 'q2', symbol: 'a'),
        Transition(id: 't4', fromState: 'q1', toState: 'q1', symbol: 'b'),
        Transition(id: 't5', fromState: 'q2', toState: 'q2', symbol: 'a'),
        Transition(id: 't6', fromState: 'q2', toState: 'q2', symbol: 'b'),
        Transition(id: 't7', fromState: 'q3', toState: 'q3', symbol: 'a'),
        Transition(id: 't8', fromState: 'q3', toState: 'q3', symbol: 'b'),
      ];
      
      final dfa = Automaton(
        id: 'minimization-test',
        name: 'Minimization Test DFA',
        type: AutomatonType.DFA,
        states: states,
        transitions: transitions,
        alphabet: Alphabet(symbols: ['a', 'b']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'regression-test',
        ),
      );
      
      // Minimize DFA
      final minimizedDfa = DfaMinimizer().minimize(dfa);
      final simulator = AutomatonSimulator();
      
      // Test that minimization preserves language
      final testStrings = ['', 'a', 'b', 'aa', 'ab', 'ba', 'bb', 'aaa', 'aab', 'aba', 'abb'];
      
      for (final testString in testStrings) {
        final originalResult = simulator.simulate(dfa, testString);
        final minimizedResult = simulator.simulate(minimizedDfa, testString);
        
        expect(originalResult.isAccepted, equals(minimizedResult.isAccepted),
          reason: 'Minimization should preserve language for string: $testString');
      }
      
      // Minimized DFA should have fewer states
      expect(minimizedDfa.states.length, lessThanOrEqualTo(dfa.states.length));
    });

    test('Example 5: FA to Regex conversion - simple pattern', () {
      // Create DFA for strings that start and end with 'a'
      final states = [
        State(id: 'q0', name: 'q0', position: Position(x: 100, y: 100), isInitial: true),
        State(id: 'q1', name: 'q1', position: Position(x: 200, y: 100)),
        State(id: 'q2', name: 'q2', position: Position(x: 300, y: 100), isAccepting: true),
      ];
      
      final transitions = [
        Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
        Transition(id: 't2', fromState: 'q1', toState: 'q1', symbol: 'a'),
        Transition(id: 't3', fromState: 'q1', toState: 'q1', symbol: 'b'),
        Transition(id: 't4', fromState: 'q1', toState: 'q2', symbol: 'a'),
      ];
      
      final dfa = Automaton(
        id: 'starts-ends-a',
        name: 'Starts and ends with "a" DFA',
        type: AutomatonType.DFA,
        states: states,
        transitions: transitions,
        alphabet: Alphabet(symbols: ['a', 'b']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'regression-test',
        ),
      );
      
      // Convert to regex
      final regex = FaToRegexConverter().convert(dfa);
      final simulator = AutomatonSimulator();
      
      // Test that regex matches the same language
      final testStrings = ['a', 'aa', 'aba', 'abba', 'ababa', 'b', 'ab', 'ba', 'bb'];
      
      for (final testString in testStrings) {
        final dfaResult = simulator.simulate(dfa, testString);
        final regexResult = _testRegexMatch(regex.pattern, testString);
        
        expect(dfaResult.isAccepted, equals(regexResult),
          reason: 'FA and Regex should match for string: $testString');
      }
    });

    test('Example 6: Regex to NFA conversion - complex pattern', () {
      // Test regex (a+b)*ab
      final regexPattern = '(a+b)*ab';
      
      // Convert to NFA
      final nfa = RegexToNfaConverter().convert(regexPattern);
      final simulator = AutomatonSimulator();
      
      // Test cases
      expect(simulator.simulate(nfa, 'ab').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'aab').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'bab').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'abab').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'aabb').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'a').isAccepted, isFalse);
      expect(simulator.simulate(nfa, 'b').isAccepted, isFalse);
      expect(simulator.simulate(nfa, 'ba').isAccepted, isFalse);
      expect(simulator.simulate(nfa, 'aa').isAccepted, isFalse);
      expect(simulator.simulate(nfa, 'bb').isAccepted, isFalse);
    });

    test('Example 7: Empty language automaton', () {
      // Create DFA that accepts no strings
      final states = [
        State(id: 'q0', name: 'q0', position: Position(x: 100, y: 100), isInitial: true),
      ];
      
      final transitions = [
        Transition(id: 't1', fromState: 'q0', toState: 'q0', symbol: 'a'),
        Transition(id: 't2', fromState: 'q0', toState: 'q0', symbol: 'b'),
      ];
      
      final emptyDfa = Automaton(
        id: 'empty-language',
        name: 'Empty Language DFA',
        type: AutomatonType.DFA,
        states: states,
        transitions: transitions,
        alphabet: Alphabet(symbols: ['a', 'b']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'regression-test',
        ),
      );
      
      final simulator = AutomatonSimulator();
      
      // Should reject all strings
      expect(simulator.simulate(emptyDfa, '').isAccepted, isFalse);
      expect(simulator.simulate(emptyDfa, 'a').isAccepted, isFalse);
      expect(simulator.simulate(emptyDfa, 'b').isAccepted, isFalse);
      expect(simulator.simulate(emptyDfa, 'ab').isAccepted, isFalse);
    });

    test('Example 8: Universal language automaton', () {
      // Create DFA that accepts all strings
      final states = [
        State(id: 'q0', name: 'q0', position: Position(x: 100, y: 100), isInitial: true, isAccepting: true),
      ];
      
      final transitions = [
        Transition(id: 't1', fromState: 'q0', toState: 'q0', symbol: 'a'),
        Transition(id: 't2', fromState: 'q0', toState: 'q0', symbol: 'b'),
      ];
      
      final universalDfa = Automaton(
        id: 'universal-language',
        name: 'Universal Language DFA',
        type: AutomatonType.DFA,
        states: states,
        transitions: transitions,
        alphabet: Alphabet(symbols: ['a', 'b']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'regression-test',
        ),
      );
      
      final simulator = AutomatonSimulator();
      
      // Should accept all strings
      expect(simulator.simulate(universalDfa, '').isAccepted, isTrue);
      expect(simulator.simulate(universalDfa, 'a').isAccepted, isTrue);
      expect(simulator.simulate(universalDfa, 'b').isAccepted, isTrue);
      expect(simulator.simulate(universalDfa, 'ab').isAccepted, isTrue);
      expect(simulator.simulate(universalDfa, 'ba').isAccepted, isTrue);
      expect(simulator.simulate(universalDfa, 'aab').isAccepted, isTrue);
    });

    test('Example 9: Pumping lemma example', () {
      // Create DFA for a^n b^n (n > 0)
      // This should be a context-free language, not regular
      // But we'll create a simple version for testing
      final states = [
        State(id: 'q0', name: 'q0', position: Position(x: 100, y: 100), isInitial: true),
        State(id: 'q1', name: 'q1', position: Position(x: 200, y: 100)),
        State(id: 'q2', name: 'q2', position: Position(x: 300, y: 100), isAccepting: true),
      ];
      
      final transitions = [
        Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
        Transition(id: 't2', fromState: 'q1', toState: 'q1', symbol: 'a'),
        Transition(id: 't3', fromState: 'q1', toState: 'q2', symbol: 'b'),
        Transition(id: 't4', fromState: 'q2', toState: 'q2', symbol: 'b'),
      ];
      
      final dfa = Automaton(
        id: 'pumping-lemma-test',
        name: 'Pumping Lemma Test DFA',
        type: AutomatonType.DFA,
        states: states,
        transitions: transitions,
        alphabet: Alphabet(symbols: ['a', 'b']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'regression-test',
        ),
      );
      
      final simulator = AutomatonSimulator();
      
      // Test cases
      expect(simulator.simulate(dfa, 'ab').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'aab').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'abb').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'aabb').isAccepted, isTrue);
      expect(simulator.simulate(dfa, 'a').isAccepted, isFalse);
      expect(simulator.simulate(dfa, 'b').isAccepted, isFalse);
      expect(simulator.simulate(dfa, 'ba').isAccepted, isFalse);
    });

    test('Example 10: Complex NFA with epsilon transitions', () {
      // Create NFA with epsilon transitions for (a+b)*
      final states = [
        State(id: 'q0', name: 'q0', position: Position(x: 100, y: 100), isInitial: true),
        State(id: 'q1', name: 'q1', position: Position(x: 200, y: 100)),
        State(id: 'q2', name: 'q2', position: Position(x: 300, y: 100), isAccepting: true),
        State(id: 'q3', name: 'q3', position: Position(x: 200, y: 200)),
        State(id: 'q4', name: 'q4', position: Position(x: 300, y: 200), isAccepting: true),
      ];
      
      final transitions = [
        Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
        Transition(id: 't2', fromState: 'q0', toState: 'q3', symbol: 'b'),
        Transition(id: 't3', fromState: 'q1', toState: 'q2', symbol: 'a'),
        Transition(id: 't4', fromState: 'q3', toState: 'q4', symbol: 'b'),
        Transition(id: 't5', fromState: 'q2', toState: 'q0', symbol: 'ε'),
        Transition(id: 't6', fromState: 'q4', toState: 'q0', symbol: 'ε'),
      ];
      
      final nfa = Automaton(
        id: 'epsilon-nfa',
        name: 'Epsilon NFA',
        type: AutomatonType.NFA,
        states: states,
        transitions: transitions,
        alphabet: Alphabet(symbols: ['a', 'b', 'ε']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'regression-test',
        ),
      );
      
      final simulator = AutomatonSimulator();
      
      // Test cases
      expect(simulator.simulate(nfa, '').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'a').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'b').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'aa').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'bb').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'ab').isAccepted, isTrue);
      expect(simulator.simulate(nfa, 'ba').isAccepted, isTrue);
    });
  });

  // Helper function for regex matching
  bool _testRegexMatch(String pattern, String input) {
    try {
      final regex = RegExp('^$pattern\$');
      return regex.hasMatch(input);
    } catch (e) {
      return false;
    }
  }
}
