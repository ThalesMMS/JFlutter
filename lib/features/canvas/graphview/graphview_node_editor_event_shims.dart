import 'dart:ui';

/// Lightweight payload describing the result of a drag-selection gesture within
/// the GraphView canvas.
class GraphViewDragSelectionEndEventPayload {
  const GraphViewDragSelectionEndEventPayload({
    required this.nodeIds,
    this.position,
  });

  final Set<String> nodeIds;
  final Offset? position;
}

/// Payload describing the selected transitions inside the GraphView canvas.
class GraphViewLinkSelectionEventPayload {
  const GraphViewLinkSelectionEventPayload({required this.linkIds});

  final Set<String> linkIds;
}

/// Payload describing transitions that have been deselected.
class GraphViewLinkDeselectionEventPayload {
  const GraphViewLinkDeselectionEventPayload({required this.linkIds});

  final Set<String> linkIds;
}

/// Payload emitted when a transition is removed from the GraphView canvas.
class GraphViewRemoveLinkEventPayload {
  const GraphViewRemoveLinkEventPayload({required this.linkId});

  final String linkId;
}

/// Utility helpers to standardise payloads emitted by custom interaction
/// handlers built on top of the GraphView canvas. The helpers accept raw inputs
/// (such as `Iterable` instances or nullable strings) and coerce them into the
/// strongly-typed payloads consumed by presentation widgets.
class GraphViewNodeEditorEventShims {
  const GraphViewNodeEditorEventShims._();

  static GraphViewDragSelectionEndEventPayload dragSelection({
    required Iterable<String> nodeIds,
    Offset? position,
  }) {
    return GraphViewDragSelectionEndEventPayload(
      nodeIds: Set<String>.unmodifiable(nodeIds),
      position: position,
    );
  }

  static GraphViewLinkSelectionEventPayload linkSelection(
    Iterable<String> linkIds,
  ) {
    return GraphViewLinkSelectionEventPayload(
      linkIds: Set<String>.unmodifiable(linkIds),
    );
  }

  static GraphViewLinkDeselectionEventPayload linkDeselection(
    Iterable<String> linkIds,
  ) {
    return GraphViewLinkDeselectionEventPayload(
      linkIds: Set<String>.unmodifiable(linkIds),
    );
  }

  static GraphViewRemoveLinkEventPayload removeLink(String linkId) {
    return GraphViewRemoveLinkEventPayload(linkId: linkId);
  }
}
