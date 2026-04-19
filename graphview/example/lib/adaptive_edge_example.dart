import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class AdaptiveEdgeExamplePage extends StatefulWidget {
  @override
  _AdaptiveEdgeExamplePageState createState() =>
      _AdaptiveEdgeExamplePageState();
}

class _AdaptiveEdgeExamplePageState extends State<AdaptiveEdgeExamplePage> {
  GraphViewController _controller = GraphViewController();

  // Configuration state
  AnchorMode _anchorMode = AnchorMode.dynamic;
  RoutingMode _routingMode = RoutingMode.bezier;
  bool _enableRepulsion = false;
  double _repulsionStrength = 0.5;
  double _minEdgeDistance = 10.0;
  bool _draggingEnabled = true;

  // Drag events for logging
  final List<String> _dragEvents = [];
  final ScrollController _eventScrollController = ScrollController();
  int _dragUpdateCounter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adaptive Edge Routing'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Configuration controls panel
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and instructions
                Text(
                  'Adaptive Edge Routing Demo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Drag nodes to see adaptive anchors and routing in action!',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16),

                // Anchor Mode selector
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anchor Mode:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildModeChip(
                                'Center',
                                _anchorMode == AnchorMode.center,
                                () {
                                  _anchorMode = AnchorMode.center;
                                  _updateRenderer();
                                },
                              ),
                              _buildModeChip(
                                'Cardinal (4)',
                                _anchorMode == AnchorMode.cardinal,
                                () {
                                  _anchorMode = AnchorMode.cardinal;
                                  _updateRenderer();
                                },
                              ),
                              _buildModeChip(
                                'Octagonal (8)',
                                _anchorMode == AnchorMode.octagonal,
                                () {
                                  _anchorMode = AnchorMode.octagonal;
                                  _updateRenderer();
                                },
                              ),
                              _buildModeChip(
                                'Dynamic',
                                _anchorMode == AnchorMode.dynamic,
                                () {
                                  _anchorMode = AnchorMode.dynamic;
                                  _updateRenderer();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Routing Mode selector
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Routing Mode:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildModeChip(
                                'Direct',
                                _routingMode == RoutingMode.direct,
                                () {
                                  _routingMode = RoutingMode.direct;
                                  _updateRenderer();
                                },
                              ),
                              _buildModeChip(
                                'Orthogonal',
                                _routingMode == RoutingMode.orthogonal,
                                () {
                                  _routingMode = RoutingMode.orthogonal;
                                  _updateRenderer();
                                },
                              ),
                              _buildModeChip(
                                'Bezier',
                                _routingMode == RoutingMode.bezier,
                                () {
                                  _routingMode = RoutingMode.bezier;
                                  _updateRenderer();
                                },
                              ),
                              _buildModeChip(
                                'Bundling',
                                _routingMode == RoutingMode.bundling,
                                () {
                                  _routingMode = RoutingMode.bundling;
                                  _updateRenderer();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),
                Divider(height: 1),
                SizedBox(height: 16),

                // Edge Repulsion controls
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Edge Repulsion:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 8),
                              Switch(
                                value: _enableRepulsion,
                                onChanged: (value) {
                                  _enableRepulsion = value;
                                  _updateRenderer();
                                },
                              ),
                            ],
                          ),
                          if (_enableRepulsion) ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                    'Strength: ${_repulsionStrength.toStringAsFixed(2)}'),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Slider(
                                    value: _repulsionStrength,
                                    min: 0.1,
                                    max: 1.0,
                                    divisions: 9,
                                    label:
                                        _repulsionStrength.toStringAsFixed(2),
                                    onChanged: (value) {
                                      _repulsionStrength = value;
                                      _updateRenderer();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                    'Min Distance: ${_minEdgeDistance.toStringAsFixed(0)}px'),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Slider(
                                    value: _minEdgeDistance,
                                    min: 5.0,
                                    max: 30.0,
                                    divisions: 5,
                                    label: _minEdgeDistance.toStringAsFixed(0),
                                    onChanged: (value) {
                                      _minEdgeDistance = value;
                                      _updateRenderer();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Text(
                      'Node Dragging: ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Switch(
                      value: _draggingEnabled,
                      onChanged: (value) {
                        setState(() {
                          _draggingEnabled = value;
                        });
                      },
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _controller.zoomToFit();
                      },
                      icon: Icon(Icons.fit_screen, size: 18),
                      label: Text('Zoom to Fit'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _dragEvents.clear();
                        });
                      },
                      icon: Icon(Icons.clear, size: 18),
                      label: Text('Clear Events'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Graph view
          Expanded(
            flex: 3,
            child: GraphView.builder(
              controller: _controller,
              graph: graph,
              algorithm: algorithm,
              centerGraph: true,
              nodeDraggingConfig: NodeDraggingConfiguration(
                enabled: _draggingEnabled,
                onNodeDragStart: (node) {
                  _dragUpdateCounter = 0;
                  _addDragEvent('Drag Start: Node ${node.key?.value}');
                },
                onNodeDragUpdate: (node, position) {
                  _dragUpdateCounter++;
                  // Only log occasional updates to avoid spam
                  if (_dragUpdateCounter % 10 == 0) {
                    _addDragEvent('Dragging Node ${node.key?.value}...');
                  }
                },
                onNodeDragEnd: (node, finalPosition) {
                  _addDragEvent(
                      'Drag End: Node ${node.key?.value} at (${finalPosition.dx.toStringAsFixed(0)}, ${finalPosition.dy.toStringAsFixed(0)})');
                },
              ),
              builder: (Node node) {
                var nodeId = node.key?.value as int?;
                var isHub = _hubNodes.contains(node);

                return Container(
                  padding: EdgeInsets.all(isHub ? 20 : 16),
                  decoration: BoxDecoration(
                    color: isHub ? Colors.orange[100] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(isHub ? 30 : 8),
                    border: Border.all(
                      color: isHub ? Colors.orange[700]! : Colors.blue[700]!,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isHub ? Colors.orange : Colors.blue)
                            .withValues(alpha: 0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Node $nodeId',
                        style: TextStyle(
                          fontSize: isHub ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: isHub ? Colors.orange[900] : Colors.blue[900],
                        ),
                      ),
                      if (isHub)
                        Text(
                          'Hub',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[700],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          Divider(height: 1),

          // Event log
          Container(
            height: 120,
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(Icons.event_note, size: 16, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Text(
                        'Drag Events Log:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _dragEvents.isEmpty
                      ? Center(
                          child: Text(
                            'Drag a node to see events...',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _eventScrollController,
                          itemCount: _dragEvents.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              child: Text(
                                '${_dragEvents.length - index}. ${_dragEvents[_dragEvents.length - index - 1]}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: Colors.grey[800],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.blue[300],
      backgroundColor: Colors.grey[200],
      checkmarkColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  void _addDragEvent(String event) {
    setState(() {
      _dragEvents.add(event);
      // Keep only last 100 events
      if (_dragEvents.length > 100) {
        _dragEvents.removeAt(0);
      }
    });
  }

  final Graph graph = Graph();
  late FruchtermanReingoldAlgorithm algorithm;
  final List<Node> _hubNodes = [];

  @override
  void initState() {
    super.initState();

    // Create a network graph with hub-and-spoke pattern plus cross-connections
    // This demonstrates adaptive edges well with multiple edge directions

    // Hub nodes
    final hub1 = Node.Id(1);
    final hub2 = Node.Id(2);
    final hub3 = Node.Id(3);
    _hubNodes.addAll([hub1, hub2, hub3]);

    // Spoke nodes around hub1
    final node4 = Node.Id(4);
    final node5 = Node.Id(5);
    final node6 = Node.Id(6);
    final node7 = Node.Id(7);

    // Spoke nodes around hub2
    final node8 = Node.Id(8);
    final node9 = Node.Id(9);
    final node10 = Node.Id(10);

    // Spoke nodes around hub3
    final node11 = Node.Id(11);
    final node12 = Node.Id(12);
    final node13 = Node.Id(13);

    // Additional nodes for complex patterns
    final node14 = Node.Id(14);
    final node15 = Node.Id(15);

    // Hub1 connections (orange edges)
    graph.addEdge(hub1, node4,
        paint: Paint()
          ..color = Colors.orange
          ..strokeWidth = 2);
    graph.addEdge(hub1, node5,
        paint: Paint()
          ..color = Colors.orange
          ..strokeWidth = 2);
    graph.addEdge(hub1, node6,
        paint: Paint()
          ..color = Colors.orange
          ..strokeWidth = 2);
    graph.addEdge(hub1, node7,
        paint: Paint()
          ..color = Colors.orange
          ..strokeWidth = 2);

    // Hub2 connections (green edges)
    graph.addEdge(hub2, node8,
        paint: Paint()
          ..color = Colors.green
          ..strokeWidth = 2);
    graph.addEdge(hub2, node9,
        paint: Paint()
          ..color = Colors.green
          ..strokeWidth = 2);
    graph.addEdge(hub2, node10,
        paint: Paint()
          ..color = Colors.green
          ..strokeWidth = 2);

    // Hub3 connections (purple edges)
    graph.addEdge(hub3, node11,
        paint: Paint()
          ..color = Colors.purple
          ..strokeWidth = 2);
    graph.addEdge(hub3, node12,
        paint: Paint()
          ..color = Colors.purple
          ..strokeWidth = 2);
    graph.addEdge(hub3, node13,
        paint: Paint()
          ..color = Colors.purple
          ..strokeWidth = 2);

    // Inter-hub connections (blue edges) - demonstrates parallel edges
    graph.addEdge(hub1, hub2,
        paint: Paint()
          ..color = Colors.blue
          ..strokeWidth = 3);
    graph.addEdge(hub2, hub3,
        paint: Paint()
          ..color = Colors.blue
          ..strokeWidth = 3);
    graph.addEdge(hub3, hub1,
        paint: Paint()
          ..color = Colors.blue
          ..strokeWidth = 3);

    // Additional parallel edges to demonstrate anchor distribution
    graph.addEdge(hub1, hub2,
        paint: Paint()
          ..color = Colors.cyan
          ..strokeWidth = 2);

    // Cross connections (demonstrates complex routing)
    graph.addEdge(node4, node8,
        paint: Paint()
          ..color = Colors.red
          ..strokeWidth = 1.5);
    graph.addEdge(node5, node11,
        paint: Paint()
          ..color = Colors.pink
          ..strokeWidth = 1.5);
    graph.addEdge(node6, node12,
        paint: Paint()
          ..color = Colors.teal
          ..strokeWidth = 1.5);
    graph.addEdge(node7, hub2,
        paint: Paint()
          ..color = Colors.amber
          ..strokeWidth = 1.5);

    // Additional nodes connected to multiple hubs
    graph.addEdge(node14, hub1,
        paint: Paint()
          ..color = Colors.indigo
          ..strokeWidth = 2);
    graph.addEdge(node14, hub2,
        paint: Paint()
          ..color = Colors.indigo
          ..strokeWidth = 2);
    graph.addEdge(node15, hub2,
        paint: Paint()
          ..color = Colors.lime
          ..strokeWidth = 2);
    graph.addEdge(node15, hub3,
        paint: Paint()
          ..color = Colors.lime
          ..strokeWidth = 2);

    // Some bidirectional edges to demonstrate anchor distribution
    graph.addEdge(node10, hub3,
        paint: Paint()
          ..color = Colors.deepOrange
          ..strokeWidth = 1.5);
    graph.addEdge(node9, node13,
        paint: Paint()
          ..color = Colors.brown
          ..strokeWidth = 1.5);

    // Configure force-directed layout for organic positioning
    var config = FruchtermanReingoldConfiguration()
      ..iterations = 1000
      ..attractionRate = 0.5
      ..repulsionRate = 0.5;

    algorithm = FruchtermanReingoldAlgorithm(config);

    // Set initial renderer with default configuration
    _updateRenderer();
  }

  void _updateRenderer() {
    setState(() {
      // Create EdgeRoutingConfig based on current state
      final config = EdgeRoutingConfig()
        ..anchorMode = _anchorMode
        ..routingMode = _routingMode
        ..enableRepulsion = _enableRepulsion
        ..repulsionStrength = _repulsionStrength
        ..minEdgeDistance = _minEdgeDistance
        ..maxRepulsionIterations = 10
        ..movementThreshold = 1.0;

      // Use AdaptiveEdgeRenderer with current configuration
      algorithm.renderer = AdaptiveEdgeRenderer(config: config);
    });
  }

  @override
  void dispose() {
    _eventScrollController.dispose();
    super.dispose();
  }
}
