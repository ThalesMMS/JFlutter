import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class BarnesHutDemoPage extends StatefulWidget {
  @override
  _BarnesHutDemoPageState createState() => _BarnesHutDemoPageState();
}

class _BarnesHutDemoPageState extends State<BarnesHutDemoPage> {
  final Graph graph = Graph();
  late FruchtermanReingoldAlgorithm algorithm;
  final Random r = Random();

  bool useBarnesHut = true;
  int nodeCount = 500;
  double iterations = 100;
  int lastLayoutTime = 0;

  @override
  void initState() {
    super.initState();
    _buildGraph();
    _updateAlgorithm();
  }

  void _buildGraph() {
    graph.nodes.clear();
    graph.edges.clear();

    // Create nodes
    final nodes = List.generate(nodeCount, (i) => Node.Id(i + 1));

    // Create edges - build a more connected graph for interesting layout
    // Each node connects to 2-4 other nodes randomly
    for (var i = 0; i < nodeCount; i++) {
      final connectionCount = 2 + r.nextInt(3); // 2-4 connections
      for (var j = 0; j < connectionCount; j++) {
        final targetIndex = r.nextInt(nodeCount);
        if (targetIndex != i) {
          try {
            graph.addEdge(nodes[i], nodes[targetIndex]);
          } catch (e) {
            // Edge might already exist, ignore
          }
        }
      }
    }
  }

  void _updateAlgorithm() {
    final config = FruchtermanReingoldConfiguration()
      ..iterations = iterations.toInt()
      ..useBarnesHut = useBarnesHut
      ..theta = 0.5
      ..repulsionRate = 0.2
      ..attractionRate = 0.15;

    algorithm = FruchtermanReingoldAlgorithm(config);
  }

  void _relayout() {
    final stopwatch = Stopwatch()..start();
    _updateAlgorithm();
    algorithm.init(graph);
    algorithm.run(graph, 0, 0);
    stopwatch.stop();

    setState(() {
      lastLayoutTime = stopwatch.elapsedMilliseconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barnes-Hut Algorithm Demo'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Text(
                lastLayoutTime > 0 ? 'Layout: ${lastLayoutTime}ms' : '',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControls(),
          Expanded(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: EdgeInsets.all(100),
              minScale: 0.01,
              maxScale: 10.0,
              child: GraphViewCustomPainter(
                graph: graph,
                algorithm: algorithm,
                paint: Paint()
                  ..color = Colors.green
                  ..strokeWidth = 1
                  ..style = PaintingStyle.stroke,
                builder: (Node node) {
                  return _buildNodeWidget(node);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Nodes',
                  nodeCount.toString(),
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Edges',
                  graph.edges.length.toString(),
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Algorithm',
                  useBarnesHut ? 'O(n log n)' : 'O(n²)',
                  useBarnesHut ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nodes: ${nodeCount.toInt()}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Slider(
                      value: nodeCount.toDouble(),
                      min: 50,
                      max: 1000,
                      divisions: 19,
                      label: nodeCount.toString(),
                      onChanged: (value) {
                        setState(() {
                          nodeCount = value.toInt();
                          _buildGraph();
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Iterations: ${iterations.toInt()}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Slider(
                      value: iterations,
                      min: 50,
                      max: 500,
                      divisions: 9,
                      label: iterations.toInt().toString(),
                      onChanged: (value) {
                        setState(() {
                          iterations = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: Text(
                    'Use Barnes-Hut Optimization',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    useBarnesHut
                        ? 'O(n log n) - Recommended for large graphs'
                        : 'O(n²) - Slower for large graphs',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: useBarnesHut,
                  onChanged: (value) {
                    setState(() {
                      useBarnesHut = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _relayout,
                icon: Icon(Icons.refresh),
                label: Text('Re-layout Graph'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Toggle Barnes-Hut to compare performance. With 500+ nodes, Barnes-Hut is significantly faster while maintaining good layout quality.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeWidget(Node node) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
