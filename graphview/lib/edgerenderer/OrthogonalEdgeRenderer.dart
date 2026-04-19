part of graphview;

/// Edge renderer that generates orthogonal (L-shaped Manhattan) paths.
///
/// This renderer creates paths with right angles, routing edges horizontally
/// and vertically. The routing algorithm chooses between horizontal-first and
/// vertical-first based on the relative positions of the nodes.
class OrthogonalEdgeRenderer extends EdgeRenderer {
  EdgeRoutingConfig configuration;

  OrthogonalEdgeRenderer(this.configuration);

  void render(Canvas canvas, Graph graph, Paint paint) {
    graph.edges.forEach((edge) {
      renderEdge(canvas, edge, paint);
    });
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    final edgePaint = _copyPaint(edge.paint ?? paint)
      ..style = PaintingStyle.stroke;
    var source = edge.source;
    var destination = edge.destination;

    // Handle self-loops
    if (source == destination) {
      final loopPath = buildSelfLoopPath(edge, arrowLength: 0.0);
      if (loopPath != null) {
        drawStyledPath(canvas, loopPath.path, edgePaint,
            lineType: destination.lineType);

        // Render label for self-loop edge
        if (edge.label != null && edge.label!.isNotEmpty) {
          final metrics = loopPath.path.computeMetrics().toList();
          if (metrics.isNotEmpty) {
            final metric = metrics.first;

            final positionFactor = _labelPositionFactor(edge.labelPosition);

            final position = metric.length * positionFactor;
            final tangent = metric.getTangentForOffset(position);
            if (tangent != null) {
              final rotationAngle = (edge.labelFollowsEdgeDirection ?? true)
                  ? tangent.angle
                  : null; // null means no rotation (horizontal)
              renderEdgeLabel(
                canvas,
                edge,
                tangent.position,
                rotationAngle,
              );
            }
          }
        }
      }
      return;
    }

    final sourcePos = getNodePosition(source);
    final destinationPos = getNodePosition(destination);

    final linePath = Path();
    buildOrthogonalPath(
        linePath, source, destination, sourcePos, destinationPos);

    // Check if the destination node has a specific line type
    final lineType = destination.lineType;

    drawStyledPath(canvas, linePath, edgePaint, lineType: lineType);

    // Render label for regular edge
    if (edge.label != null && edge.label!.isNotEmpty) {
      final positionFactor = _labelPositionFactor(edge.labelPosition);
      final tangent = _getTangentAtPosition(linePath, positionFactor);
      if (tangent != null) {
        final rotationAngle = (edge.labelFollowsEdgeDirection ?? true)
            ? tangent.angle
            : null; // null means no rotation (horizontal)
        renderEdgeLabel(
          canvas,
          edge,
          tangent.position,
          rotationAngle,
        );
      }
    }
  }

