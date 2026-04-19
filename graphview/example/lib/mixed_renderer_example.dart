import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class MixedRendererExamplePage extends StatefulWidget {
  @override
  _MixedRendererExamplePageState createState() =>
      _MixedRendererExamplePageState();
}

class _MixedRendererExamplePageState extends State<MixedRendererExamplePage>
    with SingleTickerProviderStateMixin {
  GraphViewController _controller = GraphViewController();
  late AnimationController _animationController;
  bool isPlaying = true;

  @override
  void initState() {
    super.initState();

    // Create animation controller for animated edges
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat();

    // Update animation value on each tick
    _animationController.addListener(() {
      if (mounted) {
        // Update all animated edge renderers
        for (var renderer in animatedRenderers) {
          renderer.setAnimationValue(_animationController.value);
        }
        setState(() {});
      }
    });

    // Initialize graph with mixed renderers
    _initializeGraph();

    // Configure force-directed layout
    var config = FruchtermanReingoldConfiguration()..iterations = 1000;

    algorithm = FruchtermanReingoldAlgorithm(config);
    // Default renderer is ArrowEdgeRenderer (straight arrows)
    algorithm.renderer = ArrowEdgeRenderer();
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
        title: Text('Mixed Renderer Example'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Legend/Info Panel
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Per-Edge Renderer Demonstration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                _buildLegendItem(
                  Colors.blue,
                  'Straight Edges',
                  'Default ArrowEdgeRenderer',
                ),
                SizedBox(height: 4),
                _buildLegendItem(
                  Colors.green,
                  'Curved Edges',
                  'CurvedEdgeRenderer (curvature 0.5)',
                ),
                SizedBox(height: 4),
                _buildLegendItem(
                  Colors.orange,
                  'Animated Edges',
                  'AnimatedEdgeRenderer with flow particles',
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'This example shows how different edge renderers can be mixed in the same graph using per-edge renderer specification.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                    SizedBox(width: 16),
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
                    border: Border.all(color: Colors.blueGrey, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.withValues(alpha: 0.3),
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

  Widget _buildLegendItem(Color color, String title, String description) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          color: color,
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  final Graph graph = Graph();
  late FruchtermanReingoldAlgorithm algorithm;
  final List<AnimatedEdgeRenderer> animatedRenderers = [];

  void _initializeGraph() {
    // Create nodes
    final node1 = Node.Id(1);
    final node2 = Node.Id(2);
    final node3 = Node.Id(3);
    final node4 = Node.Id(4);
    final node5 = Node.Id(5);
    final node6 = Node.Id(6);
    final node7 = Node.Id(7);
    final node8 = Node.Id(8);

    // Create edge renderers
    final curvedRenderer = CurvedEdgeRenderer(curvature: 0.5);

    final animatedRenderer1 = AnimatedEdgeRenderer(
      animationConfig: AnimatedEdgeConfiguration(
        animationSpeed: 1.0,
        particleCount: 3,
        particleSize: 3.0,
        particleColor: Colors.white,
      ),
      animationValue: 0.0,
    );
    animatedRenderers.add(animatedRenderer1);

    final animatedRenderer2 = AnimatedEdgeRenderer(
      animationConfig: AnimatedEdgeConfiguration(
        animationSpeed: 1.5,
        particleCount: 2,
        particleSize: 4.0,
        particleColor: Colors.white,
      ),
      animationValue: 0.0,
    );
    animatedRenderers.add(animatedRenderer2);

    // Add edges with different renderers

    // Straight edges (use default ArrowEdgeRenderer from algorithm)
    // No renderer specified, will use algorithm.renderer
    graph.addEdge(
      node1,
      node2,
      paint: Paint()..color = Colors.blue..strokeWidth = 2,
    );
    graph.addEdge(
      node2,
      node4,
      paint: Paint()..color = Colors.blue..strokeWidth = 2,
    );
    graph.addEdge(
      node4,
      node8,
      paint: Paint()..color = Colors.blue..strokeWidth = 2,
    );

    // Curved edges (use CurvedEdgeRenderer)
    graph.addEdge(
      node1,
      node3,
      paint: Paint()..color = Colors.green..strokeWidth = 2,
      renderer: curvedRenderer,
    );
    graph.addEdge(
      node3,
      node5,
      paint: Paint()..color = Colors.green..strokeWidth = 2,
      renderer: curvedRenderer,
    );
    graph.addEdge(
      node5,
      node7,
      paint: Paint()..color = Colors.green..strokeWidth = 2,
      renderer: curvedRenderer,
    );
    graph.addEdge(
      node7,
      node8,
      paint: Paint()..color = Colors.green..strokeWidth = 2,
      renderer: curvedRenderer,
    );

    // Animated edges (use AnimatedEdgeRenderer)
    graph.addEdge(
      node2,
      node3,
      paint: Paint()..color = Colors.orange..strokeWidth = 2,
      renderer: animatedRenderer1,
    );
    graph.addEdge(
      node4,
      node5,
      paint: Paint()..color = Colors.orange..strokeWidth = 2,
      renderer: animatedRenderer1,
    );
    graph.addEdge(
      node6,
      node7,
      paint: Paint()..color = Colors.orange..strokeWidth = 2,
      renderer: animatedRenderer2,
    );

    // Mix it up - some cross edges with different renderers
    graph.addEdge(
      node1,
      node6,
      paint: Paint()..color = Colors.blue.withValues(alpha: 0.6)..strokeWidth = 1.5,
    );
    graph.addEdge(
      node3,
      node6,
      paint: Paint()..color = Colors.green.withValues(alpha: 0.6)..strokeWidth = 1.5,
      renderer: curvedRenderer,
    );
    graph.addEdge(
      node5,
      node8,
      paint: Paint()..color = Colors.orange.withValues(alpha: 0.6)..strokeWidth = 1.5,
      renderer: animatedRenderer2,
    );
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
}
