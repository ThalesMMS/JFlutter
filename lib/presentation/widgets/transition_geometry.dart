import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/transition.dart';

/// Geometry helper for drawing curved transitions without overlaps.
class TransitionCurve {
  final Offset start;
  final Offset control;
  final Offset end;
  final Offset labelPosition;
  final double tangentAngle;

  const TransitionCurve({
    required this.start,
    required this.control,
    required this.end,
    required this.labelPosition,
    required this.tangentAngle,
  });

  /// Computes geometry for the [current] transition relative to [transitions].
  static TransitionCurve compute<T extends Transition>(
    List<T> transitions,
    T current, {
    required double stateRadius,
    double curvatureStrength = 45,
    double labelOffset = 16,
  }) {
    final from =
        Offset(current.fromState.position.x, current.fromState.position.y);
    final to = Offset(current.toState.position.x, current.toState.position.y);
    final direction = to - from;
    final distance = direction.distance;
    final unit = distance == 0
        ? const Offset(1, 0)
        : Offset(direction.dx / distance, direction.dy / distance);

    final start = from + unit * stateRadius;
    final end = to - unit * stateRadius;

    final orderedGroup = transitions
        .where((t) =>
            t.fromState.id == current.fromState.id &&
            t.toState.id == current.toState.id &&
            t.fromState != t.toState)
        .toList();
    final orderedIndex = orderedGroup.indexOf(current);
    final orderedTotal = orderedGroup.length;

    final unorderedTotal = transitions
        .where((t) =>
            t.fromState != t.toState &&
            ((t.fromState.id == current.fromState.id &&
                    t.toState.id == current.toState.id) ||
                (t.fromState.id == current.toState.id &&
                    t.toState.id == current.fromState.id)))
        .length;

    double offsetFactor = 0.0;
    if (orderedTotal > 1) {
      offsetFactor = orderedIndex - (orderedTotal - 1) / 2;
    } else if (unorderedTotal > 1) {
      offsetFactor =
          current.fromState.id.compareTo(current.toState.id) < 0 ? 0.5 : -0.5;
    }

    final normal = Offset(-unit.dy, unit.dx);
    final controlOffset = normal * curvatureStrength * offsetFactor;
    final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final control = midPoint + controlOffset;

    final labelPoint = _quadraticPoint(start, control, end, 0.5);
    final labelDirection = offsetFactor == 0
        ? 1.0
        : offsetFactor > 0
            ? 1.0
            : -1.0;
    final labelPosition = labelPoint + normal * labelOffset * labelDirection;

    final derivative = _quadraticDerivative(start, control, end, 1.0);
    final tangentAngle = math.atan2(derivative.dy, derivative.dx);

    return TransitionCurve(
      start: start,
      control: control,
      end: end,
      labelPosition: labelPosition,
      tangentAngle: tangentAngle,
    );
  }

  static Offset _quadraticPoint(
    Offset start,
    Offset control,
    Offset end,
    double t,
  ) {
    final oneMinusT = 1 - t;
    return start * (oneMinusT * oneMinusT) +
        control * (2 * oneMinusT * t) +
        end * (t * t);
  }

  /// Returns a point along the quadratic curve at parameter [t].
  static Offset pointAt(
    Offset start,
    Offset control,
    Offset end,
    double t,
  ) =>
      _quadraticPoint(start, control, end, t);

  static Offset _quadraticDerivative(
    Offset start,
    Offset control,
    Offset end,
    double t,
  ) {
    return (control - start) * (2 * (1 - t)) + (end - control) * (2 * t);
  }

  /// Returns the derivative of the quadratic curve at parameter [t].
  static Offset derivativeAt(
    Offset start,
    Offset control,
    Offset end,
    double t,
  ) =>
      _quadraticDerivative(start, control, end, t);
}
