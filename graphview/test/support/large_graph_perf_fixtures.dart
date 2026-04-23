import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

enum GraphTopology { chain, tree, dense, grid }

class LargeGraphFixture {
  const LargeGraphFixture({
    required this.graph,
    required this.nodes,
    required this.edges,
    required this.canvasSize,
  });

  final Graph graph;
  final List<Node> nodes;
  final List<Edge> edges;
  final Size canvasSize;
}

LargeGraphFixture createLargeGraphFixture({
  required int nodeCount,
  required GraphTopology topology,
  bool prePositioned = true,
}) {
  if (nodeCount <= 0) {
    throw ArgumentError.value(
      nodeCount,
      'nodeCount',
      'must be greater than 0',
    );
  }

  final graph = Graph();
  final nodes = List<Node>.generate(nodeCount, (index) {
    final node = Node.Id(index);
    node.size = const Size(24, 24);
    return node;
  }, growable: false);
  graph.addNodes(nodes);

  if (prePositioned) {
    _positionNodes(nodes, topology);
    _normalizeNodePositions(nodes);
  }

  final edges = switch (topology) {
    GraphTopology.chain => _buildChainEdges(graph, nodes),
    GraphTopology.tree => _buildTreeEdges(graph, nodes),
    GraphTopology.dense => _buildDenseEdges(graph, nodes),
    GraphTopology.grid => _buildGridEdges(graph, nodes),
  };

  return LargeGraphFixture(
    graph: graph,
    nodes: nodes,
    edges: edges,
    canvasSize: _resolveCanvasSize(nodes),
  );
}

class CountingStaticLayoutAlgorithm extends Algorithm {
  CountingStaticLayoutAlgorithm({EdgeRenderer? renderer}) {
    this.renderer = renderer ??
        AdaptiveEdgeRenderer(
          config: EdgeRoutingConfig()
            ..anchorMode = AnchorMode.dynamic
            ..routingMode = RoutingMode.bezier
            ..enableRepulsion = false,
        );
  }

  int runCount = 0;

  @override
  void init(Graph? graph) {}

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    runCount++;
    if (graph == null || graph.nodes.isEmpty) {
      return Size.zero;
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final node in graph.nodes) {
      minX = math.min(minX, node.position.dx);
      minY = math.min(minY, node.position.dy);
      maxX = math.max(maxX, node.position.dx + node.width);
      maxY = math.max(maxY, node.position.dy + node.height);
    }

    if (!minX.isFinite || !minY.isFinite) {
      return Size.zero;
    }

    return Size(
      math.max(0.0, maxX - minX + 48),
      math.max(0.0, maxY - minY + 48),
    );
  }

  @override
  void setDimensions(double width, double height) {}
}

double averageMilliseconds(Iterable<Duration> samples) {
  final values = samples.toList(growable: false);
  if (values.isEmpty) {
    throw ArgumentError.value(samples, 'samples', 'must not be empty');
  }
  final totalMicroseconds = values.fold<int>(
    0,
    (sum, sample) => sum + sample.inMicroseconds,
  );
  return totalMicroseconds / values.length / 1000.0;
}

double medianMilliseconds(Iterable<Duration> samples) {
  final values = samples.toList(growable: false);
  if (values.isEmpty) {
    throw ArgumentError.value(samples, 'samples', 'must not be empty');
  }
  final sorted = values.map((value) => value.inMicroseconds).toList()..sort();
  final middle = sorted.length ~/ 2;
  final medianMicroseconds = sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2.0;
  return medianMicroseconds / 1000.0;
}

List<Edge> _buildChainEdges(Graph graph, List<Node> nodes) {
  final edges = <Edge>[];
  for (var index = 0; index < nodes.length - 1; index++) {
    edges.add(graph.addEdge(nodes[index], nodes[index + 1]));
  }
  return edges;
}

