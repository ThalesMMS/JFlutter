import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class AnimatedEdgeExamplePage extends StatefulWidget {
  @override
  _AnimatedEdgeExamplePageState createState() => _AnimatedEdgeExamplePageState();
}

class _AnimatedEdgeExamplePageState extends State<AnimatedEdgeExamplePage>
    with SingleTickerProviderStateMixin {
  GraphViewController _controller = GraphViewController();
  late AnimationController _animationController;
  double animationSpeed = 1.0;
  int particleCount = 3;
  double particleSize = 3.0;
  bool isPlaying = true;

  @override
  void initState() {
    super.initState();

    // Create animation controller that drives the particle movement
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(); // Loop continuously

    // Update the renderer's animation value on each animation tick
    _animationController.addListener(() {
      if (mounted) {
        final renderer = algorithm.renderer;
        if (renderer is AnimatedEdgeRenderer) {
          renderer.setAnimationValue(_animationController.value);
        }
        setState(() {});
      }
    });

    // Create graph with directional edges
    _initializeGraph();

    // Configure force-directed layout
    var config = FruchtermanReingoldConfiguration()
      ..iterations = 1000;

    algorithm = FruchtermanReingoldAlgorithm(config);

    // Set initial renderer with animation configuration
    algorithm.renderer = AnimatedEdgeRenderer(
      animationConfig: AnimatedEdgeConfiguration(
        animationSpeed: animationSpeed,
        particleCount: particleCount,
        particleSize: particleSize,
        particleColor: Colors.white,
      ),
      animationValue: 0.0,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Animated Edge Example'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Configuration controls
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Animation Controls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: _toggleAnimation,
                      tooltip: isPlaying ? 'Pause' : 'Play',
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _controller.zoomToFit();
                      },
                      child: Text('Zoom to Fit'),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Speed: ${animationSpeed.toStringAsFixed(1)}x',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: animationSpeed,
                        min: 0.1,
                        max: 3.0,
                        divisions: 29,
                        label: '${animationSpeed.toStringAsFixed(1)}x',
                        onChanged: (value) {
                          setState(() {
                            animationSpeed = value;
                            _updateRenderer();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Particles: $particleCount',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: particleCount.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$particleCount',
                        onChanged: (value) {
                          setState(() {
                            particleCount = value.round();
                            _updateRenderer();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Size: ${particleSize.toStringAsFixed(1)}px',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: particleSize,
                        min: 1.0,
                        max: 8.0,
                        divisions: 14,
                        label: '${particleSize.toStringAsFixed(1)}px',
                        onChanged: (value) {
                          setState(() {
                            particleSize = value;
                            _updateRenderer();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1),
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
      ),
    );
  }

  final Graph graph = Graph();
  late FruchtermanReingoldAlgorithm algorithm;

  void _initializeGraph() {
    // Create nodes for a data flow visualization
    final node1 = Node.Id(1);
    final node2 = Node.Id(2);
    final node3 = Node.Id(3);
    final node4 = Node.Id(4);
    final node5 = Node.Id(5);
    final node6 = Node.Id(6);
    final node7 = Node.Id(7);
    final node8 = Node.Id(8);

    // Create directed edges with different colors to show flow direction
    // Source nodes (inputs)
    graph.addEdge(node1, node3, paint: Paint()..color = Colors.blue..strokeWidth = 2);
    graph.addEdge(node1, node4, paint: Paint()..color = Colors.blue..strokeWidth = 2);
    graph.addEdge(node2, node3, paint: Paint()..color = Colors.green..strokeWidth = 2);
    graph.addEdge(node2, node5, paint: Paint()..color = Colors.green..strokeWidth = 2);

    // Processing nodes (middle layer)
    graph.addEdge(node3, node6, paint: Paint()..color = Colors.orange..strokeWidth = 2);
    graph.addEdge(node3, node7, paint: Paint()..color = Colors.orange..strokeWidth = 2);
    graph.addEdge(node4, node6, paint: Paint()..color = Colors.purple..strokeWidth = 2);
    graph.addEdge(node4, node7, paint: Paint()..color = Colors.purple..strokeWidth = 2);
    graph.addEdge(node5, node7, paint: Paint()..color = Colors.teal..strokeWidth = 2);
    graph.addEdge(node5, node8, paint: Paint()..color = Colors.teal..strokeWidth = 2);

    // Output nodes
    graph.addEdge(node6, node8, paint: Paint()..color = Colors.red..strokeWidth = 2);
    graph.addEdge(node7, node8, paint: Paint()..color = Colors.pink..strokeWidth = 2);

    // Add some feedback edges to show circular flow
    graph.addEdge(node8, node1, paint: Paint()..color = Colors.grey..strokeWidth = 1.5);
  }

  void _toggleAnimation() {
    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    });
  }

  void _updateRenderer() {
    // Create new renderer with updated configuration
    algorithm.renderer = AnimatedEdgeRenderer(
      animationConfig: AnimatedEdgeConfiguration(
        animationSpeed: animationSpeed,
        particleCount: particleCount,
        particleSize: particleSize,
        particleColor: Colors.white,
      ),
      animationValue: _animationController.value,
    );
  }
}
