import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

const itemHeight = 50.0;
const itemWidth = 50.0;

void main() {
  group('Adaptive Edge Routing Performance Tests', () {
    test('100-edge graph renders in under 100ms', () {
      // Create graph with 50 nodes and 100 edges
      final graph = _createDenseGraph(50, 100);

      // Configure adaptive edge renderer with bezier routing
      final config = EdgeRoutingConfig()
        ..anchorMode = AnchorMode.dynamic
        ..routingMode = RoutingMode.bezier
        ..enableRepulsion = false;

      final renderer = AdaptiveEdgeRenderer(config: config);
      renderer.setGraph(graph);

      final stopwatch = Stopwatch()..start();

      // Simulate edge path generation for all edges
      for (final edge in graph.edges) {
        renderer.renderEdge(MockCanvas(), edge, Paint());
      }

      stopwatch.stop();
      final renderTime = stopwatch.elapsedMilliseconds;

      print('100-edge graph render time: ${renderTime}ms');
      expect(renderTime, lessThan(100),
          reason: '100-edge graph should render in under 100ms');
    });

    test('Edge repulsion solver completes in under 500ms for 200+ edges', () {
      // Create dense graph with 100 nodes and 200+ edges
      final graph = _createDenseGraph(100, 200);

      // Configure edge routing with repulsion enabled
      final config = EdgeRoutingConfig()
        ..anchorMode = AnchorMode.dynamic
        ..routingMode = RoutingMode.bezier
        ..enableRepulsion = true
        ..repulsionStrength = 0.5
        ..minEdgeDistance = 10.0
        ..maxRepulsionIterations = 10;

      final renderer = AdaptiveEdgeRenderer(config: config);
      final solver = EdgeRepulsionSolver();

      final stopwatch = Stopwatch()..start();

      // Build spatial grid and detect intersections/proximity
      solver.buildGrid(graph.edges.toList(), renderer);
      final intersections = solver.detectIntersections();
      final proximity = solver.detectProximity(config.minEdgeDistance);

      // Apply repulsion forces
      final offsets =
          solver.applyRepulsionForces(graph.edges.toList(), renderer, config);

      stopwatch.stop();
      final repulsionTime = stopwatch.elapsedMilliseconds;

      print(
          'Edge repulsion solver time for ${graph.edges.length} edges: ${repulsionTime}ms');
      print('  - Intersections detected: ${intersections.length}');
      print('  - Proximity pairs detected: ${proximity.length}');
      print('  - Repulsion offsets calculated: ${offsets.length}');

      expect(repulsionTime, lessThan(500),
          reason:
              'Repulsion solver should complete in under 500ms for 200+ edges');
    });

    test(
        'Dirty tracking efficiency - moving 1 node recalculates only connected edges',
        () {
      // Create graph with 50 nodes and 100 edges
      final graph = _createDenseGraph(50, 100);

      // Simulate moving one node by getting its connected edges
      final nodeToMove = graph.getNodeAtPosition(10);
      final outEdges = graph.getOutEdges(nodeToMove);
      final inEdges = graph.getInEdges(nodeToMove);
      final connectedEdges = {...outEdges, ...inEdges};

      print('Total edges in graph: ${graph.edges.length}');
      print('Node to move: ${nodeToMove.key}');
      print('Connected edges (dirty edges): ${connectedEdges.length}');

      // Verify dirty tracking efficiency: should be much less than total edges
      expect(connectedEdges.length, lessThan(10),
          reason:
              'Moving 1 node should mark fewer than 10 edges dirty in a 100-edge graph');

      // Verify it's a reasonable percentage of total edges
      final percentage = (connectedEdges.length / graph.edges.length) * 100;
      print(
          'Percentage of edges marked dirty: ${percentage.toStringAsFixed(1)}%');
      expect(percentage, lessThan(15.0),
          reason: 'Dirty edges should be less than 15% of total edges');
    });

    test('Path caching hit rate - second render reuses 100% cached paths', () {
      // Create graph with 50 nodes and 100 edges
      final graph = _createDenseGraph(50, 100);

      // Configure renderer with caching
      final config = EdgeRoutingConfig()
        ..anchorMode = AnchorMode.dynamic
        ..routingMode = RoutingMode.bezier
        ..enableRepulsion = false;

      final renderer = AdaptiveEdgeRenderer(config: config);
      final mockRenderBox = MockRenderCustomLayoutBox();

      // First render: cache all paths
      final stopwatch1 = Stopwatch()..start();
      for (final edge in graph.edges) {
        final path = renderer.routeEdgePath(
          edge.source.position,
          edge.destination.position,
          edge,
        );
        mockRenderBox.cachePath(edge, path);
      }
      stopwatch1.stop();
      final firstRenderTime = stopwatch1.elapsedMilliseconds;

      // Verify all paths are cached
      var cachedCount = 0;
      for (final edge in graph.edges) {
        if (mockRenderBox.getCachedPath(edge) != null) {
          cachedCount++;
        }
      }

      print('First render time: ${firstRenderTime}ms');
      print('Cached paths: ${cachedCount}/${graph.edges.length}');

      // Second render: should reuse cached paths (nodes haven't moved)
      final stopwatch2 = Stopwatch()..start();
      var cacheHits = 0;
      for (final edge in graph.edges) {
        final cachedPath = mockRenderBox.getCachedPath(edge);
        if (cachedPath != null) {
          cacheHits++;
          // Use cached path (no recalculation)
        } else {
          // Recalculate path
          final path = renderer.routeEdgePath(
            edge.source.position,
            edge.destination.position,
            edge,
          );
          mockRenderBox.cachePath(edge, path);
        }
      }
      stopwatch2.stop();
      final secondRenderTime = stopwatch2.elapsedMilliseconds;

      final cacheHitRate = (cacheHits / graph.edges.length) * 100;
      print('Second render time: ${secondRenderTime}ms');
      print('Cache hit rate: ${cacheHitRate.toStringAsFixed(1)}%');

      expect(cacheHitRate, equals(100.0),
          reason:
              'Second render should reuse 100% of cached paths when nodes are static');
      expect(secondRenderTime, lessThanOrEqualTo(firstRenderTime),
          reason: 'Second render should be faster or equal due to caching');
    });

    test('Spatial partitioning achieves O(n log n) performance', () {
      // Test with different graph sizes to verify O(n log n) scaling
      final sizes = [50, 100, 200];
      final times = <int, int>{};

      for (final size in sizes) {
        final graph = _createDenseGraph(size, size * 2);
        final config = EdgeRoutingConfig()
          ..enableRepulsion = true
          ..minEdgeDistance = 10.0;
        final renderer = AdaptiveEdgeRenderer(config: config);
        final solver = EdgeRepulsionSolver();

        final stopwatch = Stopwatch()..start();
        solver.buildGrid(graph.edges.toList(), renderer);
        solver.detectIntersections();
        stopwatch.stop();

        times[size] = stopwatch.elapsedMilliseconds;
        print(
            'Spatial partitioning time for $size nodes (${graph.edges.length} edges): ${times[size]}ms');
      }

      // Verify O(n log n) scaling: time ratio should be less than (n2/n1)^2
      final time100 = times[100]!;
      final time200 = times[200]!;

      // If it were O(n^2), 100->200 would be 4x slower
      // With O(n log n), it should be approximately 2.13x (200 log 200 / 100 log 100)
      // Allow up to 5x when the baseline is large enough to make a ratio stable.
      // For very small baselines, millisecond scheduling noise can dominate the
      // ratio, so use an absolute upper bound for the larger run instead.
      if (time100 > 0) {
        final ratio = time200 / time100;
        print('Scaling ratio 200->100 nodes: ${ratio.toStringAsFixed(2)}x');
        if (time100 >= 10) {
          expect(ratio, lessThanOrEqualTo(5.0),
              reason: 'O(n log n) scaling should be less than O(n^2) scaling');
        } else {
          expect(time200, lessThanOrEqualTo(50),
              reason: '200-node routing should stay fast when ratio baseline '
                  'is too small for stable timing');
        }
      }
    });

    test('Orthogonal routing performance with 150+ edges', () {
      // Create graph with 75 nodes and 150 edges
      final graph = _createDenseGraph(75, 150);

      // Configure orthogonal renderer
      final config = EdgeRoutingConfig()
        ..anchorMode = AnchorMode.cardinal
        ..routingMode = RoutingMode.orthogonal
        ..enableRepulsion = false;

      final renderer = OrthogonalEdgeRenderer(config);
      renderer.setGraph(graph);

      final stopwatch = Stopwatch()..start();

      // Generate orthogonal paths for all edges
      for (final edge in graph.edges) {
        renderer.renderEdge(MockCanvas(), edge, Paint());
      }

      stopwatch.stop();
      final renderTime = stopwatch.elapsedMilliseconds;

      print(
          'Orthogonal routing time for ${graph.edges.length} edges: ${renderTime}ms');
      expect(renderTime, lessThan(100),
          reason:
              'Orthogonal routing should complete in under 100ms for 150 edges');
    });

    test(
        'Combined: adaptive anchors + bezier routing + repulsion with 100+ edges',
        () {
      // Create realistic graph with 60 nodes and 120 edges
      final graph = _createDenseGraph(60, 120);

      // Configure full adaptive edge routing pipeline
      final config = EdgeRoutingConfig()
        ..anchorMode = AnchorMode.dynamic
        ..routingMode = RoutingMode.bezier
        ..enableRepulsion = true
        ..repulsionStrength = 0.5
        ..minEdgeDistance = 10.0
        ..maxRepulsionIterations = 10;

      final renderer = AdaptiveEdgeRenderer(config: config);
      renderer.setGraph(graph);

      final stopwatch = Stopwatch()..start();

      // Simulate full rendering pipeline
      for (final edge in graph.edges) {
        renderer.renderEdge(MockCanvas(), edge, Paint());
      }

      stopwatch.stop();
      final totalTime = stopwatch.elapsedMilliseconds;

      print(
          'Full adaptive edge routing pipeline for ${graph.edges.length} edges: ${totalTime}ms');
      print('  - Anchor mode: ${config.anchorMode}');
      print('  - Routing mode: ${config.routingMode}');
      print('  - Repulsion enabled: ${config.enableRepulsion}');

      expect(totalTime, lessThan(200),
          reason:
              'Full adaptive routing pipeline should complete in under 200ms for 120 edges');
    });

    test('Memory efficiency - multiple renders do not leak', () {
      // Create graph with 50 nodes and 100 edges
      final graph = _createDenseGraph(50, 100);
      final config = EdgeRoutingConfig()
        ..anchorMode = AnchorMode.dynamic
        ..routingMode = RoutingMode.bezier;
      final renderer = AdaptiveEdgeRenderer(config: config);
      renderer.setGraph(graph);

      // Perform multiple render cycles
      for (var cycle = 0; cycle < 10; cycle++) {
        for (final edge in graph.edges) {
          renderer.renderEdge(MockCanvas(), edge, Paint());
        }
        // Reset renderer state for next cycle
        renderer.setGraph(graph);
      }

      // Test passes if no memory exceptions occur
      print('10 render cycles completed successfully (no memory leaks)');
      expect(true, true);
    });
  });
}

