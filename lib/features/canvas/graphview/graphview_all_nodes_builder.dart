/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/features/canvas/graphview/graphview_all_nodes_builder.dart
/// Descrição: Estende o GraphView padrão para renderizar todos os nós do
///            canvas, respeitando animações e ajustes de zoom personalizados.
/// ---------------------------------------------------------------------------
import 'package:flutter/widgets.dart';
import 'package:graphview/GraphView.dart';

class GraphViewAllNodes extends GraphView {
  GraphViewAllNodes.builder({
    Key? key,
    required Graph graph,
    required Algorithm algorithm,
    Paint? paint,
    required NodeWidgetBuilder builder,
    GraphViewController? controller,
    bool animated = true,
    ValueKey? initialNode,
    bool autoZoomToFit = false,
    Duration? panAnimationDuration,
    Duration? toggleAnimationDuration,
    bool centerGraph = false,
  }) : super.builder(
          key: key,
          graph: graph,
          algorithm: algorithm,
          paint: paint,
          builder: builder,
          controller: controller,
          animated: animated,
          initialNode: initialNode,
          autoZoomToFit: autoZoomToFit,
          panAnimationDuration: panAnimationDuration,
          toggleAnimationDuration: toggleAnimationDuration,
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
