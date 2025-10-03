import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';

import '../../../core/models/simulation_highlight.dart';
import 'fl_nodes_canvas_models.dart';
import 'fl_nodes_highlight_controller.dart';

/// Shared viewport and highlight helpers for fl_nodes canvas controllers.
mixin FlNodesViewportHighlightMixin on FlNodesHighlightController {
  /// Exposes the underlying editor controller.
  FlNodeEditorController get controller;

  /// Provides access to the cached canvas nodes.
  Map<String, FlNodesCanvasNode> get nodesCache;

  /// Notifier used to broadcast highlight updates to listeners.
  final ValueNotifier<SimulationHighlight> highlightNotifier = ValueNotifier(
    SimulationHighlight.empty,
  );

  /// Tracks the ids of the transitions currently highlighted.
  final Set<String> highlightedTransitionIds = <String>{};

  /// Releases the resources owned by the mixin.
  void disposeViewportHighlight() {
    highlightNotifier.dispose();
  }

  /// Increases the viewport zoom while respecting reasonable bounds.
  void zoomIn() {
    controller.setViewportZoom(
      (controller.viewportZoom * 1.2).clamp(0.05, 10.0),
    );
  }

  /// Decreases the viewport zoom while respecting reasonable bounds.
  void zoomOut() {
    controller.setViewportZoom(
      (controller.viewportZoom / 1.2).clamp(0.05, 10.0),
    );
  }

  /// Resets the viewport offset and zoom to their defaults.
  void resetView() {
    controller.setViewportOffset(Offset.zero, absolute: true);
    controller.setViewportZoom(1.0);
  }

  /// Adjusts the viewport to focus on the available nodes while
  /// preserving the previous selection.
  void fitToContent() {
    if (nodesCache.isEmpty) {
      resetView();
      return;
    }

    final previousNodeSelection = controller.selectedNodeIds.toList();
    final previousLinkSelection = controller.selectedLinkIds.toList();

    controller.focusNodesById(nodesCache.keys.toSet());
    controller.clearSelection(isHandled: true);

    if (previousNodeSelection.isNotEmpty) {
      controller.selectNodesById(
        previousNodeSelection.toSet(),
        holdSelection: false,
        isHandled: true,
      );
    }

    if (previousLinkSelection.isNotEmpty) {
      controller.selectLinkById(
        previousLinkSelection.first,
        holdSelection: false,
        isHandled: true,
      );
      for (final linkId in previousLinkSelection.skip(1)) {
        controller.selectLinkById(linkId, holdSelection: true, isHandled: true);
      }
    }
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

  /// Updates the link selection to match the provided highlighted ids.
  void updateLinkHighlights(Set<String> transitionIds) {
    final desiredIds = Set<String>.from(transitionIds);
    final idsToVisit = <String>{...highlightedTransitionIds, ...desiredIds};

    final manualSelection = controller.selectedLinkIds.toSet();
    var hasChanged = false;

    for (final linkId in idsToVisit) {
      final link = controller.linksById[linkId];
      if (link == null) {
        continue;
      }
      final shouldSelect =
          desiredIds.contains(linkId) || manualSelection.contains(linkId);
      if (link.state.isSelected != shouldSelect) {
        link.state.isSelected = shouldSelect;
        hasChanged = true;
      }
    }

    if (hasChanged) {
      controller.linksDataDirty = true;
      controller.notifyListeners();
    }

    highlightedTransitionIds
      ..clear()
      ..addAll(desiredIds);
  }
}
