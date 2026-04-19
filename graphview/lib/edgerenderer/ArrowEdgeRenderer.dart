part of graphview;

const double ARROW_DEGREES = 0.5;
const double ARROW_LENGTH = 10;

class ArrowEdgeRenderer extends EdgeRenderer {
  var trianglePath = Path();
  final bool noArrow;
  final EdgeRoutingConfig? config;

  ArrowEdgeRenderer({this.noArrow = false, this.config});

  Offset _getNodeCenter(Node node) {
    final nodePosition = getNodePosition(node);
    return Offset(
      nodePosition.dx + node.width * 0.5,
      nodePosition.dy + node.height * 0.5,
    );
  }

  /// Determines if adaptive anchors should be used based on configuration.
  bool _shouldUseAdaptiveAnchors() {
    return config != null && config!.anchorMode != AnchorMode.center;
  }

  @override
  Offset calculateSourceConnectionPoint(
      Edge edge, Offset destinationCenter, int edgeIndex) {
    // If no config or anchor mode is center, use center point
    if (!_shouldUseAdaptiveAnchors()) {
      return _getNodeCenter(edge.source);
    }

    // Use adaptive anchor calculation based on config
    final sourceCenter = _getNodeCenter(edge.source);

    Offset baseAnchor;
    switch (config!.anchorMode) {
      case AnchorMode.center:
        baseAnchor = sourceCenter;
        break;
      case AnchorMode.cardinal:
        baseAnchor = _calculateCardinalAnchor(
            edge.source, sourceCenter, destinationCenter);
        break;
      case AnchorMode.octagonal:
        baseAnchor = _calculateOctagonalAnchor(
            edge.source, sourceCenter, destinationCenter);
        break;
      case AnchorMode.dynamic:
        baseAnchor = _calculateDynamicAnchor(
            edge.source, sourceCenter, destinationCenter);
        break;
    }

    // Apply perpendicular offset for parallel edges
    return _applyParallelEdgeOffset(
        baseAnchor, sourceCenter, destinationCenter, edgeIndex);
  }

  @override
  Offset calculateDestinationConnectionPoint(
      Edge edge, Offset sourceCenter, int edgeIndex) {
    // If no config or anchor mode is center, use center point
    if (!_shouldUseAdaptiveAnchors()) {
      return _getNodeCenter(edge.destination);
    }

    // Use adaptive anchor calculation based on config
    final destCenter = _getNodeCenter(edge.destination);

    Offset baseAnchor;
    switch (config!.anchorMode) {
      case AnchorMode.center:
        baseAnchor = destCenter;
        break;
      case AnchorMode.cardinal:
        baseAnchor = _calculateCardinalAnchor(
            edge.destination, destCenter, sourceCenter);
        break;
      case AnchorMode.octagonal:
        baseAnchor = _calculateOctagonalAnchor(
            edge.destination, destCenter, sourceCenter);
        break;
      case AnchorMode.dynamic:
        baseAnchor =
            _calculateDynamicAnchor(edge.destination, destCenter, sourceCenter);
        break;
    }

    // Apply perpendicular offset for parallel edges
    return _applyParallelEdgeOffset(
        baseAnchor, destCenter, sourceCenter, edgeIndex);
  }

