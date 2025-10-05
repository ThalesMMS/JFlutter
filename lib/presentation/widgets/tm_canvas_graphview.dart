import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';

import '../../core/models/simulation_highlight.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/graphview/graphview_canvas_models.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../features/canvas/graphview/graphview_tm_canvas_controller.dart';
import '../providers/tm_editor_provider.dart';
import 'transition_editors/tm_transition_operations_editor.dart';

class TMCanvasGraphView extends ConsumerStatefulWidget {
  const TMCanvasGraphView({
    super.key,
    required this.onTmModified,
    this.controller,
  });

  final ValueChanged<TM> onTmModified;
  final GraphViewTmCanvasController? controller;

  @override
  ConsumerState<TMCanvasGraphView> createState() => _TMCanvasGraphViewState();
}

class _TMCanvasGraphViewState extends ConsumerState<TMCanvasGraphView> {
  late GraphViewTmCanvasController _canvasController;
  late bool _ownsController;
  late SugiyamaAlgorithm _algorithm;
  ProviderSubscription<TMEditorState>? _subscription;
  TM? _lastDeliveredTm;
  SimulationHighlightService? _highlightService;
  SimulationHighlightChannel? _previousHighlightChannel;
  GraphViewSimulationHighlightChannel? _highlightChannel;

  GraphViewTmCanvasController get controller => _canvasController;

