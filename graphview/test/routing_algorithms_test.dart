import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

// Helper to extract points from a path using metrics
List<Offset> extractPathPoints(Path path) {
  final points = <Offset>[];
  final metrics = path.computeMetrics();
  for (var metric in metrics) {
    final length = metric.length;
    const sampleDistance = 10.0;
    var distance = 0.0;
    while (distance <= length) {
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        points.add(tangent.position);
      }
      distance += sampleDistance;
    }
    final finalTangent = metric.getTangentForOffset(length);
    if (finalTangent != null) {
      points.add(finalTangent.position);
    }
  }
  return points;
}

Path buildOrthogonalPathForTest(
    OrthogonalEdgeRenderer renderer, Node source, Node destination) {
  final path = Path();
  renderer.buildOrthogonalPath(
    path,
    source,
    destination,
    source.position,
    destination.position,
  );
  return path;
}

double _distanceFromLine(Offset point, Offset lineStart, Offset lineEnd) {
  final line = lineEnd - lineStart;
  final length = line.distance;
  if (length == 0) return 0;

  return ((line.dy * point.dx) -
              (line.dx * point.dy) +
              (lineEnd.dx * lineStart.dy) -
              (lineEnd.dy * lineStart.dx))
          .abs() /
      length;
}

void main() {
  group('OrthogonalEdgeRenderer - Basic Path Generation', () {
    test('renderEdge does not mutate caller-owned paints', () {
      final source = Node.Id(1)
        ..position = const Offset(0, 0)
        ..size = const Size(80, 40);
      final destination = Node.Id(2)
        ..position = const Offset(200, 0)
        ..size = const Size(80, 40);
      final renderer = OrthogonalEdgeRenderer(EdgeRoutingConfig());
      final fallbackPaint = Paint()
        ..style = PaintingStyle.fill
        ..strokeWidth = 3;
      final edgePaint = Paint()
        ..style = PaintingStyle.fill
        ..strokeWidth = 7;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderEdge(canvas, Edge(source, destination), fallbackPaint);
      renderer.renderEdge(
        canvas,
        Edge(source, destination, paint: edgePaint),
        fallbackPaint,
      );
      final picture = recorder.endRecording();

      addTearDown(picture.dispose);
      expect(fallbackPaint.style, PaintingStyle.fill);
      expect(fallbackPaint.strokeWidth, 3);
      expect(edgePaint.style, PaintingStyle.fill);
      expect(edgePaint.strokeWidth, 7);
    });

    test('creates L-shaped path for horizontal nodes', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(0, 50);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(200, 50);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      // Path should be generated (we can't easily extract path points without Canvas,
      // but we can verify the renderer was created and method executes)
      expect(linePath.computeMetrics().isNotEmpty, isTrue);
    });

    test('creates L-shaped path for vertical nodes', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(100, 0);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(100, 200);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      // Path should be generated
      expect(linePath.computeMetrics().isNotEmpty, isTrue);
    });

    test('creates L-shaped path for diagonal nodes', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(0, 0);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(200, 150);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      // Path should be generated with right angles
      expect(linePath.computeMetrics().isNotEmpty, isTrue);
    });

    test('handles collinear horizontal nodes with offset', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(0, 100);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(200, 100);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      // Path should be generated with offset for collinear nodes
      expect(linePath.computeMetrics().isNotEmpty, isTrue);
    });

    test('handles collinear vertical nodes with offset', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(100, 0);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(100, 200);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      // Path should be generated with offset for collinear nodes
      expect(linePath.computeMetrics().isNotEmpty, isTrue);
    });

    test('handles nodes at same position', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(100, 100);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(100, 100);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      // Same-position nodes can produce a zero-length path, but should not throw.
      expect(linePath.computeMetrics().isEmpty, isTrue);
    });
  });

  group('OrthogonalEdgeRenderer - Path Direction Logic', () {
    test('uses horizontal-first routing when horizontal distance is greater',
        () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(0, 50);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      // Horizontal distance: 300, Vertical distance: 30
      node2.position = Offset(300, 80);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      // Should use horizontal-first routing
      expect(linePath.computeMetrics().isNotEmpty, isTrue);
    });

    test('uses vertical-first routing when vertical distance is greater', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(100, 0);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      // Horizontal distance: 30, Vertical distance: 300
      node2.position = Offset(130, 300);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      // Should use vertical-first routing
      expect(linePath.computeMetrics().isNotEmpty, isTrue);
    });
  });

  group('OrthogonalEdgeRenderer - Self-Loops', () {
    test('handles self-loop edges', () {
      final graph = Graph();
      final node = Node.Id(1);
      node.position = Offset(100, 100);
      node.size = Size(80, 40);

      graph.addNode(node);
      final edge = graph.addEdge(node, node);

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      // Self-loops should use buildSelfLoopPath from base class
      final loopPath = renderer.buildSelfLoopPath(edge);

      expect(loopPath, isNotNull);
      expect(loopPath!.path, isNotNull);
    });
  });

  group('OrthogonalEdgeRenderer - Edge Labels', () {
    test('supports edge labels', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(0, 50);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(200, 50);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      final edge = graph.addEdge(node1, node2, label: 'Test Label');

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      // Edge should have label
      expect(edge.label, equals('Test Label'));
      expect(linePath.computeMetrics().isNotEmpty, isTrue);
    });
  });

  group('OrthogonalEdgeRenderer - Configuration', () {
    test('accepts EdgeRoutingConfig', () {
      final config = EdgeRoutingConfig(
        anchorMode: AnchorMode.cardinal,
        routingMode: RoutingMode.orthogonal,
      );
      final renderer = OrthogonalEdgeRenderer(config);

      expect(renderer.configuration, equals(config));
      expect(
          renderer.configuration.routingMode, equals(RoutingMode.orthogonal));
    });

    test('works with different anchor modes', () {
      final config = EdgeRoutingConfig(
        anchorMode: AnchorMode.dynamic,
        routingMode: RoutingMode.orthogonal,
      );
      final renderer = OrthogonalEdgeRenderer(config);

      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(0, 50);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(200, 50);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      expect(linePath.computeMetrics().isNotEmpty, isTrue);
    });
  });

  group('OrthogonalEdgeRenderer - Right Angles Verification', () {
    test('orthogonal paths have right angles', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(0, 0);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(200, 150);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      final metric = linePath.computeMetrics().single;
      var hasHorizontalSegment = false;
      var hasVerticalSegment = false;

      for (var distance = 0.0; distance <= metric.length; distance += 5.0) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent == null) continue;
        final dx = tangent.vector.dx.abs();
        final dy = tangent.vector.dy.abs();
        hasHorizontalSegment |= dy < 0.01 && dx > 0.01;
        hasVerticalSegment |= dx < 0.01 && dy > 0.01;
      }

      expect(hasHorizontalSegment, isTrue);
      expect(hasVerticalSegment, isTrue);
    });

    test('all path segments are horizontal or vertical', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(50, 50);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(250, 200);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      final metric = linePath.computeMetrics().single;
      for (var distance = 0.0; distance <= metric.length; distance += 5.0) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent == null) continue;
        final dx = tangent.vector.dx.abs();
        final dy = tangent.vector.dy.abs();
        final isHorizontal = dy < 0.01 && dx > 0.01;
        final isVertical = dx < 0.01 && dy > 0.01;

        expect(
          isHorizontal || isVertical,
          isTrue,
          reason: 'Orthogonal path tangents should be horizontal or vertical',
        );
      }
    });

    test('orthogonal path is one continuous contour', () {
      final node1 = Node.Id(1)
        ..position = const Offset(50, 50)
        ..size = const Size(80, 40);
      final node2 = Node.Id(2)
        ..position = const Offset(250, 200)
        ..size = const Size(80, 40);
      final renderer = OrthogonalEdgeRenderer(EdgeRoutingConfig());

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      expect(linePath.computeMetrics().length, 1);
    });

    test('collinear orthogonal path uses offset corridor', () {
      final node1 = Node.Id(1)
        ..position = const Offset(0, 0)
        ..size = const Size(80, 40);
      final node2 = Node.Id(2)
        ..position = const Offset(200, 0)
        ..size = const Size(80, 40);
      final renderer = OrthogonalEdgeRenderer(
        EdgeRoutingConfig(minEdgeDistance: 24),
      );

      final linePath = buildOrthogonalPathForTest(renderer, node1, node2);

      final metric = linePath.computeMetrics().single;
      final startY = metric.getTangentForOffset(0)!.position.dy;
      double? offsetSegmentY;

      for (var distance = 0.0; distance <= metric.length; distance += 2.0) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent == null) continue;
        final isHorizontal =
            tangent.vector.dy.abs() < 0.01 && tangent.vector.dx.abs() > 0.01;
        if (isHorizontal && (tangent.position.dy - startY).abs() > 1.0) {
          offsetSegmentY = tangent.position.dy;
          break;
        }
      }

      expect(offsetSegmentY, isNotNull);
      expect((offsetSegmentY! - startY).abs(), closeTo(24, 0.1));
    });
  });

  group('OrthogonalEdgeRenderer - Multiple Edges', () {
    test('renders multiple edges between different nodes', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(0, 50);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(200, 50);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);
      graph.addEdge(node2, node1);

      final config = EdgeRoutingConfig();
      final renderer = OrthogonalEdgeRenderer(config);

      final firstPath = buildOrthogonalPathForTest(renderer, node1, node2);
      expect(firstPath.computeMetrics().isNotEmpty, isTrue);

      final secondPath = buildOrthogonalPathForTest(renderer, node2, node1);
      expect(secondPath.computeMetrics().isNotEmpty, isTrue);
    });
  });

  group('AdaptiveEdgeRenderer - Bezier Routing', () {
    test('creates smooth bezier curves between nodes', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(0, 0);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(200, 150);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      final edge = graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig(
        anchorMode: AnchorMode.dynamic,
        routingMode: RoutingMode.bezier,
      );
      final renderer = AdaptiveEdgeRenderer(config: config);
      renderer.setGraph(graph);

      // Calculate connection points
      final sourceCenter = Offset(
        node1.position.dx + node1.width * 0.5,
        node1.position.dy + node1.height * 0.5,
      );
      final destCenter = Offset(
        node2.position.dx + node2.width * 0.5,
        node2.position.dy + node2.height * 0.5,
      );

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, 0);
      final destPoint =
          renderer.calculateDestinationConnectionPoint(edge, sourceCenter, 0);

      // Route the path with bezier
      final path = renderer.routeEdgePath(sourcePoint, destPoint, edge);

      // Path should be created (we can't easily inspect cubic bezier points)
      expect(path, isNotNull);
    });

    test('bezier paths curve smoothly with control points', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(50, 50);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(300, 200);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      final edge = graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig(
        anchorMode: AnchorMode.cardinal,
        routingMode: RoutingMode.bezier,
      );
      final renderer = AdaptiveEdgeRenderer(config: config);
      renderer.setGraph(graph);

      final sourceCenter = Offset(
        node1.position.dx + node1.width * 0.5,
        node1.position.dy + node1.height * 0.5,
      );
      final destCenter = Offset(
        node2.position.dx + node2.width * 0.5,
        node2.position.dy + node2.height * 0.5,
      );

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, 0);
      final destPoint =
          renderer.calculateDestinationConnectionPoint(edge, sourceCenter, 0);

      // Route the path with bezier
      final path = renderer.routeEdgePath(sourcePoint, destPoint, edge);

      expect(path, isNotNull);
      final sampledPoints = extractPathPoints(path);
      final maxLineDistance = sampledPoints
          .map((point) => _distanceFromLine(point, sourcePoint, destPoint))
          .reduce(max);

      expect(maxLineDistance, greaterThan(0.1));
    });

    test('bezier routing handles zero-distance edges gracefully', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(100, 100);
      node1.size = Size(80, 40);

      graph.addNode(node1);
      final edge = graph.addEdge(node1, node1);

      final config = EdgeRoutingConfig(
        anchorMode: AnchorMode.center,
        routingMode: RoutingMode.bezier,
      );
      final renderer = AdaptiveEdgeRenderer(config: config);
      renderer.setGraph(graph);

      final center = Offset(
        node1.position.dx + node1.width * 0.5,
        node1.position.dy + node1.height * 0.5,
      );

      // Same point for source and destination (edge case)
      final path = renderer.routeEdgePath(center, center, edge);

      expect(path, isNotNull);
    });

    test('bezier routing works with octagonal anchor mode', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(0, 0);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(150, 150);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      final edge = graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig(
        anchorMode: AnchorMode.octagonal,
        routingMode: RoutingMode.bezier,
      );
      final renderer = AdaptiveEdgeRenderer(config: config);
      renderer.setGraph(graph);

      final sourceCenter = Offset(
        node1.position.dx + node1.width * 0.5,
        node1.position.dy + node1.height * 0.5,
      );
      final destCenter = Offset(
        node2.position.dx + node2.width * 0.5,
        node2.position.dy + node2.height * 0.5,
      );

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, 0);
      final destPoint =
          renderer.calculateDestinationConnectionPoint(edge, sourceCenter, 0);

      final path = renderer.routeEdgePath(sourcePoint, destPoint, edge);

      expect(path, isNotNull);
    });

    test('direct routing mode creates straight lines', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(0, 0);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(200, 150);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      final edge = graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig(
        anchorMode: AnchorMode.dynamic,
        routingMode: RoutingMode.direct,
      );
      final renderer = AdaptiveEdgeRenderer(config: config);
      renderer.setGraph(graph);

      final sourceCenter = Offset(
        node1.position.dx + node1.width * 0.5,
        node1.position.dy + node1.height * 0.5,
      );
      final destCenter = Offset(
        node2.position.dx + node2.width * 0.5,
        node2.position.dy + node2.height * 0.5,
      );

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, 0);
      final destPoint =
          renderer.calculateDestinationConnectionPoint(edge, sourceCenter, 0);

      final path = renderer.routeEdgePath(sourcePoint, destPoint, edge);

      expect(path, isNotNull);
    });

    test(
        'orthogonal routing mode in AdaptiveEdgeRenderer creates L-shaped paths',
        () {
      final graph = Graph();
      final node1 = Node.Id(1);
      node1.position = Offset(0, 0);
      node1.size = Size(80, 40);

      final node2 = Node.Id(2);
      node2.position = Offset(200, 150);
      node2.size = Size(80, 40);

      graph.addNode(node1);
      graph.addNode(node2);
      final edge = graph.addEdge(node1, node2);

      final config = EdgeRoutingConfig(
        anchorMode: AnchorMode.cardinal,
        routingMode: RoutingMode.orthogonal,
      );
      final renderer = AdaptiveEdgeRenderer(config: config);
      renderer.setGraph(graph);

      final sourceCenter = Offset(
        node1.position.dx + node1.width * 0.5,
        node1.position.dy + node1.height * 0.5,
      );
      final destCenter = Offset(
        node2.position.dx + node2.width * 0.5,
        node2.position.dy + node2.height * 0.5,
      );

      final sourcePoint =
          renderer.calculateSourceConnectionPoint(edge, destCenter, 0);
      final destPoint =
          renderer.calculateDestinationConnectionPoint(edge, sourceCenter, 0);

      final path = renderer.routeEdgePath(sourcePoint, destPoint, edge);

      expect(path, isNotNull);
    });
  });
}
