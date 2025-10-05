import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import '../../../core/models/simulation_highlight.dart';
import 'graphview_canvas_models.dart';
import 'graphview_highlight_controller.dart';
import 'graphview_viewport_highlight_mixin.dart';

class _GraphHistoryEntry {
  const _GraphHistoryEntry({required this.snapshot, required this.highlight});

  final GraphViewAutomatonSnapshot snapshot;
  final SimulationHighlight highlight;
}

/// Base controller that coordinates GraphView interactions with domain notifiers.
abstract class BaseGraphViewCanvasController<TNotifier, TSnapshot>
    extends GraphViewHighlightController
    with GraphViewViewportHighlightMixin {
  BaseGraphViewCanvasController({
    required this.notifier,
    Graph? graph,
    GraphViewController? viewController,
    TransformationController? transformationController,
  })  : graph = graph ?? Graph(),
        graphController = viewController ??
            GraphViewController(
              transformationController:
                  transformationController ?? TransformationController(),
            ),
        _ownsTransformationController =
            viewController == null && transformationController == null;

  @protected
  final TNotifier notifier;

  @override
  final Graph graph;

  @override
  final GraphViewController graphController;

  final bool _ownsTransformationController;

  final Map<String, GraphViewCanvasNode> _nodes = {};
  final Map<String, GraphViewCanvasEdge> _edges = {};
  final Map<String, Node> _graphNodes = {};
  final Map<String, Edge> _graphEdges = {};

  bool _isSynchronizing = false;

  final List<_GraphHistoryEntry> _undoHistory = [];
  final List<_GraphHistoryEntry> _redoHistory = [];

  @protected
  Map<String, Node> get graphNodes => _graphNodes;

  @protected
  Map<String, Edge> get graphEdges => _graphEdges;

  @override
  Map<String, GraphViewCanvasNode> get nodesCache => _nodes;

  @override
  Map<String, GraphViewCanvasEdge> get edgesCache => _edges;

  Iterable<GraphViewCanvasNode> get nodes => _nodes.values;
  Iterable<GraphViewCanvasEdge> get edges => _edges.values;

  GraphViewCanvasNode? nodeById(String id) => _nodes[id];
  GraphViewCanvasEdge? edgeById(String id) => _edges[id];

  bool get canUndo => _undoHistory.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;

  /// Releases the resources owned by the controller.
  void dispose() {
    disposeViewportHighlight();
    if (_ownsTransformationController) {
      graphController.transformationController?.dispose();
    }
  }

  /// Converts domain state into a snapshot consumed by the canvas.
  @protected
  GraphViewAutomatonSnapshot toSnapshot(TSnapshot? data);

  /// Returns the current domain entity rendered on the canvas.
  @protected
  TSnapshot? get currentDomainData;

  /// Applies a [snapshot] to the underlying domain notifier and synchronises
  /// the canvas state accordingly.
  @protected
  void applySnapshotToDomain(GraphViewAutomatonSnapshot snapshot);

  /// Creates a GraphView node for the provided canvas [node].
  @protected
  Node buildGraphNode(GraphViewCanvasNode node) {
    final instance = Node.Id(node.id);
    instance.position = Offset(node.x, node.y);
    return instance;
  }

  /// Creates a GraphView edge for the provided canvas [edge].
  @protected
  Edge buildGraphEdge(GraphViewCanvasEdge edge, Node from, Node to) {
    return Edge(from, to, key: ValueKey(edge.id));
  }

  /// Records the current canvas state before invoking [mutation].
  @protected
  void performMutation(VoidCallback mutation) {
    if (_isSynchronizing) {
      mutation();
      return;
    }

    final entry = _captureHistoryEntry();
    if (entry != null) {
      _undoHistory.add(entry);
      _redoHistory.clear();
    }

    mutation();
    synchronizeGraph(currentDomainData);
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

  /// Synchronises the canvas with the provided domain [data].
  @protected
  void synchronizeGraph(TSnapshot? data) {
    final snapshot = toSnapshot(data);
    final incomingNodes = {for (final node in snapshot.nodes) node.id: node};
    final incomingEdges = {for (final edge in snapshot.edges) edge.id: edge};

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
        final nodeInstance = _graphNodes.remove(nodeId);
        if (nodeInstance != null) {
          graph.removeNode(nodeInstance);
          nodesDirty = true;
        }

        final affectedEdges = _edges.values
            .where((edge) =>
                edge.fromStateId == nodeId || edge.toStateId == nodeId)
            .map((edge) => edge.id)
            .toList();
        for (final edgeId in affectedEdges) {
          _edges.remove(edgeId);
          final edgeInstance = _graphEdges.remove(edgeId);
          if (edgeInstance != null) {
            graph.removeEdge(edgeInstance);
            edgesDirty = true;
          }
          pruneLinkHighlight(edgeId);
        }
      }

      final removedEdgeIds =
          _edges.keys.where((id) => !incomingEdges.containsKey(id)).toList();
      for (final edgeId in removedEdgeIds) {
        _edges.remove(edgeId);
        final edgeInstance = _graphEdges.remove(edgeId);
        if (edgeInstance != null) {
          graph.removeEdge(edgeInstance);
          edgesDirty = true;
        }
        pruneLinkHighlight(edgeId);
      }

      for (final entry in incomingNodes.entries) {
        final nodeId = entry.key;
        final incomingNode = entry.value;
        final existingNode = _nodes[nodeId];
        final nodeInstance = _graphNodes[nodeId];

        if (existingNode == null || nodeInstance == null) {
          final createdNode = buildGraphNode(incomingNode);
          _nodes[nodeId] = incomingNode;
          _graphNodes[nodeId] = createdNode;
          graph.addNode(createdNode);
          nodesDirty = true;
          continue;
        }

        final hasPositionChanged =
            existingNode.x != incomingNode.x || existingNode.y != incomingNode.y;
        final hasMetadataChanged = existingNode.label != incomingNode.label ||
            existingNode.isInitial != incomingNode.isInitial ||
            existingNode.isAccepting != incomingNode.isAccepting;

        if (hasPositionChanged || hasMetadataChanged) {
          nodeInstance.position = Offset(incomingNode.x, incomingNode.y);
          nodesDirty = true;
        }

        _nodes[nodeId] = incomingNode;
      }

      for (final entry in incomingEdges.entries) {
        final edgeId = entry.key;
        final incomingEdge = entry.value;
        final existingEdge = _edges[edgeId];
        final edgeInstance = _graphEdges[edgeId];

        if (existingEdge == null || edgeInstance == null) {
          final fromNode = _graphNodes[incomingEdge.fromStateId];
          final toNode = _graphNodes[incomingEdge.toStateId];
          if (fromNode == null || toNode == null) {
            continue;
          }
          final createdEdge = buildGraphEdge(incomingEdge, fromNode, toNode);
          _edges[edgeId] = incomingEdge;
          _graphEdges[edgeId] = createdEdge;
          graph.addEdgeS(createdEdge);
          edgesDirty = true;
          continue;
        }

        if (existingEdge != incomingEdge) {
          _edges[edgeId] = incomingEdge;
          edgesDirty = true;
        }
      }

      final sanitizedHighlight = SimulationHighlight(
        stateIds: previousHighlight.stateIds
            .where((id) => incomingNodes.containsKey(id))
            .toSet(),
        transitionIds: previousHighlight.transitionIds
            .where((id) => incomingEdges.containsKey(id))
            .toSet(),
      );

      updateLinkHighlights(sanitizedHighlight.transitionIds);
      highlightNotifier.value = sanitizedHighlight;

      if (nodesDirty || edgesDirty) {
        graph.notifyGraphObserver();
        graphRevision.value++;
      }
    } finally {
      _isSynchronizing = false;
    }
  }

  @visibleForTesting
  void pruneLinkHighlight(String edgeId) {
    if (!highlightedTransitionIds.contains(edgeId)) {
      return;
    }

    final updatedHighlighted = Set<String>.from(highlightedTransitionIds)
      ..remove(edgeId);
    updateLinkHighlights(updatedHighlighted);

    final currentHighlight = highlightNotifier.value;
    if (currentHighlight.transitionIds.contains(edgeId)) {
      final remaining = Set<String>.from(currentHighlight.transitionIds)
        ..remove(edgeId);
      if (remaining.isEmpty && currentHighlight.stateIds.isEmpty) {
        highlightNotifier.value = SimulationHighlight.empty;
      } else {
        highlightNotifier.value = currentHighlight.copyWith(
          transitionIds: remaining,
        );
      }
    } else if (updatedHighlighted.isEmpty &&
        currentHighlight.transitionIds.isEmpty &&
        currentHighlight.stateIds.isEmpty) {
      highlightNotifier.value = SimulationHighlight.empty;
    }
  }

  _GraphHistoryEntry? _captureHistoryEntry() {
    try {
      final snapshot = toSnapshot(currentDomainData);
      final encoded =
          GraphViewAutomatonSnapshot.fromJson(snapshot.toJson());
      final highlight = SimulationHighlight(
        stateIds: Set<String>.from(highlightNotifier.value.stateIds),
        transitionIds: Set<String>.from(highlightNotifier.value.transitionIds),
      );
      return _GraphHistoryEntry(snapshot: encoded, highlight: highlight);
    } catch (_) {
      return null;
    }
  }

  void _applyHistoryEntry(_GraphHistoryEntry entry) {
    applySnapshotToDomain(entry.snapshot);

    final highlight = SimulationHighlight(
      stateIds: Set<String>.from(entry.highlight.stateIds),
      transitionIds: Set<String>.from(entry.highlight.transitionIds),
    );

    updateLinkHighlights(highlight.transitionIds);
    highlightNotifier.value = highlight;
  }
}
