part of graphview;

class EdgeRender extends CustomPainter {
  Algorithm algorithm;
  Graph graph;
  Offset offset;
  Paint? customPaint;

  EdgeRender(this.algorithm, this.graph, this.offset, this.customPaint);

  @override
  void paint(Canvas canvas, Size size) {
    var edgePaint = customPaint ??
        (Paint()
          ..color = Colors.black
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt);

    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // Set graph reference on renderer for edge distribution calculation
    algorithm.renderer?.setGraph(graph);

    for (var value in graph.edges) {
      algorithm.renderer?.renderEdge(canvas, value, edgePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is! EdgeRender) {
      return true;
    }

    // Check if graph changed (either different instance or same instance but modified)
    final graphChanged = graph != oldDelegate.graph ||
        (identical(graph, oldDelegate.graph) &&
         graph.generation != oldDelegate.graph.generation);

    return graphChanged ||
        algorithm != oldDelegate.algorithm ||
        offset != oldDelegate.offset ||
        customPaint != oldDelegate.customPaint;
  }
}
