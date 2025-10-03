import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/simulation_result.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../features/canvas/fl_nodes/fl_nodes_canvas_controller.dart';
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
    @Deprecated('No longer used; the canvas writes directly to AutomatonProvider.')
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
  @Deprecated('No longer used; the canvas writes directly to AutomatonProvider.')
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
    _highlightListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    _canvasController.highlightNotifier.addListener(_highlightListener!);
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
    if (automatonChanged) {
      _canvasController.synchronize(widget.automaton);
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

  @override
  void dispose() {
    if (_highlightListener != null) {
      _canvasController.highlightNotifier
          .removeListener(_highlightListener!);
    }
    if (_ownsController) {
      _canvasController.dispose();
    }
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

    if (_lastEditorStyle == null || !_editorStylesEqual(_lastEditorStyle!, desiredStyle)) {
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
      statesById.addEntries(automaton.states.map(
        (state) => MapEntry(state.id, state),
      ));
      final transitions = automaton.fsaTransitions.toList(growable: false);
      final nondeterministicTransitions =
          _identifyNondeterministicTransitions(transitions);
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
              overlay: () => const <FlOverlayData>[],
              headerBuilder: (context, node, style, onToggleCollapse) {
                final automatonState = _statesById[node.id];
                final label = automatonState?.label ?? node.id;
                final isInitial = automaton?.initialState?.id == node.id;
                final isAccepting = automaton?.acceptingStates
                        .any((candidate) => candidate.id == node.id) ??
                    false;
                final isVisited = widget.showTrace && _visitedStateIds.contains(node.id);
                final isCurrent = widget.showTrace && _currentStateId == node.id;
                final isNondeterministic =
                    _nondeterministicStateIds.contains(node.id);
                final isHighlighted = highlight.stateIds.contains(node.id);

                final colors = _resolveHeaderColors(
                  theme,
                  isHighlighted: isHighlighted,
                  isCurrent: isCurrent,
                  isVisited: isVisited,
                  isNondeterministic: isNondeterministic,
                );

                return _AutomatonNodeHeader(
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
    return _HighlightData(
      visitedStates: visited,
      currentStateId: currentState,
    );
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
  required bool isCurrent,
  required bool isVisited,
  required bool isNondeterministic,
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
