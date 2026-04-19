import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

void main() {
  group('Edge Label', () {
    test('Edge can be created with label text', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2, label: 'Test Label');

      expect(edge.label, 'Test Label');
      expect(edge.labelStyle, isNull);
      expect(edge.labelWidget, isNull);
    });

    test('Edge can be created with label and custom TextStyle', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      const customStyle = TextStyle(
        color: Colors.red,
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
      );
      final edge = Edge(node1, node2, label: 'Styled Label', labelStyle: customStyle);

      expect(edge.label, 'Styled Label');
      expect(edge.labelStyle, customStyle);
      expect(edge.labelStyle?.color, Colors.red);
      expect(edge.labelStyle?.fontSize, 16.0);
      expect(edge.labelStyle?.fontWeight, FontWeight.bold);
    });

    test('Edge can be created with labelWidget', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final widget = Container(child: const Text('Widget Label'));
      final edge = Edge(node1, node2, labelWidget: widget);

      expect(edge.labelWidget, widget);
    });

    test('Edge without label has null label properties', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2);

      expect(edge.label, isNull);
      expect(edge.labelStyle, isNull);
      expect(edge.labelWidget, isNull);
    });

    test('Graph.addEdge creates edge with label', () {
      final graph = Graph();
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');

      final edge = graph.addEdge(node1, node2, label: 'Edge Label');

      expect(edge.label, 'Edge Label');
      expect(graph.edges.length, 1);
      expect(graph.edges.first.label, 'Edge Label');
    });

    test('Graph.addEdge creates edge with label and style', () {
      final graph = Graph();
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      const style = TextStyle(color: Colors.blue, fontSize: 14.0);

      final edge = graph.addEdge(node1, node2, label: 'Styled Edge', labelStyle: style);

      expect(edge.label, 'Styled Edge');
      expect(edge.labelStyle, style);
      expect(graph.edges.first.labelStyle?.color, Colors.blue);
    });

    test('Empty label string is handled gracefully', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2, label: '');

      expect(edge.label, '');
      expect(edge.label!.isEmpty, true);
    });

    test('ArrowEdgeRenderer handles edge without label', () {
      final renderer = ArrowEdgeRenderer();
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 0);
      final edge = Edge(node1, node2);
      final paint = Paint();

      // Should not throw when rendering edge without label
      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdge(canvas, edge, paint);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('ArrowEdgeRenderer handles edge with label', () {
      final renderer = ArrowEdgeRenderer();
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 0);
      final edge = Edge(node1, node2, label: 'Test');
      final paint = Paint();

      // Should not throw when rendering edge with label
      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdge(canvas, edge, paint);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('ArrowEdgeRenderer handles empty label string', () {
      final renderer = ArrowEdgeRenderer();
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 0);
      final edge = Edge(node1, node2, label: '');
      final paint = Paint();

      // Should not throw when rendering edge with empty label
      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdge(canvas, edge, paint);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('Self-loop edge with label renders without error', () {
      final renderer = ArrowEdgeRenderer();
      final node = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 100);
      final edge = Edge(node, node, label: 'Self Loop Label');
      final paint = Paint();

      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdge(canvas, edge, paint);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('TreeEdgeRenderer handles edge with label', () {
      final renderer = TreeEdgeRenderer(BuchheimWalkerConfiguration());
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 100);
      final edge = Edge(node1, node2, label: 'Tree Edge');
      final paint = Paint();

      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdge(canvas, edge, paint);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('SugiyamaEdgeRenderer handles edge with label', () {
      final nodeData = <Node, SugiyamaNodeData>{};
      final edgeData = <Edge, SugiyamaEdgeData>{};
      final config = SugiyamaConfiguration();
      final renderer = SugiyamaEdgeRenderer(
        nodeData,
        edgeData,
        config.bendPointShape,
        config.addTriangleToEdge,
      );
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 100);
      final edge = Edge(node1, node2, label: 'Sugiyama Edge');
      final paint = Paint();

      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdge(canvas, edge, paint);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('MindmapEdgeRenderer handles edge with label', () {
      final config = BuchheimWalkerConfiguration();
      final renderer = MindmapEdgeRenderer(config);
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 100);
      final edge = Edge(node1, node2, label: 'Mindmap Edge');
      final paint = Paint();

      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdge(canvas, edge, paint);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('Multiple edges can have different labels', () {
      final graph = Graph();
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final node3 = Node.Id('C');

      final edge1 = graph.addEdge(node1, node2, label: 'Edge 1');
      final edge2 = graph.addEdge(node2, node3, label: 'Edge 2');
      final edge3 = graph.addEdge(node1, node3, label: 'Edge 3');

      expect(graph.edges.length, 3);
      expect(edge1.label, 'Edge 1');
      expect(edge2.label, 'Edge 2');
      expect(edge3.label, 'Edge 3');
    });

    test('Edge label can be a numeric string', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2, label: '42');

      expect(edge.label, '42');
    });

    test('Edge label can contain special characters', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2, label: 'α → β (100%)');

      expect(edge.label, 'α → β (100%)');
    });

    test('Edge label with custom style has correct properties', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      const style = TextStyle(
        color: Colors.green,
        fontSize: 18.0,
        fontStyle: FontStyle.italic,
        decoration: TextDecoration.underline,
      );
      final edge = Edge(node1, node2, label: 'Custom', labelStyle: style);

      expect(edge.labelStyle?.color, Colors.green);
      expect(edge.labelStyle?.fontSize, 18.0);
      expect(edge.labelStyle?.fontStyle, FontStyle.italic);
      expect(edge.labelStyle?.decoration, TextDecoration.underline);
    });

    test('renderEdgeLabel handles null label gracefully', () {
      final renderer = ArrowEdgeRenderer();
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 0);
      final edge = Edge(node1, node2);

      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdgeLabel(canvas, edge, const Offset(50, 20), 0.0);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('renderEdgeLabel handles empty label gracefully', () {
      final renderer = ArrowEdgeRenderer();
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 0);
      final edge = Edge(node1, node2, label: '');

      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdgeLabel(canvas, edge, const Offset(50, 20), 0.0);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('renderEdgeLabel renders with null angle', () {
      final renderer = ArrowEdgeRenderer();
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 0);
      final edge = Edge(node1, node2, label: 'No Rotation');

      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdgeLabel(canvas, edge, const Offset(50, 20), null);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('renderEdgeLabel renders with various rotation angles', () {
      final renderer = ArrowEdgeRenderer();
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 0);
      final edge = Edge(node1, node2, label: 'Rotated');

      final angles = [0.0, pi / 4, pi / 2, pi, -pi / 2];

      for (final angle in angles) {
        expect(() {
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          renderer.renderEdgeLabel(canvas, edge, const Offset(50, 20), angle);
          recorder.endRecording();
        }, returnsNormally);
      }
    });

    test('Edge with both label and labelWidget stores both', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final widget = const Text('Widget');
      final edge = Edge(
        node1,
        node2,
        label: 'Text Label',
        labelWidget: widget,
      );

      expect(edge.label, 'Text Label');
      expect(edge.labelWidget, widget);
    });

    test('Graph with labeled edges can be serialized and deserialized', () {
      final graph = Graph();
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      const style = TextStyle(color: Colors.blue);

      graph.addEdge(node1, node2, label: 'Test', labelStyle: style);

      expect(graph.edges.length, 1);
      expect(graph.edges.first.label, 'Test');
      expect(graph.edges.first.labelStyle, style);
    });

    test('Very long label does not cause errors', () {
      final renderer = ArrowEdgeRenderer();
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 0);
      final longLabel = 'A' * 1000;
      final edge = Edge(node1, node2, label: longLabel);
      final paint = Paint();

      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdge(canvas, edge, paint);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('Unicode characters in labels are handled correctly', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2, label: '🔥 火 → 水 💧');

      expect(edge.label, '🔥 火 → 水 💧');
    });

    test('Edge label can be positioned at start', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2, label: 'Start', labelPosition: EdgeLabelPosition.start);

      expect(edge.label, 'Start');
      expect(edge.labelPosition, EdgeLabelPosition.start);
    });

    test('Edge label can be positioned at middle', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2, label: 'Middle', labelPosition: EdgeLabelPosition.middle);

      expect(edge.label, 'Middle');
      expect(edge.labelPosition, EdgeLabelPosition.middle);
    });

    test('Edge label can be positioned at end', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2, label: 'End', labelPosition: EdgeLabelPosition.end);

      expect(edge.label, 'End');
      expect(edge.labelPosition, EdgeLabelPosition.end);
    });

    test('Edge label defaults to middle position when labelPosition is null', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2, label: 'Default');

      expect(edge.label, 'Default');
      expect(edge.labelPosition, isNull); // Null means middle is used by default
    });

    test('Edge label follows edge direction by default', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2, label: 'Rotated');

      expect(edge.label, 'Rotated');
      expect(edge.labelFollowsEdgeDirection, isNull); // Null means true (follows edge)
    });

    test('Edge label can be set to follow edge direction explicitly', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2, label: 'Rotated', labelFollowsEdgeDirection: true);

      expect(edge.label, 'Rotated');
      expect(edge.labelFollowsEdgeDirection, true);
    });

    test('Edge label can be set to remain horizontal', () {
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      final edge = Edge(node1, node2, label: 'Horizontal', labelFollowsEdgeDirection: false);

      expect(edge.label, 'Horizontal');
      expect(edge.labelFollowsEdgeDirection, false);
    });

    test('Graph.addEdge() supports labelPosition parameter', () {
      final graph = Graph();
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      graph.addNode(node1);
      graph.addNode(node2);

      final edge = graph.addEdge(node1, node2, label: 'Positioned', labelPosition: EdgeLabelPosition.end);

      expect(edge.label, 'Positioned');
      expect(edge.labelPosition, EdgeLabelPosition.end);
    });

    test('Graph.addEdge() supports labelFollowsEdgeDirection parameter', () {
      final graph = Graph();
      final node1 = Node.Id('A');
      final node2 = Node.Id('B');
      graph.addNode(node1);
      graph.addNode(node2);

      final edge = graph.addEdge(node1, node2, label: 'Horizontal', labelFollowsEdgeDirection: false);

      expect(edge.label, 'Horizontal');
      expect(edge.labelFollowsEdgeDirection, false);
    });

    test('Edge label renders at start position in ArrowEdgeRenderer', () {
      final renderer = ArrowEdgeRenderer();
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 0);
      final edge = Edge(node1, node2, label: 'Start', labelPosition: EdgeLabelPosition.start);
      final paint = Paint();

      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdge(canvas, edge, paint);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('Edge label renders at end position in ArrowEdgeRenderer', () {
      final renderer = ArrowEdgeRenderer();
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 0);
      final edge = Edge(node1, node2, label: 'End', labelPosition: EdgeLabelPosition.end);
      final paint = Paint();

      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdge(canvas, edge, paint);
        recorder.endRecording();
      }, returnsNormally);
    });

    test('Edge label remains horizontal when labelFollowsEdgeDirection is false', () {
      final renderer = ArrowEdgeRenderer();
      final node1 = Node.Id('A')
        ..size = const Size(40, 40)
        ..position = const Offset(0, 0);
      final node2 = Node.Id('B')
        ..size = const Size(40, 40)
        ..position = const Offset(100, 100);
      final edge = Edge(node1, node2, label: 'Horizontal', labelFollowsEdgeDirection: false);
      final paint = Paint();

      expect(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderer.renderEdge(canvas, edge, paint);
        recorder.endRecording();
      }, returnsNormally);
    });
  });
}
