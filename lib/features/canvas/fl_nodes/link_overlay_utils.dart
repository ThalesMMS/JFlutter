import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/widgets.dart';

import '../../../core/constants/automaton_canvas.dart';
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

  final fromCenter = resolveNodeCenter(fromNode);
  final toCenter = resolveNodeCenter(toNode);
  if (fromCenter == null || toCenter == null) {
    return null;
  }

  if (edge?.controlPointX != null && edge?.controlPointY != null) {
    return Offset(edge!.controlPointX!, edge.controlPointY!);
  }

  if (link.fromTo.from == link.fromTo.to) {
    return _resolveLoopAnchor(fromNode, edge) ?? fromCenter;
  }

  return Offset(
    (fromCenter.dx + toCenter.dx) / 2,
    (fromCenter.dy + toCenter.dy) / 2,
  );
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

Offset? resolveNodeCenter(NodeInstance node) {
  final renderObject = node.key.currentContext?.findRenderObject();
  Size? nodeSize;
  if (renderObject is RenderBox && renderObject.hasSize) {
    nodeSize = renderObject.size;
  }

  final width = nodeSize?.width ?? kAutomatonStateDiameter;
  final height = nodeSize?.height ?? kAutomatonStateDiameter;
  return node.offset + Offset(width / 2, height / 2);
}

double resolveNodeRadius(NodeInstance node) {
  final renderObject = node.key.currentContext?.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    return renderObject.size.shortestSide / 2;
  }
  return kAutomatonStateDiameter / 2;
}

Offset? _resolveLoopAnchor(NodeInstance node, FlNodesCanvasEdge? edge) {
  if (edge?.controlPointX != null && edge?.controlPointY != null) {
    return Offset(edge!.controlPointX!, edge.controlPointY!);
  }

  final center = resolveNodeCenter(node);
  if (center == null) {
    return null;
  }
  final radius = resolveNodeRadius(node);
  return center.translate(0, -(radius * 2));
}
