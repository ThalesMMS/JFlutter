import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class GraphScreen extends StatefulWidget {
  final Graph graph;
  final FruchtermanReingoldAlgorithm algorithm;
  final Paint? paint;

  GraphScreen(this.graph, this.algorithm, this.paint);

  @override
  _GraphScreenState createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  bool animated = true;
  Random r = Random();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Graph Screen'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              setState(() {
                final node12 = Node.Id(_nextUniqueNodeId());
                if (widget.graph.nodeCount() == 0) {
                  widget.graph.addNode(node12);
                  return;
                }

                final edge = widget.graph
                    .getNodeAtPosition(r.nextInt(widget.graph.nodeCount()));
                widget.graph.addEdge(edge, node12);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.animation),
            onPressed: () async {
              setState(() {
                animated = !animated;
              });
            },
          )
        ],
      ),
      body: InteractiveViewer(
          constrained: false,
          boundaryMargin: EdgeInsets.all(100),
          minScale: 0.0001,
          maxScale: 10.6,
          child: GraphViewCustomPainter(
            graph: widget.graph,
            algorithm: widget.algorithm,
            paint: widget.paint,
            animated: animated,
            builder: (Node node) {
              // I can decide what widget should be shown here based on the id
              var a = node.key!.value as String;
              return rectangWidget(a);
            },
          )),
    );
  }

  Widget rectangWidget(String? i) {
    return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.blue, spreadRadius: 1),
          ],
        ),
        child: Center(child: Text('Node $i')));
  }

  String _nextUniqueNodeId() {
    final ids = widget.graph.nodes
        .map((node) => int.tryParse(node.key?.value.toString() ?? ''))
        .whereType<int>()
        .toList();
    return ((ids.isEmpty ? 0 : ids.reduce(max)) + 1).toString();
  }

  Future<void> update() async {
    setState(() {});
  }
}
