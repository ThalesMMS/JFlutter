import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/tm.dart';
import '../../../core/models/tm_transition.dart';
import '../../../presentation/providers/tm_editor_provider.dart';
import 'base_fl_nodes_canvas_controller.dart';
import 'fl_nodes_canvas_models.dart';
import 'fl_nodes_tm_mapper.dart';

/// Controller responsible for synchronising the fl_nodes editor with the
/// [TMEditorNotifier].
class FlNodesTmCanvasController
    extends BaseFlNodesCanvasController<TMEditorNotifier, TM> {
  FlNodesTmCanvasController({
    required TMEditorNotifier editorNotifier,
    FlNodeEditorController? editorController,
  }) : super(
          notifier: editorNotifier,
          editorController: editorController,
        );

  TMEditorNotifier get _notifier => notifier;

  @override
  String get statePrototypeId => 'tm_state';

  @override
  String get stateDescription => 'Estado da Máquina de Turing';

  @override
  FlNodesAutomatonSnapshot toSnapshot(TM? machine) {
    return FlNodesTmMapper.toSnapshot(machine);
  }

  @override
  FlNodesCanvasNode createCanvasNode(NodeInstance node) {
    final label = resolveLabel(node);
    return FlNodesCanvasNode(
      id: node.id,
      label: label,
      x: node.offset.dx,
      y: node.offset.dy,
      isInitial: false,
      isAccepting: false,
    );
  }

  @override
  void onCanvasNodeAdded(FlNodesCanvasNode node) {
    _notifier.upsertState(
      id: node.id,
      label: node.label,
      x: node.x,
      y: node.y,
    );
  }

  @override
  void onCanvasNodeRemoved(String nodeId) {
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
      writeSymbol: '',
      direction: TapeDirection.right,
      tapeNumber: 0,
    );
  }

  @override
  void onCanvasEdgeAdded(FlNodesCanvasEdge edge) {
    _notifier.addOrUpdateTransition(
      id: edge.id,
      fromStateId: edge.fromStateId,
      toStateId: edge.toStateId,
      readSymbol: edge.readSymbol,
      writeSymbol: edge.writeSymbol,
      direction: edge.direction,
    );
  }

  @override
  void onCanvasEdgeRemoved(String edgeId) {
    _notifier.removeTransition(id: edgeId);
  }

  @override
  void onCanvasEdgeGeometryUpdated(FlNodesCanvasEdge edge, Offset controlPoint) {
    _notifier.addOrUpdateTransition(
      id: edge.id,
      fromStateId: edge.fromStateId,
      toStateId: edge.toStateId,
      readSymbol: edge.readSymbol,
      writeSymbol: edge.writeSymbol,
      direction: edge.direction,
      controlPoint: Vector2(controlPoint.dx, controlPoint.dy),
    );
  }

  /// Synchronises the fl_nodes controller with the latest [machine].
  void synchronize(TM? machine) {
    synchronizeCanvas(machine);
  }
}
