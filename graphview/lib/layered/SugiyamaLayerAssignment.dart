part of graphview;

mixin SugiyamaLayerAssignment on _SugiyamaAlgorithmState {
  void layerAssignment() {
    switch (configuration.layeringStrategy) {
      case LayeringStrategy.topDown:
        layerAssignmentTopDown();
        break;
      case LayeringStrategy.longestPath:
        layerAssignmentLongestPath();
        break;
      case LayeringStrategy.coffmanGraham:
        layerAssignmentCoffmanGraham();
        break;
      case LayeringStrategy.networkSimplex:
        layerAssignmentNetworkSimplex();
        break;
    }

    // Add dummy nodes for long edges
    addDummyNodes();
  }

  void layerAssignmentTopDown() {
    if (graph.nodes.isEmpty) return;

    layers.clear();
    final copiedGraph = copyGraph(graph);
    var roots = getRootNodes(copiedGraph);

    while (roots.isNotEmpty) {
      layers.add(roots);
      copiedGraph.removeNodes(roots);
      roots = getRootNodes(copiedGraph);
    }

    // Set layer metadata
    for (var i = 0; i < layers.length; i++) {
      for (var j = 0; j < layers[i].length; j++) {
        nodeData[layers[i][j]]!.layer = i;
        nodeData[layers[i][j]]!.position = j;
      }
    }
  }

  void layerAssignmentLongestPath() {
    if (graph.nodes.isEmpty) return;

    var U = <Node>{};
    var Z = <Node>{};
    var V = Set<Node>.from(graph.nodes);
    var currentLayer = 0;
    layers = [[]];

    while (U.length != graph.nodes.length) {
      var candidates = V
          .where((v) => !U.contains(v) && Z.containsAll(graph.successorsOf(v)));

      if (candidates.isNotEmpty) {
        var node = candidates.first;
        layers[currentLayer].add(node);
        U.add(node);
      } else {
        currentLayer++;
        layers.add([]);
        Z.addAll(U);
      }
    }

    // Reverse layers and set metadata
    layers = layers.reversed.where((layer) => layer.isNotEmpty).toList();
    for (var i = 0; i < layers.length; i++) {
      for (var j = 0; j < layers[i].length; j++) {
        nodeData[layers[i][j]]!.layer = i;
        nodeData[layers[i][j]]!.position = j;
      }
    }
  }

  void layerAssignmentCoffmanGraham() {
    if (graph.nodes.isEmpty) return;

    var width = (graph.nodes.length / 10).ceil();

    var Z = <Node>{};
    var lambda = <Node, int>{};
    var V = Set<Node>.from(graph.nodes);

    // Assign lambda values based on in-degree
    for (final v in V) {
      lambda[v] = double.maxFinite.toInt();
    }
    for (var i = 0; i < V.length; i++) {
      var mv = V.where((v) => lambda[v] == double.maxFinite.toInt()).reduce(
          (a, b) =>
              graph.getInEdges(a).length <= graph.getInEdges(b).length ? a : b);
      lambda[mv] = i;
    }

    var k = 0;
    layers = [[]];
    var U = <Node>{};

    while (U.length != graph.nodes.length) {
      var candidates = V
          .where((v) => !U.contains(v) && U.containsAll(graph.successorsOf(v)));

      if (candidates.isNotEmpty) {
        var got = candidates.reduce((a, b) => lambda[a]! > lambda[b]! ? a : b);

        if (layers[k].length < width &&
            Z.containsAll(graph.successorsOf(got))) {
          layers[k].add(got);
        } else {
          Z.addAll(layers[k]);
          k++;
          layers.add([]);
          layers[k].add(got);
        }
        U.add(got);
      }
    }

    // Remove empty layers and reverse
    layers = layers.where((l) => l.isNotEmpty).toList().reversed.toList();

    // Set metadata
    for (var i = 0; i < layers.length; i++) {
      for (var j = 0; j < layers[i].length; j++) {
        nodeData[layers[i][j]]!.layer = i;
        nodeData[layers[i][j]]!.position = j;
      }
    }
  }

  /// Heuristic iterative improvement, not a full network simplex.
  ///
  /// Starts from [layerAssignmentLongestPath], then moves nodes toward their
  /// successors using [nodeData] and [layers] to reduce edge span.
  void layerAssignmentNetworkSimplex() {
    layerAssignmentLongestPath();

    // Simple optimization: try to minimize edge span
    var improved = true;
    var iterations = 5;

    while (improved && iterations > 0) {
      improved = false;
      iterations--;

      for (var i = layers.length - 1; i >= 0; i--) {
        var layer = List<Node>.from(layers[i]);
        var nodesToMove = <Node, int>{};

        for (final v in layer) {
          if (graph.getOutEdges(v).isEmpty) continue;

          final outgoingEdges = graph.getOutEdges(v);
          if (outgoingEdges.isNotEmpty) {
            final minRank = outgoingEdges
                .map((e) => nodeData[e.destination]!.layer - 1)
                .reduce(min);

            if (minRank != nodeData[v]!.layer && minRank >= 0) {
              nodesToMove[v] = minRank;
              improved = true;
            }
          }
        }

        // Move nodes
        for (final entry in nodesToMove.entries) {
          final node = entry.key;
          final newRank = entry.value;
          final oldRank = nodeData[node]!.layer;

          layers[oldRank].remove(node);
          while (newRank >= layers.length) {
            layers.add([]);
          }
          layers[newRank].add(node);
          nodeData[node]!.layer = newRank;
        }
      }

      // Remove empty ranks introduced by moves and keep layer indexes dense.
      layers = layers.where((layer) => layer.isNotEmpty).toList();

      // Recompute layer indexes and positions
      for (var i = 0; i < layers.length; i++) {
        for (var j = 0; j < layers[i].length; j++) {
          final node = layers[i][j];
          nodeData[node]!.layer = i;
          nodeData[node]!.position = j;
        }
      }
    }
  }

  void addDummyNodes() {
    for (var i = 0; i < layers.length - 1; i++) {
      final indexNextLayer = i + 1;
      final currentLayer = layers[i];
      final nextLayer = layers[indexNextLayer];

      // Calculate average layer height for dummy nodes
      final vertical = isVertical();
      final realNodes = nextLayer.where((n) => !nodeData[n]!.isDummy);
      var avgHeight = 0.0;
      if (realNodes.isNotEmpty) {
        var totalHeight = 0.0;
        for (final n in realNodes) {
          totalHeight += vertical ? n.height : n.width;
        }
        avgHeight = totalHeight / realNodes.length;
      }

      for (final node in currentLayer) {
        final edges = graph.edges
            .where((element) =>
                element.source == node &&
                (nodeData[element.destination]!.layer - nodeData[node]!.layer)
                        .abs() >
                    1)
            .toList();

        for (final edge in edges) {
          final dummy = Node.Id(dummyId);
          final dummyNodeData = SugiyamaNodeData(node.lineType);
          dummyNodeData.isDummy = true;
          dummyNodeData.layer = indexNextLayer;
          nextLayer.add(dummy);
          dummyNodeData.position = nextLayer.length - 1;
          nodeData[dummy] = dummyNodeData;
          dummy.size = vertical
              ? Size(edge.source.width, avgHeight)
              : Size(avgHeight, edge.source.height);
          final dummyEdge1 = graph.addEdge(edge.source, dummy);
          final dummyEdge2 = graph.addEdge(dummy, edge.destination);
          edgeData[dummyEdge1] = SugiyamaEdgeData();
          edgeData[dummyEdge2] = SugiyamaEdgeData();
          graph.removeEdge(edge);
        }
      }
    }
  }
}
