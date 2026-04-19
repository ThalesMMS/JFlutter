part of graphview;

/// Fruchterman-Reingold force-directed graph layout algorithm.
///
/// Implements a spring-embedder layout where edges act as springs (attraction)
/// and nodes repel each other. Supports optional Barnes-Hut optimization for
/// O(n log n) repulsion calculations on large graphs.
class FruchtermanReingoldAlgorithm implements Algorithm {
  static const double DEFAULT_TICK_FACTOR = 0.1;
  static const double CONVERGENCE_THRESHOLD = 1.0;

  Map<Node, Offset> displacement = {};
  Map<Node, Rect> nodeRects = {};
  Random rand = Random();
  double graphHeight = 500; //default value, change ahead of time
  double graphWidth = 500;
  late double tick;

  FruchtermanReingoldConfiguration configuration;

  @override
  EdgeRenderer? renderer;

  FruchtermanReingoldAlgorithm(this.configuration, {this.renderer}) {
    renderer = renderer ?? ArrowEdgeRenderer(noArrow: true);
  }

  @override
  void init(Graph? graph) {
    // Check if all nodes are at the same position (e.g., all at origin).
    // Force-directed algorithms need distinct initial positions to compute
    // meaningful direction vectors for repulsion forces.
    final allSamePosition = graph!.nodes.length > 1 &&
        graph.nodes.every((n) => n.position == graph.nodes.first.position);

    var index = 0;
    graph.nodes.forEach((node) {
      displacement[node] = Offset.zero;

      if (configuration.shuffleNodes) {
        node.position = Offset(
            rand.nextDouble() * graphWidth, rand.nextDouble() * graphHeight);
      } else if (allSamePosition) {
        // Spread nodes in a small circle around the center so the algorithm
        // can compute non-zero direction vectors for repulsion
        final angle = index * 2 * pi / graph.nodeCount();
        node.position = Offset(
            graphWidth / 2 + cos(angle) * 10.0,
            graphHeight / 2 + sin(angle) * 10.0);
        index++;
      }

      nodeRects[node] = Rect.fromLTWH(node.x, node.y, node.width, node.height);
    });
  }

  void moveNodes(Graph graph) {
    final lerpFactor = configuration.lerpFactor;

    graph.nodes.forEach((node) {
      final nodeDisplacement = displacement[node]!;
      var target = node.position + nodeDisplacement;
      var newPosition = Offset.lerp(node.position, target, lerpFactor)!;
      double newDX = min(graphWidth - node.size.width * 0.5,
          max(node.size.width * 0.5, newPosition.dx));
      double newDY = min(graphHeight - node.size.height * 0.5,
          max(node.size.height * 0.5, newPosition.dy));

      node.position = Offset(newDX, newDY);
      // Update cached rect after position change
      nodeRects[node] = Rect.fromLTWH(node.x, node.y, node.width, node.height);
    });
  }

  void cool(int currentIteration) {
    // tick *= 1.0 - currentIteration / configuration.iterations;
    const alpha = 0.99; // tweakable decay factor (0.8–0.99 typical)
    tick *= alpha;
  }

  void limitMaximumDisplacement(List<Node> nodes) {
    final epsilon = configuration.epsilon;

    nodes.forEach((node) {
      final nodeDisplacement = displacement[node]!;
      var dispLength = max(epsilon, nodeDisplacement.distance);
      node.position += nodeDisplacement / dispLength * min(dispLength, tick);
      // Update cached rect after position change
      nodeRects[node] = Rect.fromLTWH(node.x, node.y, node.width, node.height);
    });
  }

