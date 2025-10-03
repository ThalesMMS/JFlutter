import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes/src/core/models/events.dart'
    show
        DragSelectionEndEvent,
        LinkDeselectionEvent,
        LinkSelectionEvent,
        NodeEditorEvent,
        RemoveLinkEvent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../../features/canvas/fl_nodes/fl_nodes_tm_canvas_controller.dart';
import '../../features/canvas/fl_nodes/link_overlay_utils.dart';
import 'transition_editors/tm_transition_operations_editor.dart';
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
  StreamSubscription<NodeEditorEvent>? _eventSubscription;
  VoidCallback? _controllerListener;
  VoidCallback? _viewportOffsetListener;
  VoidCallback? _viewportZoomListener;
  String? _selectedLinkId;
  final GlobalKey _canvasKey = GlobalKey();

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
          final currentLink = _selectedLinkId;
          if (currentLink != null &&
              _canvasController.edgeById(currentLink) == null) {
            _selectedLinkId = null;
          }
        }
      },
    );
    _highlightListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    _canvasController.highlightNotifier.addListener(_highlightListener!);
    _initialiseOverlayListeners();
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
    _eventSubscription?.cancel();
    if (_controllerListener != null) {
      _canvasController.controller.removeListener(_controllerListener!);
    }
    if (_viewportOffsetListener != null) {
      _canvasController.controller.viewportOffsetNotifier
          .removeListener(_viewportOffsetListener!);
    }
    if (_viewportZoomListener != null) {
      _canvasController.controller.viewportZoomNotifier
          .removeListener(_viewportZoomListener!);
    }
    if (_ownsController) {
      _canvasController.dispose();
    }
    super.dispose();
  }

  void _initialiseOverlayListeners() {
    final controller = _canvasController.controller;
    _selectedLinkId = controller.selectedLinkIds.isNotEmpty
        ? controller.selectedLinkIds.first
        : null;
    _controllerListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    controller.addListener(_controllerListener!);
    _viewportOffsetListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    controller.viewportOffsetNotifier.addListener(_viewportOffsetListener!);
    _viewportZoomListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    controller.viewportZoomNotifier.addListener(_viewportZoomListener!);
    _eventSubscription = controller.eventBus.events.listen(_handleEditorEvent);
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
          child: KeyedSubtree(
            key: _canvasKey,
            child: FlNodeEditorWidget(
              controller: _canvasController.controller,
              overlay: _buildOverlay,
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

                final notifier = ref.read(tmEditorProvider.notifier);
                return _TMNodeHeader(
                  label: label,
                  isInitial: isInitial,
                  isAccepting: isAccepting,
                  isCollapsed: node.state.isCollapsed,
                  colors: colors,
                  onToggleCollapse: onToggleCollapse,
                  onToggleInitial: () {
                    notifier.updateStateFlags(
                      id: node.id,
                      isInitial: !isInitial,
                    );
                  },
                  onToggleAccepting: () {
                    notifier.updateStateFlags(
                      id: node.id,
                      isAccepting: !isAccepting,
                    );
                  },
                  initialToggleKey: Key('tm-node-${node.id}-initial-toggle'),
                  acceptingToggleKey: Key('tm-node-${node.id}-accepting-toggle'),
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

  List<FlOverlayData> _buildOverlay() {
    final linkId = _selectedLinkId;
    if (linkId == null) {
      return const <FlOverlayData>[];
    }

    final controller = _canvasController.controller;
    final anchor = resolveLinkAnchorWorld(
      controller,
      linkId,
      _canvasController.edgeById(linkId),
    );
    if (anchor == null) {
      return const <FlOverlayData>[];
    }

    final position = projectCanvasPointToOverlay(
      controller: controller,
      canvasKey: _canvasKey,
      worldOffset: anchor,
    );
    if (position == null) {
      return const <FlOverlayData>[];
    }

    final editorState = ref.read(tmEditorProvider);
    final transition = editorState.transitions
        .firstWhereOrNull((candidate) => candidate.id == linkId);
    final edge = _canvasController.edgeById(linkId);
    final initialRead = transition?.readSymbol ?? edge?.readSymbol ?? '';
    final initialWrite = transition?.writeSymbol ?? edge?.writeSymbol ?? '';
    final direction = transition?.direction ??
        edge?.direction ??
        TapeDirection.right;

    return [
      FlOverlayData(
        left: position.dx,
        top: position.dy,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -1.0),
          child: TmTransitionOperationsEditor(
            key: ValueKey('tm-transition-editor-$linkId-$initialRead-$initialWrite-${direction.name}'),
            initialRead: initialRead,
            initialWrite: initialWrite,
            initialDirection: direction,
            onSubmit: ({
              required String readSymbol,
              required String writeSymbol,
              required TapeDirection direction,
            }) {
              ref.read(tmEditorProvider.notifier).updateTransitionOperations(
                    id: linkId,
                    readSymbol: readSymbol,
                    writeSymbol: writeSymbol,
                    direction: direction,
                  );
            },
            onCancel: () => controller.clearSelection(),
          ),
        ),
      ),
    ];
  }

  void _handleEditorEvent(NodeEditorEvent event) {
    if (!mounted) {
      return;
    }
    if (event is LinkSelectionEvent) {
      final ids = event.linkIds;
      setState(() {
        _selectedLinkId = ids.length == 1 ? ids.first : null;
      });
    } else if (event is LinkDeselectionEvent) {
      if (_selectedLinkId != null) {
        setState(() {
          _selectedLinkId = null;
        });
      }
    } else if (event is RemoveLinkEvent) {
      if (_selectedLinkId == event.link.id) {
        setState(() {
          _selectedLinkId = null;
        });
      }
    } else if (event is DragSelectionEndEvent) {
      if (_selectedLinkId != null) {
        setState(() {});
      }
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
    required this.onToggleInitial,
    required this.onToggleAccepting,
    required this.initialToggleKey,
    required this.acceptingToggleKey,
  });

  final String label;
  final bool isInitial;
  final bool isAccepting;
  final bool isCollapsed;
  final _HeaderColors colors;
  final VoidCallback onToggleCollapse;
  final VoidCallback onToggleInitial;
  final VoidCallback onToggleAccepting;
  final Key initialToggleKey;
  final Key acceptingToggleKey;

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
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
          const SizedBox(width: 8),
          _HeaderActionButton(
            buttonKey: initialToggleKey,
            tooltip: isInitial ? 'Unset initial state' : 'Set as initial state',
            icon: Icons.play_circle_outline,
            activeIcon: Icons.play_circle,
            isActive: isInitial,
            color: colors.foreground,
            onPressed: onToggleInitial,
          ),
          const SizedBox(width: 4),
          _HeaderActionButton(
            buttonKey: acceptingToggleKey,
            tooltip:
                isAccepting ? 'Unset accepting state' : 'Set as accepting state',
            icon: Icons.check_circle_outline,
            activeIcon: Icons.check_circle,
            isActive: isAccepting,
            color: colors.foreground,
            onPressed: onToggleAccepting,
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: isCollapsed ? 'Expand state' : 'Collapse state',
            child: IconButton(
              icon: Icon(
                isCollapsed ? Icons.expand_more : Icons.expand_less,
                size: 20,
                color: colors.foreground.withOpacity(0.9),
              ),
              onPressed: onToggleCollapse,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints.tightFor(width: 32, height: 32),
              splashRadius: 18,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.color,
    required this.onPressed,
    this.buttonKey,
  });

  final String tooltip;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final Color color;
  final VoidCallback onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final resolvedIcon = Icon(
      isActive ? activeIcon : icon,
      size: 20,
      color: isActive ? color : color.withOpacity(0.6),
    );

    return Tooltip(
      message: tooltip,
      child: IconButton(
        key: buttonKey,
        icon: resolvedIcon,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        splashRadius: 18,
        visualDensity: VisualDensity.compact,
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