  void render(Canvas canvas, Graph graph, Paint paint) {
    graph.edges.forEach((edge) {
      renderEdge(canvas, edge, paint);
    });
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    // Check if edge has a custom renderer - if so, delegate to it
    if (edge.renderer != null) {
      edge.renderer!.renderEdge(canvas, edge, paint);
      return;
    }

    var source = edge.source;
    var destination = edge.destination;

    final currentPaint = (edge.paint ?? paint)..style = PaintingStyle.stroke;
    final lineType = _getLineType(destination);

    if (source == destination) {
      final loopResult = buildSelfLoopPath(
        edge,
        arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
      );

      if (loopResult != null) {
        drawStyledPath(canvas, loopResult.path, currentPaint,
            lineType: lineType);

        if (!noArrow) {
          final trianglePaint = Paint()
            ..color = edge.paint?.color ?? paint.color
            ..style = PaintingStyle.fill;
          final triangleCentroid = drawTriangle(
            canvas,
            trianglePaint,
            loopResult.arrowBase.dx,
            loopResult.arrowBase.dy,
            loopResult.arrowTip.dx,
            loopResult.arrowTip.dy,
          );

          drawStyledLine(
            canvas,
            loopResult.arrowBase,
            triangleCentroid,
            currentPaint,
            lineType: lineType,
          );
        }

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

    // Calculate connection points (adaptive or center-based)
    double startX, startY, stopX, stopY;

    if (_shouldUseAdaptiveAnchors()) {
      // Use adaptive anchors when configured
      final edgeIndex = _calculateEdgeIndex(edge);
      final destCenter = _getNodeCenter(destination);
      final sourceCenter = _getNodeCenter(source);

      final sourcePoint =
          calculateSourceConnectionPoint(edge, destCenter, edgeIndex);
      final destPoint =
          calculateDestinationConnectionPoint(edge, sourceCenter, edgeIndex);

      startX = sourcePoint.dx;
      startY = sourcePoint.dy;
      stopX = destPoint.dx;
      stopY = destPoint.dy;
    } else {
      // Use center points (default/backward compatible behavior)
      var sourceOffset = getNodePosition(source);
      var destinationOffset = getNodePosition(destination);

      startX = sourceOffset.dx + source.width * 0.5;
      startY = sourceOffset.dy + source.height * 0.5;
      stopX = destinationOffset.dx + destination.width * 0.5;
      stopY = destinationOffset.dy + destination.height * 0.5;
    }

    var clippedLine = _shouldUseAdaptiveAnchors()
        ? [startX, startY, stopX, stopY] // Adaptive anchors already on boundary
        : clipLineEnd(
            startX,
            startY,
            stopX,
            stopY,
            getNodePosition(destination).dx,
            getNodePosition(destination).dy,
            destination.width,
            destination.height);

    if (noArrow) {
      // Draw line without arrow, respecting line type
      drawStyledLine(
        canvas,
        Offset(clippedLine[0], clippedLine[1]),
        Offset(clippedLine[2], clippedLine[3]),
        currentPaint,
        lineType: lineType,
      );
    } else {
      var trianglePaint = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;

      // Draw line with arrow
      Paint? edgeTrianglePaint;
      if (edge.paint != null) {
        edgeTrianglePaint = Paint()
          ..color = edge.paint?.color ?? paint.color
          ..style = PaintingStyle.fill;
      }

      var triangleCentroid = drawTriangle(
          canvas,
          edgeTrianglePaint ?? trianglePaint,
          clippedLine[0],
          clippedLine[1],
          clippedLine[2],
          clippedLine[3]);

      // Draw the line with the appropriate style
      drawStyledLine(
        canvas,
        Offset(clippedLine[0], clippedLine[1]),
        triangleCentroid,
        currentPaint,
        lineType: lineType,
      );
    }

    // Render label for straight edge
    if (edge.label != null && edge.label!.isNotEmpty) {
      final labelPos = edge.labelPosition ?? EdgeLabelPosition.middle;
      double positionFactor;
      if (labelPos == EdgeLabelPosition.start) {
        positionFactor = 0.2;
      } else if (labelPos == EdgeLabelPosition.end) {
        positionFactor = 0.8;
      } else {
        positionFactor = 0.5; // middle (default)
      }

      final labelPosition = Offset(
        clippedLine[0] + (clippedLine[2] - clippedLine[0]) * positionFactor,
        clippedLine[1] + (clippedLine[3] - clippedLine[1]) * positionFactor,
      );
      final angle = atan2(
        clippedLine[3] - clippedLine[1],
        clippedLine[2] - clippedLine[0],
      );
      final rotationAngle =
          (edge.labelFollowsEdgeDirection ?? true) ? angle : null;
      renderEdgeLabel(canvas, edge, labelPosition, rotationAngle);
    }
  }

  /// Helper to get line type from node data if available
  LineType? _getLineType(Node node) {
    return node.lineType == LineType.defaultLine ? null : node.lineType;
  }

  Offset drawTriangle(Canvas canvas, Paint paint, double lineStartX,
      double lineStartY, double arrowTipX, double arrowTipY) {
    // Calculate direction from line start to arrow tip, then flip 180° to point backwards from tip
    var lineDirection =
        (atan2(arrowTipY - lineStartY, arrowTipX - lineStartX) + pi);

    // Calculate the two base points of the arrowhead triangle
    var leftWingX =
        (arrowTipX + ARROW_LENGTH * cos((lineDirection - ARROW_DEGREES)));
    var leftWingY =
        (arrowTipY + ARROW_LENGTH * sin((lineDirection - ARROW_DEGREES)));
    var rightWingX =
        (arrowTipX + ARROW_LENGTH * cos((lineDirection + ARROW_DEGREES)));
    var rightWingY =
        (arrowTipY + ARROW_LENGTH * sin((lineDirection + ARROW_DEGREES)));

    // Draw the triangle: tip -> left wing -> right wing -> back to tip
    trianglePath.moveTo(arrowTipX, arrowTipY); // Arrow tip
    trianglePath.lineTo(leftWingX, leftWingY); // Left wing
    trianglePath.lineTo(rightWingX, rightWingY); // Right wing
    trianglePath.close(); // Back to tip
    canvas.drawPath(trianglePath, paint);

    // Calculate center point of the triangle
    var triangleCenterX = (arrowTipX + leftWingX + rightWingX) / 3;
    var triangleCenterY = (arrowTipY + leftWingY + rightWingY) / 3;

    trianglePath.reset();
    return Offset(triangleCenterX, triangleCenterY);
  }

  List<double> clipLineEnd(
      double startX,
      double startY,
      double stopX,
      double stopY,
      double destX,
      double destY,
      double destWidth,
      double destHeight) {
    var clippedStopX = stopX;
    var clippedStopY = stopY;

    if (startX == stopX && startY == stopY) {
      return [startX, startY, clippedStopX, clippedStopY];
    }

    var slope = (startY - stopY) / (startX - stopX);
    final halfHeight = destHeight * 0.5;
    final halfWidth = destWidth * 0.5;

    // Check vertical edge intersections
    if (startX != stopX) {
      final halfSlopeWidth = slope * halfWidth;
      if (halfSlopeWidth.abs() <= halfHeight) {
        if (destX > startX) {
          // Left edge intersection
          return [startX, startY, stopX - halfWidth, stopY - halfSlopeWidth];
        } else if (destX < startX) {
          // Right edge intersection
          return [startX, startY, stopX + halfWidth, stopY + halfSlopeWidth];
        }
      }
    }

    // Check horizontal edge intersections
    if (startY != stopY && slope != 0) {
      final halfSlopeHeight = halfHeight / slope;
      if (halfSlopeHeight.abs() <= halfWidth) {
        if (destY < startY) {
          // Bottom edge intersection
          clippedStopX = stopX + halfSlopeHeight;
          clippedStopY = stopY + halfHeight;
        } else if (destY > startY) {
          // Top edge intersection
          clippedStopX = stopX - halfSlopeHeight;
          clippedStopY = stopY - halfHeight;
        }
      }
    }

    return [startX, startY, clippedStopX, clippedStopY];
  }

  List<double> clipLine(double startX, double startY, double stopX,
      double stopY, Node destination) {
    final resultLine = [startX, startY, stopX, stopY];

    if (startX == stopX && startY == stopY) return resultLine;

    var slope = (startY - stopY) / (startX - stopX);
    final halfHeight = destination.height * 0.5;
    final halfWidth = destination.width * 0.5;

    // Check vertical edge intersections
    if (startX != stopX) {
      final halfSlopeWidth = slope * halfWidth;
      if (halfSlopeWidth.abs() <= halfHeight) {
        if (destination.x > startX) {
          // Left edge intersection
          resultLine[2] = stopX - halfWidth;
          resultLine[3] = stopY - halfSlopeWidth;
          return resultLine;
        } else if (destination.x < startX) {
          // Right edge intersection
          resultLine[2] = stopX + halfWidth;
          resultLine[3] = stopY + halfSlopeWidth;
          return resultLine;
        }
      }
    }

    // Check horizontal edge intersections
    if (startY != stopY && slope != 0) {
      final halfSlopeHeight = halfHeight / slope;
      if (halfSlopeHeight.abs() <= halfWidth) {
        if (destination.y < startY) {
          // Bottom edge intersection
          resultLine[2] = stopX + halfSlopeHeight;
          resultLine[3] = stopY + halfHeight;
        } else if (destination.y > startY) {
          // Top edge intersection
          resultLine[2] = stopX - halfSlopeHeight;
          resultLine[3] = stopY - halfHeight;
        }
      }
    }

    return resultLine;
  }

  /// Calculates a cardinal anchor point (N, E, S, W) on the node boundary.
  Offset _calculateCardinalAnchor(
      Node node, Offset nodeCenter, Offset targetCenter) {
    final nodePosition = getNodePosition(node);
    final direction = targetCenter - nodeCenter;
    final angle = atan2(direction.dy, direction.dx);
    final degrees = angle * 180 / pi;

    if (degrees >= -45 && degrees < 45) {
      // East - right edge
      return Offset(
        nodePosition.dx + node.width,
        nodePosition.dy + node.height * 0.5,
      );
    } else if (degrees >= 45 && degrees < 135) {
      // South - bottom edge
      return Offset(
        nodePosition.dx + node.width * 0.5,
        nodePosition.dy + node.height,
      );
    } else if (degrees >= -135 && degrees < -45) {
      // North - top edge
      return Offset(
        nodePosition.dx + node.width * 0.5,
        nodePosition.dy,
      );
    } else {
      // West - left edge
      return Offset(
        nodePosition.dx,
        nodePosition.dy + node.height * 0.5,
      );
    }
  }

  /// Calculates an octagonal anchor point (8 compass points) on the node boundary.
  Offset _calculateOctagonalAnchor(
      Node node, Offset nodeCenter, Offset targetCenter) {
    final nodePosition = getNodePosition(node);
    final direction = targetCenter - nodeCenter;
    final angle = atan2(direction.dy, direction.dx);
    final degrees = angle * 180 / pi;

    if (degrees >= -22.5 && degrees < 22.5) {
      // East
      return Offset(
        nodePosition.dx + node.width,
        nodePosition.dy + node.height * 0.5,
      );
    } else if (degrees >= 22.5 && degrees < 67.5) {
      // Southeast
      return Offset(
        nodePosition.dx + node.width,
        nodePosition.dy + node.height,
      );
    } else if (degrees >= 67.5 && degrees < 112.5) {
      // South
      return Offset(
        nodePosition.dx + node.width * 0.5,
        nodePosition.dy + node.height,
      );
    } else if (degrees >= 112.5 && degrees < 157.5) {
      // Southwest
      return Offset(
        nodePosition.dx,
        nodePosition.dy + node.height,
      );
    } else if (degrees >= -157.5 && degrees < -112.5) {
      // Northwest
      return Offset(
        nodePosition.dx,
        nodePosition.dy,
      );
    } else if (degrees >= -112.5 && degrees < -67.5) {
      // North
      return Offset(
        nodePosition.dx + node.width * 0.5,
        nodePosition.dy,
      );
    } else if (degrees >= -67.5 && degrees < -22.5) {
      // Northeast
      return Offset(
        nodePosition.dx + node.width,
        nodePosition.dy,
      );
    } else {
      // West
      return Offset(
        nodePosition.dx,
        nodePosition.dy + node.height * 0.5,
      );
    }
  }

  /// Calculates a dynamic anchor point using exact ray-rectangle intersection.
  Offset _calculateDynamicAnchor(
      Node node, Offset nodeCenter, Offset targetCenter) {
    final nodePosition = getNodePosition(node);

    // If nodes at same position, return center
    if ((nodeCenter - targetCenter).distance < 1e-6) {
      return nodeCenter;
    }

    final halfWidth = node.width * 0.5;
    final halfHeight = node.height * 0.5;
    final dx = targetCenter.dx - nodeCenter.dx;
    final dy = targetCenter.dy - nodeCenter.dy;

    // Handle vertical line
    if (dx.abs() < 1e-6) {
      if (dy > 0) {
        return Offset(nodeCenter.dx, nodePosition.dy + node.height);
      } else {
        return Offset(nodeCenter.dx, nodePosition.dy);
      }
    }

    final slope = dy / dx;

    // Check vertical edge intersections
    final halfSlopeWidth = slope * halfWidth;
    if (halfSlopeWidth.abs() <= halfHeight) {
      if (dx > 0) {
        return Offset(
          nodePosition.dx + node.width,
          nodeCenter.dy + halfSlopeWidth,
        );
      } else {
        return Offset(
          nodePosition.dx,
          nodeCenter.dy - halfSlopeWidth,
        );
      }
    }

    // Check horizontal edge intersections
    if (slope != 0) {
      final halfSlopeHeight = halfHeight / slope;
      if (halfSlopeHeight.abs() <= halfWidth) {
        if (dy > 0) {
          return Offset(
            nodeCenter.dx + halfSlopeHeight,
            nodePosition.dy + node.height,
          );
        } else {
          return Offset(
            nodeCenter.dx - halfSlopeHeight,
            nodePosition.dy,
          );
        }
      }
    }

    return nodeCenter;
  }

  /// Calculates the index of this edge among parallel edges.
  int _calculateEdgeIndex(Edge edge) {
    if (_graph == null) {
      return 0;
    }

    final outEdges = _graph!.getOutEdges(edge.source);
    final parallelEdges =
        outEdges.where((e) => e.destination == edge.destination).toList();

    if (parallelEdges.length <= 1) {
      return 0;
    }

    parallelEdges
        .sort((a, b) => _stableEdgeSortKey(a).compareTo(_stableEdgeSortKey(b)));
    final index = parallelEdges.indexOf(edge);
    final centerOffset = (parallelEdges.length - 1) / 2;
    return index - centerOffset.floor();
  }

  String _stableEdgeSortKey(Edge edge) {
    final graphIndex = _graph?.edges.indexOf(edge) ?? -1;
    return [
      edge.key?.toString() ?? '',
      edge.source.key?.value?.toString() ?? '',
      edge.destination.key?.value?.toString() ?? '',
      graphIndex.toString().padLeft(8, '0'),
    ].join('|');
  }

  /// Applies perpendicular offset for parallel edge distribution.
  Offset _applyParallelEdgeOffset(
    Offset anchor,
    Offset nodeCenter,
    Offset targetCenter,
    int edgeIndex,
  ) {
    if (edgeIndex == 0 || config == null) {
      return anchor;
    }

    final direction = targetCenter - nodeCenter;
    if (direction.distance < 1e-6) {
      return anchor;
    }

    // Calculate perpendicular vector
    final perpendicular = Offset(-direction.dy, direction.dx);
    final length = perpendicular.distance;
    final normalized =
        Offset(perpendicular.dx / length, perpendicular.dy / length);
    final offset = normalized * (edgeIndex * config!.minEdgeDistance);

    return anchor + offset;
  }
}