  /// Builds an orthogonal (L-shaped Manhattan) path between two nodes
  void buildOrthogonalPath(
    Path linePath,
    Node source,
    Node destination,
    Offset sourcePos,
    Offset destinationPos,
  ) {
    final sourceCenterX = sourcePos.dx + source.width * 0.5;
    final sourceCenterY = sourcePos.dy + source.height * 0.5;
    final destinationCenterX = destinationPos.dx + destination.width * 0.5;
    final destinationCenterY = destinationPos.dy + destination.height * 0.5;
    final centerHorizontalDistance = (destinationCenterX - sourceCenterX).abs();
    final centerVerticalDistance = (destinationCenterY - sourceCenterY).abs();
    final horizontalFirst = centerHorizontalDistance >= centerVerticalDistance;
    final sourceAnchor = _calculateCardinalAnchor(
      source,
      sourcePos,
      Offset(sourceCenterX, sourceCenterY),
      Offset(destinationCenterX, destinationCenterY),
      horizontalFirst,
    );
    final destinationAnchor = _calculateCardinalAnchor(
      destination,
      destinationPos,
      Offset(destinationCenterX, destinationCenterY),
      Offset(sourceCenterX, sourceCenterY),
      horizontalFirst,
    );

    // Handle case where nodes are at same position
    if ((sourceAnchor.dx - destinationAnchor.dx).abs() < 0.001 &&
        (sourceAnchor.dy - destinationAnchor.dy).abs() < 0.001) {
      linePath
        ..moveTo(sourceAnchor.dx, sourceAnchor.dy)
        ..lineTo(destinationAnchor.dx, destinationAnchor.dy);
      return;
    }

    // Calculate start and end points for the path
    final startX = sourceAnchor.dx;
    final startY = sourceAnchor.dy;
    final endX = destinationAnchor.dx;
    final endY = destinationAnchor.dy;

    // Determine routing direction based on relative positions
    // Use horizontal-first if horizontal distance is greater, vertical-first otherwise
    final horizontalDistance = (endX - startX).abs();
    final verticalDistance = (endY - startY).abs();

    if (horizontalDistance >= verticalDistance) {
      // Horizontal-first routing: go horizontal to midpoint, then vertical, then horizontal
      final midX = (startX + endX) * 0.5;

      // Handle collinear nodes (same Y coordinate) by adding a minimal vertical offset
      if ((endY - startY).abs() < 0.001) {
        // Nodes are horizontally aligned, add a small vertical offset for visibility
        final collinearOffset = configuration.minEdgeDistance;
        _addOrthogonalSegments(linePath, [
          Offset(startX, startY),
          Offset(startX, startY + collinearOffset),
          Offset(endX, startY + collinearOffset),
          Offset(endX, endY),
        ]);
      } else {
        // Normal L-shaped path
        _addOrthogonalSegments(linePath, [
          Offset(startX, startY),
          Offset(midX, startY),
          Offset(midX, endY),
          Offset(endX, endY),
        ]);
      }
    } else {
      // Vertical-first routing: go vertical to midpoint, then horizontal, then vertical
      final midY = (startY + endY) * 0.5;

      // Handle collinear nodes (same X coordinate) by adding a minimal horizontal offset
      if ((endX - startX).abs() < 0.001) {
        // Nodes are vertically aligned, add a small horizontal offset for visibility
        final collinearOffset = configuration.minEdgeDistance;
        _addOrthogonalSegments(linePath, [
          Offset(startX, startY),
          Offset(startX + collinearOffset, startY),
          Offset(startX + collinearOffset, endY),
          Offset(endX, endY),
        ]);
      } else {
        // Normal L-shaped path
        _addOrthogonalSegments(linePath, [
          Offset(startX, startY),
          Offset(startX, midY),
          Offset(endX, midY),
          Offset(endX, endY),
        ]);
      }
    }
  }

  ({Offset position, double angle})? _getTangentAtPosition(
      Path path, double positionFactor) {
    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold(0.0, (sum, metric) => sum + metric.length);
    var target = totalLength * positionFactor;

    for (final metric in metrics) {
      if (target <= metric.length) {
        final tangent = metric.getTangentForOffset(target);
        return tangent == null
            ? null
            : (position: tangent.position, angle: tangent.angle);
      }
      target -= metric.length;
    }

    if (metrics.isEmpty) {
      return null;
    }
    final tangent = metrics.last.getTangentForOffset(metrics.last.length);
    return tangent == null
        ? null
        : (position: tangent.position, angle: tangent.angle);
  }

  void _addOrthogonalSegments(Path linePath, List<Offset> points) {
    var hasStarted = false;
    Offset? previousPoint;

    for (final point in points) {
      if (previousPoint != null && (previousPoint - point).distance < 0.001) {
        continue;
      }
      if (hasStarted) {
        linePath.lineTo(point.dx, point.dy);
      } else {
        linePath.moveTo(point.dx, point.dy);
        hasStarted = true;
      }
      previousPoint = point;
    }
  }

  double _labelPositionFactor(EdgeLabelPosition? position) {
    switch (position) {
      case EdgeLabelPosition.start:
        return 0.2;
      case EdgeLabelPosition.end:
        return 0.8;
      case EdgeLabelPosition.middle:
      case null:
        return 0.5;
    }
  }

  Paint _copyPaint(Paint base) {
    return Paint()
      ..isAntiAlias = base.isAntiAlias
      ..color = base.color
      ..blendMode = base.blendMode
      ..style = base.style
      ..strokeWidth = base.strokeWidth
      ..strokeCap = base.strokeCap
      ..strokeJoin = base.strokeJoin
      ..strokeMiterLimit = base.strokeMiterLimit
      ..filterQuality = base.filterQuality
      ..shader = base.shader
      ..colorFilter = base.colorFilter
      ..imageFilter = base.imageFilter
      ..maskFilter = base.maskFilter
      ..invertColors = base.invertColors;
  }

  Offset _calculateCardinalAnchor(Node node, Offset nodePos, Offset nodeCenter,
      Offset targetCenter, bool horizontalFirst) {
    if (horizontalFirst) {
      final x = targetCenter.dx >= nodeCenter.dx
          ? nodePos.dx + node.width
          : nodePos.dx;
      return Offset(x, nodeCenter.dy);
    }

    final y = targetCenter.dy >= nodeCenter.dy
        ? nodePos.dy + node.height
        : nodePos.dy;
    return Offset(nodeCenter.dx, y);
  }
}
