import 'dart:async';

import 'package:fl_nodes/fl_nodes.dart';
// ignore: implementation_imports
import 'package:fl_nodes/src/core/models/events.dart'
    show DragSelectionEndEvent;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/pda.dart';
import '../../../core/models/simulation_highlight.dart';
import '../../../presentation/providers/pda_editor_provider.dart';
import 'fl_nodes_canvas_models.dart';
import 'fl_nodes_highlight_controller.dart';
import 'fl_nodes_label_field_editor.dart';
import 'fl_nodes_pda_mapper.dart';
import 'link_geometry_event_utils.dart';

/// Controller responsible for synchronising the fl_nodes editor with the
/// [PDAEditorNotifier].
class FlNodesPdaCanvasController implements FlNodesHighlightController {
  FlNodesPdaCanvasController({
    required PDAEditorNotifier editorNotifier,
    FlNodeEditorController? editorController,
  }) : _notifier = editorNotifier,
       controller = editorController ?? FlNodeEditorController() {
    _registerPrototypes();
    _subscription = controller.eventBus.events.listen(_handleEvent);
  }

  final PDAEditorNotifier _notifier;
  final FlNodeEditorController controller;

  final Map<String, FlNodesCanvasNode> _nodes = {};
  final Map<String, FlNodesCanvasEdge> _edges = {};
  final ValueNotifier<SimulationHighlight> highlightNotifier = ValueNotifier(
    SimulationHighlight.empty,
  );
  final Set<String> _highlightedTransitionIds = <String>{};
  StreamSubscription<NodeEditorEvent>? _subscription;
  bool _isSynchronizing = false;

  int get nodeCount => _nodes.length;
  int get edgeCount => _edges.length;
  Iterable<FlNodesCanvasNode> get nodes => _nodes.values;
  Iterable<FlNodesCanvasEdge> get edges => _edges.values;
  FlNodesCanvasNode? nodeById(String id) => _nodes[id];
  FlNodesCanvasEdge? edgeById(String id) => _edges[id];

  static const String _statePrototypeId = 'pda_state';
  static const String _inPortId = 'incoming';
  static const String _outPortId = 'outgoing';
  static const String _labelFieldId = 'label';
  static const double _dragEpsilon = 0.001;

  late final ControlInputPortPrototype _inputPortPrototype =
      ControlInputPortPrototype(
        idName: _inPortId,
        displayName: (_) => 'Entrada',
      );

  late final ControlOutputPortPrototype _outputPortPrototype =
      ControlOutputPortPrototype(
        idName: _outPortId,
        displayName: (_) => 'Saída',
      );

  late final FieldPrototype _labelFieldPrototype = FieldPrototype(
    idName: _labelFieldId,
    displayName: (_) => 'Rótulo',
    dataType: String,
    defaultData: '',
    style: const FlFieldStyle(),
    visualizerBuilder: (value) {
      final text = (value as String?)?.trim();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text == null || text.isEmpty ? 'Sem nome' : text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    },
    editorBuilder: (context, removeOverlay, value, setData) {
      return FlNodesLabelFieldEditor(
        initialValue: (value as String?) ?? '',
        onSubmit: (label) {
          setData(label, eventType: FieldEventType.submit);
          removeOverlay();
        },
        onCancel: () {
          setData(value, eventType: FieldEventType.cancel);
          removeOverlay();
        },
      );
    },
  );

  late final NodePrototype _statePrototype = NodePrototype(
    idName: _statePrototypeId,
    displayName: (_) => 'Estado',
    description: (_) => 'Estado do autômato com pilha',
    ports: [_inputPortPrototype, _outputPortPrototype],
    fields: [_labelFieldPrototype],
    onExecute: (ports, fields, execState, forward, put) async {},
  );

  void dispose() {
    _subscription?.cancel();
    highlightNotifier.dispose();
    controller.dispose();
  }

  void zoomIn() {
    controller.setViewportZoom(
      (controller.viewportZoom * 1.2).clamp(0.05, 10.0),
    );
  }

  void zoomOut() {
    controller.setViewportZoom(
      (controller.viewportZoom / 1.2).clamp(0.05, 10.0),
    );
  }

  void resetView() {
    controller.setViewportOffset(Offset.zero, absolute: true);
    controller.setViewportZoom(1.0);
  }

  void fitToContent() {
    if (_nodes.isEmpty) {
      resetView();
      return;
    }

    final previousNodeSelection = controller.selectedNodeIds.toList();
    final previousLinkSelection = controller.selectedLinkIds.toList();

    controller.focusNodesById(_nodes.keys.toSet());
    controller.clearSelection(isHandled: true);

    if (previousNodeSelection.isNotEmpty) {
      controller.selectNodesById(
        previousNodeSelection.toSet(),
        holdSelection: false,
        isHandled: true,
      );
    }

    if (previousLinkSelection.isNotEmpty) {
      controller.selectLinkById(
        previousLinkSelection.first,
        holdSelection: false,
        isHandled: true,
      );
      for (final linkId in previousLinkSelection.skip(1)) {
        controller.selectLinkById(linkId, holdSelection: true, isHandled: true);
      }
    }
  }

