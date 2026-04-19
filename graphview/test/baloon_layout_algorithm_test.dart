import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

const itemHeight = 100.0;
const itemWidth = 100.0;

void main() {
  group('Balloon Layout Algorithm', () {
    late Graph graph;
    late BuchheimWalkerConfiguration configuration;
    late BalloonLayoutAlgorithm algorithm;

    setUp(() {
      graph = Graph();
      configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = 100
        ..levelSeparation = 150
        ..subtreeSeparation = 150;
      algorithm = BalloonLayoutAlgorithm(configuration, TreeEdgeRenderer(configuration));
    });

    test('Balloon layout handles empty graph', () {
      final size = algorithm.run(graph, 0, 0);
      expect(size, Size.zero);
    });

    test('Balloon layout handles single node', () {
      final node1 = Node.Id(1);
      graph.addNode(node1);
      node1.size = Size(itemWidth, itemHeight);

      final size = algorithm.run(graph, 10, 10);

      expect(node1.position, Offset(110, 110));
      expect(size, Size(200, 200));
    });

    test('Balloon layout positions nodes correctly for simple tree', () {
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      graph.addEdge(node1, node2);
      graph.addEdge(node1, node3);
      graph.addEdge(node1, node4);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final stopwatch = Stopwatch()..start();
      final size = algorithm.run(graph, 10, 10);
      final timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      // Root should be at a calculable position
      final root = graph.getNodeUsingId(1);
      expect(root.position, isNotNull);

      // Children should be positioned around the root
      final child1 = graph.getNodeUsingId(2);
      final child2 = graph.getNodeUsingId(3);
      final child3 = graph.getNodeUsingId(4);

      expect(child1.position, isNotNull);
      expect(child2.position, isNotNull);
      expect(child3.position, isNotNull);

      // All children should be at same distance from root (radial layout)
      final distToChild1 = sqrt(pow(child1.x - root.x, 2) + pow(child1.y - root.y, 2));
      final distToChild2 = sqrt(pow(child2.x - root.x, 2) + pow(child2.y - root.y, 2));
      final distToChild3 = sqrt(pow(child3.x - root.x, 2) + pow(child3.y - root.y, 2));

      expect((distToChild1 - distToChild2).abs() < 1.0, true);
      expect((distToChild2 - distToChild3).abs() < 1.0, true);

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Balloon layout handles larger tree structure', () {
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);
      final node5 = Node.Id(5);
      final node6 = Node.Id(6);
      final node7 = Node.Id(7);
      final node8 = Node.Id(8);

      graph.addEdge(node1, node2);
      graph.addEdge(node1, node3);
      graph.addEdge(node1, node4);
      graph.addEdge(node2, node5);
      graph.addEdge(node2, node6);
      graph.addEdge(node4, node7);
      graph.addEdge(node4, node8);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final size = algorithm.run(graph, 0, 0);

      // Verify all nodes have positions
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.position, isNotNull);
        expect(node.x.isFinite, true);
        expect(node.y.isFinite, true);
      }

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Balloon layout handles cyclic graph via spanning tree', () {
      final nodeA = Node.Id('A');
      final nodeB = Node.Id('B');
      final nodeC = Node.Id('C');
      final nodeD = Node.Id('D');

      // Create cycle: A -> B -> C -> A, plus D connected to A
      graph.addEdge(nodeA, nodeB);
      graph.addEdge(nodeB, nodeC);
      graph.addEdge(nodeC, nodeA); // This creates the cycle
      graph.addEdge(nodeA, nodeD);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      // Should not throw - should handle cycle by creating spanning tree
      final size = algorithm.run(graph, 0, 0);

      // Verify all nodes have valid positions
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.position, isNotNull);
        expect(node.x.isFinite, true);
        expect(node.y.isFinite, true);
      }

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Balloon layout handles multiple roots', () {
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);
      final node5 = Node.Id(5);
      final node6 = Node.Id(6);

      // Create two separate trees
      graph.addEdge(node1, node2);
      graph.addEdge(node1, node3);
      graph.addEdge(node4, node5);
      graph.addEdge(node4, node6);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final size = algorithm.run(graph, 0, 0);

      // Verify all nodes have positions
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.position, isNotNull);
        expect(node.x.isFinite, true);
        expect(node.y.isFinite, true);
      }

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Balloon layout polar coordinates are set correctly', () {
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);

      graph.addEdge(node1, node2);
      graph.addEdge(node1, node3);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      algorithm.run(graph, 0, 0);

      // Root should have origin polar coordinates
      final rootPolar = algorithm.getPolarLocation(node1);
      expect(rootPolar, isNotNull);
      expect(rootPolar!.theta, 0);
      expect(rootPolar.radius, 0);

      // Children should have polar coordinates set
      final child1Polar = algorithm.getPolarLocation(node2);
      final child2Polar = algorithm.getPolarLocation(node3);

      expect(child1Polar, isNotNull);
      expect(child2Polar, isNotNull);
      expect(child1Polar!.radius > 0, true);
      expect(child2Polar!.radius > 0, true);

      // Children should have different angles
      expect(child1Polar.theta != child2Polar.theta, true);
    });

    test('Balloon layout radii are calculated correctly', () {
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      graph.addEdge(node1, node2);
      graph.addEdge(node1, node3);
      graph.addEdge(node2, node4);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      algorithm.run(graph, 0, 0);

      final radii = algorithm.getRadii();

      // Root has no radius (at origin)
      expect(radii[node1], isNull);

      // Children should have radii
      expect(radii[node2], isNotNull);
      expect(radii[node3], isNotNull);
      expect(radii[node4], isNotNull);

      // Siblings should have same radius
      expect((radii[node2]! - radii[node3]!).abs() < 0.001, true);
    });

    test('Balloon layout with shift offset', () {
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);

      graph.addEdge(node1, node2);
      graph.addEdge(node1, node3);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final shiftX = 50.0;
      final shiftY = 75.0;

      // First run without shift to get baseline positions
      final unshiftedGraph = Graph();
      final uNode1 = Node.Id(1);
      final uNode2 = Node.Id(2);
      final uNode3 = Node.Id(3);
      unshiftedGraph.addEdge(uNode1, uNode2);
      unshiftedGraph.addEdge(uNode1, uNode3);
      for (var i = 0; i < unshiftedGraph.nodeCount(); i++) {
        unshiftedGraph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final unshiftedAlg = BalloonLayoutAlgorithm(configuration, TreeEdgeRenderer(configuration));
      unshiftedAlg.run(unshiftedGraph, 0, 0);

      // Now run with shift
      algorithm.run(graph, shiftX, shiftY);

      // Verify that the shift was applied correctly by comparing positions
      for (var i = 0; i < graph.nodeCount(); i++) {
        final shiftedNode = graph.getNodeAtPosition(i);
        final unshiftedNode = unshiftedGraph.getNodeAtPosition(i);

        expect((shiftedNode.x - unshiftedNode.x - shiftX).abs() < 0.1, true);
        expect((shiftedNode.y - unshiftedNode.y - shiftY).abs() < 0.1, true);
      }
    });

    test('Balloon Performance for 1000 nodes to be less than 100ms', () {
      Graph createGraph(int n) {
        final graph = Graph();
        final nodes = List.generate(n, (i) => Node.Id(i + 1));
        var currentChild = 1;
        for (var i = 0; i < n && currentChild < n; i++) {
          final children = (i < n ~/ 3) ? 3 : 2;

          for (var j = 0; j < children && currentChild < n; j++) {
            graph.addEdge(nodes[i], nodes[currentChild]);
            currentChild++;
          }
        }
        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = const Size(itemWidth, itemHeight);
        }
        return graph;
      }

      final perfGraph = createGraph(1000);
      final perfAlgorithm = BalloonLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      final stopwatch = Stopwatch()..start();
      perfAlgorithm.run(perfGraph, 0, 0);
      final timeTaken = stopwatch.elapsed.inMilliseconds;

      print('BalloonLayout: $timeTaken ms for ${perfGraph.nodeCount()} nodes');

      expect(timeTaken < 100, true);
    });

    test('Balloon layout maintains node sizes', () {
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);

      graph.addEdge(node1, node2);

      final size1 = Size(120, 80);
      final size2 = Size(150, 90);

      node1.size = size1;
      node2.size = size2;

      algorithm.run(graph, 0, 0);

      // Node sizes should be preserved
      expect(node1.size, size1);
      expect(node2.size, size2);
    });
  });
}
