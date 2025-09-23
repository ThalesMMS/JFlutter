import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import 'package:jflutter/presentation/providers/tm_metrics_controller.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('TmMetricsController', () {
    test('exposes empty metrics when editor has no TM', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final metrics = container.read(tmMetricsControllerProvider);

      expect(metrics.hasMachine, isFalse);
      expect(metrics.isMachineReady, isFalse);
      expect(metrics.stateCount, 0);
      expect(metrics.transitionCount, 0);
      expect(metrics.tapeSymbols, isEmpty);
    });

    test('updates metrics when editor state changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final tm = _buildSampleTM();
      final notifier = container.read(tmEditorProvider.notifier);

      notifier.state = TMEditorState(
        tm: tm,
        tapeSymbols: {'B', 'a'},
        moveDirections: {'right'},
        nondeterministicTransitionIds: {'t0'},
      );

      final metrics = container.read(tmMetricsControllerProvider);

      expect(metrics.tm, same(tm));
      expect(metrics.stateCount, 2);
      expect(metrics.transitionCount, 1);
      expect(metrics.tapeSymbols, unorderedEquals(['B', 'a']));
      expect(metrics.moveDirections, contains('RIGHT'));
      expect(metrics.hasMachine, isTrue);
      expect(metrics.isMachineReady, isTrue);
      expect(metrics.nondeterministicTransitionIds, contains('t0'));

      notifier.state = const TMEditorState();
      final cleared = container.read(tmMetricsControllerProvider);
      expect(cleared.hasMachine, isFalse);
      expect(cleared.stateCount, 0);
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