  void addStateAtCenter() {
    final center = -controller.viewportOffset;
    controller.addNode(_statePrototypeId, offset: center);
  }

  @override
  void applyHighlight(SimulationHighlight highlight) {
    _updateLinkHighlights(highlight.transitionIds);
    highlightNotifier.value = highlight;
  }

  @override
  void clearHighlight() {
    _updateLinkHighlights(const <String>{});
    highlightNotifier.value = SimulationHighlight.empty;
  }

  void _registerPrototypes() {
    controller.registerNodePrototype(_statePrototype);
  }

  void synchronize(PDA? automaton) {
    final snapshot = FlNodesPdaMapper.toSnapshot(automaton);
    _isSynchronizing = true;
    controller.clear();
    _nodes
      ..clear()
      ..addEntries(snapshot.nodes.map((node) => MapEntry(node.id, node)));
    _edges
      ..clear()
      ..addEntries(snapshot.edges.map((edge) => MapEntry(edge.id, edge)));

    for (final node in snapshot.nodes) {
      controller.addNodeFromExisting(_buildNodeInstance(node), isHandled: true);
    }

    for (final edge in snapshot.edges) {
      controller.addLinkFromExisting(_buildLink(edge), isHandled: true);
    }

    if (_highlightedTransitionIds.isNotEmpty ||
        highlightNotifier.value.transitionIds.isNotEmpty) {
      _updateLinkHighlights(_highlightedTransitionIds);
    }

    _isSynchronizing = false;
  }

  NodeInstance _buildNodeInstance(FlNodesCanvasNode node) {
    final ports = {
      _inPortId: PortInstance(
        prototype: _inputPortPrototype,
        state: PortState(),
      ),
      _outPortId: PortInstance(
        prototype: _outputPortPrototype,
        state: PortState(),
      ),
    };

    final fields = {
      _labelFieldId: FieldInstance(
        prototype: _labelFieldPrototype,
        data: node.label,
      ),
    };

    return NodeInstance(
      id: node.id,
      prototype: _statePrototype,
      ports: ports,
      fields: fields,
      state: NodeState(),
      offset: Offset(node.x, node.y),
    );
  }

  Link _buildLink(FlNodesCanvasEdge edge) {
    return Link(
      id: edge.id,
      fromTo: (
        from: edge.fromStateId,
        to: edge.toStateId,
        fromPort: _outPortId,
        toPort: _inPortId,
      ),
      state: LinkState(),
    );
  }

  void _handleEvent(NodeEditorEvent event) {
    if (_isSynchronizing || event.isHandled) {
      return;
    }

    final geometryPayload = parseLinkGeometryEvent(event);
    if (geometryPayload != null) {
      _handleLinkGeometryEvent(geometryPayload);
      return;
    }

    if (event is AddNodeEvent) {
      _handleNodeAdded(event.node);
    } else if (event is RemoveNodeEvent) {
      _handleNodeRemoved(event.node);
    } else if (event is DragSelectionEndEvent) {
      _handleSelectionDragged(event.nodeIds);
    } else if (event is NodeFieldEvent) {
      _handleNodeField(event);
    } else if (event is AddLinkEvent) {
      _handleLinkAdded(event.link);
    } else if (event is RemoveLinkEvent) {
      _handleLinkRemoved(event.link);
    }
  }

  void _handleLinkGeometryEvent(LinkGeometryEventPayload payload) {
    final edge = _edges[payload.linkId];
    if (edge == null) {
      return;
    }

    if (!payload.hasControlPoint) {
      return;
    }

    final double updatedX = payload.controlPoint?.dx ?? 0;
    final double updatedY = payload.controlPoint?.dy ?? 0;
    if ((edge.controlPointX ?? 0) == updatedX &&
        (edge.controlPointY ?? 0) == updatedY) {
      return;
    }

    final updatedEdge = edge.copyWith(
      controlPointX: updatedX,
      controlPointY: updatedY,
    );
    _edges[payload.linkId] = updatedEdge;

    final vectorControlPoint = Vector2(updatedX, updatedY);

    _notifier.upsertTransition(
      id: updatedEdge.id,
      fromStateId: updatedEdge.fromStateId,
      toStateId: updatedEdge.toStateId,
      label: updatedEdge.label,
      readSymbol: updatedEdge.readSymbol,
      popSymbol: updatedEdge.popSymbol,
      pushSymbol: updatedEdge.pushSymbol,
      isLambdaInput: updatedEdge.isLambdaInput,
      isLambdaPop: updatedEdge.isLambdaPop,
      isLambdaPush: updatedEdge.isLambdaPush,
      controlPoint: vectorControlPoint,
    );
  }

