part of graphview;

mixin EiglspergerGraphNormalization on _EiglspergerAlgorithmState {
  void shiftCoordinates(double shiftX, double shiftY) {
    for (final layer in layers) {
      for (final node in layer) {
        final position = node.position;
        node.position = Offset(position.dx + shiftX, position.dy + shiftY);
      }
    }
  }

  void initNodeData() {
    for (final node in graph.nodes) {
      node.position = Offset.zero;
      nodeData[node] = EiglspergerNodeData(node.lineType);
    }

    for (final edge in graph.edges) {
      _edgeData[edge] = EiglspergerEdgeData();
    }

    for (final edge in graph.edges) {
      nodeData[edge.source]?.successorNodes.add(edge.destination);
      nodeData[edge.destination]?.predecessorNodes.add(edge.source);
    }
  }

  void cycleRemoval() {
    for (final node in graph.nodes) {
      dfs(node);
    }
  }

  void dfs(Node node) {
    if (visited.contains(node)) {
      return;
    }
    visited.add(node);
    stack.add(node);
    for (final edge in graph.getOutEdges(node).toList()) {
      final target = edge.destination;
      if (stack.contains(target)) {
        graph.removeEdge(edge);
        graph.addEdge(target, node);
        nodeData[node]!.reversed.add(target);
      } else {
        dfs(target);
      }
    }
    stack.remove(node);
  }

  void layerAssignment() {
    if (graph.nodes.isEmpty) {
      return;
    }

    // Build layers using topological sort
    final copiedGraph = copyGraph(graph);
    var roots = getRootNodes(copiedGraph);

    while (roots.isNotEmpty) {
      layers.add(roots);
      copiedGraph.removeNodes(roots);
      roots = getRootNodes(copiedGraph);
    }

    // Create segments for long edges
    createSegmentsForLongEdges();
  }

  void createSegmentsForLongEdges() {
    // Create segments for edges spanning more than one layer
    for (var i = 0; i < layers.length - 1; i++) {
      final currentLayer = layers[i];

      for (final node in List.from(currentLayer)) {
        final edges = graph
            .getOutEdges(node)
            .where((e) =>
                (nodeData[e.destination]!.layer - nodeData[node]!.layer).abs() >
                1)
            .toList();

        for (final edge in edges) {
          if (nodeData[edge.destination]!.layer - nodeData[node]!.layer == 2) {
            // Simple case: only one layer between source and target
            createSingleDummyVertex(edge, i + 1);
          } else {
            // Complex case: multiple layers between source and target
            createSegment(edge);
          }
          graph.removeEdge(edge);
        }
      }
    }
  }

  void createSingleDummyVertex(Edge edge, int dummyLayer) {
    final dummy = Node.Id(dummyId);

    final dummyData = EiglspergerNodeData(edge.source.lineType);
    dummyData.isDummy = true;
    dummyData.layer = dummyLayer;
    nodeData[dummy] = dummyData;

    dummy.size = Size(edge.source.width, 0);

    layers[dummyLayer].add(dummy);
    graph.addNode(dummy);

    final edge1 = graph.addEdge(edge.source, dummy);
    final edge2 = graph.addEdge(dummy, edge.destination);

    _edgeData[edge1] = EiglspergerEdgeData();
    _edgeData[edge2] = EiglspergerEdgeData();
  }

  void createSegment(Edge edge) {
    final sourceLayer = nodeData[edge.source]!.layer;
    final targetLayer = nodeData[edge.destination]!.layer;

    // Create P-vertex (top of segment)
    final pVertex = Node.Id(dummyId);
    final pData = EiglspergerNodeData(edge.source.lineType);
    pData.isDummy = true;
    pData.isPVertex = true;
    pData.layer = sourceLayer + 1;
    nodeData[pVertex] = pData;
    pVertex.size = Size(edge.source.width, 0);

    // Create Q-vertex (bottom of segment)
    final qVertex = Node.Id(dummyId);
    final qData = EiglspergerNodeData(edge.source.lineType);
    qData.isDummy = true;
    qData.isQVertex = true;
    qData.layer = targetLayer - 1;
    nodeData[qVertex] = qData;
    qVertex.size = Size(edge.source.width, 0);

    // Create segment and link vertices
    final segment = Segment(pVertex, qVertex);
    pData.segment = segment;
    qData.segment = segment;
    segments.add(segment);

    // Add to layers and graph
    layers[sourceLayer + 1].add(pVertex);
    layers[targetLayer - 1].add(qVertex);
    graph.addNode(pVertex);
    graph.addNode(qVertex);

    // Create edges
    final edgeToP = graph.addEdge(edge.source, pVertex);
    final segmentEdge = graph.addEdge(pVertex, qVertex);
    final edgeFromQ = graph.addEdge(qVertex, edge.destination);

    _edgeData[edgeToP] = EiglspergerEdgeData();
    _edgeData[segmentEdge] = EiglspergerEdgeData();
    _edgeData[edgeFromQ] = EiglspergerEdgeData();
  }

  List<Node> getRootNodes(Graph graph) {
    final predecessors = <Node, bool>{};
    for (final element in graph.edges) {
      predecessors[element.destination] = true;
    }

    final roots = graph.nodes.where((node) => predecessors[node] == null);
    for (final node in roots) {
      nodeData[node]?.layer = layers.length;
    }

    return roots.toList();
  }

  Graph copyGraph(Graph graph) {
    final copy = Graph();
    copy.addNodes(graph.nodes);
    copy.addEdges(graph.edges);
    return copy;
  }

  void denormalize() {
    // Remove dummy vertices and create bend points for articulated edges
    for (var i = 1; i < layers.length - 1; i++) {
      final iterator = layers[i].iterator;

      while (iterator.moveNext()) {
        final current = iterator.current;
        final currentData = nodeData[current];
        if (currentData == null || !currentData.isDummy) {
          continue;
        }

        final predecessors = graph.predecessorsOf(current);
        final successors = graph.successorsOf(current);
        if (predecessors.isEmpty || successors.isEmpty) {
          continue;
        }

        final predecessor = predecessors.first;
        final successor = successors.first;
        final incomingEdge = graph.getEdgeBetween(predecessor, current);
        final incomingEdgeData =
            incomingEdge == null ? null : _edgeData[incomingEdge];
        if (incomingEdgeData == null) {
          continue;
        }

        final bendPoints = incomingEdgeData.bendPoints;

        if (bendPoints.isEmpty ||
            !bendPoints.contains(current.x + predecessor.width / 2)) {
          bendPoints.add(predecessor.x + predecessor.width / 2);
          bendPoints.add(predecessor.y + predecessor.height / 2);
          bendPoints.add(current.x + predecessor.width / 2);
          bendPoints.add(current.y);
        }

        if (!(nodeData[predecessor]?.isDummy ?? false)) {
          bendPoints.add(current.x + predecessor.width / 2);
        } else {
          bendPoints.add(current.x);
        }
        bendPoints.add(current.y);

        if (nodeData[successor]?.isDummy ?? false) {
          bendPoints.add(successor.x + predecessor.width / 2);
        } else {
          bendPoints.add(successor.x + successor.width / 2);
        }
        bendPoints.add(successor.y + successor.height / 2);

        graph.removeEdgeFromPredecessor(predecessor, current);
        graph.removeEdgeFromPredecessor(current, successor);

        final edge = graph.addEdge(predecessor, successor);
        final edgeData = EiglspergerEdgeData();
        edgeData.bendPoints = bendPoints;
        _edgeData[edge] = edgeData;

        graph.removeNode(current);
      }
    }
  }

  void restoreCycle() {
    for (final n in graph.nodes) {
      if (nodeData[n]!.isReversed) {
        for (final target in nodeData[n]!.reversed.toList()) {
          final existingEdge = graph.getEdgeBetween(target, n);
          final bendPoints =
              existingEdge != null && _edgeData[existingEdge] != null
                  ? _edgeData[existingEdge]!.bendPoints
                  : <double>[];
          graph.removeEdgeFromPredecessor(target, n);
          final edge = graph.addEdge(n, target);

          final edgeData = EiglspergerEdgeData();
          edgeData.bendPoints = bendPoints;
          _edgeData[edge] = edgeData;
        }
      }
    }
  }
}
