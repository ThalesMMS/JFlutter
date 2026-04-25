import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'grouped_fsa_geometry.dart';

part 'jflutter_adaptive_edge_renderer_compat.dart';
part 'jflutter_adaptive_edge_renderer_grouped_rendering.dart';
part 'jflutter_adaptive_edge_renderer_grouped_geometry.dart';
part 'jflutter_adaptive_edge_renderer_label_layout.dart';
part 'jflutter_adaptive_edge_renderer_cache.dart';
part 'jflutter_adaptive_edge_renderer_models.dart';

enum JFlutterEdgeRenderMode { standard, groupedFsa }

const double _selectedStrokeWidth = 4.0;
const double _normalStrokeWidth = 2.0;
const double _loopLabelOffset = 10.0;
const double _groupLaneSpacing = 34.0;
const double _labelPaddingHorizontal = 10.0;
const double _labelPaddingVertical = 8.0;
const double _labelLineSpacing = 4.0;
const double _labelPathGap = 14.0;
const double _groupedLoopLabelGap = 6.0;
const double _labelScrollGap = 14.0;
const double _labelScrollPixelsPerTurn = 8.0;
const double _labelCollisionStep = 14.0;
const double _labelPathClearance = 10.0;
const double _labelNodeClearance = 12.0;
const double _labelCardSpacing = 12.0;
const int _maxVisibleGroupedLabels = 5;
const int _labelCollisionAttempts = 6;
const int _maxCachedLabelPainters = 200;

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

  Set<String> _highlightedEdgeIds = const <String>{};
  Set<String> _selectedEdgeIds = const <String>{};
  double _animationTurnCount = 0.0;
  double _lastAnimationValue = 0.0;
  final Map<_DirectedEdgePair, List<Edge>> _groupedEdgeCache =
      <_DirectedEdgePair, List<Edge>>{};
  final Set<_DirectedEdgePair> _opposingTrafficCache = <_DirectedEdgePair>{};
  final LinkedHashMap<_LabelPainterCacheKey, TextPainter> _labelPainterCache =
      LinkedHashMap<_LabelPainterCacheKey, TextPainter>();
  final Set<TextPainter> _activeLabelPainters = HashSet<TextPainter>.identity();
  final Set<TextPainter> _transientLabelPainters =
      HashSet<TextPainter>.identity();
  Graph? _edgeCacheGraph;
  int _edgeCacheCount = -1;
  bool _edgeCachesDirty = true;

  Color baseColor;
  Color highlightColor;
  Color labelSurfaceColor;
  double labelFontSize;
  JFlutterEdgeRenderMode renderMode;

  @override
  void setGraph(Graph graph) {
    if (identical(graph, this.graph)) {
      return;
    }
    super.setGraph(graph);
    _invalidateEdgeCaches();
  }

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
    final labelStyleChanged =
        this.baseColor != baseColor || this.highlightColor != highlightColor;
    _highlightedEdgeIds = Set<String>.from(highlightedEdgeIds);
    _selectedEdgeIds = Set<String>.from(selectedEdgeIds);
    this.baseColor = baseColor;
    this.highlightColor = highlightColor;
    this.labelSurfaceColor = labelSurfaceColor;
    if (labelStyleChanged) {
      _clearLabelPainterCache();
    }
  }

  @override
  void prepareForRenderCycle() {
    super.prepareForRenderCycle();
    _ensureEdgeCaches();
  }

  void invalidateEdgeCaches() {
    _invalidateEdgeCaches();
  }

  @visibleForTesting
  double debugLaneOffsetForEdge(Edge edge) => _laneOffsetForDirectedPair(edge);

  @visibleForTesting
  Path? debugGroupedPathForEdge(Edge edge) {
    if (renderMode != JFlutterEdgeRenderMode.groupedFsa) {
      return null;
    }
    final groupedGeometry = _representativeGroupedGeometry(edge);
    return groupedGeometry?.geometry.path;
  }

  @visibleForTesting
  Rect? debugGroupedLabelRectForEdge(Edge edge) {
    if (renderMode != JFlutterEdgeRenderMode.groupedFsa) {
      return null;
    }
    final representative = _groupRepresentative(edge);
    final groupedGeometry = _representativeGroupedGeometry(representative);
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
        .map(
          (groupedEdge) =>
              _GroupedLabelEntry(painter: _buildLabelPainter(groupedEdge)),
        )
        .toList(growable: false);
    try {
      return _resolveGroupedLabelRect(
        representative,
        groupedGeometry,
        labelEntries,
      );
    } finally {
      _releaseLabelEntries(labelEntries);
    }
  }

  @visibleForTesting
  String debugGroupRepresentativeId(Edge edge) =>
      _edgeId(_groupRepresentative(edge));

  @visibleForTesting
  int get debugLabelPainterCacheSize => _labelPainterCache.length;

  @visibleForTesting
  int get debugGroupedEdgeCacheSize => _groupedEdgeCache.length;

  @visibleForTesting
  int get debugOpposingTrafficCacheSize => _opposingTrafficCache.length;

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    if (edge.renderer != null) {
      edge.renderer!.renderEdge(canvas, edge, paint);
      return;
    }

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
}
