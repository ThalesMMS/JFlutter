part of graphview;

mixin EiglspergerCoordinateAssignment on _EiglspergerAlgorithmState {
  void coordinateAssignment() {
    assignX();
    // Resolve any node overlaps that may have occurred
    resolveNodeOverlaps();
    assignY();
    final offset = OrientationUtils.getOffset(graph, configuration.orientation);

    for (final v in graph.nodes) {
      v.position =
          OrientationUtils.getPosition(v, offset, configuration.orientation);
    }
  }

  void assignX() {
    // Brandes-Köpf coordinate assignment with type1Conflicts support
    final root = <Map<Node, Node>>[];
    // each node points to its aligned neighbor in the layer below.
    final align = <Map<Node, Node>>[];
    final sink = <Map<Node, Node>>[];
    final x = <Map<Node, double>>[];
    // minimal separation between the roots of different classes.
    final shift = <Map<Node, double>>[];
    // the width of each block (max width of node in block)
    final blockWidth = <Map<Node, double>>[];

    for (var i = 0; i < 4; i++) {
      root.add({});
      align.add({});
      sink.add({});
      shift.add({});
      x.add({});
      blockWidth.add({});

      for (final n in graph.nodes) {
        root[i][n] = n;
        align[i][n] = n;
        sink[i][n] = n;
        shift[i][n] = double.infinity;
        x[i][n] = double.negativeInfinity;
        blockWidth[i][n] = 0;
      }
    }
    final separation = configuration.nodeSeparation;

    final vertical = isVertical();
    for (var downward = 0; downward <= 1; downward++) {
      final isDownward = downward == 0;
      final type1Conflicts = markType1Conflicts(isDownward);
      for (var leftToRight = 0; leftToRight <= 1; leftToRight++) {
        final k = 2 * downward + leftToRight;
        final isLeftToRight = leftToRight == 0;
        verticalAlignment(
            root[k], align[k], type1Conflicts, isDownward, isLeftToRight);
        for (final v in graph.nodes) {
          final r = root[k][v]!;
          blockWidth[k][r] = max(
              blockWidth[k][r]!, vertical ? v.width + separation : v.height);
        }
        horizontalCompactation(align[k], root[k], sink[k], shift[k],
            blockWidth[k], x[k], isLeftToRight, isDownward, layers, separation);
      }
    }

    balance(x, blockWidth);
  }

  Map<int, int> markType1Conflicts(bool downward) {
    final type1Conflicts = <int, int>{};
    if (layers.length >= 4) {
      int upper;
      int lower; // iteration bounds
      int k1; // node position boundaries of closest inner segments
      if (downward) {
        lower = 1;
        upper = layers.length - 2;
      } else {
        lower = layers.length - 1;
        upper = 2;
      }
      /*
             * iterate level[2..h-2] in the given direction
             * available 1 levels to h
             */
      for (var i = lower;
          downward ? i <= upper : i >= upper;
          i += downward ? 1 : -1) {
        var k0 = 0;
        var firstIndex = 0; // index of first node on layer
        final currentLevel = layers[i];
        final nextLevel = downward ? layers[i + 1] : layers[i - 1];

        // for all nodes on next level
        for (var l1 = 0; l1 < nextLevel.length; l1++) {
          final virtualTwin = virtualTwinNode(nextLevel[l1], downward);

          if (l1 == nextLevel.length - 1 || virtualTwin != null) {
            k1 = currentLevel.length - 1;

            if (virtualTwin != null) {
              k1 = positionOfNode(virtualTwin);
            }

            while (firstIndex <= l1) {
              final upperNeighbours =
                  getAdjNodes(nextLevel[firstIndex], downward);

              for (var currentNeighbour in upperNeighbours) {
                /*
                *  XXX< 0 in first iteration is still ok for indizes starting
                * with 0 because no index can be smaller than 0
                 */
                final currentNeighbourIndex = positionOfNode(currentNeighbour);

                if (currentNeighbourIndex < k0 || currentNeighbourIndex > k1) {
                  type1Conflicts[firstIndex] = currentNeighbourIndex;
                }
              }
              firstIndex++;
            }

            k0 = k1;
          }
        }
      }
    }
    return type1Conflicts;
  }

  void balance(List<Map<Node, double>> x, List<Map<Node?, double>> blockWidth) {
    final coordinates = <Node, double>{};

    for (final n in graph.nodes) {
      var xVal = x[3][n] ?? 0.0;
      // Handle negative infinity case - use fallback from other passes
      if (xVal == double.negativeInfinity || xVal.isNaN || xVal.isInfinite) {
        for (var i = 0; i < 4; i++) {
          final candidate = x[i][n] ?? double.negativeInfinity;
          if (candidate != double.negativeInfinity &&
              !candidate.isNaN &&
              !candidate.isInfinite) {
            xVal = candidate;
            break;
          }
        }
        // If still invalid, default to 0
        if (xVal == double.negativeInfinity || xVal.isNaN || xVal.isInfinite) {
          xVal = 0.0;
        }
      }
      coordinates[n] = xVal;
    }

    // Handle empty graph case
    if (coordinates.isEmpty) {
      return;
    }

    // Get the minimum coordinate value
    final minValue = coordinates.values.reduce(min);

    // Set left border to 0
    if (minValue != 0) {
      for (final n in coordinates.keys) {
        coordinates[n] = coordinates[n]! - minValue;
      }
    }

    for (final v in graph.nodes) {
      v.x = coordinates[v]!;
    }
  }

  /// Resolves node overlaps within each layer by shifting nodes horizontally
  void resolveNodeOverlaps() {
    // Group nodes by layer
    final nodesByLayer = <int, List<Node>>{};
    for (final node in graph.nodes) {
      final layer = nodeData[node]?.layer ?? -1;
      if (layer >= 0) {
        nodesByLayer.putIfAbsent(layer, () => []).add(node);
      }
    }

    // Resolve overlaps within each layer
    for (final layer in nodesByLayer.keys) {
      final nodesInLayer = nodesByLayer[layer]!;

      // Sort nodes by x-coordinate
      nodesInLayer.sort((a, b) => a.x.compareTo(b.x));

      // Shift overlapping nodes
      for (var i = 0; i < nodesInLayer.length - 1; i++) {
        final current = nodesInLayer[i];
        final next = nodesInLayer[i + 1];

        // Calculate minimum required separation
        final currentExtent = isVertical() ? current.width : current.height;
        final minX = current.x + currentExtent + configuration.nodeSeparation;

        // If next node overlaps or is too close, shift it
        if (next.x < minX) {
          next.x = minX;
        }
      }
    }
  }

  void verticalAlignment(Map<Node?, Node?> root, Map<Node?, Node?> align,
      Map<int, int> type1Conflicts, bool downward, bool leftToRight) {
    // for all Level;

    var layersa = downward ? layers : layers.reversed;

    for (var layer in layersa) {
      // As with layers, we need a reversed iterator for blocks for different directions
      var nodes = leftToRight ? layer : layer.reversed;
      // Do an initial placement for all blocks
      var r = leftToRight ? -1 : double.infinity;
      for (var v in nodes) {
        final adjNodes = getAdjNodes(v, downward);
        if (adjNodes.isNotEmpty) {
          var midLevelValue = adjNodes.length / 2;
          // Calculate medians
          final medians = adjNodes.length % 2 == 1
              ? [adjNodes[midLevelValue.floor()]]
              : [
                  adjNodes[midLevelValue.toInt() - 1],
                  adjNodes[midLevelValue.toInt()]
                ];

          // For all median neighbours in direction of H
          for (var m in medians) {
            final posM = positionOfNode(m);
            // if segment (u,v) not marked by type1 conflicts AND ...;
            if (align[v] == v &&
                type1Conflicts[positionOfNode(v)] != posM &&
                (leftToRight ? r < posM : r > posM)) {
              align[m] = v;
              root[v] = root[m];
              align[v] = root[v];
              r = posM;
            }
          }
        }
      }
    }
  }

  void horizontalCompactation(
      Map<Node, Node> align,
      Map<Node, Node> root,
      Map<Node, Node> sink,
      Map<Node, double> shift,
      Map<Node, double> blockWidth,
      Map<Node, double> x,
      bool leftToRight,
      bool downward,
      List<List<Node>> layers,
      int separation) {
    // calculate class relative coordinates for all roots;
    // If the layers are traversed from right to left, a reverse iterator is needed (note that this does not change the original list of layers)
    var layersa = leftToRight ? layers : layers.reversed;

    for (var layer in layersa) {
      // As with layers, we need a reversed iterator for blocks for different directions
      var nodes = downward ? layer : layer.reversed;
      // Do an initial placement for all blocks
      for (var v in nodes) {
        if (root[v] == v) {
          placeBlock(v, sink, shift, x, align, blockWidth, root, leftToRight,
              layers, separation);
        }
      }
    }

    var d = 0.0;
    var i = downward ? 0 : layers.length - 1;
    while (downward && i <= layers.length - 1 || !downward && i >= 0) {
      final currentLevel = layers[i];
      final v = currentLevel[leftToRight ? 0 : currentLevel.length - 1];
      if (v == sink[root[v]]) {
        final oldShift = shift[v]!;
        if (oldShift < double.infinity) {
          shift[v] = oldShift + d;
          d += oldShift;
        } else {
          shift[v] = 0;
        }
      }
      i = downward ? i + 1 : i - 1;
    }

    // apply root coordinates for all aligned nodes;
    // (place block did this only for the roots)+;
    for (final v in graph.nodes) {
      x[v] = x[root[v]]!;
      final shiftVal = shift[sink[root[v]]]!;
      if (shiftVal < double.infinity) {
        x[v] = x[v]! + shiftVal; // apply shift for each class;
      }
    }
  }

  void placeBlock(
      Node v,
      Map<Node, Node> sink,
      Map<Node, double> shift,
      Map<Node, double> x,
      Map<Node, Node> align,
      Map<Node, double> blockWidth,
      Map<Node, Node> root,
      bool leftToRight,
      List<List<Node>> layers,
      int separation) {
    if (x[v] == double.negativeInfinity) {
      x[v] = 0;
      var currentNode = v;

      try {
        do {
          // if not first node on layer;
          final hasPredecessor =
              leftToRight && positionOfNode(currentNode) > 0 ||
                  !leftToRight &&
                      positionOfNode(currentNode) <
                          layers[getLayerIndex(currentNode)].length - 1;
          if (hasPredecessor) {
            final pred = predecessor(currentNode, leftToRight);
            /* Get the root of u (proceeding all the way upwards in the block) */
            final u = root[pred]!;
            /* Place the block of u recursively */
            placeBlock(u, sink, shift, x, align, blockWidth, root, leftToRight,
                layers, separation);
            /* If v is its own sink yet, set its sink to the sink of u */
            if (sink[v] == v) {
              sink[v] = sink[u]!;
            }
            /* If v and u have different sinks (i.e. they are in different classes),
             * shift the sink of u so that the two blocks are separated by the preferred gap  */
            var gap = separation + 0.5 * (blockWidth[u]! + blockWidth[v]!);
            if (sink[v] != sink[u]) {
              if (leftToRight) {
                shift[sink[u]!] = min(shift[sink[u]]!, x[v]! - x[u]! - gap);
              } else {
                shift[sink[u]!] = max(shift[sink[u]]!, x[v]! - x[u]! + gap);
              }
            } else {
              /* v and u have the same sink, i.e. they are in the same level.
              Make sure that v is separated from u by at least gap.*/
              if (leftToRight) {
                x[v] = max(x[v]!, x[u]! + gap);
              } else {
                x[v] = min(x[v]!, x[u]! - gap);
              }
            }
          }
          currentNode = align[currentNode]!;
        } while (currentNode != v);
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(
            StateError('EiglspergerCoordinateAssignment.placeBlock failed: '
                '$error'),
            stackTrace);
      }
    }
  }

  @override
  List<Node> successorsOf(Node? node) {
    return graph.successorsOf(node);
  }

  @override
  List<Node> predecessorsOf(Node? node) {
    return graph.predecessorsOf(node);
  }

  @override
  List<Node> getAdjNodes(Node node, bool downward) {
    if (downward) {
      return predecessorsOf(node);
    } else {
      return successorsOf(node);
    }
  }

  // predecessor;
  @override
  Node? predecessor(Node? v, bool leftToRight) {
    final pos = positionOfNode(v);
    final rank = getLayerIndex(v);
    final level = layers[rank];
    if (leftToRight && pos != 0 || !leftToRight && pos != level.length - 1) {
      return level[(leftToRight) ? pos - 1 : pos + 1];
    } else {
      return null;
    }
  }

  @override
  Node? virtualTwinNode(Node node, bool downward) {
    if (!isLongEdgeDummy(node)) {
      return null;
    }
    final adjNodes = getAdjNodes(node, downward);
    return adjNodes.isEmpty ? null : adjNodes[0];
  }

  // get node index in layer;
  @override
  int positionOfNode(Node? node) {
    return nodeData[node]?.position ?? -1;
  }

  @override
  int getLayerIndex(Node? node) {
    return nodeData[node]?.layer ?? -1;
  }

  @override
  bool isLongEdgeDummy(Node? v) {
    if (v == null) {
      return false;
    }
    final data = nodeData[v];
    if (data == null || !data.isDummy) {
      return false;
    }
    final successors = successorsOf(v);
    if (successors.length != 1) {
      return false;
    }
    return nodeData[successors[0]]?.isDummy ?? false;
  }

  void assignY() {
    final k = layers.length;
    var yPos = 0.0;
    final vertical = isVertical();

    for (var i = 0; i < k; i++) {
      final level = layers[i];
      var maxHeight = 0.0;

      for (final node in level) {
        final h = nodeData[node]!.isDummy
            ? 0.0
            : vertical
                ? node.height
                : node.width;
        if (h > maxHeight) {
          maxHeight = h;
        }
        node.y = yPos;
      }

      if (i < k - 1) {
        yPos += configuration.levelSeparation + maxHeight;
      }
    }
  }
}
