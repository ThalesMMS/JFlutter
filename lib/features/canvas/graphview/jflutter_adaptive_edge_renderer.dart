import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'grouped_fsa_geometry.dart';

enum JFlutterEdgeRenderMode { standard, groupedFsa }

/// Thin JFlutter-specific edge renderer layered on top of GraphView's adaptive
/// routing and animation primitives.
class JFlutterAdaptiveEdgeRenderer extends AnimatedAdaptiveEdgeRenderer {
  JFlutterAdaptiveEdgeRenderer({
    required super.config,
    super.animationConfig,
    this.baseColor = Colors.black,
    this.highlightColor = Colors.blue,
    this.labelSurfaceColor = Colors.white,
    this.labelFontSize = 14.0,
    this.renderMode = JFlutterEdgeRenderMode.standard,
  });

  static const double _selectedStrokeWidth = 4.0;
  static const double _normalStrokeWidth = 2.0;
  static const double _loopLabelOffset = 10.0;
  static const double _groupLaneSpacing = 34.0;
  static const double _labelPaddingHorizontal = 10.0;
  static const double _labelPaddingVertical = 8.0;
  static const double _labelLineSpacing = 4.0;
  static const double _labelPathGap = 14.0;
  static const double _groupedLoopLabelGap = 6.0;
  static const double _labelScrollGap = 14.0;
  static const double _labelScrollPixelsPerTurn = 8.0;
  static const double _labelCollisionStep = 14.0;
  static const double _labelPathClearance = 10.0;
  static const double _labelNodeClearance = 12.0;
  static const double _labelCardSpacing = 12.0;
  static const int _maxVisibleGroupedLabels = 5;
  static const int _labelCollisionAttempts = 6;

  Set<String> _highlightedEdgeIds = const <String>{};
  Set<String> _selectedEdgeIds = const <String>{};
  double _animationTurnCount = 0.0;
  double _lastAnimationValue = 0.0;

  Color baseColor;
  Color highlightColor;
  Color labelSurfaceColor;
  double labelFontSize;
  JFlutterEdgeRenderMode renderMode;

  @override
  void setAnimationValue(double value) {
    if (value + 0.05 < _lastAnimationValue) {
      _animationTurnCount += 1.0;
    }
    _lastAnimationValue = value;
    super.setAnimationValue(value);
  }

  void updateAppearance({
    required Set<String> highlightedEdgeIds,
    required Set<String> selectedEdgeIds,
    required Color baseColor,
    required Color highlightColor,
    required Color labelSurfaceColor,
  }) {
    _highlightedEdgeIds = Set<String>.from(highlightedEdgeIds);
    _selectedEdgeIds = Set<String>.from(selectedEdgeIds);
    this.baseColor = baseColor;
    this.highlightColor = highlightColor;
    this.labelSurfaceColor = labelSurfaceColor;
  }

  @visibleForTesting
  double debugLaneOffsetForEdge(Edge edge) => _laneOffsetForDirectedPair(edge);

  @visibleForTesting
  Path? debugGroupedPathForEdge(Edge edge) {
    if (renderMode != JFlutterEdgeRenderMode.groupedFsa) {
      return null;
    }
    final groupedGeometry = _debugGroupedGeometry(edge);
    return groupedGeometry?.geometry.path;
  }

