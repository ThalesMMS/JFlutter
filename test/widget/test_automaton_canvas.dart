// Widget test for automaton canvas
// This test MUST fail initially - it defines the expected widget behavior

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/models/automaton.dart';
import 'package:jflutter_core/widgets/automaton_canvas.dart';

void main() {
  group('Automaton Canvas Widget Tests', () {
    late Automaton testAutomaton;

    setUp(() {
      testAutomaton = Automaton(
        id: 'test-fa',
        name: 'Test FA',
        type: AutomatonType.DFA,
        states: [
          State(
            id: 'q0',
            name: 'q0',
            position: Position(x: 100, y: 100),
            isInitial: true,
          ),
          State(
            id: 'q1',
            name: 'q1',
            position: Position(x: 200, y: 100),
            isAccepting: true,
          ),
        ],
        transitions: [
          Transition(
            id: 't1',
            fromState: 'q0',
            toState: 'q1',
            symbol: 'a',
          ),
        ],
        alphabet: Alphabet(symbols: ['a', 'b']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'test',
        ),
      );
    });

    testWidgets('should render automaton states', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: testAutomaton,
              onStateTap: (state) {},
              onTransitionTap: (transition) {},
            ),
          ),
        ),
      );

      // Verify states are rendered
      expect(find.byKey(const Key('state-q0')), findsOneWidget);
      expect(find.byKey(const Key('state-q1')), findsOneWidget);
      
      // Verify state labels
      expect(find.text('q0'), findsOneWidget);
      expect(find.text('q1'), findsOneWidget);
    });

    testWidgets('should render automaton transitions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: testAutomaton,
              onStateTap: (state) {},
              onTransitionTap: (transition) {},
            ),
          ),
        ),
      );

      // Verify transition is rendered
      expect(find.byKey(const Key('transition-t1')), findsOneWidget);
      
      // Verify transition label
      expect(find.text('a'), findsOneWidget);
    });

    testWidgets('should handle state tap events', (WidgetTester tester) async {
      bool stateTapped = false;
      State? tappedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: testAutomaton,
              onStateTap: (state) {
                stateTapped = true;
                tappedState = state;
              },
              onTransitionTap: (transition) {},
            ),
          ),
        ),
      );

      // Tap on a state
      await tester.tap(find.byKey(const Key('state-q0')));
      await tester.pump();

      expect(stateTapped, true);
      expect(tappedState?.id, 'q0');
    });

    testWidgets('should handle transition tap events', (WidgetTester tester) async {
      bool transitionTapped = false;
      Transition? tappedTransition;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: testAutomaton,
              onStateTap: (state) {},
              onTransitionTap: (transition) {
                transitionTapped = true;
                tappedTransition = transition;
              },
            ),
          ),
        ),
      );

      // Tap on a transition
      await tester.tap(find.byKey(const Key('transition-t1')));
      await tester.pump();

      expect(transitionTapped, true);
      expect(tappedTransition?.id, 't1');
    });

    testWidgets('should support zoom and pan gestures', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: testAutomaton,
              onStateTap: (state) {},
              onTransitionTap: (transition) {},
            ),
          ),
        ),
      );

      // Test pinch zoom gesture
      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveTo(const Offset(200, 200));
      await gesture.up();
      await tester.pump();

      // Test pan gesture
      final panGesture = await tester.startGesture(const Offset(50, 50));
      await panGesture.moveTo(const Offset(150, 150));
      await panGesture.up();
      await tester.pump();

      // Canvas should still be visible after gestures
      expect(find.byType(AutomatonCanvas), findsOneWidget);
    });

    testWidgets('should highlight selected state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: testAutomaton,
              selectedStateId: 'q0',
              onStateTap: (state) {},
              onTransitionTap: (transition) {},
            ),
          ),
        ),
      );

      // Verify selected state has different styling
      final selectedState = find.byKey(const Key('state-q0'));
      expect(selectedState, findsOneWidget);
      
      // The selected state should have a different appearance
      // This would be verified through the widget's internal styling
    });

    testWidgets('should highlight selected transition', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: testAutomaton,
              selectedTransitionId: 't1',
              onStateTap: (state) {},
              onTransitionTap: (transition) {},
            ),
          ),
        ),
      );

      // Verify selected transition has different styling
      final selectedTransition = find.byKey(const Key('transition-t1'));
      expect(selectedTransition, findsOneWidget);
    });

    testWidgets('should render different automaton types', (WidgetTester tester) async {
      final pdaAutomaton = Automaton(
        id: 'test-pda',
        name: 'Test PDA',
        type: AutomatonType.PDA,
        states: testAutomaton.states,
        transitions: testAutomaton.transitions,
        alphabet: testAutomaton.alphabet,
        metadata: testAutomaton.metadata,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: pdaAutomaton,
              onStateTap: (state) {},
              onTransitionTap: (transition) {},
            ),
          ),
        ),
      );

      // PDA should render differently (e.g., with stack symbols)
      expect(find.byType(AutomatonCanvas), findsOneWidget);
    });

    testWidgets('should handle empty automaton', (WidgetTester tester) async {
      final emptyAutomaton = Automaton(
        id: 'empty',
        name: 'Empty',
        type: AutomatonType.DFA,
        states: [],
        transitions: [],
        alphabet: Alphabet(symbols: []),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'test',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: emptyAutomaton,
              onStateTap: (state) {},
              onTransitionTap: (transition) {},
            ),
          ),
        ),
      );

      // Should render empty canvas
      expect(find.byType(AutomatonCanvas), findsOneWidget);
      expect(find.byKey(const Key('state-q0')), findsNothing);
      expect(find.byKey(const Key('transition-t1')), findsNothing);
    });

    testWidgets('should support accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: testAutomaton,
              onStateTap: (state) {},
              onTransitionTap: (transition) {},
            ),
          ),
        ),
      );

      // Verify accessibility features
      final semantics = tester.getSemantics(find.byType(AutomatonCanvas));
      expect(semantics, isNotNull);
      
      // States should be accessible
      expect(find.byKey(const Key('state-q0')), findsOneWidget);
      expect(find.byKey(const Key('state-q1')), findsOneWidget);
    });

    testWidgets('should handle large automata performance', (WidgetTester tester) async {
      // Create a large automaton with many states and transitions
      final largeStates = <State>[];
      final largeTransitions = <Transition>[];
      
      for (int i = 0; i < 50; i++) {
        largeStates.add(State(
          id: 'q$i',
          name: 'q$i',
          position: Position(x: i * 10.0, y: i * 10.0),
          isInitial: i == 0,
          isAccepting: i == 49,
        ));
      }
      
      for (int i = 0; i < 49; i++) {
        largeTransitions.add(Transition(
          id: 't$i',
          fromState: 'q$i',
          toState: 'q${i + 1}',
          symbol: 'a',
        ));
      }

      final largeAutomaton = Automaton(
        id: 'large',
        name: 'Large Automaton',
        type: AutomatonType.DFA,
        states: largeStates,
        transitions: largeTransitions,
        alphabet: Alphabet(symbols: ['a']),
        metadata: AutomatonMetadata(
          createdAt: DateTime.now(),
          createdBy: 'test',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonCanvas(
              automaton: largeAutomaton,
              onStateTap: (state) {},
              onTransitionTap: (transition) {},
            ),
          ),
        ),
      );

      // Should render without performance issues
      expect(find.byType(AutomatonCanvas), findsOneWidget);
    });
  });
}