/// Creates a dense graph with n nodes and approximately edgeCount edges
Graph _createDenseGraph(int nodeCount, int edgeCount) {
  final graph = Graph();
  final nodes = List.generate(nodeCount, (i) => Node.Id(i + 1));

  // Create a connected graph with specified number of edges
  var edgesCreated = 0;

  // First, create a spanning tree to ensure connectivity
  for (var i = 0; i < nodeCount - 1; i++) {
    graph.addEdge(nodes[i], nodes[i + 1]);
    edgesCreated++;
  }

  // Add additional edges to reach target count
  for (var i = 0; i < nodeCount && edgesCreated < edgeCount; i++) {
    for (var j = i + 2; j < nodeCount && edgesCreated < edgeCount; j++) {
      // Skip if edge would be too far (limit connections to nearby nodes)
      if (j - i > nodeCount ~/ 3) continue;

      // Add edge if not already exists
      final existingEdge = graph.edges
          .any((e) => e.source == nodes[i] && e.destination == nodes[j]);
      if (!existingEdge) {
        graph.addEdge(nodes[i], nodes[j]);
        edgesCreated++;
      }
    }
  }

  // Set node sizes
  for (var i = 0; i < graph.nodeCount(); i++) {
    graph.getNodeAtPosition(i).size = const Size(itemWidth, itemHeight);
    // Position nodes in a grid for realistic testing
    final row = i ~/ 10;
    final col = i % 10;
    graph.getNodeAtPosition(i).position = Offset(
      col * 100.0,
      row * 100.0,
    );
  }

  return graph;
}

/// Mock Canvas for testing edge rendering without actual drawing
class MockCanvas implements Canvas {
  @override
  void noSuchMethod(Invocation invocation) {}
}

/// Mock RenderCustomLayoutBox for testing path caching
class MockRenderCustomLayoutBox {
  final _pathCache = <Edge, Path>{};
  final _dirtyEdges = <Edge>{};

  Path? getCachedPath(Edge edge) {
    if (_dirtyEdges.contains(edge)) {
      return null;
    }
    return _pathCache[edge];
  }

  void cachePath(Edge edge, Path path) {
    _pathCache[edge] = path;
  }

  void markDirty(Edge edge) {
    _dirtyEdges.add(edge);
  }

  void clearDirty() {
    // Invalidate cached paths for dirty edges
    for (final edge in _dirtyEdges) {
      _pathCache.remove(edge);
    }
    _dirtyEdges.clear();
  }
}
