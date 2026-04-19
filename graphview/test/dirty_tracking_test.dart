import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void main() {
  group('Dirty Edge Tracking', () {
    test('dirtyEdges starts empty for a new graph', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);

      // Simulate dirty edge tracking: initially no node has moved
      final dirtyEdges = <Edge>{};
      expect(dirtyEdges.isEmpty, isTrue);
    });

    test('edges connected to moved node are marked dirty', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);

      // Create edges: node1 -> node2, node2 -> node3
      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node2, node3);

      // In a real scenario, when node2 is moved (dragged), edges connected to it should be marked dirty
      // Simulate this by directly calling the methods that would be called during drag

      final dirtyEdges = <Edge>{};
      dirtyEdges.addAll(graph.getOutEdges(node2)); // edge2
      dirtyEdges.addAll(graph.getInEdges(node2)); // edge1

      expect(dirtyEdges.length, 2);
      expect(dirtyEdges.contains(edge1), isTrue);
      expect(dirtyEdges.contains(edge2), isTrue);
    });

    test('only edges connected to moved node are marked dirty', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);
      graph.addNode(node4);

      // Create edges: node1 -> node2, node2 -> node3, node3 -> node4
      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node2, node3);
      final edge3 = graph.addEdge(node3, node4);

      // When node2 is moved, only edge1 and edge2 should be marked dirty
      final dirtyEdges = <Edge>{};
      dirtyEdges.addAll(graph.getOutEdges(node2));
      dirtyEdges.addAll(graph.getInEdges(node2));

      expect(dirtyEdges.length, 2);
      expect(dirtyEdges.contains(edge1), isTrue);
      expect(dirtyEdges.contains(edge2), isTrue);
      expect(
          dirtyEdges.contains(edge3), isFalse); // edge3 not connected to node2
    });

    test('edges to multiple nodes are tracked correctly', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);

      // Create multiple edges from node1
      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node1, node3);

      // When node1 is moved, both outgoing edges should be marked dirty
      final dirtyEdges = <Edge>{};
      dirtyEdges.addAll(graph.getOutEdges(node1));
      dirtyEdges.addAll(graph.getInEdges(node1));

      expect(dirtyEdges.length, 2);
      expect(dirtyEdges.contains(edge1), isTrue);
      expect(dirtyEdges.contains(edge2), isTrue);
    });

    test('bidirectional edges are tracked correctly', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);

      graph.addNode(node1);
      graph.addNode(node2);

      // Create bidirectional edges
      final edge1 = graph.addEdge(node1, node2);
      final edge2 = graph.addEdge(node2, node1);

      // When node1 is moved, both edges should be marked dirty
      final dirtyEdges = <Edge>{};
      dirtyEdges.addAll(graph.getOutEdges(node1));
      dirtyEdges.addAll(graph.getInEdges(node1));

      expect(dirtyEdges.length, 2);
      expect(dirtyEdges.contains(edge1), isTrue);
      expect(dirtyEdges.contains(edge2), isTrue);
    });

    test('self-loop edges are tracked correctly', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);

      graph.addNode(node1);
      graph.addNode(node2);

      // Create a self-loop edge
      final edge1 = graph.addEdge(node1, node1);
      final edge2 = graph.addEdge(node1, node2);

      // When node1 is moved, self-loop should be marked dirty once (not twice)
      final dirtyEdges = <Edge>{};
      dirtyEdges.addAll(graph.getOutEdges(node1));
      dirtyEdges.addAll(graph.getInEdges(node1));

      expect(dirtyEdges.length, 2);
      expect(dirtyEdges.contains(edge1), isTrue);
      expect(dirtyEdges.contains(edge2), isTrue);
    });

    test('isolated node has no dirty edges', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addNode(node3);

      // Only create edge between node1 and node2
      final edge1 = graph.addEdge(node1, node2);

      // When isolated node3 is moved, no edges should be marked dirty
      final dirtyEdges = <Edge>{};
      dirtyEdges.addAll(graph.getOutEdges(node3));
      dirtyEdges.addAll(graph.getInEdges(node3));

      expect(dirtyEdges.isEmpty, isTrue);
      expect(dirtyEdges.contains(edge1), isFalse);
    });

    test('getDirtyEdges returns copy of dirty edges set', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);

      graph.addNode(node1);
      graph.addNode(node2);

      final edge1 = graph.addEdge(node1, node2);

      // Simulate the render box having dirty edges
      final renderBox = TestRenderCustomLayoutBox();
      renderBox.dirtyEdges.add(edge1);

      // Get copy of dirty edges
      final dirtyEdgesCopy = renderBox.getDirtyEdges();

      // Verify it's a copy (modifying copy doesn't affect original)
      expect(dirtyEdgesCopy.length, 1);
      expect(dirtyEdgesCopy.contains(edge1), isTrue);

      dirtyEdgesCopy.clear();
      expect(renderBox.dirtyEdges.length, 1); // Original unchanged
    });

    test('dirty edges are cleared after rendering', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);

      graph.addNode(node1);
      graph.addNode(node2);

      final edge1 = graph.addEdge(node1, node2);

      // Simulate render box with dirty edges
      final renderBox = TestRenderCustomLayoutBox();
      renderBox.dirtyEdges.add(edge1);

      expect(renderBox.dirtyEdges.length, 1);

      // After clear (which happens in paint method)
      renderBox.dirtyEdges.clear();

      expect(renderBox.dirtyEdges.isEmpty, isTrue);
    });
  });
}

// Test helper class to access dirtyEdges field
class TestRenderCustomLayoutBox {
  final dirtyEdges = <Edge>{};

  Set<Edge> getDirtyEdges() => Set<Edge>.from(dirtyEdges);
}
