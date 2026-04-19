part of graphview;

class GraphViewController {
  _GraphViewState? _state;
  final TransformationController? transformationController;
  final bool _ownsTransformationController;

  final Map<Node, bool> collapsedNodes = {};
  final Map<Node, bool> expandingNodes = {};
  final Map<Node, Node> hiddenBy = {};

  Node? collapsedNode;
  Node? focusedNode;

  GraphViewController({
    TransformationController? transformationController,
  })  : transformationController = transformationController,
        _ownsTransformationController = transformationController == null;

  void _attach(_GraphViewState? state) => _state = state;

  void _detach() => _state = null;

  void dispose() => _detach();

  void animateToNode(ValueKey key) => _state?.jumpToNodeUsingKey(key, true);

  void jumpToNode(ValueKey key) => _state?.jumpToNodeUsingKey(key, false);

  void animateToMatrix(Matrix4 target) => _state?.animateToMatrix(target);

  void resetView() => _state?.resetView();

  void zoomToFit() => _state?.zoomToFit();

  void forceRecalculation() => _state?.forceRecalculation();

  // Visibility management methods
  bool isNodeCollapsed(Node node) => collapsedNodes.containsKey(node);

  bool isNodeHidden(Node node) => hiddenBy.containsKey(node);

  // The graph parameter is retained for compatibility with existing callers.
  bool isNodeVisible(Graph graph, Node node) {
    return !hiddenBy.containsKey(node);
  }

  Node? findClosestVisibleAncestor(Graph graph, Node node) {
    var current = graph.predecessorsOf(node).firstOrNull;

    // Walk up until we find a visible ancestor
    while (current != null) {
      if (isNodeVisible(graph, current)) {
        return current; // Return the first (closest) visible ancestor
      }
      current = graph.predecessorsOf(current).firstOrNull;
    }

    return null;
  }

  void _markDescendantsHiddenBy(
      Graph graph, Node collapsedNode, Node currentNode,
      [Set<Node>? visited]) {
    visited ??= <Node>{};
    if (!visited.add(currentNode)) {
      return;
    }

    for (final child in graph.successorsOf(currentNode)) {
      if (visited.contains(child)) {
        continue;
      }

      // Only mark as hidden if:
      // 1. Not already hidden, OR
      // 2. Was hidden by a node that's no longer collapsed
      if (child != collapsedNode &&
          (!hiddenBy.containsKey(child) ||
              !collapsedNodes.containsKey(hiddenBy[child]))) {
        hiddenBy[child] = collapsedNode;
      }

      // Recurse only if this child isn't itself a collapsed node
      if (!collapsedNodes.containsKey(child)) {
        _markDescendantsHiddenBy(graph, collapsedNode, child, visited);
      }
    }
  }

  void _markExpandingDescendants(Graph graph, Node node, [Set<Node>? visited]) {
    visited ??= <Node>{};
    if (!visited.add(node)) {
      return;
    }

    for (final child in graph.successorsOf(node)) {
      if (visited.contains(child)) {
        continue;
      }

      expandingNodes[child] = true;
      if (!collapsedNodes.containsKey(child)) {
        _markExpandingDescendants(graph, child, visited);
      }
    }
  }

  void expandNode(Graph graph, Node node, {animate = false}) {
    collapsedNodes.remove(node);
    hiddenBy.removeWhere((hiddenNode, hiddenBy) => hiddenBy == node);

    expandingNodes.clear();
    _markExpandingDescendants(graph, node);

    if (animate) {
      focusedNode = node;
    }
    forceRecalculation();
  }

  void collapseNode(Graph graph, Node node, {animate = false}) {
    if (graph.hasSuccessor(node)) {
      collapsedNodes[node] = true;
      collapsedNode = node;
      if (animate) {
        focusedNode = node;
      }
      _markDescendantsHiddenBy(graph, node, node);
      forceRecalculation();
    }
    expandingNodes.clear();
  }

  void toggleNodeExpanded(Graph graph, Node node, {animate = false}) {
    if (isNodeCollapsed(node)) {
      expandNode(graph, node, animate: animate);
    } else {
      collapseNode(graph, node, animate: animate);
    }
  }

  List<Edge> getCollapsingEdges(Graph graph) {
    if (collapsedNode == null) return [];

    return graph.edges.where((edge) {
      return hiddenBy[edge.destination] == collapsedNode;
    }).toList();
  }

  List<Edge> getExpandingEdges(Graph graph) {
    final expandingEdges = <Edge>[];

    for (final node in expandingNodes.keys) {
      // Get all incoming edges to expanding nodes
      for (final edge in graph.getInEdges(node)) {
        expandingEdges.add(edge);
      }
    }

    return expandingEdges;
  }

  // Additional convenience methods for setting initial state
  void setInitiallyCollapsedNodes(Graph graph, List<Node> nodes) {
    for (final node in nodes) {
      collapsedNodes[node] = true;
      // Mark descendants as hidden by this node
      _markDescendantsHiddenBy(graph, node, node);
    }
  }

  void setInitiallyCollapsedByKeys(Graph graph, Set<ValueKey> keys) {
    for (final key in keys) {
      try {
        final node = graph.getNodeUsingKey(key);
        collapsedNodes[node] = true;
        // Mark descendants as hidden by this node
        _markDescendantsHiddenBy(graph, node, node);
      } on StateError {
        // Node with key not found, ignore
      }
    }
  }

  bool isNodeExpanding(Node node) => expandingNodes.containsKey(node);

  void removeCollapsingNodes() {
    collapsedNode = null;
  }

  void jumpToFocusedNode() {
    if (focusedNode != null) {
      final node = focusedNode!;
      final center = Offset(
        node.position.dx + node.width / 2,
        node.position.dy + node.height / 2,
      );
      _state?.jumpToOffset(center, true);
      focusedNode = null;
    }
  }
}
