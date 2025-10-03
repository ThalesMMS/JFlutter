import 'dart:math' as math;

import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/widgets.dart';

import 'fl_nodes_canvas_models.dart';

Offset? resolveLinkAnchorWorld(
  FlNodeEditorController controller,
  String linkId,
  FlNodesCanvasEdge? edge,
) {
  final link = controller.linksById[linkId];
  if (link == null) {
    return null;
  }

  final fromNode = controller.nodes[link.fromTo.from];
  final toNode = controller.nodes[link.fromTo.to];
  if (fromNode == null || toNode == null) {
    return null;
  }

  final fromPort = fromNode.ports[link.fromTo.fromPort];
  final toPort = toNode.ports[link.fromTo.toPort];
  if (fromPort == null || toPort == null) {
    return null;
  }

  if (edge?.controlPointX != null && edge?.controlPointY != null) {
    return Offset(edge!.controlPointX!, edge.controlPointY!);
  }

  final start = fromNode.offset + fromPort.offset;
  final end = toNode.offset + toPort.offset;

  if (link.fromTo.from == link.fromTo.to) {
    final loopAnchor = _resolveLoopAnchor(fromNode);
    return loopAnchor ?? Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
  }

  return Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
}

Offset? projectCanvasPointToOverlay({
  required FlNodeEditorController controller,
  required GlobalKey canvasKey,
  required Offset worldOffset,
}) {
  final renderObject = canvasKey.currentContext?.findRenderObject();
  if (renderObject is! RenderBox) {
    return null;
  }

  final size = renderObject.size;
  if (size.isEmpty) {
    return null;
  }

  final offset = controller.viewportOffset;
  final zoom = controller.viewportZoom;

  final viewport = Rect.fromLTWH(
    -size.width / 2 / zoom - offset.dx,
    -size.height / 2 / zoom - offset.dy,
    size.width / zoom,
    size.height / zoom,
  );

  final dx = ((worldOffset.dx - viewport.left) / viewport.width) * size.width;
  final dy = ((worldOffset.dy - viewport.top) / viewport.height) * size.height;

  if (dx.isNaN || dy.isNaN || !dx.isFinite || !dy.isFinite) {
    return null;
  }

  return Offset(dx, dy);
}

Offset? _resolveLoopAnchor(NodeInstance node) {
  final renderObject = node.key.currentContext?.findRenderObject();
  Size? nodeSize;
  if (renderObject is RenderBox) {
    nodeSize = renderObject.size;
  }

  final width = nodeSize?.width ?? 120;
  final height = nodeSize?.height ?? 60;
  final center = Offset(
    node.offset.dx + width / 2,
    node.offset.dy + height / 2,
  );

  final radius = math.sqrt(width * width + height * height) / 2;
  return center.translate(0, -(radius + 40));
}
