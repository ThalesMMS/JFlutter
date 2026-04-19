import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

const itemHeight = 100.0;
const itemWidth = 100.0;

void main() {
  group('TidierTree Graph', () {
    final graph = Graph();
    final node1 = Node.Id(1);
    final node2 = Node.Id(2);
    final node3 = Node.Id(3);
    final node4 = Node.Id(4);
    final node5 = Node.Id(5);
    final node6 = Node.Id(6);
    final node8 = Node.Id(7);
    final node7 = Node.Id(8);
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

    test('TidierTree Node positions are correct for Top_Bottom', () {
      final _configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150)
        ..subtreeSeparation = (150)
        ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

      var algorithm = TidierTreeLayoutAlgorithm(
          _configuration, TreeEdgeRenderer(_configuration));

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      expect(graph.getNodeAtPosition(0).position, Offset(510.0, 160.0));
      expect(graph.getNodeAtPosition(6).position, Offset(260.0, 1060.0));
      expect(graph.getNodeUsingId(3).position, Offset(510.0, 460.0));
      expect(graph.getNodeUsingId(4).position, Offset(760.0, 460.0));

      expect(size, Size(900.0, 1000.0));
    });

    test('TidierTree handles cyclic dependencies', () {
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
        ..levelSeparation = (150)
        ..subtreeSeparation = (150)
        ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

      var algorithm = TidierTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      // TidierTree should handle cycles by creating a spanning tree
      // It should not throw an exception
      expect(
        () {
          algorithm.run(cyclicGraph, 0, 0);
        },
        returnsNormally,
      );

      // Verify that all nodes have positions assigned
      for (var i = 0; i < cyclicGraph.nodeCount(); i++) {
        final node = cyclicGraph.getNodeAtPosition(i);
        expect(node.position, isNot(Offset.zero));
      }
    });

    test('TidierTree normalizes rooted graphs with cycles and shared parents',
        () {
      final rootedGraph = Graph();
      final root = Node.Id('root');
      final nodeA = Node.Id('A');
      final nodeB = Node.Id('B');
      final nodeC = Node.Id('C');
      final secondRoot = Node.Id('secondRoot');
      final nodeD = Node.Id('D');
      final isolated = Node.Id('isolated');

      rootedGraph.addEdge(root, nodeA);
      rootedGraph.addEdge(nodeA, nodeB);
      rootedGraph.addEdge(nodeB, nodeC);
      rootedGraph.addEdge(nodeC, nodeA);
      rootedGraph.addEdge(root, nodeC);
      rootedGraph.addEdge(secondRoot, nodeD);
      rootedGraph.addNode(isolated);

      for (var i = 0; i < rootedGraph.nodeCount(); i++) {
        rootedGraph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150)
        ..subtreeSeparation = (150)
        ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

      final algorithm = TidierTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      expect(
        () {
          algorithm.run(rootedGraph, 0, 0);
        },
        returnsNormally,
      );

      for (var i = 0; i < rootedGraph.nodeCount(); i++) {
        final position = rootedGraph.getNodeAtPosition(i).position;
        expect(position.dx.isFinite, true);
        expect(position.dy.isFinite, true);
        expect(position, isNot(Offset.zero));
      }
    });

    test('TidierTree spanning forest preserves directed roots', () {
      final directedGraph = Graph();
      final root = Node.Id('root');
      final child = Node.Id('child');
      final grandchild = Node.Id('grandchild');

      directedGraph.addEdge(child, grandchild);
      directedGraph.addEdge(root, child);

      for (var i = 0; i < directedGraph.nodeCount(); i++) {
        directedGraph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150)
        ..subtreeSeparation = (150)
        ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
      final algorithm = TidierTreeLayoutAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

      algorithm.run(directedGraph, 0, 0);

      expect(
        algorithm.tree
            .getOutEdges(root)
            .any((edge) => edge.destination == child),
        true,
      );
      expect(
        algorithm.tree
            .getOutEdges(child)
            .any((edge) => edge.destination == root),
        false,
      );
    });

    test('TidierTree Performance for 1000 nodes to be less than 40ms', () {
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

      final _configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150)
        ..subtreeSeparation = (150)
        ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

      var algorithm = TidierTreeLayoutAlgorithm(
          _configuration, TreeEdgeRenderer(_configuration));

      var graph = _createGraph(1000);
      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      algorithm.run(graph, 0, 0);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Timetaken $timeTaken for ${graph.nodeCount()} nodes');

      expect(timeTaken < 40, true);
    });
  });
}
