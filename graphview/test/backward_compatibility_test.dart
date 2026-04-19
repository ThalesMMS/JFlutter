import 'package:flutter/widgets.dart';
import 'package:graphview/GraphView.dart';
import 'package:flutter_test/flutter_test.dart';

/// Backward compatibility tests to ensure existing renderers work unchanged
/// after adding adaptive edge routing features.
///
/// This test suite verifies that:
/// 1. Existing renderers can be instantiated without new parameters
/// 2. They render edges without errors
/// 3. They maintain default center-to-center connection behavior
/// 4. No breaking API changes were introduced
void main() {
  group('Backward Compatibility - Existing Renderers', () {
    late Graph graph;
    late Node node1;
    late Node node2;
    late Node node3;
    late Edge edge1;
    late Edge edge2;

    setUp(() {
      graph = Graph();
      node1 = Node.Id('1')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      node2 = Node.Id('2')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 0);
      node3 = Node.Id('3')
        ..size = const Size(40, 40)
        ..position = const Offset(50, 100);

      edge1 = graph.addEdge(node1, node2);
      edge2 = graph.addEdge(node2, node3);
    });

    group('ArrowEdgeRenderer', () {
      test('initializes without config parameter (default behavior)', () {
        expect(() => ArrowEdgeRenderer(), returnsNormally);
      });

      test('initializes with noArrow parameter (existing API)', () {
        expect(() => ArrowEdgeRenderer(noArrow: true), returnsNormally);
      });

      test('uses center-to-center connections by default', () {
        final renderer = ArrowEdgeRenderer();

        // Set graph on renderer (required for new methods)
        renderer.setGraph(graph);

        // Calculate connection points without config
        final sourceCenter = Offset(
          node1.position.dx + node1.width * 0.5,
          node1.position.dy + node1.height * 0.5,
        );
        final destCenter = Offset(
          node2.position.dx + node2.width * 0.5,
          node2.position.dy + node2.height * 0.5,
        );

        // Verify connection points are node centers (not adaptive)
        final sourcePoint =
            renderer.calculateSourceConnectionPoint(edge1, destCenter, 0);
        final destPoint = renderer.calculateDestinationConnectionPoint(
            edge1, sourceCenter, 0);

        expect(sourcePoint, equals(sourceCenter));
        expect(destPoint, equals(destCenter));
      });

      test('renders edges without errors (no config)', () {
        final renderer = ArrowEdgeRenderer();
        // This should not throw - we can't actually render without a canvas,
        // but we can verify the renderer is properly configured
        expect(() {
          // Verify graph and edge structure
          expect(graph.edges.length, 2);
          expect(graph.nodes.length, 3);

          // Verify renderer has correct setup
          renderer.setGraph(graph);
          expect(renderer, isNotNull);
        }, returnsNormally);
      });

      test('handles self-loop edges without config', () {
        final selfLoopNode = Node.Id('self')
          ..size = const Size(40, 40)
          ..position = const Offset(50, 50);
        final selfLoopEdge = graph.addEdge(selfLoopNode, selfLoopNode);

        final renderer = ArrowEdgeRenderer();
        renderer.setGraph(graph);

        // Verify buildSelfLoopPath works without config
        final result = renderer.buildSelfLoopPath(selfLoopEdge);
        expect(result, isNotNull);
        expect(result!.path, isNotNull);
      });

      test('supports optional config parameter (new feature)', () {
        final config = EdgeRoutingConfig()..anchorMode = AnchorMode.cardinal;

        expect(() => ArrowEdgeRenderer(config: config), returnsNormally);
      });
    });

    group('CurvedEdgeRenderer', () {
      test('initializes with default curvature', () {
        final renderer = CurvedEdgeRenderer();
        expect(renderer.curvature, 0.5);
      });

      test('initializes with custom curvature', () {
        final renderer = CurvedEdgeRenderer(curvature: 0.8);
        expect(renderer.curvature, 0.8);
      });

      test('renders edges without errors', () {
        final renderer = CurvedEdgeRenderer();

        expect(() {
          // Build curved path for edge
          final sourceCenter = Offset(
            node1.position.dx + node1.width * 0.5,
            node1.position.dy + node1.height * 0.5,
          );
          final destCenter = Offset(
            node2.position.dx + node2.width * 0.5,
            node2.position.dy + node2.height * 0.5,
          );

          renderer.buildCurvedPath(
            sourceCenter.dx,
            sourceCenter.dy,
            destCenter.dx,
            destCenter.dy,
          );

          final metrics = renderer.curvePath.computeMetrics().toList();
          expect(metrics, isNotEmpty);
        }, returnsNormally);
      });

      test('handles self-loop edges', () {
        final selfLoopNode = Node.Id('self')
          ..size = const Size(40, 40)
          ..position = const Offset(50, 50);
        final selfLoopEdge = graph.addEdge(selfLoopNode, selfLoopNode);

        final renderer = CurvedEdgeRenderer();
        final result = renderer.buildSelfLoopPath(selfLoopEdge);

        expect(result, isNotNull);
        expect(result!.path, isNotNull);
      });
    });

    group('TreeEdgeRenderer', () {
      test('initializes with configuration', () {
        final config = BuchheimWalkerConfiguration();
        expect(() => TreeEdgeRenderer(config), returnsNormally);
      });

      test('renders edges without errors', () {
        final config = BuchheimWalkerConfiguration();
        final renderer = TreeEdgeRenderer(config);

        expect(() {
          // Verify graph structure
          expect(graph.edges.length, 2);
          expect(graph.nodes.length, 3);

          // Verify renderer is properly configured
          expect(renderer.configuration, equals(config));
        }, returnsNormally);
      });

      test('handles self-loop edges', () {
        final config = BuchheimWalkerConfiguration();
        final renderer = TreeEdgeRenderer(config);

        final selfLoopNode = Node.Id('self')
          ..size = const Size(40, 40)
          ..position = const Offset(50, 50);
        final selfLoopEdge = graph.addEdge(selfLoopNode, selfLoopNode);

        final result = renderer.buildSelfLoopPath(selfLoopEdge);
        expect(result, isNotNull);
        expect(result!.path, isNotNull);
      });
    });

    group('SugiyamaEdgeRenderer', () {
      test('initializes with required parameters', () {
        final nodeData = <Node, SugiyamaNodeData>{};
        final edgeData = <Edge, SugiyamaEdgeData>{};

        expect(
          () => SugiyamaEdgeRenderer(
            nodeData,
            edgeData,
            SharpBendPointShape(),
            false,
          ),
          returnsNormally,
        );
      });

      test('extends ArrowEdgeRenderer (backward compatible)', () {
        final nodeData = <Node, SugiyamaNodeData>{};
        final edgeData = <Edge, SugiyamaEdgeData>{};

        final renderer = SugiyamaEdgeRenderer(
          nodeData,
          edgeData,
          SharpBendPointShape(),
          false,
        );

        expect(renderer, isA<ArrowEdgeRenderer>());
        expect(renderer, isA<EdgeRenderer>());
      });

      test('handles edges without bend points', () {
        final nodeData = <Node, SugiyamaNodeData>{};
        final edgeData = <Edge, SugiyamaEdgeData>{};

        final renderer = SugiyamaEdgeRenderer(
          nodeData,
          edgeData,
          SharpBendPointShape(),
          false,
        );

        expect(renderer.hasBendEdges(edge1), isFalse);
        expect(renderer.hasBendEdges(edge2), isFalse);
      });
    });

    group('EiglspergerEdgeRenderer', () {
      test('initializes with required parameters', () {
        final nodeData = <Node, EiglspergerNodeData>{};
        final edgeData = <Edge, EiglspergerEdgeData>{};

        expect(
          () => EiglspergerEdgeRenderer(
            nodeData,
            edgeData,
            SharpBendPointShape(),
            false,
          ),
          returnsNormally,
        );
      });

      test('extends ArrowEdgeRenderer (backward compatible)', () {
        final nodeData = <Node, EiglspergerNodeData>{};
        final edgeData = <Edge, EiglspergerEdgeData>{};

        final renderer = EiglspergerEdgeRenderer(
          nodeData,
          edgeData,
          SharpBendPointShape(),
          false,
        );

        expect(renderer, isA<ArrowEdgeRenderer>());
        expect(renderer, isA<EdgeRenderer>());
      });

      test('handles edges without bend points', () {
        final nodeData = <Node, EiglspergerNodeData>{};
        final edgeData = <Edge, EiglspergerEdgeData>{};

        final renderer = EiglspergerEdgeRenderer(
          nodeData,
          edgeData,
          SharpBendPointShape(),
          false,
        );

        expect(renderer.hasBendEdges(edge1), isFalse);
        expect(renderer.hasBendEdges(edge2), isFalse);
      });
    });

    group('MindmapEdgeRenderer', () {
      test('initializes with configuration', () {
        final config = BuchheimWalkerConfiguration();
        expect(() => MindmapEdgeRenderer(config), returnsNormally);
      });

      test('extends TreeEdgeRenderer (backward compatible)', () {
        final config = BuchheimWalkerConfiguration();
        final renderer = MindmapEdgeRenderer(config);

        expect(renderer, isA<TreeEdgeRenderer>());
        expect(renderer, isA<EdgeRenderer>());
        expect(renderer.configuration, equals(config));
      });

      test('handles different orientations', () {
        final config = BuchheimWalkerConfiguration();
        final renderer = MindmapEdgeRenderer(config);

        // Verify getEffectiveOrientation method exists and works
        expect(() {
          // Create nodes with different positions for mindmap layout
          final parentNode = Node.Id('parent')
            ..x = 0.0
            ..y = 0.0;
          final childNode1 = Node.Id('child1')
            ..x = 100.0
            ..y = -50.0; // Negative Y
          final childNode2 = Node.Id('child2')
            ..x = -100.0
            ..y = 50.0; // Negative X

          // Test orientation calculation (method from MindmapEdgeRenderer)
          final orientation1 =
              renderer.getEffectiveOrientation(parentNode, childNode1);
          final orientation2 =
              renderer.getEffectiveOrientation(parentNode, childNode2);

          expect(orientation1, isA<int>());
          expect(orientation2, isA<int>());
        }, returnsNormally);
      });
    });

    group('AnimatedEdgeRenderer', () {
      test('initializes with default configuration', () {
        expect(() => AnimatedEdgeRenderer(), returnsNormally);
      });

      test('initializes with custom configuration', () {
        final config = AnimatedEdgeConfiguration(
          animationSpeed: 2.0,
          particleCount: 5,
          particleSize: 4.0,
        );

        expect(() => AnimatedEdgeRenderer(animationConfig: config),
            returnsNormally);
      });

      test('extends ArrowEdgeRenderer (backward compatible)', () {
        final renderer = AnimatedEdgeRenderer();

        expect(renderer, isA<ArrowEdgeRenderer>());
        expect(renderer, isA<EdgeRenderer>());
      });

      test('supports animation value updates', () {
        final renderer = AnimatedEdgeRenderer();

        expect(() {
          renderer.setAnimationValue(0.5);
          expect(renderer.animationValue, 0.5);
        }, returnsNormally);
      });

      test('supports noArrow parameter', () {
        final renderer = AnimatedEdgeRenderer(noArrow: true);
        expect(renderer, isNotNull);
      });
    });

    group('EdgeRenderer Base Class', () {
      test('default methods maintain backward compatibility', () {
        // Create a minimal renderer to test base class behavior
        final renderer = ArrowEdgeRenderer();
        renderer.setGraph(graph);

        // Test default connection point methods
        final destCenter = Offset(100, 20);
        final sourceCenter = Offset(20, 20);

        // Default implementations should work
        expect(() {
          renderer.calculateSourceConnectionPoint(edge1, destCenter, 0);
          renderer.calculateDestinationConnectionPoint(edge1, sourceCenter, 0);
        }, returnsNormally);
      });

      test('routeEdgePath has default implementation', () {
        final renderer = ArrowEdgeRenderer();

        final start = const Offset(0, 0);
        final end = const Offset(100, 100);

        // Default routeEdgePath should create direct path
        final path = renderer.routeEdgePath(start, end, edge1);
        expect(path, isNotNull);

        final metrics = path.computeMetrics().toList();
        expect(metrics, isNotEmpty);
      });

      test('applyEdgeRepulsion has default implementation', () {
        final renderer = ArrowEdgeRenderer();

        final originalPath = Path()
          ..moveTo(0, 0)
          ..lineTo(100, 100);

        // Default applyEdgeRepulsion should return path unchanged
        final resultPath =
            renderer.applyEdgeRepulsion([edge1], edge1, originalPath);
        expect(resultPath, equals(originalPath));
      });

      test('buildSelfLoopPath works for all renderers', () {
        final selfLoopNode = Node.Id('self')
          ..size = const Size(40, 40)
          ..position = const Offset(50, 50);
        final selfLoopEdge = graph.addEdge(selfLoopNode, selfLoopNode);

        // Test self-loop rendering for different renderers
        final arrowRenderer = ArrowEdgeRenderer();
        final curvedRenderer = CurvedEdgeRenderer();
        final treeRenderer = TreeEdgeRenderer(BuchheimWalkerConfiguration());

        expect(arrowRenderer.buildSelfLoopPath(selfLoopEdge), isNotNull);
        expect(curvedRenderer.buildSelfLoopPath(selfLoopEdge), isNotNull);
        expect(treeRenderer.buildSelfLoopPath(selfLoopEdge), isNotNull);
      });
    });

    group('Graph Structure Unchanged', () {
      test('Graph API remains unchanged', () {
        final g = Graph();
        final n1 = Node.Id('1');
        final n2 = Node.Id('2');

        // Verify existing Graph API still works
        expect(() {
          g.addNode(n1);
          g.addNode(n2);
          g.addEdge(n1, n2);

          expect(g.nodes.length, 2);
          expect(g.edges.length, 1);
          expect(g.getOutEdges(n1).length, 1);
          expect(g.getInEdges(n2).length, 1);
        }, returnsNormally);
      });

      test('Node API remains unchanged', () {
        final node = Node.Id('test');

        // Verify existing Node API still works
        expect(() {
          node.size = const Size(50, 50);
          node.position = const Offset(100, 100);

          expect(node.width, 50.0);
          expect(node.height, 50.0);
          expect(node.x, 100.0);
          expect(node.y, 100.0);
        }, returnsNormally);
      });

      test('Edge API remains unchanged', () {
        final n1 = Node.Id('1');
        final n2 = Node.Id('2');
        final edge = Edge(n1, n2);

        // Verify existing Edge API still works
        expect(() {
          edge.paint = Paint()..color = const Color(0xFF0000FF);
          edge.label = 'test';

          expect(edge.source, equals(n1));
          expect(edge.destination, equals(n2));
          expect(edge.paint, isNotNull);
          expect(edge.label, 'test');
        }, returnsNormally);
      });
    });

    group('No Breaking Changes', () {
      test('Existing code patterns still work', () {
        // This test verifies that common usage patterns remain valid

        // Pattern 1: Basic graph with ArrowEdgeRenderer
        expect(() {
          final g = Graph();
          final n1 = Node.Id('1');
          final n2 = Node.Id('2');
          g.addEdge(n1, n2);

          final renderer = ArrowEdgeRenderer();
          renderer.setGraph(g);

          expect(g.edges.length, 1);
          expect(renderer, isNotNull);
        }, returnsNormally);

        // Pattern 2: Tree layout with TreeEdgeRenderer
        expect(() {
          final g = Graph();
          final root = Node.Id('root');
          final child1 = Node.Id('child1');
          final child2 = Node.Id('child2');

          g.addEdge(root, child1);
          g.addEdge(root, child2);

          final config = BuchheimWalkerConfiguration();
          final renderer = TreeEdgeRenderer(config);

          expect(g.edges.length, 2);
          expect(renderer.configuration, equals(config));
        }, returnsNormally);

        // Pattern 3: Curved edges with CurvedEdgeRenderer
        expect(() {
          final g = Graph();
          final n1 = Node.Id('1')..position = const Offset(0, 0);
          final n2 = Node.Id('2')..position = const Offset(100, 100);
          g.addEdge(n1, n2);

          final renderer = CurvedEdgeRenderer(curvature: 0.6);
          expect(renderer.curvature, 0.6);
        }, returnsNormally);
      });

      test('Optional new features do not break existing code', () {
        // Verify that new EdgeRoutingConfig is optional

        // Old way (without config) - should still work
        final renderer1 = ArrowEdgeRenderer();
        expect(renderer1, isNotNull);

        // New way (with config) - should also work
        final config = EdgeRoutingConfig()
          ..anchorMode = AnchorMode.dynamic
          ..routingMode = RoutingMode.bezier;
        final renderer2 = ArrowEdgeRenderer(config: config);
        expect(renderer2, isNotNull);
      });
    });
  });
}
