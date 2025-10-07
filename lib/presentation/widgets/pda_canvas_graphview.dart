/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/widgets/pda_canvas_graphview.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Renderiza o canvas de autômatos de pilha usando GraphView, sincronizando estados e transições com o provedor de edição.
/// Contexto: Integra controladores especializados para atualizar nós, gerenciar canal de destaques e ajustar a visualização conforme o conteúdo.
/// Observações: Oferece opção de reutilizar controlador externo preservando recursos e evitando substituição de canais existentes.
/// ---------------------------------------------------------------------------
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';

import '../../core/models/pda.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/graphview/graphview_canvas_models.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../features/canvas/graphview/graphview_pda_canvas_controller.dart';
import '../providers/pda_editor_provider.dart';
import 'automaton_canvas_tool.dart';
import 'graphview_interactive_canvas.dart';
import 'transition_editors/pda_transition_editor.dart';

class PDACanvasGraphView extends ConsumerStatefulWidget {
  const PDACanvasGraphView({
    super.key,
    required this.onPdaModified,
    this.controller,
    this.toolController,
  });

  final ValueChanged<PDA> onPdaModified;
  final GraphViewPdaCanvasController? controller;
  final AutomatonCanvasToolController? toolController;

  @override
  ConsumerState<PDACanvasGraphView> createState() => _PDACanvasGraphViewState();
}

class _PDACanvasGraphViewState extends ConsumerState<PDACanvasGraphView> {
  late GraphViewPdaCanvasController _controller;
  late bool _ownsController;
  late AutomatonCanvasToolController _toolController;
  late bool _ownsToolController;
  SimulationHighlightService? _highlightService;
  SimulationHighlightChannel? _previousHighlightChannel;
  GraphViewSimulationHighlightChannel? _highlightChannel;
  ProviderSubscription<PDAEditorState>? _subscription;
  PDA? _lastDeliveredPda;
  final GlobalKey _canvasKey = GlobalKey();