  /// Calculates attraction forces along edges.
  ///
  /// Connected nodes attract each other with a force proportional to their
  /// distance squared divided by the optimal distance k. This implements
  /// the spring force from the Fruchterman-Reingold model.
  ///
  /// Complexity: O(e) where e is the number of edges.
  void calculateAttraction(List<Edge> edges) {
    final attractionRate = configuration.attractionRate;
    final epsilon = configuration.epsilon;

    // Optimal distance (k) based on area and node count
    final k = sqrt((graphWidth * graphHeight) / (edges.length + 1));

    for (var edge in edges) {
      var source = edge.source;
      var destination = edge.destination;
      var delta = source.position - destination.position;
      var deltaDistance = max(epsilon, delta.distance);

      // Standard FR attraction: proportional to distance² / k
      var attractionForce = (deltaDistance * deltaDistance) / k;
      var attractionVector =
          delta / deltaDistance * attractionForce * attractionRate;

      displacement[source] = displacement[source]! - attractionVector;
      displacement[destination] = displacement[destination]! + attractionVector;
    }
  }

  /// Calculates repulsion forces between all pairs of nodes (naive O(n²) approach).
  ///
  /// Each node repels every other node with a force that decreases with distance.
  /// Uses rectangle-based distance calculation to account for node sizes.
  ///
  /// Complexity: O(n²) where n is the number of nodes.
  void calculateRepulsion(List<Node> nodes) {
    final repulsionRate = configuration.repulsionRate;
    final repulsionPercentage = configuration.repulsionPercentage;
    final epsilon = configuration.epsilon;
    final nodeCountDouble = nodes.length.toDouble();
    final maxRepulsionDistance = min(
        graphWidth * repulsionPercentage, graphHeight * repulsionPercentage);

    for (var i = 0; i < nodeCountDouble; i++) {
      final currentNode = nodes[i];

      for (var j = i + 1; j < nodeCountDouble; j++) {
        final otherNode = nodes[j];
        if (currentNode != otherNode) {
          // Calculate distance between node rectangles, not just centers
          var delta = _getNodeRectDistance(currentNode, otherNode);
          var deltaDistance = max(epsilon, delta.distance); //protect for 0
          var repulsionForce = max(0, maxRepulsionDistance - deltaDistance) /
              maxRepulsionDistance; //value between 0-1
          var repulsionVector = delta * repulsionForce * repulsionRate;

          displacement[currentNode] =
              displacement[currentNode]! + repulsionVector;
          displacement[otherNode] = displacement[otherNode]! - repulsionVector;
        }
      }
    }
  }

  /// Calculates repulsion forces using the Barnes-Hut algorithm for optimization.
  ///
  /// Builds a quadtree spatial index and uses it to approximate distant node
  /// clusters as single bodies. This reduces complexity from O(n²) to O(n log n)
  /// while maintaining reasonable accuracy.
  ///
  /// The theta parameter controls the accuracy/speed tradeoff:
  /// - Lower theta (0.3-0.5) = more accurate, slower
  /// - Higher theta (0.7-1.0) = less accurate, faster
  ///
  /// Complexity: O(n log n) where n is the number of nodes.
  void calculateRepulsionBarnesHut(List<Node> nodes) {
    final repulsionRate = configuration.repulsionRate;
    final repulsionPercentage = configuration.repulsionPercentage;
    final epsilon = configuration.epsilon;
    final theta = configuration.theta;
    final maxRepulsionDistance = min(
        graphWidth * repulsionPercentage, graphHeight * repulsionPercentage);

    // Build quadtree with bounds covering the entire graph
    final padding = max(graphWidth, graphHeight) * 0.1;
    final bounds = Rect.fromLTWH(
        -padding, -padding, graphWidth + 2 * padding, graphHeight + 2 * padding);
    final quadtree = BarnesHutQuadtree(bounds);

    // Insert all nodes into the quadtree
    for (final node in nodes) {
      quadtree.insert(node);
    }

    // Calculate repulsion forces for each node using the quadtree
    for (final currentNode in nodes) {
      _calculateForceFromQuadtree(
          currentNode, quadtree, theta, repulsionRate, maxRepulsionDistance, epsilon);
    }
  }

