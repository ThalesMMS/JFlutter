//
//  graphview_all_nodes_builder.dart
//  JFlutter
//
//  Extensão do widget GraphView que garante a renderização de todos os nós do
//  grafo, mesmo quando a biblioteca base tenta otimizar a exibição. A classe
//  adapta o delegate interno para preservar animações e configurações de zoom
//  personalizadas do canvas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:graphview/GraphView.dart';

class GraphViewAllNodes extends GraphView {
  GraphViewAllNodes.builder({
    super.key,
    required Graph graph,
    required Algorithm algorithm,
    super.paint,
    required NodeWidgetBuilder builder,
    GraphViewController? controller,
    super.animated,
    super.initialNode,
    super.autoZoomToFit,
    super.panAnimationDuration,
    super.toggleAnimationDuration,
    bool centerGraph = false,
  }) : super.builder(
          graph: graph,
          algorithm: algorithm,
          builder: builder,
          controller: controller,
          centerGraph: centerGraph,
        ) {
    delegate = _GraphViewAllNodesDelegate(
      graph: graph,
      algorithm: algorithm,
      builder: builder,
      controller: controller,
      centerGraph: centerGraph,
    );
  }
}

class _GraphViewAllNodesDelegate extends GraphChildDelegate {
  _GraphViewAllNodesDelegate({
    required super.graph,
    required super.algorithm,
    required super.builder,
    required super.controller,
    super.centerGraph,
  });

  @override
  Graph getVisibleGraph() {
    final visibleGraph = super.getVisibleGraph();
    _ensureAllNodesPresent(visibleGraph);
    return visibleGraph;
  }

  @override
  Graph getVisibleGraphOnly() {
    final visibleGraph = super.getVisibleGraphOnly();
    _ensureAllNodesPresent(visibleGraph);
    return visibleGraph;
  }

  void _ensureAllNodesPresent(Graph visibleGraph) {
    if (visibleGraph.nodes.length == graph.nodes.length) {
      return;
    }

    for (final node in graph.nodes) {
      if (!visibleGraph.nodes.contains(node)) {
        visibleGraph.addNode(node);
      }
    }
  }
}
