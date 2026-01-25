//
//  graphview_canvas_painters.dart
//  JFlutter
//
//  Custom painters for rendering automaton graph elements: initial state arrows
//  and transition edges with proper highlighting, selection states, and label
//  positioning for both normal edges and self-loops.
//
//  Extracted from automaton_graphview_canvas.dart - January 2026
//

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import '../../../core/constants/automaton_canvas.dart';
import 'graphview_canvas_models.dart';

const double _kNodeDiameter = kAutomatonStateDiameter;
const double _kNodeRadius = _kNodeDiameter / 2;

/// Custom painter for rendering the initial state arrow indicator.
/// Draws a triangular arrow pointing to the initial state of the automaton.
class InitialStateArrowPainter extends CustomPainter {
  const InitialStateArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant InitialStateArrowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Custom painter for rendering automaton transition edges.
/// Handles both normal edges (with optional Bezier curves) and self-loops,
/// with support for highlighting, selection, and label rendering.
class GraphViewEdgePainter extends CustomPainter {
  GraphViewEdgePainter({
    required this.edges,
    required this.nodes,
    required this.highlightedTransitions,
    required this.selectedTransitions,
    required this.theme,
  });

  static final ArrowEdgeRenderer _loopRenderer = ArrowEdgeRenderer();

  final List<GraphViewCanvasEdge> edges;
  final List<GraphViewCanvasNode> nodes;
  final Set<String> highlightedTransitions;
  final Set<String> selectedTransitions;
  final ThemeData theme;

  static const double _kLabelNormalOffset = 14;
  static const double _kLoopLabelOffset = 16;

  GraphViewCanvasNode? _nodeById(String id) {
    for (final node in nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = theme.colorScheme.outline;
    final highlightColor = theme.colorScheme.primary;

    final selfLoops = <String, List<GraphViewCanvasEdge>>{};
    final normalEdges = <GraphViewCanvasEdge>[];

    for (final edge in edges) {
      if (edge.fromStateId == edge.toStateId) {
        selfLoops.putIfAbsent(edge.fromStateId, () => []).add(edge);
      } else {
        normalEdges.add(edge);
      }
    }

    // Paint grouped self-loops
    for (final nodeId in selfLoops.keys) {
      final loopEdges = selfLoops[nodeId]!;
      if (loopEdges.isEmpty) continue;

      final firstEdge = loopEdges.first;
      final node = _nodeById(nodeId);
      if (node == null) continue;

      final isAnyHighlighted = loopEdges.any(
        (e) => highlightedTransitions.contains(e.id),
      );
      final isAnySelected = loopEdges.any(
        (e) => selectedTransitions.contains(e.id),
      );

      final pathColor = isAnyHighlighted ? highlightColor : baseColor;
      final strokeWidth = isAnySelected ? 4.0 : 2.0;
      final paint = Paint()
        ..color = pathColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final loopGeometry = _buildGraphViewSelfLoop(firstEdge, node);
      if (loopGeometry == null) {
        continue;
      }

      _loopRenderer.renderEdge(canvas, loopGeometry.edge, paint);

      var previousTopFromAnchor = 0.0;
      // Stack labels upwards
      for (var i = 0; i < loopEdges.length; i++) {
        final edge = loopEdges[i];
        if (edge.label.isEmpty) continue;

        final isEdgeHighlighted = highlightedTransitions.contains(edge.id);
        final labelColor = isEdgeHighlighted ? highlightColor : baseColor;

        // Create text painter with PDA formatting if applicable
        TextPainter textPainter;
        if (_isPdaTransition(edge)) {
          textPainter = _createPdaTextPainter(edge, labelColor);
        } else {
          textPainter = TextPainter(
            text: TextSpan(
              text: edge.label,
              style: TextStyle(color: labelColor, fontSize: 14),
            ),
            textDirection: TextDirection.ltr,
          );
        }
        textPainter.layout();

        double centerFromAnchor;
        if (i == 0) {
          centerFromAnchor = 0.0;
          previousTopFromAnchor = textPainter.height / 2;
        } else {
          centerFromAnchor =
              previousTopFromAnchor + 2.0 + textPainter.height / 2;
          previousTopFromAnchor = centerFromAnchor + textPainter.height / 2;
        }

        final drawPosition =
            loopGeometry.labelAnchor +
            Offset(
              -textPainter.width / 2,
              -centerFromAnchor - textPainter.height / 2,
            );

        textPainter.paint(canvas, drawPosition);
      }
    }

    // Paint normal edges
    for (final edge in normalEdges) {
      final from = _nodeById(edge.fromStateId);
      final to = _nodeById(edge.toStateId);
      if (from == null || to == null) {
        continue;
      }

      final fromCenter = Offset(from.x + _kNodeRadius, from.y + _kNodeRadius);
      final toCenter = Offset(to.x + _kNodeRadius, to.y + _kNodeRadius);
      final controlPoint = _resolveControlPoint(edge, fromCenter, toCenter);

      final isHighlighted = highlightedTransitions.contains(edge.id);
      final isSelected = selectedTransitions.contains(edge.id);
      final color = isHighlighted ? highlightColor : baseColor;
      final strokeWidth = isSelected ? 4.0 : 2.0;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final start = _projectFromCenter(
        fromCenter,
        controlPoint ?? toCenter,
        _kNodeRadius,
      );
      final end = _projectFromCenter(
        toCenter,
        controlPoint ?? fromCenter,
        _kNodeRadius,
      );

      final path = Path()..moveTo(start.dx, start.dy);
      Offset direction;
      if (controlPoint != null) {
        path.quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          end.dx,
          end.dy,
        );
        direction = end - controlPoint;
      } else {
        path.lineTo(end.dx, end.dy);
        direction = end - start;
      }
      canvas.drawPath(path, paint);
      _drawArrowHead(canvas, end, direction, color);

      final labelAnchor = _computeEdgeLabelAnchor(
        start: start,
        end: end,
        controlPoint: controlPoint,
      );
      _drawEdgeLabel(canvas, labelAnchor, edge.label, color, edge: edge);
    }
  }

