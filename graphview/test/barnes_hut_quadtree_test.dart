import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void main() {
  group('BarnesHutQuadtree', () {
    test('Empty quadtree is initially empty and a leaf', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));

      expect(quadtree.isEmpty, true);
      expect(quadtree.isLeaf, true);
      expect(quadtree.totalMass, equals(0.0));
      expect(quadtree.centerOfMass, equals(Offset.zero));
    });

    test('Insert single node into empty quadtree', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));
      final node = Node.Id(1);
      node.position = Offset(50, 50);

      final inserted = quadtree.insert(node);

      expect(inserted, true);
      expect(quadtree.isEmpty, false);
      expect(quadtree.isLeaf, true);
      expect(quadtree.totalMass, equals(1.0));
      expect(quadtree.centerOfMass, equals(Offset(50, 50)));
      expect(quadtree.node, equals(node));
    });

    test('Insert node outside bounds returns false', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));
      final node = Node.Id(1);
      node.position = Offset(150, 150);

      final inserted = quadtree.insert(node);

      expect(inserted, false);
      expect(quadtree.isEmpty, true);
      expect(quadtree.isLeaf, true);
      expect(quadtree.totalMass, equals(0.0));
    });

    test('Insert second node triggers subdivision', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));
      final node1 = Node.Id(1);
      node1.position = Offset(25, 25);
      final node2 = Node.Id(2);
      node2.position = Offset(75, 75);

      quadtree.insert(node1);
      quadtree.insert(node2);

      expect(quadtree.isLeaf, false);
      expect(quadtree.node, isNull);
      expect(quadtree.totalMass, equals(2.0));
      expect(quadtree.northWest, isNotNull);
      expect(quadtree.northEast, isNotNull);
      expect(quadtree.southWest, isNotNull);
      expect(quadtree.southEast, isNotNull);
    });

    test('Center of mass calculation for two nodes', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));
      final node1 = Node.Id(1);
      node1.position = Offset(20, 20);
      final node2 = Node.Id(2);
      node2.position = Offset(80, 80);

      quadtree.insert(node1);
      quadtree.insert(node2);

      // Center of mass should be at the midpoint: (20+80)/2 = 50, (20+80)/2 = 50
      expect(quadtree.centerOfMass.dx, closeTo(50.0, 0.01));
      expect(quadtree.centerOfMass.dy, closeTo(50.0, 0.01));
    });

    test('Center of mass calculation for multiple nodes', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));
      final node1 = Node.Id(1);
      node1.position = Offset(10, 10);
      final node2 = Node.Id(2);
      node2.position = Offset(90, 10);
      final node3 = Node.Id(3);
      node3.position = Offset(50, 90);

      quadtree.insert(node1);
      quadtree.insert(node2);
      quadtree.insert(node3);

      // Center of mass: x = (10+90+50)/3 = 50, y = (10+10+90)/3 = 36.67
      expect(quadtree.totalMass, equals(3.0));
      expect(quadtree.centerOfMass.dx, closeTo(50.0, 0.01));
      expect(quadtree.centerOfMass.dy, closeTo(36.67, 0.01));
    });

    test('Nodes are inserted into correct quadrants', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));
      final nodeNW = Node.Id(1);
      nodeNW.position = Offset(25, 25);
      final nodeNE = Node.Id(2);
      nodeNE.position = Offset(75, 25);
      final nodeSW = Node.Id(3);
      nodeSW.position = Offset(25, 75);
      final nodeSE = Node.Id(4);
      nodeSE.position = Offset(75, 75);

      quadtree.insert(nodeNW);
      quadtree.insert(nodeNE);
      quadtree.insert(nodeSW);
      quadtree.insert(nodeSE);

      expect(quadtree.northWest!.isEmpty, false);
      expect(quadtree.northEast!.isEmpty, false);
      expect(quadtree.southWest!.isEmpty, false);
      expect(quadtree.southEast!.isEmpty, false);
      expect(quadtree.totalMass, equals(4.0));
    });

    test('recalculateMassAndCenter for empty leaf returns zero', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));

      quadtree.recalculateMassAndCenter();

      expect(quadtree.totalMass, equals(0.0));
      expect(quadtree.centerOfMass, equals(Offset.zero));
    });

    test('recalculateMassAndCenter for single node leaf', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));
      final node = Node.Id(1);
      node.position = Offset(40, 60);

      quadtree.insert(node);
      quadtree.recalculateMassAndCenter();

      expect(quadtree.totalMass, equals(1.0));
      expect(quadtree.centerOfMass, equals(Offset(40, 60)));
    });

    test('recalculateMassAndCenter for subdivided tree', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));
      final node1 = Node.Id(1);
      node1.position = Offset(20, 20);
      final node2 = Node.Id(2);
      node2.position = Offset(80, 80);

      quadtree.insert(node1);
      quadtree.insert(node2);
      quadtree.recalculateMassAndCenter();

      expect(quadtree.totalMass, equals(2.0));
      expect(quadtree.centerOfMass.dx, closeTo(50.0, 0.01));
      expect(quadtree.centerOfMass.dy, closeTo(50.0, 0.01));
    });

    test('recalculateMassAndCenter produces same result as incremental updates',
        () {
      final quadtree1 = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 200, 200));
      final quadtree2 = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 200, 200));

      final nodes = [
        Node.Id(1)..position = Offset(30, 30),
        Node.Id(2)..position = Offset(150, 40),
        Node.Id(3)..position = Offset(50, 160),
        Node.Id(4)..position = Offset(170, 180),
        Node.Id(5)..position = Offset(100, 100),
      ];

      // Insert into both quadtrees
      for (final node in nodes) {
        quadtree1.insert(node);
        quadtree2.insert(node);
      }

      // Recalculate only quadtree2
      quadtree2.recalculateMassAndCenter();

      // Both should have the same total mass
      expect(quadtree1.totalMass, equals(quadtree2.totalMass));

      // Centers of mass should be close (allowing for floating point precision)
      expect(
          quadtree1.centerOfMass.dx, closeTo(quadtree2.centerOfMass.dx, 0.01));
      expect(
          quadtree1.centerOfMass.dy, closeTo(quadtree2.centerOfMass.dy, 0.01));
    });

    test('Insert many nodes at same location', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));

      // All nodes at the same position
      for (var i = 0; i < 10; i++) {
        final node = Node.Id(i);
        node.position = Offset(50, 50);
        quadtree.insert(node);
      }

      expect(quadtree.totalMass, equals(10.0));
      expect(quadtree.centerOfMass.dx, closeTo(50.0, 0.01));
      expect(quadtree.centerOfMass.dy, closeTo(50.0, 0.01));

      quadtree.recalculateMassAndCenter();

      expect(quadtree.totalMass, equals(10.0));
      expect(quadtree.centerOfMass.dx, closeTo(50.0, 0.01));
      expect(quadtree.centerOfMass.dy, closeTo(50.0, 0.01));
    });

    test('Boundary nodes are inserted correctly', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));

      // Test corner positions
      final topLeft = Node.Id(1);
      topLeft.position = Offset(0, 0);
      final topRight = Node.Id(2);
      topRight.position = Offset(99.9, 0);
      final bottomLeft = Node.Id(3);
      bottomLeft.position = Offset(0, 99.9);
      final bottomRight = Node.Id(4);
      bottomRight.position = Offset(99.9, 99.9);

      expect(quadtree.insert(topLeft), true);
      expect(quadtree.insert(topRight), true);
      expect(quadtree.insert(bottomLeft), true);
      expect(quadtree.insert(bottomRight), true);

      expect(quadtree.totalMass, equals(4.0));
    });

    test('Nodes on quadrant boundaries are not dropped', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));
      final node1 = Node.Id(1)..position = Offset(25, 25);
      final boundaryNode = Node.Id(2)..position = Offset(50, 50);

      expect(quadtree.insert(node1), true);
      expect(quadtree.insert(boundaryNode), true);

      quadtree.recalculateMassAndCenter();
      expect(quadtree.totalMass, equals(2.0));
    });

    test('Performance: Insert 1000 nodes completes quickly', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 1000, 1000));
      final nodes = <Node>[];

      // Create nodes in a grid pattern
      for (var i = 0; i < 1000; i++) {
        final node = Node.Id(i);
        node.position = Offset(
          (i % 100) * 10.0,
          (i ~/ 100) * 10.0,
        );
        nodes.add(node);
      }

      final stopwatch = Stopwatch()..start();
      for (final node in nodes) {
        quadtree.insert(node);
      }
      final timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Inserted ${nodes.length} nodes in $timeTaken ms');

      expect(timeTaken < 500, true);
      expect(quadtree.totalMass, equals(1000.0));
    });

    test('Performance: recalculateMassAndCenter for 1000 nodes', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 1000, 1000));

      // Insert 1000 nodes
      for (var i = 0; i < 1000; i++) {
        final node = Node.Id(i);
        node.position = Offset(
          (i % 100) * 10.0,
          (i ~/ 100) * 10.0,
        );
        quadtree.insert(node);
      }

      final stopwatch = Stopwatch()..start();
      quadtree.recalculateMassAndCenter();
      final timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Recalculated mass and center for 1000 nodes in $timeTaken ms');

      expect(timeTaken < 100, true);
      expect(quadtree.totalMass, equals(1000.0));
    });

    test('Deep subdivision with many nodes in small area', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));

      // Insert many nodes in a small region to create deep subdivision
      for (var i = 0; i < 20; i++) {
        final node = Node.Id(i);
        node.position = Offset(
          50 + i * 0.1,
          50 + i * 0.1,
        );
        quadtree.insert(node);
      }

      expect(quadtree.totalMass, equals(20.0));
      expect(quadtree.isLeaf, false);
    });

    test('Quadtree subdivision creates correct bounds', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));
      final node1 = Node.Id(1);
      node1.position = Offset(25, 25);
      final node2 = Node.Id(2);
      node2.position = Offset(75, 75);

      quadtree.insert(node1);
      quadtree.insert(node2);

      // Check that children have correct bounds
      expect(quadtree.northWest!.bounds, equals(Rect.fromLTWH(0, 0, 50, 50)));
      expect(quadtree.northEast!.bounds, equals(Rect.fromLTWH(50, 0, 50, 50)));
      expect(quadtree.southWest!.bounds, equals(Rect.fromLTWH(0, 50, 50, 50)));
      expect(quadtree.southEast!.bounds, equals(Rect.fromLTWH(50, 50, 50, 50)));
    });

    test('Center of mass for asymmetric distribution', () {
      final quadtree = BarnesHutQuadtree(Rect.fromLTWH(0, 0, 100, 100));

      // Three nodes in one quadrant, one in another
      final node1 = Node.Id(1);
      node1.position = Offset(10, 10);
      final node2 = Node.Id(2);
      node2.position = Offset(15, 15);
      final node3 = Node.Id(3);
      node3.position = Offset(12, 13);
      final node4 = Node.Id(4);
      node4.position = Offset(90, 90);

      quadtree.insert(node1);
      quadtree.insert(node2);
      quadtree.insert(node3);
      quadtree.insert(node4);

      // Center of mass should be weighted toward the cluster
      // x = (10 + 15 + 12 + 90) / 4 = 31.75
      // y = (10 + 15 + 13 + 90) / 4 = 32
      expect(quadtree.totalMass, equals(4.0));
      expect(quadtree.centerOfMass.dx, closeTo(31.75, 0.01));
      expect(quadtree.centerOfMass.dy, closeTo(32.0, 0.01));
    });
  });
}
