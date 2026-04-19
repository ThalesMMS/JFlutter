import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphview/GraphView.dart';

import 'multiple_forest_graphview.dart';

class MultipleForestTreeViewPageState
    extends State<MultipleForestTreeViewPage> {
  final GraphViewController _controller = GraphViewController();
  final Random r = Random();
  int nextNodeId = 1;
  int _maxNodeId = 0;
  final Graph graph = Graph();
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  late final TextEditingController _siblingSeparationController;
  late final TextEditingController _levelSeparationController;
  late final TextEditingController _subtreeSeparationController;
  late final TextEditingController _orientationController;

  @override
  void dispose() {
    _siblingSeparationController.dispose();
    _levelSeparationController.dispose();
    _subtreeSeparationController.dispose();
    _orientationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Tree View'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Configuration controls
            Wrap(
              children: [
                Container(
                  width: 100,
                  child: TextFormField(
                    controller: _siblingSeparationController,
                    decoration:
                        InputDecoration(labelText: 'Sibling Separation'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (text) {
                      builder.siblingSeparation =
                          max(0, int.tryParse(text) ?? 0);
                      _setControllerText(
                        _siblingSeparationController,
                        builder.siblingSeparation.toString(),
                      );
                      this.setState(() {});
                    },
                  ),
                ),
                Container(
                  width: 100,
                  child: TextFormField(
                    controller: _levelSeparationController,
                    decoration: InputDecoration(labelText: 'Level Separation'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (text) {
                      builder.levelSeparation = max(0, int.tryParse(text) ?? 0);
                      _setControllerText(
                        _levelSeparationController,
                        builder.levelSeparation.toString(),
                      );
                      this.setState(() {});
                    },
                  ),
                ),
                Container(
                  width: 100,
                  child: TextFormField(
                    controller: _subtreeSeparationController,
                    decoration:
                        InputDecoration(labelText: 'Subtree separation'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (text) {
                      builder.subtreeSeparation =
                          max(0, int.tryParse(text) ?? 0);
                      _setControllerText(
                        _subtreeSeparationController,
                        builder.subtreeSeparation.toString(),
                      );
                      this.setState(() {});
                    },
                  ),
                ),
                Container(
                  width: 100,
                  child: TextFormField(
                    controller: _orientationController,
                    decoration: InputDecoration(labelText: 'Orientation'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (text) {
                      final orientation = int.tryParse(text);
                      const allowedOrientations = {
                        BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM,
                        BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP,
                        BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT,
                        BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT,
                      };
                      if (allowedOrientations.contains(orientation)) {
                        builder.orientation = orientation!;
                      }
                      _setControllerText(
                        _orientationController,
                        builder.orientation.toString(),
                      );
                      this.setState(() {});
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final node12 = Node.Id(++_maxNodeId);
                    if (graph.nodeCount() > 0) {
                      final edge =
                          graph.getNodeAtPosition(r.nextInt(graph.nodeCount()));
                      graph.addEdge(edge, node12);
                    } else {
                      graph.addNode(node12);
                    }
                    setState(() {});
                  },
                  child: Text('Add'),
                ),
                ElevatedButton(
                  onPressed: _navigateToRandomNode,
                  child: Text('Go to Node $nextNodeId'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _resetView,
                  child: Text('Reset View'),
                ),
                SizedBox(
                  width: 8,
                ),
                ElevatedButton(
                    onPressed: () {
                      _controller.zoomToFit();
                    },
                    child: Text('Zoom to fit'))
              ],
            ),

            Expanded(
                child: GraphView.builder(
              controller: _controller,
              graph: graph,
              algorithm: TidierTreeLayoutAlgorithm(builder, null),
              builder: (Node node) => rectangleWidget(node.key?.value),
            )),
          ],
        ));
  }

  Widget rectangleWidget(int? a) {
    return InkWell(
      onTap: () {},
      child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.blue[100]!, spreadRadius: 1),
            ],
          ),
          child: Text('Node ${a} ')),
    );
  }

  void _navigateToRandomNode() {
    if (graph.nodes.isEmpty) return;

    final randomNode = graph.nodes.firstWhere(
      (node) => node.key != null && node.key!.value == nextNodeId,
      orElse: () => graph.nodes.firstWhere(
        (node) => node.key != null,
        orElse: () => graph.nodes.first,
      ),
    );
    final nodeId = randomNode.key;
    if (nodeId == null) return;
    _controller.animateToNode(nodeId);

    setState(() {
      final nodeKeys =
          graph.nodes.map((node) => node.key?.value).whereType<int>().toList();
      if (nodeKeys.isNotEmpty) {
        nextNodeId = nodeKeys[r.nextInt(nodeKeys.length)];
      }
    });
  }

  void _resetView() {
    _controller.resetView();
  }

  void _setControllerText(
    TextEditingController controller,
    String text,
  ) {
    if (controller.text == text) return;

    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void initState() {
    super.initState();

    final List<({int from, int to})> edges = [
      (from: 1, to: 2),
      (from: 2, to: 3),
      (from: 2, to: 4),
      (from: 2, to: 5),
      (from: 5, to: 6),
      (from: 5, to: 7),
      (from: 6, to: 8),
      (from: 12, to: 11),
    ];

    for (final edge in edges) {
      final fromNodeId = edge.from;
      final toNodeId = edge.to;
      graph.addEdge(Node.Id(fromNodeId), Node.Id(toNodeId));
      _maxNodeId = max(_maxNodeId, max(fromNodeId, toNodeId));
    }

    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

    _siblingSeparationController =
        TextEditingController(text: builder.siblingSeparation.toString());
    _levelSeparationController =
        TextEditingController(text: builder.levelSeparation.toString());
    _subtreeSeparationController =
        TextEditingController(text: builder.subtreeSeparation.toString());
    _orientationController =
        TextEditingController(text: builder.orientation.toString());
  }
}
