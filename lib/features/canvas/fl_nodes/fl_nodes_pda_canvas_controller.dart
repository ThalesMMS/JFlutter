import 'dart:math' as math;

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
  PDA? get currentDomainData => _notifier.state.pda;

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
    performMutation(() {
      _notifier.addOrUpdateState(
        id: node.id,
        label: node.label,
        x: node.x,
        y: node.y,
      );
    });
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

    performMutation(() {
      for (final edgeId in orphanedEdges) {
        edgesCache.remove(edgeId);
        _notifier.removeTransition(id: edgeId);
      }

      _notifier.removeState(id: nodeId);
    });
  }

  @override
  void onCanvasNodesMoved(Map<String, FlNodesCanvasNode> updatedNodes) {
    performMutation(() {
      for (final entry in updatedNodes.entries) {
        _notifier.moveState(
          id: entry.key,
          x: entry.value.x,
          y: entry.value.y,
        );
      }
    });
  }

  @override
  void onCanvasNodeLabelUpdated(FlNodesCanvasNode node) {
    performMutation(() {
      _notifier.updateStateLabel(
        id: node.id,
        label: node.label.isEmpty ? node.id : node.label,
      );
    });
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
    performMutation(() {
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
    });
  }

  @override
  void onCanvasEdgeRemoved(String edgeId) {
    performMutation(() {
      _notifier.removeTransition(id: edgeId);
    });
  }

  @override
  void onCanvasEdgeGeometryUpdated(FlNodesCanvasEdge edge, Offset controlPoint) {
    performMutation(() {
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
    });
  }

  /// Synchronises the fl_nodes controller with the latest [automaton].
  void synchronize(PDA? automaton) {
    synchronizeCanvas(automaton);
  }

  @override
  void applySnapshotToDomain(FlNodesAutomatonSnapshot snapshot) {
    final template = _notifier.state.pda ??
        PDA(
          id: snapshot.metadata.id ?? 'pda_${DateTime.now().microsecondsSinceEpoch}',
          name: snapshot.metadata.name ?? 'Canvas PDA',
          states: const {},
          transitions: const {},
          alphabet: snapshot.metadata.alphabet.toSet(),
          initialState: null,
          acceptingStates: const {},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle<double>(0, 0, 800, 600),
          stackAlphabet: const {'Z'},
          initialStackSymbol: 'Z',
          panOffset: Vector2.zero(),
          zoomLevel: 1.0,
        );

    final merged = FlNodesPdaMapper.mergeIntoTemplate(snapshot, template).copyWith(
      id: snapshot.metadata.id ?? template.id,
      name: snapshot.metadata.name ?? template.name,
      alphabet: snapshot.metadata.alphabet.isNotEmpty
          ? snapshot.metadata.alphabet.toSet()
          : template.alphabet,
      modified: DateTime.now(),
    );

    _notifier.setPda(merged);
    synchronize(merged);
  }
}
