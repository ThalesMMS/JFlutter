part of graphview;

mixin EiglspergerNodeOrdering on _EiglspergerAlgorithmState {
  bool _missingPositionLogged = false;

  void resetMissingPositionLog() {
    _missingPositionLogged = false;
  }

  void nodeOrdering() {
    final best = <List<Node>>[
      for (final layer in layers) List<Node>.from(layer)
    ];

    // Precalculate neighbor information

    var bestCrossCount = _totalCrossings(layers);

    for (var i = 0; i < configuration.iterations; i++) {
      var crossCount = 0.0;

      if (i % 2 == 0) {
        crossCount = forwardSweep(layers);
      } else {
        crossCount = backwardSweep(layers);
      }

      if (crossCount < bestCrossCount) {
        bestCrossCount = crossCount;
        // Save best configuration
        for (var layerIndex = 0; layerIndex < layers.length; layerIndex++) {
          best[layerIndex] = List.from(layers[layerIndex]);
        }
      }

      if (crossCount == 0) break;
    }

    // Restore best configuration
    for (var layerIndex = 0; layerIndex < layers.length; layerIndex++) {
      layers[layerIndex] = best[layerIndex];
    }

    // Set final positions
    updateNodePositions();
  }

  double _totalCrossings(List<List<Node>> layers) {
    var totalCrossings = 0.0;
    for (var i = 0; i < layers.length - 1; i++) {
      final currentElements = createLayerElements(layers[i], true);
      final nextElements = createLayerElements(layers[i + 1], true);
      totalCrossings += stepFive(currentElements, nextElements, i, i + 1);
    }
    return totalCrossings;
  }

  double forwardSweep(List<List<Node>> layers) {
    var totalCrossings = 0.0;

    for (var i = 0; i < layers.length - 1; i++) {
      final currentLayer = layers[i];
      final nextLayer = layers[i + 1];

      // Convert to layer elements with containers
      final currentElements = createLayerElements(currentLayer, true);
      final nextElements = createLayerElements(nextLayer, true);

      // Eiglsperger 6-step process
      stepTwo(currentElements, nextElements, true); // true = forward sweep
      stepThree(nextElements);
      stepFour(nextElements);
      totalCrossings += stepFive(currentElements, nextElements, i, i + 1);
      stepSix(nextElements);

      // Convert back to node layer
      layers[i + 1] = extractNodes(nextElements, i + 1);
    }

    return totalCrossings;
  }

  double backwardSweep(List<List<Node>> layers) {
    var totalCrossings = 0.0;

    for (var i = layers.length - 1; i > 0; i--) {
      final currentLayer = layers[i];
      final prevLayer = layers[i - 1];

      final currentElements = createLayerElements(currentLayer, false);
      final prevElements = createLayerElements(prevLayer, false);

      stepTwo(currentElements, prevElements, false); // false = backward sweep
      stepThree(prevElements);
      stepFour(prevElements);
      totalCrossings += stepFive(currentElements, prevElements, i, i - 1);
      stepSix(prevElements);

      layers[i - 1] = extractNodes(prevElements, i - 1);
    }

    return totalCrossings;
  }

  List<LayerElement> createLayerElements(List<Node> layer, bool isForward) {
    final elements = <LayerElement>[
      for (final node in layer) NodeElement(node)
    ];
    stepOne(elements, isForward);
    return elements;
  }

  List<Node> extractNodes(List<LayerElement> elements, int layerIndex) {
    var nodes = <Node>[];
    final seen = <Node>{};

    void addNode(Node node) {
      if (seen.add(node)) {
        nodes.add(node);
      }
    }

    for (var element in elements) {
      if (element is NodeElement) {
        addNode(element.node);
      } else if (element is ContainerElement) {
        // Extract nodes from segments in container that belong to this layer
        for (var segment in element.container.segments) {
          // Check if pVertex belongs to this layer
          if (nodeData[segment.pVertex]?.layer == layerIndex) {
            addNode(segment.pVertex);
          }
          // Check if qVertex belongs to this layer
          if (nodeData[segment.qVertex]?.layer == layerIndex) {
            addNode(segment.qVertex);
          }
        }
      }
    }
    return nodes;
  }

  // Eiglsperger Step 1: Handle P-vertices (forward) or Q-vertices (backward)
  void stepOne(List<LayerElement> layer, bool isForward) {
    var processedElements = <LayerElement>[];
    ContainerX? currentContainer;

    for (var element in layer) {
      if (element is NodeElement) {
        var node = element.node;
        var data = nodeData[node];

        var shouldMerge =
            isForward ? (data?.isPVertex ?? false) : (data?.isQVertex ?? false);

        if (shouldMerge && data?.segment != null) {
          // Merge into container
          currentContainer ??= ContainerX();
          currentContainer.append(data!.segment!);

          if (!processedElements.any((e) =>
              e is ContainerElement && e.container == currentContainer)) {
            processedElements.add(ContainerElement(currentContainer));
          }
        } else {
          // Regular node
          processedElements.add(element);
          currentContainer = null;
        }
      } else {
        processedElements.add(element);
        currentContainer = null;
      }
    }

    layer.clear();
    layer.addAll(processedElements);
  }

  // Eiglsperger Step 2: Compute position values and measures
  void stepTwo(List<LayerElement> currentLayer, List<LayerElement> nextLayer,
      bool isForward) {
    // Assign positions to current layer
    assignPositions(currentLayer);

    // Compute measures for next layer based on current layer positions
    for (var order = 0; order < nextLayer.length; order++) {
      final element = nextLayer[order];
      element.index = order;
      if (element is NodeElement) {
        var node = element.node;
        // Use predecessors for forward sweep, successors for backward sweep
        var adjacentNodes =
            isForward ? predecessorsOf(node) : successorsOf(node);

        final positions = _positionsOfVertices(adjacentNodes, currentLayer);
        if (positions.isNotEmpty) {
          element.measure =
              EiglspergerAlgorithm.medianValue(positions).toDouble();
        } else {
          element.measure = order.toDouble();
        }
      } else if (element is ContainerElement) {
        // For containers, compute measure based on their segments' endpoints
        var segmentMeasures = <double>[];
        for (var segment in element.container.segments) {
          // Get the appropriate vertex based on sweep direction
          var vertex = isForward ? segment.pVertex : segment.qVertex;
          var adjNodes =
              isForward ? predecessorsOf(vertex) : successorsOf(vertex);
          final positions = _positionsOfVertices(adjNodes, currentLayer);
          if (positions.isNotEmpty) {
            segmentMeasures
                .add(EiglspergerAlgorithm.medianValue(positions).toDouble());
          }
        }
        // Use average of segment measures, or current order if no measures.
        element.measure = segmentMeasures.isEmpty
            ? order.toDouble()
            : segmentMeasures.reduce((a, b) => a + b) / segmentMeasures.length;
      }
    }
  }

  void assignPositions(List<LayerElement> layer) {
    var currentPos = 0;
    for (var element in layer) {
      element.pos = currentPos;

      if (element is NodeElement) {
        nodeData[element.node]?.position = currentPos;
        currentPos++;
      } else if (element is ContainerElement) {
        element.container.pos = currentPos;
        for (var i = 0; i < element.container.segments.length; i++) {
          element.container.segments[i].index = i;
        }
        currentPos += element.container.size();
      }
    }
  }

  int? _positionOfVertex(Node vertex, List<LayerElement> layer) {
    for (final element in layer) {
      if (element is NodeElement && element.node == vertex) {
        return element.pos;
      }
      if (element is ContainerElement) {
        for (var i = 0; i < element.container.segments.length; i++) {
          final segment = element.container.segments[i];
          if (segment.pVertex == vertex || segment.qVertex == vertex) {
            return element.pos + i;
          }
        }
      }
    }
    return null;
  }

  List<int> _positionsOfVertices(
      Iterable<Node> vertices, List<LayerElement> layer) {
    final positions = <int>[];
    for (final vertex in vertices) {
      final position = _positionOfVertex(vertex, layer);
      if (position != null) {
        positions.add(position);
      }
    }
    positions.sort();
    return positions;
  }

  // Eiglsperger Step 3: Initial ordering based on measures
  void stepThree(List<LayerElement> layer) {
    var vertices = <LayerElement>[];
    var containers = <ContainerElement>[];

    // Separate vertices and containers
    for (var element in layer) {
      if (element is ContainerElement && element.container.size() > 0) {
        containers.add(element);
      } else if (element is NodeElement) {
        vertices.add(element);
      }
    }

    // Sort by measure
    vertices.sort(_compareByMeasure);
    containers.sort(_compareByMeasure);

    // Assign initial positions to containers based on their sorted order
    var containerPos = 0;
    for (var container in containers) {
      container.pos = containerPos;
      containerPos += container.container.size();
    }

    // Merge lists according to Eiglsperger algorithm
    var merged = mergeSortedLists(vertices, containers);

    layer.clear();
    layer.addAll(merged);
  }

  int _compareByMeasure(LayerElement a, LayerElement b) {
    final measureComparison = a.measure.compareTo(b.measure);
    if (measureComparison != 0) {
      return measureComparison;
    }
    return a.index.compareTo(b.index);
  }

  List<LayerElement> mergeSortedLists(
      List<LayerElement> vertices, List<ContainerElement> containers) {
    var result = <LayerElement>[];
    final pendingContainers = containers.toList();
    var vIndex = 0;
    var cIndex = 0;

    while (vIndex < vertices.length && cIndex < pendingContainers.length) {
      var vertex = vertices[vIndex];
      var container = pendingContainers[cIndex];

      if (vertex.measure <= container.pos) {
        result.add(vertex);
        vIndex++;
      } else if (vertex.measure >=
          (container.pos + container.container.size() - 1)) {
        result.add(container);
        cIndex++;
      } else {
        // Split container
        var k = (vertex.measure - container.pos).ceil();
        var split = ContainerX.splitAt(container.container, k);

        if (split.left.size() > 0) {
          result.add(ContainerElement(split.left));
        }
        result.add(vertex);
        if (split.right.size() > 0) {
          final rightContainer = ContainerElement(split.right);
          rightContainer.pos = container.pos + k;
          pendingContainers.insert(cIndex + 1, rightContainer);
        }
        vIndex++;
        cIndex++;
      }
    }

    // Add remaining elements
    while (vIndex < vertices.length) {
      result.add(vertices[vIndex++]);
    }
    while (cIndex < pendingContainers.length) {
      result.add(pendingContainers[cIndex++]);
    }

    return result;
  }

  // Eiglsperger Step 4: Place Q-vertices according to their segments
  void stepFour(List<LayerElement> layer) {
    var segmentVertices = <NodeElement>[];

    // Find segment vertices in this layer
    for (var element in List.from(layer)) {
      if (element is NodeElement) {
        var data = nodeData[element.node];
        if (data?.isSegmentVertex ?? false) {
          segmentVertices.add(element);
          layer.remove(element);
        }
      }
    }

    // Place each segment vertex
    for (var segmentElement in segmentVertices) {
      var segmentNode = segmentElement.node;
      var data = nodeData[segmentNode];
      var segment = data?.segment;

      if (segment != null) {
        // Find container containing this segment
        ContainerElement? containerElement;
        for (var element in layer) {
          if (element is ContainerElement &&
              element.container.contains(segment)) {
            containerElement = element;
            break;
          }
        }

        if (containerElement != null) {
          var containerIndex = layer.indexOf(containerElement);
          var split = ContainerX.split(containerElement.container, segment);

          layer.removeAt(containerIndex);

          if (split.left.size() > 0) {
            layer.insert(containerIndex, ContainerElement(split.left));
            containerIndex++;
          }

          layer.insert(containerIndex, segmentElement);
          containerIndex++;

          if (split.right.size() > 0) {
            layer.insert(containerIndex, ContainerElement(split.right));
          }
        } else {
          // No container found, just add the segment vertex
          layer.add(segmentElement);
        }
      }
    }

    updateIndices(layer);
  }

  void updateIndices(List<LayerElement> layer) {
    var currentPos = 0;
    for (var i = 0; i < layer.length; i++) {
      final element = layer[i];
      element.index = i;
      element.pos = currentPos;
      if (element is NodeElement) {
        currentPos++;
      } else if (element is ContainerElement) {
        element.container.pos = currentPos;
        for (var segmentIndex = 0;
            segmentIndex < element.container.segments.length;
            segmentIndex++) {
          element.container.segments[segmentIndex].index = segmentIndex;
        }
        currentPos += element.container.size();
      }
    }
  }

  // Eiglsperger Step 5: Cross counting with virtual edges
  double stepFive(List<LayerElement> currentLayer, List<LayerElement> nextLayer,
      int currentRank, int nextRank) {
    // Remove empty containers
    currentLayer
        .removeWhere((e) => e is ContainerElement && e.container.isEmpty);
    nextLayer.removeWhere((e) => e is ContainerElement && e.container.isEmpty);

    updateIndices(currentLayer);
    updateIndices(nextLayer);

    // Collect all edges including virtual edges
    var allEdges = <dynamic>[];

    // Add regular graph edges between these layers
    for (var edge in graph.edges) {
      if (nodeData[edge.source]?.layer == currentRank &&
          nodeData[edge.destination]?.layer == nextRank) {
        allEdges.add(edge);
      } else if (nodeData[edge.destination]?.layer == currentRank &&
          nodeData[edge.source]?.layer == nextRank) {
        allEdges.add(Edge(edge.destination, edge.source));
      }
    }

    // Add virtual edges for containers
    for (var element in nextLayer) {
      if (element is ContainerElement && element.container.size() > 0) {
        final source = findVirtualEdgeSource(element, currentLayer);
        if (source != null) {
          var virtualEdge =
              VirtualEdge(source, element, element.container.size());
          allEdges.add(virtualEdge);
        }
      } else if (element is NodeElement) {
        var data = nodeData[element.node];
        if (data?.isSegmentVertex ?? false) {
          final source = findVirtualEdgeSource(element, currentLayer);
          if (source != null) {
            var virtualEdge = VirtualEdge(source, element.node, 1);
            allEdges.add(virtualEdge);
          }
        }
      }
    }

    // Count crossings with weights
    return countWeightedCrossings(allEdges, currentLayer, nextLayer);
  }

  double countWeightedCrossings(List<dynamic> edges,
      List<LayerElement> currentLayer, List<LayerElement> nextLayer) {
    var crossings = 0.0;
    final positionedEdges = <_PositionedEdge>[];

    for (final edge in edges) {
      final source = getSourcePosition(edge, currentLayer);
      final target = getTargetPosition(edge, nextLayer);
      if (source < 0 || target < 0) {
        continue;
      }
      positionedEdges.add(_PositionedEdge(source, target, getEdgeWeight(edge)));
    }

    for (var i = 0; i < positionedEdges.length - 1; i++) {
      for (var j = i + 1; j < positionedEdges.length; j++) {
        var edge1 = positionedEdges[i];
        var edge2 = positionedEdges[j];

        if (edge1.source < edge2.source && edge1.target > edge2.target ||
            edge1.source > edge2.source && edge1.target < edge2.target) {
          crossings += edge1.weight * edge2.weight;
        }
      }
    }

    return crossings;
  }

  int getEdgeWeight(dynamic edge) {
    if (edge is VirtualEdge) {
      return edge.weight;
    }
    return 1;
  }

  Object? findVirtualEdgeSource(
      LayerElement target, List<LayerElement> currentLayer) {
    final targetSegments = <Segment>{};

    if (target is ContainerElement) {
      targetSegments.addAll(target.container.segments);
    } else if (target is NodeElement) {
      final segment = nodeData[target.node]?.segment;
      if (segment != null) {
        targetSegments.add(segment);
      }
    }

    if (targetSegments.isEmpty) {
      return null;
    }

    for (final element in currentLayer) {
      if (element is ContainerElement &&
          element.container.segments.any(targetSegments.contains)) {
        return element;
      }
      if (element is NodeElement) {
        final segment = nodeData[element.node]?.segment;
        if (segment != null && targetSegments.contains(segment)) {
          return element;
        }
      }
    }

    return null;
  }

  int getSourcePosition(dynamic edge, List<LayerElement> currentLayer) {
    if (edge is VirtualEdge) {
      return _positionOfEndpoint(edge.source, currentLayer);
    } else if (edge is Edge) {
      return _positionOfEndpoint(edge.source, currentLayer);
    }
    return _missingPosition('source', edge);
  }

  int getTargetPosition(dynamic edge, List<LayerElement> nextLayer) {
    if (edge is VirtualEdge) {
      return _positionOfEndpoint(edge.target, nextLayer);
    } else if (edge is Edge) {
      return _positionOfEndpoint(edge.destination, nextLayer);
    }
    return _missingPosition('target', edge);
  }

  int _positionOfEndpoint(Object? endpoint, List<LayerElement> layer) {
    for (var i = 0; i < layer.length; i++) {
      final element = layer[i];
      if (element == endpoint) {
        return element.pos;
      }
      if (element is NodeElement && element.node == endpoint) {
        return element.pos;
      }
      if (endpoint is Node && element is ContainerElement) {
        for (var segmentIndex = 0;
            segmentIndex < element.container.segments.length;
            segmentIndex++) {
          final segment = element.container.segments[segmentIndex];
          if (segment.pVertex == endpoint || segment.qVertex == endpoint) {
            return element.pos + segmentIndex;
          }
        }
      }
    }
    return _missingPosition('endpoint', endpoint);
  }

  int _missingPosition(String kind, Object? value) {
    assert(() {
      if (!_missingPositionLogged) {
        _missingPositionLogged = true;
        debugPrint(
            'EiglspergerNodeOrdering: missing $kind position for $value; '
            'skipping this crossing comparison');
      }
      return true;
    }());
    return -1;
  }

  // Eiglsperger Step 6: Scan and ensure alternating structure
  void stepSix(List<LayerElement> layer) {
    var scanned = <LayerElement>[];

    for (final element in layer) {
      if (scanned.isEmpty) {
        if (element is ContainerElement) {
          scanned.add(element);
        } else {
          scanned.add(ContainerElement(ContainerX.createEmpty()));
          scanned.add(element);
        }
      } else {
        var previous = scanned.last;

        if (previous is ContainerElement && element is ContainerElement) {
          // Join containers
          previous.container.join(element.container);
        } else if (previous is NodeElement && element is NodeElement) {
          // Insert empty container between nodes
          scanned.add(ContainerElement(ContainerX.createEmpty()));
          scanned.add(element);
        } else {
          scanned.add(element);
        }
      }
    }

    // Ensure ends with container
    if (scanned.isNotEmpty && scanned.last is NodeElement) {
      scanned.add(ContainerElement(ContainerX.createEmpty()));
    }

    layer.clear();
    layer.addAll(scanned);
    updateIndices(layer);
  }

  void updateNodePositions() {
    for (var layerIndex = 0; layerIndex < layers.length; layerIndex++) {
      for (var nodeIndex = 0;
          nodeIndex < layers[layerIndex].length;
          nodeIndex++) {
        var node = layers[layerIndex][nodeIndex];
        var data = nodeData[node];
        if (data != null) {
          data.layer = layerIndex;
          data.position = nodeIndex;
          data.rank = layerIndex;
        }
      }
    }
  }
}

class _PositionedEdge {
  final int source;
  final int target;
  final int weight;

  _PositionedEdge(this.source, this.target, this.weight);
}