  ({Edge edge, Offset labelAnchor})? _buildGraphViewSelfLoop(
    GraphViewCanvasEdge edge,
    GraphViewCanvasNode node,
  ) {
    final graphNode = Node.Id(node.id)
      ..size = const Size(_kNodeDiameter, _kNodeDiameter)
      ..position = Offset(node.x, node.y);
    final graphEdge = Edge(graphNode, graphNode);

    final loop = _loopRenderer.buildSelfLoopPath(
      graphEdge,
      arrowLength: ARROW_LENGTH,
    );
    if (loop == null) {
      return null;
    }

    final bounds = loop.path.getBounds();
    final labelAnchor = Offset(
      bounds.center.dx,
      bounds.top - _kLoopLabelOffset,
    );

    return (edge: graphEdge, labelAnchor: labelAnchor);
  }

  Offset _projectFromCenter(Offset center, Offset target, double radius) {
    final vector = target - center;
    if (vector.distance == 0) {
      return center;
    }
    final normalized = vector / vector.distance;
    return center + normalized * radius;
  }

  Offset? _resolveControlPoint(
    GraphViewCanvasEdge edge,
    Offset fromCenter,
    Offset toCenter,
  ) {
    final rawX = edge.controlPointX;
    final rawY = edge.controlPointY;
    if (rawX == null || rawY == null) {
      return null;
    }

    final raw = Offset(rawX, rawY);
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

  void _drawArrowHead(
    Canvas canvas,
    Offset position,
    Offset direction,
    Color color,
  ) {
    if (direction.distance == 0) {
      return;
    }
    final normalized = direction / direction.distance;
    final normal = Offset(-normalized.dy, normalized.dx);
    const arrowLength = 12.0;
    const arrowWidth = 6.0;
    final tip = position;
    final base = tip - normalized * arrowLength;
    final left = base + normal * arrowWidth;
    final right = base - normal * arrowWidth;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawEdgeLabel(
    Canvas canvas,
    Offset position,
    String label,
    Color color, {
    GraphViewCanvasEdge? edge,
  }) {
    if (label.isEmpty) {
      return;
    }

    // Check if this is a PDA transition with enhanced formatting
    if (edge != null && _isPdaTransition(edge)) {
      _drawPdaEdgeLabel(canvas, position, edge, color);
      return;
    }

    // Default single-color label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: color, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset =
        position - Offset(textPainter.width / 2, textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  bool _isPdaTransition(GraphViewCanvasEdge edge) {
    return edge.popSymbol != null ||
        edge.pushSymbol != null ||
        edge.isLambdaInput != null ||
        edge.isLambdaPop != null ||
        edge.isLambdaPush != null;
  }

  TextPainter _createPdaTextPainter(
    GraphViewCanvasEdge edge,
    Color baseColor,
  ) {
    // Extract PDA transition components
    final lambdaInput =
        edge.isLambdaInput ?? (edge.readSymbol == null || edge.readSymbol!.isEmpty);
    final lambdaPop =
        edge.isLambdaPop ?? (edge.popSymbol == null || edge.popSymbol!.isEmpty);
    final lambdaPush =
        edge.isLambdaPush ?? (edge.pushSymbol == null || edge.pushSymbol!.isEmpty);

    final read = lambdaInput ? 'λ' : (edge.readSymbol ?? '');
    final pop = lambdaPop ? 'λ' : (edge.popSymbol ?? '');
    final push = lambdaPush ? 'λ' : (edge.pushSymbol ?? '');

    // Define colors for different components (from Material 3 theme)
    final inputColor = theme.colorScheme.primary;
    final popColor = theme.colorScheme.secondary;
    final pushColor = theme.colorScheme.tertiary;
    final lambdaColor = theme.colorScheme.outline.withOpacity(0.6);
    final separatorColor = baseColor;

    // Build formatted label with color coding
    final children = <TextSpan>[
      // Input symbol
      TextSpan(
        text: read,
        style: TextStyle(
          color: lambdaInput ? lambdaColor : inputColor,
          fontSize: 14,
          fontWeight: lambdaInput ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      // Comma separator
      TextSpan(
        text: ', ',
        style: TextStyle(color: separatorColor, fontSize: 14),
      ),
      // Pop symbol
      TextSpan(
        text: pop,
        style: TextStyle(
          color: lambdaPop ? lambdaColor : popColor,
          fontSize: 14,
          fontWeight: lambdaPop ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      // Arrow separator
      TextSpan(
        text: '/',
        style: TextStyle(color: separatorColor, fontSize: 14),
      ),
      // Push symbol
      TextSpan(
        text: push,
        style: TextStyle(
          color: lambdaPush ? lambdaColor : pushColor,
          fontSize: 14,
          fontWeight: lambdaPush ? FontWeight.normal : FontWeight.w600,
        ),
      ),
    ];

    return TextPainter(
      text: TextSpan(children: children),
      textDirection: TextDirection.ltr,
    );
  }

  void _drawPdaEdgeLabel(
    Canvas canvas,
    Offset position,
    GraphViewCanvasEdge edge,
    Color baseColor,
  ) {
    final textPainter = _createPdaTextPainter(edge, baseColor)..layout();
    final offset =
        position - Offset(textPainter.width / 2, textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  Offset _computeEdgeLabelAnchor({
    required Offset start,
    required Offset end,
    Offset? controlPoint,
  }) {
    if (controlPoint == null) {
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final tangent = end - start;
      final normal = _preferredNormal(tangent);
      return mid + normal * _kLabelNormalOffset;
    }

    const t = 0.5;
    final point = _evaluateQuadraticPoint(start, controlPoint, end, t);
    final tangent = _evaluateQuadraticTangent(start, controlPoint, end, t);
    final normal = _preferredNormal(tangent);
    return point + normal * _kLabelNormalOffset;
  }

  Offset _evaluateQuadraticPoint(
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

  Offset _evaluateQuadraticTangent(
    Offset start,
    Offset control,
    Offset end,
    double t,
  ) {
    final term1 = (control - start) * (2 * (1 - t));
    final term2 = (end - control) * (2 * t);
    return term1 + term2;
  }

  Offset _preferredNormal(Offset tangent) {
    if (tangent.distance == 0) {
      return const Offset(0, -1);
    }
    Offset normal = Offset(-tangent.dy, tangent.dx);
    if (normal.distance == 0) {
      return const Offset(0, -1);
    }
    normal = normal / normal.distance;
    if (normal.dy > 0) {
      normal = -normal;
    }
    return normal;
  }

  @override
  bool shouldRepaint(covariant GraphViewEdgePainter oldDelegate) {
    return !listEquals(oldDelegate.edges, edges) ||
        !listEquals(oldDelegate.nodes, nodes) ||
        !setEquals(
          oldDelegate.highlightedTransitions,
          highlightedTransitions,
        ) ||
        !setEquals(oldDelegate.selectedTransitions, selectedTransitions) ||
        oldDelegate.theme != theme;
  }
}
