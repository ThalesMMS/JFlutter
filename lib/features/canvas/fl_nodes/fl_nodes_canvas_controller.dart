import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';

import '../../../core/models/fsa.dart';
import '../../../presentation/providers/automaton_provider.dart';
import 'base_fl_nodes_canvas_controller.dart';
import 'fl_nodes_automaton_mapper.dart';
import 'fl_nodes_canvas_models.dart';

/// Controller that keeps the [FlNodeEditorController] in sync with the
/// [AutomatonProvider].
class FlNodesCanvasController extends BaseFlNodesCanvasController<AutomatonProvider, FSA> {
  FlNodesCanvasController({
    required AutomatonProvider automatonProvider,
    FlNodeEditorController? editorController,
  }) : super(
          notifier: automatonProvider,
          editorController: editorController,
        );

  AutomatonProvider get _provider => notifier;

  @override
  String get statePrototypeId => 'automaton_state';

  @override
  String get stateDescription => 'Estado do autômato finito';

  @override
  FlNodesAutomatonSnapshot toSnapshot(FSA? automaton) {
    return FlNodesAutomatonMapper.toSnapshot(automaton);
  }

  @override
  FlNodesCanvasNode createCanvasNode(NodeInstance node) {
    final label = resolveLabel(node);
    final isFirstState = nodesCache.isEmpty;
    return FlNodesCanvasNode(
      id: node.id,
      label: label,
      x: node.offset.dx,
      y: node.offset.dy,
      isInitial: isFirstState,
      isAccepting: false,
    );
  }

  @override
  void onCanvasNodeAdded(FlNodesCanvasNode node) {
    _provider.addState(
      id: node.id,
      label: node.label,
      x: node.x,
      y: node.y,
      isInitial: node.isInitial ? true : null,
      isAccepting: node.isAccepting,
    );
  }

  @override
  void onCanvasNodeRemoved(String nodeId) {
    _provider.removeState(id: nodeId);
  }

  @override
  void onCanvasNodesMoved(Map<String, FlNodesCanvasNode> updatedNodes) {
    for (final entry in updatedNodes.entries) {
      _provider.moveState(
        id: entry.key,
        x: entry.value.x,
        y: entry.value.y,
      );
    }
  }

  @override
  void onCanvasNodeLabelUpdated(FlNodesCanvasNode node) {
    _provider.updateStateLabel(
      id: node.id,
      label: node.label.isEmpty ? node.id : node.label,
    );
  }

  @override
  FlNodesCanvasEdge? createEdgeForLink(Link link) {
    return FlNodesCanvasEdge(
      id: link.id,
      fromStateId: link.fromTo.from,
      toStateId: link.fromTo.to,
      symbols: const <String>[],
      lambdaSymbol: null,
      controlPointX: null,
      controlPointY: null,
    );
  }

  @override
  void onCanvasEdgeAdded(FlNodesCanvasEdge edge) {
    _provider.addOrUpdateTransition(
      id: edge.id,
      fromStateId: edge.fromStateId,
      toStateId: edge.toStateId,
      label: edge.label,
      controlPointX: edge.controlPointX,
      controlPointY: edge.controlPointY,
    );
  }

  @override
  void onCanvasEdgeRemoved(String edgeId) {
    _provider.removeTransition(id: edgeId);
  }

  @override
  void onCanvasEdgeGeometryUpdated(FlNodesCanvasEdge edge, Offset controlPoint) {
    _provider.addOrUpdateTransition(
      id: edge.id,
      fromStateId: edge.fromStateId,
      toStateId: edge.toStateId,
      label: edge.label,
      controlPointX: controlPoint.dx,
      controlPointY: controlPoint.dy,
    );
  }

  /// Synchronises the fl_nodes controller with the latest [automaton].
  void synchronize(FSA? automaton) {
    synchronizeCanvas(automaton);
  }
}