List<Edge> _buildTreeEdges(Graph graph, List<Node> nodes) {
  final edges = <Edge>[];
  var nextChild = 1;
  for (var parentIndex = 0;
      parentIndex < nodes.length && nextChild < nodes.length;
      parentIndex++) {
    for (var branch = 0; branch < 3 && nextChild < nodes.length; branch++) {
      edges.add(graph.addEdge(nodes[parentIndex], nodes[nextChild]));
      nextChild++;
    }
  }
  return edges;
}

List<Edge> _buildDenseEdges(Graph graph, List<Node> nodes) {
  final edges = <Edge>[];
  const fanOut = 5;
  for (var index = 0; index < nodes.length; index++) {
    for (var offset = 1;
        offset <= fanOut && index + offset < nodes.length;
        offset++) {
      edges.add(graph.addEdge(nodes[index], nodes[index + offset]));
    }
  }
  return edges;
}

List<Edge> _buildGridEdges(Graph graph, List<Node> nodes) {
  final edges = <Edge>[];
  final columns = math.max(1, math.sqrt(nodes.length).ceil());
  for (var index = 0; index < nodes.length; index++) {
    final column = index % columns;
    final right = index + 1;
    final below = index + columns;
    if (column < columns - 1 && right < nodes.length) {
      edges.add(graph.addEdge(nodes[index], nodes[right]));
    }
    if (below < nodes.length) {
      edges.add(graph.addEdge(nodes[index], nodes[below]));
    }
  }
  return edges;
}

void _positionNodes(List<Node> nodes, GraphTopology topology) {
  switch (topology) {
    case GraphTopology.chain:
      for (var index = 0; index < nodes.length; index++) {
        final row = index ~/ 40;
        final column = index % 40;
        nodes[index].position = Offset(
          40 + (column * 48.0),
          40 + (row * 64.0),
        );
      }
    case GraphTopology.tree:
      for (var index = 0; index < nodes.length; index++) {
        if (index == 0) {
          nodes[index].position = const Offset(400, 40);
          continue;
        }
        final level = math.max(
          0,
          (math.log((2 * index) + 1) / math.log(3)).floor(),
        );
        final levelStart = ((math.pow(3, level) - 1) / 2).toInt();
        final slot = index - levelStart;
        final nodesInLevel = math.pow(3, level).toInt();
        final spread = math.max(180.0, nodesInLevel * 28.0);
        final step = nodesInLevel == 1 ? 0.0 : spread / (nodesInLevel - 1);
        nodes[index].position = Offset(
          400 - (spread / 2) + (slot * step),
          40 + (level * 84.0),
        );
      }
    case GraphTopology.dense:
      final columns = math.max(1, math.sqrt(nodes.length).ceil());
      for (var index = 0; index < nodes.length; index++) {
        final row = index ~/ columns;
        final column = index % columns;
        nodes[index].position = Offset(
          32 + (column * 44.0),
          32 + (row * 44.0),
        );
      }
    case GraphTopology.grid:
      final columns = math.max(1, math.sqrt(nodes.length).ceil());
      for (var index = 0; index < nodes.length; index++) {
        final row = index ~/ columns;
        final column = index % columns;
        nodes[index].position = Offset(
          32 + (column * 48.0),
          32 + (row * 48.0),
        );
      }
  }
}

void _normalizeNodePositions(List<Node> nodes) {
  if (nodes.isEmpty) {
    return;
  }

  var minX = double.infinity;
  var minY = double.infinity;
  for (final node in nodes) {
    minX = math.min(minX, node.position.dx);
    minY = math.min(minY, node.position.dy);
  }

  if (!minX.isFinite || !minY.isFinite) {
    return;
  }

  final shift = Offset(-minX, -minY);
  if (shift == Offset.zero) {
    return;
  }

  for (final node in nodes) {
    node.position += shift;
  }
}

Size _resolveCanvasSize(List<Node> nodes) {
  var maxX = 0.0;
  var maxY = 0.0;
  for (final node in nodes) {
    maxX = math.max(maxX, node.position.dx + node.width);
    maxY = math.max(maxY, node.position.dy + node.height);
  }
  return Size(maxX + 48.0, maxY + 48.0);
}