  /// Recursively calculates repulsion force from a quadtree node onto a graph node.
  ///
  /// This is the core of the Barnes-Hut algorithm. It decides whether to:
  /// - Approximate the quadtree node as a single body (if far enough away), or
  /// - Recurse into its children for more accurate calculation
  ///
  /// The decision is based on the Barnes-Hut criterion: (size / distance) < theta.
  /// If the criterion is met, the entire quadtree node is treated as a single
  /// point mass at its center of mass.
  ///
  /// Parameters:
  /// - currentNode: The node to calculate force on
  /// - quadtreeNode: The quadtree node being considered
  /// - theta: Approximation threshold (lower = more accurate)
  /// - repulsionRate: Strength multiplier for repulsion
  /// - maxRepulsionDistance: Maximum distance for repulsion effects
  /// - epsilon: Minimum distance to prevent division by zero
  void _calculateForceFromQuadtree(Node currentNode, BarnesHutQuadtree quadtreeNode,
      double theta, double repulsionRate, double maxRepulsionDistance, double epsilon) {
    // Skip empty quadtree nodes
    if (quadtreeNode.isEmpty) {
      return;
    }

    // If this is a leaf node containing the current node itself, skip it
    if (quadtreeNode.isLeaf && quadtreeNode.node == currentNode) {
      return;
    }

    // Calculate distance from current node to quadtree node's center of mass
    final delta = currentNode.position - quadtreeNode.centerOfMass;
    final deltaDistance = max(epsilon, delta.distance);

    // Barnes-Hut criterion: if (size / distance) < theta, approximate
    final size = max(quadtreeNode.bounds.width, quadtreeNode.bounds.height);
    if (quadtreeNode.isLeaf || (size / deltaDistance) < theta) {
      // Treat this quadtree node as a single body
      var repulsionForce = max(0, maxRepulsionDistance - deltaDistance) /
          maxRepulsionDistance; //value between 0-1
      var repulsionVector = delta * repulsionForce * repulsionRate * quadtreeNode.totalMass;

      displacement[currentNode] = displacement[currentNode]! + repulsionVector;
    } else {
      // Recurse into children
      _calculateForceFromQuadtree(
          currentNode, quadtreeNode.northWest!, theta, repulsionRate, maxRepulsionDistance, epsilon);
      _calculateForceFromQuadtree(
          currentNode, quadtreeNode.northEast!, theta, repulsionRate, maxRepulsionDistance, epsilon);
      _calculateForceFromQuadtree(
          currentNode, quadtreeNode.southWest!, theta, repulsionRate, maxRepulsionDistance, epsilon);
      _calculateForceFromQuadtree(
          currentNode, quadtreeNode.southEast!, theta, repulsionRate, maxRepulsionDistance, epsilon);
    }
  }

  /// Calculates the closest distance vector between two node rectangles.
  ///
  /// Uses cached rectangle bounds for performance. Handles overlapping nodes
  /// by pushing them apart. Returns a vector pointing from nodeB to nodeA.
  Offset _getNodeRectDistance(Node nodeA, Node nodeB) {
    final rectA = nodeRects[nodeA]!;
    final rectB = nodeRects[nodeB]!;

    final centerA = rectA.center;
    final centerB = rectB.center;

    if (rectA.overlaps(rectB)) {
      // Push overlapping nodes apart by at least half their combined size
      final dxDiff = centerA.dx - centerB.dx;
      final dyDiff = centerA.dy - centerB.dy;
      // When centers are identical, .sign returns 0 which kills repulsion.
      // Use 1.0 as default direction to break symmetry.
      final dx =
          (dxDiff == 0 ? 1.0 : dxDiff.sign) * (rectA.width / 2 + rectB.width / 2);
      final dy = (dyDiff == 0 ? 1.0 : dyDiff.sign) *
          (rectA.height / 2 + rectB.height / 2);
      return Offset(dx, dy);
    }

    // Non-overlapping: distance along nearest edges
    final dx = (centerA.dx < rectB.left)
        ? (rectB.left - rectA.right)
        : (centerA.dx > rectB.right)
            ? (rectA.left - rectB.right)
            : 0.0;

    final dy = (centerA.dy < rectB.top)
        ? (rectB.top - rectA.bottom)
        : (centerA.dy > rectB.bottom)
            ? (rectA.top - rectB.bottom)
            : 0.0;

    return Offset(dx == 0 ? centerA.dx - centerB.dx : dx,
        dy == 0 ? centerA.dy - centerB.dy : dy);
  }

