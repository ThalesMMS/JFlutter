import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/presentation/widgets/gestures/transition_hit_tester.dart';
import 'package:jflutter/presentation/widgets/transition_geometry.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('TransitionHitTester', () {
    late automaton_state.State q0;
    late automaton_state.State q1;
    late List<FSATransition> transitions;

    setUp(() {
      q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(100, 100),
        isInitial: true,
        isAccepting: false,
      );
      q1 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(200, 100),
        isInitial: false,
        isAccepting: false,
      );
      transitions = [
        FSATransition(
          id: 't0',
          fromState: q0,
          toState: q1,
          label: 'a',
          inputSymbols: {'a'},
        ),
        FSATransition(
          id: 'self',
          fromState: q0,
          toState: q0,
          label: 'b',
          inputSymbols: {'b'},
        ),
      ];
    });

    test('detects hits on linear transitions', () {
      final tester = TransitionHitTester<FSATransition>(
        stateRadius: 30,
        selfLoopBaseRadius: 40,
        selfLoopSpacing: 12,
      );

      final curve = TransitionCurve.compute(
        transitions,
        transitions.first,
        stateRadius: 30,
        curvatureStrength: 45,
        labelOffset: 16,
      );
      final midpoint = TransitionCurve.pointAt(
        curve.start,
        curve.control,
        curve.end,
        0.5,
      );

      final hit = tester.findTransitionAt(midpoint, transitions);
      expect(hit, equals(transitions.first));
    });

    test('detects hits on self loops', () {
      final tester = TransitionHitTester<FSATransition>(
        stateRadius: 30,
        selfLoopBaseRadius: 40,
        selfLoopSpacing: 12,
      );

      final radius = 40.0;
      final loopCenter = Offset(q0.position.x, q0.position.y - radius);
      final angle = 1.5 * math.pi;
      final pointOnLoop = Offset(
        loopCenter.dx + radius * math.cos(angle),
        loopCenter.dy + radius * math.sin(angle),
      );

      final hit = tester.findTransitionAt(pointOnLoop, transitions);
      expect(hit?.id, equals('self'));
    });

    test('returns null when no transition is hit', () {
      final tester = TransitionHitTester<FSATransition>(
        stateRadius: 30,
        selfLoopBaseRadius: 40,
        selfLoopSpacing: 12,
      );

      final hit = tester.findTransitionAt(const Offset(10, 10), transitions);
      expect(hit, isNull);
    });
  });
}
