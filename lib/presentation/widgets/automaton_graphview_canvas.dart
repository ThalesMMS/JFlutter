import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../../core/constants/automaton_canvas.dart';
import '../../core/models/fsa.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/models/simulation_result.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/graphview/graphview_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_canvas_models.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../features/canvas/graphview/graphview_all_nodes_builder.dart';
import '../../features/canvas/graphview/graphview_label_field_editor.dart';
import '../../features/canvas/graphview/graphview_link_overlay_utils.dart';
import '../providers/automaton_provider.dart';
import 'automaton_canvas_tool.dart';
import 'transition_editors/transition_label_editor.dart';

const double _kNodeDiameter = kAutomatonStateDiameter;
const double _kNodeRadius = _kNodeDiameter / 2;
const Size _kInitialArrowSize = Size(24, 12);

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
  });

  final FSA? automaton;
  final GlobalKey canvasKey;
  final GraphViewCanvasController? controller;
  final AutomatonCanvasToolController? toolController;
  final SimulationResult? simulationResult;
  final int? currentStepIndex;
  final bool showTrace;

  @override
  ConsumerState<AutomatonGraphViewCanvas> createState() =>
      _AutomatonGraphViewCanvasState();
}

class _AutomatonGraphViewCanvasState
    extends ConsumerState<AutomatonGraphViewCanvas> {
  late GraphViewCanvasController _controller;
  late bool _ownsController;
  late AutomatonCanvasToolController _toolController;
  late bool _ownsToolController;
  AutomatonCanvasTool _activeTool = AutomatonCanvasTool.selection;
  SimulationHighlightService? _highlightService;
  SimulationHighlightChannel? _previousHighlightChannel;
  GraphViewSimulationHighlightChannel? _highlightChannel;
  late _AutomatonGraphSugiyamaAlgorithm _algorithm;
  final Set<String> _selectedTransitions = <String>{};
  String? _transitionSourceId;
  OverlayEntry? _transitionOverlayEntry;
  final ValueNotifier<_GraphViewTransitionOverlayState?>
  _transitionOverlayState = ValueNotifier<_GraphViewTransitionOverlayState?>(
    null,
  );
  FSA? _pendingSyncAutomaton;
  bool _syncScheduled = false;
  Matrix4? _frozenTransformationMatrix;
  String? _draggingNodeId;
  Offset? _dragStartWorldPosition;
  Offset? _dragStartNodeCenter;

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
      _highlightChannel = highlightChannel;
      highlightService.channel = highlightChannel;
    }

    _algorithm = _AutomatonGraphSugiyamaAlgorithm(
      controller: _controller,
      configuration: _buildConfiguration(),
    );
    _scheduleControllerSync(widget.automaton);
    _controller.graphRevision.addListener(_handleGraphRevisionChanged);
    _transformationController?.addListener(_onTransformationChanged);

    if (_activeTool != AutomatonCanvasTool.selection) {
      final transformation = _transformationController;
      if (transformation != null) {
        _frozenTransformationMatrix = Matrix4.copy(transformation.value);
      }
    }

    if ((widget.automaton?.states.isNotEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.fitToContent();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AutomatonGraphViewCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    }

    if (oldWidget.controller != widget.controller) {
      _controller.graphRevision.removeListener(_handleGraphRevisionChanged);
      _transformationController?.removeListener(_onTransformationChanged);
      if (_ownsController) {
        if (_highlightService != null) {
          _highlightService!.channel = _previousHighlightChannel;
          _highlightChannel = null;
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
        _highlightChannel = highlightChannel;
        highlightService.channel = highlightChannel;
      }
      _algorithm = _AutomatonGraphSugiyamaAlgorithm(
        controller: _controller,
        configuration: _buildConfiguration(),
      );
      _transformationController?.addListener(_onTransformationChanged);
      if (_activeTool != AutomatonCanvasTool.selection) {
        final transformation = _transformationController;
        if (transformation != null) {
          _frozenTransformationMatrix = Matrix4.copy(transformation.value);
        }
      }
      _scheduleControllerSync(widget.automaton);
      _controller.graphRevision.addListener(_handleGraphRevisionChanged);
      _hideTransitionOverlay();
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
      _highlightChannel = null;
    }
    _transitionOverlayEntry?.remove();
    _transitionOverlayEntry = null;
    _transitionOverlayState.dispose();
    super.dispose();
  }

  void _handleActiveToolChanged() {
    final nextTool = _toolController.activeTool;
    if (nextTool == _activeTool) {
      return;
    }
    final previousTool = _activeTool;
    if (previousTool == AutomatonCanvasTool.selection &&
        nextTool != AutomatonCanvasTool.selection) {
      final transformation = _transformationController;
      if (transformation != null) {
        _frozenTransformationMatrix = Matrix4.copy(transformation.value);
      } else {
        _frozenTransformationMatrix = null;
      }
    } else if (nextTool == AutomatonCanvasTool.selection) {
      _frozenTransformationMatrix = null;
    } else if (_frozenTransformationMatrix == null) {
      final transformation = _transformationController;
      if (transformation != null) {
        _frozenTransformationMatrix = Matrix4.copy(transformation.value);
      }
    }
    setState(() {
      _activeTool = nextTool;
      if (_activeTool != AutomatonCanvasTool.transition) {
        _transitionSourceId = null;
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
    final transformation = _transformationController;
    var resetTransformation = false;
    if (_activeTool != AutomatonCanvasTool.selection) {
      final frozen = _frozenTransformationMatrix;
      if (transformation != null && frozen != null) {
        if (!listEquals(transformation.value.storage, frozen.storage)) {
          transformation.value = Matrix4.copy(frozen);
          resetTransformation = true;
        }
      }
    }
    if (resetTransformation) {
      return;
    }
    _updateTransitionOverlayPosition();
    setState(() {});
  }

  void _scheduleControllerSync(FSA? automaton) {
    _pendingSyncAutomaton = automaton;
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
      _controller.synchronize(target);
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
    if (_activeTool == AutomatonCanvasTool.transition) {
      final node = _hitTestNode(local, logDetails: false);
      if (node != null) {
        _handleNodeTap(node.id);
      }
    }
  }

  void _beginNodeDrag(GraphViewCanvasNode node, Offset localPosition) {
    debugPrint('[AutomatonGraphViewCanvas] Begin drag for ${node.id}');
    _hideTransitionOverlay();
    _draggingNodeId = node.id;
    _dragStartWorldPosition = _screenToWorld(localPosition);
    final current = _controller.nodeById(node.id) ?? node;
    _dragStartNodeCenter = Offset(current.x, current.y);
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
  }

  void _endNodeDrag() {
    _draggingNodeId = null;
    _dragStartWorldPosition = null;
    _dragStartNodeCenter = null;
  }

  Future<void> _handleCanvasTap(TapUpDetails details) async {
    debugPrint(
      '[AutomatonGraphViewCanvas] Canvas tapped with '
      'active tool ${_activeTool.name}',
    );
    if (_activeTool != AutomatonCanvasTool.addState) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }
    final localPosition = box.globalToLocal(details.globalPosition);
    final world = _screenToWorld(localPosition);
    _controller.addStateAt(world);
  }

  void _handleNodePanStart(DragStartDetails details) {
    if (_activeTool != AutomatonCanvasTool.selection) {
      return;
    }
    final node = _hitTestNode(details.localPosition);
    if (node == null) {
      return;
    }
    _beginNodeDrag(node, details.localPosition);
  }

  void _handleNodePanUpdate(DragUpdateDetails details) {
    if (_activeTool != AutomatonCanvasTool.selection) {
      return;
    }
    _updateNodeDrag(details.localPosition);
  }

  void _handleNodePanEnd(DragEndDetails details) {
    if (_activeTool != AutomatonCanvasTool.selection) {
      return;
    }
    _endNodeDrag();
  }

  void _handleNodePanCancel() {
    if (_activeTool != AutomatonCanvasTool.selection) {
      return;
    }
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

  void _handleNodeLongPress(String nodeId) {
    if (_activeTool != AutomatonCanvasTool.selection) {
      return;
    }
    final node = _controller.nodeById(nodeId);
    if (node == null) {
      return;
    }
    _showStateOptions(node);
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

    final initialValue = existing?.label ?? '';
    final worldAnchor = !createNew && existing != null
        ? resolveLinkAnchorWorld(_controller, existing) ??
              Offset(existing.controlPointX ?? 0, existing.controlPointY ?? 0)
        : _deriveControlPoint(fromId, toId);

    final overlayDisplayed = _showTransitionOverlay(
      fromStateId: fromId,
      toStateId: toId,
      transitionId: createNew ? null : existing?.id,
      initialValue: initialValue,
      worldAnchor: worldAnchor,
    );

    if (overlayDisplayed) {
      debugPrint(
        '[AutomatonGraphViewCanvas] Showing transition editor '
        'for $fromId → $toId (transitionId: ${existing?.id})',
      );
      setState(() {
        _selectedTransitions..clear();
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

    final label = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: TransitionLabelEditorForm(
            initialValue: initialValue,
            autofocus: true,
            touchOptimized: true,
            onSubmit: (value) => Navigator.of(context).pop(value),
            onCancel: () => Navigator.of(context).pop(null),
          ),
        );
      },
    );

    if (!mounted || label == null) {
      return;
    }

    debugPrint(
      '[AutomatonGraphViewCanvas] Persisting transition '
      'for $fromId → $toId (transitionId: ${existing?.id})',
    );

    _controller.addOrUpdateTransition(
      fromStateId: fromId,
      toStateId: toId,
      label: label,
      transitionId: createNew ? null : existing?.id,
      controlPointX: worldAnchor.dx,
      controlPointY: worldAnchor.dy,
    );
  }

  Future<_TransitionEditChoice?> _promptTransitionEditChoice(
    List<GraphViewCanvasEdge> edges,
  ) {
    return showDialog<_TransitionEditChoice>(
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
                      ).pop(_TransitionEditChoice.edit(edge)),
                    ),
                  ListTile(
                    key: const ValueKey(
                      'automaton-transition-choice-create-new',
                    ),
                    leading: const Icon(Icons.add_outlined),
                    title: const Text('Criar nova transição'),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(const _TransitionEditChoice.createNew()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
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
        initialValue: edge.label,
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
    required String initialValue,
    required Offset worldAnchor,
    String? transitionId,
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
    _transitionOverlayState.value = _GraphViewTransitionOverlayState(
      fromStateId: fromStateId,
      toStateId: toStateId,
      initialValue: initialValue,
      worldAnchor: worldAnchor,
      overlayPosition: overlayPosition,
      transitionId: transitionId,
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
          child: ValueListenableBuilder<_GraphViewTransitionOverlayState?>(
            valueListenable: _transitionOverlayState,
            builder: (context, state, _) {
              if (state == null) {
                return const SizedBox.shrink();
              }
              return Stack(
                children: [
                  Positioned(
                    left: state.overlayPosition.dx,
                    top: state.overlayPosition.dy,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: GraphViewLabelFieldEditor(
                        initialValue: state.initialValue,
                        onSubmit: (value) => _handleOverlaySubmit(state, value),
                        onCancel: _hideTransitionOverlay,
                      ),
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
    _GraphViewTransitionOverlayState state,
    String label,
  ) {
    debugPrint(
      '[AutomatonGraphViewCanvas] Persisting transition '
      'for ${state.fromStateId} → ${state.toStateId} '
      '(transitionId: ${state.transitionId})',
    );
    _controller.addOrUpdateTransition(
      fromStateId: state.fromStateId,
      toStateId: state.toStateId,
      label: label,
      transitionId: state.transitionId,
      controlPointX: state.worldAnchor.dx,
      controlPointY: state.worldAnchor.dy,
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
    final painter = _GraphViewEdgePainter(
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
        onTapUp: _activeTool == AutomatonCanvasTool.addState
            ? _handleCanvasTap
            : null,
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
                                return _AutomatonGraphNode(
                                  label: canvasNode.label,
                                  isInitial: canvasNode.isInitial,
                                  isAccepting: canvasNode.isAccepting,
                                  isHighlighted: isHighlighted,
                                );
                              },
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
            ),
            (recognizer) {
              recognizer
                ..onStart = _handleNodePanStart
                ..onUpdate = _handleNodePanUpdate
                ..onEnd = _handleNodePanEnd
                ..onCancel = _handleNodePanCancel
                ..dragStartBehavior = DragStartBehavior.down;
            },
          ),
    };

    gestures[_NodeTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<_NodeTapGestureRecognizer>(
          () => _NodeTapGestureRecognizer(
            hitTester: (global) =>
                _hitTestNode(_globalToCanvasLocal(global), logDetails: false),
            toolResolver: () => _activeTool,
            onPointerDown: (global) => _logCanvasTapFromGlobal(
              source: 'tap-pointer',
              globalPosition: global,
            ),
          ),
          (recognizer) {
            recognizer.onNodeTap = (node) => _handleNodeTap(node.id);
          },
        );

    gestures[_NodeLongPressGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<_NodeLongPressGestureRecognizer>(
          () => _NodeLongPressGestureRecognizer(
            hitTester: (global) =>
                _hitTestNode(_globalToCanvasLocal(global), logDetails: false),
            toolResolver: () => _activeTool,
            onPointerDown: (global) => _logCanvasTapFromGlobal(
              source: 'long-press-pointer',
              globalPosition: global,
            ),
          ),
          (recognizer) {
            recognizer.onNodeLongPress = (node) =>
                _handleNodeLongPress(node.id);
          },
        );

    return gestures;
  }
}

class _TransitionEditChoice {
  const _TransitionEditChoice._({required this.createNew, this.edge});

  const _TransitionEditChoice.edit(GraphViewCanvasEdge edge)
    : this._(createNew: false, edge: edge);

  const _TransitionEditChoice.createNew() : this._(createNew: true);

  final bool createNew;
  final GraphViewCanvasEdge? edge;
}

class _GraphViewTransitionOverlayState {
  const _GraphViewTransitionOverlayState({
    required this.fromStateId,
    required this.toStateId,
    required this.initialValue,
    required this.worldAnchor,
    required this.overlayPosition,
    this.transitionId,
  });

  final String fromStateId;
  final String toStateId;
  final String initialValue;
  final Offset worldAnchor;
  final Offset overlayPosition;
  final String? transitionId;

  _GraphViewTransitionOverlayState copyWith({
    String? initialValue,
    Offset? worldAnchor,
    Offset? overlayPosition,
  }) {
    return _GraphViewTransitionOverlayState(
      fromStateId: fromStateId,
      toStateId: toStateId,
      initialValue: initialValue ?? this.initialValue,
      worldAnchor: worldAnchor ?? this.worldAnchor,
      overlayPosition: overlayPosition ?? this.overlayPosition,
      transitionId: transitionId,
    );
  }
}

class _AutomatonGraphSugiyamaAlgorithm extends SugiyamaAlgorithm {
  _AutomatonGraphSugiyamaAlgorithm({
    required this.controller,
    required SugiyamaConfiguration configuration,
  }) : super(configuration);

  final GraphViewCanvasController controller;

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodes.isEmpty) {
      // GraphView's Sugiyama implementation crashes when no nodes exist.
      return Size.zero;
    }
    final size = super.run(graph, shiftX, shiftY);
    for (final node in graph.nodes) {
      final nodeId = node.key?.value?.toString();
      if (nodeId == null) {
        continue;
      }
      final cached = controller.nodeById(nodeId);
      if (cached == null) {
        continue;
      }
      node.position = Offset(cached.x, cached.y);
    }
    return size;
  }
}

class _AutomatonGraphNode extends StatelessWidget {
  const _AutomatonGraphNode({
    required this.label,
    required this.isInitial,
    required this.isAccepting,
    required this.isHighlighted,
  });

  final String label;
  final bool isInitial;
  final bool isAccepting;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isHighlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    final backgroundColor = isHighlighted
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surface;

    final badgeColor = theme.colorScheme.primary;

    return SizedBox(
      width: _kNodeDiameter,
      height: _kNodeDiameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor,
                border: Border.all(color: borderColor, width: 3),
              ),
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (isInitial)
            Positioned(
              left: -_kInitialArrowSize.width + 1,
              top: _kNodeRadius - (_kInitialArrowSize.height / 2),
              child: CustomPaint(
                size: _kInitialArrowSize,
                painter: _InitialStateArrowPainter(color: borderColor),
              ),
            ),
          if (isAccepting)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: badgeColor, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InitialStateArrowPainter extends CustomPainter {
  const _InitialStateArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InitialStateArrowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _GraphViewEdgePainter extends CustomPainter {
  _GraphViewEdgePainter({
    required this.edges,
    required this.nodes,
    required this.highlightedTransitions,
    required this.selectedTransitions,
    required this.theme,
  });

  final List<GraphViewCanvasEdge> edges;
  final List<GraphViewCanvasNode> nodes;
  final Set<String> highlightedTransitions;
  final Set<String> selectedTransitions;
  final ThemeData theme;

  GraphViewCanvasNode? _nodeById(String id) {
    for (final node in nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = theme.colorScheme.outline;
    final highlightColor = theme.colorScheme.primary;

    for (final edge in edges) {
      final from = _nodeById(edge.fromStateId);
      final to = _nodeById(edge.toStateId);
      if (from == null || to == null) {
        continue;
      }

      final fromCenter = Offset(from.x + _kNodeRadius, from.y + _kNodeRadius);
      final toCenter = Offset(to.x + _kNodeRadius, to.y + _kNodeRadius);
      final controlPoint = _resolveControlPoint(edge, fromCenter, toCenter);

      final isHighlighted = highlightedTransitions.contains(edge.id);
      final isSelected = selectedTransitions.contains(edge.id);
      final color = isHighlighted ? highlightColor : baseColor;
      final strokeWidth = isSelected ? 4.0 : 2.0;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (edge.fromStateId == edge.toStateId) {
        final loopPoint =
            controlPoint ?? fromCenter.translate(0, -_kNodeDiameter);
        final loopPath = _buildLoopPath(fromCenter, loopPoint);
        canvas.drawPath(loopPath.path, paint);
        _drawArrowHead(canvas, loopPath.tip, loopPath.direction, color);
        _drawEdgeLabel(canvas, loopPath.labelAnchor, edge.label, color);
        continue;
      }

      final start = _projectFromCenter(
        fromCenter,
        controlPoint ?? toCenter,
        _kNodeRadius,
      );
      final end = _projectFromCenter(
        toCenter,
        controlPoint ?? fromCenter,
        _kNodeRadius,
      );

      final path = Path()..moveTo(start.dx, start.dy);
      Offset direction;
      if (controlPoint != null) {
        path.quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          end.dx,
          end.dy,
        );
        direction = end - controlPoint;
      } else {
        path.lineTo(end.dx, end.dy);
        direction = end - start;
      }
      canvas.drawPath(path, paint);
      _drawArrowHead(canvas, end, direction, color);

      final labelAnchor =
          controlPoint ??
          Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      _drawEdgeLabel(canvas, labelAnchor, edge.label, color);
    }
  }

  ({Path path, Offset tip, Offset direction, Offset labelAnchor})
  _buildLoopPath(Offset center, Offset anchor) {
    final path = Path();
    final start = center + Offset(0, -_kNodeRadius);
    final end = center + Offset(_kNodeRadius * 0.7, -_kNodeRadius * 0.2);
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(anchor.dx, anchor.dy, end.dx, end.dy);
    final labelAnchor = Offset(
      (start.dx + anchor.dx) / 2,
      math.min(start.dy, anchor.dy) - 12,
    );
    return (
      path: path,
      tip: end,
      direction: end - anchor,
      labelAnchor: labelAnchor,
    );
  }

  Offset _projectFromCenter(Offset center, Offset target, double radius) {
    final vector = target - center;
    if (vector.distance == 0) {
      return center;
    }
    final normalized = vector / vector.distance;
    return center + normalized * radius;
  }

  Offset? _resolveControlPoint(
    GraphViewCanvasEdge edge,
    Offset fromCenter,
    Offset toCenter,
  ) {
    final rawX = edge.controlPointX;
    final rawY = edge.controlPointY;
    if (rawX == null || rawY == null) {
      return null;
    }

    final raw = Offset(rawX, rawY);
    final averageCenter = Offset(
      (fromCenter.dx + toCenter.dx) / 2,
      (fromCenter.dy + toCenter.dy) / 2,
    );

    const legacyOffset = Offset(_kNodeRadius, _kNodeRadius);
    final legacyCandidate = raw + legacyOffset;

    final rawDistance = (raw - averageCenter).distance;
    final legacyDistance = (legacyCandidate - averageCenter).distance;

    return legacyDistance < rawDistance ? legacyCandidate : raw;
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset position,
    Offset direction,
    Color color,
  ) {
    if (direction.distance == 0) {
      return;
    }
    final normalized = direction / direction.distance;
    final normal = Offset(-normalized.dy, normalized.dx);
    const arrowLength = 12.0;
    const arrowWidth = 6.0;
    final tip = position;
    final base = tip - normalized * arrowLength;
    final left = base + normal * arrowWidth;
    final right = base - normal * arrowWidth;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawEdgeLabel(
    Canvas canvas,
    Offset position,
    String label,
    Color color,
  ) {
    if (label.isEmpty) {
      return;
    }
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: color, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset =
        position - Offset(textPainter.width / 2, textPainter.height / 2 + 4);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _GraphViewEdgePainter oldDelegate) {
    return !listEquals(oldDelegate.edges, edges) ||
        !listEquals(oldDelegate.nodes, nodes) ||
        !setEquals(
          oldDelegate.highlightedTransitions,
          highlightedTransitions,
        ) ||
        !setEquals(oldDelegate.selectedTransitions, selectedTransitions) ||
        oldDelegate.theme != theme;
  }
}

typedef _NodeHitTester = GraphViewCanvasNode? Function(Offset globalPosition);
typedef _ToolResolver = AutomatonCanvasTool Function();

class _NodePanGestureRecognizer extends PanGestureRecognizer {
  _NodePanGestureRecognizer({
    required this.hitTester,
    required this.toolResolver,
    this.onPointerDown,
  });

  final _NodeHitTester hitTester;
  final _ToolResolver toolResolver;
  final ValueChanged<Offset>? onPointerDown;

  int? _activePointer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    onPointerDown?.call(event.position);
    if (_activePointer != null) {
      return;
    }
    if (toolResolver() != AutomatonCanvasTool.selection) {
      return;
    }
    final node = hitTester(event.position);
    if (node == null) {
      return;
    }
    debugPrint(
      '[NodePanRecognizer] accepting pointer ${event.pointer} '
      'for node ${node.id}',
    );
    _activePointer = event.pointer;
    super.addAllowedPointer(event);
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer == _activePointer) {
      _activePointer = null;
    }
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (pointer == _activePointer) {
      _activePointer = null;
    }
    super.didStopTrackingLastPointer(pointer);
  }
}

class _NodeTapGestureRecognizer extends TapGestureRecognizer {
  _NodeTapGestureRecognizer({
    required this.hitTester,
    required this.toolResolver,
    this.onPointerDown,
  });

  final _NodeHitTester hitTester;
  final _ToolResolver toolResolver;
  final ValueChanged<Offset>? onPointerDown;

  ValueChanged<GraphViewCanvasNode>? onNodeTap;
  GraphViewCanvasNode? _downNode;

  bool get _toolEnabled {
    final tool = toolResolver();
    return tool == AutomatonCanvasTool.transition ||
        tool == AutomatonCanvasTool.selection;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    onPointerDown?.call(event.position);
    if (!_toolEnabled) {
      return;
    }
    final node = hitTester(event.position);
    if (node == null) {
      return;
    }
    _downNode = node;
    debugPrint(
      '[NodeTapRecognizer] pointer ${event.pointer} '
      'down on ${node.id} tool=${toolResolver().name}',
    );
    super.addAllowedPointer(event);
    resolvePointer(event.pointer, GestureDisposition.accepted);
  }

  @override
  void handleTapUp({
    required PointerDownEvent down,
    required PointerUpEvent up,
  }) {
    final node = _downNode ?? hitTester(up.position);
    debugPrint(
      '[NodeTapRecognizer] tap up pointer ${up.pointer} '
      'node=${node?.id}',
    );
    if (node != null) {
      onNodeTap?.call(node);
    }
    _downNode = null;
    super.handleTapUp(down: down, up: up);
  }

  @override
  void handleTapCancel({
    required PointerDownEvent down,
    PointerCancelEvent? cancel,
    required String reason,
  }) {
    debugPrint(
      '[NodeTapRecognizer] tap cancel pointer ${down.pointer} '
      'reason=$reason',
    );
    _downNode = null;
    super.handleTapCancel(down: down, cancel: cancel, reason: reason);
  }

  @override
  void rejectGesture(int pointer) {
    _downNode = null;
    super.rejectGesture(pointer);
  }
}

class _NodeLongPressGestureRecognizer extends LongPressGestureRecognizer {
  _NodeLongPressGestureRecognizer({
    required this.hitTester,
    required this.toolResolver,
    this.onPointerDown,
  }) {
    super.onLongPress = _invokeNodeLongPress;
  }

  final _NodeHitTester hitTester;
  final _ToolResolver toolResolver;
  final ValueChanged<Offset>? onPointerDown;

  ValueChanged<GraphViewCanvasNode>? onNodeLongPress;
  GraphViewCanvasNode? _candidate;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    onPointerDown?.call(event.position);
    if (toolResolver() != AutomatonCanvasTool.selection) {
      return;
    }
    final node = hitTester(event.position);
    if (node == null) {
      return;
    }
    _candidate = node;
    super.addAllowedPointer(event);
  }

  @override
  void rejectGesture(int pointer) {
    _candidate = null;
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _candidate = null;
    super.didStopTrackingLastPointer(pointer);
  }

  void _invokeNodeLongPress() {
    final node = _candidate;
    if (node != null) {
      onNodeLongPress?.call(node);
    }
    _candidate = null;
  }
}
