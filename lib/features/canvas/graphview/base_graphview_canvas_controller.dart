/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/features/canvas/graphview/base_graphview_canvas_controller.dart
/// Descrição: Implementa o controlador base do GraphView, lidando com histórico
///            de snapshots, animações de camera e integrações de destaque.
/// ---------------------------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../../../core/models/simulation_highlight.dart';
import 'graphview_canvas_models.dart';
import 'graphview_highlight_controller.dart';
import 'graphview_viewport_highlight_mixin.dart';

void _logGraphViewBase(String message) {
  if (kDebugMode) {
    debugPrint('[GraphViewBase] $message');
  }
}

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
  }) : graph = graph ?? Graph(),
       graphController =
           viewController ??
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

  Size? _viewportSize;

  @protected
  Map<String, Node> get graphNodes => _graphNodes;

  @protected
  Map<String, Edge> get graphEdges => _graphEdges;

  @override
  Map<String, GraphViewCanvasNode> get nodesCache => _nodes;

  @override
  Map<String, GraphViewCanvasEdge> get edgesCache => _edges;

  @override
  Size? get currentViewportSize => _viewportSize;

  Iterable<GraphViewCanvasNode> get nodes => _nodes.values;
  Iterable<GraphViewCanvasEdge> get edges => _edges.values;

  GraphViewCanvasNode? nodeById(String id) => _nodes[id];
  GraphViewCanvasEdge? edgeById(String id) => _edges[id];

  /// Returns the world position of the graph node with the provided [id].
  @visibleForTesting
  Offset? nodePosition(String id) => _graphNodes[id]?.position;

  bool get canUndo => _undoHistory.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;

  /// Returns the last viewport size observed by the controller.
  @visibleForTesting
  Size? get viewportSize => _viewportSize;

  /// Updates the cached viewport [size] used when translating screen
  /// coordinates into world coordinates.
  void updateViewportSize(Size size) {
    if (!size.width.isFinite || !size.height.isFinite) {
      return;
    }
    if (_viewportSize == size) {
      return;
    }
    _viewportSize = size;
    _logGraphViewBase(
      'Viewport size updated (${size.width.toStringAsFixed(1)} x ${size.height.toStringAsFixed(1)})',
    );
  }

  /// Converts the provided [viewportOffset] from viewport space into world
  /// coordinates based on the current transformation matrix.
  @protected
  Offset toWorldOffset(Offset viewportOffset) {
    final transformation = graphController.transformationController;
    if (transformation == null) {
      return viewportOffset;
    }

    final matrix = Matrix4.copy(transformation.value);
    final determinant = matrix.invert();
    if (determinant == 0) {
      return viewportOffset;
    }

    final vector = matrix.transform3(
      vmath.Vector3(viewportOffset.dx, viewportOffset.dy, 0),
    );
    return Offset(vector.x, vector.y);
  }

  /// Returns the world-space coordinates corresponding to the visual centre of
  /// the viewport. When the viewport dimensions are unknown the origin is
  /// returned.
  @protected
  Offset resolveViewportCenterWorld() {
    final size = _viewportSize;
    final viewportCenter = size != null
        ? Offset(size.width / 2, size.height / 2)
        : Offset.zero;
    final world = toWorldOffset(viewportCenter);
    _logGraphViewBase(
      'Viewport centre resolved to (${world.dx.toStringAsFixed(2)}, ${world.dy.toStringAsFixed(2)})',
    );
    return world;
  }

  /// Releases the resources owned by the controller.
  void dispose() {
    _logGraphViewBase(
      'Disposing controller (ownsTransformation=$_ownsTransformationController)',
    );
    disposeViewportHighlight();
    // GraphView internally disposes the transformation controller when the
    // widget is removed from the tree. Disposing it here causes the controller
    // to be accessed after disposal during widget teardown, so we intentionally
    // skip manual disposal even when we created it.
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
      _logGraphViewBase('performMutation invoked during synchronization');
      mutation();
      return;
    }

    final entry = _captureHistoryEntry();
    if (entry != null) {
      _undoHistory.add(entry);
      _redoHistory.clear();
      _logGraphViewBase(
        'History snapshot captured (#undo=${_undoHistory.length}, #redo=${_redoHistory.length})',
      );
    } else {
      _logGraphViewBase('History snapshot skipped (serialization failed)');
    }

    mutation();
    _logGraphViewBase(
      'Mutation executed, synchronizing graph with domain data',
    );
    synchronizeGraph(currentDomainData, fromMutation: true);
  }

  /// Restores the previous canvas snapshot if available.
  bool undo() {
    if (_undoHistory.isEmpty) {
      _logGraphViewBase('Undo requested with empty history');
      return false;
    }

    final currentEntry = _captureHistoryEntry();
    if (currentEntry != null) {
      _redoHistory.add(currentEntry);
    }

    final entry = _undoHistory.removeLast();
    _applyHistoryEntry(entry);
    _logGraphViewBase(
      'Undo applied (#undo=${_undoHistory.length}, #redo=${_redoHistory.length})',
    );
    return true;
  }

  /// Reapplies the most recently undone canvas snapshot if available.
  bool redo() {
    if (_redoHistory.isEmpty) {
      _logGraphViewBase('Redo requested with empty history');
      return false;
    }

    final currentEntry = _captureHistoryEntry();
    if (currentEntry != null) {
      _undoHistory.add(currentEntry);
    }

    final entry = _redoHistory.removeLast();
    _applyHistoryEntry(entry);
    _logGraphViewBase(
      'Redo applied (#undo=${_undoHistory.length}, #redo=${_redoHistory.length})',
    );
    return true;
  }

  /// Synchronises the canvas with the provided domain [data].
  @protected
  void synchronizeGraph(TSnapshot? data, {bool fromMutation = false}) {
    final isExternalSync = !fromMutation;
    if (isExternalSync &&
        (_undoHistory.isNotEmpty || _redoHistory.isNotEmpty)) {
      _undoHistory.clear();
      _redoHistory.clear();
      graphRevision.value++;
      _logGraphViewBase(
        'History cleared due to external synchronization (revision=${graphRevision.value})',
      );
    }

    final snapshot = toSnapshot(data);
    final incomingNodes = {for (final node in snapshot.nodes) node.id: node};
    final incomingEdges = {for (final edge in snapshot.edges) edge.id: edge};
    _logGraphViewBase(
      'Synchronizing graph (incomingNodes=${incomingNodes.length}, incomingEdges=${incomingEdges.length})',
    );

    final previousHighlight = SimulationHighlight(
      stateIds: Set<String>.from(highlightNotifier.value.stateIds),
      transitionIds: Set<String>.from(highlightNotifier.value.transitionIds),
    );

    _isSynchronizing = true;

    var nodesDirty = false;
    var edgesDirty = false;

    try {
      final removedNodeIds = _nodes.keys
          .where((id) => !incomingNodes.containsKey(id))
          .toList();
      for (final nodeId in removedNodeIds) {
        _nodes.remove(nodeId);
        final nodeInstance = _graphNodes.remove(nodeId);
        if (nodeInstance != null) {
          graph.removeNode(nodeInstance);
          nodesDirty = true;
        }

        final affectedEdges = _edges.values
            .where(
              (edge) => edge.fromStateId == nodeId || edge.toStateId == nodeId,
            )
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

      final removedEdgeIds = _edges.keys
          .where((id) => !incomingEdges.containsKey(id))
          .toList();
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
            existingNode.x != incomingNode.x ||
            existingNode.y != incomingNode.y;
        final hasMetadataChanged =
            existingNode.label != incomingNode.label ||
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
      _logGraphViewBase(
        'Highlight updated (states=${sanitizedHighlight.stateIds.length}, transitions=${sanitizedHighlight.transitionIds.length})',
      );

      if (nodesDirty || edgesDirty) {
        graph.notifyGraphObserver();
        graphRevision.value++;
        _logGraphViewBase(
          'Graph refreshed (nodes=${_nodes.length}, edges=${_edges.length}, revision=${graphRevision.value})',
        );
      } else {
        _logGraphViewBase(
          'Graph synchronization completed without structural changes',
        );
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

    _logGraphViewBase('Pruning highlight for $edgeId');
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
      final encoded = GraphViewAutomatonSnapshot.fromJson(snapshot.toJson());
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
    _logGraphViewBase(
      'History entry applied (states=${highlight.stateIds.length}, transitions=${highlight.transitionIds.length})',
    );
  }
}
