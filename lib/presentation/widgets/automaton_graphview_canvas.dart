/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/widgets/automaton_graphview_canvas.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Implementa canvas interativo baseado em GraphView para edição e visualização de autômatos finitos. Administra ferramentas, destaques de simulação e sincronização com provedores Riverpod garantindo experiência fluida.
/// Contexto: Coordena controladores internos e externos para manipular nós, transições e overlays de rótulos, além de emitir atualizações para o AutomatonProvider. Incorpora algoritmos de layout e integrações com serviços de destaque para acompanhar execuções.
/// Observações: Gerencia gestos complexos, estados de arrasto e atualizações diferidas para manter desempenho em autômatos grandes. Estrutura lógica extensível permitindo adicionar novas ferramentas ou interações sem refatorações profundas.
/// ---------------------------------------------------------------------------
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';

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
import 'graphview_interactive_canvas.dart';
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
  SimulationHighlightService? _highlightService;
  SimulationHighlightChannel? _previousHighlightChannel;
  GraphViewSimulationHighlightChannel? _highlightChannel;
  FSA? _pendingSyncAutomaton;
  bool _syncScheduled = false;

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

    _scheduleControllerSync(widget.automaton);

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
      if (_ownsToolController) {
        _toolController.dispose();
      }
      final nextController =
          widget.toolController ?? AutomatonCanvasToolController();
      _toolController = nextController;
      _ownsToolController = widget.toolController == null;
    }

    if (oldWidget.controller != widget.controller) {
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
      _scheduleControllerSync(widget.automaton);
    } else if (oldWidget.automaton != widget.automaton) {
      _scheduleControllerSync(widget.automaton);
    }
  }

  @override
  void dispose() {
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

  GraphViewTransitionDelegate<String> _buildTransitionDelegate() {
    return GraphViewTransitionDelegate<String>(
      buildDefaultData: (_, __) => '',
      dataFromEdge: (edge) => edge.label,
      commit: (fromStateId, toStateId, worldAnchor, label, transitionId) {
        _controller.addOrUpdateTransition(
          fromStateId: fromStateId,
          toStateId: toStateId,
          label: label,
          transitionId: transitionId,
          controlPointX: worldAnchor.dx,
          controlPointY: worldAnchor.dy,
        );
      },
      buildOverlay: (context, state, onSubmit, onCancel) {
        return GraphViewLabelFieldEditor(
          initialValue: state.data,
          onSubmit: onSubmit,
          onCancel: onCancel,
        );
      },
      buildFallbackEditor: (context, state) async {
        final result = await showDialog<String?>(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: TransitionLabelEditorForm(
                initialValue: state.data,
                autofocus: true,
                touchOptimized: true,
                onSubmit: (value) => Navigator.of(context).pop(value),
                onCancel: () => Navigator.of(context).pop(null),
              ),
            );
          },
        );
        return result;
      },
      selectionPrompt: (context, edges) =>
          _promptTransitionEditChoice(context, edges),
    );
  }

  Future<GraphViewTransitionSelection> _promptTransitionEditChoice(
    BuildContext context,
    List<GraphViewCanvasEdge> edges,
  ) async {
    final choice = await showDialog<_TransitionEditChoice?>(
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
                    title: const Text('Create new transition'),
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
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (choice == null || choice.createNew) {
      return const GraphViewTransitionSelection.createNew();
    }
    return GraphViewTransitionSelection.edit(choice.edge!);
  }

  @override
  Widget build(BuildContext context) {
    return GraphViewInteractiveCanvas<String>(
      canvasKey: widget.canvasKey,
      controller: _controller,
      algorithmBuilder: (controller) => _AutomatonGraphSugiyamaAlgorithm(
        controller: controller as GraphViewCanvasController,
        configuration: _buildConfiguration(),
      ),
      toolController: _toolController,
      transitionDelegate: _buildTransitionDelegate(),
      nodeBuilder: (context, node, highlight, isHighlighted) {
        return _AutomatonGraphNode(
          label: node.label,
          isInitial: node.isInitial,
          isAccepting: node.isAccepting,
          isHighlighted: isHighlighted,
        );
      },
      edgePainterBuilder:
          ({
            required edges,
            required nodes,
            required highlight,
            required theme,
            required selectedTransitions,
          }) {
            return _GraphViewEdgePainter(
              edges: edges,
              nodes: nodes,
              highlightedTransitions: highlight.transitionIds,
              selectedTransitions: selectedTransitions,
              theme: theme,
            );
          },
      transitionToolLabel: 'Add transition…',
    );
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
      return Size.zero;
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final node in graph.nodes) {
      final nodeId = node.key?.value?.toString();
      final cached = nodeId != null ? controller.nodeById(nodeId) : null;
      final position = cached != null
          ? Offset(cached.x, cached.y)
          : node.position;

      node.position = position;

      minX = math.min(minX, position.dx);
      minY = math.min(minY, position.dy);
      maxX = math.max(maxX, position.dx + node.width);
      maxY = math.max(maxY, position.dy + node.height);
    }

    if (minX == double.infinity || minY == double.infinity) {
      return Size.zero;
    }

    final width = (maxX - minX).clamp(0.0, double.infinity) + _kNodeDiameter;
    final height = (maxY - minY).clamp(0.0, double.infinity) + _kNodeDiameter;

    return Size(width, height);
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

  static final ArrowEdgeRenderer _loopRenderer = ArrowEdgeRenderer();

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
        final loopGeometry = _buildGraphViewSelfLoop(edge, from);
        if (loopGeometry == null) {
          continue;
        }
        _loopRenderer.renderEdge(canvas, loopGeometry.edge, paint);
        _drawEdgeLabel(canvas, loopGeometry.labelAnchor, edge.label, color);
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

  ({Edge edge, Offset labelAnchor})? _buildGraphViewSelfLoop(
    GraphViewCanvasEdge edge,
    GraphViewCanvasNode node,
  ) {
    final graphNode = Node.Id(node.id)
      ..size = const Size(_kNodeDiameter, _kNodeDiameter)
      ..position = Offset(node.x, node.y);
    final graphEdge = Edge(graphNode, graphNode);

    final loop = _loopRenderer.buildSelfLoopPath(
      graphEdge,
      arrowLength: ARROW_LENGTH,
    );
    if (loop == null) {
      return null;
    }

    final bounds = loop.path.getBounds();
    final labelAnchor = Offset(bounds.center.dx, bounds.top - 12);

    return (edge: graphEdge, labelAnchor: labelAnchor);
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
