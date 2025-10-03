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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/models/simulation_result.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../features/canvas/fl_nodes/fl_nodes_canvas_controller.dart';
import '../../features/canvas/fl_nodes/fl_nodes_label_field_editor.dart';
import '../../features/canvas/fl_nodes/link_overlay_utils.dart';
import '../providers/automaton_provider.dart';

/// Shared automaton canvas backed by the fl_nodes editor. This replaces the
/// legacy CustomPaint implementation and delegates editing to
/// [FlNodesCanvasController], keeping the Riverpod automaton state in sync with
/// the visual representation.
class AutomatonCanvas extends ConsumerStatefulWidget {
  const AutomatonCanvas({
    super.key,
    required this.automaton,
    required this.canvasKey,
    @Deprecated(
      'No longer used; the canvas writes directly to AutomatonProvider.',
    )
    ValueChanged<FSA>? onAutomatonChanged,
    this.simulationResult,
    this.currentStepIndex,
    this.showTrace = false,
    this.controller,
  }) : _deprecatedOnAutomatonChanged = onAutomatonChanged;

  final FSA? automaton;
  final GlobalKey canvasKey;
  final FlNodesCanvasController? controller;

  /// Legacy callback kept for compatibility with pre-fl_nodes canvases. All
  /// mutations now happen directly through [AutomatonProvider].
  // ignore: unused_field
  @Deprecated(
    'No longer used; the canvas writes directly to AutomatonProvider.',
  )
  final ValueChanged<FSA>? _deprecatedOnAutomatonChanged;

  final SimulationResult? simulationResult;
  final int? currentStepIndex;
  final bool showTrace;

  @override
  ConsumerState<AutomatonCanvas> createState() => _AutomatonCanvasState();
}

class _AutomatonCanvasState extends ConsumerState<AutomatonCanvas> {
  late final FlNodesCanvasController _canvasController;
  late final bool _ownsController;
  FlNodeEditorStyle? _lastEditorStyle;
  Map<String, automaton_state.State> _statesById = const {};
  Set<String> _nondeterministicStateIds = const {};
  Set<String> _visitedStateIds = const {};
  String? _currentStateId;
  VoidCallback? _highlightListener;
  StreamSubscription<NodeEditorEvent>? _eventSubscription;
  VoidCallback? _controllerListener;
  VoidCallback? _viewportOffsetListener;
  VoidCallback? _viewportZoomListener;
  String? _selectedLinkId;
  SimulationHighlight? _lastHighlight;

  @override
  void initState() {
    super.initState();
    final externalController = widget.controller;
    if (externalController != null) {
      _canvasController = externalController;
      _ownsController = false;
    } else {
      _canvasController = FlNodesCanvasController(
        automatonProvider: ref.read(automatonProvider.notifier),
      );
      _ownsController = true;
    }
    _canvasController.synchronize(widget.automaton);
    _applyDerivedState(_computeDerivedState());
    _lastHighlight = _canvasController.highlightNotifier.value;
    _highlightListener = () {
      if (!mounted) {
        return;
      }
      final highlight = _canvasController.highlightNotifier.value;
      final previous = _lastHighlight;
      if (previous != null && _highlightsEqual(previous, highlight)) {
        return;
      }
      _lastHighlight = highlight;
      setState(() {});
    };
    _canvasController.highlightNotifier.addListener(_highlightListener!);
    _initialiseOverlayListeners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyEditorStyle(Theme.of(context));
  }

  @override
  void didUpdateWidget(covariant AutomatonCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final automatonChanged = !identical(oldWidget.automaton, widget.automaton);
    if (automatonChanged && _shouldSynchronize(widget.automaton)) {
      _canvasController.synchronize(widget.automaton);
      final currentLink = _selectedLinkId;
      if (currentLink != null &&
          _canvasController.edgeById(currentLink) == null) {
        _selectedLinkId = null;
      }
    }

    if (automatonChanged ||
        oldWidget.simulationResult != widget.simulationResult ||
        oldWidget.currentStepIndex != widget.currentStepIndex ||
        oldWidget.showTrace != widget.showTrace) {
      setState(() {
        _applyDerivedState(_computeDerivedState());
      });
    }
  }

