import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../../features/canvas/fl_nodes/fl_nodes_tm_canvas_controller.dart';
import '../providers/tm_editor_provider.dart';

class TMCanvasNative extends ConsumerStatefulWidget {
  const TMCanvasNative({
    super.key,
    required this.onTMModified,
    this.controller,
  });

  final ValueChanged<TM> onTMModified;
  final FlNodesTmCanvasController? controller;

  @override
  ConsumerState<TMCanvasNative> createState() => _TMCanvasNativeState();
}

class _TMCanvasNativeState extends ConsumerState<TMCanvasNative> {
  late final FlNodesTmCanvasController _canvasController;
  late final bool _ownsController;
  FlNodeEditorStyle? _lastEditorStyle;
  ProviderSubscription<TMEditorState>? _subscription;
  TM? _lastDeliveredTM;
  VoidCallback? _highlightListener;

  @override
  void initState() {
    super.initState();
    final externalController = widget.controller;
    if (externalController != null) {
      _canvasController = externalController;
      _ownsController = false;
    } else {
      _canvasController = FlNodesTmCanvasController(
        editorNotifier: ref.read(tmEditorProvider.notifier),
      );
      _ownsController = true;
    }
    final initialState = ref.read(tmEditorProvider);
    _canvasController.synchronize(initialState.tm);
    _lastDeliveredTM = initialState.tm;
    if (initialState.tm != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onTMModified(initialState.tm!);
        }
      });
    }
    _subscription = ref.listenManual<TMEditorState>(
      tmEditorProvider,
      (previous, next) {
        if (!mounted) return;
        final tm = next.tm;
        if (tm != null && !identical(tm, _lastDeliveredTM)) {
          _lastDeliveredTM = tm;
          widget.onTMModified(tm);
        }
        if (_shouldSynchronize(previous, next)) {
          _canvasController.synchronize(next.tm);
        }
      },
    );
    _highlightListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    _canvasController.highlightNotifier.addListener(_highlightListener!);
  }

  bool _shouldSynchronize(TMEditorState? previous, TMEditorState next) {
    if (next.tm == null) {
      return true;
    }
    if (previous == null) {
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

    return false;
  }

  @override
  void dispose() {
    _subscription?.close();
    if (_highlightListener != null) {
      _canvasController.highlightNotifier
          .removeListener(_highlightListener!);
    }
    if (_ownsController) {
      _canvasController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _applyEditorStyle(theme);

    final editorState = ref.watch(tmEditorProvider);
    final tm = editorState.tm;
    final states = editorState.states;
    final transitions = editorState.transitions;
    final hasStates = states.isNotEmpty;
    final highlight = _canvasController.highlightNotifier.value;

    final statesById = {for (final state in states) state.id: state};
    final initialStateId = tm?.initialState?.id;
    final acceptingIds = tm?.acceptingStates.map((state) => state.id).toSet() ?? {};
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
              final isHighlighted = highlight.stateIds.contains(node.id);
              final colors = _resolveHeaderColors(
                theme,
                isHighlighted: isHighlighted,
                isInitial: isInitial,
                isAccepting: isAccepting,
                isNondeterministic: isNondeterministic,
              );

              return _TMNodeHeader(
                label: label,
                isInitial: isInitial,
                isAccepting: isAccepting,
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

  static Set<String> _identifyNondeterministicStates(
    List<TMTransition> transitions,
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

class _TMNodeHeader extends StatelessWidget {
  const _TMNodeHeader({
    required this.label,
    required this.isInitial,
    required this.isAccepting,
    required this.isCollapsed,
    required this.colors,
    required this.onToggleCollapse,
  });

  final String label;
  final bool isInitial;
  final bool isAccepting;
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
              Icons.memory,
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
              'Use the toolbar to add new states and transitions.',
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
  required bool isHighlighted,
  required bool isInitial,
  required bool isAccepting,
  required bool isNondeterministic,
}) {
  final colorScheme = theme.colorScheme;
  if (isHighlighted) {
    return _HeaderColors(
      background: colorScheme.primary,
      foreground: colorScheme.onPrimary,
    );
  }
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