  bool step(Graph graph) {
    var moved = false;
    displacement.clear();
    for (var node in graph.nodes) {
      displacement[node] = Offset.zero;
    }

    if (configuration.useBarnesHut) {
      calculateRepulsionBarnesHut(graph.nodes);
    } else {
      calculateRepulsion(graph.nodes);
    }
    calculateAttraction(graph.edges);

    for (var node in graph.nodes) {
      final nodeDisplacement = displacement[node]!;
      if (nodeDisplacement.distance > configuration.movementThreshold) {
        moved = true;
      }
    }

    moveNodes(graph);
    graph.markModified();
    return moved;
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodes.isEmpty) {
      return Size.zero;
    }

    if (graph.nodes.length == 1) {
      final node = graph.nodes.first;
      node.position = Offset(shiftX, shiftY);
      return Size(node.width, node.height);
    }

    var size = findBiggestSize(graph) * graph.nodeCount();
    graphWidth = size;
    graphHeight = size;

    var nodes = graph.nodes;
    var edges = graph.edges;

    tick = DEFAULT_TICK_FACTOR * sqrt(graphWidth / 2 * graphHeight / 2);

    // Always initialize displacement and rect caches for all nodes
    for (var node in graph.nodes) {
      displacement[node] = Offset.zero;
      nodeRects[node] = Rect.fromLTWH(node.x, node.y, node.width, node.height);
    }

    if (graph.nodes.any((node) => node.position == Offset.zero)) {
      init(graph);
    }

    for (var i = 0; i < configuration.iterations; i++) {
      if (configuration.useBarnesHut) {
        calculateRepulsionBarnesHut(nodes);
      } else {
        calculateRepulsion(nodes);
      }
      calculateAttraction(edges);
      limitMaximumDisplacement(nodes);

      cool(i);

      if (done()) {
        break;
      }
    }

    positionNodes(graph);

    shiftCoordinates(graph, shiftX, shiftY);

