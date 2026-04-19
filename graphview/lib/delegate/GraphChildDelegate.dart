part of graphview;

class GraphChildDelegate {
  final Graph graph;
  final Algorithm algorithm;
  final NodeWidgetBuilder builder;
  GraphViewController? controller;
  final bool centerGraph;
  final NodeDraggingConfiguration? nodeDraggingConfig;
  Graph? _cachedVisibleGraph;
  bool _needsRecalculation = true;

  GraphChildDelegate({
    required this.graph,
    required this.algorithm,
    required this.builder,
    required this.controller,
    this.centerGraph = false,
    this.nodeDraggingConfig,
  });

  Graph getVisibleGraph() {
    if (_cachedVisibleGraph != null && !_needsRecalculation) {
      return _cachedVisibleGraph!;
    }

    final visibleGraph = getVisibleGraphOnly();

    final collapsingEdges = controller?.getCollapsingEdges(graph) ?? [];
    visibleGraph.addEdges(collapsingEdges);

    _cachedVisibleGraph = visibleGraph;
    _needsRecalculation = false;
    return visibleGraph;
  }

  Graph getVisibleGraphOnly() {
    final visibleGraph = Graph();
    for (final edge in graph.edges) {
      if (isNodeVisible(edge.source) && isNodeVisible(edge.destination)) {
        visibleGraph.addEdgeS(edge);
      }
    }

    if (visibleGraph.nodes.isEmpty && graph.nodes.isNotEmpty) {
      visibleGraph.addNode(graph.nodes.first);
    }
    return visibleGraph;
  }

  Widget? build(Node node) {
    var child = node.data ?? builder(node);
    return KeyedSubtree(key: node.key, child: child);
  }

  bool shouldRebuild(GraphChildDelegate oldDelegate) {
    final result = graph != oldDelegate.graph ||
        algorithm != oldDelegate.algorithm ||
        nodeDraggingConfig != oldDelegate.nodeDraggingConfig;
    if (result) _needsRecalculation = true;
    return result;
  }

  Size runAlgorithm() {
    final visibleGraph = getVisibleGraphOnly();

    if (centerGraph) {
      // Use large viewport and center the graph
      var viewPortSize = Size(200000, 200000);
      var centerX = viewPortSize.width / 2;
      var centerY = viewPortSize.height / 2;
      algorithm.run(visibleGraph, centerX, centerY);
      return viewPortSize;
    } else {
      // Use default algorithm behavior
      return algorithm.run(visibleGraph, 0, 0);
    }
  }

  bool isNodeVisible(Node node) {
    return controller?.isNodeVisible(graph, node) ?? true;
  }

  Node? findClosestVisibleAncestor(Node node) {
    return controller?.findClosestVisibleAncestor(graph, node);
  }
}
