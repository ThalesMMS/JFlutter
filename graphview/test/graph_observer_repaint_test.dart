import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

import 'support/large_graph_perf_fixtures.dart';

void main() {
  group('Graph observer repaint wiring', () {
    late Graph graph;
    late Node nodeA;
    late Node nodeB;

    setUp(() {
      graph = Graph();
      nodeA = Node.Id('a')..position = const Offset(40, 40);
      nodeB = Node.Id('b')..position = const Offset(240, 160);
      graph.addNode(nodeA);
      graph.addNode(nodeB);
      graph.addEdge(nodeA, nodeB);
    });

    Widget buildHost() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 640,
            height: 480,
            child: GraphView.builder(
              graph: graph,
              algorithm: CountingStaticLayoutAlgorithm(),
              animated: false,
              builder: (node) => const SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );
    }

    testWidgets(
        'render object observes the source graph and schedules a repaint '
        'for in-place position updates', (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.pump();

      final renderBox = tester
          .renderObject<RenderCustomLayoutBox>(find.byType(GraphViewWidget));
      expect(graph.graphObserver, contains(renderBox));
      expect(renderBox.debugNeedsPaint, isFalse);

      // Simulates a live drag preview: the host mutates the node position in
      // place and notifies the graph without rebuilding any widget.
      nodeA.position = const Offset(120, 90);
      graph.markModified();

      expect(renderBox.debugNeedsPaint, isTrue);
      expect(renderBox.debugNeedsLayout, isFalse);

      await tester.pump();
      expect(renderBox.debugNeedsPaint, isFalse);
    });

    testWidgets('stops observing the graph once the view is disposed',
        (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.pump();

      expect(graph.graphObserver, isNotEmpty);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(graph.graphObserver, isEmpty);
    });
  });
}