  bool _shouldSynchronize(FSA? automaton) {
    if (automaton == null) {
      return true;
    }

    final stateIds = {for (final state in automaton.states) state.id};
    final nodeIds = {for (final node in _canvasController.nodes) node.id};
    if (stateIds.length != nodeIds.length || !nodeIds.containsAll(stateIds)) {
      return true;
    }

    for (final state in automaton.states) {
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

    final transitionIds = {
      for (final transition in automaton.fsaTransitions) transition.id
    };
    final edgeIds = {for (final edge in _canvasController.edges) edge.id};
    if (transitionIds.length != edgeIds.length ||
        !edgeIds.containsAll(transitionIds)) {
      return true;
    }

    const symbolEquality = SetEquality<String>();
    for (final transition in automaton.fsaTransitions) {
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
      final edgeLambda = edge.lambdaSymbol?.trim();
      final transitionLambda = transition.lambdaSymbol?.trim();
      if (edgeLambda != transitionLambda) {
        return true;
      }
      final edgeSymbols = edge.symbols
          .map((symbol) => symbol.trim())
          .where((symbol) => symbol.isNotEmpty)
          .toSet();
      final transitionSymbols = transition.inputSymbols
          .map((symbol) => symbol.trim())
          .where((symbol) => symbol.isNotEmpty)
          .toSet();
      if (!symbolEquality.equals(edgeSymbols, transitionSymbols)) {
        return true;
      }
    }

    return false;
  }

  @override
  void dispose() {
    if (_highlightListener != null) {
      _canvasController.highlightNotifier.removeListener(_highlightListener!);
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

  void _applyDerivedState(_DerivedState data) {
    _statesById = data.statesById;
    _nondeterministicStateIds = data.nondeterministicStateIds;
    _visitedStateIds = data.visitedStates;
    _currentStateId = data.currentStateId;
  }

  _DerivedState _computeDerivedState() {
    final automaton = widget.automaton;
    final statesById = <String, automaton_state.State>{};
    var nondeterministicStateIds = <String>{};

    if (automaton != null) {
      statesById.addEntries(
        automaton.states.map((state) => MapEntry(state.id, state)),
      );
      final transitions = automaton.fsaTransitions.toList(growable: false);
      final nondeterministicTransitions = _identifyNondeterministicTransitions(
        transitions,
      );
      nondeterministicStateIds = _identifyNondeterministicStates(
        transitions,
        nondeterministicTransitions,
      );
    }

    final highlights = _computeHighlights(
      widget.simulationResult,
      widget.currentStepIndex,
      widget.showTrace,
    );

    return _DerivedState(
      statesById: statesById,
      nondeterministicStateIds: nondeterministicStateIds,
      visitedStates: highlights.visitedStates,
      currentStateId: highlights.currentStateId,
    );
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
      canvasKey: widget.canvasKey,
      worldOffset: anchor,
    );
    if (position == null) {
      return const <FlOverlayData>[];
    }

    final transition = widget.automaton?.fsaTransitions
        .firstWhereOrNull((candidate) => candidate.id == linkId);
    final label = transition?.label ??
        _canvasController.edgeById(linkId)?.label ??
        '';

    return [
      FlOverlayData(
        left: position.dx,
        top: position.dy,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -1.0),
          child: FlNodesLabelFieldEditor(
            key: ValueKey('transition-editor-$linkId-$label'),
            initialValue: label,
            onSubmit: (value) {
              ref.read(automatonProvider.notifier).updateTransitionLabel(
                    id: linkId,
                    label: value,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _applyEditorStyle(theme);

    final automaton = widget.automaton;
    final hasStates = automaton?.states.isNotEmpty ?? false;
    final highlight = _canvasController.highlightNotifier.value;

    return Stack(
      children: [
        Positioned.fill(
          child: KeyedSubtree(
            key: widget.canvasKey,
            child: FlNodeEditorWidget(
              controller: _canvasController.controller,
              overlay: _buildOverlay,
              headerBuilder: (context, node, style, onToggleCollapse) {
                final automatonNotifier =
                    ref.read(automatonProvider.notifier);
                final automatonState = _statesById[node.id];
                final label = automatonState?.label ?? node.id;
                final isInitial = automaton?.initialState?.id == node.id;
                final isAccepting =
                    automaton?.acceptingStates.any(
                      (candidate) => candidate.id == node.id,
                    ) ??
                    false;
                final isVisited =
                    widget.showTrace && _visitedStateIds.contains(node.id);
                final isCurrent =
                    widget.showTrace && _currentStateId == node.id;
                final isNondeterministic = _nondeterministicStateIds.contains(
                  node.id,
                );
                final isHighlighted = highlight.stateIds.contains(node.id);

                final colors = _resolveHeaderColors(
                  theme,
                  isHighlighted: isHighlighted,
                  isCurrent: isCurrent,
                  isVisited: isVisited,
                  isNondeterministic: isNondeterministic,
                  isInitial: isInitial,
                  isAccepting: isAccepting,
                );

                return _AutomatonNodeHeader(
                  label: label,
                  isInitial: isInitial,
                  isAccepting: isAccepting,
                  isCollapsed: node.state.isCollapsed,
                  colors: colors,
                  onToggleCollapse: onToggleCollapse,
                  onToggleInitial: () {
                    automatonNotifier.updateStateFlags(
                      id: node.id,
                      isInitial: !isInitial,
                    );
                  },
                  onToggleAccepting: () {
                    automatonNotifier.updateStateFlags(
                      id: node.id,
                      isAccepting: !isAccepting,
                    );
                  },
                  initialToggleKey:
                      Key('automaton-node-${node.id}-initial-toggle'),
                  acceptingToggleKey:
                      Key('automaton-node-${node.id}-accepting-toggle'),
                );
              },
            ),
          ),
        ),
        if (!hasStates) const _EmptyCanvasMessage(),
      ],
    );
  }

  static _HighlightData _computeHighlights(
    SimulationResult? result,
    int? currentStepIndex,
    bool showTrace,
  ) {
    if (!showTrace || result == null || result.steps.isEmpty) {
      return const _HighlightData.empty();
    }

    final maxIndex = result.steps.length - 1;
    final resolvedIndex = (currentStepIndex ?? maxIndex).clamp(0, maxIndex);
    final visited = <String>{};

    for (var index = 0; index <= resolvedIndex; index++) {
      final step = result.steps[index];
      visited.add(step.currentState);
    }

    final currentState = result.steps[resolvedIndex].currentState;
    return _HighlightData(visitedStates: visited, currentStateId: currentState);
  }

  static Set<String> _identifyNondeterministicTransitions(
    List<FSATransition> transitions,
  ) {
    final nondeterministicIds = <String>{};
    final outgoingByState = <String, Map<String, List<FSATransition>>>{};

    for (final transition in transitions) {
      if (transition.inputSymbols.length > 1) {
        nondeterministicIds.add(transition.id);
      }

      final symbols = transition.isEpsilonTransition
          ? <String>{transition.lambdaSymbol ?? 'ε'}
          : transition.inputSymbols.isEmpty
          ? {transition.label}
          : transition.inputSymbols;

      final symbolBuckets = outgoingByState.putIfAbsent(
        transition.fromState.id,
        () => <String, List<FSATransition>>{},
      );

      for (final rawSymbol in symbols) {
        final symbol = rawSymbol.isEmpty ? 'ε' : rawSymbol;
        final transitionsForSymbol = symbolBuckets.putIfAbsent(
          symbol,
          () => <FSATransition>[],
        );
        transitionsForSymbol.add(transition);
      }
    }

    for (final symbolBuckets in outgoingByState.values) {
      for (final transitionsForSymbol in symbolBuckets.values) {
        if (transitionsForSymbol.length > 1) {
          nondeterministicIds.addAll(
            transitionsForSymbol.map((transition) => transition.id),
          );
        }
      }
    }

    return nondeterministicIds;
  }

  static Set<String> _identifyNondeterministicStates(
    List<FSATransition> transitions,
    Set<String> nondeterministicTransitionIds,
  ) {
    final stateIds = <String>{};
    for (final transition in transitions) {
      if (nondeterministicTransitionIds.contains(transition.id) ||
          transition.isEpsilonTransition) {
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

  bool _highlightsEqual(SimulationHighlight a, SimulationHighlight b) {
    return setEquals(a.stateIds, b.stateIds) &&
        setEquals(a.transitionIds, b.transitionIds);
  }
}

class _DerivedState {
  const _DerivedState({
    required this.statesById,
    required this.nondeterministicStateIds,
    required this.visitedStates,
    required this.currentStateId,
  });

  final Map<String, automaton_state.State> statesById;
  final Set<String> nondeterministicStateIds;
  final Set<String> visitedStates;
  final String? currentStateId;
}

class _HighlightData {
  const _HighlightData({
    required this.visitedStates,
    required this.currentStateId,
  });

  const _HighlightData.empty()
    : visitedStates = const <String>{},
      currentStateId = null;

  final Set<String> visitedStates;
  final String? currentStateId;
}

class _HeaderColors {
  const _HeaderColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

_HeaderColors _resolveHeaderColors(
  ThemeData theme, {
  required bool isHighlighted,
  required bool isCurrent,
  required bool isVisited,
  required bool isNondeterministic,
  required bool isInitial,
  required bool isAccepting,
}) {
  final colorScheme = theme.colorScheme;
  if (isHighlighted) {
    return _HeaderColors(
      background: colorScheme.primary,
      foreground: colorScheme.onPrimary,
    );
  }
  if (isCurrent) {
    return _HeaderColors(
      background: colorScheme.primary,
      foreground: colorScheme.onPrimary,
    );
  }
  if (isVisited) {
    return _HeaderColors(
      background: colorScheme.secondaryContainer,
      foreground: colorScheme.onSecondaryContainer,
    );
  }
  if (isNondeterministic) {
    return _HeaderColors(
      background: colorScheme.tertiaryContainer,
      foreground: colorScheme.onTertiaryContainer,
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

class _AutomatonNodeHeader extends StatelessWidget {
  const _AutomatonNodeHeader({
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
    final textStyle =
        Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ) ??
        TextStyle(color: colors.foreground, fontWeight: FontWeight.w600);

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
              Icons.account_tree_outlined,
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
              'Use the toolbar to clear or add new states.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
