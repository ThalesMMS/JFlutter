import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../../core/constants/automaton_canvas.dart';
import '../../core/models/simulation_highlight.dart';
import '../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_all_nodes_builder.dart';
import '../../features/canvas/graphview/graphview_canvas_models.dart';
import '../../features/canvas/graphview/graphview_link_overlay_utils.dart';
import 'automaton_canvas_tool.dart';

const double _kNodeDiameter = kAutomatonStateDiameter;
const double _kNodeRadius = _kNodeDiameter / 2;

class GraphViewTransitionSelection {
  const GraphViewTransitionSelection._({required this.createNew, this.edge});

  const GraphViewTransitionSelection.edit(GraphViewCanvasEdge edge)
    : this._(createNew: false, edge: edge);

  const GraphViewTransitionSelection.createNew() : this._(createNew: true);

  final bool createNew;
  final GraphViewCanvasEdge? edge;
}

class GraphViewTransitionOverlayState<T> {
  const GraphViewTransitionOverlayState({
    required this.fromStateId,
    required this.toStateId,
    required this.data,
    required this.worldAnchor,
    required this.overlayPosition,
    this.transitionId,
  });

  final String fromStateId;
  final String toStateId;
  final T data;
  final Offset worldAnchor;
  final Offset overlayPosition;
  final String? transitionId;

  GraphViewTransitionOverlayState<T> copyWith({
    T? data,
    Offset? worldAnchor,
    Offset? overlayPosition,
  }) {
    return GraphViewTransitionOverlayState<T>(
      fromStateId: fromStateId,
      toStateId: toStateId,
      data: data ?? this.data,
      worldAnchor: worldAnchor ?? this.worldAnchor,
      overlayPosition: overlayPosition ?? this.overlayPosition,
      transitionId: transitionId,
    );
  }
}

typedef GraphViewEdgePainterBuilder =
    CustomPainter Function({
      required List<GraphViewCanvasEdge> edges,
      required List<GraphViewCanvasNode> nodes,
      required SimulationHighlight highlight,
      required ThemeData theme,
      required Set<String> selectedTransitions,
    });

typedef GraphViewNodeBuilder =
    Widget Function(
      BuildContext context,
      GraphViewCanvasNode node,
      SimulationHighlight highlight,
      bool isTransitionSource,
    );

typedef GraphViewTransitionOverlayBuilder<T> =
    Widget Function(
      BuildContext context,
      GraphViewTransitionOverlayState<T> state,
      void Function(T) onSubmit,
      VoidCallback onCancel,
    );

typedef GraphViewTransitionFallbackEditor<T> =
    Future<T?> Function(
      BuildContext context,
      GraphViewTransitionOverlayState<T> state,
    );

typedef GraphViewTransitionSelectionPrompt =
    Future<GraphViewTransitionSelection> Function(
      BuildContext context,
      List<GraphViewCanvasEdge> edges,
    );

class GraphViewTransitionDelegate<T> {
  const GraphViewTransitionDelegate({
    required this.buildDefaultData,
    required this.dataFromEdge,
    required this.commit,
    required this.buildOverlay,
    this.buildFallbackEditor,
    this.selectionPrompt,
  });

  final T Function(String fromStateId, String toStateId) buildDefaultData;
  final T Function(GraphViewCanvasEdge edge) dataFromEdge;
  final void Function(
    String fromStateId,
    String toStateId,
    Offset worldAnchor,
    T data,
    String? transitionId,
  )
  commit;
  final GraphViewTransitionOverlayBuilder<T> buildOverlay;
  final GraphViewTransitionFallbackEditor<T>? buildFallbackEditor;
  final GraphViewTransitionSelectionPrompt? selectionPrompt;
}

class GraphViewInteractiveCanvas<T> extends StatefulWidget {
  const GraphViewInteractiveCanvas({
    super.key,
    required this.canvasKey,
    required this.controller,
    required this.algorithmBuilder,
    required this.toolController,
    required this.transitionDelegate,
    required this.nodeBuilder,
    required this.edgePainterBuilder,
    this.transitionToolLabel,
  });

