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
import '../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_canvas_models.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../features/canvas/graphview/graphview_all_nodes_builder.dart';
import '../../features/canvas/graphview/graphview_link_overlay_utils.dart';
import '../../features/canvas/graphview/graphview_transition_models.dart';
import '../../features/canvas/graphview/graphview_canvas_config.dart';
import '../../features/canvas/graphview/graphview_canvas_painters.dart';
import '../../features/canvas/graphview/graphview_canvas_gesture_recognizers.dart';
import '../../features/canvas/graphview/graphview_canvas_widgets.dart';
import '../../features/canvas/graphview/graphview_layout_algorithm.dart';
import '../providers/automaton_provider.dart';
import 'automaton_canvas_tool.dart';

const double _kNodeDiameter = kAutomatonStateDiameter;
const double _kNodeRadius = _kNodeDiameter / 2;

/// GraphView-based canvas used to render and edit automatons.
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
    extends ConsumerState<AutomatonGraphViewCanvas> {
  late BaseGraphViewCanvasController<dynamic, dynamic> _controller;
  late bool _ownsController;
  late AutomatonCanvasToolController _toolController;
  late bool _ownsToolController;
  AutomatonCanvasTool _activeTool = AutomatonCanvasTool.selection;
  SimulationHighlightService? _highlightService;
  SimulationHighlightChannel? _previousHighlightChannel;
  late AutomatonGraphSugiyamaAlgorithm _algorithm;
  final Set<String> _selectedTransitions = <String>{};
  String? _transitionSourceId;
  OverlayEntry? _transitionOverlayEntry;
  final ValueNotifier<GraphViewTransitionOverlayState?>
  _transitionOverlayState = ValueNotifier<GraphViewTransitionOverlayState?>(
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
  DateTime? _lastTapTimestamp;
  bool _isDraggingNode = false;
  bool _didMoveDraggedNode = false;
  late AutomatonGraphViewCanvasCustomization _customization;
  late AutomatonGraphViewTransitionConfig _transitionConfig;

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
      final notifier = ref.read(automatonProvider.notifier);
      _controller = GraphViewCanvasController(automatonProvider: notifier);
      _ownsController = true;
      final highlightService = ref.read(canvasHighlightServiceProvider);
      _highlightService = highlightService;
      _previousHighlightChannel = highlightService.channel;
      final highlightChannel = GraphViewSimulationHighlightChannel(_controller);
      highlightService.channel = highlightChannel;
    }

    _applyCustomization(widget.customization);
    _algorithm = AutomatonGraphSugiyamaAlgorithm(
      controller: _controller,
      configuration: _buildConfiguration(),
    );
    _scheduleControllerSync(widget.automaton);
    _controller.graphRevision.addListener(_handleGraphRevisionChanged);
    _transformationController?.addListener(_onTransformationChanged);

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
        final notifier = ref.read(automatonProvider.notifier);
        _controller = GraphViewCanvasController(automatonProvider: notifier);
        _ownsController = true;
        final highlightService = ref.read(canvasHighlightServiceProvider);
        _highlightService = highlightService;
        _previousHighlightChannel = highlightService.channel;
        final highlightChannel = GraphViewSimulationHighlightChannel(
          _controller,
        );
        highlightService.channel = highlightChannel;
      }
      _algorithm = AutomatonGraphSugiyamaAlgorithm(
        controller: _controller,
        configuration: _buildConfiguration(),
      );
      _transformationController?.addListener(_onTransformationChanged);
      _scheduleControllerSync(widget.automaton);
      _controller.graphRevision.addListener(_handleGraphRevisionChanged);
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
    _transformationController?.removeListener(_onTransformationChanged);
    _toolController.removeListener(_handleActiveToolChanged);
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
    setState(() {});
  }

  void _applyCustomization(
    AutomatonGraphViewCanvasCustomization? customization,
  ) {
    final resolved =
        customization ?? AutomatonGraphViewCanvasCustomization.fsa();
    _customization = resolved;
    _transitionConfig = resolved.transitionConfigBuilder(_controller);
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
            '\$error',
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

  GraphViewCanvasNode? _hitTestNode(
    Offset localPosition, {
    bool logDetails = true,
  }) {
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
    if (logDetails) {
      if (closest != null) {
        debugPrint(
          '[AutomatonGraphViewCanvas] Hit node ${closest.id} '
          '(tool=${_activeTool.name}) local=$localPosition world=$world',
        );
      } else if (_activeTool == AutomatonCanvasTool.transition) {
        debugPrint(
          '[AutomatonGraphViewCanvas] Transition tool miss '
          'local=$localPosition world=$world',
        );
      }
    }
    return closest;
  }

  Offset _globalToCanvasLocal(Offset globalPosition) {
    final renderBox =
        widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return globalPosition;
    }
    return renderBox.globalToLocal(globalPosition);
  }

  void _logCanvasTapFromLocal({
    required String source,
    required Offset localPosition,
  }) {
    final node = _hitTestNode(localPosition, logDetails: false);
    final world = _screenToWorld(localPosition);
    final target = node?.id ?? 'canvas-background';
    debugPrint(
      '[AutomatonGraphViewCanvas] Tap source=$source target=$target '
      'tool=${_activeTool.name} local=$localPosition world=$world',
    );
  }

  void _logCanvasTapFromGlobal({
    required String source,
    required Offset globalPosition,
  }) {
    final local = _globalToCanvasLocal(globalPosition);
    _logCanvasTapFromLocal(source: source, localPosition: local);
  }

  void _handleCanvasTapDown(TapDownDetails details) {
    final global = details.globalPosition;
    final local = _globalToCanvasLocal(global);
    _logCanvasTapFromLocal(source: 'tap-down', localPosition: local);
  }

  void _beginNodeDrag(GraphViewCanvasNode node, Offset localPosition) {
    debugPrint('[AutomatonGraphViewCanvas] Begin drag for ${node.id}');
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
    _setCanvasPanSuppressed(false, reason: 'drag ended');
    _isDraggingNode = false;
    _didMoveDraggedNode = false;
  }

  Future<void> _handleCanvasTapUp(TapUpDetails details) async {
    final global = details.globalPosition;
    final local = _globalToCanvasLocal(global);
    debugPrint(
      '[AutomatonGraphViewCanvas] Tap up with active tool ${_activeTool.name} '
      'local=$local',
    );
    final node = _hitTestNode(local, logDetails: false);

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
        _handleNodeTap(node.id);
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

  void _handleNodePanStart(DragStartDetails details) {
    if (!_customization.enableStateDrag) {
      return;
    }
    final node = _hitTestNode(details.localPosition);
    if (node == null) {
      return;
    }
    debugPrint(
      '[AutomatonGraphViewCanvas] pan start gesture -> ${node.id} '
      'local=${details.localPosition}',
    );
    _setCanvasPanSuppressed(true, reason: 'node drag start ${node.id}');
    _beginNodeDrag(node, details.localPosition);
  }

  void _handleNodePanUpdate(DragUpdateDetails details) {
    debugPrint('[AutomatonGraphViewCanvas] pan update delta=${details.delta}');
    _updateNodeDrag(details.localPosition);
  }

  void _handleNodePanEnd(DragEndDetails details) {
    final nodeId = _draggingNodeId;
    final didMove = _didMoveDraggedNode;
    debugPrint(
      '[AutomatonGraphViewCanvas] pan end velocity=${details.velocity}',
    );
    _endNodeDrag();
    if (!didMove &&
        nodeId != null &&
        _activeTool != AutomatonCanvasTool.transition) {
      _handleNodeTapFromPan(nodeId);
    }
  }

  void _handleNodePanCancel() {
    debugPrint('[AutomatonGraphViewCanvas] pan cancel');
    _endNodeDrag();
  }

  void _handleNodeTap(String nodeId) {
    debugPrint(
      '[AutomatonGraphViewCanvas] Node tapped $nodeId with '
      'active tool ${_activeTool.name}',
    );
    if (_activeTool != AutomatonCanvasTool.transition) {
      return;
    }

    if (_transitionSourceId == null) {
      debugPrint(
        '[AutomatonGraphViewCanvas] Transition source selected '
        '-> $nodeId',
      );
      setState(() {
        _transitionSourceId = nodeId;
      });
      return;
    }

    final sourceId = _transitionSourceId!;
    setState(() {
      _transitionSourceId = null;
    });
    debugPrint(
      '[AutomatonGraphViewCanvas] Transition target selected '
      '-> $nodeId (source: $sourceId)',
    );
    _showTransitionEditor(sourceId, nodeId);
  }

  void _handleNodeContextTap(String nodeId) {
    final node = _controller.nodeById(nodeId);
    if (node == null) {
      return;
    }
    debugPrint('[AutomatonGraphViewCanvas] opening state options for $nodeId');
    _showStateOptions(node);
  }

  void _handleNodeTapFromPan(String nodeId) {
    _registerNodeTap(nodeId);
  }

  void _registerNodeTap(String nodeId) {
    const doubleTapTimeout = Duration(milliseconds: 300);
    final now = DateTime.now();
    if (_lastTapNodeId == nodeId &&
        _lastTapTimestamp != null &&
        now.difference(_lastTapTimestamp!) <= doubleTapTimeout) {
      debugPrint('[AutomatonGraphViewCanvas] Detected double tap on $nodeId');
      _handleNodeContextTap(nodeId);
      _lastTapNodeId = null;
      _lastTapTimestamp = null;
    } else {
      _lastTapNodeId = nodeId;
      _lastTapTimestamp = now;
    }
  }

  Future<void> _showStateOptions(GraphViewCanvasNode node) async {
    final labelController = TextEditingController(text: node.label);
    var isInitial = node.isInitial;
    var isAccepting = node.isAccepting;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    node.label.isEmpty ? node.id : node.label,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(labelText: 'State label'),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      final resolved = value.trim();
                      if (resolved != node.label) {
                        _controller.updateStateLabel(node.id, resolved);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: isInitial,
                    title: const Text('Initial state'),
                    onChanged: (value) {
                      setModalState(() => isInitial = value);
                      _controller.updateStateFlags(node.id, isInitial: value);
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: isAccepting,
                    title: const Text('Final state'),
                    onChanged: (value) {
                      setModalState(() => isAccepting = value);
                      _controller.updateStateFlags(node.id, isAccepting: value);
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final resolved = labelController.text.trim();
                      if (resolved != node.label) {
                        _controller.updateStateLabel(node.id, resolved);
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save changes'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    labelController.dispose();
  }

  List<GraphViewCanvasEdge> _findExistingEdges(String fromId, String toId) {
    return _controller.edges
        .where((edge) => edge.fromStateId == fromId && edge.toStateId == toId)
        .toList(growable: false);
  }

  Future<void> _showTransitionEditor(String fromId, String toId) async {
    final existingEdges = _findExistingEdges(fromId, toId);
    debugPrint(
      '[AutomatonGraphViewCanvas] Preparing transition editor '
      'from=$fromId to=$toId existing=${existingEdges.length}',
    );
    GraphViewCanvasEdge? existing;
    var createNew = existingEdges.isEmpty;

    if (!createNew) {
      existing = existingEdges.firstWhereOrNull(
        (edge) => _selectedTransitions.contains(edge.id),
      );

      if (existing == null) {
        final selection = await _promptTransitionEditChoice(existingEdges);
        if (!mounted || selection == null) {
          return;
        }
        if (selection.createNew) {
          createNew = true;
        } else {
          existing = selection.edge;
          if (existing == null) {
            createNew = true;
          }
        }
      }
    }

    final payload = _transitionConfig.initialPayloadBuilder(existing);
    final worldAnchor = !createNew && existing != null
        ? resolveLinkAnchorWorld(_controller, existing) ??
              Offset(existing.controlPointX ?? 0, existing.controlPointY ?? 0)
        : _deriveControlPoint(fromId, toId);
    final overlayData = AutomatonTransitionOverlayData(
      fromStateId: fromId,
      toStateId: toId,
      worldAnchor: worldAnchor,
      payload: payload,
      transitionId: createNew ? null : existing?.id,
      edge: existing,
    );

    final overlayDisplayed = _showTransitionOverlay(overlayData);

    if (overlayDisplayed) {
      debugPrint(
        '[AutomatonGraphViewCanvas] Showing transition editor '
        'for $fromId → $toId (transitionId: ${existing?.id})',
      );
      setState(() {
        _selectedTransitions.clear();
        if (!createNew && existing?.id != null) {
          _selectedTransitions.add(existing!.id);
        }
      });
      return;
    }

    debugPrint(
      '[AutomatonGraphViewCanvas] Fallback modal for '
      '$fromId → $toId (existing=${existing?.id})',
    );

    final result = await showDialog<AutomatonTransitionPayload?>(
      context: context,
      builder: (context) {
        final controller = AutomatonTransitionOverlayController(
          onSubmit: (value) => Navigator.of(context).pop(value),
          onCancel: () => Navigator.of(context).pop(null),
        );
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: _transitionConfig.overlayBuilder(
            context,
            overlayData,
            controller,
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    debugPrint(
      '[AutomatonGraphViewCanvas] Persisting transition '
      'for $fromId → $toId (transitionId: ${existing?.id})',
    );

    _transitionConfig.persistTransition(
      AutomatonTransitionPersistRequest(
        fromStateId: fromId,
        toStateId: toId,
        transitionId: createNew ? null : existing?.id,
        payload: result,
        worldAnchor: worldAnchor,
        controller: _controller,
      ),
    );
  }

  Future<TransitionEditChoice?> _promptTransitionEditChoice(
    List<GraphViewCanvasEdge> edges,
  ) {
    return showDialog<TransitionEditChoice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecione a transição'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SingleChildScrollView(
              child: ListBody(
                children: [
                  for (final edge in edges)
                    ListTile(
                      key: ValueKey('automaton-transition-choice-${edge.id}'),
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(edge.label.isEmpty ? edge.id : edge.label),
                      subtitle: Text('${edge.fromStateId} → ${edge.toStateId}'),
                      onTap: () => Navigator.of(
                        context,
                      ).pop(TransitionEditChoice.edit(edge)),
                    ),
                  ListTile(
                    key: const ValueKey(
                      'automaton-transition-choice-create-new',
                    ),
                    leading: const Icon(Icons.add_outlined),
                    title: const Text('Create new transition'),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(const TransitionEditChoice.createNew()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
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

    final data = state.data;
    final transitionId = data.transitionId;
    if (transitionId != null) {
      final edge = _controller.edgeById(transitionId);
      if (edge == null) {
        _hideTransitionOverlay();
        return;
      }
      final anchor =
          resolveLinkAnchorWorld(_controller, edge) ?? data.worldAnchor;
      final payload = _transitionConfig.initialPayloadBuilder(edge);
      _transitionOverlayState.value = state.copyWith(
        data: data.copyWith(payload: payload, worldAnchor: anchor, edge: edge),
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
      final anchor = _deriveControlPoint(data.fromStateId, data.toStateId);
      _transitionOverlayState.value = state.copyWith(
        data: data.copyWith(worldAnchor: anchor),
      );
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

  bool _showTransitionOverlay(AutomatonTransitionOverlayData data) {
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
    _transitionOverlayState.value = GraphViewTransitionOverlayState(
      data: data,
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
          child: ValueListenableBuilder<GraphViewTransitionOverlayState?>(
            valueListenable: _transitionOverlayState,
            builder: (context, state, _) {
              if (state == null) {
                return const SizedBox.shrink();
              }
              final overlayController = AutomatonTransitionOverlayController(
                onSubmit: (payload) => _handleOverlaySubmit(state, payload),
                onCancel: _hideTransitionOverlay,
              );
              final overlayChild = _transitionConfig.overlayBuilder(
                context,
                state.data,
                overlayController,
              );
              return Stack(
                children: [
                  Positioned(
                    left: state.overlayPosition.dx,
                    top: state.overlayPosition.dy,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: overlayChild,
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

  void _handleOverlaySubmit(
    GraphViewTransitionOverlayState state,
    AutomatonTransitionPayload payload,
  ) {
    final data = state.data;
    debugPrint(
      '[AutomatonGraphViewCanvas] Persisting transition '
      'for ${data.fromStateId} → ${data.toStateId} '
      '(transitionId: ${data.transitionId})',
    );
    _transitionConfig.persistTransition(
      AutomatonTransitionPersistRequest(
        fromStateId: data.fromStateId,
        toStateId: data.toStateId,
        transitionId: data.transitionId,
        payload: payload,
        worldAnchor: data.worldAnchor,
        controller: _controller,
      ),
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
    final painter = GraphViewEdgePainter(
      edges: edges,
      nodes: nodes,
      highlightedTransitions: highlight.transitionIds,
      selectedTransitions: _selectedTransitions,
      theme: theme,
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
          builder: (context, _, _) {
            final nodes = _controller.nodes.toList(growable: false);
            final edges = _controller.edges.toList(growable: false);
            return ValueListenableBuilder<SimulationHighlight>(
              valueListenable: _controller.highlightNotifier,
              builder: (context, highlight, _) {
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
                                  return AutomatonGraphNode(
                                    label: canvasNode.label,
                                    isInitial: canvasNode.isInitial,
                                    isAccepting: canvasNode.isAccepting,
                                    isHighlighted: isHighlighted,
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
      NodePanGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<NodePanGestureRecognizer>(
            () => NodePanGestureRecognizer(
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
