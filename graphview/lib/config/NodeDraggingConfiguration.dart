part of graphview;

/// Configuration for individual node dragging functionality.
///
/// This class controls the behavior of node dragging within the graph,
/// including callbacks for drag events and node locking capabilities.
class NodeDraggingConfiguration {
  /// Default enabled state for node dragging.
  static const bool DEFAULT_ENABLED = true;

  /// Whether node dragging is enabled.
  ///
  /// When true, nodes can be dragged via long press or tap-and-hold gestures.
  /// When false, nodes remain fixed and only pan/zoom gestures work.
  bool enabled;

  /// Callback invoked when a node drag gesture begins.
  ///
  /// Called when the user initiates a drag gesture on a node.
  /// Receives the [Node] that is being dragged.
  void Function(Node node)? onNodeDragStart;

  /// Callback invoked during node dragging.
  ///
  /// Called repeatedly as the node is dragged to a new position.
  /// Receives the [Node] being dragged and the current [Offset] position.
  void Function(Node node, Offset position)? onNodeDragUpdate;

  /// Callback invoked when a node drag gesture ends.
  ///
  /// Called when the user releases the node after dragging.
  /// Receives the [Node] that was dragged and the final [Offset] position.
  void Function(Node node, Offset finalPosition)? onNodeDragEnd;

  /// Predicate function to determine if a node can be dragged.
  ///
  /// When provided, this function is called to check if a node is draggable.
  /// Return true to allow dragging, false to prevent it.
  /// If null, all nodes can be dragged (when [enabled] is true).
  bool Function(Node node)? canDragPredicate;

  NodeDraggingConfiguration({
    this.enabled = DEFAULT_ENABLED,
    this.onNodeDragStart,
    this.onNodeDragUpdate,
    this.onNodeDragEnd,
    this.canDragPredicate,
  });
}
