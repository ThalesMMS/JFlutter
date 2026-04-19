import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class NodeDraggingExample extends StatefulWidget {
  @override
  _NodeDraggingExampleState createState() => _NodeDraggingExampleState();
}

class _NodeDraggingExampleState extends State<NodeDraggingExample> {
  GraphViewController _controller = GraphViewController();
  bool _draggingEnabled = true;
  final List<String> _dragEvents = [];
  final ScrollController _eventScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Node Dragging Example'),
      ),
      body: Column(
        children: [
          // Control panel
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Node Dragging: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Switch(
                      value: _draggingEnabled,
                      onChanged: (value) {
                        setState(() {
                          _draggingEnabled = value;
                        });
                      },
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _dragEvents.clear();
                        });
                      },
                      child: Text('Clear Events'),
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
                SizedBox(height: 8),
                Text(
                  'Instructions: Long press a node to drag it. Blue nodes are unlocked, red nodes are locked.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          // Graph view
          Expanded(
            flex: 2,
            child: GraphView.builder(
              controller: _controller,
              graph: graph,
              algorithm: algorithm,
              nodeDraggingConfig: NodeDraggingConfiguration(
                enabled: _draggingEnabled,
                onNodeDragStart: (node) {
                  _addDragEvent('Drag Start: Node ${node.key?.value}');
                },
                onNodeDragUpdate: (node, position) {
                  _addDragEvent(
                      'Drag Update: Node ${node.key?.value} at (${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)})');
                },
                onNodeDragEnd: (node, finalPosition) {
                  _addDragEvent(
                      'Drag End: Node ${node.key?.value} at (${finalPosition.dx.toStringAsFixed(1)}, ${finalPosition.dy.toStringAsFixed(1)})');
                },
                canDragPredicate: (node) {
                  // Check if node has locked property set to true
                  return !node.locked;
                },
              ),
              builder: (Node node) {
                final isLocked = node.locked;
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.red[100] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLocked ? Colors.red : Colors.blue,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Node ${node.key?.value}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.red[900] : Colors.blue[900],
                        ),
                      ),
                      if (isLocked)
                        Icon(Icons.lock, size: 16, color: Colors.red[900]),
                    ],
                  ),
                );
              },
            ),
          ),

          // Event log
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Drag Events:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _eventScrollController,
                      itemCount: _dragEvents.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Text(
                            _dragEvents[index],
                            style: TextStyle(
                                fontSize: 12, fontFamily: 'monospace'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addDragEvent(String event) {
    setState(() {
      _dragEvents.add(event);
      // Keep only last 50 events
      if (_dragEvents.length > 50) {
        _dragEvents.removeAt(0);
      }
    });
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_eventScrollController.hasClients) {
        _eventScrollController.animateTo(
          _eventScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  final Graph graph = Graph();
  late FruchtermanReingoldAlgorithm algorithm;

  @override
  void initState() {
    super.initState();

    // Create a simple graph with some locked and unlocked nodes
    final node1 = Node.Id(1);
    final node2 = Node.Id(2);
    final node3 = Node.Id(3);
    final node4 = Node.Id(4);
    final node5 = Node.Id(5);
    final node6 = Node.Id(6);

    // Lock some nodes (2 and 5)
    node2.locked = true;
    node5.locked = true;

    // Add edges to create connections
    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
    graph.addEdge(node2, node4);
    graph.addEdge(node3, node4);
    graph.addEdge(node3, node5);
    graph.addEdge(node4, node6);
    graph.addEdge(node5, node6);

    // Use force-directed layout for natural positioning
    var config = FruchtermanReingoldConfiguration()..iterations = 1000;
    algorithm = FruchtermanReingoldAlgorithm(config);
  }

  @override
  void dispose() {
    _eventScrollController.dispose();
    super.dispose();
  }
}
