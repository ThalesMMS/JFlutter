import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/presentation/pages/tm_page.dart';
import 'package:jflutter/presentation/widgets/tm_canvas.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('TMPage', () {
    testWidgets('updates metadata when TMCanvas notifies about changes',
        (tester) async {
      binding.window.physicalSizeTestValue = const Size(900, 1600);
      binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        binding.window.clearPhysicalSizeTestValue();
        binding.window.clearDevicePixelRatioTestValue();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TMPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final simulateButtonFinder =
          find.widgetWithText(ElevatedButton, 'Simulate');
      final algorithmButtonFinder =
          find.widgetWithText(ElevatedButton, 'Algorithms');

      final simulateButtonInitial =
          tester.widget<ElevatedButton>(simulateButtonFinder);
      expect(simulateButtonInitial.onPressed, isNull);

      final algorithmButtonInitial =
          tester.widget<ElevatedButton>(algorithmButtonFinder);
      expect(algorithmButtonInitial.onPressed, isNull);

      final tmCanvas = tester.widget<TMCanvas>(find.byType(TMCanvas));
      final tm = _buildSampleTM();

      tmCanvas.onTMModified(tm);
      await tester.pumpAndSettle();

      expect(find.text('States: 2'), findsOneWidget);
      expect(find.text('Transitions: 1'), findsOneWidget);
      expect(find.text('Tape Symbols: B, a'), findsOneWidget);
      expect(find.text('Move Directions: RIGHT'), findsOneWidget);
      expect(find.text('Simulation Ready: Yes'), findsOneWidget);

      final simulateButtonUpdated =
          tester.widget<ElevatedButton>(simulateButtonFinder);
      expect(simulateButtonUpdated.onPressed, isNotNull);

      final algorithmButtonUpdated =
          tester.widget<ElevatedButton>(algorithmButtonFinder);
      expect(algorithmButtonUpdated.onPressed, isNotNull);
    });
  });
}

TM _buildSampleTM() {
  final initialState = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );

  final acceptingState = automaton_state.State(
    id: 'q1',
    label: 'q1',
    position: Vector2(150, 0),
    isAccepting: true,
  );

  final transition = TMTransition(
    id: 't0',
    fromState: initialState,
    toState: acceptingState,
    label: 'a',
    readSymbol: 'a',
    writeSymbol: 'a',
    direction: TapeDirection.right,
  );

  const bounds = math.Rectangle<double>(0, 0, 400, 400);
  final now = DateTime(2024, 1, 1);

  return TM(
    id: 'test',
    name: 'Test TM',
    states: {initialState, acceptingState},
    transitions: {transition},
    alphabet: {'a'},
    initialState: initialState,
    acceptingStates: {acceptingState},
    created: now,
    modified: now,
    bounds: bounds,
    tapeAlphabet: {'B', 'a'},
    blankSymbol: 'B',
    tapeCount: 1,
    zoomLevel: 1,
    panOffset: Vector2.zero(),
  );
}
