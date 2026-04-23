//
//  automaton_graphview_canvas.dart
//  JFlutter
//
//  Implementa o canvas interativo baseado em GraphView responsável por editar e
//  visualizar autômatos nos diferentes modos do aplicativo, coordenando
//  ferramentas, arrastos de estados, criação de transições e emissão de destaques
//  durante simulações.
//  Orquestra controladores especializados para FSA, PDA e TM, integra editores de
//  rótulos, sobreposições contextuais e sincronização com providers Riverpod para
//  manter o modelo consistente mesmo em autômatos de grande porte.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../../core/constants/automaton_canvas.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/models/simulation_result.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../core/models/tm_transition.dart' show TapeDirection;
import '../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_canvas_models.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../features/canvas/graphview/jflutter_adaptive_edge_renderer.dart';
import '../../features/canvas/graphview/graphview_label_field_editor.dart';
import '../../features/canvas/graphview/grouped_fsa_geometry.dart';
import '../../features/canvas/graphview/graphview_link_overlay_utils.dart';
import '../../features/canvas/graphview/graphview_pda_canvas_controller.dart';
import '../../l10n/app_localizations.dart';
import '../providers/automaton_state_provider.dart';
import 'automaton_canvas_tool.dart';
import 'transition_editors/pda_transition_editor.dart';

part 'automaton_graphview_canvas_models.dart';
part 'automaton_graphview_canvas_overlay.dart';
part 'automaton_graphview_canvas_rendering.dart';
part 'automaton_graphview_canvas_interactions.dart';

class AutomatonGraphViewCanvas extends ConsumerStatefulWidget {
  const AutomatonGraphViewCanvas({
    super.key,
    required this.automaton,
    required this.canvasKey,
    this.simulationResult,
    this.currentStepIndex,
    this.showTrace = false,
    this.controller,
    this.toolController,
    this.customization,
  });

  final Object? automaton;
  final GlobalKey canvasKey;
  final BaseGraphViewCanvasController<dynamic, dynamic>? controller;
  final AutomatonCanvasToolController? toolController;
  final SimulationResult? simulationResult;
  final int? currentStepIndex;
  final bool showTrace;
  final AutomatonGraphViewCanvasCustomization? customization;

  @override
  ConsumerState<AutomatonGraphViewCanvas> createState() =>
      _AutomatonGraphViewCanvasState();
}

