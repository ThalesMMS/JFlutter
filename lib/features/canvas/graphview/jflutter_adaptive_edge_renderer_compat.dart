part of 'jflutter_adaptive_edge_renderer.dart';

final Expando<Offset> _jflutterEdgeControlPoints =
    Expando<Offset>('jflutterEdgeControlPoint');

void setJFlutterEdgeControlPoint(Edge edge, Offset? controlPoint) {
  edge.controlPoint = controlPoint;
  _jflutterEdgeControlPoints[edge] = controlPoint;
}

Offset? jFlutterEdgeControlPoint(Edge edge) {
  return edge.controlPoint ?? _jflutterEdgeControlPoints[edge];
}

class EdgePathGeometry {
  const EdgePathGeometry({
    required this.path,
    required this.start,
    required this.end,
    required this.arrowBase,
    required this.arrowTip,
    this.isSelfLoop = false,
  });

  final Path path;
  final Offset start;
  final Offset end;
  final Offset arrowBase;
  final Offset arrowTip;
  final bool isSelfLoop;
}

class EdgeLabelGeometry {
  const EdgeLabelGeometry({
    required this.position,
    this.angle,
  });

  final Offset position;
  final double? angle;
}

class AnimatedAdaptiveEdgeRenderer extends AdaptiveEdgeRenderer {
  AnimatedAdaptiveEdgeRenderer({
    required super.config,
    this.animationConfig = const AnimatedEdgeConfiguration(),
    this.animationValue = 0.0,
    super.noArrow,
  });

  final AnimatedEdgeConfiguration animationConfig;
  double animationValue;
  Graph? _graph;
  final Map<String, List<Edge>> _parallelEdgeCache = <String, List<Edge>>{};
  Graph? _parallelEdgeCacheGraph;
  int _parallelEdgeCacheCount = -1;

  Graph? get graph => _graph;

  @override
  void setGraph(Graph graph) {
    super.setGraph(graph);
    _graph = graph;
    _clearParallelEdgeCache();
  }

  void setAnimationValue(double value) {
    animationValue = value;
  }

  void prepareForRenderCycle() {
    resetRepulsionCalculation();
    _ensureParallelEdgeCache();
  }

  EdgePathGeometry? buildEdgeGeometry(
    Edge edge, {
    double arrowLength = ARROW_LENGTH,
  }) {
    if (edge.source == edge.destination) {
      final loopResult = buildSelfLoopPath(edge, arrowLength: arrowLength);
      if (loopResult == null) {
        return null;
      }
      final geometry = buildPathGeometry(
        loopResult.path,
        arrowLength: arrowLength,
        isSelfLoop: true,
      );
      return EdgePathGeometry(
        path: loopResult.path,
        start: geometry.start,
        end: geometry.end,
        arrowBase: loopResult.arrowBase,
        arrowTip: loopResult.arrowTip,
        isSelfLoop: true,
      );
    }

    final controlPoint = jFlutterEdgeControlPoint(edge);
    if (controlPoint != null) {
      final sourcePoint = calculateSourceConnectionPoint(edge, controlPoint, 0);
      final destinationPoint =
          calculateDestinationConnectionPoint(edge, controlPoint, 0);
      final path = Path()
        ..moveTo(sourcePoint.dx, sourcePoint.dy)
        ..quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          destinationPoint.dx,
          destinationPoint.dy,
        );
      return buildPathGeometry(path, arrowLength: arrowLength);
    }

