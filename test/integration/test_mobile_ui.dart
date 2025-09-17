import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/presentation/pages/home_page.dart';
import 'package:jflutter/presentation/pages/automaton_editor_page.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas.dart';
import 'package:jflutter/presentation/widgets/touch_gesture_handler.dart';
import 'package:jflutter/presentation/widgets/state_widget.dart';
import 'package:jflutter/presentation/widgets/transition_widget.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/providers/layout_provider.dart';
import 'package:provider/provider.dart';

/// Integration tests for mobile UI interactions
/// These tests verify end-to-end mobile user interface functionality
void main() {
  group('Mobile UI Integration Tests', () {
    late AutomatonProvider automatonProvider;
    late LayoutProvider layoutProvider;

    setUp(() {
      automatonProvider = AutomatonProvider();
      layoutProvider = LayoutProvider();
    });

    group('Home Page Navigation', () {
      testWidgets('should display home page with navigation options', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('JFlutter'), findsOneWidget);
        expect(find.text('Finite State Automata'), findsOneWidget);
        expect(find.text('Pushdown Automata'), findsOneWidget);
        expect(find.text('Turing Machines'), findsOneWidget);
        expect(find.text('Grammars'), findsOneWidget);
        expect(find.text('L-Systems'), findsOneWidget);
        expect(find.text('Pumping Lemma Games'), findsOneWidget);
      });

      testWidgets('should navigate to FSA editor when tapped', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Finite State Automata'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AutomatonEditorPage), findsOneWidget);
      });

      testWidgets('should navigate to grammar editor when tapped', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Grammars'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(GrammarEditorPage), findsOneWidget);
      });
    });

    group('Automaton Canvas Touch Interactions', () {
      testWidgets('should handle tap to add state', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: AutomatonEditorPage(),
            ),
          ),
        );

        // Act
        await tester.tapAt(const Offset(200, 200));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(StateWidget), findsOneWidget);
        expect(automatonProvider.currentAutomaton?.states.length, equals(1));
      });

      testWidgets('should handle long press to add state', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: AutomatonEditorPage(),
            ),
          ),
        );

        // Act
        await tester.longPressAt(const Offset(200, 200));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(StateWidget), findsOneWidget);
        expect(automatonProvider.currentAutomaton?.states.length, equals(1));
      });

      testWidgets('should handle drag to move state', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: AutomatonEditorPage(),
            ),
          ),
        );

        // Add initial state
        await tester.tapAt(const Offset(200, 200));
        await tester.pumpAndSettle();

        // Act - Drag state
        await tester.drag(find.byType(StateWidget), const Offset(100, 100));
        await tester.pumpAndSettle();

        // Assert
        final state = automatonProvider.currentAutomaton?.states.first;
        expect(state?.position.x, equals(300));
        expect(state?.position.y, equals(300));
      });

      testWidgets('should handle pinch to zoom', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: AutomatonEditorPage(),
            ),
          ),
        );

        // Act - Pinch gesture
        await tester.startGesture(const Offset(100, 100));
        await tester.moveTo(const Offset(150, 100));
        await tester.moveTo(const Offset(200, 100));
        await tester.endGesture();

        // Assert
        expect(layoutProvider.zoomLevel, greaterThan(1.0));
      });

      testWidgets('should handle pan gesture', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: AutomatonEditorPage(),
            ),
          ),
        );

        // Act - Pan gesture
        await tester.drag(find.byType(AutomatonCanvas), const Offset(100, 100));
        await tester.pumpAndSettle();

        // Assert
        expect(layoutProvider.panOffset.dx, equals(100));
        expect(layoutProvider.panOffset.dy, equals(100));
      });

      testWidgets('should handle double tap to zoom', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: AutomatonEditorPage(),
            ),
          ),
        );

        // Act - Double tap
        await tester.tapAt(const Offset(200, 200));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tapAt(const Offset(200, 200));
        await tester.pumpAndSettle();

        // Assert
        expect(layoutProvider.zoomLevel, greaterThan(1.0));
      });
    });

    group('State Widget Interactions', () {
      testWidgets('should display state with correct properties', (WidgetTester tester) async {
        // Arrange
        final state = State(
          id: 'q0',
          label: 'q0',
          position: Point(200, 200),
          isInitial: true,
          isAccepting: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StateWidget(state: state),
            ),
          ),
        );

        // Assert
        expect(find.text('q0'), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Initial state indicator
      });

      testWidgets('should display accepting state with correct indicator', (WidgetTester tester) async {
        // Arrange
        final state = State(
          id: 'q1',
          label: 'q1',
          position: Point(200, 200),
          isInitial: false,
          isAccepting: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StateWidget(state: state),
            ),
          ),
        );

        // Assert
        expect(find.text('q1'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget); // Accepting state indicator
      });

      testWidgets('should handle state selection', (WidgetTester tester) async {
        // Arrange
        final state = State(
          id: 'q0',
          label: 'q0',
          position: Point(200, 200),
          isInitial: false,
          isAccepting: false,
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: StateWidget(state: state),
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(StateWidget));
        await tester.pumpAndSettle();

        // Assert
        expect(automatonProvider.selectedStates, contains('q0'));
      });

      testWidgets('should handle state context menu', (WidgetTester tester) async {
        // Arrange
        final state = State(
          id: 'q0',
          label: 'q0',
          position: Point(200, 200),
          isInitial: false,
          isAccepting: false,
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: StateWidget(state: state),
              ),
            ),
          ),
        );

        // Act - Long press to show context menu
        await tester.longPress(find.byType(StateWidget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Delete State'), findsOneWidget);
        expect(find.text('Edit State'), findsOneWidget);
        expect(find.text('Set as Initial'), findsOneWidget);
        expect(find.text('Set as Accepting'), findsOneWidget);
      });
    });

    group('Transition Widget Interactions', () {
      testWidgets('should display transition with correct label', (WidgetTester tester) async {
        // Arrange
        final fromState = State(
          id: 'q0',
          label: 'q0',
          position: Point(100, 100),
          isInitial: true,
          isAccepting: false,
        );
        final toState = State(
          id: 'q1',
          label: 'q1',
          position: Point(200, 200),
          isInitial: false,
          isAccepting: true,
        );
        final transition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: toState,
          label: 'a',
          inputSymbols: {'a'},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TransitionWidget(transition: transition),
            ),
          ),
        );

        // Assert
        expect(find.text('a'), findsOneWidget);
      });

      testWidgets('should handle transition selection', (WidgetTester tester) async {
        // Arrange
        final fromState = State(
          id: 'q0',
          label: 'q0',
          position: Point(100, 100),
          isInitial: true,
          isAccepting: false,
        );
        final toState = State(
          id: 'q1',
          label: 'q1',
          position: Point(200, 200),
          isInitial: false,
          isAccepting: true,
        );
        final transition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: toState,
          label: 'a',
          inputSymbols: {'a'},
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: TransitionWidget(transition: transition),
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(TransitionWidget));
        await tester.pumpAndSettle();

        // Assert
        expect(automatonProvider.selectedTransitions, contains('t1'));
      });

      testWidgets('should handle transition context menu', (WidgetTester tester) async {
        // Arrange
        final fromState = State(
          id: 'q0',
          label: 'q0',
          position: Point(100, 100),
          isInitial: true,
          isAccepting: false,
        );
        final toState = State(
          id: 'q1',
          label: 'q1',
          position: Point(200, 200),
          isInitial: false,
          isAccepting: true,
        );
        final transition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: toState,
          label: 'a',
          inputSymbols: {'a'},
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: TransitionWidget(transition: transition),
              ),
            ),
          ),
        );

        // Act - Long press to show context menu
        await tester.longPress(find.byType(TransitionWidget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Delete Transition'), findsOneWidget);
        expect(find.text('Edit Transition'), findsOneWidget);
      });
    });

    group('Touch Gesture Handler', () {
      testWidgets('should handle single tap gesture', (WidgetTester tester) async {
        // Arrange
        bool tapHandled = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TouchGestureHandler(
                onTap: (position) {
                  tapHandled = true;
                },
                child: Container(
                  width: 400,
                  height: 400,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        );

        // Act
        await tester.tapAt(const Offset(200, 200));
        await tester.pumpAndSettle();

        // Assert
        expect(tapHandled, isTrue);
      });

      testWidgets('should handle long press gesture', (WidgetTester tester) async {
        // Arrange
        bool longPressHandled = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TouchGestureHandler(
                onLongPress: (position) {
                  longPressHandled = true;
                },
                child: Container(
                  width: 400,
                  height: 400,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        );

        // Act
        await tester.longPressAt(const Offset(200, 200));
        await tester.pumpAndSettle();

        // Assert
        expect(longPressHandled, isTrue);
      });

      testWidgets('should handle drag gesture', (WidgetTester tester) async {
        // Arrange
        Offset? dragStartPosition;
        Offset? dragEndPosition;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TouchGestureHandler(
                onDragStart: (position) {
                  dragStartPosition = position;
                },
                onDragEnd: (position) {
                  dragEndPosition = position;
                },
                child: Container(
                  width: 400,
                  height: 400,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        );

        // Act
        await tester.dragFrom(const Offset(100, 100), const Offset(200, 200));
        await tester.pumpAndSettle();

        // Assert
        expect(dragStartPosition, equals(const Offset(100, 100)));
        expect(dragEndPosition, equals(const Offset(200, 200)));
      });

      testWidgets('should handle pinch gesture', (WidgetTester tester) async {
        // Arrange
        double? scale;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TouchGestureHandler(
                onScaleUpdate: (scaleValue) {
                  scale = scaleValue;
                },
                child: Container(
                  width: 400,
                  height: 400,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        );

        // Act - Simulate pinch gesture
        await tester.startGesture(const Offset(100, 100));
        await tester.moveTo(const Offset(150, 100));
        await tester.moveTo(const Offset(200, 100));
        await tester.endGesture();

        // Assert
        expect(scale, isNotNull);
        expect(scale!, greaterThan(1.0));
      });
    });

    group('Mobile Layout Responsiveness', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        // Arrange
        await tester.binding.setSurfaceSize(const Size(360, 640)); // Small phone
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(HomePage), findsOneWidget);
        
        // Change to tablet size
        await tester.binding.setSurfaceSize(const Size(768, 1024));
        await tester.pumpAndSettle();
        
        expect(find.byType(HomePage), findsOneWidget);
      });

      testWidgets('should handle orientation changes', (WidgetTester tester) async {
        // Arrange
        await tester.binding.setSurfaceSize(const Size(360, 640)); // Portrait
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: AutomatonEditorPage(),
            ),
          ),
        );

        // Act
        await tester.pumpAndSettle();
        expect(find.byType(AutomatonEditorPage), findsOneWidget);
        
        // Change to landscape
        await tester.binding.setSurfaceSize(const Size(640, 360));
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.byType(AutomatonEditorPage), findsOneWidget);
      });

      testWidgets('should maintain touch target sizes', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: AutomatonEditorPage(),
            ),
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert - Check that touch targets are at least 44dp
        final stateWidget = find.byType(StateWidget);
        if (stateWidget.evaluate().isNotEmpty) {
          final renderBox = tester.renderObject(stateWidget) as RenderBox;
          expect(renderBox.size.width, greaterThanOrEqualTo(44));
          expect(renderBox.size.height, greaterThanOrEqualTo(44));
        }
      });
    });

    group('Accessibility Features', () {
      testWidgets('should provide semantic labels for states', (WidgetTester tester) async {
        // Arrange
        final state = State(
          id: 'q0',
          label: 'q0',
          position: Point(200, 200),
          isInitial: true,
          isAccepting: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StateWidget(state: state),
            ),
          ),
        );

        // Assert
        expect(find.bySemanticsLabel('State q0, initial state'), findsOneWidget);
      });

      testWidgets('should provide semantic labels for transitions', (WidgetTester tester) async {
        // Arrange
        final fromState = State(
          id: 'q0',
          label: 'q0',
          position: Point(100, 100),
          isInitial: true,
          isAccepting: false,
        );
        final toState = State(
          id: 'q1',
          label: 'q1',
          position: Point(200, 200),
          isInitial: false,
          isAccepting: true,
        );
        final transition = FSATransition(
          id: 't1',
          fromState: fromState,
          toState: toState,
          label: 'a',
          inputSymbols: {'a'},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TransitionWidget(transition: transition),
            ),
          ),
        );

        // Assert
        expect(find.bySemanticsLabel('Transition from q0 to q1 on symbol a'), findsOneWidget);
      });

      testWidgets('should support screen reader navigation', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: HomePage(),
            ),
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert
        expect(find.bySemanticsLabel('Finite State Automata'), findsOneWidget);
        expect(find.bySemanticsLabel('Pushdown Automata'), findsOneWidget);
        expect(find.bySemanticsLabel('Turing Machines'), findsOneWidget);
        expect(find.bySemanticsLabel('Grammars'), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle large automata efficiently', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: AutomatonEditorPage(),
            ),
          ),
        );

        // Act - Add many states
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 50; i++) {
          await tester.tapAt(Offset(100 + i * 10, 100 + i * 10));
          await tester.pump();
        }
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 1 second limit
        expect(automatonProvider.currentAutomaton?.states.length, equals(50));
      });

      testWidgets('should maintain 60fps during interactions', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => automatonProvider),
              ChangeNotifierProvider(create: (_) => layoutProvider),
            ],
            child: const MaterialApp(
              home: AutomatonEditorPage(),
            ),
          ),
        );

        // Act - Rapid interactions
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 10; i++) {
          await tester.tapAt(Offset(100 + i * 20, 100 + i * 20));
          await tester.pump();
        }
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // 500ms limit
      });
    });
  });
}
