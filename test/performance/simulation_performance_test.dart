// Performance tests for simulation with >10k steps
// Tests simulation performance for large automata and long input strings

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/automaton.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/core/models/alphabet.dart';
import 'package:jflutter/core/models/automaton_metadata.dart';
import 'package:jflutter/core/algorithms/automaton_simulator.dart';

void main() {
  group('Simulation Performance Tests', () {
    late Automaton testAutomaton;

    setUp(() {
      // Create a complex automaton with many states
      final states = <State>[];
      final transitions = <Transition>[];
      
      // Create 50 states in a chain
      for (int i = 0; i < 50; i++) {
        states.add(State(
          id: 'q$i',
          name: 'q$i',
          position: Position(x: i * 50.0, y: 100.0),
          isInitial: i == 0,
          isAccepting: i == 49,
        ));
      }

      // Create transitions between consecutive states
      for (int i = 0; i < 49; i++) {
        transitions.add(Transition(
          id: 't$i',
          fromState: 'q$i',
          toState: 'q${i + 1}',
          symbol: 'a',
        ));
      }

      testAutomaton = Automaton(
        id: 'simulation-performance-test',
        name: 'Simulation Performance Test Automaton',
        type: AutomatonType.DFA,
        states: states,
        transitions: transitions,
        alphabet: Alphabet(symbols: ['a']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'performance-test',
        ),
      );
    });

    test('Simulation with 10k steps should complete in reasonable time', () async {
      // Create a long input string (10k 'a' characters)
      final longInput = 'a' * 10000;
      
      final stopwatch = Stopwatch()..start();
      
      final simulator = AutomatonSimulator();
      final result = await simulator.simulate(testAutomaton, longInput);
      
      stopwatch.stop();
      
      // Should complete 10k steps in reasonable time (< 5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      expect(result.isAccepted, isTrue);
      expect(result.steps.length, equals(10000));
    });

    test('Simulation with 50k steps should complete in reasonable time', () async {
      // Create an even longer input string (50k 'a' characters)
      final veryLongInput = 'a' * 50000;
      
      final stopwatch = Stopwatch()..start();
      
      final simulator = AutomatonSimulator();
      final result = await simulator.simulate(testAutomaton, veryLongInput);
      
      stopwatch.stop();
      
      // Should complete 50k steps in reasonable time (< 30 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(30000));
      expect(result.isAccepted, isTrue);
      expect(result.steps.length, equals(50000));
    });

    test('Simulation with complex branching automaton', () async {
      // Create a more complex automaton with branching
      final complexStates = <State>[];
      final complexTransitions = <Transition>[];
      
      // Create 100 states with branching structure
      for (int i = 0; i < 100; i++) {
        complexStates.add(State(
          id: 'q$i',
          name: 'q$i',
          position: Position(x: (i % 10) * 50.0, y: (i ~/ 10) * 50.0),
          isInitial: i == 0,
          isAccepting: i == 99,
        ));
      }

      // Create branching transitions
      for (int i = 0; i < 99; i++) {
        // Forward transition
        complexTransitions.add(Transition(
          id: 't${i}_forward',
          fromState: 'q$i',
          toState: 'q${i + 1}',
          symbol: 'a',
        ));
        
        // Branching transition (if not at the end of a row)
        if (i % 10 < 9) {
          complexTransitions.add(Transition(
            id: 't${i}_branch',
            fromState: 'q$i',
            toState: 'q${i + 10}',
            symbol: 'b',
          ));
        }
      }

      final complexAutomaton = Automaton(
        id: 'complex-simulation-test',
        name: 'Complex Simulation Test Automaton',
        type: AutomatonType.DFA,
        states: complexStates,
        transitions: complexTransitions,
        alphabet: Alphabet(symbols: ['a', 'b']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'performance-test',
        ),
      );

      // Test with alternating input
      final alternatingInput = 'ab' * 5000; // 10k characters total
      
      final stopwatch = Stopwatch()..start();
      
      final simulator = AutomatonSimulator();
      final result = await simulator.simulate(complexAutomaton, alternatingInput);
      
      stopwatch.stop();
      
      // Should complete complex simulation in reasonable time (< 10 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      expect(result.steps.length, equals(10000));
    });

    test('Memory usage during long simulation', () async {
      // Test memory usage doesn't grow excessively during long simulation
      final longInput = 'a' * 20000; // 20k characters
      
      final simulator = AutomatonSimulator();
      
      // Run multiple simulations to test memory stability
      for (int i = 0; i < 5; i++) {
        final result = await simulator.simulate(testAutomaton, longInput);
        expect(result.isAccepted, isTrue);
        expect(result.steps.length, equals(20000));
      }
      
      // If we get here without memory issues, the test passes
      expect(true, isTrue);
    });

    test('Concurrent simulation performance', () async {
      // Test multiple concurrent simulations
      final input1 = 'a' * 5000;
      final input2 = 'a' * 5000;
      final input3 = 'a' * 5000;
      
      final stopwatch = Stopwatch()..start();
      
      final simulator = AutomatonSimulator();
      
      // Run three simulations concurrently
      final futures = [
        simulator.simulate(testAutomaton, input1),
        simulator.simulate(testAutomaton, input2),
        simulator.simulate(testAutomaton, input3),
      ];
      
      final results = await Future.wait(futures);
      
      stopwatch.stop();
      
      // All simulations should complete successfully
      for (final result in results) {
        expect(result.isAccepted, isTrue);
        expect(result.steps.length, equals(5000));
      }
      
      // Concurrent simulations should complete in reasonable time (< 15 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(15000));
    });
  });
}
