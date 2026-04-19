part of graphview;

mixin SugiyamaCoordinateAssignment on _SugiyamaAlgorithmState {
  void coordinateAssignment() {
    assignX();
    assignY();

    if (configuration.postStraighten) {
      postStraighten();
    }

    final offset = getOffset(graph, needReverseOrder());
    for (final v in graph.nodes) {
      v.position = getPosition(v, offset);
    }
  }

  // Reference parity: follows the paired GraphView Sugiyama coordinate
  // assignment, with fork deltas for four-way coordinate averaging,
  // node-size-aware overlap resolution, node-keyed type-1 conflict tracking,
  // and post-straighten position finalization.
  void assignX() {
    // Existing implementation remains the same
    final root = <Map<Node, Node>>[];
    // each node points to its aligned neighbor in the layer below.;
    final align = <Map<Node, Node>>[];
    final sink = <Map<Node, Node>>[];
    final x = <Map<Node, double>>[];
    // minimal separation between the roots of different classes.;
    final shift = <Map<Node, double>>[];
    // the width of each block (max width of node in block);
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
          blockWidth[k][r] =
              max(blockWidth[k][r]!, vertical ? v.width : v.height);
        }
        horizontalCompactation(align[k], root[k], sink[k], shift[k],
            blockWidth[k], x[k], isLeftToRight, isDownward, layers, separation);
      }
    }

    balance(x, blockWidth);
  }

  void balance(List<Map<Node, double>> x, List<Map<Node?, double>> blockWidth) {
    final coordinates = <Node, double>{};

    switch (configuration.coordinateAssignment) {
      case CoordinateAssignment.Average:
        var minWidth = double.infinity;

        var smallestWidthLayout = 0;
        final minArray = List.filled(4, 0.0);
        final maxArray = List.filled(4, 0.0);

        // Get the layout with the smallest width and set minimum and maximum value for each direction;
        for (var i = 0; i < 4; i++) {
          minArray[i] = double.infinity;
          maxArray[i] = double.negativeInfinity;

          for (final v in graph.nodes) {
            final bw = 0.5 * blockWidth[i][v]!;
            var xp = x[i][v]! - bw;
            if (xp < minArray[i]) {
              minArray[i] = xp;
            }
            xp = x[i][v]! + bw;
            if (xp > maxArray[i]) {
              maxArray[i] = xp;
            }
          }

          final width = maxArray[i] - minArray[i];
          if (width < minWidth) {
            minWidth = width;
            smallestWidthLayout = i;
          }
        }

        // Align the layouts to the one with the smallest width
        for (var layout = 0; layout < 4; layout++) {
          if (layout != smallestWidthLayout) {
            // Align the left to right layouts to the left border of the smallest layout
            var diff = 0.0;
            if (layout % 2 == 0) {
              diff = minArray[layout] - minArray[smallestWidthLayout];
            } else {
              // Align the right to left layouts to the right border of the smallest layout
              diff = maxArray[layout] - maxArray[smallestWidthLayout];
            }
            for (final n in x[layout].keys) {
              x[layout][n] = x[layout][n]! - diff;
            }
          }
        }

        // Get the average median of each coordinate
        final values = List.filled(4, 0.0);
        for (final n in graph.nodes) {
          for (var i = 0; i < 4; i++) {
            values[i] = x[i][n]!;
          }
          values.sort();
          final average = (values[1] + values[2]) * 0.5;
          coordinates[n] = average;
        }
        break;
      case CoordinateAssignment.DownRight:
        for (final n in graph.nodes) {
          coordinates[n] = x[0][n] ?? 0.0;
        }
        break;
      case CoordinateAssignment.DownLeft:
        for (final n in graph.nodes) {
          coordinates[n] = x[1][n] ?? 0.0;
        }
        break;
      case CoordinateAssignment.UpRight:
        for (final n in graph.nodes) {
          coordinates[n] = x[2][n] ?? 0.0;
        }
        break;
      case CoordinateAssignment.UpLeft:
        for (final n in graph.nodes) {
          coordinates[n] = x[3][n] ?? 0.0;
        }
        break;
    }

    if (coordinates.isEmpty && graph.nodes.isEmpty) {
      return;
    }

    if (coordinates.isEmpty) {
      for (final node in graph.nodes) {
        coordinates[node] = 0.0;
      }
    }

    // Get the minimum coordinate value
    final minValue = coordinates.values.reduce(min);

    // Set left border to 0
    if (minValue != 0) {
      for (final n in coordinates.keys) {
        coordinates[n] = coordinates[n]! - minValue;
      }
    }

    resolveOverlaps(coordinates);

    for (final v in graph.nodes) {
      v.x = coordinates[v]!;
    }
  }

  void resolveOverlaps(Map<Node, double> coordinates) {
    for (var layer in layers) {
      if (layer.isEmpty) {
        continue;
      }

      var layerNodes = List<Node>.from(layer);
      layerNodes.sort(
          (a, b) => nodeData[a]!.position.compareTo(nodeData[b]!.position));

      var leftCoordinate = 0.0;
      for (var i = 1; i < layerNodes.length; i++) {
        var currentNode = layerNodes[i];
        if (!nodeData[currentNode]!.isDummy) {
          var previousNode = getPreviousNonDummyNode(layerNodes, i);

          if (previousNode != null) {
            final previousExtent =
                isVertical() ? previousNode.width : previousNode.height;
            final currentExtent =
                isVertical() ? currentNode.width : currentNode.height;
            leftCoordinate = coordinates[previousNode]! +
                previousExtent / 2 +
                currentExtent / 2 +
                configuration.nodeSeparation;
          } else {
            leftCoordinate = 0.0;
          }

          if (leftCoordinate > coordinates[currentNode]!) {
            coordinates[currentNode] = leftCoordinate;
          }
        }
      }
    }
  }

  Node? getPreviousNonDummyNode(List<Node> layerNodes, int currentIndex) {
    for (var i = currentIndex - 1; i >= 0; i--) {
      var previousNode = layerNodes[i];
      if (!nodeData[previousNode]!.isDummy) {
        return previousNode;
      }
    }
    return null;
  }

  Map<Node, Set<Node>> markType1Conflicts(bool downward) {
    final localType1Conflicts = <Node, Set<Node>>{};
    if (layers.length >= 4) {
      int upper;
      int lower; // iteration bounds;
      int k1; // node position boundaries of closest inner segments;
      if (downward) {
        lower = 1;
        upper = layers.length - 2;
      } else {
        lower = layers.length - 1;
        upper = 2;
      }
      /*;
             * iterate level[2..h-2] in the given direction;
             * available 1 levels to h;
             */
      for (var i = lower;
          downward ? i <= upper : i >= upper;
          i += downward ? 1 : -1) {
        var k0 = 0;
        var firstIndex = 0; // index of first node on layer;
        final currentLevel = layers[i];
        final nextLevel = downward ? layers[i + 1] : layers[i - 1];

        // for all nodes on next level;
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
                /*;
                *  XXX< 0 in first iteration is still ok for indizes starting;
                * with 0 because no index can be smaller than 0;
                 */
                final currentNeighbourIndex = positionOfNode(currentNeighbour);

                if (currentNeighbourIndex < k0 || currentNeighbourIndex > k1) {
                  localType1Conflicts
                      .putIfAbsent(nextLevel[firstIndex], () => <Node>{})
                      .add(currentNeighbour);
                }
              }
              firstIndex++;
            }

            k0 = k1;
          }
        }
      }
    }
    return localType1Conflicts;
  }

  void verticalAlignment(Map<Node?, Node?> root, Map<Node?, Node?> align,
      Map<Node, Set<Node>> type1Conflicts, bool downward, bool leftToRight) {
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
            final conflicts = type1Conflicts[v];
            if (align[v] == v &&
                (conflicts == null || !conflicts.contains(m)) &&
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
    var layersa = downward ? layers : layers.reversed;

    for (var layer in layersa) {
      // As with layers, we need a reversed iterator for blocks for different directions
      var nodes = leftToRight ? layer : layer.reversed;
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
            StateError('SugiyamaCoordinateAssignment.placeBlock failed: '
                '$error'),
            stackTrace);
      }
    }
  }

  @override
  List<Node> successorsOf(Node? node) {
    return nodeData[node]?.successorNodes ?? [];
  }

  @override
  List<Node> predecessorsOf(Node? node) {
    return nodeData[node]?.predecessorNodes ?? [];
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

  @override
  Offset getOffset(Graph graph, bool _needReverseOrder) {
    return OrientationUtils.getOffset(graph, configuration.orientation);
  }

  @override
  Offset getPosition(Node node, Offset offset) {
    return OrientationUtils.getPosition(
        node, offset, configuration.orientation);
  }
}
