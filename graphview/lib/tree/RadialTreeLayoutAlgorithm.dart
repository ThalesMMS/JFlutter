part of graphview;

class TreeLayoutNodeData {
  Rectangle? bounds;
  int depth = 0;
  bool visited = false;
  List<Node> successorNodes = [];

  /// Radial tree layout assumes one parent per node; extra incoming edges are ignored.
  Node? parent;

  TreeLayoutNodeData();
}

class RadialTreeLayoutAlgorithm extends Algorithm {
  late BuchheimWalkerConfiguration config;
  final Map<Node, TreeLayoutNodeData> nodeData = {};
  final Map<Node, Size> baseBounds = {};
  final Map<Node, PolarPoint> polarLocations = {};

  RadialTreeLayoutAlgorithm(this.config, EdgeRenderer? renderer) {
    this.renderer = renderer ?? ArrowEdgeRenderer();
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodes.isEmpty) {
      return Size.zero;
    }

    nodeData.clear();
    baseBounds.clear();
    polarLocations.clear();

    // Handle single node case
    if (graph.nodes.length == 1) {
      final node = graph.nodes.first;
      node.position = Offset(shiftX + 100, shiftY + 100);
      return Size(200, 200);
    }

    _initializeData(graph);
    final roots = _findRoots(graph);

    if (roots.isEmpty) {
      final spanningForest = _createSpanningForest(graph);
      return _layoutSpanningTree(spanningForest, shiftX, shiftY);
    }

    // First, build the tree using regular tree layout
    _buildRegularTree(graph, roots);

    // Then convert to radial coordinates
    _setRadialLocations(graph, roots);

    // Convert polar to cartesian and position nodes
    _putRadialPointsInModel(graph);

    _shiftCoordinates(graph, shiftX, shiftY);

