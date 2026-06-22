import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void sizeNodes(Graph graph, [Size size = const Size(50, 50)]) {
  for (final node in graph.nodes) {
    node.size = size;
  }
}

Graph buildCycleGraph() {
  final graph = Graph();
  graph.addEdge(Node.Id(1), Node.Id(2));
  graph.addEdge(Node.Id(2), Node.Id(3));
  graph.addEdge(Node.Id(3), Node.Id(1));
  sizeNodes(graph);
  return graph;
}

Graph buildDiamondGraph() {
  final graph = Graph();
  graph.addEdge(Node.Id(1), Node.Id(3));
  graph.addEdge(Node.Id(1), Node.Id(4));
  graph.addEdge(Node.Id(2), Node.Id(3));
  graph.addEdge(Node.Id(2), Node.Id(4));
  graph.addEdge(Node.Id(3), Node.Id(5));
  graph.addEdge(Node.Id(4), Node.Id(5));
  sizeNodes(graph, const Size(60, 40));
  return graph;
}

Graph buildDAG() {
  final graph = Graph();
  graph.addEdge(Node.Id(1), Node.Id(2));
  graph.addEdge(Node.Id(1), Node.Id(3));
  graph.addEdge(Node.Id(2), Node.Id(4));
  graph.addEdge(Node.Id(3), Node.Id(4));
  sizeNodes(graph);
  return graph;
}

void main() {
  group('AccumulatorTree', () {
    test('no crossings for empty sequence', () {
      final tree = AccumulatorTree(4);
      expect(tree.crossCount([]), equals(0));
    });

    test('no crossings for single element', () {
      final tree = AccumulatorTree(4);
      expect(tree.crossCount([2]), equals(0));
    });

    test('no crossings for already sorted sequence', () {
      final tree = AccumulatorTree(4);
      expect(tree.crossCount([0, 1, 2, 3]), equals(0));
    });

    test('one crossing for reversed two-element sequence', () {
      final tree = AccumulatorTree(2);
      expect(tree.crossCount([1, 0]), equals(1));
    });

    test('three crossings for reversed three-element sequence', () {
      final tree = AccumulatorTree(3);
      expect(tree.crossCount([2, 1, 0]), equals(3));
    });

    test('partial order sequence produces correct crossing count', () {
      final tree = AccumulatorTree(3);
      expect(tree.crossCount([1, 0, 2]), equals(1));
    });

    test('size 1 tree has no crossings', () {
      final tree = AccumulatorTree(1);
      expect(tree.crossCount([0]), equals(0));
    });

    test('tree is initialized with zeros', () {
      final tree = AccumulatorTree(8);
      expect(tree.crossCount([0, 1, 2, 3, 4, 5, 6, 7]), equals(0));
    });
  });

  group('GreedyCycleRemoval', () {
    test('returns empty set for acyclic graph', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(3));

      final arcs = GreedyCycleRemoval(graph).getFeedbackArcs();

      expect(arcs, isEmpty);
    });

    test('returns empty set for empty graph', () {
      final graph = Graph();

      expect(GreedyCycleRemoval(graph).getFeedbackArcs(), isEmpty);
    });

    test('detects a simple two-node cycle', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(1));

      final arcs = GreedyCycleRemoval(graph).getFeedbackArcs();

      expect(arcs.length, equals(1));
    });

    test('detects a three-node cycle', () {
      final arcs = GreedyCycleRemoval(buildCycleGraph()).getFeedbackArcs();

      expect(arcs, isNotEmpty);
    });

    test('does not modify the original graph', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(1));
      final originalEdgeCount = graph.edges.length;

      GreedyCycleRemoval(graph).getFeedbackArcs();

      expect(graph.edges.length, equals(originalEdgeCount));
    });

    test('acyclic tree-shaped graph yields no feedback arcs', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(1), Node.Id(3));
      graph.addEdge(Node.Id(2), Node.Id(4));

      expect(GreedyCycleRemoval(graph).getFeedbackArcs(), isEmpty);
    });

    test('multiple separate cycles are each handled', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(1));
      graph.addEdge(Node.Id(3), Node.Id(4));
      graph.addEdge(Node.Id(4), Node.Id(3));

      final arcs = GreedyCycleRemoval(graph).getFeedbackArcs();

      expect(arcs.length, greaterThanOrEqualTo(2));
    });

    test('feedback arcs are reset and defensively copied between calls', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(1));
      final removal = GreedyCycleRemoval(graph);

      final firstArcs = removal.getFeedbackArcs();
      final firstLength = firstArcs.length;
      firstArcs.clear();
      final secondArcs = removal.getFeedbackArcs();

      expect(secondArcs.length, equals(firstLength));
      expect(secondArcs, isNot(same(firstArcs)));
    });
  });

  group('SugiyamaAlgorithm with greedy cycle removal', () {
    test('handles a simple cycle with greedy strategy', () {
      final config = SugiyamaConfiguration()
        ..cycleRemovalStrategy = CycleRemovalStrategy.greedy
        ..nodeSeparation = 15
        ..levelSeparation = 15;

      final size = SugiyamaAlgorithm(config).run(buildCycleGraph(), 0, 0);

      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    for (final strategy in CycleRemovalStrategy.values) {
      test('${strategy.name} strategy produces a valid layout', () {
        final config = SugiyamaConfiguration()
          ..cycleRemovalStrategy = strategy
          ..nodeSeparation = 15
          ..levelSeparation = 15;

        final size = SugiyamaAlgorithm(config).run(buildCycleGraph(), 0, 0);

        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
      });
    }
  });

  group('SugiyamaAlgorithm with accumulatorTree cross minimization', () {
    test('accumulatorTree strategy produces valid layout', () {
      final config = SugiyamaConfiguration()
        ..crossMinimizationStrategy = CrossMinimizationStrategy.accumulatorTree
        ..nodeSeparation = 15
        ..levelSeparation = 20;

      final size = SugiyamaAlgorithm(config).run(buildDiamondGraph(), 0, 0);

      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    for (final strategy in CrossMinimizationStrategy.values) {
      test('${strategy.name} strategy produces a valid layout', () {
        final config = SugiyamaConfiguration()
          ..crossMinimizationStrategy = strategy
          ..nodeSeparation = 15
          ..levelSeparation = 20;

        final size = SugiyamaAlgorithm(config).run(buildDiamondGraph(), 0, 0);

        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
      });
    }
  });

  group('SugiyamaAlgorithm layering strategies', () {
    for (final strategy in LayeringStrategy.values) {
      test('${strategy.name} strategy produces a valid layout', () {
        final config = SugiyamaConfiguration()
          ..layeringStrategy = strategy
          ..nodeSeparation = 15
          ..levelSeparation = 15;

        final size = SugiyamaAlgorithm(config).run(buildDAG(), 0, 0);

        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
      });
    }
  });
}
