import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

const itemHeight = 100.0;
const itemWidth = 100.0;

void main() {
  group('FruchtermanReingold Graph', () {
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

    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3, paint: Paint()..color = Colors.red);
    graph.addEdge(node2, node4);
    graph.addEdge(node2, node5);
    graph.addEdge(node3, node6);
    graph.addEdge(node3, node7);
    graph.addEdge(node4, node8);
    graph.addEdge(node5, node9);
    graph.addEdge(node6, node10);

    test('FruchtermanReingold basic layout positions nodes', () {
      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 100
        ..shuffleNodes = false;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 2000, true);

      // Verify that all nodes have been positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.position.dx, isNot(equals(0.0)));
        expect(node.position.dy, isNot(equals(0.0)));
      }

      // Verify size is non-zero
      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('FruchtermanReingold for unconnected nodes', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(3), Node.Id(4));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 100
        ..shuffleNodes = false
        ..clusterPadding = 50;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      // All nodes should be positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.x >= 0, true);
        expect(node.y >= 0, true);
      }

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('FruchtermanReingold for a single edge', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(2));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      // Both nodes should be positioned
      expect(graph.getNodeUsingId(1).x >= 0, true);
      expect(graph.getNodeUsingId(2).x >= 0, true);

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('FruchtermanReingold with custom configuration', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));
      graph.addEdge(Node.Id(3), Node.Id(4));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 150
        ..repulsionRate = 0.3
        ..attractionRate = 0.2
        ..shuffleNodes = false;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var size = algorithm.run(graph, 0, 0);

      // All nodes should be positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.x >= 0, true);
        expect(node.y >= 0, true);
      }

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('FruchtermanReingold Performance for 500 nodes to be less than 3000ms',
        () {
      Graph _createGraph(int n) {
        final graph = Graph();
        final nodes = List.generate(n, (i) => Node.Id(i + 1));

        // Create a connected graph with random edges
        for (var i = 0; i < n; i++) {
          // Connect each node to the next one to ensure connectivity
          if (i < n - 1) {
            graph.addEdge(nodes[i], nodes[i + 1]);
          }
          // Add some additional connections
          if (i < n - 2) {
            graph.addEdge(nodes[i], nodes[i + 2]);
          }
        }

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = const Size(itemWidth, itemHeight);
        }
        return graph;
      }

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = true;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      var graph = _createGraph(500);

      var stopwatch = Stopwatch()..start();
      algorithm.run(graph, 0, 0);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      print('TimeTaken $timeTaken ms for ${graph.nodeCount()} nodes');

      expect(timeTaken < 3000, true);
    });

    test('FruchtermanReingold with null graph returns Size.zero', () {
      final configuration = FruchtermanReingoldConfiguration();
      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      var size = algorithm.run(null, 0, 0);

      expect(size, Size.zero);
    });

    test('FruchtermanReingold with empty graph returns Size.zero', () {
      final graph = Graph();
      final configuration = FruchtermanReingoldConfiguration();
      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      var size = algorithm.run(graph, 0, 0);

      expect(size, Size.zero);
    });

    test('FruchtermanReingold with single node', () {
      final graph = Graph();
      final node = Node.Id(1);
      graph.addNode(node);
      node.size = Size(itemWidth, itemHeight);

      final configuration = FruchtermanReingoldConfiguration()
        ..shuffleNodes = false;
      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      var size = algorithm.run(graph, 10, 10);

      // Single node should be positioned
      expect(node.x >= 0, true);
      expect(node.y >= 0, true);
      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('FruchtermanReingold with shift coordinates', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var shiftX = 100.0;
      var shiftY = 150.0;
      algorithm.run(graph, shiftX, shiftY);

      // All nodes should be shifted by the offset
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.x >= shiftX, true);
        expect(node.y >= shiftY, true);
      }
    });

    test('FruchtermanReingold with cyclic graph', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));
      graph.addEdge(Node.Id(3), Node.Id(4));
      graph.addEdge(Node.Id(4), Node.Id(1)); // Creates a cycle

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 100
        ..shuffleNodes = false;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      // All nodes should be positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.position.dx, isNot(equals(0.0)));
        expect(node.position.dy, isNot(equals(0.0)));
      }

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('FruchtermanReingold cluster handling for disconnected components', () {
      final graph = Graph();

      // First component
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));

      // Second component (disconnected)
      graph.addEdge(Node.Id(4), Node.Id(5));
      graph.addEdge(Node.Id(5), Node.Id(6));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 100
        ..shuffleNodes = false
        ..clusterPadding = 100;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var size = algorithm.run(graph, 10, 10);

      // All nodes should be positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.x >= 0, true);
        expect(node.y >= 0, true);
      }

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('FruchtermanReingold with setDimensions', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      // Set custom dimensions
      algorithm.setDimensions(1000, 1000);

      var size = algorithm.run(graph, 0, 0);

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('FruchtermanReingold renderer is initialized', () {
      final configuration = FruchtermanReingoldConfiguration();
      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      expect(algorithm.renderer, isNotNull);
      expect(algorithm.renderer, isA<ArrowEdgeRenderer>());
    });

    test('FruchtermanReingold with custom renderer', () {
      final configuration = FruchtermanReingoldConfiguration();
      final customRenderer = ArrowEdgeRenderer();
      var algorithm =
          FruchtermanReingoldAlgorithm(configuration, renderer: customRenderer);

      expect(algorithm.renderer, equals(customRenderer));
    });

    test('FruchtermanReingold with high repulsion rate', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));
      graph.addEdge(Node.Id(3), Node.Id(4));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 100
        ..repulsionRate = 0.8
        ..shuffleNodes = false;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var size = algorithm.run(graph, 0, 0);

      // All nodes should be positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.x >= 0, true);
        expect(node.y >= 0, true);
      }

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('FruchtermanReingold with low iteration count', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 10 // Very low iteration count
        ..shuffleNodes = false;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 0, 0);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 500, true);
      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('FruchtermanReingold nodes do not overlap after layout', () {
      final graph = Graph();

      // Create a simple star graph
      final center = Node.Id(1);
      for (var i = 2; i <= 6; i++) {
        graph.addEdge(center, Node.Id(i));
      }

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 200
        ..repulsionRate = 0.3
        ..shuffleNodes = false;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      algorithm.run(graph, 0, 0);

      // Check that nodes are positioned at different locations
      final positions = <String>{};
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        final posKey = '${node.x.toStringAsFixed(2)},${node.y.toStringAsFixed(2)}';
        expect(positions.contains(posKey), false,
            reason: 'Nodes should not have identical positions');
        positions.add(posKey);
      }
    });
  });

  group('FruchtermanReingold with Barnes-Hut', () {
    test('Barnes-Hut basic layout positions nodes correctly', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(1), Node.Id(3));
      graph.addEdge(Node.Id(2), Node.Id(4));
      graph.addEdge(Node.Id(2), Node.Id(5));
      graph.addEdge(Node.Id(3), Node.Id(6));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 100
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 2000, true);

      // Verify that all nodes have been positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.position.dx, isNot(equals(0.0)));
        expect(node.position.dy, isNot(equals(0.0)));
        expect(node.x >= 10, true);
        expect(node.y >= 10, true);
      }

      // Verify size is non-zero
      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Barnes-Hut for unconnected nodes', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(3), Node.Id(4));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 100
        ..shuffleNodes = false
        ..clusterPadding = 50
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      // All nodes should be positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.x >= 0, true);
        expect(node.y >= 0, true);
      }

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Barnes-Hut for a single edge', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(2));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      // Both nodes should be positioned
      expect(graph.getNodeUsingId(1).x >= 0, true);
      expect(graph.getNodeUsingId(2).x >= 0, true);

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Barnes-Hut with cyclic graph', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));
      graph.addEdge(Node.Id(3), Node.Id(4));
      graph.addEdge(Node.Id(4), Node.Id(1)); // Creates a cycle

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 100
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      // All nodes should be positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.position.dx, isNot(equals(0.0)));
        expect(node.position.dy, isNot(equals(0.0)));
      }

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Barnes-Hut nodes do not overlap after layout', () {
      final graph = Graph();

      // Create a simple star graph
      final center = Node.Id(1);
      for (var i = 2; i <= 8; i++) {
        graph.addEdge(center, Node.Id(i));
      }

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 200
        ..repulsionRate = 0.3
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      algorithm.run(graph, 0, 0);

      // Check that nodes are positioned at different locations
      final positions = <String>{};
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        final posKey = '${node.x.toStringAsFixed(2)},${node.y.toStringAsFixed(2)}';
        expect(positions.contains(posKey), false,
            reason: 'Nodes should not have identical positions');
        positions.add(posKey);
      }
    });

    test('Barnes-Hut with different theta values produces valid layouts', () {
      final thetaValues = [0.3, 0.5, 0.8];

      for (final theta in thetaValues) {
        final graph = Graph();
        graph.addEdge(Node.Id(1), Node.Id(2));
        graph.addEdge(Node.Id(2), Node.Id(3));
        graph.addEdge(Node.Id(3), Node.Id(4));
        graph.addEdge(Node.Id(4), Node.Id(5));

        final configuration = FruchtermanReingoldConfiguration()
          ..iterations = 100
          ..shuffleNodes = false
          ..useBarnesHut = true
          ..theta = theta;

        var algorithm = FruchtermanReingoldAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var size = algorithm.run(graph, 0, 0);

        // All nodes should be positioned
        for (var i = 0; i < graph.nodeCount(); i++) {
          final node = graph.getNodeAtPosition(i);
          expect(node.x >= 0, true,
              reason: 'Node ${i} should have valid x position with theta=$theta');
          expect(node.y >= 0, true,
              reason: 'Node ${i} should have valid y position with theta=$theta');
        }

        expect(size.width > 0, true,
            reason: 'Size width should be positive with theta=$theta');
        expect(size.height > 0, true,
            reason: 'Size height should be positive with theta=$theta');
      }
    });

    test('Barnes-Hut with custom configuration', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));
      graph.addEdge(Node.Id(3), Node.Id(4));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 150
        ..repulsionRate = 0.3
        ..attractionRate = 0.2
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.6;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var size = algorithm.run(graph, 0, 0);

      // All nodes should be positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.x >= 0, true);
        expect(node.y >= 0, true);
      }

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Barnes-Hut cluster handling for disconnected components', () {
      final graph = Graph();

      // First component
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));

      // Second component (disconnected)
      graph.addEdge(Node.Id(4), Node.Id(5));
      graph.addEdge(Node.Id(5), Node.Id(6));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 100
        ..shuffleNodes = false
        ..clusterPadding = 100
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var size = algorithm.run(graph, 10, 10);

      // All nodes should be positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.x >= 0, true);
        expect(node.y >= 0, true);
      }

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Barnes-Hut with shift coordinates', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var shiftX = 100.0;
      var shiftY = 150.0;
      algorithm.run(graph, shiftX, shiftY);

      // All nodes should be shifted by the offset
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.x >= shiftX, true);
        expect(node.y >= shiftY, true);
      }
    });

    test('Barnes-Hut with single node', () {
      final graph = Graph();
      final node = Node.Id(1);
      graph.addNode(node);
      node.size = Size(itemWidth, itemHeight);

      final configuration = FruchtermanReingoldConfiguration()
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      var size = algorithm.run(graph, 10, 10);

      // Single node should be positioned
      expect(node.x >= 0, true);
      expect(node.y >= 0, true);
      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Barnes-Hut produces valid layout size for medium graph', () {
      final graph = Graph();
      final nodes = List.generate(50, (i) => Node.Id(i + 1));

      // Create a connected graph
      for (var i = 0; i < 49; i++) {
        graph.addEdge(nodes[i], nodes[i + 1]);
        if (i < 47) {
          graph.addEdge(nodes[i], nodes[i + 2]);
        }
      }

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = const Size(itemWidth, itemHeight);
      }

      final configuration = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithm = FruchtermanReingoldAlgorithm(configuration);

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 0, 0);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1500, true);

      // Verify all nodes are positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.x >= 0, true);
        expect(node.y >= 0, true);
      }

      // Verify size is valid
      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });
  });
}