    return graph.calculateGraphSize();
  }

  void _initializeData(Graph graph) {
    // Initialize node data
    for (final node in graph.nodes) {
      nodeData[node] = TreeLayoutNodeData();
    }

    // Build tree structure from edges
    for (final edge in graph.edges) {
      final source = edge.source;
      final target = edge.destination;
      final targetData = nodeData[target]!;

      if (targetData.parent != null && targetData.parent != source) {
        debugPrint(
            'RadialTreeLayoutAlgorithm ignored extra parent for ${target.key?.value}: '
            'existing=${targetData.parent?.key?.value}, extra=${source.key?.value}');
        continue;
      }
      nodeData[source]!.successorNodes.add(target);
      targetData.parent = source;
    }
  }

  List<Node> _findRoots(Graph graph) {
    return graph.nodes.where((node) {
      return nodeData[node]!.parent == null;
    }).toList();
  }

  void _buildRegularTree(Graph graph, List<Node> roots) {
    _calculateSubtreeDimensions(roots);
    _positionNodes(roots);
  }

  void _calculateSubtreeDimensions(List<Node> roots) {
    final visited = <Node>{};

    for (final root in roots) {
      _calculateWidth(root, visited);
    }

    visited.clear();
    for (final root in roots) {
      _calculateHeight(root, visited);
    }
  }

  int _calculateWidth(Node node, Set<Node> visited) {
    if (!visited.add(node)) return 0;

    final children = successorsOf(node);
    if (children.isEmpty) {
      final width = max(node.width.toInt(), config.siblingSeparation);
      baseBounds[node] = Size(width.toDouble(), 0);
      return width;
    }

    var totalWidth = 0;
    for (var i = 0; i < children.length; i++) {
      totalWidth += _calculateWidth(children[i], visited);
      if (i < children.length - 1) {
        totalWidth += config.siblingSeparation;
      }
    }

    baseBounds[node] = Size(totalWidth.toDouble(), 0);
    return totalWidth;
  }

  int _calculateHeight(Node node, Set<Node> visited) {
    if (!visited.add(node)) return 0;

    final children = successorsOf(node);
    if (children.isEmpty) {
      final height = max(node.height.toInt(), config.levelSeparation);
      final current = baseBounds[node]!;
      baseBounds[node] = Size(current.width, height.toDouble());
      return height;
    }

    var maxChildHeight = 0;
    for (final child in children) {
      maxChildHeight = max(maxChildHeight, _calculateHeight(child, visited));
    }

    final totalHeight = maxChildHeight + config.levelSeparation;
    final current = baseBounds[node]!;
    baseBounds[node] = Size(current.width, totalHeight.toDouble());
    return totalHeight;
  }

  void _positionNodes(List<Node> roots) {
    var currentX = config.siblingSeparation.toDouble();

    for (final root in roots) {
      final rootWidth = baseBounds[root]!.width;
      currentX += rootWidth / 2;

      _buildTree(root, currentX, config.levelSeparation.toDouble(), <Node>{});

      currentX += rootWidth / 2 + config.siblingSeparation;
    }
  }

  void _buildTree(Node node, double x, double y, Set<Node> visited) {
    if (!visited.add(node)) return;

    node.position = Offset(x, y);

    final children = successorsOf(node);
    if (children.isEmpty) return;

    final nextY = y + config.levelSeparation;
    final totalWidth = baseBounds[node]!.width;
    var childX = x - totalWidth / 2;

    for (final child in children) {
      final childWidth = baseBounds[child]!.width;
      childX += childWidth / 2;

      _buildTree(child, childX, nextY, visited);

      childX += childWidth / 2 + config.siblingSeparation;
    }
  }

  void _setRadialLocations(Graph graph, List<Node> roots) {
    final bounds = graph.calculateGraphBounds();
    final maxPoint = max(bounds.width, VectorUtils.epsilon);

    // Calculate theta step based on maximum x coordinate
    final theta = 2 * pi / maxPoint;
    final deltaRadius = 1.0;
    final offset = roots.length > 1 ? config.levelSeparation.toDouble() : 0.0;

    for (final node in graph.nodes) {
      final position = node.position;

      // Convert cartesian tree coordinates to polar coordinates
      final polarTheta = position.dx * theta;
      final polarRadius =
          (offset + position.dy - config.levelSeparation) * deltaRadius;

      final polarPoint = PolarPoint.of(polarTheta, polarRadius);
      polarLocations[node] = polarPoint;
    }
  }

  void _putRadialPointsInModel(Graph graph) {
    final diameter = _calculateDiameter();
    final center = diameter * 0.5;

    polarLocations.forEach((node, polarPoint) {
      final cartesian = polarPoint.toCartesian();
      node.position = Offset(center + cartesian.dx, center + cartesian.dy);
    });
  }

  double _calculateDiameter() {
    if (polarLocations.isEmpty) return 400.0;

    double maxRadius = 0;
    polarLocations.values.forEach((polarPoint) {
      maxRadius = max(maxRadius, polarPoint.radius * 2);
    });

    return maxRadius + config.siblingSeparation;
  }

  void _shiftCoordinates(Graph graph, double shiftX, double shiftY) {
    for (final node in graph.nodes) {
      node.position = Offset(node.x + shiftX, node.y + shiftY);
    }
  }

  Graph _createSpanningForest(Graph graph) {
    final forest = Graph();
    final visited = <Node>{};

    for (final node in graph.nodes) {
      forest.addNode(node);
    }

    for (final startNode in graph.nodes) {
      if (visited.contains(startNode)) continue;

      final queue = Queue<Node>()..add(startNode);
      visited.add(startNode);

      while (queue.isNotEmpty) {
        final current = queue.removeFirst();

        for (final edge in graph.edges) {
          Node? neighbor;
          Edge? spanningEdge;
          if (edge.source == current && !visited.contains(edge.destination)) {
            neighbor = edge.destination;
            spanningEdge = edge;
          } else if (edge.destination == current &&
              !visited.contains(edge.source)) {
            neighbor = edge.source;
            spanningEdge = _copyEdge(edge, current, edge.source);
          }

          if (neighbor != null) {
            forest.addEdgeS(spanningEdge!);
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }
    }

    return forest;
  }

  Edge _copyEdge(Edge edge, Node source, Node destination) {
    return Edge(
      source,
      destination,
      key: edge.key,
      paint: edge.paint,
      label: edge.label,
      labelStyle: edge.labelStyle,
      labelPosition: edge.labelPosition,
      labelFollowsEdgeDirection: edge.labelFollowsEdgeDirection,
      labelWidget: edge.labelWidget,
      controlPoint: edge.controlPoint,
      renderer: edge.renderer,
    );
  }

  Size _layoutSpanningTree(Graph spanningTree, double shiftX, double shiftY) {
    nodeData.clear();
    baseBounds.clear();
    polarLocations.clear();

    _initializeData(spanningTree);
    final roots = _findRoots(spanningTree);

    final radialRoots = roots.isEmpty && spanningTree.nodes.isNotEmpty
        ? [spanningTree.nodes.first]
        : roots;

    if (roots.isEmpty && spanningTree.nodes.isNotEmpty) {
      final fakeRoot = spanningTree.nodes.first;
      _buildRegularTree(spanningTree, [fakeRoot]);
    } else {
      _buildRegularTree(spanningTree, roots);
    }

    _setRadialLocations(spanningTree, radialRoots);
    _putRadialPointsInModel(spanningTree);

    _shiftCoordinates(spanningTree, shiftX, shiftY);
    return spanningTree.calculateGraphSize();
  }

  @override
  void init(Graph? graph) {
    // Implementation can be added if needed
  }

  @override
  void setDimensions(double width, double height) {
    // Implementation can be added if needed
  }

  List<Node> successorsOf(Node? node) {
    if (node == null || !nodeData.containsKey(node)) {
      return [];
    }
    return nodeData[node]!.successorNodes;
  }

  @override
  EdgeRenderer? renderer;
}
