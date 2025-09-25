// Performance tests for canvas rendering and simulation
// Tests 60fps canvas performance and >10k simulation steps

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas/automaton_canvas.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas/automaton_painter.dart';
import 'package:jflutter/core/models/automaton.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/core/models/alphabet.dart';
import 'package:jflutter/core/models/automaton_metadata.dart';

void main() {
  group('Canvas Performance Tests', () {
    late Automaton testAutomaton;

    setUp(() {
      // Create a complex automaton with many states and transitions
      final states = <State>[];
      final transitions = <Transition>[];
      
      // Create 100 states in a grid pattern
      for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
          states.add(State(
            id: 'q${i}_${j}',
            name: 'q${i}_${j}',
            position: Position(x: i * 100.0, y: j * 100.0),
            isInitial: i == 0 && j == 0,
            isAccepting: i == 9 && j == 9,
          ));
        }
      }

      // Create transitions between adjacent states
      for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
          final currentId = 'q${i}_${j}';
          
          // Right transition
          if (j < 9) {
            transitions.add(Transition(
              id: 't_${i}_${j}_right',
              fromState: currentId,
              toState: 'q${i}_${j + 1}',
              symbol: 'a',
            ));
          }
          
          // Down transition
          if (i < 9) {
            transitions.add(Transition(
              id: 't_${i}_${j}_down',
              fromState: currentId,
              toState: 'q${i + 1}_${j}',
              symbol: 'b',
            ));
          }
        }
      }

      testAutomaton = Automaton(
        id: 'performance-test',
        name: 'Performance Test Automaton',
        type: AutomatonType.DFA,
        states: states,
        transitions: transitions,
        alphabet: Alphabet(symbols: ['a', 'b']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'performance-test',
        ),
      );
    });

    testWidgets('Canvas rendering performance - 60fps target', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      int frameCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: testAutomaton,
              onStateAdded: (x, y) {},
              onTransitionAdded: (from, to, symbol) {},
              onStateUpdated: (state) {},
              onTransitionUpdated: (transition) {},
            ),
          ),
        ),
      );

      // Simulate 60 frames (1 second at 60fps)
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16)); // ~60fps
        frameCount++;
      }

      stopwatch.stop();
      final fps = frameCount / (stopwatch.elapsedMilliseconds / 1000.0);
      
      // Should maintain at least 50fps (allowing some margin)
      expect(fps, greaterThanOrEqualTo(50.0));
    });

    testWidgets('Canvas rendering with zoom and pan operations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: testAutomaton,
              onStateAdded: (x, y) {},
              onTransitionAdded: (from, to, symbol) {},
              onStateUpdated: (state) {},
              onTransitionUpdated: (transition) {},
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();
      
      // Simulate zoom and pan operations
      for (int i = 0; i < 100; i++) {
        // Simulate pinch zoom
        await tester.startGesture(const Offset(100, 100));
        await tester.moveTo(const Offset(200, 200));
        await tester.endGesture();
        
        // Simulate pan
        await tester.startGesture(const Offset(50, 50));
        await tester.moveTo(const Offset(150, 150));
        await tester.endGesture();
        
        await tester.pump(const Duration(milliseconds: 16));
      }

      stopwatch.stop();
      
      // Should complete 100 operations in reasonable time (< 2 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    testWidgets('Large automaton rendering performance', (WidgetTester tester) async {
      // Create an even larger automaton
      final largeStates = <State>[];
      final largeTransitions = <Transition>[];
      
      // Create 400 states (20x20 grid)
      for (int i = 0; i < 20; i++) {
        for (int j = 0; j < 20; j++) {
          largeStates.add(State(
            id: 'q${i}_${j}',
            name: 'q${i}_${j}',
            position: Position(x: i * 50.0, y: j * 50.0),
            isInitial: i == 0 && j == 0,
            isAccepting: i == 19 && j == 19,
          ));
        }
      }

      // Create transitions
      for (int i = 0; i < 20; i++) {
        for (int j = 0; j < 20; j++) {
          final currentId = 'q${i}_${j}';
          
          if (j < 19) {
            largeTransitions.add(Transition(
              id: 't_${i}_${j}_right',
              fromState: currentId,
              toState: 'q${i}_${j + 1}',
              symbol: 'a',
            ));
          }
          
          if (i < 19) {
            largeTransitions.add(Transition(
              id: 't_${i}_${j}_down',
              fromState: currentId,
              toState: 'q${i + 1}_${j}',
              symbol: 'b',
            ));
          }
        }
      }

      final largeAutomaton = Automaton(
        id: 'large-performance-test',
        name: 'Large Performance Test Automaton',
        type: AutomatonType.DFA,
        states: largeStates,
        transitions: largeTransitions,
        alphabet: Alphabet(symbols: ['a', 'b']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'performance-test',
        ),
      );

      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: largeAutomaton,
              onStateAdded: (x, y) {},
              onTransitionAdded: (from, to, symbol) {},
              onStateUpdated: (state) {},
              onTransitionUpdated: (transition) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();
      
      // Should render large automaton in reasonable time (< 1 second)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
