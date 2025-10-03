import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/pda.dart';
import '../../../presentation/providers/pda_editor_provider.dart';
import 'base_fl_nodes_canvas_controller.dart';
import 'fl_nodes_canvas_models.dart';
import 'fl_nodes_pda_mapper.dart';

/// Controller responsible for synchronising the fl_nodes editor with the
/// [PDAEditorNotifier].
class FlNodesPdaCanvasController
    extends BaseFlNodesCanvasController<PDAEditorNotifier, PDA> {
  FlNodesPdaCanvasController({
    required PDAEditorNotifier editorNotifier,
    FlNodeEditorController? editorController,
  }) : super(
          notifier: editorNotifier,
          editorController: editorController,
        );

  PDAEditorNotifier get _notifier => notifier;

  @override
  String get statePrototypeId => 'pda_state';

  @override
  String get stateDescription => 'Estado do autômato com pilha';

  @override
  FlNodesAutomatonSnapshot toSnapshot(PDA? automaton) {
    return FlNodesPdaMapper.toSnapshot(automaton);
  }

  @override
  FlNodesCanvasNode createCanvasNode(NodeInstance node) {
    final label = resolveLabel(node);
    return FlNodesCanvasNode(
      id: node.id,
      label: label,
      x: node.offset.dx,
      y: node.offset.dy,
      isInitial: nodesCache.isEmpty,
      isAccepting: false,
    );
  }

  @override
  void onCanvasNodeAdded(FlNodesCanvasNode node) {
    _notifier.addOrUpdateState(
      id: node.id,
      label: node.label,
      x: node.x,
      y: node.y,
    );
  }

  @override
  void onCanvasNodeRemoved(String nodeId) {
    final orphanedEdges = edgesCache.entries
        .where(
          (entry) =>
              entry.value.fromStateId == nodeId ||
              entry.value.toStateId == nodeId,
        )
        .map((entry) => entry.key)
        .toList(growable: false);

    for (final edgeId in orphanedEdges) {
      edgesCache.remove(edgeId);
      _notifier.removeTransition(id: edgeId);
    }

    _notifier.removeState(id: nodeId);
  }

  @override
  void onCanvasNodesMoved(Map<String, FlNodesCanvasNode> updatedNodes) {
    for (final entry in updatedNodes.entries) {
      _notifier.moveState(
        id: entry.key,
        x: entry.value.x,
        y: entry.value.y,
      );
    }
  }

  @override
  void onCanvasNodeLabelUpdated(FlNodesCanvasNode node) {
    _notifier.updateStateLabel(
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
      readSymbol: '',
      popSymbol: '',
      pushSymbol: '',
      isLambdaInput: true,
      isLambdaPop: true,
      isLambdaPush: true,
    );
  }

  @override
  void onCanvasEdgeAdded(FlNodesCanvasEdge edge) {
    _notifier.upsertTransition(
      id: edge.id,
      fromStateId: edge.fromStateId,
      toStateId: edge.toStateId,
      readSymbol: edge.readSymbol,
      popSymbol: edge.popSymbol,
      pushSymbol: edge.pushSymbol,
      isLambdaInput: edge.isLambdaInput,
      isLambdaPop: edge.isLambdaPop,
      isLambdaPush: edge.isLambdaPush,
    );
  }

  @override
  void onCanvasEdgeRemoved(String edgeId) {
    _notifier.removeTransition(id: edgeId);
  }

  @override
  void onCanvasEdgeGeometryUpdated(FlNodesCanvasEdge edge, Offset controlPoint) {
    _notifier.upsertTransition(
      id: edge.id,
      fromStateId: edge.fromStateId,
      toStateId: edge.toStateId,
      label: edge.label,
      readSymbol: edge.readSymbol,
      popSymbol: edge.popSymbol,
      pushSymbol: edge.pushSymbol,
      isLambdaInput: edge.isLambdaInput,
      isLambdaPop: edge.isLambdaPop,
      isLambdaPush: edge.isLambdaPush,
      controlPoint: Vector2(controlPoint.dx, controlPoint.dy),
    );
  }

  /// Synchronises the fl_nodes controller with the latest [automaton].
  void synchronize(PDA? automaton) {
    synchronizeCanvas(automaton);
  }
}
