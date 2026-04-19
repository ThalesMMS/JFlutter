part of graphview;

class CurvedEdgeRenderer extends EdgeRenderer {
  /// The curvature factor for curved edges.
  /// Higher values create more pronounced curves.
  /// Default is 0.5 (moderate curve).
  final double curvature;

  CurvedEdgeRenderer({this.curvature = 0.5});

  var curvePath = Path();

  void render(Canvas canvas, Graph graph, Paint paint) {
    graph.edges.forEach((edge) {
      renderEdge(canvas, edge, paint);
    });
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    var source = edge.source;
    var destination = edge.destination;

    final currentPaint = (edge.paint ?? paint)..style = PaintingStyle.stroke;
    final lineType = _getLineType(destination);

    if (source == destination) {
      final loopResult = buildSelfLoopPath(edge, arrowLength: 0.0);

      if (loopResult != null) {
        drawStyledPath(canvas, loopResult.path, currentPaint,
            lineType: lineType);

        // Render label for self-loop edge
        if (edge.label != null && edge.label!.isNotEmpty) {
          final metrics = loopResult.path.computeMetrics().toList();
          if (metrics.isNotEmpty) {
            final metric = metrics.first;

            // Calculate position based on labelPosition
            final labelPos = edge.labelPosition ?? EdgeLabelPosition.middle;
            double positionFactor;
            if (labelPos == EdgeLabelPosition.start) {
              positionFactor = 0.2;
            } else if (labelPos == EdgeLabelPosition.end) {
              positionFactor = 0.8;
            } else {
              positionFactor = 0.5; // middle (default)
            }

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

        return;
      }
    }

    final sourceCenter = getNodeCenter(source);
    final destinationCenter = getNodeCenter(destination);
    final sourceTarget = edge.controlPoint ?? destinationCenter;
    final destinationTarget = edge.controlPoint ?? sourceCenter;
    final edgeIndex = max(0, _graph?.edges.indexOf(edge) ?? 0);
    final sourcePoint =
        calculateSourceConnectionPoint(edge, sourceTarget, edgeIndex);
    final destinationPoint =
        calculateDestinationConnectionPoint(edge, destinationTarget, edgeIndex);

    // Build curved path using quadratic bezier curve
    curvePath.reset();
    buildCurvedPath(
      sourcePoint.dx,
      sourcePoint.dy,
      destinationPoint.dx,
      destinationPoint.dy,
      controlPoint: edge.controlPoint,
    );

    // Draw the curved path with the appropriate style
    if (lineType != null && lineType != LineType.defaultLine) {
      drawStyledPath(canvas, curvePath, currentPaint, lineType: lineType);
    } else {
      canvas.drawPath(curvePath, currentPaint);
    }

    // Render label for curved edge
    if (edge.label != null && edge.label!.isNotEmpty) {
      final metrics = curvePath.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;

        // Calculate position based on labelPosition
        final labelPos = edge.labelPosition ?? EdgeLabelPosition.middle;
        double positionFactor;
        if (labelPos == EdgeLabelPosition.start) {
          positionFactor = 0.2;
        } else if (labelPos == EdgeLabelPosition.end) {
          positionFactor = 0.8;
        } else {
          positionFactor = 0.5; // middle (default)
        }

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

  /// Helper to get line type from node data if available
  LineType? _getLineType(Node node) {
    return node.lineType;
  }

  /// Builds a curved path using quadratic bezier curve
  void buildCurvedPath(
    double startX,
    double startY,
    double stopX,
    double stopY, {
    Offset? controlPoint,
  }) {
    final dx = stopX - startX;
    final dy = stopY - startY;

    // Perpendicular vector (rotated 90 degrees)
    final perpX = -dy;
    final perpY = dx;

    // Normalize and scale by curvature factor
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) {
      // If start and end are the same, just draw a straight line
      curvePath
        ..moveTo(startX, startY)
        ..lineTo(stopX, stopY);
      return;
    }

    final resolvedControlPoint = controlPoint ??
        (() {
          final midX = (startX + stopX) * 0.5;
          final midY = (startY + stopY) * 0.5;
          final normalizedPerpX = perpX / length;
          final normalizedPerpY = perpY / length;
          return Offset(
            midX + normalizedPerpX * length * curvature,
            midY + normalizedPerpY * length * curvature,
          );
        })();

    // Build the quadratic bezier curve
    curvePath
      ..moveTo(startX, startY)
      ..quadraticBezierTo(
        resolvedControlPoint.dx,
        resolvedControlPoint.dy,
        stopX,
        stopY,
      );
  }
}
