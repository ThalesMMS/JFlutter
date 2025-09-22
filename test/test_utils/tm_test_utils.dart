import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_analysis.dart';
import 'package:jflutter/core/models/tm_transition.dart';

class TmTestData {
  static TM createTm() {
    final initial = State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
    );
    final accept = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(50, 0),
      isAccepting: true,
    );

    final transition = TMTransition(
      id: 't0',
      fromState: initial,
      toState: accept,
      label: '1',
      readSymbol: '1',
      writeSymbol: '1',
      direction: TapeDirection.right,
    );

    final now = DateTime(2024, 1, 1);

    return TM(
      id: 'tm1',
      name: 'Test TM',
      states: {initial, accept},
      transitions: {transition},
      alphabet: {'1'},
      initialState: initial,
      acceptingStates: {accept},
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 100, 100),
      tapeAlphabet: {'B', '1'},
      blankSymbol: 'B',
      tapeCount: 1,
      zoomLevel: 1,
      panOffset: Vector2.zero(),
    );
  }

  static TMAnalysis createAnalysis(TM tm) {
    final initial = tm.initialState!;
    final accept = tm.acceptingStates.first;

    return TMAnalysis(
      stateAnalysis: const TMStateAnalysis(
        totalStates: 2,
        acceptingStates: 1,
        nonAcceptingStates: 1,
      ),
      transitionAnalysis: const TMTransitionAnalysis(
        totalTransitions: 1,
        tmTransitions: 1,
        fsaTransitions: 0,
      ),
      tapeAnalysis: const TapeAnalysis(
        writeOperations: {'1'},
        readOperations: {'1'},
        moveDirections: {'right'},
        tapeSymbols: {'B', '1'},
      ),
      reachabilityAnalysis: TMReachabilityAnalysis(
        reachableStates: {initial, accept},
        unreachableStates: {},
      ),
      executionTime: const Duration(milliseconds: 2),
    );
  }
}
