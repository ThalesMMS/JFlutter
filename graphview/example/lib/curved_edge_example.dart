import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class CurvedEdgeExamplePage extends StatefulWidget {
  @override
  _CurvedEdgeExamplePageState createState() => _CurvedEdgeExamplePageState();
}

class _CurvedEdgeExamplePageState extends State<CurvedEdgeExamplePage> {
  GraphViewController _controller = GraphViewController();
  double curvature = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Curved Edge Example'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Configuration controls
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Curvature: ${curvature.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: curvature,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      label: curvature.toStringAsFixed(2),
                      onChanged: (value) {
                        setState(() {
                          curvature = value;
                          algorithm.renderer = CurvedEdgeRenderer(curvature: curvature);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      _controller.zoomToFit();
                    },
                    child: Text('Zoom to Fit'),
                  ),
                ],
              ),
            ),
            Divider(),
            Expanded(
              child: GraphView.builder(
                controller: _controller,
                graph: graph,
                algorithm: algorithm,
                centerGraph: true,
                builder: (Node node) {
                  var nodeId = node.key?.value as int?;
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Text(
                      'Node $nodeId',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ));
  }

  final Graph graph = Graph();
  late FruchtermanReingoldAlgorithm algorithm;

  @override
  void initState() {
    super.initState();

    // Create a network of nodes to demonstrate curved edges
    final node1 = Node.Id(1);
    final node2 = Node.Id(2);
    final node3 = Node.Id(3);
    final node4 = Node.Id(4);
    final node5 = Node.Id(5);
    final node6 = Node.Id(6);
    final node7 = Node.Id(7);
    final node8 = Node.Id(8);

    // Create edges with different colors to showcase curved rendering
    graph.addEdge(node1, node2, paint: Paint()..color = Colors.blue..strokeWidth = 2);
    graph.addEdge(node1, node3, paint: Paint()..color = Colors.red..strokeWidth = 2);
    graph.addEdge(node1, node4, paint: Paint()..color = Colors.green..strokeWidth = 2);
    graph.addEdge(node2, node5, paint: Paint()..color = Colors.purple..strokeWidth = 2);
    graph.addEdge(node3, node6, paint: Paint()..color = Colors.orange..strokeWidth = 2);
    graph.addEdge(node4, node7, paint: Paint()..color = Colors.teal..strokeWidth = 2);
    graph.addEdge(node5, node8, paint: Paint()..color = Colors.pink..strokeWidth = 2);
    graph.addEdge(node6, node8, paint: Paint()..color = Colors.indigo..strokeWidth = 2);
    graph.addEdge(node7, node8, paint: Paint()..color = Colors.cyan..strokeWidth = 2);

    // Add some cross edges to create more interesting curved patterns
    graph.addEdge(node2, node3, paint: Paint()..color = Colors.amber..strokeWidth = 1.5);
    graph.addEdge(node3, node4, paint: Paint()..color = Colors.lime..strokeWidth = 1.5);
    graph.addEdge(node5, node6, paint: Paint()..color = Colors.deepOrange..strokeWidth = 1.5);
    graph.addEdge(node6, node7, paint: Paint()..color = Colors.deepPurple..strokeWidth = 1.5);

    // Configure force-directed layout
    var config = FruchtermanReingoldConfiguration()
      ..iterations = 1000;

    algorithm = FruchtermanReingoldAlgorithm(config);
    // Set initial renderer with default curvature
    algorithm.renderer = CurvedEdgeRenderer(curvature: curvature);
  }
}