class _AutomatonGraphViewCanvasState
    extends ConsumerState<AutomatonGraphViewCanvas>
    with TickerProviderStateMixin {
  late BaseGraphViewCanvasController<dynamic, dynamic> _controller;
  late bool _ownsController;
  late AutomatonCanvasToolController _toolController;
  late bool _ownsToolController;
  AutomatonCanvasTool _activeTool = AutomatonCanvasTool.selection;
  SimulationHighlightService? _highlightService;
  SimulationHighlightChannel? _previousHighlightChannel;
  late _AutomatonGraphSugiyamaAlgorithm _algorithm;
  final Set<String> _selectedTransitions = <String>{};
  String? _transitionSourceId;
  OverlayEntry? _transitionOverlayEntry;
  final ValueNotifier<_GraphViewTransitionOverlayState?>
      _transitionOverlayState =
      ValueNotifier<_GraphViewTransitionOverlayState?>(
    null,
  );
  Object? _pendingSyncAutomaton;
  bool _syncScheduled = false;
  String? _draggingNodeId;
  Offset? _dragStartWorldPosition;
  Offset? _dragStartNodeCenter;
  final GestureArenaTeam _gestureArenaTeam = GestureArenaTeam();
  bool _suppressCanvasPan = false;
  String? _lastTapNodeId;
  Duration? _lastTapTimestamp;
  final Stopwatch _monotonicStopwatch = Stopwatch()..start();
  bool _isDraggingNode = false;
  bool _didMoveDraggedNode = false;
  late AutomatonGraphViewCanvasCustomization _customization;
  late AutomatonGraphViewTransitionConfig _transitionConfig;
  late final AnimationController _edgeAnimationController;
  late final JFlutterAdaptiveEdgeRenderer _edgeRenderer;
  bool _hasEdgeRenderer = false;
  String? _lastEdgeStructureSignature;

  void _setCanvasPanSuppressed(bool value, {String reason = ''}) {
    if (!mounted) {
      return;
    }
    if (_suppressCanvasPan == value) {
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[AutomatonGraphViewCanvas] suppressPan=$value reason=$reason',
      );
    }
    setState(() {
      _suppressCanvasPan = value;
    });
  }

  void _setTransitionSourceId(String? nodeId) {
    if (!mounted) {
      return;
    }
    setState(() {
      _transitionSourceId = nodeId;
    });
  }

  TransformationController? get _transformationController =>
      _controller.graphController.transformationController;

  @override
  void initState() {
    super.initState();
    final externalToolController = widget.toolController;
    if (externalToolController != null) {
      _toolController = externalToolController;
      _ownsToolController = false;
    } else {
      _toolController = AutomatonCanvasToolController();
      _ownsToolController = true;
    }
    _activeTool = _toolController.activeTool;
    _toolController.addListener(_handleActiveToolChanged);

    final externalController = widget.controller;
    if (externalController != null) {
      _controller = externalController;
      _ownsController = false;
    } else {
      final notifier = ref.read(automatonStateProvider.notifier);
      _controller = GraphViewCanvasController(automatonStateNotifier: notifier);
      _ownsController = true;
      final highlightService = ref.read(canvasHighlightServiceProvider);
      _highlightService = highlightService;
      _previousHighlightChannel = highlightService.channel;
      final highlightChannel = GraphViewSimulationHighlightChannel(_controller);
      highlightService.channel = highlightChannel;
    }

    _applyCustomization(widget.customization);
    _edgeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(_handleEdgeAnimationTick);
    _edgeRenderer = JFlutterAdaptiveEdgeRenderer(
      config: EdgeRoutingConfig(
        anchorMode: AnchorMode.dynamic,
        routingMode: RoutingMode.bezier,
        enableRepulsion: true,
      ),
      animationConfig: const AnimatedEdgeConfiguration(
        animationSpeed: 1.0,
        particleCount: 3,
        particleSize: 3.0,
      ),
      renderMode: _customization.edgeRenderMode,
    );
    _hasEdgeRenderer = true;
    _edgeRenderer.setAnimationValue(_edgeAnimationController.value);
    _algorithm = _AutomatonGraphSugiyamaAlgorithm(
      configuration: _buildConfiguration(),
    );
    _algorithm.renderer = _edgeRenderer;
    _scheduleControllerSync(widget.automaton);
    _controller.graphRevision.addListener(_handleGraphRevisionChanged);
    _controller.highlightNotifier.addListener(_handleHighlightChanged);
    _transformationController?.addListener(_onTransformationChanged);
    _handleHighlightChanged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.graph.nodes.isNotEmpty) {
        _controller.fitToContent();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AutomatonGraphViewCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    var shouldReapplyCustomization = false;
    if (oldWidget.toolController != widget.toolController) {
      _toolController.removeListener(_handleActiveToolChanged);
      if (_ownsToolController) {
        _toolController.dispose();
      }
      final nextController =
          widget.toolController ?? AutomatonCanvasToolController();
      _toolController = nextController;
      _ownsToolController = widget.toolController == null;
      _toolController.addListener(_handleActiveToolChanged);
      _activeTool = _toolController.activeTool;
      shouldReapplyCustomization = true;
    }

    if (oldWidget.controller != widget.controller) {
      _controller.graphRevision.removeListener(_handleGraphRevisionChanged);
      _controller.highlightNotifier.removeListener(_handleHighlightChanged);
      _transformationController?.removeListener(_onTransformationChanged);
      if (_ownsController) {
        if (_highlightService != null) {
          _highlightService!.channel = _previousHighlightChannel;
        }
        _controller.dispose();
      }
      final externalController = widget.controller;
      if (externalController != null) {
        _controller = externalController;
        _ownsController = false;
        _highlightService = null;
        _previousHighlightChannel = null;
      } else {
        final notifier = ref.read(automatonStateProvider.notifier);
        _controller = GraphViewCanvasController(
          automatonStateNotifier: notifier,
        );
        _ownsController = true;
        final highlightService = ref.read(canvasHighlightServiceProvider);
        _highlightService = highlightService;
        _previousHighlightChannel = highlightService.channel;
        final highlightChannel = GraphViewSimulationHighlightChannel(
          _controller,
        );
        highlightService.channel = highlightChannel;
      }
      _algorithm = _AutomatonGraphSugiyamaAlgorithm(
        configuration: _buildConfiguration(),
      );
      _algorithm.renderer = _edgeRenderer;
      _transformationController?.addListener(_onTransformationChanged);
      _scheduleControllerSync(widget.automaton);
      _lastEdgeStructureSignature = null;
      _controller.graphRevision.addListener(_handleGraphRevisionChanged);
      _controller.highlightNotifier.addListener(_handleHighlightChanged);
      _handleHighlightChanged();
      _hideTransitionOverlay();
      shouldReapplyCustomization = true;
    } else if (oldWidget.automaton != widget.automaton) {
      _scheduleControllerSync(widget.automaton);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _refreshTransitionOverlayFromGraph();
        _updateTransitionOverlayPosition();
      });
    }

    if (shouldReapplyCustomization ||
        oldWidget.customization != widget.customization) {
      _applyCustomization(widget.customization);
    }
  }

  @override
  void dispose() {
    _controller.graphRevision.removeListener(_handleGraphRevisionChanged);
    _controller.highlightNotifier.removeListener(_handleHighlightChanged);
    _transformationController?.removeListener(_onTransformationChanged);
    _toolController.removeListener(_handleActiveToolChanged);
    _edgeAnimationController
      ..removeListener(_handleEdgeAnimationTick)
      ..dispose();
    if (_ownsToolController) {
      _toolController.dispose();
    }
    if (_ownsController) {
      _controller.dispose();
    }
    if (_highlightService != null) {
      _highlightService!.channel = _previousHighlightChannel;
    }
    _transitionOverlayEntry?.remove();
    _transitionOverlayEntry = null;
    _transitionOverlayState.dispose();
    super.dispose();
  }

  void _handleActiveToolChanged() {
    final nextTool = _toolController.activeTool;
    if (!_customization.enableToolSelection &&
        nextTool != AutomatonCanvasTool.selection) {
      _toolController.setActiveTool(AutomatonCanvasTool.selection);
      return;
    }
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
    debugPrint(
      '[AutomatonGraphViewCanvas] Active tool set to '
      '${nextTool.name}',
    );
    if (nextTool != AutomatonCanvasTool.transition) {
      _hideTransitionOverlay();
    }
  }

  void _onTransformationChanged() {
    _updateTransitionOverlayPosition();
  }

  void _handleEdgeAnimationTick() {
    _edgeRenderer.setAnimationValue(_edgeAnimationController.value);
  }

  void _handleHighlightChanged() {
    final hasHighlightedTransitions =
        _controller.highlightNotifier.value.transitionIds.isNotEmpty;
    if (hasHighlightedTransitions) {
      if (!_edgeAnimationController.isAnimating) {
        _edgeAnimationController.repeat();
      }
      return;
    }

    if (_edgeAnimationController.isAnimating) {
      _edgeAnimationController.stop();
    }
    if (_edgeAnimationController.value != 0) {
      _edgeAnimationController.value = 0;
      _edgeRenderer.setAnimationValue(0);
    }
  }

  void _applyCustomization(
    AutomatonGraphViewCanvasCustomization? customization,
  ) {
    final resolved =
        customization ?? AutomatonGraphViewCanvasCustomization.fsa();
    _customization = resolved;
    _transitionConfig = resolved.transitionConfigBuilder(_controller);
    if (_hasEdgeRenderer) {
      _edgeRenderer.renderMode = resolved.edgeRenderMode;
    }
    if (!_customization.enableToolSelection &&
        _toolController.activeTool != AutomatonCanvasTool.selection) {
      _toolController.setActiveTool(AutomatonCanvasTool.selection);
    }
    _activeTool = _toolController.activeTool;
  }

  void _scheduleControllerSync(Object? data) {
    _pendingSyncAutomaton = data;
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) {
        _pendingSyncAutomaton = null;
        return;
      }
      final target = _pendingSyncAutomaton;
      _pendingSyncAutomaton = null;
      final dynamic synchronizable = _controller;
      try {
        // ignore: avoid_dynamic_calls
        synchronizable.synchronize(target);
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[AutomatonGraphViewCanvas] Failed to synchronize controller: '
            '$error',
          );
          debugPrint(stackTrace.toString());
        }
      }
    });
  }

  SugiyamaConfiguration _buildConfiguration() {
    final configuration = SugiyamaConfiguration()
      ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
      ..nodeSeparation = 160
      ..levelSeparation = 160
      ..bendPointShape = CurvedBendPointShape(curveLength: 40);
    return configuration;
  }

  Offset _screenToWorld(Offset localPosition) =>
      this._screenToWorldExtracted(localPosition);

  GraphViewCanvasNode? _hitTestNode(
    Offset localPosition, {
    bool logDetails = true,
  }) =>
      this._hitTestNodeExtracted(localPosition, logDetails: logDetails);

  Offset _globalToCanvasLocal(Offset globalPosition) =>
      this._globalToCanvasLocalExtracted(globalPosition);

  void _logCanvasTapFromLocal({
    required String source,
    required Offset localPosition,
  }) =>
      this._logCanvasTapFromLocalExtracted(
        source: source,
        localPosition: localPosition,
      );

  void _logCanvasTapFromGlobal({
    required String source,
    required Offset globalPosition,
  }) =>
      this._logCanvasTapFromGlobalExtracted(
        source: source,
        globalPosition: globalPosition,
      );

  void _handleCanvasTapDown(TapDownDetails details) =>
      this._handleCanvasTapDownExtracted(details);

  void _beginNodeDrag(GraphViewCanvasNode node, Offset localPosition) =>
      this._beginNodeDragExtracted(node, localPosition);

  void _updateNodeDrag(Offset localPosition) =>
      this._updateNodeDragExtracted(localPosition);

  void _endNodeDrag() => this._endNodeDragExtracted();

  Future<void> _handleCanvasTapUp(TapUpDetails details) =>
      this._handleCanvasTapUpExtracted(details);

  void _handleNodePanStart(DragStartDetails details) =>
      this._handleNodePanStartExtracted(details);

  void _handleNodePanUpdate(DragUpdateDetails details) =>
      this._handleNodePanUpdateExtracted(details);

  void _handleNodePanEnd(DragEndDetails details) =>
      this._handleNodePanEndExtracted(details);

  void _handleNodePanCancel() => this._handleNodePanCancelExtracted();

  void _handleNodeTap(String nodeId) => this._handleNodeTapExtracted(nodeId);

  void _handleNodeContextTap(String nodeId) =>
      this._handleNodeContextTapExtracted(nodeId);

  void _handleNodeTapFromPan(String nodeId) =>
      this._handleNodeTapFromPanExtracted(nodeId);

  void _registerNodeTap(String nodeId) =>
      this._registerNodeTapExtracted(nodeId);

  Future<void> _showStateOptions(GraphViewCanvasNode node) =>
      this._showStateOptionsExtracted(node);

  List<GraphViewCanvasEdge> _findExistingEdges(String fromId, String toId) =>
      this._findExistingEdgesExtracted(fromId, toId);

  Future<void> _showTransitionEditor(String fromId, String toId) =>
      this._showTransitionEditorExtracted(fromId, toId);

  Future<_TransitionEditChoice?> _promptTransitionEditChoice(
    List<GraphViewCanvasEdge> edges,
  ) =>
      this._promptTransitionEditChoiceExtracted(edges);

  Offset _deriveControlPoint(String fromId, String toId) =>
      this._deriveControlPointExtracted(fromId, toId);

  void _handleGraphRevisionChanged() =>
      this._handleGraphRevisionChangedExtracted();

  void _invalidateEdgeRendererCachesIfNeeded() {
    final signature = _computeEdgeStructureSignature();
    if (signature == _lastEdgeStructureSignature) {
      return;
    }
    _lastEdgeStructureSignature = signature;
    if (_hasEdgeRenderer) {
      _edgeRenderer.invalidateEdgeCaches();
    }
  }

  String _computeEdgeStructureSignature() {
    final edges = _controller.edges.sortedBy((edge) => edge.id);
    final buffer = StringBuffer()..write(edges.length);
    for (final edge in edges) {
      buffer
        ..write('|')
        ..write(edge.id)
        ..write(':')
        ..write(edge.fromStateId)
        ..write('->')
        ..write(edge.toStateId)
        ..write(':')
        ..write(edge.label);
    }
    return buffer.toString();
  }

  void _refreshTransitionOverlayFromGraph() =>
      this._refreshTransitionOverlayFromGraphExtracted();

  void _updateTransitionOverlayPosition() =>
      this._updateTransitionOverlayPositionExtracted();

  bool _showTransitionOverlay(AutomatonTransitionOverlayData data) =>
      this._showTransitionOverlayExtracted(data);

  void _ensureTransitionOverlay(OverlayState overlayState) =>
      this._ensureTransitionOverlayExtracted(overlayState);

  void _handleOverlaySubmit(
    _GraphViewTransitionOverlayState state,
    AutomatonTransitionPayload payload,
  ) =>
      this._handleOverlaySubmitExtracted(state, payload);

  void _hideTransitionOverlay() => this._hideTransitionOverlayExtracted();

  bool _isNodeHighlighted(
    GraphViewCanvasNode node,
    SimulationHighlight highlight,
  ) =>
      this._isNodeHighlightedExtracted(node, highlight);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    final motionPreset = disableAnimations
        ? _CanvasMotionPreset.reduced
        : _CanvasMotionPreset.organic;
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
            return ValueListenableBuilder<SimulationHighlight>(
              valueListenable: _controller.highlightNotifier,
              builder: (context, highlight, __) {
                _edgeRenderer.updateAppearance(
                  highlightedEdgeIds: highlight.transitionIds,
                  selectedEdgeIds: _selectedTransitions,
                  baseColor: theme.colorScheme.outline,
                  highlightColor: theme.colorScheme.primary,
                  labelSurfaceColor: theme.colorScheme.surfaceContainerHighest,
                );
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
                              // Suppress GraphView's own pan handling whenever
                              // a node drag or tool-specific gesture owns the
                              // interaction, avoiding mixed canvas/node motion.
                              absorbing: _suppressCanvasPan ||
                                  _activeTool == AutomatonCanvasTool.addState ||
                                  _activeTool == AutomatonCanvasTool.transition,
                              child: ExcludeSemantics(
                                // The surrounding controls remain accessible,
                                // but the free-form canvas itself is excluded
                                // until state/transition semantics are added in
                                // a future accessibility pass.
                                child: GraphView.builder(
                                  graph: _controller.graph,
                                  controller: _controller.graphController,
                                  algorithm: _algorithm,
                                  animated:
                                      motionPreset.graphAnimationEnabled &&
                                          !_isDraggingNode,
                                  panAnimationDuration:
                                      motionPreset.viewportDuration,
                                  toggleAnimationDuration:
                                      motionPreset.nodeDuration,
                                  paint: Paint()
                                    ..color = theme.colorScheme.outline
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 2
                                    ..strokeCap = StrokeCap.round,
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
                                    return _AutomatonGraphNode(
                                      label: canvasNode.label,
                                      isInitial: canvasNode.isInitial,
                                      isAccepting: canvasNode.isAccepting,
                                      isHighlighted: isHighlighted,
                                      motionPreset: motionPreset,
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
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

  Map<Type, GestureRecognizerFactory> _buildGestureRecognizers() {
    final gestures = <Type, GestureRecognizerFactory>{
      _NodePanGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<_NodePanGestureRecognizer>(
        () => _NodePanGestureRecognizer(
          hitTester: (global) =>
              _hitTestNode(_globalToCanvasLocal(global), logDetails: false),
          toolResolver: () => _activeTool,
          onPointerDown: (global) => _logCanvasTapFromGlobal(
            source: 'pan-pointer',
            globalPosition: global,
          ),
          onDragAccepted: () => _setCanvasPanSuppressed(
            true,
            reason: 'node pointer accepted',
          ),
          onDragReleased: () => _setCanvasPanSuppressed(
            false,
            reason: 'node pointer released',
          ),
        ),
        (recognizer) {
          recognizer.team ??= _gestureArenaTeam;
          recognizer
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
}
