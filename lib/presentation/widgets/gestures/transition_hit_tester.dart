import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/models/transition.dart';
import '../transition_geometry.dart';

/// Provides hit testing utilities for automaton transitions and self-loops.
class TransitionHitTester<T extends Transition> {
  const TransitionHitTester({
    required this.stateRadius,
    required this.selfLoopBaseRadius,
    required this.selfLoopSpacing,
    this.hitTolerance = 18.0,
  });

  final double stateRadius;
  final double selfLoopBaseRadius;
  final double selfLoopSpacing;
  final double hitTolerance;

  /// Finds the first transition intersecting the provided [point].
  T? findTransitionAt(Offset point, List<T> transitions) {
    for (final transition in transitions) {
      if (isPointOnTransition(point, transition, transitions)) {
        return transition;
      }
    }
    return null;
  }

  /// Determines if [point] lies on [transition].
  bool isPointOnTransition(Offset point, T transition, List<T> transitions) {
    if (transition.fromState == transition.toState) {
      return isPointOnSelfLoop(point, transition, transitions);
    }

    final curve = TransitionCurve.compute(
      transitions,
      transition,
      stateRadius: stateRadius,
      curvatureStrength: 45,
      labelOffset: 16,
    );

    return _distanceToQuadratic(point, curve.start, curve.control, curve.end) <=
        hitTolerance;
  }

  /// Determines if [point] lies on the self-loop represented by [transition].
  bool isPointOnSelfLoop(Offset point, T transition, List<T> transitions) {
    final center = Offset(
      transition.fromState.position.x,
      transition.fromState.position.y,
    );
    final loops = transitions
        .where((t) =>
            t.fromState.id == transition.fromState.id &&
            t.fromState == t.toState)
        .toList();
    final index = loops.indexOf(transition);
    final radius = selfLoopBaseRadius + index * selfLoopSpacing;
    final loopCenter = Offset(center.dx, center.dy - radius);

    final distance = (point - loopCenter).distance;
    if ((distance - radius).abs() > hitTolerance) {
      return false;
    }

    final angle = math.atan2(point.dy - loopCenter.dy, point.dx - loopCenter.dx);
    final normalized = _normalizeAngle(angle);
    final start = _normalizeAngle(1.1 * math.pi);
    final end = start + 1.6 * math.pi;
    final adjusted = normalized < start ? normalized + 2 * math.pi : normalized;
    return adjusted >= start && adjusted <= end;
  }

  double _distanceToQuadratic(
    Offset point,
    Offset start,
    Offset control,
    Offset end,
  ) {
    double minDistance = double.infinity;
    const segments = 24;
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final sample = TransitionCurve.pointAt(start, control, end, t);
      final distance = (point - sample).distance;
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance;
  }

  double _normalizeAngle(double angle) {
    var a = angle;
    while (a < 0) {
      a += 2 * math.pi;
    }
    while (a >= 2 * math.pi) {
      a -= 2 * math.pi;
    }
    return a;
  }
}
