import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/constants/automaton_canvas.dart';
import 'graphview_canvas_controller.dart';
import 'graphview_canvas_models.dart';

const double _kNodeDiameter = kAutomatonStateDiameter;
const double _kNodeRadius = _kNodeDiameter / 2;

/// Computes the preferred world anchor for the provided [edge].
Offset? resolveLinkAnchorWorld(
  GraphViewCanvasController controller,
  GraphViewCanvasEdge edge,
) {
  final from = controller.nodeById(edge.fromStateId);
  final to = controller.nodeById(edge.toStateId);
  if (from == null || to == null) {
    return null;
  }

  if (edge.controlPointX != null && edge.controlPointY != null) {
    final raw = Offset(edge.controlPointX!, edge.controlPointY!);
    return _normalizeControlPoint(raw, from, to);
  }

  if (edge.fromStateId == edge.toStateId) {
    return _resolveLoopAnchor(from);
  }

  final fromCenter = resolveNodeCenter(from);
  final toCenter = resolveNodeCenter(to);
  return Offset(
    (fromCenter.dx + toCenter.dx) / 2,
    (fromCenter.dy + toCenter.dy) / 2,
  );
}

/// Converts a world [offset] into a screen-space position relative to the
/// overlay associated with [canvasKey].
Offset? projectWorldPointToOverlay({
  required GlobalKey canvasKey,
  required TransformationController transformationController,
  required Offset worldOffset,
}) {
  final renderObject = canvasKey.currentContext?.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) {
    return null;
  }

  final matrix = transformationController.value;
  final projected = MatrixUtils.transformPoint(matrix, worldOffset);
  if (!projected.dx.isFinite || !projected.dy.isFinite) {
    return null;
  }

  return renderObject.localToGlobal(projected);
}

/// Returns the node center in world coordinates.
Offset resolveNodeCenter(GraphViewCanvasNode node) {
  return Offset(node.x + _kNodeRadius, node.y + _kNodeRadius);
}

Offset _resolveLoopAnchor(GraphViewCanvasNode node) {
  final center = resolveNodeCenter(node);
  return center.translate(0, -_kNodeRadius * 2);
}

Offset _normalizeControlPoint(
  Offset raw,
  GraphViewCanvasNode from,
  GraphViewCanvasNode to,
) {
  final fromCenter = resolveNodeCenter(from);
  final toCenter = resolveNodeCenter(to);
  final averageCenter = Offset(
    (fromCenter.dx + toCenter.dx) / 2,
    (fromCenter.dy + toCenter.dy) / 2,
  );

  const legacyOffset = Offset(_kNodeRadius, _kNodeRadius);
  final legacyCandidate = raw + legacyOffset;

  final rawDistance = (raw - averageCenter).distance;
  final legacyDistance = (legacyCandidate - averageCenter).distance;

  return legacyDistance < rawDistance ? legacyCandidate : raw;
}
