import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

const itemHeight = 100.0;
const itemWidth = 100.0;

void main() {
  group('Barnes-Hut Performance Comparison', () {
    test('Performance comparison for 100 nodes', () {
      final graph = _createGraph(100);

      // Test naive implementation
      final configNaive = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false
        ..useBarnesHut = false;

      var algorithmNaive = FruchtermanReingoldAlgorithm(configNaive);

      final stopwatchNaive = Stopwatch()..start();
      algorithmNaive.run(graph, 0, 0);
      stopwatchNaive.stop();
      final naiveTime = stopwatchNaive.elapsedMilliseconds;

      // Test Barnes-Hut implementation
      final graph2 = _createGraph(100);
      final configBarnesHut = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithmBarnesHut = FruchtermanReingoldAlgorithm(configBarnesHut);

      final stopwatchBarnesHut = Stopwatch()..start();
      algorithmBarnesHut.run(graph2, 0, 0);
      stopwatchBarnesHut.stop();
      final barnesHutTime = stopwatchBarnesHut.elapsedMilliseconds;

      print('100 nodes - Naive: ${naiveTime}ms, Barnes-Hut: ${barnesHutTime}ms');

      // Both should complete in reasonable time
      expect(naiveTime < 2000, true);
      expect(barnesHutTime < 2000, true);

      // Verify both layouts positioned all nodes
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node1 = graph.getNodeAtPosition(i);
        final node2 = graph2.getNodeAtPosition(i);
        expect(node1.x >= 0, true);
        expect(node1.y >= 0, true);
        expect(node2.x >= 0, true);
        expect(node2.y >= 0, true);
      }
    });

    test('Performance comparison for 500 nodes - Barnes-Hut should be faster',
        () {
      final graph = _createGraph(500);

      // Test naive implementation
      final configNaive = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false
        ..useBarnesHut = false;

      var algorithmNaive = FruchtermanReingoldAlgorithm(configNaive);

      final stopwatchNaive = Stopwatch()..start();
      algorithmNaive.run(graph, 0, 0);
      stopwatchNaive.stop();
      final naiveTime = stopwatchNaive.elapsedMilliseconds;

      // Test Barnes-Hut implementation
      final graph2 = _createGraph(500);
      final configBarnesHut = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithmBarnesHut = FruchtermanReingoldAlgorithm(configBarnesHut);

      final stopwatchBarnesHut = Stopwatch()..start();
      algorithmBarnesHut.run(graph2, 0, 0);
      stopwatchBarnesHut.stop();
      final barnesHutTime = stopwatchBarnesHut.elapsedMilliseconds;

      print(
          '500 nodes - Naive: ${naiveTime}ms, Barnes-Hut: ${barnesHutTime}ms, Speedup: ${(naiveTime / barnesHutTime).toStringAsFixed(2)}x');

      // Barnes-Hut should be faster for 500 nodes
      expect(barnesHutTime < naiveTime, true,
          reason:
              'Barnes-Hut should be faster than naive for 500 nodes. Naive: ${naiveTime}ms, Barnes-Hut: ${barnesHutTime}ms');

      // Both should complete in reasonable time
      expect(naiveTime < 5000, true);
      expect(barnesHutTime < 3000, true);

      // Verify both layouts positioned all nodes
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node1 = graph.getNodeAtPosition(i);
        final node2 = graph2.getNodeAtPosition(i);
        expect(node1.x >= 0, true);
        expect(node1.y >= 0, true);
        expect(node2.x >= 0, true);
        expect(node2.y >= 0, true);
      }
    });

    test('Performance comparison for 1000 nodes - Barnes-Hut should be much faster',
        () {
      final graph = _createGraph(1000);

      // Test naive implementation
      final configNaive = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false
        ..useBarnesHut = false;

      var algorithmNaive = FruchtermanReingoldAlgorithm(configNaive);

      final stopwatchNaive = Stopwatch()..start();
      algorithmNaive.run(graph, 0, 0);
      stopwatchNaive.stop();
      final naiveTime = stopwatchNaive.elapsedMilliseconds;

      // Test Barnes-Hut implementation
      final graph2 = _createGraph(1000);
      final configBarnesHut = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithmBarnesHut = FruchtermanReingoldAlgorithm(configBarnesHut);

      final stopwatchBarnesHut = Stopwatch()..start();
      algorithmBarnesHut.run(graph2, 0, 0);
      stopwatchBarnesHut.stop();
      final barnesHutTime = stopwatchBarnesHut.elapsedMilliseconds;

      print(
          '1000 nodes - Naive: ${naiveTime}ms, Barnes-Hut: ${barnesHutTime}ms, Speedup: ${(naiveTime / barnesHutTime).toStringAsFixed(2)}x');

      // Barnes-Hut should be significantly faster for 1000 nodes
      expect(barnesHutTime < naiveTime, true,
          reason:
              'Barnes-Hut should be faster than naive for 1000 nodes. Naive: ${naiveTime}ms, Barnes-Hut: ${barnesHutTime}ms');

      // Barnes-Hut should complete in reasonable time
      expect(barnesHutTime < 5000, true,
          reason: 'Barnes-Hut should complete in under 5000ms for 1000 nodes');

      // Verify both layouts positioned all nodes
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node1 = graph.getNodeAtPosition(i);
        final node2 = graph2.getNodeAtPosition(i);
        expect(node1.x >= 0, true);
        expect(node1.y >= 0, true);
        expect(node2.x >= 0, true);
        expect(node2.y >= 0, true);
      }
    });

    test('Barnes-Hut with different theta values', () {
      final thetaValues = [0.3, 0.5, 0.8];
      final graph = _createGraph(500);

      for (final theta in thetaValues) {
        final config = FruchtermanReingoldConfiguration()
          ..iterations = 50
          ..shuffleNodes = false
          ..useBarnesHut = true
          ..theta = theta;

        var algorithm = FruchtermanReingoldAlgorithm(config);

        final stopwatch = Stopwatch()..start();
        algorithm.run(graph, 0, 0);
        stopwatch.stop();

        print('Theta ${theta}: ${stopwatch.elapsedMilliseconds}ms');

        // All theta values should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds < 3000, true);

        // Verify all nodes are positioned
        for (var i = 0; i < graph.nodeCount(); i++) {
          final node = graph.getNodeAtPosition(i);
          expect(node.x >= 0, true);
          expect(node.y >= 0, true);
        }
      }
    });

    test('Barnes-Hut layout quality verification', () {
      final graph = _createGraph(200);

      // Run both algorithms with same initial conditions
      final configNaive = FruchtermanReingoldConfiguration()
        ..iterations = 100
        ..shuffleNodes = false
        ..useBarnesHut = false;

      final configBarnesHut = FruchtermanReingoldConfiguration()
        ..iterations = 100
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithmNaive = FruchtermanReingoldAlgorithm(configNaive);
      var algorithmBarnesHut = FruchtermanReingoldAlgorithm(configBarnesHut);

      final sizeNaive = algorithmNaive.run(graph, 0, 0);
      final graph2 = _createGraph(200);
      final sizeBarnesHut = algorithmBarnesHut.run(graph2, 0, 0);

      // Both should produce valid layouts
      expect(sizeNaive.width > 0, true);
      expect(sizeNaive.height > 0, true);
      expect(sizeBarnesHut.width > 0, true);
      expect(sizeBarnesHut.height > 0, true);

      // Calculate average node spacing for both layouts
      var naiveSpacing = 0.0;
      var barnesHutSpacing = 0.0;
      var edgeCount = 0;

      for (final edge in graph.edges) {
        final source1 = edge.source;
        final dest1 = edge.destination;
        final delta1 = source1.position - dest1.position;
        naiveSpacing += delta1.distance;
        edgeCount++;
      }

      for (final edge in graph2.edges) {
        final source2 = edge.source;
        final dest2 = edge.destination;
        final delta2 = source2.position - dest2.position;
        barnesHutSpacing += delta2.distance;
      }

      naiveSpacing /= edgeCount;
      barnesHutSpacing /= edgeCount;

      print(
          'Average edge length - Naive: ${naiveSpacing.toStringAsFixed(2)}, Barnes-Hut: ${barnesHutSpacing.toStringAsFixed(2)}');

      // Layouts should have similar characteristics (within 50% of each other)
      final ratio = barnesHutSpacing / naiveSpacing;
      expect(ratio > 0.5 && ratio < 2.0, true,
          reason:
              'Layout quality should be similar. Ratio: ${ratio.toStringAsFixed(2)}');
    });

    test('Barnes-Hut with unconnected components', () {
      final graph = Graph();

      // Create two separate components
      final nodes1 = List.generate(50, (i) => Node.Id(i + 1));
      final nodes2 = List.generate(50, (i) => Node.Id(i + 51));

      // Connect first component
      for (var i = 0; i < 49; i++) {
        graph.addEdge(nodes1[i], nodes1[i + 1]);
        if (i < 47) {
          graph.addEdge(nodes1[i], nodes1[i + 2]);
        }
      }

      // Connect second component
      for (var i = 0; i < 49; i++) {
        graph.addEdge(nodes2[i], nodes2[i + 1]);
        if (i < 47) {
          graph.addEdge(nodes2[i], nodes2[i + 2]);
        }
      }

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = const Size(itemWidth, itemHeight);
      }

      final config = FruchtermanReingoldConfiguration()
        ..iterations = 50
        ..shuffleNodes = false
        ..useBarnesHut = true
        ..theta = 0.5;

      var algorithm = FruchtermanReingoldAlgorithm(config);

      final stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 0, 0);
      stopwatch.stop();

      print('Unconnected components time: ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds < 2000, true);
      expect(size.width > 0, true);
      expect(size.height > 0, true);

      // All nodes should be positioned
      for (var i = 0; i < graph.nodeCount(); i++) {
        final node = graph.getNodeAtPosition(i);
        expect(node.x >= 0, true);
        expect(node.y >= 0, true);
      }
    });
  });
}

/// Creates a connected graph with n nodes for performance testing
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
