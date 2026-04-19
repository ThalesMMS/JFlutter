part of graphview;

mixin SugiyamaCycleRemoval on _SugiyamaAlgorithmState {
  void cycleRemoval() {
    switch (configuration.cycleRemovalStrategy) {
      case CycleRemovalStrategy.dfs:
        _dfsRecursiveCycleRemoval();
        break;
      case CycleRemovalStrategy.greedy:
        _greedyCycleRemoval();
        break;
    }
  }

  void _dfsRecursiveCycleRemoval() {
    for (final node in graph.nodes) {
      dfs(node);
    }
  }

  void _greedyCycleRemoval() {
    final greedyRemoval = GreedyCycleRemoval(graph);
    final feedbackArcs = greedyRemoval.getFeedbackArcs();

    for (final edge in feedbackArcs) {
      final source = edge.source;
      final target = edge.destination;
      final storedData = edgeData.remove(edge);
      graph.removeEdge(edge);
      final reversedEdge = graph.addEdge(target, source);
      edgeData[reversedEdge] = storedData ?? SugiyamaEdgeData();
      nodeData[source]!.reversed.add(target);
    }
  }

  @override
  void postStraighten() {
    // Align dummy vertices to create straighter edges
    final dummyNodes = <Node>[];
    for (final layer in layers) {
      dummyNodes.addAll(layer.where((n) => nodeData[n]!.isDummy));
    }

    // Group dummy nodes by their original edge
    final edgeGroups = <List<Node>>[];
    final processed = <Node>{};

    for (final dummy in dummyNodes) {
      if (processed.contains(dummy)) continue;

      final group = <Node>[dummy];
      processed.add(dummy);

      // Find connected dummy nodes (same edge)
      _findConnectedDummies(dummy, group, processed, dummyNodes);

      if (group.length > 1) {
        edgeGroups.add(group);
      }
    }

    // Align each group vertically
    for (final group in edgeGroups) {
      group.sort((a, b) => nodeData[a]!.layer.compareTo(nodeData[b]!.layer));

      // Calculate average x position
      final avgX = group.map((n) => n.x).reduce((a, b) => a + b) / group.length;

      // Set all dummy nodes to average x
      for (final node in group) {
        node.x = avgX;
      }
    }
  }

  void _findConnectedDummies(
      Node current, List<Node> group, Set<Node> processed, List<Node> dummies) {
    final stack = <Node>[current];

    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      final neighbours = <Node>[
        ...successorsOf(node),
        ...predecessorsOf(node),
      ];

      for (final neighbour in neighbours) {
        if (dummies.contains(neighbour) && !processed.contains(neighbour)) {
          group.add(neighbour);
          processed.add(neighbour);
          stack.add(neighbour);
        }
      }
    }
  }
}
