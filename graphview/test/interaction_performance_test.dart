import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

import 'support/large_graph_perf_fixtures.dart';

void main() {
  group('GraphView interaction performance', () {
    for (final nodeCount in [500, 1000, 2000]) {
      testWidgets(
        'single-node drag stays within frame budget on $nodeCount-node tree',
        (tester) async {
          final fixture = createLargeGraphFixture(
            nodeCount: nodeCount,
            topology: GraphTopology.tree,
          );
          final algorithm = CountingStaticLayoutAlgorithm();
          final dragNode = fixture.nodes[1];
          final connectedEdges = {
            ...fixture.graph.getInEdges(dragNode),
            ...fixture.graph.getOutEdges(dragNode),
          }.length;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 960,
                  height: 720,
                  child: GraphView.builder(
                    graph: fixture.graph,
                    algorithm: algorithm,
                    animated: false,
                    builder: (node) => const SizedBox(width: 24, height: 24),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          final renderBox = tester.renderObject<RenderCustomLayoutBox>(
              find.byType(GraphViewWidget));
          final gesture = await tester.startGesture(
            dragNode.position + const Offset(12, 12),
          );
          await tester.pump();

          const moveCount = 60;
          final stopwatch = Stopwatch()..start();
          var maxDirtyEdges = 0;
          for (var index = 0; index < moveCount; index++) {
            await gesture.moveBy(const Offset(6, 0));
            maxDirtyEdges = math.max(
              maxDirtyEdges,
              renderBox.getDirtyEdges().length,
            );
            await tester.pump();
          }
          stopwatch.stop();

          await gesture.up();
          await tester.pump();

          final averageMoveMs =
              stopwatch.elapsedMicroseconds / moveCount / 1000.0;
          // Keep thresholds above measured medians to absorb CI/hardware
          // variance, browser differences, GC jitter, and a small safety
          // buffer; the same rationale applies to zoom/pan thresholds below.
          final thresholdMs = switch (nodeCount) {
            500 => 25.0,
            1000 => 75.0,
            _ => 200.0,
          };

          debugPrint(
            'Drag benchmark ($nodeCount nodes): '
            '${averageMoveMs.toStringAsFixed(2)}ms/move, '
            'dirtyEdges=$maxDirtyEdges/$connectedEdges',
          );

          expect(
            averageMoveMs,
            lessThan(thresholdMs),
            reason: 'Average drag move should stay below ${thresholdMs}ms',
          );
          expect(
            maxDirtyEdges,
            lessThanOrEqualTo(connectedEdges),
            reason:
                'Dragging one node should only invalidate its connected edges',
          );
        },
      );
    }

    for (final nodeCount in [500, 1000, 2000]) {
      testWidgets(
        'zoom and pan updates avoid relayout on $nodeCount-node grid',
        (tester) async {
          final fixture = createLargeGraphFixture(
            nodeCount: nodeCount,
            topology: GraphTopology.grid,
          );
          final algorithm = CountingStaticLayoutAlgorithm();
          final transformationController = TransformationController();
          final graphController = GraphViewController(
            transformationController: transformationController,
          );
          final trackedNodes = fixture.nodes.take(5).toList(growable: false);
          final originalPositions =
              trackedNodes.map((node) => node.position).toList(growable: false);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 960,
                  height: 720,
                  child: GraphView.builder(
                    graph: fixture.graph,
                    algorithm: algorithm,
                    animated: false,
                    controller: graphController,
                    builder: (node) => const SizedBox(width: 24, height: 24),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          final initialRunCount = algorithm.runCount;
          const updateCount = 40;
          final samples = <Duration>[];

          for (var index = 0; index < updateCount; index++) {
            final stopwatch = Stopwatch()..start();
            final scale = 1.0 + ((index % 5) * 0.03);
            transformationController.value = Matrix4.diagonal3Values(
              scale,
              scale,
              1.0,
            )..setTranslationRaw(-12.0 * index, -8.0 * (index % 6), 0.0);
            await tester.pump();
            stopwatch.stop();
            samples.add(stopwatch.elapsed);
          }

          final averageUpdateMs = averageMilliseconds(samples);
          final medianUpdateMs = medianMilliseconds(samples);

          debugPrint(
            'Zoom/pan benchmark ($nodeCount nodes): '
            '${averageUpdateMs.toStringAsFixed(2)}ms avg, '
            '${medianUpdateMs.toStringAsFixed(2)}ms median, '
            'layoutRuns=${algorithm.runCount - initialRunCount}',
          );

          expect(
            algorithm.runCount,
            equals(initialRunCount),
            reason: 'Viewport transforms must not trigger layout recalculation',
          );
          // Keep thresholds above measured medians to absorb CI/hardware
          // variance, browser differences, GC jitter, and a small safety
          // buffer; these numbers are intentionally permissive to reduce flakes.
          final thresholdMs = switch (nodeCount) {
            500 => 60.0,
            1000 => 220.0,
            _ => 700.0,
          };
          expect(
            averageUpdateMs,
            lessThan(thresholdMs),
            reason:
                'Average transform update should stay below ${thresholdMs}ms',
          );

          for (var index = 0; index < trackedNodes.length; index++) {
            expect(
                trackedNodes[index].position, equals(originalPositions[index]));
          }
        },
      );
    }
  });
}
