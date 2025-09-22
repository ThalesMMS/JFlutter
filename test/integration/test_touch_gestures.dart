import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/presentation/widgets/touch_gesture_handler.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('Touch Gesture Handler Tests', () {
    late List<automaton_state.State> testStates;
    late List<FSATransition> testTransitions;
    late automaton_state.State? selectedState;
    late List<automaton_state.State?> stateSelectedCalls;
    late List<automaton_state.State> stateMovedCalls;
    late List<Offset> stateAddedCalls;
    late List<({automaton_state.State from, automaton_state.State to})>
        transitionAddedCalls;
    late List<automaton_state.State> stateEditedCalls;
    late List<automaton_state.State> stateDeletedCalls;
    late List<FSATransition> transitionDeletedCalls;

    setUp(() {
      testStates = [
        automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2(100, 100),
          isInitial: true,
          isAccepting: false,
        ),
        automaton_state.State(
          id: 'q1',
          label: 'q1',
          position: Vector2(200, 100),
          isInitial: false,
          isAccepting: true,
        ),
      ];

      testTransitions = [
        FSATransition(
          id: 't0',
          fromState: testStates[0],
          toState: testStates[1],
          label: 'a',
          inputSymbols: {'a'},
        ),
      ];

      selectedState = null;
      stateSelectedCalls = [];
      stateMovedCalls = [];
      stateAddedCalls = [];
      transitionAddedCalls = [];
      stateEditedCalls = [];
      stateDeletedCalls = [];
      transitionDeletedCalls = [];
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: TouchGestureHandler(
            states: testStates,
            transitions: testTransitions,
            selectedState: selectedState,
            onStateSelected: (state) {
              stateSelectedCalls.add(state);
            },
            onStateMoved: (state) {
              stateMovedCalls.add(state);
            },
            onStateAdded: (position) {
              stateAddedCalls.add(position);
            },
            onTransitionAdded: (from, to) {
              transitionAddedCalls.add((from: from, to: to));
            },
            onStateEdited: (state) {
              stateEditedCalls.add(state);
            },
            onStateDeleted: (state) {
              stateDeletedCalls.add(state);
            },
            onTransitionDeleted: (transition) {
              transitionDeletedCalls.add(transition);
            },
            child: Container(
              width: 400,
              height: 400,
              color: Colors.grey[200],
            ),
          ),
        ),
      );
    }

    testWidgets('should handle tap to select state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap on first state
      await tester.tapAt(const Offset(100, 100));
      await tester.pump();

      expect(stateSelectedCalls.length, equals(1));
      expect(stateSelectedCalls.first?.id, equals('q0'));
    });

    testWidgets('should handle tap on empty space', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap on empty space
      await tester.tapAt(const Offset(50, 50));
      await tester.pump();

      expect(stateSelectedCalls.length, equals(1));
      expect(stateSelectedCalls.first, isNull);
    });

    testWidgets('should handle double tap to edit state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Double tap on first state
      await tester.tapAt(const Offset(100, 100));
      await tester.pump();
      await tester.tapAt(const Offset(100, 100));
      await tester.pump();

      expect(stateEditedCalls.length, equals(1));
      expect(stateEditedCalls.first.id, equals('q0'));
    });

    testWidgets('should handle long press for context menu', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Long press on first state
      await tester.longPressAt(const Offset(100, 100));
      await tester.pump(const Duration(milliseconds: 600));

      // Context menu should appear
      expect(find.text('Edit State'), findsOneWidget);
      expect(find.text('Delete State'), findsOneWidget);
    });

    testWidgets('should handle drag to move state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Start drag from first state
      final gesture = await tester.startGesture(const Offset(100, 100));
      await tester.pump();
      
      // Drag to new position
      await gesture.moveTo(const Offset(150, 150));
      await tester.pump();
      
      // End drag
      await gesture.up();
      await tester.pump();

      expect(stateMovedCalls.length, equals(1));
      expect(stateMovedCalls.first.id, equals('q0'));
    });

    testWidgets('should handle pinch to zoom', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Start pinch gesture
      final gesture1 = await tester.startGesture(const Offset(100, 100));
      final gesture2 = await tester.startGesture(const Offset(200, 200));
      await tester.pump();

      // Move gestures apart to zoom in
      await gesture1.moveTo(const Offset(50, 50));
      await gesture2.moveTo(const Offset(250, 250));
      await tester.pump();

      // End gestures
      await gesture1.up();
      await gesture2.up();
      await tester.pump();

      // Widget should still be rendered (no crashes)
      expect(find.byType(TouchGestureHandler), findsOneWidget);
    });

    testWidgets('should show context menu on long press empty space', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Long press on empty space
      await tester.longPressAt(const Offset(50, 50));
      await tester.pump(const Duration(milliseconds: 600));

      // Context menu should appear with "Add State" option
      expect(find.text('Add State'), findsOneWidget);
    });

    testWidgets('should close context menu when tapping outside', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Long press to show context menu
      await tester.longPressAt(const Offset(100, 100));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Edit State'), findsOneWidget);

      // Tap outside to close
      await tester.tapAt(const Offset(300, 300));
      await tester.pump();

      expect(find.text('Edit State'), findsNothing);
    });
  });
}