  final GlobalKey canvasKey;
  final BaseGraphViewCanvasController<dynamic, dynamic> controller;
  final SugiyamaAlgorithm Function(
    BaseGraphViewCanvasController<dynamic, dynamic> controller,
  )
  algorithmBuilder;
  final AutomatonCanvasToolController toolController;
  final GraphViewTransitionDelegate<T> transitionDelegate;
  final GraphViewNodeBuilder nodeBuilder;
  final GraphViewEdgePainterBuilder edgePainterBuilder;
  final String? transitionToolLabel;

  @override
  State<GraphViewInteractiveCanvas<T>> createState() =>
      _GraphViewInteractiveCanvasState<T>();
}

class _GraphViewInteractiveCanvasState<T>
    extends State<GraphViewInteractiveCanvas<T>> {
  AutomatonCanvasToolController get _toolController => widget.toolController;
  BaseGraphViewCanvasController<dynamic, dynamic> get _controller =>
      widget.controller;

  late AutomatonCanvasTool _activeTool = _toolController.activeTool;
  late SugiyamaAlgorithm _algorithm = widget.algorithmBuilder(
    widget.controller,
  );
  final Set<String> _selectedTransitions = <String>{};
  String? _transitionSourceId;
  OverlayEntry? _transitionOverlayEntry;
  final ValueNotifier<GraphViewTransitionOverlayState<T>?>
  _transitionOverlayState = ValueNotifier<GraphViewTransitionOverlayState<T>?>(
    null,
  );
  bool _suppressCanvasPan = false;
  String? _draggingNodeId;
  Offset? _dragStartWorldPosition;
  Offset? _dragStartNodeCenter;
  final GestureArenaTeam _gestureArenaTeam = GestureArenaTeam();
  String? _lastTapNodeId;
  DateTime? _lastTapTimestamp;
  bool _isDraggingNode = false;
  bool _didMoveDraggedNode = false;

  TransformationController? get _transformationController =>
      _controller.graphController.transformationController;

  @override
  void initState() {
    super.initState();
    _toolController.addListener(_handleActiveToolChanged);
    _controller.graphRevision.addListener(_handleGraphRevisionChanged);
    _transformationController?.addListener(_onTransformationChanged);
  }

  @override
  void didUpdateWidget(covariant GraphViewInteractiveCanvas<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.toolController != widget.toolController) {
      oldWidget.toolController.removeListener(_handleActiveToolChanged);
      widget.toolController.addListener(_handleActiveToolChanged);
      _activeTool = widget.toolController.activeTool;
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.graphRevision.removeListener(
        _handleGraphRevisionChanged,
      );
      oldWidget.controller.graphController.transformationController
          ?.removeListener(_onTransformationChanged);
      widget.controller.graphRevision.addListener(_handleGraphRevisionChanged);
      _transformationController?.addListener(_onTransformationChanged);
      _algorithm = widget.algorithmBuilder(widget.controller);
      _hideTransitionOverlay();
    } else if (oldWidget.algorithmBuilder != widget.algorithmBuilder) {
      _algorithm = widget.algorithmBuilder(widget.controller);
    }
  }

  @override
  void dispose() {
    _controller.graphRevision.removeListener(_handleGraphRevisionChanged);
    _transformationController?.removeListener(_onTransformationChanged);
    _toolController.removeListener(_handleActiveToolChanged);
    _transitionOverlayEntry?.remove();
    _transitionOverlayState.dispose();
    super.dispose();
  }

  void _handleActiveToolChanged() {
    final nextTool = _toolController.activeTool;
    if (nextTool == _activeTool) {
      return;
    }
    setState(() {
      _activeTool = nextTool;
      if (_activeTool != AutomatonCanvasTool.transition) {
        _transitionSourceId = null;
      }
      if (_activeTool != AutomatonCanvasTool.selection) {
        _lastTapNodeId = null;
        _lastTapTimestamp = null;
      }
    });
    if (nextTool != AutomatonCanvasTool.transition) {
      _hideTransitionOverlay();
    }
  }

  void _setCanvasPanSuppressed(bool value) {
    if (!mounted || _suppressCanvasPan == value) {
      return;
    }
    setState(() {
      _suppressCanvasPan = value;
    });
  }

  void _onTransformationChanged() {
    _updateTransitionOverlayPosition();
    if (mounted) {
      setState(() {});
    }
  }

  Offset _screenToWorld(Offset localPosition) {
    final controller = _transformationController;
    if (controller == null) {
      return localPosition;
    }
    final matrix = Matrix4.copy(controller.value);
    final determinant = matrix.invert();
    if (determinant == 0) {
      return localPosition;
    }
    final vector = matrix.transform3(
      vmath.Vector3(localPosition.dx, localPosition.dy, 0),
    );
    return Offset(vector.x, vector.y);
  }

  Offset _globalToCanvasLocal(Offset globalPosition) {
    final renderBox =
        widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return globalPosition;
    }
    return renderBox.globalToLocal(globalPosition);
  }

  GraphViewCanvasNode? _hitTestNode(Offset localPosition) {
    final world = _screenToWorld(localPosition);
    GraphViewCanvasNode? closest;
    var closestDistance = double.infinity;
    for (final node in _controller.nodes) {
      final center = Offset(node.x + _kNodeRadius, node.y + _kNodeRadius);
      final dx = world.dx - center.dx;
      final dy = world.dy - center.dy;
      final distanceSquared = dx * dx + dy * dy;
      if (distanceSquared <= _kNodeRadius * _kNodeRadius &&
          distanceSquared < closestDistance) {
        closest = node;
        closestDistance = distanceSquared;
      }
    }
    return closest;
  }

  void _beginNodeDrag(GraphViewCanvasNode node, Offset localPosition) {
    _hideTransitionOverlay();
    _draggingNodeId = node.id;
    _dragStartWorldPosition = _screenToWorld(localPosition);
    final current = _controller.nodeById(node.id) ?? node;
    _dragStartNodeCenter = Offset(current.x, current.y);
    _isDraggingNode = true;
    _didMoveDraggedNode = false;
  }

  void _updateNodeDrag(Offset localPosition) {
    final nodeId = _draggingNodeId;
    final dragStartWorld = _dragStartWorldPosition;
    final dragStartNodeCenter = _dragStartNodeCenter;
    if (nodeId == null ||
        dragStartWorld == null ||
        dragStartNodeCenter == null) {
      return;
    }
    final currentWorld = _screenToWorld(localPosition);
    final delta = currentWorld - dragStartWorld;
    final nextPosition = dragStartNodeCenter + delta;
    _controller.moveState(nodeId, nextPosition);
    _didMoveDraggedNode = true;
  }

  void _endNodeDrag() {
    _draggingNodeId = null;
    _dragStartWorldPosition = null;
    _dragStartNodeCenter = null;
    _setCanvasPanSuppressed(false);
    _isDraggingNode = false;
    _didMoveDraggedNode = false;
  }

  void _handleCanvasTapDown(TapDownDetails details) {
    _globalToCanvasLocal(details.globalPosition);
  }

  Future<void> _handleCanvasTapUp(TapUpDetails details) async {
    final local = _globalToCanvasLocal(details.globalPosition);
    final node = _hitTestNode(local);

    if (_activeTool == AutomatonCanvasTool.addState) {
      if (_isDraggingNode || _didMoveDraggedNode || node != null) {
        return;
      }
      final world = _screenToWorld(local);
      _controller.addStateAt(world);
      return;
    }

    if (_activeTool == AutomatonCanvasTool.transition) {
      if (node != null) {
        await _handleNodeTap(node.id);
      }
      return;
    }

    if (_activeTool != AutomatonCanvasTool.selection) {
      return;
    }

    if (_isDraggingNode || _didMoveDraggedNode) {
      _lastTapNodeId = null;
      _lastTapTimestamp = null;
      return;
    }

    if (node == null) {
      _lastTapNodeId = null;
      _lastTapTimestamp = null;
      return;
    }

    _registerNodeTap(node.id);
  }

  Future<void> _handleNodeTap(String nodeId) async {
    if (_activeTool != AutomatonCanvasTool.transition) {
      return;
    }

    if (_transitionSourceId == null) {
      setState(() {
        _transitionSourceId = nodeId;
      });
      return;
    }

    final fromId = _transitionSourceId!;
    final toId = nodeId;

    if (fromId == toId) {
      final existingEdges = _findExistingEdges(fromId, toId);
      if (existingEdges.isNotEmpty) {
        final existing = existingEdges.first;
        _controller.removeTransition(existing.id);
        return;
      }
    }

    GraphViewCanvasEdge? existing;
    var createNew = true;
    final edges = _findExistingEdges(fromId, toId);
    if (edges.length == 1) {
      existing = edges.first;
      createNew = false;
    } else if (edges.length > 1) {
      final selectionPrompt = widget.transitionDelegate.selectionPrompt;
      final choice = selectionPrompt != null
          ? await selectionPrompt(context, edges)
          : const GraphViewTransitionSelection.createNew();
      if (!mounted) {
        return;
      }
      if (!choice.createNew) {
        existing = choice.edge;
        createNew = false;
      }
    }

    final data = createNew
        ? widget.transitionDelegate.buildDefaultData(fromId, toId)
        : widget.transitionDelegate.dataFromEdge(existing!);

    final worldAnchor = !createNew && existing != null
        ? resolveLinkAnchorWorld(_controller, existing) ??
              Offset(existing.controlPointX ?? 0, existing.controlPointY ?? 0)
        : _deriveControlPoint(fromId, toId);

    final displayed = _showTransitionOverlay(
      fromStateId: fromId,
      toStateId: toId,
      transitionId: createNew ? null : existing?.id,
      data: data,
      worldAnchor: worldAnchor,
    );

    if (displayed) {
      setState(() {
        _selectedTransitions
          ..clear()
          ..addAll(
            existing != null && existing.id.isNotEmpty
                ? <String>{existing.id}
                : const <String>{},
          );
      });
      return;
    }

    final fallbackEditor = widget.transitionDelegate.buildFallbackEditor;
    if (fallbackEditor == null) {
      return;
    }

    final fallbackState = GraphViewTransitionOverlayState<T>(
      fromStateId: fromId,
      toStateId: toId,
      data: data,
      worldAnchor: worldAnchor,
      overlayPosition: Offset.zero,
      transitionId: createNew ? null : existing?.id,
    );

    final result = await fallbackEditor(context, fallbackState);
    if (!mounted || result == null) {
      return;
    }

    widget.transitionDelegate.commit(
      fromId,
      toId,
      worldAnchor,
      result,
      createNew ? null : existing?.id,
    );
  }

  void _registerNodeTap(String nodeId) {
    final now = DateTime.now();
    const threshold = Duration(milliseconds: 350);
    if (_lastTapNodeId == nodeId &&
        _lastTapTimestamp != null &&
        now.difference(_lastTapTimestamp!) <= threshold) {
      _toolController.setActiveTool(AutomatonCanvasTool.transition);
      setState(() {
        _transitionSourceId = nodeId;
      });
    }
    _lastTapNodeId = nodeId;
    _lastTapTimestamp = now;
  }

  List<GraphViewCanvasEdge> _findExistingEdges(String fromId, String toId) {
    return _controller.edges
        .where((edge) => edge.fromStateId == fromId && edge.toStateId == toId)
        .toList(growable: false);
  }

  Offset _deriveControlPoint(String fromId, String toId) {
    final fromNode = _controller.nodeById(fromId);
    final toNode = _controller.nodeById(toId);
    if (fromNode == null || toNode == null) {
      return Offset.zero;
    }

    final fromCenter = Offset(
      fromNode.x + _kNodeRadius,
      fromNode.y + _kNodeRadius,
    );
    final toCenter = Offset(toNode.x + _kNodeRadius, toNode.y + _kNodeRadius);

    if (fromId == toId) {
      return fromCenter.translate(0, -_kNodeDiameter);
    }

    final midpoint = Offset(
      (fromCenter.dx + toCenter.dx) / 2,
      (fromCenter.dy + toCenter.dy) / 2,
    );

    final dx = toCenter.dx - fromCenter.dx;
    final dy = toCenter.dy - fromCenter.dy;
    var normal = Offset(-dy, dx);
    if (normal.distanceSquared == 0) {
      normal = const Offset(0, -1);
    }
    final existing = _findExistingEdges(fromId, toId).length;
    final direction = existing.isEven ? 1.0 : -1.0;
    final magnitude = (_kNodeDiameter * 0.8) + existing * 12;
    final normalized = normal / normal.distance * magnitude * direction;
    return midpoint + normalized;
  }

  void _handleGraphRevisionChanged() {
    if (!mounted) {
      return;
    }
    _refreshTransitionOverlayFromGraph();
    _updateTransitionOverlayPosition();
  }

  void _refreshTransitionOverlayFromGraph() {
    final state = _transitionOverlayState.value;
    if (state == null) {
      return;
    }

    final transitionId = state.transitionId;
    if (transitionId != null) {
      final edge = _controller.edgeById(transitionId);
      if (edge == null) {
        _hideTransitionOverlay();
        return;
      }
      final anchor =
          resolveLinkAnchorWorld(_controller, edge) ?? state.worldAnchor;
      _transitionOverlayState.value = state.copyWith(
        data: widget.transitionDelegate.dataFromEdge(edge),
        worldAnchor: anchor,
      );
      final shouldUpdateSelection =
          _selectedTransitions.length != 1 ||
          !_selectedTransitions.contains(transitionId);
      if (shouldUpdateSelection) {
        setState(() {
          _selectedTransitions
            ..clear()
            ..add(transitionId);
        });
      }
    } else {
      final anchor = _deriveControlPoint(state.fromStateId, state.toStateId);
      _transitionOverlayState.value = state.copyWith(worldAnchor: anchor);
    }
  }

  void _updateTransitionOverlayPosition() {
    final state = _transitionOverlayState.value;
    if (state == null) {
      return;
    }
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) {
      return;
    }
    final overlayPosition = overlayBox.size.center(Offset.zero);
    if ((overlayPosition - state.overlayPosition).distance <= 0.5) {
      return;
    }
    _transitionOverlayState.value = state.copyWith(
      overlayPosition: overlayPosition,
    );
  }

  bool _showTransitionOverlay({
    required String fromStateId,
    required String toStateId,
    required String? transitionId,
    required T data,
    required Offset worldAnchor,
  }) {
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) {
      return false;
    }
    final overlayBox = overlayState.context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) {
      return false;
    }
    final overlayPosition = overlayBox.size.center(Offset.zero);
    _ensureTransitionOverlay(overlayState);
    _transitionOverlayState.value = GraphViewTransitionOverlayState<T>(
      fromStateId: fromStateId,
      toStateId: toStateId,
      transitionId: transitionId,
      data: data,
      worldAnchor: worldAnchor,
      overlayPosition: overlayPosition,
    );
    return true;
  }

  void _ensureTransitionOverlay(OverlayState overlayState) {
    if (_transitionOverlayEntry != null) {
      return;
    }
    _transitionOverlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: ValueListenableBuilder<GraphViewTransitionOverlayState<T>?>(
            valueListenable: _transitionOverlayState,
            builder: (context, state, _) {
              if (state == null) {
                return const SizedBox.shrink();
              }
              final overlay = widget.transitionDelegate.buildOverlay(
                context,
                state,
                (value) => _handleOverlaySubmit(state, value),
                _hideTransitionOverlay,
              );
              return Stack(
                children: [
                  Positioned(
                    left: state.overlayPosition.dx,
                    top: state.overlayPosition.dy,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: overlay,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    overlayState.insert(_transitionOverlayEntry!);
  }

  void _handleOverlaySubmit(GraphViewTransitionOverlayState<T> state, T data) {
    widget.transitionDelegate.commit(
      state.fromStateId,
      state.toStateId,
      state.worldAnchor,
      data,
      state.transitionId,
    );
    _hideTransitionOverlay();
  }

  void _hideTransitionOverlay() {
    final hadOverlay = _transitionOverlayState.value != null;
    final hadSelection = _selectedTransitions.isNotEmpty;
    if (hadOverlay) {
      _transitionOverlayState.value = null;
    }
    if (hadOverlay || hadSelection) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedTransitions.clear();
      });
    }
  }

  Map<Type, GestureRecognizerFactory> _buildGestureRecognizers() {
    final gestures = <Type, GestureRecognizerFactory>{
      PanGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(team: _gestureArenaTeam),
            (instance) {
              instance
                ..onStart = _handleNodePanStart
                ..onUpdate = _handleNodePanUpdate
                ..onEnd = _handleNodePanEnd
                ..onCancel = _handleNodePanCancel
                ..dragStartBehavior = DragStartBehavior.start;
            },
          ),
    };

    return gestures;
  }

  void _handleNodePanStart(DragStartDetails details) {
    final node = _hitTestNode(details.localPosition);
    if (node == null) {
      return;
    }
    _setCanvasPanSuppressed(true);
    _beginNodeDrag(node, details.localPosition);
  }

  void _handleNodePanUpdate(DragUpdateDetails details) {
    _updateNodeDrag(details.localPosition);
  }

  void _handleNodePanEnd(DragEndDetails details) {
    final nodeId = _draggingNodeId;
    final didMove = _didMoveDraggedNode;
    _endNodeDrag();
    if (!didMove &&
        nodeId != null &&
        _activeTool != AutomatonCanvasTool.transition) {
      _handleNodeTap(nodeId);
    }
  }

  void _handleNodePanCancel() {
    _endNodeDrag();
  }

  bool _isNodeHighlighted(
    GraphViewCanvasNode node,
    SimulationHighlight highlight,
  ) {
    return highlight.stateIds.contains(node.id) ||
        node.id == _transitionSourceId;
  }

  Widget _buildEdgeLayer({
    required List<GraphViewCanvasEdge> edges,
    required List<GraphViewCanvasNode> nodes,
    required SimulationHighlight highlight,
    required ThemeData theme,
  }) {
    final painter = widget.edgePainterBuilder(
      edges: edges,
      nodes: nodes,
      highlight: highlight,
      theme: theme,
      selectedTransitions: _selectedTransitions,
    );

    final transformation = _transformationController;
    if (transformation == null) {
      return CustomPaint(painter: painter);
    }

    return AnimatedBuilder(
      animation: transformation,
      builder: (context, _) {
        return Transform(
          alignment: Alignment.topLeft,
          transform: transformation.value,
          child: CustomPaint(painter: painter),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RawGestureDetector(
      key: widget.canvasKey,
      behavior: HitTestBehavior.translucent,
      gestures: _buildGestureRecognizers(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: _handleCanvasTapDown,
        onTapUp: _handleCanvasTapUp,
        child: ValueListenableBuilder<int>(
          valueListenable: _controller.graphRevision,
          builder: (context, _, __) {
            final nodes = _controller.nodes.toList(growable: false);
            final edges = _controller.edges.toList(growable: false);
            return ValueListenableBuilder<SimulationHighlight>(
              valueListenable: _controller.highlightNotifier,
              builder: (context, highlight, __) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final viewport = constraints.biggest;
                          if (viewport.width.isFinite &&
                              viewport.height.isFinite) {
                            _controller.updateViewportSize(viewport);
                          }
                          return RepaintBoundary(
                            child: AbsorbPointer(
                              absorbing: _suppressCanvasPan,
                              child: GraphViewAllNodes.builder(
                                graph: _controller.graph,
                                controller: _controller.graphController,
                                algorithm: _algorithm,
                                paint: Paint()..color = Colors.transparent,
                                builder: (node) {
                                  final nodeId = node.key?.value?.toString();
                                  if (nodeId == null) {
                                    return const SizedBox.shrink();
                                  }
                                  final canvasNode =
                                      _controller.nodeById(nodeId) ??
                                      GraphViewCanvasNode(
                                        id: nodeId,
                                        label: nodeId,
                                        x: node.position.dx,
                                        y: node.position.dy,
                                        isInitial: false,
                                        isAccepting: false,
                                      );
                                  final isHighlighted = _isNodeHighlighted(
                                    canvasNode,
                                    highlight,
                                  );
                                  return widget.nodeBuilder(
                                    context,
                                    canvasNode,
                                    highlight,
                                    isHighlighted,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _buildEdgeLayer(
                          edges: edges,
                          nodes: nodes,
                          highlight: highlight,
                          theme: theme,
                        ),
                      ),
                    ),
                    if (_activeTool == AutomatonCanvasTool.transition)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.link,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.transitionToolLabel ??
                                      'Add transition…',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
