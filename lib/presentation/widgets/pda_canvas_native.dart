import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/pda.dart';
import '../../core/models/pda_transition.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../features/canvas/fl_nodes/fl_nodes_pda_canvas_controller.dart';
import '../providers/pda_editor_provider.dart';

/// Pushdown automaton canvas backed by the native fl_nodes editor.
class PDACanvasNative extends ConsumerStatefulWidget {
  const PDACanvasNative({
    super.key,
    required this.onPdaModified,
  });

  final ValueChanged<PDA> onPdaModified;

  @override
  ConsumerState<PDACanvasNative> createState() => _PDACanvasNativeState();
}

class _PDACanvasNativeState extends ConsumerState<PDACanvasNative> {
  late final FlNodesPdaCanvasController _canvasController;
  FlNodeEditorStyle? _lastEditorStyle;
  ProviderSubscription<PDAEditorState>? _subscription;
  PDA? _lastDeliveredPda;

  @override
  void initState() {
    super.initState();
    _canvasController = FlNodesPdaCanvasController(
      editorNotifier: ref.read(pdaEditorProvider.notifier),
    );
    final initialState = ref.read(pdaEditorProvider);
    _canvasController.synchronize(initialState.pda);
    _lastDeliveredPda = initialState.pda;
    if (initialState.pda != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && initialState.pda != null) {
          widget.onPdaModified(initialState.pda!);
        }
      });
    }
    _subscription = ref.listenManual<PDAEditorState>(
      pdaEditorProvider,
      (previous, next) {
        if (!mounted) return;
        final pda = next.pda;
        if (pda != null && !identical(pda, _lastDeliveredPda)) {
          _lastDeliveredPda = pda;
          widget.onPdaModified(pda);
        } else if (pda == null) {
          _lastDeliveredPda = null;
        }
        if (_shouldSynchronize(previous, next)) {
          _canvasController.synchronize(pda);
        }
      },
    );
  }

  bool _shouldSynchronize(PDAEditorState? previous, PDAEditorState next) {
    final pda = next.pda;
    if (pda == null) {
      return true;
    }
    if (previous?.pda == null) {
      return true;
    }

    final nodeIds = {for (final node in _canvasController.nodes) node.id};
    final stateIds = {for (final state in pda.states) state.id};
    if (nodeIds.length != stateIds.length || !nodeIds.containsAll(stateIds)) {
      return true;
    }

    final edgeIds = {for (final edge in _canvasController.edges) edge.id};
    final transitionIds = {for (final transition in pda.pdaTransitions) transition.id};
    if (edgeIds.length != transitionIds.length ||
        !edgeIds.containsAll(transitionIds)) {
      return true;
    }

    for (final state in pda.states) {
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

    for (final transition in pda.pdaTransitions) {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyEditorStyle(Theme.of(context));
  }

  @override
  void dispose() {
    _subscription?.close();
    _canvasController.dispose();
    super.dispose();
  }

  void _applyEditorStyle(ThemeData theme) {
    final controller = _canvasController.controller;
    final currentStyle = controller.style;
    final colorScheme = theme.colorScheme;
    final desiredStyle = currentStyle.copyWith(
      decoration: BoxDecoration(color: colorScheme.surface),
      gridStyle: currentStyle.gridStyle.copyWith(
        lineColor: colorScheme.outlineVariant.withOpacity(0.35),
        intersectionColor: colorScheme.outlineVariant.withOpacity(0.55),
      ),
      highlightAreaStyle: currentStyle.highlightAreaStyle.copyWith(
        color: colorScheme.primary.withOpacity(0.12),
        borderColor: colorScheme.primary.withOpacity(0.6),
      ),
    );

    if (_lastEditorStyle == null ||
        !_editorStylesEqual(_lastEditorStyle!, desiredStyle)) {
      _lastEditorStyle = desiredStyle;
      controller.setStyle(desiredStyle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _applyEditorStyle(theme);

    final editorState = ref.watch(pdaEditorProvider);
    final pda = editorState.pda;
    final states = pda?.states.toList() ?? const <automaton_state.State>[];
    final transitions = pda?.pdaTransitions.toList() ?? const <PDATransition>[];
    final hasStates = states.isNotEmpty;

    final statesById = {for (final state in states) state.id: state};
    final initialStateId = pda?.initialState?.id;
    final acceptingIds =
        pda?.acceptingStates.map((state) => state.id).toSet() ?? <String>{};
    final nondeterministicStateIds = _identifyNondeterministicStates(
      transitions,
      editorState.nondeterministicTransitionIds,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: FlNodeEditorWidget(
            controller: _canvasController.controller,
            overlay: () => const <FlOverlayData>[],
            headerBuilder: (context, node, style, onToggleCollapse) {
              final state = statesById[node.id];
              final label = state?.label ?? node.id;
              final isInitial = initialStateId == node.id;
              final isAccepting = acceptingIds.contains(node.id);
              final isNondeterministic =
                  nondeterministicStateIds.contains(node.id);

              final colors = _resolveHeaderColors(
                theme,
                isInitial: isInitial,
                isAccepting: isAccepting,
                isNondeterministic: isNondeterministic,
              );

              return _PDANodeHeader(
                label: label,
                isInitial: isInitial,
                isAccepting: isAccepting,
                isNondeterministic: isNondeterministic,
                isCollapsed: node.state.isCollapsed,
                colors: colors,
                onToggleCollapse: onToggleCollapse,
              );
            },
          ),
        ),
        if (!hasStates) const _EmptyCanvasMessage(),
      ],
    );
  }

  static Set<String> _identifyNondeterministicStates(
    List<PDATransition> transitions,
    Set<String> nondeterministicTransitionIds,
  ) {
    final stateIds = <String>{};
    for (final transition in transitions) {
      if (nondeterministicTransitionIds.contains(transition.id)) {
        stateIds.add(transition.fromState.id);
      }
    }
    return stateIds;
  }

  bool _editorStylesEqual(FlNodeEditorStyle a, FlNodeEditorStyle b) {
    final aDecoration = a.decoration;
    final bDecoration = b.decoration;
    Color? aColor;
    Color? bColor;
    if (aDecoration is BoxDecoration) {
      aColor = aDecoration.color;
    }
    if (bDecoration is BoxDecoration) {
      bColor = bDecoration.color;
    }

    return aColor == bColor &&
        a.gridStyle.lineColor == b.gridStyle.lineColor &&
        a.gridStyle.intersectionColor == b.gridStyle.intersectionColor &&
        a.highlightAreaStyle.color == b.highlightAreaStyle.color &&
        a.highlightAreaStyle.borderColor == b.highlightAreaStyle.borderColor;
  }
}

class _PDANodeHeader extends StatelessWidget {
  const _PDANodeHeader({
    required this.label,
    required this.isInitial,
    required this.isAccepting,
    required this.isNondeterministic,
    required this.isCollapsed,
    required this.colors,
    required this.onToggleCollapse,
  });

  final String label;
  final bool isInitial;
  final bool isAccepting;
  final bool isNondeterministic;
  final bool isCollapsed;
  final _HeaderColors colors;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ) ??
        TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.w600,
        );

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (isInitial)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 16,
                color: colors.foreground,
              ),
            ),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
          if (isAccepting)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.check_circle,
                size: 16,
                color: colors.foreground,
              ),
            ),
          if (isNondeterministic)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: colors.foreground,
              ),
            ),
          InkWell(
            onTap: onToggleCollapse,
            borderRadius: BorderRadius.circular(16),
            child: Icon(
              isCollapsed ? Icons.expand_more : Icons.expand_less,
              size: 18,
              color: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCanvasMessage extends StatelessWidget {
  const _EmptyCanvasMessage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return IgnorePointer(
      ignoring: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree,
              size: 64,
              color: colorScheme.outline.withOpacity(0.45),
            ),
            const SizedBox(height: 16),
            Text(
              'Empty canvas',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add states and transitions to define your pushdown automaton.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderColors {
  const _HeaderColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

_HeaderColors _resolveHeaderColors(
  ThemeData theme, {
  required bool isInitial,
  required bool isAccepting,
  required bool isNondeterministic,
}) {
  final colorScheme = theme.colorScheme;
  if (isNondeterministic) {
    return _HeaderColors(
      background: colorScheme.errorContainer,
      foreground: colorScheme.onErrorContainer,
    );
  }
  if (isAccepting) {
    return _HeaderColors(
      background: colorScheme.secondaryContainer,
      foreground: colorScheme.onSecondaryContainer,
    );
  }
  if (isInitial) {
    return _HeaderColors(
      background: colorScheme.primaryContainer,
      foreground: colorScheme.onPrimaryContainer,
    );
  }
  return _HeaderColors(
    background: colorScheme.surfaceVariant,
    foreground: colorScheme.onSurfaceVariant,
  );
}