  GraphViewPdaCanvasController get controller => _controller;

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
      _controller = GraphViewPdaCanvasController(
        editorNotifier: ref.read(pdaEditorProvider.notifier),
      );
      _ownsController = true;
      final highlightService = ref.read(canvasHighlightServiceProvider);
      _highlightService = highlightService;
      _previousHighlightChannel = highlightService.channel;
      final highlightChannel = GraphViewSimulationHighlightChannel(_controller);
      _highlightChannel = highlightChannel;
      highlightService.channel = highlightChannel;
    }

    final initialState = ref.read(pdaEditorProvider);
    _controller.synchronize(initialState.pda);
    if (initialState.pda?.states.isNotEmpty ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.fitToContent();
      });
    }

    _lastDeliveredPda = initialState.pda;
    if (initialState.pda != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onPdaModified(initialState.pda!);
      });
    }

    _subscription = ref.listenManual<PDAEditorState>(pdaEditorProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      final pda = next.pda;
      if (pda != null && !identical(pda, _lastDeliveredPda)) {
        _lastDeliveredPda = pda;
        widget.onPdaModified(pda);
      } else if (pda == null) {
        _lastDeliveredPda = null;
      }
      if (_shouldSynchronize(previous, next)) {
        final hadNodes = _controller.nodes.isNotEmpty;
        _controller.synchronize(pda);
        if (!hadNodes && (pda?.states.isNotEmpty ?? false)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _controller.fitToContent();
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant PDACanvasGraphView oldWidget) {
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
        _controller = GraphViewPdaCanvasController(
          editorNotifier: ref.read(pdaEditorProvider.notifier),
        );
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
      final current = ref.read(pdaEditorProvider).pda;
      _controller.synchronize(current);
    }
  }

  @override
  void dispose() {
    _subscription?.close();
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

  bool _shouldSynchronize(PDAEditorState? previous, PDAEditorState next) {
    final pda = next.pda;
    if (pda == null) {
      return true;
    }
    if (previous?.pda == null) {
      return true;
    }

    final nodeIds = {for (final node in _controller.nodes) node.id};
    final stateIds = {for (final state in pda.states) state.id};
    if (nodeIds.length != stateIds.length || !nodeIds.containsAll(stateIds)) {
      return true;
    }

    final edgeIds = {for (final edge in _controller.edges) edge.id};
    final transitionIds = {
      for (final transition in pda.pdaTransitions) transition.id,
    };
    if (edgeIds.length != transitionIds.length ||
        !edgeIds.containsAll(transitionIds)) {
      return true;
    }

    for (final state in pda.states) {
      final node = _controller.nodeById(state.id);
      if (node == null) {
        return true;
      }
      if ((node.x - state.position.x).abs() > 0.5 ||
          (node.y - state.position.y).abs() > 0.5) {
        return true;
      }
      if (node.label.trim() != state.label.trim()) {
        return true;
      }
    }

    for (final transition in pda.pdaTransitions) {
      final edge = _controller.edgeById(transition.id);
      if (edge == null) {
        return true;
      }
      if (edge.fromStateId != transition.fromState.id ||
          edge.toStateId != transition.toState.id) {
        return true;
      }
      final controlPoint = transition.controlPoint;
      final edgeX = edge.controlPointX ?? controlPoint.x;
      final edgeY = edge.controlPointY ?? controlPoint.y;
      if ((edgeX - controlPoint.x).abs() > 0.5 ||
          (edgeY - controlPoint.y).abs() > 0.5) {
        return true;
      }
      final read = transition.inputSymbol;
      final pop = transition.popSymbol;
      final push = transition.pushSymbol;
      final edgeRead = edge.readSymbol ?? '';
      final edgePop = edge.popSymbol ?? '';
      final edgePush = edge.pushSymbol ?? '';
      if (edgeRead.trim() != read.trim() ||
          edgePop.trim() != pop.trim() ||
          edgePush.trim() != push.trim()) {
        return true;
      }
      if ((edge.isLambdaInput ?? false) != transition.isLambdaInput ||
          (edge.isLambdaPop ?? false) != transition.isLambdaPop ||
          (edge.isLambdaPush ?? false) != transition.isLambdaPush) {
        return true;
      }
    }

    return false;
  }

  SugiyamaAlgorithm _buildAlgorithm(
    BaseGraphViewCanvasController<dynamic, dynamic> controller,
  ) {
    return SugiyamaAlgorithm(
      SugiyamaConfiguration()
        ..nodeSeparation = 160
        ..levelSeparation = 160
        ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM,
    );
  }

  GraphViewTransitionDelegate<_PdaTransitionEditorValue>
  _buildTransitionDelegate() {
    return GraphViewTransitionDelegate<_PdaTransitionEditorValue>(
      buildDefaultData: (_, __) => const _PdaTransitionEditorValue(),
      dataFromEdge: (edge) => _PdaTransitionEditorValue(
        readSymbol: edge.readSymbol ?? '',
        popSymbol: edge.popSymbol ?? '',
        pushSymbol: edge.pushSymbol ?? '',
        lambdaInput: edge.isLambdaInput ?? false,
        lambdaPop: edge.isLambdaPop ?? false,
        lambdaPush: edge.isLambdaPush ?? false,
      ),
      commit: (fromStateId, toStateId, worldAnchor, value, transitionId) {
        _controller.addOrUpdateTransition(
          fromStateId: fromStateId,
          toStateId: toStateId,
          readSymbol: value.readSymbol,
          popSymbol: value.popSymbol,
          pushSymbol: value.pushSymbol,
          isLambdaInput: value.lambdaInput,
          isLambdaPop: value.lambdaPop,
          isLambdaPush: value.lambdaPush,
          transitionId: transitionId,
          controlPointX: worldAnchor.dx,
          controlPointY: worldAnchor.dy,
        );
      },
      buildOverlay: (context, state, onSubmit, onCancel) {
        return Card(
          elevation: 8,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: PdaTransitionEditor(
                initialRead: state.data.readSymbol,
                initialPop: state.data.popSymbol,
                initialPush: state.data.pushSymbol,
                isLambdaInput: state.data.lambdaInput,
                isLambdaPop: state.data.lambdaPop,
                isLambdaPush: state.data.lambdaPush,
                onSubmit:
                    ({
                      required String readSymbol,
                      required String popSymbol,
                      required String pushSymbol,
                      required bool lambdaInput,
                      required bool lambdaPop,
                      required bool lambdaPush,
                    }) {
                      onSubmit(
                        _PdaTransitionEditorValue(
                          readSymbol: readSymbol,
                          popSymbol: popSymbol,
                          pushSymbol: pushSymbol,
                          lambdaInput: lambdaInput,
                          lambdaPop: lambdaPop,
                          lambdaPush: lambdaPush,
                        ),
                      );
                    },
                onCancel: onCancel,
              ),
            ),
          ),
        );
      },
      selectionPrompt: (context, edges) =>
          _promptTransitionSelection(context, edges),
    );
  }

  Future<GraphViewTransitionSelection> _promptTransitionSelection(
    BuildContext context,
    List<GraphViewCanvasEdge> edges,
  ) async {
    final choice = await showDialog<GraphViewTransitionSelection?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecione a transição'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final edge in edges)
                    ListTile(
                      key: ValueKey('pda-transition-choice-${edge.id}'),
                      leading: const Icon(Icons.edit_outlined),
                      title: Text('${edge.fromStateId} → ${edge.toStateId}'),
                      subtitle: Text(edge.label),
                      onTap: () => Navigator.of(
                        context,
                      ).pop(GraphViewTransitionSelection.edit(edge)),
                    ),
                  ListTile(
                    key: const ValueKey('pda-transition-choice-create-new'),
                    leading: const Icon(Icons.add_outlined),
                    title: const Text('Create new transition'),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(const GraphViewTransitionSelection.createNew()),
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

    return choice ?? const GraphViewTransitionSelection.createNew();
  }

  @override
  Widget build(BuildContext context) {
    return GraphViewInteractiveCanvas<_PdaTransitionEditorValue>(
      canvasKey: _canvasKey,
      controller: _controller,
      algorithmBuilder: _buildAlgorithm,
      toolController: _toolController,
      transitionDelegate: _buildTransitionDelegate(),
      nodeBuilder: (context, node, highlight, isHighlighted) {
        return _GraphNodeWidget(
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
            return _GraphEdgePainter(
              edges: edges,
              nodes: nodes,
              highlight: highlight,
              theme: theme,
            );
          },
      transitionToolLabel: 'Add transition…',
    );
  }
}

class _PdaTransitionEditorValue {
  const _PdaTransitionEditorValue({
    this.readSymbol = '',
    this.popSymbol = '',
    this.pushSymbol = '',
    this.lambdaInput = false,
    this.lambdaPop = false,
    this.lambdaPush = false,
  });

  final String readSymbol;
  final String popSymbol;
  final String pushSymbol;
  final bool lambdaInput;
  final bool lambdaPop;
  final bool lambdaPush;
}

class _GraphNodeWidget extends StatelessWidget {
  const _GraphNodeWidget({
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
        ? theme.colorScheme.secondary
        : theme.colorScheme.primary;
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface,
        border: Border.all(color: borderColor, width: 3),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isAccepting)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
              ),
            ),
          Text(label.isEmpty ? 'q' : label, style: theme.textTheme.titleMedium),
          if (isInitial)
            Positioned(
              left: -24,
              child: Icon(Icons.play_arrow, color: borderColor),
            ),
        ],
      ),
    );
  }
}

