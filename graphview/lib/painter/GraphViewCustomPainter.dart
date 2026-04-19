part of graphview;

class GraphViewCustomPainter extends StatefulWidget {
  final Graph graph;
  final FruchtermanReingoldAlgorithm algorithm;
  final Paint? paint;
  final NodeWidgetBuilder builder;
  final bool animated;
  final stepMilis = 25;

  GraphViewCustomPainter({
    Key? key,
    required this.graph,
    required this.algorithm,
    this.paint,
    this.animated = true,
    required this.builder,
  }) : super(key: key);

  @override
  _GraphViewCustomPainterState createState() => _GraphViewCustomPainterState();
}

class _GraphViewCustomPainterState extends State<GraphViewCustomPainter> {
  static const nodeEdgeOffset = Offset(20, 20);

  late Timer timer;
  late Graph graph;
  late FruchtermanReingoldAlgorithm algorithm;

  @override
  void initState() {
    super.initState();

    graph = widget.graph;

    algorithm = widget.algorithm;
    algorithm.init(graph);
    startTimer();
  }

  @override
  void didUpdateWidget(covariant GraphViewCustomPainter oldWidget) {
    super.didUpdateWidget(oldWidget);

    final graphChanged = widget.graph != graph;
    final algorithmChanged = widget.algorithm != algorithm;
    if (!graphChanged && !algorithmChanged) return;

    graph = widget.graph;
    algorithm = widget.algorithm;
    algorithm.init(graph);

    if (algorithmChanged) {
      timer.cancel();
      startTimer();
    }
  }

  void startTimer() {
    timer = Timer.periodic(Duration(milliseconds: widget.stepMilis), (timer) {
      if (!widget.animated) return;
      algorithm.step(graph);
      update();
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    algorithm.setDimensions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: MediaQuery.of(context).size,
          painter: EdgeRender(algorithm, graph, nodeEdgeOffset, widget.paint),
        ),
        ...List<Widget>.generate(graph.nodeCount(), (index) {
          return Positioned(
            child: GestureDetector(
              child:
                  graph.nodes[index].data ?? widget.builder(graph.nodes[index]),
              onPanUpdate: (details) {
                graph.getNodeAtPosition(index).position += details.delta;
                graph.markModified();
                update();
              },
            ),
            top: graph.getNodeAtPosition(index).position.dy + nodeEdgeOffset.dy,
            left:
                graph.getNodeAtPosition(index).position.dx + nodeEdgeOffset.dx,
          );
        }),
      ],
    );
  }

  Future<void> update() async {
    setState(() {});
  }
}
