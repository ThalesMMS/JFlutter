part of graphview;

class GreedyCycleRemoval {
  final Graph graph;
  final Set<Edge> feedbackArcs = {};

  GreedyCycleRemoval(this.graph);

  Set<Edge> getFeedbackArcs() {
    feedbackArcs.clear();
    var copy = _copyGraph();
    _removeCycles(copy);
    return Set<Edge>.of(feedbackArcs);
  }

  Graph _copyGraph() {
    var copy = Graph();
    copy.addNodes(graph.nodes);
    copy.addEdges(graph.edges);
    return copy;
  }

  void _removeCycles(Graph g) {
    while (g.nodes.isNotEmpty) {
      // Remove sinks
      var sinks = g.nodes.where((n) => !g.hasSuccessor(n)).toList();
      if (sinks.isNotEmpty) {
        for (var sink in sinks) {
          g.removeNode(sink);
        }
        continue;
      }

      // Remove sources
      var sources = g.nodes.where((n) => !g.hasPredecessor(n)).toList();
      if (sources.isNotEmpty) {
        for (var source in sources) {
          g.removeNode(source);
        }
        continue;
      }

      // Choose nodes with highest out-degree - in-degree
      var best = g.nodes.reduce((a, b) {
        var aDiff = g.getOutEdges(a).length - g.getInEdges(a).length;
        var bDiff = g.getOutEdges(b).length - g.getInEdges(b).length;
        return aDiff > bDiff ? a : b;
      });

      // Add incoming edges to feedback arcs
      feedbackArcs.addAll(g.getInEdges(best));
      g.removeNode(best);
    }
  }
}
