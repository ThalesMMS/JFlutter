import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/presentation/pages/tm_page.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('TMPage', () {
    testWidgets('updates metadata when editor changes', (tester) async {
      binding.window.physicalSizeTestValue = const Size(900, 1600);
      binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        binding.window.clearPhysicalSizeTestValue();
        binding.window.clearDevicePixelRatioTestValue();
      });

      final scopeKey = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          key: scopeKey,
          child: const MaterialApp(
            home: TMPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final simulateButtonFinder =
          find.widgetWithText(ElevatedButton, 'Simulate');
      final algorithmButtonFinder =
          find.widgetWithText(ElevatedButton, 'Algorithms');
      final metricsButtonFinder =
          find.widgetWithText(ElevatedButton, 'Metrics');

      final simulateButtonInitial =
          tester.widget<ElevatedButton>(simulateButtonFinder);
      expect(simulateButtonInitial.onPressed, isNull);

      final algorithmButtonInitial =
          tester.widget<ElevatedButton>(algorithmButtonFinder);
      expect(algorithmButtonInitial.onPressed, isNull);

      final container =
          ProviderScope.containerOf(scopeKey.currentContext!, listen: false);
      final tm = _buildSampleTM();

      container.read(tmEditorProvider.notifier).state = TMEditorState(
        tm: tm,
        tapeSymbols: {'B', 'a'},
        moveDirections: {'right'},
      );

      await tester.pumpAndSettle();

      final simulateButtonUpdated =
          tester.widget<ElevatedButton>(simulateButtonFinder);
      expect(simulateButtonUpdated.onPressed, isNotNull);

      final algorithmButtonUpdated =
          tester.widget<ElevatedButton>(algorithmButtonFinder);
      expect(algorithmButtonUpdated.onPressed, isNotNull);

      await tester.tap(metricsButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('States: 2'), findsOneWidget);
      expect(find.text('Transitions: 1'), findsOneWidget);
      expect(find.text('Tape Symbols: B, a'), findsOneWidget);
      expect(find.text('Move Directions: RIGHT'), findsOneWidget);
      expect(find.text('Simulation Ready: Yes'), findsOneWidget);
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
