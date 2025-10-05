import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import '../../../core/models/simulation_highlight.dart';
import 'graphview_canvas_models.dart';
import 'graphview_highlight_controller.dart';

/// Shared viewport and highlight helpers for GraphView canvas controllers.
mixin GraphViewViewportHighlightMixin on GraphViewHighlightController {
  /// Exposes the underlying graph structure managed by the controller.
  Graph get graph;

  /// Provides access to the GraphView controller responsible for viewport
  /// operations.
  GraphViewController get graphController;

  /// Provides access to the cached canvas nodes.
  Map<String, GraphViewCanvasNode> get nodesCache;

  /// Provides access to the cached canvas edges.
  Map<String, GraphViewCanvasEdge> get edgesCache;

  /// Notifier used to broadcast highlight updates to listeners.
  final ValueNotifier<SimulationHighlight> highlightNotifier = ValueNotifier(
    SimulationHighlight.empty,
  );

  /// Notifier that indicates when the rendered graph should be repainted.
  final ValueNotifier<int> graphRevision = ValueNotifier<int>(0);

  /// Tracks the ids of the transitions currently highlighted.
  final Set<String> highlightedTransitionIds = <String>{};

  /// Releases the resources owned by the mixin.
  void disposeViewportHighlight() {
    highlightNotifier.dispose();
    graphRevision.dispose();
  }

  /// Hook invoked whenever the highlighted transitions change.
  @protected
  void onHighlightedTransitionsChanged(Set<String> transitionIds) {}

  double _extractScale(Matrix4 matrix) {
    final storage = matrix.storage;
    final scaleX = math.sqrt(storage[0] * storage[0] +
        storage[1] * storage[1] +
        storage[2] * storage[2]);
    final scaleY = math.sqrt(storage[4] * storage[4] +
        storage[5] * storage[5] +
        storage[6] * storage[6]);
    if (scaleX == 0 && scaleY == 0) {
      return 1.0;
    }
    if (scaleX == 0) {
      return scaleY.abs();
    }
    if (scaleY == 0) {
      return scaleX.abs();
    }
    return (scaleX.abs() + scaleY.abs()) / 2;
  }

  void _applyScale(double factor) {
    final transformation = graphController.transformationController;
    if (transformation == null) {
      return;
    }

    final matrix = Matrix4.copy(transformation.value);
    final currentScale = _extractScale(matrix);
    final safeCurrent = currentScale == 0 ? 1.0 : currentScale;
    final targetScale = (safeCurrent * factor).clamp(0.05, 10.0);
    final relativeScale = targetScale / safeCurrent;
    matrix.scale(relativeScale);
    transformation.value = matrix;
  }

  /// Increases the viewport zoom while respecting reasonable bounds.
  void zoomIn() {
    _applyScale(1.2);
  }

  /// Decreases the viewport zoom while respecting reasonable bounds.
  void zoomOut() {
    _applyScale(1 / 1.2);
  }

  /// Resets the viewport offset and zoom to their defaults.
  void resetView() {
    final transformation = graphController.transformationController;
    transformation?.value = Matrix4.identity();
    graphController.resetView();
  }

  /// Adjusts the viewport to focus on the available nodes.
  void fitToContent() {
    if (graph.nodes.isEmpty) {
      resetView();
      return;
    }
    graphController.zoomToFit();
  }

  @override
  void applyHighlight(SimulationHighlight highlight) {
    updateLinkHighlights(highlight.transitionIds);
    highlightNotifier.value = highlight;
  }

  @override
  void clearHighlight() {
    updateLinkHighlights(const <String>{});
    highlightNotifier.value = SimulationHighlight.empty;
  }

  /// Updates the edge highlight set to match the provided ids.
  void updateLinkHighlights(Set<String> transitionIds) {
    final desiredIds = Set<String>.from(transitionIds);
    if (setEquals(desiredIds, highlightedTransitionIds)) {
      return;
    }

    highlightedTransitionIds
      ..clear()
      ..addAll(desiredIds);

    onHighlightedTransitionsChanged(highlightedTransitionIds);
    graphRevision.value++;
  }
}
