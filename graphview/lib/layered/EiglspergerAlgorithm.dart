part of graphview;

abstract class _EiglspergerAlgorithmState extends Algorithm {
  Map<Node, EiglspergerNodeData> get nodeData;

  Map<Edge, EiglspergerEdgeData> get _edgeData;

  Set<Node> get stack;

  Set<Node> get visited;

  List<List<Node>> get layers;

  List<Segment> get segments;

  Graph get graph;

  SugiyamaConfiguration get configuration;

  int get dummyId;

  bool isVertical();

  List<Node> successorsOf(Node? node);

  List<Node> predecessorsOf(Node? node);

  List<Node> getAdjNodes(Node node, bool downward);

  Node? predecessor(Node? v, bool leftToRight);

  Node? virtualTwinNode(Node node, bool downward);

  int positionOfNode(Node? node);

  int getLayerIndex(Node? node);

  bool isLongEdgeDummy(Node? v);
}

class EiglspergerAlgorithm extends _EiglspergerAlgorithmState
    with
        EiglspergerGraphNormalization,
        EiglspergerCoordinateAssignment,
        EiglspergerNodeOrdering {
  @override
  Map<Node, EiglspergerNodeData> nodeData = {};

  @override
  final Map<Edge, EiglspergerEdgeData> _edgeData = {};

  @override
  Set<Node> stack = {};

  @override
  Set<Node> visited = {};

  @override
  List<List<Node>> layers = [];

  @override
  List<Segment> segments = [];
  Set<Edge> typeOneConflicts = {};

  @override
  late Graph graph;

  @override
  SugiyamaConfiguration configuration;

  @override
  EdgeRenderer? renderer;

  var nodeCount = 1;

  EiglspergerAlgorithm(this.configuration) {
    renderer = EiglspergerEdgeRenderer(nodeData, _edgeData,
        configuration.bendPointShape, configuration.addTriangleToEdge);
  }

  @override
  int get dummyId => 'Dummy ${nodeCount++}'.hashCode;

  @override
  bool isVertical() {
    return OrientationUtils.isVertical(configuration.orientation);
  }

  bool needReverseOrder() {
    return OrientationUtils.needReverseOrder(configuration.orientation);
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    this.graph = copyGraph(graph!);
    reset();

    // Handle empty graph
    if (this.graph.nodeCount() == 0) {
      return Size.zero;
    }

    initNodeData();
    cycleRemoval();
    layerAssignment();
    nodeOrdering(); // Eiglsperger 6-step process
    coordinateAssignment();
    shiftCoordinates(shiftX, shiftY);
    denormalize();
    final graphSize = graph.calculateGraphSize();
    restoreCycle();
    return graphSize;
  }

  void reset() {
    layers.clear();
    stack.clear();
    visited.clear();
    nodeData.clear();
    _edgeData.clear();
    segments.clear();
    typeOneConflicts.clear();
    resetMissingPositionLog();
    Segment.resetIds();
    nodeCount = 1;
  }

  static double medianValue(List<int> positions) {
    if (positions.isEmpty) return 0.0;
    if (positions.length == 1) return positions[0].toDouble();

    positions.sort();
    final mid = positions.length ~/ 2;

    if (positions.length % 2 == 1) {
      return positions[mid].toDouble();
    } else if (positions.length == 2) {
      return (positions[0] + positions[1]) / 2.0;
    } else {
      final left = positions[mid - 1] - positions[0];
      final right = positions[positions.length - 1] - positions[mid];
      if (left + right == 0) return 0.0;
      return (positions[mid - 1] * right + positions[mid] * left) /
          (left + right);
    }
  }

  @override
  void init(Graph? graph) {
    this.graph = copyGraph(graph!);
    reset();
    initNodeData();
    cycleRemoval();
    layerAssignment();
    nodeOrdering();
    coordinateAssignment();
    denormalize();
    restoreCycle();
  }

  @override
  void setDimensions(double width, double height) {
    // Can be used to set layout bounds if needed
  }
}
