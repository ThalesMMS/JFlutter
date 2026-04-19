part of graphview;

abstract class LayeredAlgorithmBase extends Algorithm {
  Set<Node> stack = {};
  Set<Node> visited = {};
  List<List<Node>> layers = [];
  final type1Conflicts = <int, int>{};
  late Graph graph;
  var nodeCount = 1;

  int get dummyId => 'Dummy ${nodeCount++}'.hashCode;

  // Abstract getter for configuration to be implemented by subclasses
  SugiyamaConfiguration get configuration;

  // Abstract getter for nodeData to be implemented by subclasses
  Map<Node, dynamic> get nodeData;

  // Abstract getter for edgeData to be implemented by subclasses
  Map<Edge, dynamic> get edgeData;

  bool isVertical() {
    return OrientationUtils.isVertical(configuration.orientation);
  }

  bool needReverseOrder() {
    return OrientationUtils.needReverseOrder(configuration.orientation);
  }

  Graph copyGraph(Graph graph) {
    final copy = Graph();
    copy.addNodes(graph.nodes);
    copy.addEdges(graph.edges);
    return copy;
  }

  List<Node> getRootNodes(Graph graph) {
    final predecessors = <Node, bool>{};
    graph.edges.forEach((element) {
      predecessors[element.destination] = true;
    });

    var roots = graph.nodes.where((node) => predecessors[node] == null);
    roots.forEach((node) {
      nodeData[node]?.layer = layers.length;
    });

    return roots.toList();
  }

  void shiftCoordinates(double shiftX, double shiftY) {
    layers.forEach((List<Node?> arrayList) {
      arrayList.forEach((it) {
        it!.position = Offset(it.x + shiftX, it.y + shiftY);
      });
    });
  }

  void dfs(Node node) {
    if (visited.contains(node)) {
      return;
    }
    visited.add(node);
    stack.add(node);
    graph.getOutEdges(node).toList().forEach((edge) {
      final target = edge.destination;
      if (stack.contains(target)) {
        final storedData = edgeData.remove(edge);
        graph.removeEdge(edge);
        final reversedEdge = graph.addEdge(target, node);
        edgeData[reversedEdge] = storedData;
        nodeData[node]!.reversed.add(target);
      } else {
        dfs(target);
      }
    });
    stack.remove(node);
  }

  void assignY() {
    // compute y-coordinates;
    final k = layers.length;

    // assign y-coordinates
    var yPos = 0.0;
    var vertical = isVertical();
    for (var i = 0; i < k; i++) {
      var level = layers[i];
      var maxHeight = 0;
      level.forEach((node) {
        var h = nodeData[node]!.isDummy
            ? 0
            : vertical
                ? node.height
                : node.width;
        if (h > maxHeight) {
          maxHeight = h.toInt();
        }
        node.y = yPos;
      });

      if (i < k - 1) {
        yPos += configuration.levelSeparation + maxHeight;
      }
    }
  }

  // Abstract method to create edge data with bend points
  // Subclasses must implement this to create their specific edge data type
  dynamic createEdgeDataWithBendPoints(List<double> bendPoints);

  // Abstract method to get bend points from edge data
  // Subclasses must implement this to access bend points from their specific edge data type
  List<double> getBendPointsFromEdgeData(dynamic edgeData);

  void denormalize() {
    // Remove dummy nodes and create bend points for articulated edges
    for (var i = 1; i < layers.length - 1; i++) {
      final iterator = layers[i].iterator;

      while (iterator.moveNext()) {
        final current = iterator.current;
        if (nodeData[current]!.isDummy) {
          final predecessor = graph.predecessorsOf(current)[0];
          final successor = graph.successorsOf(current)[0];
          final bendPoints = getBendPointsFromEdgeData(
              edgeData[graph.getEdgeBetween(predecessor, current)!]!);

          if (bendPoints.isEmpty ||
              !bendPoints.contains(current.x + predecessor.width / 2)) {
            bendPoints.add(predecessor.x + predecessor.width / 2);
            bendPoints.add(predecessor.y + predecessor.height / 2);
            bendPoints.add(current.x + predecessor.width / 2);
            bendPoints.add(current.y);
          }

          if (!nodeData[predecessor]!.isDummy) {
            bendPoints.add(current.x + predecessor.width / 2);
          } else {
            bendPoints.add(current.x);
          }
          bendPoints.add(current.y);

          if (nodeData[successor]!.isDummy) {
            bendPoints.add(successor.x + predecessor.width / 2);
          } else {
            bendPoints.add(successor.x + successor.width / 2);
          }
          bendPoints.add(successor.y + successor.height / 2);

          graph.removeEdgeFromPredecessor(predecessor, current);
          graph.removeEdgeFromPredecessor(current, successor);

          final edge = graph.addEdge(predecessor, successor);
          edgeData[edge] = createEdgeDataWithBendPoints(bendPoints);

          graph.removeNode(current);
        }
      }
    }
  }

  void restoreCycle() {
    graph.nodes.forEach((n) {
      final nodeInfo = nodeData[n];
      if (nodeInfo == null || !nodeInfo.isReversed) {
        return;
      }

      for (final target in nodeInfo.reversed.toList()) {
        final existingEdge = graph.getEdgeBetween(target, n);
        if (existingEdge == null) {
          continue;
        }
        final existingData = edgeData.remove(existingEdge);
        final bendPoints = existingData != null
            ? getBendPointsFromEdgeData(existingData)
            : <double>[];
        graph.removeEdgeFromPredecessor(target, n);
        final edge = graph.addEdge(n, target);

        edgeData[edge] = createEdgeDataWithBendPoints(bendPoints);
      }
    });
  }
}
