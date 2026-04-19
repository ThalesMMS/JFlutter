import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

import 'example_trees.dart';

const itemHeight = 100.0;
const itemWidth = 100.0;

extension on Graph {
  void inflateWithJson(Map<String, Object> json) {
    var edges = json['edges']! as List;
    edges.forEach((element) {
      var fromNodeId = element['from'];
      var toNodeId = element['to'];
      addEdge(Node.Id(fromNodeId), Node.Id(toNodeId));
    });
  }
}

extension on Node {
  Rect toRect() => Rect.fromLTRB(x, y, x + width, y + height);
}

void main() {
  group('Eiglsperger Graph', () {
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
    final node13 = Node.Id(13);
    final node14 = Node.Id(14);
    final node15 = Node.Id(15);
    final node16 = Node.Id(16);
    final node17 = Node.Id(17);
    final node18 = Node.Id(18);
    final node19 = Node.Id(19);
    final node20 = Node.Id(20);
    final node21 = Node.Id(21);
    final node22 = Node.Id(22);
    final node23 = Node.Id(23);

    graph.addEdge(node1, node13, paint: Paint()..color = Colors.red);
    graph.addEdge(node1, node21);
    graph.addEdge(node1, node4);
    graph.addEdge(node1, node3);
    graph.addEdge(node2, node3);
    graph.addEdge(node2, node20);
    graph.addEdge(node3, node4);
    graph.addEdge(node3, node5);
    graph.addEdge(node3, node23);
    graph.addEdge(node4, node6);
    graph.addEdge(node5, node7);
    graph.addEdge(node6, node8);
    graph.addEdge(node6, node16);
    graph.addEdge(node6, node23);
    graph.addEdge(node7, node9);
    graph.addEdge(node8, node10);
    graph.addEdge(node8, node11);
    graph.addEdge(node9, node12);
    graph.addEdge(node10, node13);
    graph.addEdge(node10, node14);
    graph.addEdge(node10, node15);
    graph.addEdge(node11, node15);
    graph.addEdge(node11, node16);
    graph.addEdge(node12, node20);
    graph.addEdge(node13, node17);
    graph.addEdge(node14, node17);
    graph.addEdge(node14, node18);
    graph.addEdge(node16, node18);
    graph.addEdge(node16, node19);
    graph.addEdge(node16, node20);
    graph.addEdge(node18, node21);
    graph.addEdge(node19, node22);
    graph.addEdge(node21, node23);
    graph.addEdge(node22, node23);
    graph.addEdge(node1, node22);
    graph.addEdge(node7, node8);

    test('Eiglsperger for unconnected nodes', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(3));
      graph.addEdge(Node.Id(4), Node.Id(7));

      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

      var algorithm = EiglspergerAlgorithm(_configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Eiglsperger for a single directional graph', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(3));
      graph.addEdge(Node.Id(3), Node.Id(4));
      graph.addEdge(Node.Id(4), Node.Id(7));
      graph.addEdge(Node.Id(7), Node.Id(9));
      graph.addEdge(Node.Id(9), Node.Id(111));

      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

      var algorithm = EiglspergerAlgorithm(_configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      expect(graph.getNodeUsingId(1).position.dx >= 10.0, true);
      expect(graph.getNodeUsingId(111).position.dx > graph.getNodeUsingId(1).position.dx, true);

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Eiglsperger for a cyclic graph', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(3));
      graph.addEdge(Node.Id(3), Node.Id(4));
      graph.addEdge(Node.Id(4), Node.Id(7));
      graph.addEdge(Node.Id(7), Node.Id(9));
      graph.addEdge(Node.Id(9), Node.Id(1));

      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

      var algorithm = EiglspergerAlgorithm(_configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    group('Orientation Tests', () {
      test('TOP_BOTTOM Orientation - Node Positioning', () {
        final _configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

        var algorithm = EiglspergerAlgorithm(_configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('TOP_BOTTOM Orientation - Time: ${timeTaken}ms, Size: $size');

        expect(timeTaken < 1000, true);

        expect(size.width > 0, true);
        expect(size.height > 0, true);
      });

      test('LEFT_RIGHT Orientation - Node Positioning', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

        var algorithm = EiglspergerAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('LEFT_RIGHT Orientation - Time: ${timeTaken}ms, Size: $size');

        expect(timeTaken < 1000, true);

        expect(size.width > 0, true);
        expect(size.height > 0, true);
      });

      test('BOTTOM_TOP Orientation - Node Positioning', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..orientation = SugiyamaConfiguration.ORIENTATION_BOTTOM_TOP;

        var algorithm = EiglspergerAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('BOTTOM_TOP Orientation - Time: ${timeTaken}ms, Size: $size');

        expect(timeTaken < 1000, true);

        expect(size.width > 0, true);
        expect(size.height > 0, true);
      });

      test('RIGHT_LEFT Orientation - Node Positioning', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..orientation = SugiyamaConfiguration.ORIENTATION_RIGHT_LEFT;

        var algorithm = EiglspergerAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('RIGHT_LEFT Orientation - Time: ${timeTaken}ms, Size: $size');

        expect(timeTaken < 1000, true);

        expect(size.width > 0, true);
        expect(size.height > 0, true);
      });
    });

    group('Node Separation Tests', () {
      test('Different node separations produce different layouts', () {
        final config15 = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

        final config50 = SugiyamaConfiguration()
          ..nodeSeparation = 50
          ..levelSeparation = 15
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

        final graph1 = Graph();
        graph1.addEdge(Node.Id(1), Node.Id(2));
        graph1.addEdge(Node.Id(1), Node.Id(3));
        for (var i = 0; i < graph1.nodeCount(); i++) {
          graph1.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        final graph2 = Graph();
        graph2.addEdge(Node.Id(1), Node.Id(2));
        graph2.addEdge(Node.Id(1), Node.Id(3));
        for (var i = 0; i < graph2.nodeCount(); i++) {
          graph2.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var algorithm15 = EiglspergerAlgorithm(config15);
        var algorithm50 = EiglspergerAlgorithm(config50);

        var size15 = algorithm15.run(graph1, 10, 10);
        var size50 = algorithm50.run(graph2, 10, 10);

        expect(size50.width >= size15.width, true);
      });
    });

    // Performance Tests for 140 Node Graph
    group('140 Node Graph Performance Tests', () {
      test('Eiglsperger Performance - 140 Nodes', () {
        print('\n=== 140 Node Graph - Eiglsperger Performance ===');

        final graph = Graph();
        graph.inflateWithJson(exampleTreeWith140Nodes);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

        final algorithm = EiglspergerAlgorithm(configuration);

        final stopwatch = Stopwatch()..start();
        final size = algorithm.run(graph, 10, 10);
        final timeTaken = stopwatch.elapsed.inMilliseconds;

        print('Eiglsperger: ${timeTaken}ms - Layout size: $size - Nodes: ${graph.nodeCount()}');

        expect(timeTaken < 3000, true,
            reason: 'Eiglsperger should complete within 3 seconds for 140 nodes');
      });

      test('Eiglsperger LEFT_RIGHT Orientation - 140 Nodes', () {
        final graph = Graph();
        graph.inflateWithJson(exampleTreeWith140Nodes);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

        final algorithm = EiglspergerAlgorithm(configuration);

        final stopwatch = Stopwatch()..start();
        final size = algorithm.run(graph, 10, 10);
        final timeTaken = stopwatch.elapsed.inMilliseconds;

        print('Eiglsperger LEFT_RIGHT: ${timeTaken}ms - Layout size: $size');

        expect(timeTaken < 3000, true);
      });
    });

    test('Eiglsperger for a complex graph with 140 nodes', () {
      final json = exampleTreeWith140Nodes;

      final graph = Graph();

      var edges = json['edges']!;
      edges.forEach((element) {
        var fromNodeId = element['from'];
        var toNodeId = element['to'];
        graph.addEdge(Node.Id(fromNodeId), Node.Id(toNodeId));
      });

      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

      final algorithm = EiglspergerAlgorithm(_configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Timetaken $timeTaken ${graph.nodeCount()}');

      expect(graph.nodeCount(), 140);
      expect(timeTaken < 3000, true);
    });

    test('Eiglsperger child nodes never overlaps', () {
      for (final json in exampleTrees) {
        final graph = Graph()..inflateWithJson(json);
        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();

        EiglspergerAlgorithm(SugiyamaConfiguration())..run(graph, 10, 10);

        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('Timetaken $timeTaken ${graph.nodeCount()}');

        for (var i = 0; i < graph.nodeCount(); i++) {
          final currentNode = graph.getNodeAtPosition(i);
          for (var j = 0; j < graph.nodeCount(); j++) {
            final otherNode = graph.getNodeAtPosition(j);

            if (currentNode.key == otherNode.key) continue;
            final currentRect = currentNode.toRect();
            final otherRect = otherNode.toRect();

            final overlaps = currentRect.overlaps(otherRect);
            expect(false, overlaps, reason: '$currentNode overlaps $otherNode');
          }
        }
      }
    });

    test('Eiglsperger Performance for 100 nodes to be less than 5.2s', () {
      final graph = Graph();

      var rows = 100;

      for (var i = 1; i <= rows; i++) {
        for (var j = 1; j <= i; j++) {
          graph.addEdge(Node.Id(i), Node.Id(j));
        }
      }

      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

      var algorithm = EiglspergerAlgorithm(_configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Timetaken $timeTaken ${graph.nodeCount()}');

      expect(timeTaken < 5200, true);
    });

    test('Eiglsperger handles empty graph', () {
      final graph = Graph();

      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

      var algorithm = EiglspergerAlgorithm(_configuration);

      var size = algorithm.run(graph, 10, 10);

      expect(size.width, 0);
      expect(size.height, 0);
    });

    test('Eiglsperger handles single node', () {
      final graph = Graph();
      graph.addNode(Node.Id(1));

      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

      var algorithm = EiglspergerAlgorithm(_configuration);

      graph.getNodeAtPosition(0).size = Size(itemWidth, itemHeight);

      var size = algorithm.run(graph, 10, 10);

      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Eiglsperger handles graph with multiple roots', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));
      graph.addEdge(Node.Id(4), Node.Id(5));
      graph.addEdge(Node.Id(5), Node.Id(6));

      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

      var algorithm = EiglspergerAlgorithm(_configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);
      expect(size.width > 0, true);
      expect(size.height > 0, true);
    });

    test('Eiglsperger with different level separations', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));
      graph.addEdge(Node.Id(3), Node.Id(4));

      final config1 = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

      final config2 = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 50
        ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var algorithm1 = EiglspergerAlgorithm(config1);
      var size1 = algorithm1.run(graph, 10, 10);

      final graph2 = Graph();
      graph2.addEdge(Node.Id(1), Node.Id(2));
      graph2.addEdge(Node.Id(2), Node.Id(3));
      graph2.addEdge(Node.Id(3), Node.Id(4));

      for (var i = 0; i < graph2.nodeCount(); i++) {
        graph2.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var algorithm2 = EiglspergerAlgorithm(config2);
      var size2 = algorithm2.run(graph2, 10, 10);

      expect(size2.height >= size1.height, true);
    });
  });
}
