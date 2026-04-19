import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

const itemHeight = 100.0;
const itemWidth = 100.0;

void main() {
  group('CircleLayoutAlgorithm', () {
    test('CircleLayout positions nodes in a circle', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);
      final node5 = Node.Id(5);
      final node6 = Node.Id(6);

      graph.addEdge(node1, node2);
      graph.addEdge(node2, node3);
      graph.addEdge(node3, node4);
      graph.addEdge(node4, node5);
      graph.addEdge(node5, node6);
      graph.addEdge(node6, node1);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = CircleLayoutConfiguration(
        radius: 200.0,
        reduceEdgeCrossing: false,
      );

      var algorithm = CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer());

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 0, 0);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      // Verify size is reasonable
      expect(size.width > 0, true);
      expect(size.height > 0, true);

      // Verify all nodes have positions
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.position, isNotNull);
      }

      // Verify nodes are arranged in a circle by checking distances from center
      // Calculate the actual center from node positions
      var sumX = 0.0;
      var sumY = 0.0;
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        sumX += node.x;
        sumY += node.y;
      }
      final centerX = sumX / graph.nodeCount();
      final centerY = sumY / graph.nodeCount();

      final distances = <double>[];
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        final dx = node.x - centerX;
        final dy = node.y - centerY;
        final distance = sqrt(dx * dx + dy * dy);
        distances.add(distance);
      }

      // All distances should be similar (within a reasonable threshold)
      final avgDistance = distances.reduce((a, b) => a + b) / distances.length;
      for (final distance in distances) {
        expect((distance - avgDistance).abs() < 5, true,
            reason: 'All nodes should be equidistant from center');
      }
    });

    test('CircleLayout handles single node correctly', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      graph.addNode(node1);

      node1.size = Size(itemWidth, itemHeight);

      final configuration = CircleLayoutConfiguration();
      var algorithm = CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer());

      var size = algorithm.run(graph, 10, 10);

      // Single node case returns fixed size
      expect(size, Size(200, 200));
      expect(node1.position, Offset(110, 110));
    });

    test('CircleLayout handles empty graph', () {
      final graph = Graph();

      final configuration = CircleLayoutConfiguration();
      var algorithm = CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer());

      var size = algorithm.run(graph, 0, 0);

      expect(size, Size.zero);
    });

    test('CircleLayout with custom radius', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      graph.addEdge(node1, node2);
      graph.addEdge(node2, node3);
      graph.addEdge(node3, node4);
      graph.addEdge(node4, node1);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final customRadius = 300.0;
      final configuration = CircleLayoutConfiguration(
        radius: customRadius,
        reduceEdgeCrossing: false,
      );

      var algorithm = CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer());
      algorithm.run(graph, 0, 0);

      // Verify nodes are positioned at approximately the custom radius
      final centerX = 200.0; // Default width / 2
      final centerY = 200.0; // Default height / 2

      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        final dx = node.x - centerX;
        final dy = node.y - centerY;
        final distance = sqrt(dx * dx + dy * dy);

        // Distance should be close to custom radius
        expect((distance - customRadius).abs() < 10, true,
            reason: 'Node should be at custom radius distance');
      }
    });

    test('CircleLayout with edge crossing reduction enabled', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);
      final node5 = Node.Id(5);
      final node6 = Node.Id(6);

      // Create a graph that would have crossings if not optimized
      graph.addEdge(node1, node4);
      graph.addEdge(node2, node5);
      graph.addEdge(node3, node6);
      graph.addEdge(node4, node1);
      graph.addEdge(node5, node2);
      graph.addEdge(node6, node3);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = CircleLayoutConfiguration(
        radius: 200.0,
        reduceEdgeCrossing: true,
      );

      var algorithm = CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer());

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 0, 0);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);
      expect(size.width > 0, true);
      expect(size.height > 0, true);

      // Verify all nodes have positions
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.position, isNotNull);
      }
    });

    test('CircleLayout with edge crossing reduction disabled for large graphs',
        () {
      final graph = Graph();
      final nodes = List.generate(250, (i) => Node.Id(i + 1));

      // Add some edges
      for (var i = 0; i < nodes.length - 1; i++) {
        graph.addEdge(nodes[i], nodes[i + 1]);
      }

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = CircleLayoutConfiguration(
        radius: 300.0,
        reduceEdgeCrossing: true,
        reduceEdgeCrossingMaxEdges: 200, // Should skip optimization
      );

      var algorithm = CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer());

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 0, 0);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      // Should be fast since optimization is skipped
      expect(timeTaken < 1000, true);
      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('CircleLayout handles disconnected components', () {
      final graph = Graph();

      // First component
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);

      graph.addEdge(node1, node2);
      graph.addEdge(node2, node3);

      // Second component (disconnected)
      final node4 = Node.Id(4);
      final node5 = Node.Id(5);

      graph.addEdge(node4, node5);

      // Isolated node
      final node6 = Node.Id(6);
      graph.addNode(node6);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = CircleLayoutConfiguration(
        radius: 200.0,
        reduceEdgeCrossing: true,
      );

      var algorithm = CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer());
      var size = algorithm.run(graph, 0, 0);

      expect(size.width > 0, true);
      expect(size.height > 0, true);

      // Verify all nodes have positions
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.position, isNotNull);
      }
    });

    test('CircleLayout with shift coordinates', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);

      graph.addEdge(node1, node2);
      graph.addEdge(node2, node3);
      graph.addEdge(node3, node1);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = CircleLayoutConfiguration(
        radius: 150.0,
        reduceEdgeCrossing: false,
      );

      var algorithm = CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer());

      final shiftX = 100.0;
      final shiftY = 50.0;

      algorithm.run(graph, shiftX, shiftY);

      // Verify all nodes are shifted by the specified amounts
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.x >= shiftX, true,
            reason: 'Node X should be shifted by at least shiftX');
        expect(node.y >= shiftY, true,
            reason: 'Node Y should be shifted by at least shiftY');
      }
    });

    test('CircleLayout Performance for 1000 nodes to be less than 100ms', () {
      final graph = Graph();
      final nodes = List.generate(1000, (i) => Node.Id(i + 1));

      // Add edges to create a large graph
      for (var i = 0; i < nodes.length - 1; i++) {
        graph.addEdge(nodes[i], nodes[i + 1]);
      }
      // Connect last to first
      graph.addEdge(nodes[nodes.length - 1], nodes[0]);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = CircleLayoutConfiguration(
        radius: 500.0,
        reduceEdgeCrossing: false, // Disable to ensure fast performance
      );

      var algorithm = CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer());

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 0, 0);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Timetaken $timeTaken for ${graph.nodeCount()} nodes');

      expect(timeTaken < 100, true);
      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('CircleLayout with auto-calculated radius', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      graph.addEdge(node1, node2);
      graph.addEdge(node2, node3);
      graph.addEdge(node3, node4);
      graph.addEdge(node4, node1);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = CircleLayoutConfiguration(
        radius: 0.0, // Auto-calculate
        reduceEdgeCrossing: false,
      );

      var algorithm = CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer());
      var size = algorithm.run(graph, 0, 0);

      expect(size.width > 0, true);
      expect(size.height > 0, true);

      // Verify nodes are positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.position, isNotNull);
      }
    });

    test('CircleLayout auto radius does not persist between repeated runs', () {
      final graph = Graph();
      final nodes = List.generate(4, (i) => Node.Id(i + 1));
      for (var i = 0; i < nodes.length; i++) {
        graph.addEdge(nodes[i], nodes[(i + 1) % nodes.length]);
        nodes[i].size = Size(itemWidth, itemHeight);
      }

      final algorithm = CircleLayoutAlgorithm(
          CircleLayoutConfiguration(), ArrowEdgeRenderer());

      algorithm.run(graph, 0, 0);
      final firstDistance = (nodes.first.position - Offset(200, 200)).distance;

      final node5 = Node.Id(5)..size = Size(itemWidth, itemHeight);
      nodes.add(node5);
      graph.addEdge(nodes[3], node5);
      algorithm.run(graph, 0, 0);
      final secondDistance = (nodes.first.position - Offset(200, 200)).distance;

      expect(secondDistance, closeTo(firstDistance, 0.01));
    });

    test('CircleLayout auto radius uses configured dimensions', () {
      final graph = Graph();
      final nodes = List.generate(4, (i) => Node.Id(i + 1));
      for (var i = 0; i < nodes.length; i++) {
        graph.addEdge(nodes[i], nodes[(i + 1) % nodes.length]);
        nodes[i].size = Size(itemWidth, itemHeight);
      }

      final algorithm = CircleLayoutAlgorithm(
          CircleLayoutConfiguration(reduceEdgeCrossing: false),
          ArrowEdgeRenderer());
      algorithm.setDimensions(800, 600);
      algorithm.run(graph, 0, 0);

      final center = const Offset(400, 300);
      expect((nodes.first.position - center).distance, closeTo(280, 0.01));
    });

    test('CircleLayout crossing reduction is deterministic', () {
      Graph createGraph() {
        final graph = Graph();
        final nodes = List.generate(6, (i) => Node.Id(i + 1));
        graph.addEdge(nodes[0], nodes[3]);
        graph.addEdge(nodes[1], nodes[4]);
        graph.addEdge(nodes[2], nodes[5]);
        graph.addEdge(nodes[3], nodes[0]);
        graph.addEdge(nodes[4], nodes[1]);
        graph.addEdge(nodes[5], nodes[2]);
        for (final node in nodes) {
          node.size = Size(itemWidth, itemHeight);
        }
        return graph;
      }

      final firstGraph = createGraph();
      final secondGraph = createGraph();
      final configuration = CircleLayoutConfiguration(
        radius: 200,
        reduceEdgeCrossing: true,
      );

      CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer())
          .run(firstGraph, 0, 0);
      CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer())
          .run(secondGraph, 0, 0);

      for (var i = 0; i < firstGraph.nodeCount(); i++) {
        expect(
          firstGraph.getNodeAtPosition(i).position,
          secondGraph.getNodeAtPosition(i).position,
        );
      }
    });

    test('CircleLayout with TreeEdgeRenderer', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);

      graph.addEdge(node1, node2);
      graph.addEdge(node2, node3);
      graph.addEdge(node3, node1);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = CircleLayoutConfiguration(
        radius: 200.0,
      );

      final treeConfig = BuchheimWalkerConfiguration();
      var algorithm =
          CircleLayoutAlgorithm(configuration, TreeEdgeRenderer(treeConfig));

      var size = algorithm.run(graph, 0, 0);

      expect(size.width > 0, true);
      expect(size.height > 0, true);
      expect(algorithm.renderer, isA<TreeEdgeRenderer>());
    });

    test('CircleLayout nodes are evenly spaced by angle', () {
      final graph = Graph();
      final nodeCount = 8;
      final nodes = List.generate(nodeCount, (i) => Node.Id(i + 1));

      // Create a ring
      for (var i = 0; i < nodeCount; i++) {
        graph.addEdge(nodes[i], nodes[(i + 1) % nodeCount]);
      }

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configuration = CircleLayoutConfiguration(
        radius: 250.0,
        reduceEdgeCrossing: false,
      );

      var algorithm = CircleLayoutAlgorithm(configuration, ArrowEdgeRenderer());
      algorithm.run(graph, 0, 0);

      final centerX = 200.0;
      final centerY = 200.0;

      // Calculate angles for each node
      final angles = <double>[];
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        final dx = node.x - centerX;
        final dy = node.y - centerY;
        final angle = atan2(dy, dx);
        angles.add(angle);
      }

      // Sort angles to check spacing
      angles.sort();

      // Check that angles are roughly evenly spaced
      final expectedAngleDiff = 2 * pi / nodeCount;
      for (var i = 0; i < angles.length - 1; i++) {
        final actualDiff = angles[i + 1] - angles[i];
        expect((actualDiff - expectedAngleDiff).abs() < 0.2, true,
            reason: 'Nodes should be evenly spaced by angle');
      }
    });
  });
}