  @override
  void initState() {
    super.initState();
    final externalController = widget.controller;
    if (externalController != null) {
      _canvasController = externalController;
      _ownsController = false;
    } else {
      _canvasController = GraphViewTmCanvasController(
        editorNotifier: ref.read(tmEditorProvider.notifier),
      );
      _ownsController = true;
      final highlightService = ref.read(canvasHighlightServiceProvider);
      _highlightService = highlightService;
      _previousHighlightChannel = highlightService.channel;
      final highlightChannel = GraphViewSimulationHighlightChannel(
        _canvasController,
      );
      _highlightChannel = highlightChannel;
      highlightService.channel = highlightChannel;
    }

    _algorithm = SugiyamaAlgorithm(SugiyamaConfiguration()
      ..nodeSeparation = 160
      ..levelSeparation = 160
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM);

    final initialState = ref.read(tmEditorProvider);
    _canvasController.synchronize(initialState.tm);
    if (initialState.tm?.states.isNotEmpty ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _canvasController.fitToContent();
      });
    }

    _lastDeliveredTm = initialState.tm;
    if (initialState.tm != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onTmModified(initialState.tm!);
      });
    }

    _subscription = ref.listenManual<TMEditorState>(
      tmEditorProvider,
      (previous, next) {
        if (!mounted) return;
        final tm = next.tm;
        if (tm != null && !identical(tm, _lastDeliveredTm)) {
          _lastDeliveredTm = tm;
          widget.onTmModified(tm);
        } else if (tm == null) {
          _lastDeliveredTm = null;
        }
        if (_shouldSynchronize(previous, next)) {
          final hadNodes = _canvasController.nodes.isNotEmpty;
          _canvasController.synchronize(tm);
          if (!hadNodes && (tm?.states.isNotEmpty ?? false)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _canvasController.fitToContent();
            });
          }
        }
      },
    );
  }

  bool _shouldSynchronize(TMEditorState? previous, TMEditorState next) {
    final tm = next.tm;
    if (tm == null) {
      return true;
    }
    if (previous?.tm == null) {
      return true;
    }

    final nodeIds = {for (final node in _canvasController.nodes) node.id};
    final stateIds = {for (final state in next.states) state.id};
    if (nodeIds.length != stateIds.length || !nodeIds.containsAll(stateIds)) {
      return true;
    }

    final edgeIds = {for (final edge in _canvasController.edges) edge.id};
    final transitionIds = {for (final transition in next.transitions) transition.id};
    if (edgeIds.length != transitionIds.length ||
        !edgeIds.containsAll(transitionIds)) {
      return true;
    }

    for (final state in next.states) {
      final node = _canvasController.nodeById(state.id);
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

    for (final transition in next.transitions) {
      final edge = _canvasController.edgeById(transition.id);
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
      final read = transition.readSymbol.trim();
      final write = transition.writeSymbol.trim();
      final edgeRead = (edge.readSymbol ?? '').trim();
      final edgeWrite = (edge.writeSymbol ?? '').trim();
      if (edgeRead != read || edgeWrite != write) {
        return true;
      }
      if ((edge.direction ?? TapeDirection.right) != transition.direction) {
        return true;
      }
    }

    return false;
  }

  @override
  void dispose() {
    _subscription?.close();
    if (_ownsController) {
      _canvasController.dispose();
    }
    if (_highlightService != null) {
      _highlightService!.channel = _previousHighlightChannel;
      _highlightChannel = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildCanvas(context)),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: _buildInspector(context),
        ),
      ],
    );
  }

  Widget _buildCanvas(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onDoubleTap: () => controller.addStateAtCenter(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ValueListenableBuilder<int>(
            valueListenable: _canvasController.graphRevision,
            builder: (context, _, __) {
              final nodes =
                  _canvasController.nodes.toList(growable: false);
              final edges =
                  _canvasController.edges.toList(growable: false);
              return ValueListenableBuilder(
                valueListenable: _canvasController.highlightNotifier,
                builder: (context, highlight, __) {
                  return Stack(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final viewport = constraints.biggest;
                          if (viewport.width.isFinite && viewport.height.isFinite) {
                            _canvasController.updateViewportSize(viewport);
                          }
                          return GraphView.builder(
                            graph: _canvasController.graph,
                            controller: _canvasController.graphController,
                            algorithm: _algorithm,
                            builder: (node) {
                              final nodeId = node.key?.value?.toString();
                              if (nodeId == null) {
                                return const SizedBox.shrink();
                              }
                              final canvasNode =
                                  _canvasController.nodeById(nodeId);
                              if (canvasNode == null) {
                                return const SizedBox.shrink();
                              }
                              final isHighlighted =
                                  highlight.stateIds.contains(canvasNode.id);
                              return _GraphNodeWidget(
                                label: canvasNode.label,
                                isInitial: canvasNode.isInitial,
                                isAccepting: canvasNode.isAccepting,
                                isHighlighted: isHighlighted,
                              );
                            },
                          );
                        },
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _GraphEdgePainter(
                              edges: edges,
                              nodes: nodes,
                              highlight: highlight,
                              theme: theme,
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
      ),
    );
  }

  Widget _buildInspector(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ValueListenableBuilder<int>(
          valueListenable: _canvasController.graphRevision,
          builder: (context, _, __) {
            final nodes =
                _canvasController.nodes.toList(growable: false);
            final edges =
                _canvasController.edges.toList(growable: false);
            return ListView(
              children: [
                Row(
                  children: [
                    Text(
                      'States',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => controller.addStateAt(const Offset(0, 0)),
                      icon: const Icon(Icons.add),
                      label: const Text('Add state'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (nodes.isEmpty)
                  Text(
                    'Start by adding states to the machine.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  ...nodes.map((node) => _buildStateTile(context, node)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Transitions',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed:
                          nodes.isEmpty ? null : () => _handleCreateTransition(context, nodes),
                      icon: const Icon(Icons.add),
                      label: const Text('Add transition'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (edges.isEmpty)
                  Text(
                    'Transitions control tape operations. Add one to begin.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  ...edges.map((edge) => _buildTransitionTile(context, edge)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStateTile(BuildContext context, GraphViewCanvasNode node) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    node.label.isEmpty ? node.id : node.label,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Rename state',
                  onPressed: () => _handleRenameState(context, node),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove state',
                  onPressed: () => controller.removeState(node.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Initial'),
                  selected: node.isInitial,
                  onSelected: (value) =>
                      controller.updateStateFlags(node.id, isInitial: value),
                ),
                FilterChip(
                  label: const Text('Accepting'),
                  selected: node.isAccepting,
                  onSelected: (value) => controller.updateStateFlags(
                    node.id,
                    isAccepting: value,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRenameState(
    BuildContext context,
    GraphViewCanvasNode node,
  ) async {
    final labelController = TextEditingController(text: node.label);
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename state'),
          content: TextField(
            controller: labelController,
            decoration: const InputDecoration(labelText: 'State label'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(labelController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      controller.updateStateLabel(node.id, result);
    }
  }

  Widget _buildTransitionTile(
    BuildContext context,
    GraphViewCanvasEdge edge,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text('${edge.fromStateId} → ${edge.toStateId}'),
        subtitle: Text(edge.label),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit transition',
              onPressed: () => _handleEditTransition(context, edge),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove transition',
              onPressed: () => controller.removeTransition(edge.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEditTransition(
    BuildContext context,
    GraphViewCanvasEdge edge,
  ) async {
    final result = await showDialog<_TmTransitionResult?>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TmTransitionOperationsEditor(
              initialRead: edge.readSymbol ?? '',
              initialWrite: edge.writeSymbol ?? '',
              initialDirection: edge.direction ?? TapeDirection.right,
              onSubmit: ({
                required String readSymbol,
                required String writeSymbol,
                required TapeDirection direction,
              }) {
                Navigator.of(context).pop(
                  _TmTransitionResult(
                    fromStateId: edge.fromStateId,
                    toStateId: edge.toStateId,
                    readSymbol: readSymbol,
                    writeSymbol: writeSymbol,
                    direction: direction,
                    transitionId: edge.id,
                    controlPointX: edge.controlPointX,
                    controlPointY: edge.controlPointY,
                  ),
                );
              },
              onCancel: () => Navigator.of(context).pop(null),
            ),
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    controller.addOrUpdateTransition(
      fromStateId: result.fromStateId,
      toStateId: result.toStateId,
      readSymbol: result.readSymbol,
      writeSymbol: result.writeSymbol,
      direction: result.direction,
      transitionId: result.transitionId,
      controlPointX: result.controlPointX,
      controlPointY: result.controlPointY,
    );
  }

  Future<void> _handleCreateTransition(
    BuildContext context,
    List<GraphViewCanvasNode> nodes,
  ) async {
    if (nodes.isEmpty) {
      return;
    }

    String fromStateId = nodes.first.id;
    String toStateId = nodes.first.id;

    final result = await showDialog<_TmTransitionResult?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: fromStateId,
                            decoration: const InputDecoration(labelText: 'From'),
                            items: nodes
                                .map(
                                  (node) => DropdownMenuItem(
                                    value: node.id,
                                    child: Text(node.label.isEmpty
                                        ? node.id
                                        : node.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => fromStateId = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: toStateId,
                            decoration: const InputDecoration(labelText: 'To'),
                            items: nodes
                                .map(
                                  (node) => DropdownMenuItem(
                                    value: node.id,
                                    child: Text(node.label.isEmpty
                                        ? node.id
                                        : node.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => toStateId = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TmTransitionOperationsEditor(
                      initialRead: '',
                      initialWrite: '',
                      initialDirection: TapeDirection.right,
                      onSubmit: ({
                        required String readSymbol,
                        required String writeSymbol,
                        required TapeDirection direction,
                      }) {
                        Navigator.of(context).pop(
                          _TmTransitionResult(
                            fromStateId: fromStateId,
                            toStateId: toStateId,
                            readSymbol: readSymbol,
                            writeSymbol: writeSymbol,
                            direction: direction,
                          ),
                        );
                      },
                      onCancel: () => Navigator.of(context).pop(null),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    controller.addOrUpdateTransition(
      fromStateId: result.fromStateId,
      toStateId: result.toStateId,
      readSymbol: result.readSymbol,
      writeSymbol: result.writeSymbol,
      direction: result.direction,
    );
  }
}

class _TmTransitionResult {
  _TmTransitionResult({
    required this.fromStateId,
    required this.toStateId,
    required this.readSymbol,
    required this.writeSymbol,
    required this.direction,
    this.transitionId,
    this.controlPointX,
    this.controlPointY,
  });

  final String fromStateId;
  final String toStateId;
  final String readSymbol;
  final String writeSymbol;
  final TapeDirection direction;
  final String? transitionId;
  final double? controlPointX;
  final double? controlPointY;
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
          Text(
            label.isEmpty ? 'q' : label,
            style: theme.textTheme.titleMedium,
          ),
          if (isInitial)
            Positioned(
              left: -24,
              child: Icon(
                Icons.play_arrow,
                color: borderColor,
              ),
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
      final path = Path();
      final fromOffset = Offset(from.x, from.y);
      final toOffset = Offset(to.x, to.y);
      final control = edge.controlPointX != null && edge.controlPointY != null
          ? Offset(edge.controlPointX!, edge.controlPointY!)
          : Offset(
              (fromOffset.dx + toOffset.dx) / 2,
              (fromOffset.dy + toOffset.dy) / 2,
            );

      path.moveTo(fromOffset.dx, fromOffset.dy);
      path.quadraticBezierTo(
        control.dx,
        control.dy,
        toOffset.dx,
        toOffset.dy,
      );

      paint.color = highlight.transitionIds.contains(edge.id)
          ? theme.colorScheme.tertiary
          : theme.colorScheme.onSurfaceVariant;
      canvas.drawPath(path, paint);

      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final tangent = metric.getTangentForOffset(metric.length * 0.5);
        if (tangent == null) {
          continue;
        }
        textPainter.text = TextSpan(
          text: edge.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        );
        textPainter.layout();
        final offset = tangent.position -
            Offset(textPainter.width / 2, textPainter.height / 2);
        textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GraphEdgePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.nodes != nodes ||
        oldDelegate.highlight != highlight;
  }
}
