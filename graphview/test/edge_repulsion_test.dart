import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void main() {
  group('EdgeRepulsionSolver - Spatial Grid Tests', () {
    late EdgeRepulsionSolver solver;
    late Graph graph;
    late EdgeRenderer renderer;

    setUp(() {
      solver = EdgeRepulsionSolver();
      graph = Graph();
      renderer = ArrowEdgeRenderer();
    });

    test('creates solver with default cell size', () {
      expect(solver.cellSize, equals(EdgeRepulsionSolver.DEFAULT_CELL_SIZE));
      expect(solver.cellSize, equals(50.0));
    });

    test('creates solver with custom cell size', () {
      final customSolver = EdgeRepulsionSolver(cellSize: 100.0);
      expect(customSolver.cellSize, equals(100.0));
    });

    test('clears grid and segments', () {
      // Create a simple edge
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 100);

      graph.addNode(node1);
      graph.addNode(node2);
      final edge = graph.addEdge(node1, node2);

      // Build grid
      solver.buildGrid([edge], renderer);
      var stats = solver.getStatistics();
      expect(stats['totalSegments'], greaterThan(0));

      // Clear and verify
      solver.clear();
      stats = solver.getStatistics();
      expect(stats['totalSegments'], equals(0));
      expect(stats['totalCells'], equals(0));
    });

    test('correctly buckets edge segments into grid cells', () {
      // Create nodes at specific positions
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 100);

      graph.addNode(node1);
      graph.addNode(node2);
      final edge = graph.addEdge(node1, node2);

      // Build grid with default cell size (50px)
      solver.buildGrid([edge], renderer);

      final stats = solver.getStatistics();
      expect(stats['totalSegments'], equals(1));

      // Edge from (0,0) to (100,100) should span multiple cells
      // With 50px cell size: cells (0,0), (0,1), (1,0), (1,1), (2,0), (0,2), (2,2)
      expect(stats['totalCells'], greaterThan(0));
    });

    test('detects intersecting edge segments', () {
      // Create two edges that cross each other
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      // Edge 1: from (0, 0) to (100, 100) - diagonal
      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 100);

      // Edge 2: from (0, 100) to (100, 0) - opposite diagonal (they intersect)
      node3.position = const Offset(0, 100);
      node4.position = const Offset(100, 0);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);

      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node3, node4);

      // Build grid
      solver.buildGrid([edge1, edge2], renderer);

      // Detect intersections
      final intersections = solver.detectIntersections();

      expect(intersections.length, equals(1));
      expect(intersections[0].length, equals(2));

      // Verify the intersecting edges
      final segment1 = intersections[0][0];
      final segment2 = intersections[0][1];

      expect({segment1.edge, segment2.edge}, containsAll([edge1, edge2]));
    });

    test('does not detect non-intersecting parallel segments', () {
      // Create two parallel edges that don't intersect
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      // Edge 1: from (0, 0) to (100, 0) - horizontal
      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 0);

      // Edge 2: from (0, 50) to (100, 50) - parallel horizontal, 50px away
      node3.position = const Offset(0, 50);
      node4.position = const Offset(100, 50);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);

      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node3, node4);

      // Build grid
      solver.buildGrid([edge1, edge2], renderer);

      // Detect intersections
      final intersections = solver.detectIntersections();

      expect(intersections.length, equals(0));
    });

    test('finds candidate intersections for a segment', () {
      // Create multiple edges
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 100);
      node3.position = const Offset(0, 100);
      node4.position = const Offset(100, 0);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);

      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node3, node4);

      // Build grid
      solver.buildGrid([edge1, edge2], renderer);

      // Get the first segment
      final segment = EdgeSegment(
        node1.position,
        node2.position,
        edge1,
        0,
      );

      // Find candidates
      final candidates = solver.findCandidateIntersections(segment);

      // Should find the other edge segment as a candidate
      expect(candidates.length, greaterThan(0));
    });

    test('detects proximity of nearby segments', () {
      // Create two parallel edges close together
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      // Edge 1: from (0, 0) to (100, 0)
      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 0);

      // Edge 2: from (0, 5) to (100, 5) - only 5px away
      node3.position = const Offset(0, 5);
      node4.position = const Offset(100, 5);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);

      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node3, node4);

      // Build grid
      solver.buildGrid([edge1, edge2], renderer);

      // Detect proximity with 10px threshold
      final proximities = solver.detectProximity(10.0);

      expect(proximities.length, equals(1));
      expect(proximities[0].length, equals(2));
    });

    test('does not detect proximity for far apart segments', () {
      // Create two edges far apart
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      // Edge 1: from (0, 0) to (100, 0)
      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 0);

      // Edge 2: from (0, 100) to (100, 100) - 100px away
      node3.position = const Offset(0, 100);
      node4.position = const Offset(100, 100);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);

      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node3, node4);

      // Build grid
      solver.buildGrid([edge1, edge2], renderer);

      // Detect proximity with 10px threshold
      final proximities = solver.detectProximity(10.0);

      expect(proximities.length, equals(0));
    });

    test('handles multiple edges efficiently', () {
      // Create a grid of nodes with many edges
      final nodes = <Node>[];

      for (var i = 0; i < 10; i++) {
        for (var j = 0; j < 10; j++) {
          final node = Node.Id('$i-$j');
          node.position = Offset(i * 50.0, j * 50.0);
          graph.addNode(node);
          nodes.add(node);
        }
      }

      // Create edges between adjacent nodes
      final edges = <Edge>[];
      for (var i = 0; i < 9; i++) {
        for (var j = 0; j < 9; j++) {
          final node1 = nodes[i * 10 + j];
          final node2 = nodes[i * 10 + j + 1]; // right neighbor
          final node3 = nodes[(i + 1) * 10 + j]; // bottom neighbor

          edges.add(graph.addEdge(node1, node2));
          edges.add(graph.addEdge(node1, node3));
        }
      }

      // Build grid - this should be fast with spatial partitioning
      final stopwatch = Stopwatch()..start();
      solver.buildGrid(edges, renderer);
      stopwatch.stop();

      // Should complete quickly (< 100ms for 162 edges)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));

      final stats = solver.getStatistics();
      expect(stats['totalSegments'], equals(edges.length));
    });

    test('provides accurate statistics', () {
      // Create a few edges
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);

      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 0);
      node3.position = const Offset(200, 0);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);

      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node2, node3);

      // Build grid
      solver.buildGrid([edge1, edge2], renderer);

      final stats = solver.getStatistics();

      expect(stats['totalSegments'], equals(2));
      expect(stats['totalCells'], greaterThan(0));
      expect(stats['avgSegmentsPerCell'], greaterThan(0.0));
      expect(stats['generation'], greaterThan(0));
    });

    test('handles zero-length edges gracefully', () {
      // Create a self-loop edge (source == destination)
      final node1 = Node.Id(1);
      node1.position = const Offset(50, 50);

      graph.addNode(node1);
      final edge = graph.addEdge(node1, node1);

      // Build grid
      solver.buildGrid([edge], renderer);

      final stats = solver.getStatistics();
      expect(stats['totalSegments'], equals(1));
    });

    test('skips segments from same edge in intersection detection', () {
      // This test verifies that segments from the same edge don't
      // register as intersecting with themselves

      final node1 = Node.Id(1);
      final node2 = Node.Id(2);

      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 100);

      graph.addNode(node1);
      graph.addNode(node2);

      final edge = graph.addEdge(node1, node2);

      // Build grid
      solver.buildGrid([edge], renderer);

      // Detect intersections
      final intersections = solver.detectIntersections();

      // Should not detect self-intersection
      expect(intersections.length, equals(0));
    });
  });

  group('EdgeRepulsionSolver - Repulsion Forces Tests', () {
    late EdgeRepulsionSolver solver;
    late Graph graph;
    late EdgeRenderer renderer;
    late EdgeRoutingConfig config;

    setUp(() {
      solver = EdgeRepulsionSolver();
      graph = Graph();
      renderer = ArrowEdgeRenderer();
      config = EdgeRoutingConfig(
        enableRepulsion: true,
        repulsionStrength: 0.5,
        minEdgeDistance: 10.0,
        maxRepulsionIterations: 10,
      );
    });

    test('applies repulsion forces to parallel edges that are too close', () {
      // Create two parallel horizontal edges 5px apart (less than minEdgeDistance of 10px)
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 0);
      node3.position = const Offset(0, 5);
      node4.position = const Offset(100, 5);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);

      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node3, node4);

      // Apply repulsion forces
      final offsets =
          solver.applyRepulsionForces([edge1, edge2], renderer, config);

      // Both edges should have non-zero repulsion offsets
      expect(offsets[edge1], isNotNull);
      expect(offsets[edge2], isNotNull);

      // Offsets should push edges apart (in opposite directions)
      final offset1 = offsets[edge1]!;
      final offset2 = offsets[edge2]!;

      // For horizontal edges, offsets should be primarily vertical
      expect(offset1.dy.abs(), greaterThan(VectorUtils.epsilon));
      expect(offset2.dy.abs(), greaterThan(VectorUtils.epsilon));

      // Offsets should be in opposite directions (one up, one down)
      expect(offset1.dy * offset2.dy, lessThan(0));
    });

    test('does not apply forces when repulsion is disabled', () {
      final disabledConfig = EdgeRoutingConfig(
        enableRepulsion: false,
        minEdgeDistance: 10.0,
      );

      // Create two close edges
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 0);
      node3.position = const Offset(0, 5);
      node4.position = const Offset(100, 5);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);

      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node3, node4);

      // Apply repulsion forces with disabled config
      final offsets =
          solver.applyRepulsionForces([edge1, edge2], renderer, disabledConfig);

      // Should return empty map
      expect(offsets.isEmpty, isTrue);
    });

    test('does not apply forces to edges that are far apart', () {
      // Create two parallel edges 50px apart (much more than minEdgeDistance of 10px)
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 0);
      node3.position = const Offset(0, 50);
      node4.position = const Offset(100, 50);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);

      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node3, node4);

      // Apply repulsion forces
      final offsets =
          solver.applyRepulsionForces([edge1, edge2], renderer, config);

      // Offsets should be zero or very small since edges are far apart
      final offset1 = offsets[edge1] ?? Offset.zero;
      final offset2 = offsets[edge2] ?? Offset.zero;

      expect(offset1.distance, lessThan(VectorUtils.epsilon));
      expect(offset2.distance, lessThan(VectorUtils.epsilon));
    });

    test('applies stronger forces for closer edges', () {
      // Test individual pair forces at different distances.
      // Use separate 2-edge setups to avoid multi-edge force cancellation.

      // Setup 1: reference edge + close edge (3px apart)
      final graph1 = Graph();
      final solver1 = EdgeRepulsionSolver();
      final n1a = Node.Id(1)..position = const Offset(0, 0);
      final n1b = Node.Id(2)..position = const Offset(100, 0);
      final n1c = Node.Id(3)..position = const Offset(0, 3);
      final n1d = Node.Id(4)..position = const Offset(100, 3);
      graph1.addNode(n1a);
      graph1.addNode(n1b);
      graph1.addNode(n1c);
      graph1.addNode(n1d);
      final closeEdge1 = graph1.addEdge(n1a, n1b);
      final closeEdge2 = graph1.addEdge(n1c, n1d);

      final closeOffsets = solver1
          .applyRepulsionForces([closeEdge1, closeEdge2], renderer, config);
      final closeForce = (closeOffsets[closeEdge2] ?? Offset.zero).distance;

      // Setup 2: reference edge + far edge (7px apart)
      final graph2 = Graph();
      final solver2 = EdgeRepulsionSolver();
      final n2a = Node.Id(5)..position = const Offset(0, 0);
      final n2b = Node.Id(6)..position = const Offset(100, 0);
      final n2c = Node.Id(7)..position = const Offset(0, 7);
      final n2d = Node.Id(8)..position = const Offset(100, 7);
      graph2.addNode(n2a);
      graph2.addNode(n2b);
      graph2.addNode(n2c);
      graph2.addNode(n2d);
      final farEdge1 = graph2.addEdge(n2a, n2b);
      final farEdge2 = graph2.addEdge(n2c, n2d);

      final farOffsets =
          solver2.applyRepulsionForces([farEdge1, farEdge2], renderer, config);
      final farForce = (farOffsets[farEdge2] ?? Offset.zero).distance;

      // Closer edges should have stronger force
      expect(closeForce, greaterThan(farForce));
    });

    test('forces are perpendicular to edge direction', () {
      // Create two parallel horizontal edges close together
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 0);
      node3.position = const Offset(0, 5);
      node4.position = const Offset(100, 5);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);

      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node3, node4);

      // Apply repulsion forces
      final offsets =
          solver.applyRepulsionForces([edge1, edge2], renderer, config);

      final offset1 = offsets[edge1]!;

      // Edge 1 is horizontal (direction = (100, 0))
      // Perpendicular should be vertical (0, ±1) when normalized
      // So the offset should be primarily vertical
      final edgeDirection = node2.position - node1.position;
      final perpendicular = VectorUtils.perpendicular(edgeDirection);

      // Check that offset is roughly parallel to perpendicular vector
      final normalizedOffset = VectorUtils.normalize(offset1);
      final normalizedPerpendicular = VectorUtils.normalize(perpendicular);

      // Dot product should be close to ±1 (parallel or anti-parallel)
      final dotProduct = VectorUtils.dotProduct(
        normalizedOffset,
        normalizedPerpendicular,
      ).abs();

      expect(dotProduct, greaterThan(0.9)); // Close to parallel
    });

    test('respects repulsion strength setting', () {
      final weakConfig = EdgeRoutingConfig(
        enableRepulsion: true,
        repulsionStrength: 0.1, // Weak
        minEdgeDistance: 10.0,
        maxRepulsionIterations: 10,
      );

      final strongConfig = EdgeRoutingConfig(
        enableRepulsion: true,
        repulsionStrength: 1.0, // Strong
        minEdgeDistance: 10.0,
        maxRepulsionIterations: 10,
      );

      // Create two close edges
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      node1.position = const Offset(0, 0);
      node2.position = const Offset(100, 0);
      node3.position = const Offset(0, 5);
      node4.position = const Offset(100, 5);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);

      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node3, node4);

      // Apply with weak strength
      final weakOffsets = solver.applyRepulsionForces(
        [edge1, edge2],
        renderer,
        weakConfig,
      );

      // Clear and rebuild for strong strength
      solver.clear();
      final strongOffsets = solver.applyRepulsionForces(
        [edge1, edge2],
        renderer,
        strongConfig,
      );

      // Strong config should produce larger offsets
      final weakOffset = weakOffsets[edge1] ?? Offset.zero;
      final strongOffset = strongOffsets[edge1] ?? Offset.zero;

      expect(strongOffset.distance, greaterThan(weakOffset.distance));
    });

    test('converges after multiple iterations', () {
      // Create multiple edges that need repulsion
      final nodes = <Node>[];
      final edges = <Edge>[];

      // Create 5 parallel horizontal edges, each 3px apart
      for (var i = 0; i < 5; i++) {
        final node1 = Node.Id('${i}a');
        final node2 = Node.Id('${i}b');
        node1.position = Offset(0, i * 3.0);
        node2.position = Offset(100, i * 3.0);

        graph.addNode(node1);
        graph.addNode(node2);
        nodes.add(node1);
        nodes.add(node2);

        edges.add(graph.addEdge(node1, node2));
      }

      // Apply repulsion forces
      final offsets = solver.applyRepulsionForces(edges, renderer, config);

      // All edges should have repulsion offsets
      for (final edge in edges) {
        expect(offsets[edge], isNotNull);
      }

      // Verify that the solver ran and produced results
      expect(
          offsets.values.any((offset) => offset.distance > VectorUtils.epsilon),
          isTrue);
    });

    test('handles crossing edges correctly', () {
      // Create two edges that cross each other
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      // Edge 1: diagonal from bottom-left to top-right
      node1.position = const Offset(0, 100);
      node2.position = const Offset(100, 0);

      // Edge 2: diagonal from top-left to bottom-right
      node3.position = const Offset(0, 0);
      node4.position = const Offset(100, 100);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);

      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node3, node4);

      // Apply repulsion forces
      final offsets =
          solver.applyRepulsionForces([edge1, edge2], renderer, config);

      // Both edges should have repulsion forces
      expect(offsets[edge1], isNotNull);
      expect(offsets[edge2], isNotNull);

      // Forces should push them apart
      final offset1 = offsets[edge1]!;
      final offset2 = offsets[edge2]!;

      expect(offset1.distance, greaterThan(VectorUtils.epsilon));
      expect(offset2.distance, greaterThan(VectorUtils.epsilon));
    });

    test('getRepulsionOffset returns correct offset', () {
      final edge1 = Edge(Node.Id(1), Node.Id(2));
      final edge2 = Edge(Node.Id(3), Node.Id(4));

      final offsets = {
        edge1: const Offset(5, 10),
        edge2: const Offset(-3, 7),
      };

      expect(solver.getRepulsionOffset(edge1, offsets),
          equals(const Offset(5, 10)));
      expect(solver.getRepulsionOffset(edge2, offsets),
          equals(const Offset(-3, 7)));
    });

    test('getRepulsionOffset returns zero for missing edge', () {
      final edge1 = Edge(Node.Id(1), Node.Id(2));
      final edge2 = Edge(Node.Id(3), Node.Id(4));

      final offsets = {
        edge1: const Offset(5, 10),
      };

      expect(solver.getRepulsionOffset(edge2, offsets), equals(Offset.zero));
    });
  });

  group('EdgeSegment Tests', () {
    test('calculates bounds correctly', () {
      final edge = Edge(Node.Id(1), Node.Id(2));
      final segment = EdgeSegment(
        const Offset(10, 20),
        const Offset(50, 80),
        edge,
        0,
      );

      final bounds = segment.getBounds();
      expect(bounds.left, equals(10));
      expect(bounds.top, equals(20));
      expect(bounds.right, equals(50));
      expect(bounds.bottom, equals(80));
    });

    test('calculates bounds with reversed points', () {
      final edge = Edge(Node.Id(1), Node.Id(2));
      final segment = EdgeSegment(
        const Offset(50, 80),
        const Offset(10, 20),
        edge,
        0,
      );

      final bounds = segment.getBounds();
      expect(bounds.left, equals(10));
      expect(bounds.top, equals(20));
      expect(bounds.right, equals(50));
      expect(bounds.bottom, equals(80));
    });

    test('calculates midpoint correctly', () {
      final edge = Edge(Node.Id(1), Node.Id(2));
      final segment = EdgeSegment(
        const Offset(0, 0),
        const Offset(100, 100),
        edge,
        0,
      );

      final midpoint = segment.midpoint;
      expect(midpoint.dx, equals(50));
      expect(midpoint.dy, equals(50));
    });

    test('calculates direction vector', () {
      final edge = Edge(Node.Id(1), Node.Id(2));
      final segment = EdgeSegment(
        const Offset(10, 20),
        const Offset(50, 80),
        edge,
        0,
      );

      final direction = segment.direction;
      expect(direction.dx, equals(40));
      expect(direction.dy, equals(60));
    });

    test('calculates length correctly', () {
      final edge = Edge(Node.Id(1), Node.Id(2));
      final segment = EdgeSegment(
        const Offset(0, 0),
        const Offset(3, 4),
        edge,
        0,
      );

      final length = segment.length;
      expect(length, equals(5.0)); // 3-4-5 triangle
    });
  });
}
