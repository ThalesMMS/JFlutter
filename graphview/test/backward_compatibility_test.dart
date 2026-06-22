import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void main() {
  group('Backward compatibility - retained renderers', () {
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
      test('initializes without config parameter', () {
        expect(() => ArrowEdgeRenderer(), returnsNormally);
      });

      test('initializes with noArrow parameter', () {
        expect(() => ArrowEdgeRenderer(noArrow: true), returnsNormally);
      });

      test('uses center-to-center connections by default', () {
        final renderer = ArrowEdgeRenderer()..setGraph(graph);
        final sourceCenter = Offset(
          node1.position.dx + node1.width * 0.5,
          node1.position.dy + node1.height * 0.5,
        );
        final destinationCenter = Offset(
          node2.position.dx + node2.width * 0.5,
          node2.position.dy + node2.height * 0.5,
        );

        expect(
          renderer.calculateSourceConnectionPoint(edge1, destinationCenter, 0),
          equals(sourceCenter),
        );
        expect(
          renderer.calculateDestinationConnectionPoint(edge1, sourceCenter, 0),
          equals(destinationCenter),
        );
      });

      test('handles self-loop edges without config', () {
        final selfLoopNode = Node.Id('self')
          ..size = const Size(40, 40)
          ..position = const Offset(50, 50);
        final selfLoopEdge = graph.addEdge(selfLoopNode, selfLoopNode);
        final renderer = ArrowEdgeRenderer()..setGraph(graph);

        final result = renderer.buildSelfLoopPath(selfLoopEdge);

        expect(result, isNotNull);
        expect(result!.path, isNotNull);
      });

      test('supports optional routing config', () {
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

      test('builds a curved path', () {
        final renderer = CurvedEdgeRenderer();

        renderer.buildCurvedPath(0, 0, 100, 100);

        expect(renderer.curvePath.computeMetrics().toList(), isNotEmpty);
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

      test('extends ArrowEdgeRenderer', () {
        final renderer = SugiyamaEdgeRenderer(
          <Node, SugiyamaNodeData>{},
          <Edge, SugiyamaEdgeData>{},
          SharpBendPointShape(),
          false,
        );

        expect(renderer, isA<ArrowEdgeRenderer>());
        expect(renderer, isA<EdgeRenderer>());
      });

      test('handles edges without bend points', () {
        final renderer = SugiyamaEdgeRenderer(
          <Node, SugiyamaNodeData>{},
          <Edge, SugiyamaEdgeData>{},
          SharpBendPointShape(),
          false,
        );

        expect(renderer.hasBendEdges(edge1), isFalse);
        expect(renderer.hasBendEdges(edge2), isFalse);
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

        expect(
          () => AnimatedEdgeRenderer(animationConfig: config),
          returnsNormally,
        );
      });

      test('extends ArrowEdgeRenderer', () {
        final renderer = AnimatedEdgeRenderer();

        expect(renderer, isA<ArrowEdgeRenderer>());
        expect(renderer, isA<EdgeRenderer>());
      });

      test('supports animation value updates', () {
        final renderer = AnimatedEdgeRenderer();

        renderer.setAnimationValue(0.5);

        expect(renderer.animationValue, 0.5);
      });

      test('supports noArrow parameter', () {
        final renderer = AnimatedEdgeRenderer(noArrow: true);
        expect(renderer, isNotNull);
      });
    });

    group('AdaptiveEdgeRenderer', () {
      test('initializes with routing config', () {
        final config = EdgeRoutingConfig()
          ..anchorMode = AnchorMode.dynamic
          ..routingMode = RoutingMode.bezier;

        expect(
          () => AdaptiveEdgeRenderer(config: config),
          returnsNormally,
        );
      });
    });

    group('EdgeRenderer base class', () {
      test('default connection point methods work', () {
        final renderer = ArrowEdgeRenderer()..setGraph(graph);

        expect(() {
          renderer.calculateSourceConnectionPoint(
              edge1, const Offset(100, 20), 0);
          renderer.calculateDestinationConnectionPoint(
              edge1, const Offset(20, 20), 0);
        }, returnsNormally);
      });

      test('routeEdgePath creates a direct path', () {
        final renderer = ArrowEdgeRenderer();

        final path = renderer.routeEdgePath(
            const Offset(0, 0), const Offset(100, 100), edge1);

        expect(path.computeMetrics().toList(), isNotEmpty);
      });

      test('applyEdgeRepulsion returns the path unchanged by default', () {
        final renderer = ArrowEdgeRenderer();
        final originalPath = Path()
          ..moveTo(0, 0)
          ..lineTo(100, 100);

        final resultPath =
            renderer.applyEdgeRepulsion([edge1], edge1, originalPath);

        expect(resultPath, equals(originalPath));
      });

      test('buildSelfLoopPath works for retained renderers', () {
        final selfLoopNode = Node.Id('self')
          ..size = const Size(40, 40)
          ..position = const Offset(50, 50);
        final selfLoopEdge = graph.addEdge(selfLoopNode, selfLoopNode);

        expect(ArrowEdgeRenderer().buildSelfLoopPath(selfLoopEdge), isNotNull);
        expect(CurvedEdgeRenderer().buildSelfLoopPath(selfLoopEdge), isNotNull);
      });
    });
  });

  group('Graph structures', () {
    test('Graph API remains unchanged', () {
      final graph = Graph();
      final node1 = Node.Id('1');
      final node2 = Node.Id('2');

      graph.addNode(node1);
      graph.addNode(node2);
      graph.addEdge(node1, node2);

      expect(graph.nodes.length, 2);
      expect(graph.edges.length, 1);
      expect(graph.getOutEdges(node1).length, 1);
      expect(graph.getInEdges(node2).length, 1);
    });

    test('Node API remains unchanged', () {
      final node = Node.Id('test');

      node.size = const Size(50, 50);
      node.position = const Offset(100, 100);

      expect(node.width, 50.0);
      expect(node.height, 50.0);
      expect(node.x, 100.0);
      expect(node.y, 100.0);
    });

    test('Edge API remains unchanged', () {
      final node1 = Node.Id('1');
      final node2 = Node.Id('2');
      final edge = Edge(node1, node2);

      edge.paint = Paint()..color = const Color(0xFF0000FF);
      edge.label = 'test';

      expect(edge.source, equals(node1));
      expect(edge.destination, equals(node2));
      expect(edge.paint, isNotNull);
      expect(edge.label, 'test');
    });
  });

  group('Retained usage patterns', () {
    test('basic graph with ArrowEdgeRenderer still works', () {
      final graph = Graph();
      final node1 = Node.Id('1');
      final node2 = Node.Id('2');
      graph.addEdge(node1, node2);

      final renderer = ArrowEdgeRenderer()..setGraph(graph);

      expect(graph.edges.length, 1);
      expect(renderer, isNotNull);
    });

    test('Sugiyama layout still works', () {
      final graph = Graph();
      final root = Node.Id('root')..size = const Size(40, 40);
      final child1 = Node.Id('child1')..size = const Size(40, 40);
      final child2 = Node.Id('child2')..size = const Size(40, 40);
      graph.addEdge(root, child1);
      graph.addEdge(root, child2);

      final config = SugiyamaConfiguration();
      final algorithm = SugiyamaAlgorithm(config);
      final size = algorithm.run(graph, 0, 0);

      expect(algorithm.configuration, same(config));
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('curved edges with CurvedEdgeRenderer still work', () {
      final renderer = CurvedEdgeRenderer(curvature: 0.6);

      expect(renderer.curvature, 0.6);
    });
  });
}
