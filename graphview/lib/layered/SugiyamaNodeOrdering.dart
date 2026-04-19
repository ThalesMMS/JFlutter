part of graphview;

mixin SugiyamaNodeOrdering on _SugiyamaAlgorithmState {
  void nodeOrdering() {
    // The `layers` variable is the member variable of the class.
    // We will modify it directly. There is no need for a separate 'best' copy
    // with the current iterative improvement strategy.

    // Precalculate predecessor and successor info, must be done here after adding the dummy nodes
    for (final data in nodeData.values) {
      data.predecessorNodes.clear();
      data.successorNodes.clear();
    }
    for (final element in graph.edges) {
      nodeData[element.source]?.successorNodes.add(element.destination);
      nodeData[element.destination]?.predecessorNodes.add(element.source);
    }

    bool applyTranspose() {
      return configuration.crossMinimizationStrategy ==
              CrossMinimizationStrategy.simple
          ? transposeSimple(layers)
          : transposeAccumulator(layers);
    }

    for (var i = 0; i < configuration.iterations; i++) {
      final evenMedianChanged = median(layers, i * 2);
      final evenTransposeChanged = applyTranspose();
      final oddMedianChanged = median(layers, i * 2 + 1);
      final oddTransposeChanged = applyTranspose();

      if (!evenMedianChanged &&
          !evenTransposeChanged &&
          !oddMedianChanged &&
          !oddTransposeChanged) {
        break;
      }
    }

    // Set final positions based on the optimized order.
    for (var currentLayer in layers) {
      for (var pos = 0; pos < currentLayer.length; pos++) {
        nodeData[currentLayer[pos]]?.position = pos;
      }
    }
  }

  bool median(List<List<Node>> layers, int currentIteration) {
    var changed = false;

    if (currentIteration % 2 == 0) {
      for (var i = 1; i < layers.length; i++) {
        var currentLayer = layers[i];
        var previousLayer = layers[i - 1];
        final originalLayer = List<Node>.from(currentLayer);
        final previousPositions = <Node, int>{};
        final currentPositions = <Node, int>{};

        for (var pos = 0; pos < previousLayer.length; pos++) {
          previousPositions[previousLayer[pos]] = pos;
        }
        for (var pos = 0; pos < currentLayer.length; pos++) {
          currentPositions[currentLayer[pos]] = pos;
        }

        for (final node in currentLayer) {
          final positions = <int>[];
          for (final predecessor in predecessorsOf(node)) {
            final position = previousPositions[predecessor];
            if (position != null) {
              positions.add(position);
            }
          }
          positions.sort();
          nodeData[node]!.median = positions.isEmpty
              ? currentPositions[node] ?? 0
              : _forwardMedianValue(positions);
        }

        currentLayer
            .sort((n1, n2) => _compareByMedian(n1, n2, currentPositions));
        changed = changed || !_sameOrder(originalLayer, currentLayer);
      }
    } else {
      for (var l = layers.length - 2; l >= 0; l--) {
        final currentLayer = layers[l];
        final nextLayer = layers[l + 1];
        final originalLayer = List<Node>.from(currentLayer);
        final nextPositions = <Node, int>{};
        final currentPositions = <Node, int>{};

        for (var pos = 0; pos < nextLayer.length; pos++) {
          nextPositions[nextLayer[pos]] = pos;
        }
        for (var pos = 0; pos < currentLayer.length; pos++) {
          currentPositions[currentLayer[pos]] = pos;
        }

        for (var i = currentLayer.length - 1; i >= 0; i--) {
          final node = currentLayer[i];
          final positions = <int>[];
          for (final successor in successorsOf(node)) {
            final position = nextPositions[successor];
            if (position != null) {
              positions.add(position);
            }
          }
          positions.sort();
          nodeData[node]!.median = positions.isEmpty
              ? currentPositions[node] ?? 0
              : _backwardMedianValue(positions);
        }

        currentLayer
            .sort((n1, n2) => _compareByMedian(n1, n2, currentPositions));
        changed = changed || !_sameOrder(originalLayer, currentLayer);
      }
    }

    return changed;
  }

  bool _sameOrder(List<Node> before, List<Node> after) {
    if (before.length != after.length) {
      return false;
    }
    for (var i = 0; i < before.length; i++) {
      if (before[i] != after[i]) {
        return false;
      }
    }
    return true;
  }

  int _compareByMedian(
      Node firstNode, Node secondNode, Map<Node, int> currentPositions) {
    final medianComparison =
        nodeData[firstNode]!.median - nodeData[secondNode]!.median;
    if (medianComparison != 0) {
      return medianComparison;
    }
    return (currentPositions[firstNode] ?? 0) -
        (currentPositions[secondNode] ?? 0);
  }

  int _forwardMedianValue(List<int> positions) {
    var median = positions.length ~/ 2;

    if (positions.length == 1) {
      median = positions[0];
    } else if (positions.length == 2) {
      median = (positions[0] + positions[1]) ~/ 2;
    } else if (positions.length % 2 == 1) {
      median = positions[median];
    } else {
      final left = positions[median - 1] - positions[0];
      final right = positions[positions.length - 1] - positions[median];
      if (left + right != 0) {
        median = (positions[median - 1] * right + positions[median] * left) ~/
            (left + right);
      } else {
        median = (positions[median - 1] + positions[median]) ~/ 2;
      }
    }

    return median;
  }

  int _backwardMedianValue(List<int> positions) {
    if (positions.length == 1) {
      return positions[0];
    }

    final median = positions.length ~/ 2;
    if (positions.length % 2 == 1) {
      return positions[median];
    }

    return (positions[median - 1] + positions[median]) ~/ 2;
  }

  bool transposeSimple(List<List<Node>> layers) {
    var changed = false;
    var improved = true;

    while (improved) {
      improved = false;
      for (var l = 0; l < layers.length - 1; l++) {
        final northernNodes = layers[l];
        final southernNodes = layers[l + 1];

        // Create a map that holds the index of every [Node]. Key is the [Node] and value is the index of the item.
        final indexMap = HashMap.of(
            northernNodes.asMap().map((key, value) => MapEntry(value, key)));

        for (var i = 0; i < southernNodes.length - 1; i++) {
          final v = southernNodes[i];
          final w = southernNodes[i + 1];
          if (crossingCount(indexMap, v, w) > crossingCount(indexMap, w, v)) {
            improved = true;
            exchangeByIndex(southernNodes, i, i + 1);
            changed = true;
          }
        }
      }
    }
    return changed;
  }

  bool transposeAccumulator(List<List<Node>> layers) {
    var changed = false;
    var improved = true;

    while (improved) {
      improved = false;
      for (var l = 0; l < layers.length - 1; l++) {
        final upperLayer = layers[l];
        final lowerLayer = layers[l + 1];

        // Calculate the total crossings for this pair of layers before any swaps.
        var crossingsBefore = _getBiLayerCrossings(upperLayer, lowerLayer);
        if (crossingsBefore == 0) continue;

        for (var i = 0; i < lowerLayer.length - 1; i++) {
          // Perform a trial swap
          exchangeByIndex(lowerLayer, i, i + 1);

          // Recalculate total crossings with the more efficient method.
          var crossingsAfter = _getBiLayerCrossings(upperLayer, lowerLayer);

          if (crossingsAfter < crossingsBefore) {
            // The swap was good, keep it.
            improved = true;
            changed = true;
            crossingsBefore =
                crossingsAfter; // Update the baseline crossing count
          } else {
            // The swap was not beneficial, revert it.
            exchangeByIndex(lowerLayer, i, i + 1);
          }
        }
      }
    }
    return changed;
  }

  /// Calculates the number of crossings between two specific layers using the AccumulatorTree.
  int _getBiLayerCrossings(List<Node> upperLayer, List<Node> lowerLayer) {
    if (upperLayer.isEmpty || lowerLayer.isEmpty) {
      return 0;
    }

    // Update positions in nodeData based on the current list order.
    // This is crucial as the transpose function modifies the list directly.
    for (var i = 0; i < upperLayer.length; i++) {
      nodeData[upperLayer[i]]!.position = i;
    }
    for (var i = 0; i < lowerLayer.length; i++) {
      nodeData[lowerLayer[i]]!.position = i;
    }

    final targetIndices = <int>[];
    final lowerSet = lowerLayer.toSet();

    for (final source in upperLayer) {
      final successors = successorsOf(source)
          .where((succ) => lowerSet.contains(succ))
          .toList()
        ..sort(
            (a, b) => nodeData[a]!.position.compareTo(nodeData[b]!.position));

      for (final successor in successors) {
        targetIndices.add(nodeData[successor]!.position);
      }
    }

    if (targetIndices.isNotEmpty) {
      final maxIndex = targetIndices.reduce(max);
      final accumTree = AccumulatorTree(maxIndex + 1);
      return accumTree.crossCount(targetIndices);
    }

    return 0;
  }

  void exchangeByIndex(List<Node> nodes, int i, int j) {
    var temp = nodes[i];
    nodes[i] = nodes[j];
    nodes[j] = temp;
  }

  // counts the number of edge crossings if n2 appears to the left of n1 in their layer.;
  int crossingCount(HashMap<Node, int> northernNodes, Node n1, Node n2) {
    final indexOf = (Node node) => northernNodes[node]!;
    var crossing = 0;
    final parentNodesN1 = predecessorsOf(n1);
    final parentNodesN2 = predecessorsOf(n2);
    for (final pn2 in parentNodesN2) {
      final indexOfPn2 = indexOf(pn2);
      for (final parentNode in parentNodesN1) {
        if (indexOfPn2 < indexOf(parentNode)) {
          crossing++;
        }
      }
    }

    return crossing;
  }
}