  @visibleForTesting
  Rect? debugGroupedLabelRectForEdge(Edge edge) {
    if (renderMode != JFlutterEdgeRenderMode.groupedFsa) {
      return null;
    }
    final representative = _groupRepresentative(edge);
    final groupedGeometry = _debugGroupedGeometry(representative);
    if (groupedGeometry == null) {
      return null;
    }
    final groupedEdges = _groupedEdges(representative)
        .where((candidate) => (candidate.label ?? '').trim().isNotEmpty)
        .toList(growable: false);
    if (groupedEdges.isEmpty) {
      return null;
    }
    final labelEntries = groupedEdges
        .map((groupedEdge) =>
            _GroupedLabelEntry(painter: _buildLabelPainter(groupedEdge)))
        .toList(growable: false);
    return _resolveGroupedLabelRect(
        representative, groupedGeometry, labelEntries);
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    if (edge.renderer != null) {
      edge.renderer!.renderEdge(canvas, edge, paint);
      return;
    }

    prepareForRenderCycle();

    if (renderMode == JFlutterEdgeRenderMode.groupedFsa) {
      _renderGroupedFsaEdge(canvas, edge);
      return;
    }

    if (edge.source == edge.destination) {
      _renderSelfLoopCluster(canvas, edge);
      return;
    }

    final geometry = buildEdgeGeometry(
      edge,
      arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
    );
    if (geometry == null) {
      return;
    }

    final edgeId = _edgeId(edge);
    final strokePaint = _buildStrokePaint(
      highlighted: _isHighlighted(edgeId),
      selected: _isSelected(edgeId),
    );

    paintEdgeGeometry(canvas, edge, strokePaint, geometry);

    if (!noArrow) {
      paintEdgeArrow(
        canvas,
        edge,
        _buildFillPaint(highlighted: _isHighlighted(edgeId)),
        geometry,
      );
    }

    if (_isHighlighted(edgeId)) {
      renderAnimatedParticlesOnPath(
        canvas,
        edge,
        _buildFillPaint(highlighted: true),
        geometry.path,
      );
    }

    if ((edge.label ?? '').isEmpty) {
      return;
    }

    final labelGeometry = buildLabelGeometry(edge, geometry.path);
    if (labelGeometry == null) {
      return;
    }

    final previousStyle = edge.labelStyle;
    final previousDirection = edge.labelFollowsEdgeDirection;
    edge
      ..labelStyle = TextStyle(
        color: _colorFor(highlighted: _isHighlighted(edgeId)),
        fontSize: labelFontSize,
      )
      ..labelFollowsEdgeDirection = false;
    try {
      renderEdgeLabel(canvas, edge, labelGeometry.position, null);
    } finally {
      edge
        ..labelStyle = previousStyle
        ..labelFollowsEdgeDirection = previousDirection;
    }
  }

  void _renderGroupedFsaEdge(Canvas canvas, Edge edge) {
    final groupedEdges = _groupedEdges(edge);
    if (groupedEdges.isEmpty || !identical(groupedEdges.first, edge)) {
      return;
    }

    final anyHighlighted =
        groupedEdges.any((candidate) => _isHighlighted(_edgeId(candidate)));
    final anySelected =
        groupedEdges.any((candidate) => _isSelected(_edgeId(candidate)));

    final groupedGeometry = edge.source == edge.destination
        ? _buildGroupedSelfLoopGeometry(edge, groupedEdges)
        : _buildGroupedNormalGeometry(edge);
    if (groupedGeometry == null) {
      return;
    }

    final strokePaint = _buildStrokePaint(
      highlighted: anyHighlighted,
      selected: anySelected,
    );

    paintEdgeGeometry(canvas, edge, strokePaint, groupedGeometry.geometry);

    if (!noArrow) {
      paintEdgeArrow(
        canvas,
        edge,
        _buildFillPaint(highlighted: anyHighlighted),
        groupedGeometry.geometry,
      );
    }

    if (anyHighlighted) {
      renderAnimatedParticlesOnPath(
        canvas,
        edge,
        _buildFillPaint(highlighted: true),
        groupedGeometry.geometry.path,
      );
    }

    final labeledEdges = groupedEdges
        .where((candidate) => (candidate.label ?? '').trim().isNotEmpty)
        .toList(growable: false);
    if (labeledEdges.isEmpty) {
      return;
    }

    _paintGroupedEdgeLabels(
      canvas,
      edge,
      groupedGeometry,
      labeledEdges,
      anyHighlighted: anyHighlighted,
      anySelected: anySelected,
    );
  }

