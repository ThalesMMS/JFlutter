part of graphview;

class TreeEdgeRenderer extends EdgeRenderer {
  BuchheimWalkerConfiguration configuration;

  TreeEdgeRenderer(this.configuration);

  var linePath = Path();

  void render(Canvas canvas, Graph graph, Paint paint) {
    graph.edges.forEach((edge) {
      renderEdge(canvas, edge, paint);
    });
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    final edgePaint = (edge.paint ?? paint)..style = PaintingStyle.stroke;
    var node = edge.source;
    var child = edge.destination;

    if (node == child) {
      final loopPath = buildSelfLoopPath(edge, arrowLength: 0.0);
      if (loopPath != null) {
        drawStyledPath(canvas, loopPath.path, edgePaint,
            lineType: child.lineType);

        // Render label for self-loop edge
        if (edge.label != null && edge.label!.isNotEmpty) {
          final metrics = loopPath.path.computeMetrics().toList();
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
      return;
    }

    final parentPos = getNodePosition(node);
    final childPos = getNodePosition(child);

    final orientation = getEffectiveOrientation(node, child);

    linePath.reset();
    buildEdgePath(node, child, parentPos, childPos, orientation);

    // Check if the destination node has a specific line type
    final lineType = child.lineType;

    if (lineType != LineType.defaultLine) {
      drawStyledPath(canvas, linePath, edgePaint, lineType: lineType);
    } else {
      canvas.drawPath(linePath, edgePaint);
    }

    // Render label for regular edge
    if (edge.label != null && edge.label!.isNotEmpty) {
      final metrics = linePath.computeMetrics().toList();
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

  int getEffectiveOrientation(Node node, Node child) {
    return configuration.orientation;
  }

  /// Builds the path for the edge based on orientation
  void buildEdgePath(Node node, Node child, Offset parentPos, Offset childPos,
      int orientation) {
    final parentCenterX = parentPos.dx + node.width * 0.5;
    final parentCenterY = parentPos.dy + node.height * 0.5;
    final childCenterX = childPos.dx + child.width * 0.5;
    final childCenterY = childPos.dy + child.height * 0.5;

    if (parentCenterY == childCenterY && parentCenterX == childCenterX) return;

    switch (orientation) {
      case BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM:
        buildTopBottomPath(node, child, parentPos, childPos, parentCenterX,
            parentCenterY, childCenterX, childCenterY);
        break;

      case BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP:
        buildBottomTopPath(node, child, parentPos, childPos, parentCenterX,
            parentCenterY, childCenterX, childCenterY);
        break;

      case BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT:
        buildLeftRightPath(node, child, parentPos, childPos, parentCenterX,
            parentCenterY, childCenterX, childCenterY);
        break;

      case BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT:
        buildRightLeftPath(node, child, parentPos, childPos, parentCenterX,
            parentCenterY, childCenterX, childCenterY);
        break;
    }
  }

  /// Builds path for top-bottom orientation
  void buildTopBottomPath(
      Node node,
      Node child,
      Offset parentPos,
      Offset childPos,
      double parentCenterX,
      double parentCenterY,
      double childCenterX,
      double childCenterY) {
    final parentBottomY = parentPos.dy + node.height;
    final childTopY = childPos.dy;
    final midY = (parentBottomY + childTopY) * 0.5;

    if (configuration.useCurvedConnections) {
      // Curved connection
      linePath
        ..moveTo(childCenterX, childTopY)
        ..cubicTo(
          childCenterX,
          midY,
          parentCenterX,
          midY,
          parentCenterX,
          parentBottomY,
        );
    } else {
      // L-shaped connection
      linePath
        ..moveTo(parentCenterX, parentBottomY)
        ..lineTo(parentCenterX, midY)
        ..lineTo(childCenterX, midY)
        ..lineTo(childCenterX, childTopY);
    }
  }

  /// Builds path for bottom-top orientation
  void buildBottomTopPath(
      Node node,
      Node child,
      Offset parentPos,
      Offset childPos,
      double parentCenterX,
      double parentCenterY,
      double childCenterX,
      double childCenterY) {
    final parentTopY = parentPos.dy;
    final childBottomY = childPos.dy + child.height;
    final midY = (parentTopY + childBottomY) * 0.5;

    if (configuration.useCurvedConnections) {
      linePath
        ..moveTo(childCenterX, childBottomY)
        ..cubicTo(
          childCenterX,
          midY,
          parentCenterX,
          midY,
          parentCenterX,
          parentTopY,
        );
    } else {
      linePath
        ..moveTo(parentCenterX, parentTopY)
        ..lineTo(parentCenterX, midY)
        ..lineTo(childCenterX, midY)
        ..lineTo(childCenterX, childBottomY);
    }
  }

  /// Builds path for left-right orientation
  void buildLeftRightPath(
      Node node,
      Node child,
      Offset parentPos,
      Offset childPos,
      double parentCenterX,
      double parentCenterY,
      double childCenterX,
      double childCenterY) {
    final parentRightX = parentPos.dx + node.width;
    final childLeftX = childPos.dx;
    final midX = (parentRightX + childLeftX) * 0.5;

    if (configuration.useCurvedConnections) {
      linePath
        ..moveTo(childLeftX, childCenterY)
        ..cubicTo(
          midX,
          childCenterY,
          midX,
          parentCenterY,
          parentRightX,
          parentCenterY,
        );
    } else {
      linePath
        ..moveTo(parentRightX, parentCenterY)
        ..lineTo(midX, parentCenterY)
        ..lineTo(midX, childCenterY)
        ..lineTo(childLeftX, childCenterY);
    }
  }

  /// Builds path for right-left orientation
  void buildRightLeftPath(
      Node node,
      Node child,
      Offset parentPos,
      Offset childPos,
      double parentCenterX,
      double parentCenterY,
      double childCenterX,
      double childCenterY) {
    final parentLeftX = parentPos.dx;
    final childRightX = childPos.dx + child.width;
    final midX = (parentLeftX + childRightX) * 0.5;

    if (configuration.useCurvedConnections) {
      linePath
        ..moveTo(childRightX, childCenterY)
        ..cubicTo(
          midX,
          childCenterY,
          midX,
          parentCenterY,
          parentLeftX,
          parentCenterY,
        );
    } else {
      linePath
        ..moveTo(parentLeftX, parentCenterY)
        ..lineTo(midX, parentCenterY)
        ..lineTo(midX, childCenterY)
        ..lineTo(childRightX, childCenterY);
    }
  }
}
