import 'dart:async';

import 'package:fl_nodes/fl_nodes.dart';
// ignore: implementation_imports
import 'package:fl_nodes/src/core/models/events.dart'
    show DragSelectionEndEvent;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../core/models/tm.dart';
import '../../../core/models/tm_transition.dart';
import '../../../presentation/providers/tm_editor_provider.dart';
import 'fl_nodes_canvas_models.dart';
import 'fl_nodes_highlight_controller.dart';
import 'fl_nodes_label_field_editor.dart';
import 'fl_nodes_tm_mapper.dart';
import 'fl_nodes_viewport_highlight_mixin.dart';
import 'link_geometry_event_utils.dart';

/// Controller responsible for synchronising the fl_nodes editor with the
/// [TMEditorNotifier].
class FlNodesTmCanvasController
    with FlNodesViewportHighlightMixin
    implements FlNodesHighlightController {
  FlNodesTmCanvasController({
    required TMEditorNotifier editorNotifier,
    FlNodeEditorController? editorController,
  }) : _notifier = editorNotifier,
       controller = editorController ?? FlNodeEditorController() {
    _registerPrototypes();
    _subscription = controller.eventBus.events.listen(_handleEvent);
  }

  final TMEditorNotifier _notifier;
  final FlNodeEditorController controller;

  final Map<String, FlNodesCanvasNode> _nodes = {};
  final Map<String, FlNodesCanvasEdge> _edges = {};
  StreamSubscription<NodeEditorEvent>? _subscription;
  bool _isSynchronizing = false;

  int get nodeCount => _nodes.length;
  int get edgeCount => _edges.length;
  Iterable<FlNodesCanvasNode> get nodes => _nodes.values;
  Iterable<FlNodesCanvasEdge> get edges => _edges.values;
  FlNodesCanvasNode? nodeById(String id) => _nodes[id];
  FlNodesCanvasEdge? edgeById(String id) => _edges[id];

  @override
  Map<String, FlNodesCanvasNode> get nodesCache => _nodes;

  static const String _statePrototypeId = 'tm_state';
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
    description: (_) => 'Estado da Máquina de Turing',
    ports: [_inputPortPrototype, _outputPortPrototype],
    fields: [_labelFieldPrototype],
    onExecute: (ports, fields, execState, forward, put) async {},
  );

  void dispose() {
    _subscription?.cancel();
    disposeViewportHighlight();
    controller.dispose();
  }

  void addStateAtCenter() {
    final center = -controller.viewportOffset;
    controller.addNode(_statePrototypeId, offset: center);
  }

  void addStateAt(Offset worldPosition) {
    controller.addNode(_statePrototypeId, offset: worldPosition);
  }

  void _registerPrototypes() {
    controller.registerNodePrototype(_statePrototype);
  }

  void synchronize(TM? machine) {
    final snapshot = FlNodesTmMapper.toSnapshot(machine);
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

    if (highlightedTransitionIds.isNotEmpty ||
        highlightNotifier.value.transitionIds.isNotEmpty) {
      updateLinkHighlights(highlightedTransitionIds);
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

    final controlPointVector = Vector2(updatedX, updatedY);

    _notifier.addOrUpdateTransition(
      id: updatedEdge.id,
      fromStateId: updatedEdge.fromStateId,
      toStateId: updatedEdge.toStateId,
      readSymbol: updatedEdge.readSymbol,
      writeSymbol: updatedEdge.writeSymbol,
      direction: updatedEdge.direction,
      controlPoint: controlPointVector,
    );
  }

  void _handleNodeAdded(NodeInstance node) {
    final label = _resolveLabel(node);
    final canvasNode = FlNodesCanvasNode(
      id: node.id,
      label: label,
      x: node.offset.dx,
      y: node.offset.dy,
      isInitial: false,
      isAccepting: false,
    );
    _nodes[node.id] = canvasNode;
    _notifier.upsertState(
      id: canvasNode.id,
      label: canvasNode.label,
      x: canvasNode.x,
      y: canvasNode.y,
    );
  }

  void _handleNodeRemoved(NodeInstance node) {
    _nodes.remove(node.id);
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
      writeSymbol: '',
      direction: TapeDirection.right,
      tapeNumber: 0,
    );
    _edges[edge.id] = edge;
    if (highlightedTransitionIds.contains(edge.id)) {
      updateLinkHighlights(highlightedTransitionIds);
    }
    _notifier.addOrUpdateTransition(
      id: edge.id,
      fromStateId: edge.fromStateId,
      toStateId: edge.toStateId,
      readSymbol: edge.readSymbol,
      writeSymbol: edge.writeSymbol,
      direction: edge.direction,
    );
  }

  void _handleLinkRemoved(Link link) {
    _edges.remove(link.id);
    _notifier.removeTransition(id: link.id);
  }

  String _resolveLabel(NodeInstance node) {
    final field = node.fields[_labelFieldId];
    final data = field?.data;
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return node.id;
  }
}
