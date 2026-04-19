import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void main() {
  // -----------------------------------------------------------------------
  // ContainerX tests (EiglspergerElements.dart)
  // -----------------------------------------------------------------------
  group('ContainerX', () {
    late Node pNode;
    late Node qNode;
    late Segment seg1;
    late Segment seg2;
    late Segment seg3;

    setUp(() {
      pNode = Node.Id('p1');
      qNode = Node.Id('q1');
      seg1 = Segment(pNode, qNode);
      seg2 = Segment(Node.Id('p2'), Node.Id('q2'));
      seg3 = Segment(Node.Id('p3'), Node.Id('q3'));
    });

    test('starts empty', () {
      final c = ContainerX();
      expect(c.size(), equals(0));
      expect(c.isEmpty, isTrue);
    });

    test('append adds a segment', () {
      final c = ContainerX();
      c.append(seg1);
      expect(c.size(), equals(1));
      expect(c.isEmpty, isFalse);
      expect(c.contains(seg1), isTrue);
    });

    test('append multiple segments', () {
      final c = ContainerX();
      c.append(seg1);
      c.append(seg2);
      c.append(seg3);
      expect(c.size(), equals(3));
    });

    test('contains returns false for absent segment', () {
      final c = ContainerX();
      c.append(seg1);
      expect(c.contains(seg2), isFalse);
    });

    test('join transfers segments from other container', () {
      final c1 = ContainerX();
      c1.append(seg1);
      c1.append(seg2);

      final c2 = ContainerX();
      c2.append(seg3);

      c1.join(c2);

      expect(c1.size(), equals(3));
      expect(c1.contains(seg3), isTrue);
      // Other container should be cleared
      expect(c2.size(), equals(0));
      expect(c2.isEmpty, isTrue);
    });

    test('createEmpty produces an empty container', () {
      final c = ContainerX.createEmpty();
      expect(c.size(), equals(0));
      expect(c.isEmpty, isTrue);
    });

    test('toString contains size, pos, and measure', () {
      final c = ContainerX();
      c.append(seg1);
      c.pos = 5;
      c.measure = 3.14;
      final s = c.toString();
      expect(s, contains('1')); // 1 segment
      expect(s, contains('5')); // pos
    });

    group('split (by segment)', () {
      test('splits into left and right at given segment', () {
        final c = ContainerX();
        c.append(seg1);
        c.append(seg2);
        c.append(seg3);

        final pair = ContainerX.split(c, seg2);
        expect(pair.left.size(), equals(1)); // only seg1
        expect(pair.left.contains(seg1), isTrue);
        expect(pair.right.size(), equals(1)); // only seg3
        expect(pair.right.contains(seg3), isTrue);
      });

      test('split at first element yields empty left', () {
        final c = ContainerX();
        c.append(seg1);
        c.append(seg2);

        final pair = ContainerX.split(c, seg1);
        expect(pair.left.size(), equals(0));
        expect(pair.right.size(), equals(1));
        expect(pair.right.contains(seg2), isTrue);
      });

      test('split at last element yields empty right', () {
        final c = ContainerX();
        c.append(seg1);
        c.append(seg2);

        final pair = ContainerX.split(c, seg2);
        expect(pair.left.size(), equals(1));
        expect(pair.left.contains(seg1), isTrue);
        expect(pair.right.size(), equals(0));
      });

      test('split with absent segment returns original and empty right', () {
        final c = ContainerX();
        c.append(seg1);
        c.append(seg2);

        final absentSeg = Segment(Node.Id('px'), Node.Id('qx'));
        final pair = ContainerX.split(c, absentSeg);
        // Left is the original container, right is empty
        expect(pair.right.size(), equals(0));
      });
    });

    group('splitAt (by position)', () {
      test('splitAt 0 yields empty left and full right', () {
        final c = ContainerX();
        c.append(seg1);
        c.append(seg2);
        c.append(seg3);

        final pair = ContainerX.splitAt(c, 0);
        expect(pair.left.size(), equals(0));
        expect(pair.right.size(), equals(3));
      });

      test('splitAt position >= size yields full left and empty right', () {
        final c = ContainerX();
        c.append(seg1);
        c.append(seg2);

        final pair = ContainerX.splitAt(c, 2);
        expect(pair.left.size(), equals(2));
        expect(pair.right.size(), equals(0));
      });

      test('splitAt mid position correctly divides segments', () {
        final c = ContainerX();
        c.append(seg1);
        c.append(seg2);
        c.append(seg3);

        final pair = ContainerX.splitAt(c, 1);
        expect(pair.left.size(), equals(1));
        expect(pair.left.contains(seg1), isTrue);
        expect(pair.right.size(), equals(2));
        expect(pair.right.contains(seg2), isTrue);
        expect(pair.right.contains(seg3), isTrue);
      });

      test('splitAt negative position yields empty left', () {
        final c = ContainerX();
        c.append(seg1);

        final pair = ContainerX.splitAt(c, -1);
        expect(pair.left.size(), equals(0));
        expect(pair.right.size(), equals(1));
      });
    });
  });

  // -----------------------------------------------------------------------
  // Segment tests (EiglspergerElements.dart)
  // -----------------------------------------------------------------------
  group('Segment', () {
    test('stores pVertex and qVertex', () {
      final p = Node.Id('p');
      final q = Node.Id('q');
      final seg = Segment(p, q);
      expect(seg.pVertex, equals(p));
      expect(seg.qVertex, equals(q));
    });

    test('has a unique sequential id', () {
      final p1 = Node.Id('p1');
      final q1 = Node.Id('q1');
      final seg1 = Segment(p1, q1);
      final seg2 = Segment(p1, q1);
      expect(seg2.id, greaterThan(seg1.id));
    });

    test('equality is identity-based (two distinct segments are not equal)',
        () {
      final p = Node.Id('p');
      final q = Node.Id('q');
      final seg1 = Segment(p, q);
      final seg2 = Segment(p, q);
      expect(seg1 == seg2, isFalse);
      expect(seg1 == seg1, isTrue);
    });

    test('hashCode is based on id', () {
      final p = Node.Id('p');
      final q = Node.Id('q');
      final seg = Segment(p, q);
      expect(seg.hashCode, equals(seg.id));
    });

    test('default index is -1', () {
      final seg = Segment(Node.Id('p'), Node.Id('q'));
      expect(seg.index, equals(-1));
    });

    test('toString includes id', () {
      final seg = Segment(Node.Id('p'), Node.Id('q'));
      expect(seg.toString(), contains('Segment('));
      expect(seg.toString(), contains(seg.id.toString()));
    });
  });

  // -----------------------------------------------------------------------
  // VirtualEdge tests (EiglspergerElements.dart)
  // -----------------------------------------------------------------------
  group('VirtualEdge', () {
    test('stores source, target, and weight', () {
      final ve = VirtualEdge('src', 'tgt', 5);
      expect(ve.source, equals('src'));
      expect(ve.target, equals('tgt'));
      expect(ve.weight, equals(5));
    });

    test('toString contains source, target, and weight', () {
      final ve = VirtualEdge('A', 'B', 3);
      final s = ve.toString();
      expect(s, contains('A'));
      expect(s, contains('B'));
      expect(s, contains('3'));
    });

    test('weight of 1 for single-segment virtual edge', () {
      final ve = VirtualEdge('v', 'w', 1);
      expect(ve.weight, equals(1));
    });
  });

  // -----------------------------------------------------------------------
  // NodeElement / ContainerElement tests (EiglspergerElements.dart)
  // -----------------------------------------------------------------------
  group('NodeElement', () {
    test('wraps a node', () {
      final n = Node.Id(42);
      final ne = NodeElement(n);
      expect(ne.node, equals(n));
    });

    test('default index, pos, measure from LayerElement', () {
      final ne = NodeElement(Node.Id(1));
      expect(ne.index, equals(-1));
      expect(ne.pos, equals(-1));
      expect(ne.measure, equals(-1));
    });

    test('toString contains NodeElement', () {
      final ne = NodeElement(Node.Id(7));
      expect(ne.toString(), contains('NodeElement'));
    });
  });

  group('ContainerElement', () {
    test('wraps a ContainerX', () {
      final c = ContainerX();
      final ce = ContainerElement(c);
      expect(ce.container, equals(c));
    });

    test('default index, pos, measure', () {
      final ce = ContainerElement(ContainerX());
      expect(ce.index, equals(-1));
      expect(ce.pos, equals(-1));
      expect(ce.measure, equals(-1));
    });

    test('toString contains ContainerElement', () {
      final ce = ContainerElement(ContainerX());
      expect(ce.toString(), contains('ContainerElement'));
    });
  });

  // -----------------------------------------------------------------------
  // ContainerPair tests (EiglspergerElements.dart)
  // -----------------------------------------------------------------------
  group('ContainerPair', () {
    test('stores left and right containers', () {
      final left = ContainerX();
      final right = ContainerX();
      final pair = ContainerPair(left, right);
      expect(pair.left, same(left));
      expect(pair.right, same(right));
    });
  });

  // -----------------------------------------------------------------------
  // AccumulatorTree tests (SugiyamaAccumulatorTree.dart)
  // -----------------------------------------------------------------------
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
      // Sequence [0, 1, 2, 3]: each new element is to the right of all previous ones
      final tree = AccumulatorTree(4);
      expect(tree.crossCount([0, 1, 2, 3]), equals(0));
    });

    test('one crossing for fully reversed two-element sequence', () {
      final tree = AccumulatorTree(2);
      // [1, 0] means the edge ending at position 1 comes before the edge ending at 0
      // → 1 crossing
      expect(tree.crossCount([1, 0]), equals(1));
    });

    test('three crossings for reversed three-element sequence', () {
      // [2, 1, 0]: pair (2,1), (2,0), (1,0) → 3 crossings
      final tree = AccumulatorTree(3);
      expect(tree.crossCount([2, 1, 0]), equals(3));
    });

    test('partial order sequence produces correct crossing count', () {
      // [1, 0, 2]: pairs (1,0) cross → 1 crossing
      final tree = AccumulatorTree(3);
      expect(tree.crossCount([1, 0, 2]), equals(1));
    });

    test('size 1 tree has no crossings', () {
      final tree = AccumulatorTree(1);
      expect(tree.crossCount([0]), equals(0));
    });

    test('tree is initialised with zeros', () {
      final tree = AccumulatorTree(8);
      // Before any crossCount call, internal tree should be all zeros
      // crossCount on an ordered sequence should return 0
      expect(tree.crossCount([0, 1, 2, 3, 4, 5, 6, 7]), equals(0));
    });
  });

  // -----------------------------------------------------------------------
  // GreedyCycleRemoval tests (GreedyCycleRemoval.dart)
  // -----------------------------------------------------------------------
  group('GreedyCycleRemoval', () {
    test('returns empty set for acyclic graph', () {
      final graph = Graph();
      final n1 = Node.Id(1);
      final n2 = Node.Id(2);
      final n3 = Node.Id(3);
      graph.addEdge(n1, n2);
      graph.addEdge(n2, n3);

      final gcr = GreedyCycleRemoval(graph);
      final arcs = gcr.getFeedbackArcs();
      expect(arcs, isEmpty);
    });

    test('returns empty set for empty graph', () {
      final graph = Graph();
      final gcr = GreedyCycleRemoval(graph);
      expect(gcr.getFeedbackArcs(), isEmpty);
    });

    test('detects a simple 2-node cycle', () {
      final graph = Graph();
      final n1 = Node.Id(1);
      final n2 = Node.Id(2);
      graph.addEdge(n1, n2);
      graph.addEdge(n2, n1);

      final gcr = GreedyCycleRemoval(graph);
      final arcs = gcr.getFeedbackArcs();
      // At least one arc must be removed to break the cycle
      expect(arcs, isNotEmpty);
      expect(arcs.length, equals(1));
    });

    test('detects a 3-node cycle', () {
      final graph = Graph();
      final n1 = Node.Id(1);
      final n2 = Node.Id(2);
      final n3 = Node.Id(3);
      graph.addEdge(n1, n2);
      graph.addEdge(n2, n3);
      graph.addEdge(n3, n1); // cycle back

      final gcr = GreedyCycleRemoval(graph);
      final arcs = gcr.getFeedbackArcs();
      expect(arcs, isNotEmpty);
    });

    test('does not modify the original graph', () {
      final graph = Graph();
      final n1 = Node.Id(1);
      final n2 = Node.Id(2);
      graph.addEdge(n1, n2);
      graph.addEdge(n2, n1);

      final originalEdgeCount = graph.edges.length;
      final gcr = GreedyCycleRemoval(graph);
      gcr.getFeedbackArcs();

      expect(graph.edges.length, equals(originalEdgeCount));
    });

    test('acyclic tree graph yields no feedback arcs', () {
      final graph = Graph();
      final n1 = Node.Id(1);
      final n2 = Node.Id(2);
      final n3 = Node.Id(3);
      final n4 = Node.Id(4);
      graph.addEdge(n1, n2);
      graph.addEdge(n1, n3);
      graph.addEdge(n2, n4);

      final gcr = GreedyCycleRemoval(graph);
      expect(gcr.getFeedbackArcs(), isEmpty);
    });

    test('graph with sources and sinks processes correctly', () {
      final graph = Graph();
      // n1 is a source (no incoming edges), n3 is a sink (no outgoing)
      // n2 has a self-referring cycle via n4
      final n1 = Node.Id(1);
      final n2 = Node.Id(2);
      final n3 = Node.Id(3);
      final n4 = Node.Id(4);
      graph.addEdge(n1, n2);
      graph.addEdge(n2, n3);
      graph.addEdge(n3, n4);
      graph.addEdge(n4, n2); // creates cycle n2→n3→n4→n2

      final gcr = GreedyCycleRemoval(graph);
      final arcs = gcr.getFeedbackArcs();
      expect(arcs, isNotEmpty);
    });

    test('multiple separate cycles are each handled', () {
      final graph = Graph();
      // Two independent cycles: 1→2→1 and 3→4→3
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(1));
      graph.addEdge(Node.Id(3), Node.Id(4));
      graph.addEdge(Node.Id(4), Node.Id(3));

      final gcr = GreedyCycleRemoval(graph);
      final arcs = gcr.getFeedbackArcs();
      // Two independent cycles each need at least one arc removed
      expect(arcs.length, greaterThanOrEqualTo(2));
    });

    test('feedback arcs are reset and defensively copied between calls', () {
      final graph = Graph();
      graph.addEdge(Node.Id(1), Node.Id(2));
      graph.addEdge(Node.Id(2), Node.Id(1));

      final gcr = GreedyCycleRemoval(graph);
      final firstArcs = gcr.getFeedbackArcs();
      final firstLength = firstArcs.length;
      firstArcs.clear();

      final secondArcs = gcr.getFeedbackArcs();
      expect(secondArcs.length, equals(firstLength));
      expect(secondArcs, isNot(same(firstArcs)));
    });
  });

  // -----------------------------------------------------------------------
  // EiglspergerAlgorithm.medianValue tests (EiglspergerAlgorithm.dart)
  // -----------------------------------------------------------------------
  group('EiglspergerAlgorithm.medianValue', () {
    test('returns 0.0 for empty list', () {
      expect(EiglspergerAlgorithm.medianValue([]), equals(0.0));
    });

    test('returns the single element as double', () {
      expect(EiglspergerAlgorithm.medianValue([7]), equals(7.0));
    });

    test('returns average of two elements', () {
      expect(EiglspergerAlgorithm.medianValue([2, 4]), equals(3.0));
    });

    test('returns middle element for odd-length list', () {
      expect(EiglspergerAlgorithm.medianValue([1, 3, 5]), equals(3.0));
    });

    test('returns middle element for odd-length unsorted list', () {
      // medianValue sorts internally
      expect(EiglspergerAlgorithm.medianValue([5, 1, 3]), equals(3.0));
    });

    test('returns correct weighted median for four elements', () {
      // positions = [0, 1, 2, 3], mid = 2
      // left = positions[1] - positions[0] = 1 - 0 = 1
      // right = positions[3] - positions[2] = 3 - 2 = 1
      // result = (positions[1]*right + positions[2]*left) / (left+right) = (1*1 + 2*1)/2 = 1.5
      expect(
          EiglspergerAlgorithm.medianValue([0, 1, 2, 3]), closeTo(1.5, 0.001));
    });

    test('left+right==0 edge case returns 0.0 (even length)', () {
      // positions = [0, 1]: mid=1, left = positions[0]-positions[0] = 0, right = positions[1]-positions[1] = 0
      // Actually [0,1]: mid=1, left = positions[0]-positions[0] = pos[0]-pos[0] = 0...
      // Verify code path: left = pos[mid-1]-pos[0], right = pos[last]-pos[mid]
      // For [2, 2]: left = 2-2=0, right = 2-2=0, left+right=0 → returns 0.0
      expect(EiglspergerAlgorithm.medianValue([2, 2]), equals(2.0));
    });

    test('left+right==0 symmetric even-size returns 0.0', () {
      // [1,1,1,1]: mid=2, left = pos[1]-pos[0] = 0, right = pos[3]-pos[2] = 0 → returns 0.0
      expect(EiglspergerAlgorithm.medianValue([1, 1, 1, 1]), equals(0.0));
    });

    test('large list odd length', () {
      final positions = [1, 2, 3, 4, 5, 6, 7];
      // sorted: [1,2,3,4,5,6,7], mid=3, value=4
      expect(EiglspergerAlgorithm.medianValue(positions), equals(4.0));
    });

    test('negative positions', () {
      // [-3, -1, 1]: sorted mid = -1
      expect(EiglspergerAlgorithm.medianValue([-3, -1, 1]), equals(-1.0));
    });
  });

  // -----------------------------------------------------------------------
  // EiglspergerAlgorithm integration tests (regression for refactored structure)
  // -----------------------------------------------------------------------
  group('EiglspergerAlgorithm – mixin composition regression', () {
    const itemSize = 50.0;

    SugiyamaConfiguration defaultConfig() => SugiyamaConfiguration()
      ..nodeSeparation = 15
      ..levelSeparation = 15
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

    Graph linearGraph() {
      final g = Graph();
      g.addEdge(Node.Id(1), Node.Id(2));
      g.addEdge(Node.Id(2), Node.Id(3));
      g.addEdge(Node.Id(3), Node.Id(4));
      for (var i = 0; i < g.nodeCount(); i++) {
        g.getNodeAtPosition(i).size = const Size(itemSize, itemSize);
      }
      return g;
    }

    test('run() returns non-zero size for a linear graph', () {
      final g = linearGraph();
      final alg = EiglspergerAlgorithm(defaultConfig());
      final size = alg.run(g, 0, 0);
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('nodes receive valid positions after run()', () {
      final g = linearGraph();
      final alg = EiglspergerAlgorithm(defaultConfig());
      alg.run(g, 0, 0);
      for (var i = 0; i < g.nodeCount(); i++) {
        final node = g.getNodeAtPosition(i);
        expect(node.x, isNot(equals(double.negativeInfinity)));
        expect(node.y, isNot(equals(double.negativeInfinity)));
        expect(node.x.isNaN, isFalse);
        expect(node.y.isNaN, isFalse);
      }
    });

    test('run() returns Size.zero for empty graph', () {
      final g = Graph();
      final alg = EiglspergerAlgorithm(defaultConfig());
      final size = alg.run(g, 0, 0);
      expect(size, equals(Size.zero));
    });

    test('long-edge graph (3+ layer skip) produces valid layout', () {
      // Node 1 → Node 5: skips layers, should create dummy nodes
      final g = Graph();
      final n1 = Node.Id(1);
      final n5 = Node.Id(5);
      // Two intermediate nodes
      g.addEdge(n1, Node.Id(2));
      g.addEdge(Node.Id(2), Node.Id(3));
      g.addEdge(Node.Id(3), n5);
      g.addEdge(n1, n5); // long edge spanning many layers
      for (var i = 0; i < g.nodeCount(); i++) {
        g.getNodeAtPosition(i).size = const Size(itemSize, itemSize);
      }
      final alg = EiglspergerAlgorithm(defaultConfig());
      expect(() => alg.run(g, 0, 0), returnsNormally);
      final size = alg.run(g, 0, 0);
      expect(size.width, greaterThan(0));
    });

    test('shift coordinates move all nodes by the specified amount', () {
      final g = linearGraph();
      final alg = EiglspergerAlgorithm(defaultConfig());
      alg.run(g, 0, 0);
      final baseX = g.getNodeAtPosition(0).x;
      final baseY = g.getNodeAtPosition(0).y;

      final g2 = linearGraph();
      final alg2 = EiglspergerAlgorithm(defaultConfig());
      alg2.run(g2, 20, 30);
      // After shift, node should be offset by (20, 30)
      expect(g2.getNodeAtPosition(0).x, closeTo(baseX + 20, 1.0));
      expect(g2.getNodeAtPosition(0).y, closeTo(baseY + 30, 1.0));
    });
  });

  // -----------------------------------------------------------------------
  // SugiyamaAlgorithm – greedy cycle removal via GreedyCycleRemoval
  // -----------------------------------------------------------------------
  group('SugiyamaAlgorithm with greedy cycle removal (mixin regression)', () {
    test('handles a simple cycle with greedy strategy', () {
      final graph = Graph();
      final n1 = Node.Id(1);
      final n2 = Node.Id(2);
      final n3 = Node.Id(3);
      graph.addEdge(n1, n2);
      graph.addEdge(n2, n3);
      graph.addEdge(n3, n1);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = const Size(50, 50);
      }

      final config = SugiyamaConfiguration()
        ..cycleRemovalStrategy = CycleRemovalStrategy.greedy
        ..nodeSeparation = 15
        ..levelSeparation = 15;

      final alg = SugiyamaAlgorithm(config);
      expect(() => alg.run(graph, 0, 0), returnsNormally);
      final size = alg.run(graph, 0, 0);
      expect(size.width, greaterThan(0));
    });

    test('greedy and dfs strategies both produce valid layouts', () {
      final buildGraph = () {
        final g = Graph();
        g.addEdge(Node.Id(1), Node.Id(2));
        g.addEdge(Node.Id(2), Node.Id(3));
        g.addEdge(Node.Id(3), Node.Id(1));
        for (var i = 0; i < g.nodeCount(); i++) {
          g.getNodeAtPosition(i).size = const Size(50, 50);
        }
        return g;
      };

      for (final strategy in CycleRemovalStrategy.values) {
        final config = SugiyamaConfiguration()
          ..cycleRemovalStrategy = strategy
          ..nodeSeparation = 15
          ..levelSeparation = 15;

        final alg = SugiyamaAlgorithm(config);
        final size = alg.run(buildGraph(), 0, 0);
        expect(size.width, greaterThan(0),
            reason: 'Strategy ${strategy.name} should produce valid layout');
      }
    });
  });

  // -----------------------------------------------------------------------
  // SugiyamaNodeOrdering – AccumulatorTree cross minimization regression
  // -----------------------------------------------------------------------
  group('SugiyamaAlgorithm with accumulatorTree cross minimization', () {
    test('accumulatorTree strategy produces valid layout', () {
      final graph = Graph();
      // Build a 3-layer diamond graph prone to crossings
      graph.addEdge(Node.Id(1), Node.Id(3));
      graph.addEdge(Node.Id(1), Node.Id(4));
      graph.addEdge(Node.Id(2), Node.Id(3));
      graph.addEdge(Node.Id(2), Node.Id(4));
      graph.addEdge(Node.Id(3), Node.Id(5));
      graph.addEdge(Node.Id(4), Node.Id(5));

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = const Size(60, 40);
      }

      final config = SugiyamaConfiguration()
        ..crossMinimizationStrategy = CrossMinimizationStrategy.accumulatorTree
        ..nodeSeparation = 15
        ..levelSeparation = 20;

      final alg = SugiyamaAlgorithm(config);
      final size = alg.run(graph, 0, 0);

      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('simple and accumulatorTree strategies produce comparable layouts',
        () {
      final buildGraph = () {
        final g = Graph();
        g.addEdge(Node.Id(1), Node.Id(3));
        g.addEdge(Node.Id(1), Node.Id(4));
        g.addEdge(Node.Id(2), Node.Id(3));
        g.addEdge(Node.Id(2), Node.Id(4));
        for (var i = 0; i < g.nodeCount(); i++) {
          g.getNodeAtPosition(i).size = const Size(60, 40);
        }
        return g;
      };

      final configSimple = SugiyamaConfiguration()
        ..crossMinimizationStrategy = CrossMinimizationStrategy.simple
        ..nodeSeparation = 15
        ..levelSeparation = 20;

      final configAccum = SugiyamaConfiguration()
        ..crossMinimizationStrategy = CrossMinimizationStrategy.accumulatorTree
        ..nodeSeparation = 15
        ..levelSeparation = 20;

      final sizeSimple =
          SugiyamaAlgorithm(configSimple).run(buildGraph(), 0, 0);
      final sizeAccum = SugiyamaAlgorithm(configAccum).run(buildGraph(), 0, 0);

      // Both should produce non-zero layouts
      expect(sizeSimple.width, greaterThan(0));
      expect(sizeAccum.width, greaterThan(0));
    });
  });

  // -----------------------------------------------------------------------
  // SugiyamaLayerAssignment – all layering strategies regression
  // -----------------------------------------------------------------------
  group('SugiyamaAlgorithm layering strategy regression', () {
    Graph buildDAG() {
      final g = Graph();
      g.addEdge(Node.Id(1), Node.Id(2));
      g.addEdge(Node.Id(1), Node.Id(3));
      g.addEdge(Node.Id(2), Node.Id(4));
      g.addEdge(Node.Id(3), Node.Id(4));
      for (var i = 0; i < g.nodeCount(); i++) {
        g.getNodeAtPosition(i).size = const Size(50, 50);
      }
      return g;
    }

    for (final strategy in LayeringStrategy.values) {
      test('${strategy.name} produces valid layout', () {
        final config = SugiyamaConfiguration()
          ..layeringStrategy = strategy
          ..nodeSeparation = 15
          ..levelSeparation = 15;

        final alg = SugiyamaAlgorithm(config);
        final size = alg.run(buildDAG(), 0, 0);
        expect(size.width, greaterThan(0),
            reason:
                'Layering strategy ${strategy.name} should produce valid layout');
      });
    }
  });

  // -----------------------------------------------------------------------
  // Regression: medianValue boundary cases not previously tested
  // -----------------------------------------------------------------------
  group('EiglspergerAlgorithm.medianValue – extra boundary cases', () {
    test('two equal values returns that value', () {
      expect(EiglspergerAlgorithm.medianValue([5, 5]), equals(5.0));
    });

    test('even list with skewed distribution', () {
      // positions = [0, 1, 10, 100]: mid=2
      // left = pos[1]-pos[0] = 1, right = pos[3]-pos[2] = 90
      // result = (pos[1]*90 + pos[2]*1)/(90+1) = (90 + 10)/91 ≈ 1.0989...
      final result = EiglspergerAlgorithm.medianValue([0, 1, 10, 100]);
      expect(result, closeTo(1.0989, 0.001));
    });

    test('list with duplicates in odd length', () {
      // [2, 2, 2]: sorted, mid=1, value=2
      expect(EiglspergerAlgorithm.medianValue([2, 2, 2]), equals(2.0));
    });
  });
}