  void _handleNodeAdded(NodeInstance node) {
    final label = _resolveLabel(node);
    final canvasNode = FlNodesCanvasNode(
      id: node.id,
      label: label,
      x: node.offset.dx,
      y: node.offset.dy,
      isInitial: _nodes.isEmpty,
      isAccepting: false,
    );
    _nodes[node.id] = canvasNode;
    _notifier.addOrUpdateState(
      id: canvasNode.id,
      label: canvasNode.label,
      x: canvasNode.x,
      y: canvasNode.y,
    );
  }

  void _handleNodeRemoved(NodeInstance node) {
    _nodes.remove(node.id);
    final orphanedEdges = _edges.entries
        .where(
          (entry) =>
              entry.value.fromStateId == node.id ||
              entry.value.toStateId == node.id,
        )
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final edgeId in orphanedEdges) {
      _edges.remove(edgeId);
      _notifier.removeTransition(id: edgeId);
    }
    _notifier.removeState(id: node.id);
  }

  void _handleSelectionDragged(Set<String> nodeIds) {
    for (final nodeId in nodeIds) {
      final instance = controller.nodes[nodeId];
      final cachedNode = _nodes[nodeId];
      if (instance == null || cachedNode == null) continue;

      final deltaX = (instance.offset.dx - cachedNode.x).abs();
      final deltaY = (instance.offset.dy - cachedNode.y).abs();
      if (deltaX < _dragEpsilon && deltaY < _dragEpsilon) {
        continue;
      }

      final updatedNode = cachedNode.copyWith(
        x: instance.offset.dx,
        y: instance.offset.dy,
      );
      _nodes[nodeId] = updatedNode;
      _notifier.moveState(
        id: nodeId,
        x: updatedNode.x,
        y: updatedNode.y,
      );
    }
  }

  void _handleNodeField(NodeFieldEvent event) {
    if (event.eventType != FieldEventType.submit) {
      return;
    }
    final updatedNode = _nodes[event.nodeId]?.copyWith(
      label: (event.value as String?)?.trim() ?? '',
    );
    if (updatedNode != null) {
      _nodes[event.nodeId] = updatedNode;
      _notifier.updateStateLabel(
        id: event.nodeId,
        label: updatedNode.label.isEmpty ? event.nodeId : updatedNode.label,
      );
    }
  }

  void _handleLinkAdded(Link link) {
    final fromStateId = link.fromTo.from;
    final toStateId = link.fromTo.to;
    final fromPortId = link.fromTo.fromPort;
    final toPortId = link.fromTo.toPort;

    if (fromPortId != _outPortId || toPortId != _inPortId) {
      return;
    }

    final edge = FlNodesCanvasEdge(
      id: link.id,
      fromStateId: fromStateId,
      toStateId: toStateId,
      symbols: const <String>[],
      readSymbol: '',
      popSymbol: '',
      pushSymbol: '',
      isLambdaInput: true,
      isLambdaPop: true,
      isLambdaPush: true,
    );
    _edges[edge.id] = edge;
    if (_highlightedTransitionIds.contains(edge.id)) {
      _updateLinkHighlights(_highlightedTransitionIds);
    }
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

  void _handleLinkRemoved(Link link) {
    _edges.remove(link.id);
    _notifier.removeTransition(id: link.id);
  }

  FlNodesCanvasNode? nodeById(String id) => _nodes[id];

  FlNodesCanvasEdge? edgeById(String id) => _edges[id];

  String _resolveLabel(NodeInstance node) {
    final field = node.fields[_labelFieldId];
    final data = field?.data;
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return node.id;
  }

  void _updateLinkHighlights(Set<String> transitionIds) {
    final desiredIds = Set<String>.from(transitionIds);
    final idsToVisit = <String>{..._highlightedTransitionIds, ...desiredIds};

    final manualSelection = controller.selectedLinkIds.toSet();
    var hasChanged = false;

    for (final linkId in idsToVisit) {
      final link = controller.linksById[linkId];
      if (link == null) {
        continue;
      }
      final shouldSelect =
          desiredIds.contains(linkId) || manualSelection.contains(linkId);
      if (link.state.isSelected != shouldSelect) {
        link.state.isSelected = shouldSelect;
        hasChanged = true;
      }
    }

    if (hasChanged) {
      controller.linksDataDirty = true;
      controller.notifyListeners();
    }

    _highlightedTransitionIds
      ..clear()
      ..addAll(desiredIds);
  }
}
