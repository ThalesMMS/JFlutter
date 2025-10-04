import 'dart:async';

import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/models/simulation_highlight.dart';
import 'fl_nodes_canvas_models.dart';
import 'fl_nodes_highlight_controller.dart';
import 'fl_nodes_label_field_editor.dart';
import 'fl_nodes_viewport_highlight_mixin.dart';
import 'link_geometry_event_utils.dart';
import 'node_editor_event_shims.dart';

class _CanvasHistoryEntry {
  const _CanvasHistoryEntry({
    required this.snapshot,
    required this.highlight,
  });

  final FlNodesAutomatonSnapshot snapshot;
  final SimulationHighlight highlight;
}

/// Base controller that coordinates fl_nodes interactions with domain notifiers.
abstract class BaseFlNodesCanvasController<TNotifier, TSnapshot>
    extends FlNodesHighlightController with FlNodesViewportHighlightMixin {
  BaseFlNodesCanvasController({
    required TNotifier notifier,
    FlNodeEditorController? editorController,
  })  : notifier = notifier,
        controller = editorController ?? FlNodeEditorController() {
    controller.registerNodePrototype(statePrototype);
    _subscription = controller.eventBus.events.listen(_handleEvent);
  }

  @protected
  final TNotifier notifier;

  @override
  final FlNodeEditorController controller;

  final Map<String, FlNodesCanvasNode> _nodes = {};
  final Map<String, FlNodesCanvasEdge> _edges = {};

  final List<_CanvasHistoryEntry> _undoHistory = [];
  final List<_CanvasHistoryEntry> _redoHistory = [];

  StreamSubscription<NodeEditorEvent>? _subscription;
  bool _isSynchronizing = false;

  static const String inPortId = 'incoming';
  static const String outPortId = 'outgoing';
  static const String labelFieldId = 'label';
  static const double dragEpsilon = 0.001;

  late final ControlInputPortPrototype inputPortPrototype =
      ControlInputPortPrototype(
        idName: inPortId,
        displayName: (_) => 'Entrada',
      );

  late final ControlOutputPortPrototype outputPortPrototype =
      ControlOutputPortPrototype(
        idName: outPortId,
        displayName: (_) => 'Saída',
      );

  late final FieldPrototype labelFieldPrototype = FieldPrototype(
    idName: labelFieldId,
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

  late final NodePrototype statePrototype = NodePrototype(
    idName: statePrototypeId,
    displayName: (_) => stateDisplayName,
    description: (_) => stateDescription,
    ports: [inputPortPrototype, outputPortPrototype],
    fields: [labelFieldPrototype],
    onExecute: (ports, fields, execState, forward, put) async {},
  );

  /// Unique identifier for the primary node prototype handled by the canvas.
  String get statePrototypeId;

  /// Human readable description for the canvas node prototype.
  String get stateDescription;

  /// Display name used for the canvas node prototype.
  String get stateDisplayName => 'Estado';

  /// Converts domain state into a snapshot consumed by the canvas.
  @protected
  FlNodesAutomatonSnapshot toSnapshot(TSnapshot? data);

  /// Returns the current domain entity rendered on the canvas.
  @protected
  TSnapshot? get currentDomainData;

  /// Applies a [snapshot] to the underlying domain notifier and synchronises
  /// the canvas state accordingly.
  @protected
  void applySnapshotToDomain(FlNodesAutomatonSnapshot snapshot);

  /// Builds a canvas node representation from the emitted [NodeInstance].
  @protected
  FlNodesCanvasNode createCanvasNode(NodeInstance node);

  /// Notifies subclasses that [node] was added to the canvas.
  @protected
  void onCanvasNodeAdded(FlNodesCanvasNode node);

  /// Notifies subclasses that the node with [nodeId] was removed from the canvas.
  @protected
  void onCanvasNodeRemoved(String nodeId);

  /// Notifies subclasses that a batch of nodes changed their coordinates.
  @protected
  void onCanvasNodesMoved(Map<String, FlNodesCanvasNode> updatedNodes);

  /// Notifies subclasses that [node] had its label updated.
  @protected
  void onCanvasNodeLabelUpdated(FlNodesCanvasNode node);

  /// Creates the canvas edge representation for the provided [link].
  @protected
  FlNodesCanvasEdge? createEdgeForLink(Link link);

  /// Notifies subclasses that [edge] was added to the canvas.
  @protected
  void onCanvasEdgeAdded(FlNodesCanvasEdge edge);

  /// Notifies subclasses that the edge with [edgeId] was removed from the canvas.
  @protected
  void onCanvasEdgeRemoved(String edgeId);

  /// Notifies subclasses that [edge] received a new control point [controlPoint].
  @protected
  void onCanvasEdgeGeometryUpdated(FlNodesCanvasEdge edge, Offset controlPoint);

  /// Exposes the cached edges to subclasses.
  @protected
  Map<String, FlNodesCanvasEdge> get edgesCache => _edges;

  int get nodeCount => _nodes.length;
  int get edgeCount => _edges.length;
  Iterable<FlNodesCanvasNode> get nodes => _nodes.values;
  Iterable<FlNodesCanvasEdge> get edges => _edges.values;
  FlNodesCanvasNode? nodeById(String id) => _nodes[id];
  FlNodesCanvasEdge? edgeById(String id) => _edges[id];

  @override
  Map<String, FlNodesCanvasNode> get nodesCache => _nodes;

  /// Releases the resources owned by the controller.
  void dispose() {
    _subscription?.cancel();
    disposeViewportHighlight();
    controller.dispose();
  }

  bool get canUndo => _undoHistory.isNotEmpty;

  bool get canRedo => _redoHistory.isNotEmpty;

  /// Records the current canvas state before invoking [mutation].
  @protected
  void performMutation(VoidCallback mutation) {
    final entry = _captureHistoryEntry();
    if (entry != null) {
      _undoHistory.add(entry);
      _redoHistory.clear();
    }
    mutation();
  }

  /// Restores the previous canvas snapshot if available.
  bool undo() {
    if (_undoHistory.isEmpty) {
      return false;
    }

    final currentEntry = _captureHistoryEntry();
    if (currentEntry != null) {
      _redoHistory.add(currentEntry);
    }

    final entry = _undoHistory.removeLast();
    _applyHistoryEntry(entry);
    return true;
  }

  /// Reapplies the most recently undone canvas snapshot if available.
  bool redo() {
    if (_redoHistory.isEmpty) {
      return false;
    }

    final currentEntry = _captureHistoryEntry();
    if (currentEntry != null) {
      _undoHistory.add(currentEntry);
    }

    final entry = _redoHistory.removeLast();
    _applyHistoryEntry(entry);
    return true;
  }

  /// Adds a new state centred in the current viewport.
  void addStateAtCenter() {
    final center = -controller.viewportOffset;
    controller.addNode(statePrototypeId, offset: center);
  }

  /// Adds a new state at the provided [worldPosition].
  void addStateAt(Offset worldPosition) {
    controller.addNode(statePrototypeId, offset: worldPosition);
  }

  /// Synchronises the canvas with the provided domain [data].
  @protected
  void synchronizeCanvas(TSnapshot? data) {
    final snapshot = toSnapshot(data);
    final incomingNodes = {
      for (final node in snapshot.nodes) node.id: node,
    };
    final incomingEdges = {
      for (final edge in snapshot.edges) edge.id: edge,
    };

    final previousNodeSelection = controller.selectedNodeIds.toList(growable: false);
    final previousLinkSelection = controller.selectedLinkIds.toList(growable: false);
    final previousHighlight = SimulationHighlight(
      stateIds: Set<String>.from(highlightNotifier.value.stateIds),
      transitionIds: Set<String>.from(highlightNotifier.value.transitionIds),
    );

    _isSynchronizing = true;

    var nodesDirty = false;
    var edgesDirty = false;

    try {
      final removedNodeIds =
          _nodes.keys.where((id) => !incomingNodes.containsKey(id)).toList();
      for (final nodeId in removedNodeIds) {
        _nodes.remove(nodeId);
        controller.removeNodeById(nodeId, isHandled: true);
        nodesDirty = true;
      }

      final removedEdgeIds =
          _edges.keys.where((id) => !incomingEdges.containsKey(id)).toList();
      for (final edgeId in removedEdgeIds) {
        _edges.remove(edgeId);
        controller.removeLinkById(edgeId, isHandled: true);
        pruneLinkHighlight(edgeId);
        edgesDirty = true;
      }

      for (final entry in incomingNodes.entries) {
        final nodeId = entry.key;
        final incomingNode = entry.value;
        final existingNode = _nodes[nodeId];

        if (existingNode == null) {
          _nodes[nodeId] = incomingNode;
          controller.addNodeFromExisting(
            _buildNodeInstance(incomingNode),
            isHandled: true,
          );
          nodesDirty = true;
          continue;
        }

        final hasPositionChanged =
            existingNode.x != incomingNode.x || existingNode.y != incomingNode.y;
        final hasLabelChanged = existingNode.label != incomingNode.label;
        final hasInitialChanged = existingNode.isInitial != incomingNode.isInitial;
        final hasAcceptingChanged =
            existingNode.isAccepting != incomingNode.isAccepting;

        if (hasPositionChanged ||
            hasLabelChanged ||
            hasInitialChanged ||
            hasAcceptingChanged) {
          _nodes[nodeId] = incomingNode;

          final instance = controller.nodes[nodeId];
          if (instance != null) {
            if (hasPositionChanged) {
              instance.offset = Offset(incomingNode.x, incomingNode.y);
              nodesDirty = true;
            }

            if (hasLabelChanged) {
              final field = instance.fields[labelFieldId];
              if (field != null) {
                field.data = incomingNode.label;
                nodesDirty = true;
              }
            }
          }

          if (hasInitialChanged || hasAcceptingChanged) {
            nodesDirty = true;
          }
        } else {
          _nodes[nodeId] = incomingNode;
        }
      }

      for (final entry in incomingEdges.entries) {
        final edgeId = entry.key;
        final incomingEdge = entry.value;
        final existingEdge = _edges[edgeId];

        if (existingEdge == null) {
          _edges[edgeId] = incomingEdge;
          controller.addLinkFromExisting(
            _buildLink(incomingEdge),
            isHandled: true,
          );
          edgesDirty = true;
          continue;
        }

        if (existingEdge != incomingEdge) {
          _edges[edgeId] = incomingEdge;
          edgesDirty = true;
        }
      }

      if (nodesDirty) {
        controller.nodesDataDirty = true;
      }
      if (edgesDirty) {
        controller.linksDataDirty = true;
      }

      final validNodeSelection =
          previousNodeSelection.where((id) => _nodes.containsKey(id)).toSet();
      final validLinkSelection =
          previousLinkSelection.where((id) => _edges.containsKey(id)).toList();

      if (previousNodeSelection.isNotEmpty || previousLinkSelection.isNotEmpty) {
        controller.clearSelection(isHandled: true);
      }

      if (validNodeSelection.isNotEmpty) {
        controller.selectNodesById(
          validNodeSelection,
          holdSelection: false,
          isHandled: true,
        );
      }

      if (validLinkSelection.isNotEmpty) {
        controller.selectLinkById(
          validLinkSelection.first,
          holdSelection: validNodeSelection.isNotEmpty,
          isHandled: true,
        );
        for (final linkId in validLinkSelection.skip(1)) {
          controller.selectLinkById(linkId, holdSelection: true, isHandled: true);
        }
      }

      final sanitizedHighlight = SimulationHighlight(
        stateIds: previousHighlight.stateIds
            .where((id) => _nodes.containsKey(id))
            .toSet(),
        transitionIds: previousHighlight.transitionIds
            .where((id) => _edges.containsKey(id))
            .toSet(),
      );

      updateLinkHighlights(sanitizedHighlight.transitionIds);
      highlightNotifier.value = sanitizedHighlight;

      if (nodesDirty || edgesDirty) {
        controller.notifyListeners();
      }
    } finally {
      _isSynchronizing = false;
    }
  }

  NodeInstance _buildNodeInstance(FlNodesCanvasNode node) {
    final ports = {
      inPortId: PortInstance(
        prototype: inputPortPrototype,
        state: PortState(),
      ),
      outPortId: PortInstance(
        prototype: outputPortPrototype,
        state: PortState(),
      ),
    };

    final fields = {
      labelFieldId: FieldInstance(
        prototype: labelFieldPrototype,
        data: node.label,
      ),
    };

    return NodeInstance(
      id: node.id,
      prototype: statePrototype,
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
        fromPort: outPortId,
        toPort: inPortId,
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

    final dragSelectionPayload = parseDragSelectionEndEvent(event);
    if (dragSelectionPayload != null) {
      _handleSelectionDragged(dragSelectionPayload.nodeIds);
      return;
    }

    if (event is AddNodeEvent) {
      _handleNodeAdded(event.node);
    } else if (event is RemoveNodeEvent) {
      _handleNodeRemoved(event.node);
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
    if (edge == null || !payload.hasControlPoint) {
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

    onCanvasEdgeGeometryUpdated(updatedEdge, Offset(updatedX, updatedY));
  }

  void _handleNodeAdded(NodeInstance node) {
    final canvasNode = createCanvasNode(node);
    _nodes[node.id] = canvasNode;
    onCanvasNodeAdded(canvasNode);
  }

  void _handleNodeRemoved(NodeInstance node) {
    _nodes.remove(node.id);
    onCanvasNodeRemoved(node.id);
  }

  void _handleSelectionDragged(Set<String> nodeIds) {
    final updatedNodes = <String, FlNodesCanvasNode>{};

    for (final nodeId in nodeIds) {
      final instance = controller.nodes[nodeId];
      final cachedNode = _nodes[nodeId];
      if (instance == null || cachedNode == null) {
        continue;
      }

      final deltaX = (instance.offset.dx - cachedNode.x).abs();
      final deltaY = (instance.offset.dy - cachedNode.y).abs();
      if (deltaX < dragEpsilon && deltaY < dragEpsilon) {
        continue;
      }

      final updatedNode = cachedNode.copyWith(
        x: instance.offset.dx,
        y: instance.offset.dy,
      );
      _nodes[nodeId] = updatedNode;
      updatedNodes[nodeId] = updatedNode;
    }

    if (updatedNodes.isNotEmpty) {
      onCanvasNodesMoved(updatedNodes);
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
      onCanvasNodeLabelUpdated(updatedNode);
    }
  }

  void _handleLinkAdded(Link link) {
    final fromStateId = link.fromTo.from;
    final toStateId = link.fromTo.to;
    final fromPortId = link.fromTo.fromPort;
    final toPortId = link.fromTo.toPort;

    if (fromPortId != outPortId || toPortId != inPortId) {
      return;
    }

    final edge = createEdgeForLink(link);
    if (edge == null) {
      return;
    }

    _edges[edge.id] = edge;
    if (highlightedTransitionIds.contains(edge.id)) {
      updateLinkHighlights(highlightedTransitionIds);
    }
    onCanvasEdgeAdded(edge);
  }

  void _handleLinkRemoved(Link link) {
    _edges.remove(link.id);
    pruneLinkHighlight(link.id);
    onCanvasEdgeRemoved(link.id);
  }

  @visibleForTesting
  void pruneLinkHighlight(String linkId) {
    if (!highlightedTransitionIds.contains(linkId)) {
      return;
    }

    final updatedHighlighted = Set<String>.from(highlightedTransitionIds)
      ..remove(linkId);
    updateLinkHighlights(updatedHighlighted);

    final currentHighlight = highlightNotifier.value;
    if (currentHighlight.transitionIds.contains(linkId)) {
      final remainingTransitionIds =
          Set<String>.from(currentHighlight.transitionIds)..remove(linkId);

      if (remainingTransitionIds.isEmpty &&
          currentHighlight.stateIds.isEmpty) {
        highlightNotifier.value = SimulationHighlight.empty;
      } else {
        highlightNotifier.value =
            currentHighlight.copyWith(transitionIds: remainingTransitionIds);
      }
    } else if (updatedHighlighted.isEmpty &&
        currentHighlight.transitionIds.isEmpty &&
        currentHighlight.stateIds.isEmpty) {
      highlightNotifier.value = SimulationHighlight.empty;
    }
  }

  /// Resolves the display label for the provided [node] instance.
  @protected
  String resolveLabel(NodeInstance node) {
    final field = node.fields[labelFieldId];
    final data = field?.data;
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return node.id;
  }

  _CanvasHistoryEntry? _captureHistoryEntry() {
    try {
      final snapshot = toSnapshot(currentDomainData);
      final encoded = FlNodesAutomatonSnapshot.fromJson(snapshot.toJson());
      final highlight = SimulationHighlight(
        stateIds: Set<String>.from(highlightNotifier.value.stateIds),
        transitionIds: Set<String>.from(highlightNotifier.value.transitionIds),
      );
      return _CanvasHistoryEntry(snapshot: encoded, highlight: highlight);
    } catch (_) {
      return null;
    }
  }

  void _applyHistoryEntry(_CanvasHistoryEntry entry) {
    applySnapshotToDomain(entry.snapshot);

    final highlight = SimulationHighlight(
      stateIds: Set<String>.from(entry.highlight.stateIds),
      transitionIds: Set<String>.from(entry.highlight.transitionIds),
    );

    updateLinkHighlights(highlight.transitionIds);
    highlightNotifier.value = highlight;
  }
}