    return graph.calculateGraphSize();
  }

  void shiftCoordinates(Graph graph, double shiftX, double shiftY) {
    graph.nodes.forEach((node) {
      node.position = Offset(node.x + shiftX, node.y + shiftY);
      // Update cached rect after position change
      nodeRects[node] = Rect.fromLTWH(node.x, node.y, node.width, node.height);
    });
  }

  void positionNodes(Graph graph) {
    var offset = getOffset(graph);
    var x = offset.dx;
    var y = offset.dy;
    var nodesVisited = <Node>[];
    var nodeClusters = <NodeCluster>[];
    graph.nodes.forEach((node) {
      node.position = Offset(node.x - x, node.y - y);
      // Update cached rect after position change
      nodeRects[node] = Rect.fromLTWH(node.x, node.y, node.width, node.height);
    });

    graph.nodes.forEach((node) {
      if (!nodesVisited.contains(node)) {
        nodesVisited.add(node);
        var cluster = findClusterOf(nodeClusters, node);
        if (cluster == null) {
          cluster = NodeCluster();
          cluster.add(node);
          nodeClusters.add(cluster);
        }

        followEdges(graph, cluster, node, nodesVisited);
      }
    });

    positionCluster(nodeClusters);
  }

  void positionCluster(List<NodeCluster> nodeClusters) {
    combineSingleNodeCluster(nodeClusters);

    var cluster = nodeClusters[0];
    // move first cluster to 0,0
    cluster.offset(-cluster.rect!.left, -cluster.rect!.top);

    for (var i = 1; i < nodeClusters.length; i++) {
      var nextCluster = nodeClusters[i];
      var xDiff = nextCluster.rect!.left -
          cluster.rect!.right -
          configuration.clusterPadding;
      var yDiff = nextCluster.rect!.top - cluster.rect!.top;
      nextCluster.offset(-xDiff, -yDiff);
      cluster = nextCluster;
    }
  }

  void combineSingleNodeCluster(List<NodeCluster> nodeClusters) {
    NodeCluster? firstSingleNodeCluster;

    nodeClusters.forEach((cluster) {
      if (cluster.size() == 1) {
        if (firstSingleNodeCluster == null) {
          firstSingleNodeCluster = cluster;
        } else {
          firstSingleNodeCluster!.concat(cluster);
        }
      }
    });

    nodeClusters.removeWhere((element) =>
        element.size() == 1 && element != firstSingleNodeCluster);
  }

  void followEdges(
      Graph graph, NodeCluster cluster, Node node, List nodesVisited) {
    graph.successorsOf(node).forEach((successor) {
      if (!nodesVisited.contains(successor)) {
        nodesVisited.add(successor);
        cluster.add(successor);

        followEdges(graph, cluster, successor, nodesVisited);
      }
    });

    graph.predecessorsOf(node).forEach((predecessor) {
      if (!nodesVisited.contains(predecessor)) {
        nodesVisited.add(predecessor);
        cluster.add(predecessor);

        followEdges(graph, cluster, predecessor, nodesVisited);
      }
    });
  }

  NodeCluster? findClusterOf(List<NodeCluster> clusters, Node node) {
    return clusters.firstWhereOrNull((element) => element.contains(node));
  }

  double findBiggestSize(Graph graph) {
    return graph.nodes.map((it) => max(it.height, it.width)).reduce(max);
  }

  Offset getOffset(Graph graph) {
    var offsetX = double.infinity;
    var offsetY = double.infinity;

    graph.nodes.forEach((node) {
      offsetX = min(offsetX, node.x);
      offsetY = min(offsetY, node.y);
    });

    return Offset(offsetX, offsetY);
  }

  bool done() {
    return tick < CONVERGENCE_THRESHOLD / max(graphHeight, graphWidth);
  }

  void drawEdges(Canvas canvas, Graph graph, Paint linePaint) {}

  @override
  void setDimensions(double width, double height) {
    graphWidth = width;
    graphHeight = height;
  }
}

class NodeCluster {
  List<Node> nodes;
  Rect? rect;

  List<Node> getNodes() {
    return nodes;
  }

  Rect? getRect() {
    return rect;
  }

  void setRect(Rect newRect) {
    rect = newRect;
  }

  void add(Node node) {
    nodes.add(node);

    if (nodes.length == 1) {
      rect = Rect.fromLTRB(
          node.x, node.y, node.x + node.width, node.y + node.height);
    } else {
      rect = Rect.fromLTRB(
          min(rect!.left, node.x),
          min(rect!.top, node.y),
          max(rect!.right, node.x + node.width),
          max(rect!.bottom, node.y + node.height));
    }
  }

  bool contains(Node node) {
    return nodes.contains(node);
  }

  int size() {
    return nodes.length;
  }

  void concat(NodeCluster cluster) {
    cluster.nodes.forEach((node) {
      node.position = (Offset(
          rect!.right +
              FruchtermanReingoldConfiguration.DEFAULT_CLUSTER_PADDING,
          rect!.top));
      add(node);
    });
  }

  void offset(double xDiff, double yDiff) {
    nodes.forEach((node) {
      node.position = (node.position + Offset(xDiff, yDiff));
    });

    rect = rect!.translate(xDiff, yDiff);
  }

  NodeCluster()
      : nodes = <Node>[],
        rect = Rect.zero;
}