  void _renderSelfLoopCluster(Canvas canvas, Edge edge) {
    final group = _selfLoopEdges(edge);
    if (group.isEmpty || !identical(group.first, edge)) {
      return;
    }

    final geometry = buildEdgeGeometry(
      edge,
      arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
    );
    if (geometry == null) {
      return;
    }

    final anyHighlighted =
        group.any((candidate) => _isHighlighted(_edgeId(candidate)));
    final anySelected =
        group.any((candidate) => _isSelected(_edgeId(candidate)));
    final strokePaint = _buildStrokePaint(
      highlighted: anyHighlighted,
      selected: anySelected,
    );

    paintEdgeGeometry(canvas, edge, strokePaint, geometry);

    if (!noArrow) {
      paintEdgeArrow(
        canvas,
        edge,
        _buildFillPaint(highlighted: anyHighlighted),
        geometry,
      );
    }

    if (anyHighlighted) {
      renderAnimatedParticlesOnPath(
        canvas,
        edge,
        _buildFillPaint(highlighted: true),
        geometry.path,
      );
    }

    final bounds = geometry.path.getBounds();
    final anchor = Offset(bounds.center.dx, bounds.top - _loopLabelOffset);

    var previousTopFromAnchor = 0.0;
    for (var i = 0; i < group.length; i++) {
      final loopEdge = group[i];
      if ((loopEdge.label ?? '').isEmpty) {
        continue;
      }

      final isHighlighted = _isHighlighted(_edgeId(loopEdge));
      final textPainter = TextPainter(
        text: TextSpan(
          text: loopEdge.label,
          style: TextStyle(
            color: _colorFor(highlighted: isHighlighted),
            fontSize: labelFontSize,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      double centerFromAnchor;
      if (i == 0) {
        centerFromAnchor = 0.0;
        previousTopFromAnchor = textPainter.height / 2;
      } else {
        centerFromAnchor = previousTopFromAnchor + 2.0 + textPainter.height / 2;
        previousTopFromAnchor = centerFromAnchor + textPainter.height / 2;
      }

      final drawOffset = Offset(
        anchor.dx - textPainter.width / 2,
        anchor.dy - centerFromAnchor - textPainter.height / 2,
      );
      textPainter.paint(canvas, drawOffset);
    }
  }

  List<Edge> _selfLoopEdges(Edge edge) {
    final currentGraph = graph;
    if (currentGraph == null) {
      return <Edge>[edge];
    }
    return _sortEdges(
      currentGraph.edges.where(
        (candidate) =>
            candidate.source == edge.source &&
            candidate.destination == edge.destination,
      ),
    );
  }

  List<Edge> _groupedEdges(Edge edge) {
    final currentGraph = graph;
    if (currentGraph == null) {
      return <Edge>[edge];
    }
    return _sortEdges(
      currentGraph.edges.where(
        (candidate) =>
            candidate.source == edge.source &&
            candidate.destination == edge.destination,
      ),
    );
  }

  List<Edge> _sortEdges(Iterable<Edge> edges) {
    final sorted = edges.toList(growable: false);
    sorted.sort((left, right) {
      final labelCompare = _edgeLabel(left).compareTo(_edgeLabel(right));
      if (labelCompare != 0) {
        return labelCompare;
      }
      return _edgeId(left).compareTo(_edgeId(right));
    });
    return sorted;
  }

  Edge _groupRepresentative(Edge edge) {
    final grouped = _groupedEdges(edge);
    if (grouped.isEmpty) {
      return edge;
    }
    return grouped.first;
  }

  _GroupedFsaRenderGeometry? _buildGroupedNormalGeometry(Edge edge) {
    final sourceCenter = getNodeCenter(edge.source);
    final destinationCenter = getNodeCenter(edge.destination);
    final laneOffset = _laneOffsetForDirectedPair(edge);
    final controlPoint = resolveGroupedFsaControlPoint(
      fromId: _nodeId(edge.source),
      toId: _nodeId(edge.destination),
      fromCenter: sourceCenter,
      toCenter: destinationCenter,
      hasOpposingTraffic: _hasOpposingTraffic(edge),
      spacing: _groupLaneSpacing,
    );
    final sourcePoint = calculateSourceConnectionPoint(edge, controlPoint, 0);
    final destinationPoint = calculateDestinationConnectionPoint(
      edge,
      controlPoint,
      0,
    );

    final path = Path()
      ..moveTo(sourcePoint.dx, sourcePoint.dy)
      ..quadraticBezierTo(
        controlPoint.dx,
        controlPoint.dy,
        destinationPoint.dx,
        destinationPoint.dy,
      );

    return _GroupedFsaRenderGeometry(
      geometry: buildPathGeometry(
        path,
        arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
      ),
      laneOffset: laneOffset,
    );
  }

  _GroupedFsaRenderGeometry? _buildGroupedSelfLoopGeometry(
    Edge edge,
    List<Edge> groupedEdges,
  ) {
    final loopPadding =
        16.0 + resolveGroupedFsaLoopExtraOffset(groupedEdges.length);
    final loopResult = buildSelfLoopPath(
      edge,
      loopPadding: loopPadding,
      arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
    );
    if (loopResult == null) {
      return null;
    }

    final geometry = buildPathGeometry(
      loopResult.path,
      arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
      isSelfLoop: true,
    );
    return _GroupedFsaRenderGeometry(
      geometry: EdgePathGeometry(
        path: geometry.path,
        start: geometry.start,
        end: geometry.end,
        arrowBase: loopResult.arrowBase,
        arrowTip: loopResult.arrowTip,
        isSelfLoop: true,
      ),
      laneOffset: 0.0,
    );
  }

  _GroupedFsaRenderGeometry? _debugGroupedGeometry(Edge edge) {
    final representative = _groupRepresentative(edge);
    return representative.source == representative.destination
        ? _buildGroupedSelfLoopGeometry(
            representative, _groupedEdges(representative))
        : _buildGroupedNormalGeometry(representative);
  }

  bool _hasOpposingTraffic(Edge edge) {
    final currentGraph = graph;
    if (currentGraph == null) {
      return false;
    }
    return currentGraph.edges.any(
      (candidate) =>
          candidate.source == edge.destination &&
          candidate.destination == edge.source,
    );
  }

  double _laneOffsetForDirectedPair(Edge edge) {
    return resolveGroupedFsaLaneOffset(
      fromId: _nodeId(edge.source),
      toId: _nodeId(edge.destination),
      hasOpposingTraffic: _hasOpposingTraffic(edge),
      spacing: _groupLaneSpacing,
    );
  }

  void _paintGroupedEdgeLabels(
    Canvas canvas,
    Edge edge,
    _GroupedFsaRenderGeometry groupedGeometry,
    List<Edge> groupedEdges, {
    required bool anyHighlighted,
    required bool anySelected,
  }) {
    final labelEntries = groupedEdges
        .map((edge) => _GroupedLabelEntry(painter: _buildLabelPainter(edge)))
        .toList(growable: false);
    if (labelEntries.isEmpty) {
      return;
    }

    final maxVisible = math.min(_maxVisibleGroupedLabels, labelEntries.length);
    final totalHeight = _sumLabelHeights(labelEntries);
    final visibleHeight = _sumLabelHeights(labelEntries.take(maxVisible));
    final cardRect =
        _resolveGroupedLabelRect(edge, groupedGeometry, labelEntries);
    final borderColor = _colorFor(highlighted: anyHighlighted).withValues(
      alpha: anyHighlighted || anySelected ? 0.55 : 0.22,
    );
    final cardRRect =
        RRect.fromRectAndRadius(cardRect, const Radius.circular(12));

    canvas.drawShadow(
      Path()..addRRect(cardRRect),
      Colors.black.withValues(alpha: 0.16),
      4,
      false,
    );
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = labelSurfaceColor.withValues(alpha: 0.96)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final overflowHeight = math.max(0.0, totalHeight - visibleHeight);
    final cycleDistance = overflowHeight + _labelScrollGap;
    final scrollOffset =
        labelEntries.length > _maxVisibleGroupedLabels && cycleDistance > 0
            ? (_continuousAnimationValue * _labelScrollPixelsPerTurn) %
                cycleDistance
            : 0.0;

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        cardRect.left + 1,
        cardRect.top + 1,
        cardRect.width - 2,
        cardRect.height - 2,
      ),
    );

    final contentLeft = cardRect.left + _labelPaddingHorizontal;
    final contentTop = cardRect.top + _labelPaddingVertical - scrollOffset;
    _paintLabelColumn(canvas, labelEntries, contentLeft, contentTop);
    if (scrollOffset > 0) {
      _paintLabelColumn(
        canvas,
        labelEntries,
        contentLeft,
        contentTop + totalHeight + _labelScrollGap,
      );
    }
    canvas.restore();
  }

  TextPainter _buildLabelPainter(Edge edge) {
    final edgeId = _edgeId(edge);
    final isHighlighted = _isHighlighted(edgeId);
    final isSelected = _isSelected(edgeId);
    return TextPainter(
      text: TextSpan(
        text: edge.label,
        style: TextStyle(
          color: _colorFor(highlighted: isHighlighted),
          fontSize: labelFontSize,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  double _sumLabelHeights(Iterable<_GroupedLabelEntry> entries) {
    var totalHeight = 0.0;
    var index = 0;
    for (final entry in entries) {
      if (index > 0) {
        totalHeight += _labelLineSpacing;
      }
      totalHeight += entry.painter.height;
      index++;
    }
    return totalHeight;
  }

  void _paintLabelColumn(
    Canvas canvas,
    List<_GroupedLabelEntry> entries,
    double left,
    double top,
  ) {
    var y = top;
    for (final entry in entries) {
      entry.painter.paint(canvas, Offset(left, y));
      y += entry.painter.height + _labelLineSpacing;
    }
  }

  Rect _resolveGroupedLabelRect(
    Edge edge,
    _GroupedFsaRenderGeometry groupedGeometry,
    List<_GroupedLabelEntry> labelEntries,
  ) {
    final maxVisible = math.min(_maxVisibleGroupedLabels, labelEntries.length);
    final maxWidth = labelEntries.fold<double>(
      0.0,
      (current, entry) => math.max(current, entry.painter.width),
    );
    final visibleHeight = _sumLabelHeights(labelEntries.take(maxVisible));
    final cardWidth = maxWidth + (_labelPaddingHorizontal * 2);
    final cardHeight = visibleHeight + (_labelPaddingVertical * 2);

    return groupedGeometry.geometry.isSelfLoop
        ? _resolveSelfLoopLabelRect(
            edge,
            groupedGeometry.geometry,
            cardWidth,
            cardHeight,
          )
        : _resolveNormalLabelRect(
            edge,
            groupedGeometry,
            cardWidth,
            cardHeight,
          );
  }

  Rect _resolveNormalLabelRect(
    Edge edge,
    _GroupedFsaRenderGeometry groupedGeometry,
    double cardWidth,
    double cardHeight,
  ) {
    final metric = groupedGeometry.geometry.path.computeMetrics().firstOrNull;
    final anchor = metric?.getTangentForOffset(metric.length * 0.5)?.position ??
        groupedGeometry.geometry.path.getBounds().center;
    final sourceCenter = getNodeCenter(edge.source);
    final destinationCenter = getNodeCenter(edge.destination);
    final normal = resolveGroupedFsaLabelNormal(
      fromId: _nodeId(edge.source),
      toId: _nodeId(edge.destination),
      fromCenter: sourceCenter,
      toCenter: destinationCenter,
      laneOffset: groupedGeometry.laneOffset,
    );
    final baseRect = Rect.fromCenter(
      center: anchor + (normal * (_labelPathGap + (cardHeight / 2))),
      width: cardWidth,
      height: cardHeight,
    );
    final opposingRect = _buildOpposingBaseLabelRect(edge);
    return _resolveLabelRectCollision(
      baseRect,
      normal,
      groupedGeometry.geometry.path,
      edge,
      opposingRect,
    );
  }

  Rect _resolveSelfLoopLabelRect(
    Edge edge,
    EdgePathGeometry geometry,
    double cardWidth,
    double cardHeight,
  ) {
    final metric = geometry.path.computeMetrics().firstOrNull;
    final nodeCenter = getNodeCenter(edge.source);
    final anchorOffset =
        metric != null ? math.min(metric.length * 0.42, metric.length) : 0.0;
    final anchor =
        metric?.getTangentForOffset(anchorOffset)?.position ??
        geometry.path.getBounds().topRight;

    var radial = anchor - nodeCenter;
    if (radial.distanceSquared < 0.0001) {
      radial = const Offset(1, -1);
    }
    radial = radial / radial.distance;

    final projectedHalfExtent =
        (radial.dx.abs() * (cardWidth / 2)) +
        (radial.dy.abs() * (cardHeight / 2));

    var rect = Rect.fromCenter(
      center: anchor + (radial * (projectedHalfExtent + _groupedLoopLabelGap)),
      width: cardWidth,
      height: cardHeight,
    );

    for (var attempt = 0; attempt < _labelCollisionAttempts; attempt++) {
      if (!_labelRectCollides(rect, geometry.path, edge, null)) {
        return rect;
      }
      rect = rect.shift(
        radial * (_labelCollisionStep + (attempt * 4.0)),
      );
    }

    return rect;
  }

  Rect? _buildOpposingBaseLabelRect(Edge edge) {
    final currentGraph = graph;
    if (currentGraph == null || edge.source == edge.destination) {
      return null;
    }

    final opposingGroup = _sortEdges(
      currentGraph.edges.where(
        (candidate) =>
            candidate.source == edge.destination &&
            candidate.destination == edge.source,
      ),
    );
    if (opposingGroup.isEmpty) {
      return null;
    }

    final opposingRepresentative = opposingGroup.first;
    final labeledEdges = opposingGroup
        .where((candidate) => (candidate.label ?? '').trim().isNotEmpty)
        .toList(growable: false);
    if (labeledEdges.isEmpty) {
      return null;
    }

    final groupedGeometry = _buildGroupedNormalGeometry(opposingRepresentative);
    if (groupedGeometry == null) {
      return null;
    }

    final labelEntries = labeledEdges
        .map((groupedEdge) =>
            _GroupedLabelEntry(painter: _buildLabelPainter(groupedEdge)))
        .toList(growable: false);
    final maxVisible = math.min(_maxVisibleGroupedLabels, labelEntries.length);
    final maxWidth = labelEntries.fold<double>(
      0.0,
      (current, entry) => math.max(current, entry.painter.width),
    );
    final visibleHeight = _sumLabelHeights(labelEntries.take(maxVisible));
    final cardWidth = maxWidth + (_labelPaddingHorizontal * 2);
    final cardHeight = visibleHeight + (_labelPaddingVertical * 2);
    final metric = groupedGeometry.geometry.path.computeMetrics().firstOrNull;
    final anchor = metric?.getTangentForOffset(metric.length * 0.5)?.position ??
        groupedGeometry.geometry.path.getBounds().center;
    final normal = resolveGroupedFsaLabelNormal(
      fromId: _nodeId(opposingRepresentative.source),
      toId: _nodeId(opposingRepresentative.destination),
      fromCenter: getNodeCenter(opposingRepresentative.source),
      toCenter: getNodeCenter(opposingRepresentative.destination),
      laneOffset: groupedGeometry.laneOffset,
    );
    return Rect.fromCenter(
      center: anchor + (normal * (_labelPathGap + (cardHeight / 2))),
      width: cardWidth,
      height: cardHeight,
    );
  }

  Rect _resolveLabelRectCollision(
    Rect rect,
    Offset normal,
    Path path,
    Edge edge,
    Rect? opposingRect,
  ) {
    var resolved = rect;
    for (var attempt = 0; attempt < _labelCollisionAttempts; attempt++) {
      if (!_labelRectCollides(resolved, path, edge, opposingRect)) {
        return resolved;
      }
      resolved = resolved.shift(
        normal * (_labelCollisionStep + (attempt * 4.0)),
      );
    }
    return resolved;
  }

  bool _labelRectCollides(
    Rect rect,
    Path path,
    Edge edge,
    Rect? opposingRect,
  ) {
    if (opposingRect != null &&
        rect.inflate(_labelCardSpacing).overlaps(opposingRect)) {
      return true;
    }
    if (_rectTooCloseToNode(rect, edge.source) ||
        _rectTooCloseToNode(rect, edge.destination)) {
      return true;
    }
    return _rectTooCloseToPath(rect, path);
  }

  bool _rectTooCloseToNode(Rect rect, Node node) {
    final nodeRect = Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      node.width,
      node.height,
    );
    return rect.inflate(_labelNodeClearance).overlaps(nodeRect);
  }

  bool _rectTooCloseToPath(Rect rect, Path path) {
    final metric = path.computeMetrics().firstOrNull;
    if (metric == null) {
      return false;
    }

    final probe = rect.inflate(_labelPathClearance);
    const samples = 24;
    for (var index = 0; index <= samples; index++) {
      final tangent =
          metric.getTangentForOffset(metric.length * (index / samples));
      if (tangent != null && probe.contains(tangent.position)) {
        return true;
      }
    }
    return false;
  }

  String _nodeId(Node node) {
    final key = node.key;
    if (key is ValueKey) {
      return key.value.toString();
    }
    return node.hashCode.toString();
  }

  String _edgeLabel(Edge edge) => (edge.label ?? '').trim();

  double get _continuousAnimationValue => _animationTurnCount + animationValue;

  String _edgeId(Edge edge) {
    final key = edge.key;
    if (key is ValueKey) {
      return key.value.toString();
    }
    return edge.hashCode.toString();
  }

  bool _isHighlighted(String edgeId) => _highlightedEdgeIds.contains(edgeId);

  bool _isSelected(String edgeId) => _selectedEdgeIds.contains(edgeId);

  Paint _buildStrokePaint({
    required bool highlighted,
    required bool selected,
  }) {
    return Paint()
      ..color = _colorFor(highlighted: highlighted)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? _selectedStrokeWidth : _normalStrokeWidth
      ..strokeCap = StrokeCap.round;
  }

  Paint _buildFillPaint({required bool highlighted}) {
    return Paint()
      ..color = _colorFor(highlighted: highlighted)
      ..style = PaintingStyle.fill;
  }

  Color _colorFor({required bool highlighted}) {
    return highlighted ? highlightColor : baseColor;
  }
}

class _GroupedFsaRenderGeometry {
  const _GroupedFsaRenderGeometry({
    required this.geometry,
    required this.laneOffset,
  });

  final EdgePathGeometry geometry;
  final double laneOffset;
}

class _GroupedLabelEntry {
  const _GroupedLabelEntry({required this.painter});

  final TextPainter painter;
}
