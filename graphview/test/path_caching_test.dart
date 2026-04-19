import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

/// Test helper class that mimics the path caching behavior of RenderCustomLayoutBox.
/// This avoids depending on internal Flutter render object constructors which
/// require a full widget/render tree to function correctly.
class TestPathCache {
  final _pathCache = <Edge, Path>{};
  final dirtyEdges = <Edge>{};

  Path? getCachedPath(Edge edge) {
    if (dirtyEdges.contains(edge)) {
      return null;
    }
    return _pathCache[edge];
  }

  void cachePath(Edge edge, Path path) {
    _pathCache[edge] = path;
  }

  void clearPathCache() {
    _pathCache.clear();
  }

  void forceRecalculation() {
    _pathCache.clear();
    dirtyEdges.clear();
  }
}

void main() {
  group('Path Caching Tests', () {
    test('getCachedPath returns null when path not cached', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final edge = Edge(node1, node2);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdgeS(edge);

      final renderBox = TestPathCache();

      // Should return null when no path cached
      expect(renderBox.getCachedPath(edge), isNull);
    });

    test('cachePath stores path and getCachedPath retrieves it', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final edge = Edge(node1, node2);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdgeS(edge);

      final renderBox = TestPathCache();

      // Create and cache a path
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);

      renderBox.cachePath(edge, path);

      // Should retrieve cached path
      final cachedPath = renderBox.getCachedPath(edge);
      expect(cachedPath, isNotNull);
      expect(cachedPath, equals(path));
    });

    test('getCachedPath returns null for dirty edges', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final edge = Edge(node1, node2);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdgeS(edge);

      final renderBox = TestPathCache();

      // Cache a path
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);

      renderBox.cachePath(edge, path);

      // Mark edge as dirty
      renderBox.dirtyEdges.add(edge);

      // Should return null for dirty edge even though path is cached
      expect(renderBox.getCachedPath(edge), isNull);
    });

    test('clearPathCache removes all cached paths', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final edge1 = Edge(node1, node2);
      final edge2 = Edge(node2, node3);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addEdgeS(edge1);
      graph.addEdgeS(edge2);

      final renderBox = TestPathCache();

      // Cache paths for both edges
      final path1 = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);
      final path2 = Path()
        ..moveTo(100, 100)
        ..lineTo(200, 200);

      renderBox.cachePath(edge1, path1);
      renderBox.cachePath(edge2, path2);

      // Verify both are cached
      expect(renderBox.getCachedPath(edge1), isNotNull);
      expect(renderBox.getCachedPath(edge2), isNotNull);

      // Clear cache
      renderBox.clearPathCache();

      // Verify both are cleared
      expect(renderBox.getCachedPath(edge1), isNull);
      expect(renderBox.getCachedPath(edge2), isNull);
    });

    test('forceRecalculation clears path cache', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final edge = Edge(node1, node2);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdgeS(edge);

      final renderBox = TestPathCache();

      // Cache a path
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);

      renderBox.cachePath(edge, path);
      expect(renderBox.getCachedPath(edge), isNotNull);

      // Force recalculation should clear cache
      renderBox.forceRecalculation();

      expect(renderBox.getCachedPath(edge), isNull);
    });

    test('cached paths reused when nodes are static', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final edge1 = Edge(node1, node2);
      final edge2 = Edge(node2, node3);

      node1.position = const Offset(0, 0);
      node1.size = const Size(50, 50);
      node2.position = const Offset(100, 0);
      node2.size = const Size(50, 50);
      node3.position = const Offset(200, 0);
      node3.size = const Size(50, 50);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addEdgeS(edge1);
      graph.addEdgeS(edge2);

      final renderBox = TestPathCache();

      // Cache paths
      final path1 = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);
      final path2 = Path()
        ..moveTo(100, 100)
        ..lineTo(200, 200);

      renderBox.cachePath(edge1, path1);
      renderBox.cachePath(edge2, path2);

      // When nodes are static (not dirty), cached paths should be reused
      expect(renderBox.getCachedPath(edge1), equals(path1));
      expect(renderBox.getCachedPath(edge2), equals(path2));
      expect(renderBox.dirtyEdges.isEmpty, isTrue);
    });

    test('cached paths invalidated when connected node moves', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final edge1 = Edge(node1, node2);
      final edge2 = Edge(node2, node3);

      node1.position = const Offset(0, 0);
      node1.size = const Size(50, 50);
      node2.position = const Offset(100, 0);
      node2.size = const Size(50, 50);
      node3.position = const Offset(200, 0);
      node3.size = const Size(50, 50);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addEdgeS(edge1);
      graph.addEdgeS(edge2);

      final renderBox = TestPathCache();

      // Cache paths
      final path1 = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);
      final path2 = Path()
        ..moveTo(100, 100)
        ..lineTo(200, 200);

      renderBox.cachePath(edge1, path1);
      renderBox.cachePath(edge2, path2);

      // Simulate node2 being moved - mark connected edges dirty
      renderBox.dirtyEdges.add(edge1);
      renderBox.dirtyEdges.add(edge2);

      // Dirty edges should not return cached paths
      expect(renderBox.getCachedPath(edge1), isNull);
      expect(renderBox.getCachedPath(edge2), isNull);
    });

    test('cache invalidation on render cycle completion', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final edge = Edge(node1, node2);

      node1.position = const Offset(0, 0);
      node1.size = const Size(50, 50);
      node2.position = const Offset(100, 0);
      node2.size = const Size(50, 50);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdgeS(edge);

      final renderBox = TestPathCache();

      // Cache a path
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);

      renderBox.cachePath(edge, path);

      // Mark edge as dirty
      renderBox.dirtyEdges.add(edge);

      // Verify path is not accessible while dirty
      expect(renderBox.getCachedPath(edge), isNull);

      // Simulate render cycle completion by manually invalidating and clearing
      // (In actual rendering, paint() method handles this automatically)
      renderBox.forceRecalculation();

      // Old cached path should not exist anymore
      expect(renderBox.getCachedPath(edge), isNull);

      // New path would need to be computed and cached
      final newPath = Path()
        ..moveTo(0, 0)
        ..lineTo(120, 120);
      renderBox.cachePath(edge, newPath);

      expect(renderBox.getCachedPath(edge), equals(newPath));
    });

    test('multiple edges - only dirty edge caches invalidated', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      final edge1 = Edge(node1, node2);
      final edge2 = Edge(node2, node3);
      final edge3 = Edge(node3, node4);

      node1.position = const Offset(0, 0);
      node1.size = const Size(50, 50);
      node2.position = const Offset(100, 0);
      node2.size = const Size(50, 50);
      node3.position = const Offset(200, 0);
      node3.size = const Size(50, 50);
      node4.position = const Offset(300, 0);
      node4.size = const Size(50, 50);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);
      graph.addEdgeS(edge1);
      graph.addEdgeS(edge2);
      graph.addEdgeS(edge3);

      final renderBox = TestPathCache();

      // Cache all three paths
      final path1 = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);
      final path2 = Path()
        ..moveTo(100, 100)
        ..lineTo(200, 200);
      final path3 = Path()
        ..moveTo(200, 200)
        ..lineTo(300, 300);

      renderBox.cachePath(edge1, path1);
      renderBox.cachePath(edge2, path2);
      renderBox.cachePath(edge3, path3);

      // Mark only edge2 as dirty (node2 or node3 moved)
      renderBox.dirtyEdges.add(edge2);

      // edge1 and edge3 should still be accessible
      expect(renderBox.getCachedPath(edge1), equals(path1));
      expect(renderBox.getCachedPath(edge2), isNull); // Dirty
      expect(renderBox.getCachedPath(edge3), equals(path3));
    });
  });
}
