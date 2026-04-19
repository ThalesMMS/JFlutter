import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

const itemHeight = 100.0;
const itemWidth = 100.0;

void main() {
  group('RadialTreeLayout Graph', () {
    final graph = Graph();
    final node1 = Node.Id(1);
    final node2 = Node.Id(2);
    final node3 = Node.Id(3);
    final node4 = Node.Id(4);
    final node5 = Node.Id(5);
    final node6 = Node.Id(6);
    final node7 = Node.Id(7);
    final node8 = Node.Id(8);
    final node9 = Node.Id(9);
    final node10 = Node.Id(10);
    final node11 = Node.Id(11);
    final node12 = Node.Id(12);

    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3, paint: Paint()..color = Colors.red);
    graph.addEdge(node1, node4, paint: Paint()..color = Colors.blue);
    graph.addEdge(node2, node5);
    graph.addEdge(node2, node6);
    graph.addEdge(node6, node7, paint: Paint()..color = Colors.red);
    graph.addEdge(node6, node8, paint: Paint()..color = Colors.red);
    graph.addEdge(node4, node9);
    graph.addEdge(node4, node10, paint: Paint()..color = Colors.black);
    graph.addEdge(node4, node11, paint: Paint()..color = Colors.red);
    graph.addEdge(node11, node12);

    test('RadialTreeLayout Node positions are calculated correctly', () {
      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150)
        ..subtreeSeparation = (150)
        ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

      var algorithm = RadialTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      // Verify that nodes have been positioned (not at origin)
      expect(graph.getNodeAtPosition(0).position, isNot(Offset.zero));
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));

      // Verify all nodes have been positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.position.dx, isNot(equals(0.0)));
        expect(node.position.dy, isNot(equals(0.0)));
      }
    });

    test('RadialTreeLayout handles single node correctly', () {
      final singleNodeGraph = Graph();
      final singleNode = Node.Id(1);
      singleNodeGraph.addNode(singleNode);
      singleNode.size = Size(itemWidth, itemHeight);

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150);

      var algorithm = RadialTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      var size = algorithm.run(singleNodeGraph, 10, 10);

      // Single node should be positioned with offset
      expect(singleNode.position, Offset(110.0, 110.0));
      expect(size, Size(200, 200));
    });

    test('RadialTreeLayout handles empty graph', () {
      final emptyGraph = Graph();

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150);

      var algorithm = RadialTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      var size = algorithm.run(emptyGraph, 0, 0);

      expect(size, Size.zero);
    });

    test('RadialTreeLayout includes isolated nodes in multi-node graphs', () {
      final disconnectedGraph = Graph();
      final root = Node.Id('root');
      final child = Node.Id('child');
      final isolated = Node.Id('isolated');

      disconnectedGraph.addEdge(root, child);
      disconnectedGraph.addNode(isolated);

      for (final node in disconnectedGraph.nodes) {
        node.size = Size(itemWidth, itemHeight);
      }

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150);
      final algorithm = RadialTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      algorithm.run(disconnectedGraph, 10, 10);

      expect(isolated.position.dx.isFinite, true);
      expect(isolated.position.dy.isFinite, true);
      expect(isolated.position, isNot(Offset.zero));
    });

    test('RadialTreeLayout spans every rootless component', () {
      final disconnectedCycles = Graph();
      final nodeA = Node.Id('A');
      final nodeB = Node.Id('B');
      final nodeC = Node.Id('C');
      final nodeD = Node.Id('D');

      disconnectedCycles.addEdge(nodeA, nodeB);
      disconnectedCycles.addEdge(nodeB, nodeA);
      disconnectedCycles.addEdge(nodeC, nodeD);
      disconnectedCycles.addEdge(nodeD, nodeC);

      for (var i = 0; i < disconnectedCycles.nodeCount(); i++) {
        disconnectedCycles.getNodeAtPosition(i).size =
            Size(itemWidth, itemHeight);
      }

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150);
      final algorithm = RadialTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      final size = algorithm.run(disconnectedCycles, 0, 0);

      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
      for (final node in disconnectedCycles.nodes) {
        expect(node.position.dx.isFinite, true);
        expect(node.position.dy.isFinite, true);
        expect(node.position, isNot(Offset.zero));
      }
    });

    test('RadialTreeLayout converts to polar coordinates correctly', () {
      final simpleGraph = Graph();
      final root = Node.Id('root');
      final child1 = Node.Id('child1');
      final child2 = Node.Id('child2');
      final child3 = Node.Id('child3');

      simpleGraph.addEdge(root, child1);
      simpleGraph.addEdge(root, child2);
      simpleGraph.addEdge(root, child3);

      for (var i = 0; i < simpleGraph.nodeCount(); i++) {
        simpleGraph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150);

      var algorithm = RadialTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      var size = algorithm.run(simpleGraph, 0, 0);

      // Verify nodes are arranged in radial pattern
      // Children should be distributed around the root
      final rootPos = root.position;
      final child1Pos = child1.position;
      final child2Pos = child2.position;
      final child3Pos = child3.position;

      // Calculate distances from root
      final dist1 = (child1Pos - rootPos).distance;
      final dist2 = (child2Pos - rootPos).distance;
      final dist3 = (child3Pos - rootPos).distance;

      // All children should be roughly equidistant from root (radial layout)
      expect((dist1 - dist2).abs(), lessThan(50));
      expect((dist2 - dist3).abs(), lessThan(50));

      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('RadialTreeLayout handles cyclic graphs with spanning tree', () {
      // Create a graph with a cycle
      final cyclicGraph = Graph();
      final nodeA = Node.Id('A');
      final nodeB = Node.Id('B');
      final nodeC = Node.Id('C');

      // Create cycle: A -> B -> C -> A
      cyclicGraph.addEdge(nodeA, nodeB);
      cyclicGraph.addEdge(nodeB, nodeC);
      cyclicGraph.addEdge(nodeC, nodeA); // This creates the cycle

      for (var i = 0; i < cyclicGraph.nodeCount(); i++) {
        cyclicGraph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150);

      var algorithm = RadialTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      // Should handle cycle by creating spanning tree
      var size = algorithm.run(cyclicGraph, 0, 0);

      // Verify that all nodes have been positioned
      expect(nodeA.position, isNot(Offset.zero));
      expect(nodeB.position, isNot(Offset.zero));
      expect(nodeC.position, isNot(Offset.zero));
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('RadialTreeLayout handles multiple roots', () {
      final multiRootGraph = Graph();
      final root1 = Node.Id('root1');
      final root2 = Node.Id('root2');
      final child1 = Node.Id('child1');
      final child2 = Node.Id('child2');

      // Two separate trees
      multiRootGraph.addEdge(root1, child1);
      multiRootGraph.addEdge(root2, child2);

      for (var i = 0; i < multiRootGraph.nodeCount(); i++) {
        multiRootGraph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150);

      var algorithm = RadialTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      var size = algorithm.run(multiRootGraph, 0, 0);

      // Both roots and their children should be positioned
      expect(root1.position, isNot(Offset.zero));
      expect(root2.position, isNot(Offset.zero));
      expect(child1.position, isNot(Offset.zero));
      expect(child2.position, isNot(Offset.zero));
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('RadialTreeLayout performance for 1000 nodes to be less than 100ms',
        () {
      Graph _createGraph(int n) {
        final graph = Graph();
        final nodes = List.generate(n, (i) => Node.Id(i + 1));
        var currentChild = 1; // Start from node 1 (node 0 is root)
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

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150);

      var algorithm = RadialTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      var graph = _createGraph(1000);
      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      algorithm.run(graph, 0, 0);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Timetaken $timeTaken for ${graph.nodeCount()} nodes');

      expect(timeTaken < 100, true);
    });

    test('RadialTreeLayout applies shift correctly', () {
      final simpleGraph = Graph();
      final root = Node.Id('root');
      final child = Node.Id('child');

      simpleGraph.addEdge(root, child);
      root.size = Size(itemWidth, itemHeight);
      child.size = Size(itemWidth, itemHeight);

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150);

      var algorithm = RadialTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      final shiftX = 50.0;
      final shiftY = 75.0;

      algorithm.run(simpleGraph, shiftX, shiftY);

      // Both nodes should have shift applied
      expect(root.position.dx, greaterThanOrEqualTo(shiftX));
      expect(root.position.dy, greaterThanOrEqualTo(shiftY));
      expect(child.position.dx, greaterThanOrEqualTo(shiftX));
      expect(child.position.dy, greaterThanOrEqualTo(shiftY));
    });

    test('RadialTreeLayout handles deep tree structure', () {
      final deepGraph = Graph();
      final nodes = List.generate(10, (i) => Node.Id(i));

      // Create a linear chain (deep tree)
      for (var i = 0; i < 9; i++) {
        deepGraph.addEdge(nodes[i], nodes[i + 1]);
      }

      for (var i = 0; i < deepGraph.nodeCount(); i++) {
        deepGraph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150);

      var algorithm = RadialTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      var size = algorithm.run(deepGraph, 0, 0);

      // All nodes should be positioned
      for (var node in nodes) {
        expect(node.position, isNot(Offset.zero));
      }

      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('RadialTreeLayout respects node sizes', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);

      graph.addEdge(node1, node2);

      node1.size = Size(itemWidth, itemHeight);
      node2.size = Size(itemWidth * 2, itemHeight * 2);

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150);

      var algorithm = RadialTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      algorithm.run(graph, 0, 0);

      // Verify nodes maintain their sizes
      expect(node1.width, itemWidth);
      expect(node1.height, itemHeight);
      expect(node2.width, itemWidth * 2);
      expect(node2.height, itemHeight * 2);
    });
  });
}
