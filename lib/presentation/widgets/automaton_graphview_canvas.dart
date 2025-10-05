import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
import '../providers/automaton_provider.dart';
import 'automaton_canvas_tool.dart';
import 'transition_editors/transition_label_editor.dart';

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

    _controller.synchronize(widget.automaton);
    _transformationController?.addListener(_onTransformationChanged);

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
      final nextController = widget.toolController ?? AutomatonCanvasToolController();
      _toolController = nextController;
      _ownsToolController = widget.toolController == null;
      _toolController.addListener(_handleActiveToolChanged);
      _activeTool = _toolController.activeTool;
    }

    if (oldWidget.controller != widget.controller) {
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
        final highlightChannel = GraphViewSimulationHighlightChannel(_controller);
        _highlightChannel = highlightChannel;
        highlightService.channel = highlightChannel;
      }
      _algorithm = _AutomatonGraphSugiyamaAlgorithm(
        controller: _controller,
        configuration: _buildConfiguration(),
      );
      _transformationController?.addListener(_onTransformationChanged);
      _controller.synchronize(widget.automaton);
    } else if (oldWidget.automaton != widget.automaton) {
      _controller.synchronize(widget.automaton);
    }
  }

  @override
  void dispose() {
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
    });
  }

  void _onTransformationChanged() {
    setState(() {});
  }

  SugiyamaConfiguration _buildConfiguration() {
    final configuration = SugiyamaConfiguration()
      ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
      ..nodeSeparation = 160
      ..levelSeparation = 160
      ..bendPointShape = CurvedBendPointShape(curveLength: 40);
    return configuration;
  }

  double _currentScale() {
    final matrix = _transformationController?.value ?? Matrix4.identity();
    final storage = matrix.storage;
    final scaleX = math.sqrt(storage[0] * storage[0] +
        storage[1] * storage[1] +
        storage[2] * storage[2]);
    final scaleY = math.sqrt(storage[4] * storage[4] +
        storage[5] * storage[5] +
        storage[6] * storage[6]);
    if (scaleX == 0 && scaleY == 0) {
      return 1.0;
    }
    if (scaleX == 0) {
      return scaleY.abs();
    }
    if (scaleY == 0) {
      return scaleX.abs();
    }
    return (scaleX.abs() + scaleY.abs()) / 2;
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
    final vector = matrix.transform3(vmath.Vector3(
      localPosition.dx,
      localPosition.dy,
      0,
    ));
    return Offset(vector.x, vector.y);
  }

  Future<void> _handleCanvasTap(TapUpDetails details) async {
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

  void _handleNodePanStart(String nodeId, DragStartDetails details) {
    _selectedTransitions.clear();
  }

  void _handleNodePanUpdate(String nodeId, DragUpdateDetails details) {
    final scale = _currentScale();
    final delta = details.delta / scale;
    final node = _controller.nodeById(nodeId);
    if (node == null) {
      return;
    }
    final nextPosition = Offset(node.x, node.y) + delta;
    _controller.moveState(nodeId, nextPosition);
  }

  void _handleNodeTap(String nodeId) {
    if (_activeTool != AutomatonCanvasTool.transition) {
      return;
    }

    if (_transitionSourceId == null) {
      setState(() {
        _transitionSourceId = nodeId;
      });
      return;
    }

    final sourceId = _transitionSourceId!;
    setState(() {
      _transitionSourceId = null;
    });
    _showTransitionEditor(sourceId, nodeId);
  }

  GraphViewCanvasEdge? _findExistingEdge(String fromId, String toId) {
    for (final edge in _controller.edges) {
      if (edge.fromStateId == fromId && edge.toStateId == toId) {
        return edge;
      }
    }
    return null;
  }

  Future<void> _showTransitionEditor(String fromId, String toId) async {
    final existing = _findExistingEdge(fromId, toId);
    final initialValue = existing?.label ?? '';
    final controlPoint = existing != null
        ? Offset(
            existing.controlPointX ?? 0,
            existing.controlPointY ?? 0,
          )
        : _deriveControlPoint(fromId, toId);

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

    _controller.addOrUpdateTransition(
      fromStateId: fromId,
      toStateId: toId,
      label: label,
      transitionId: existing?.id,
      controlPointX: controlPoint.dx,
      controlPointY: controlPoint.dy,
    );
  }

  Offset _deriveControlPoint(String fromId, String toId) {
    final fromNode = _controller.nodeById(fromId);
    final toNode = _controller.nodeById(toId);
    if (fromNode == null || toNode == null) {
      return Offset.zero;
    }

    final fromOffset = Offset(fromNode.x, fromNode.y);
    final toOffset = Offset(toNode.x, toNode.y);

    if (fromId == toId) {
      return fromOffset.translate(0, -_kNodeDiameter);
    }

    final midpoint = Offset(
      (fromOffset.dx + toOffset.dx) / 2,
      (fromOffset.dy + toOffset.dy) / 2,
    );

    final dx = toOffset.dx - fromOffset.dx;
    final dy = toOffset.dy - fromOffset.dy;
    var normal = Offset(-dy, dx);
    if (normal.distanceSquared == 0) {
      normal = const Offset(0, -1);
    }
    final existing = _controller.edges.where((edge) {
      return edge.fromStateId == fromId && edge.toStateId == toId;
    }).length;
    final direction = existing.isEven ? 1 : -1;
    final magnitude = (_kNodeDiameter * 0.8) + existing * 12;
    final normalized = normal / normal.distance * magnitude * direction;
    return midpoint + normalized;
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
    return GestureDetector(
      key: widget.canvasKey,
      onTapUp: _handleCanvasTap,
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
                    child: GraphView.builder(
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
                        final isHighlighted =
                            _isNodeHighlighted(canvasNode, highlight);
                        return _AutomatonGraphNode(
                          label: canvasNode.label,
                          isInitial: canvasNode.isInitial,
                          isAccepting: canvasNode.isAccepting,
                          isHighlighted: isHighlighted,
                          onTap: () => _handleNodeTap(canvasNode.id),
                          onPanStart: (details) =>
                              _handleNodePanStart(canvasNode.id, details),
                          onPanUpdate: (details) =>
                              _handleNodePanUpdate(canvasNode.id, details),
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
    final size = super.run(graph, shiftX, shiftY);
    if (graph == null) {
      return size;
    }

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
    required this.onTap,
    required this.onPanStart,
    required this.onPanUpdate,
  });

  final String label;
  final bool isInitial;
  final bool isAccepting;
  final bool isHighlighted;
  final GestureTapCallback onTap;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;

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

    return GestureDetector(
      onTap: onTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      child: SizedBox(
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
                left: -16,
                top: _kNodeRadius - 6,
                child: CustomPaint(
                  size: const Size(24, 12),
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
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
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

      final fromCenter = Offset(from.x, from.y);
      final toCenter = Offset(to.x, to.y);
      final controlPoint = (edge.controlPointX != null &&
              edge.controlPointY != null)
          ? Offset(edge.controlPointX!, edge.controlPointY!)
          : null;

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
        final loopPoint = controlPoint ??
            fromCenter.translate(0, -_kNodeDiameter);
        final loopPath = _buildLoopPath(fromCenter, loopPoint);
        canvas.drawPath(loopPath.path, paint);
        _drawArrowHead(
          canvas,
          loopPath.tip,
          loopPath.direction,
          color,
        );
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

      final labelAnchor = controlPoint ?? Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2,
      );
      _drawEdgeLabel(canvas, labelAnchor, edge.label, color);
    }
  }

  ({Path path, Offset tip, Offset direction, Offset labelAnchor}) _buildLoopPath(
    Offset center,
    Offset anchor,
  ) {
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
        style: TextStyle(
          color: color,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = position -
        Offset(textPainter.width / 2, textPainter.height / 2 + 4);
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