class _GraphEdgePainter extends CustomPainter {
  _GraphEdgePainter({
    required this.edges,
    required this.nodes,
    required this.highlight,
    required this.theme,
  });

  final List<GraphViewCanvasEdge> edges;
  final List<GraphViewCanvasNode> nodes;
  final SimulationHighlight highlight;
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
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    for (final edge in edges) {
      final from = _nodeById(edge.fromStateId);
      final to = _nodeById(edge.toStateId);
      if (from == null || to == null) {
        continue;
      }

      final isHighlighted = highlight.transitionIds.contains(edge.id);
      final color = isHighlighted
          ? theme.colorScheme.secondary
          : theme.colorScheme.onSurfaceVariant;

      paint
        ..color = color
        ..strokeWidth = isHighlighted ? 3 : 2;

      final start = Offset(from.x + 40, from.y + 40);
      final end = Offset(to.x + 40, to.y + 40);
      final controlPoint =
          edge.controlPointX != null && edge.controlPointY != null
          ? Offset(edge.controlPointX!, edge.controlPointY!)
          : Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 - 60);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);

      canvas.drawPath(path, paint);

      final arrowSize = 10.0;
      final metric = path.computeMetrics().first;
      final tangent = metric.getTangentForOffset(metric.length);
      if (tangent != null) {
        final arrowPosition = tangent.position;
        final angle = tangent.vector.direction;
        final arrowPath = Path()
          ..moveTo(arrowPosition.dx, arrowPosition.dy)
          ..relativeLineTo(
            -arrowSize * math.cos(angle - math.pi / 6),
            -arrowSize * math.sin(angle - math.pi / 6),
          )
          ..moveTo(arrowPosition.dx, arrowPosition.dy)
          ..relativeLineTo(
            -arrowSize * math.cos(angle + math.pi / 6),
            -arrowSize * math.sin(angle + math.pi / 6),
          );
        canvas.drawPath(arrowPath, paint);
      }

      final label = edge.label;
      textPainter.text = TextSpan(
        text: label.isEmpty
            ? '${edge.readSymbol ?? ''}/${edge.popSymbol ?? ''};${edge.pushSymbol ?? ''}'
            : label,
        style: TextStyle(color: color, fontSize: 14),
      );
      textPainter.layout();
      final offset =
          controlPoint -
          Offset(textPainter.width / 2, textPainter.height / 2 + 4);
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphEdgePainter oldDelegate) {
    return !listEquals(oldDelegate.edges, edges) ||
        !listEquals(oldDelegate.nodes, nodes) ||
        oldDelegate.highlight != highlight ||
        oldDelegate.theme != theme;
  }
}