    final sourceCenter = getNodeCenter(edge.source);
    final destinationCenter = getNodeCenter(edge.destination);
    final edgeIndex = _edgeIndex(edge);
    final sourcePoint = calculateSourceConnectionPoint(
      edge,
      destinationCenter,
      edgeIndex,
    );
    final destinationPoint = calculateDestinationConnectionPoint(
      edge,
      sourceCenter,
      edgeIndex,
    );
    final path = routeEdgePath(sourcePoint, destinationPoint, edge);
    return buildPathGeometry(path, arrowLength: arrowLength);
  }

  EdgeLabelGeometry? buildLabelGeometry(Edge edge, Path path) {
    final metric = path.computeMetrics().firstOrNull;
    if (metric == null) {
      return null;
    }

    final labelPosition = edge.labelPosition ?? EdgeLabelPosition.middle;
    final positionFactor = switch (labelPosition) {
      EdgeLabelPosition.start => 0.2,
      EdgeLabelPosition.middle => 0.5,
      EdgeLabelPosition.end => 0.8,
    };
    final tangent = metric.getTangentForOffset(metric.length * positionFactor);
    if (tangent == null) {
      return null;
    }

    return EdgeLabelGeometry(
      position: tangent.position,
      angle: (edge.labelFollowsEdgeDirection ?? true) ? tangent.angle : null,
    );
  }

  EdgePathGeometry buildPathGeometry(
    Path path, {
    double arrowLength = ARROW_LENGTH,
    bool isSelfLoop = false,
  }) {
    final metric = path.computeMetrics().firstOrNull;
    if (metric == null) {
      if (kDebugMode) {
        debugPrint(
          'Cannot build EdgePathGeometry for an empty path '
          '(isSelfLoop: $isSelfLoop, path: $path).',
        );
      }
      return EdgePathGeometry(
        path: path,
        start: Offset.zero,
        end: Offset.zero,
        arrowBase: Offset.zero,
        arrowTip: Offset.zero,
        isSelfLoop: isSelfLoop,
      );
    }

    final start = metric.getTangentForOffset(0)?.position ?? Offset.zero;
    final end = metric.getTangentForOffset(metric.length)?.position ?? start;
    final effectiveArrowLength =
        arrowLength <= 0 ? 0.0 : math.min(arrowLength, metric.length * 0.3);
    final arrowBaseOffset = math.max(0.0, metric.length - effectiveArrowLength);
    final arrowBase =
        metric.getTangentForOffset(arrowBaseOffset)?.position ?? end;

    return EdgePathGeometry(
      path: path,
      start: start,
      end: end,
      arrowBase: arrowBase,
      arrowTip: end,
      isSelfLoop: isSelfLoop,
    );
  }

  void paintEdgeGeometry(
    Canvas canvas,
    Edge edge,
    Paint paint,
    EdgePathGeometry geometry,
  ) {
    canvas.drawPath(geometry.path, paint);
  }

  void paintEdgeArrow(
    Canvas canvas,
    Edge edge,
    Paint paint,
    EdgePathGeometry geometry,
  ) {
    if ((geometry.arrowTip - geometry.arrowBase).distance < 0.001) {
      return;
    }
    drawTriangle(
      canvas,
      paint,
      geometry.arrowBase.dx,
      geometry.arrowBase.dy,
      geometry.arrowTip.dx,
      geometry.arrowTip.dy,
    );
  }

  void renderAnimatedParticlesOnPath(
    Canvas canvas,
    Edge edge,
    Paint paint,
    Path path,
  ) {
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) {
      return;
    }

    final particlePaint = Paint()
      ..color =
          animationConfig.particleColor ?? edge.paint?.color ?? paint.color
      ..style = PaintingStyle.fill;
    final metric = metrics.first;

    for (var i = 0; i < animationConfig.particleCount; i++) {
      final basePosition = i / animationConfig.particleCount;
      final animatedPosition =
          (basePosition + animationValue * animationConfig.animationSpeed) %
              1.0;
      final tangent =
          metric.getTangentForOffset(animatedPosition * metric.length);
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          animationConfig.particleSize,
          particlePaint,
        );
      }
    }
  }

  int _edgeIndex(Edge edge) {
    _ensureParallelEdgeCache();
    final edges = _parallelEdgeCache[_parallelEdgeKey(edge)];
    if (edges == null) {
      return 0;
    }
    final index = edges.indexOf(edge);
    return index < 0 ? 0 : index;
  }

  void _ensureParallelEdgeCache() {
    final currentGraph = graph;
    if (currentGraph == null) {
      _clearParallelEdgeCache();
      return;
    }
    if (_parallelEdgeCacheGraph != currentGraph ||
        _parallelEdgeCacheCount != currentGraph.edges.length) {
      _rebuildParallelEdgeCache();
    }
  }

  void _rebuildParallelEdgeCache() {
    final currentGraph = graph;
    if (currentGraph == null) {
      _clearParallelEdgeCache();
      return;
    }

    final graphEdges = currentGraph.edges.toList(growable: false);
    _parallelEdgeCache.clear();
    for (final edge in graphEdges) {
      _parallelEdgeCache
          .putIfAbsent(_parallelEdgeKey(edge), () => <Edge>[])
          .add(
            edge,
          );
    }

    for (final edges in _parallelEdgeCache.values) {
      edges.sort(
        (left, right) => _edgeSortKey(left, graphEdges)
            .compareTo(_edgeSortKey(right, graphEdges)),
      );
    }
    _parallelEdgeCacheGraph = currentGraph;
    _parallelEdgeCacheCount = graphEdges.length;
  }

  void _clearParallelEdgeCache() {
    _parallelEdgeCache.clear();
    _parallelEdgeCacheGraph = null;
    _parallelEdgeCacheCount = -1;
  }

  String _parallelEdgeKey(Edge edge) {
    return '${_nodeKey(edge.source)}->${_nodeKey(edge.destination)}';
  }

  String _nodeKey(Node node) {
    return node.key?.value.toString() ?? node.hashCode.toString();
  }

  String _edgeSortKey(Edge edge, List<Edge> graphEdges) {
    final key = edge.key;
    if (key is ValueKey) {
      return key.value.toString();
    }
    final graphIndex = graphEdges.indexOf(edge);
    final stableIndex = graphIndex < 0 ? graphEdges.length : graphIndex;
    final padWidth = math.max(8, graphEdges.length.toString().length);
    return stableIndex.toString().padLeft(padWidth, '0');
  }
}
