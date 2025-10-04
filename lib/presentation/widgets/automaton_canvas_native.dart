import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/models/simulation_result.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/fl_nodes/fl_nodes_canvas_controller.dart';
import '../../features/canvas/fl_nodes/fl_nodes_highlight_channel.dart';
import '../../features/canvas/fl_nodes/fl_nodes_label_field_editor.dart';
import '../../features/canvas/fl_nodes/link_overlay_utils.dart';
import '../../features/canvas/fl_nodes/node_editor_event_shims.dart';
import '../providers/automaton_provider.dart';
import 'automaton_state_node.dart';
import 'canvas_actions_sheet.dart';
import 'transition_editors/transition_label_editor.dart';
import 'automaton_canvas_tool.dart';

/// Shared automaton canvas backed by the fl_nodes editor. This replaces the
/// legacy CustomPaint implementation and delegates editing to
/// [FlNodesCanvasController], keeping the Riverpod automaton state in sync with
/// the visual representation.
class AutomatonCanvas extends ConsumerStatefulWidget {
  const AutomatonCanvas({
    super.key,
    required this.automaton,
    required this.canvasKey,
    this.simulationResult,
    this.currentStepIndex,
    this.showTrace = false,
    this.controller,
    this.toolController,
    this.onDerivedStateChanged,
  });

  final FSA? automaton;
  final GlobalKey canvasKey;
  final FlNodesCanvasController? controller;
  final AutomatonCanvasToolController? toolController;

  @visibleForTesting
  final VoidCallback? onDerivedStateChanged;

  final SimulationResult? simulationResult;
  final int? currentStepIndex;
  final bool showTrace;

  @override
  ConsumerState<AutomatonCanvas> createState() => _AutomatonCanvasState();
}

class _AutomatonCanvasState extends ConsumerState<AutomatonCanvas> {
  late final FlNodesCanvasController _canvasController;
  late final bool _ownsController;
  late AutomatonCanvasToolController _toolController;
  late bool _ownsToolController;
  AutomatonCanvasTool _activeTool = AutomatonCanvasTool.selection;
  FlNodeEditorStyle? _lastEditorStyle;
  _DerivedState _derivedState = const _DerivedState.empty();
  Map<String, automaton_state.State> _statesById = const {};
  Set<String> _nondeterministicStateIds = const {};
  Set<String> _visitedStateIds = const {};
  String? _currentStateId;
  late final ValueNotifier<_TransitionOverlayState?>
      _transitionOverlayNotifier;
  StreamSubscription<NodeEditorEvent>? _eventSubscription;
  VoidCallback? _controllerListener;
  VoidCallback? _viewportOffsetListener;
  VoidCallback? _viewportZoomListener;
  String? _selectedLinkId;
  bool _isLabelSheetOpen = false;
  String? _activeLabelSheetLinkId;
  SimulationHighlightService? _highlightService;
  SimulationHighlightChannel? _previousHighlightChannel;
  FlNodesSimulationHighlightChannel? _highlightChannel;
  final Set<int> _activePointerIds = <int>{};
  int _doubleTapPointerCount = 1;
  int _currentTapMaxPointerCount = 0;
  bool _isPanningCanvas = false;
  Offset? _canvasPanStartGlobalPosition;

  bool get _isAddStateToolActive =>
      _activeTool == AutomatonCanvasTool.addState;

  @override
  void initState() {
    super.initState();
    _transitionOverlayNotifier = ValueNotifier<_TransitionOverlayState?>(null);
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
      _canvasController = externalController;
      _ownsController = false;
    } else {
      _canvasController = FlNodesCanvasController(
        automatonProvider: ref.read(automatonProvider.notifier),
      );
      _ownsController = true;
      final highlightService = ref.read(canvasHighlightServiceProvider);
      _highlightService = highlightService;
      _previousHighlightChannel = highlightService.channel;
      final highlightChannel =
          FlNodesSimulationHighlightChannel(_canvasController);
      _highlightChannel = highlightChannel;
      highlightService.channel = highlightChannel;
    }
    _canvasController.synchronize(widget.automaton);
    if (widget.automaton?.states.isNotEmpty ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _canvasController.fitToContent();
      });
    }
    _applyDerivedState(_computeDerivedState());
    _initialiseOverlayListeners();
  }

  void _handleActiveToolChanged() {
    final nextTool = _toolController.activeTool;
    if (nextTool == _activeTool) {
      return;
    }
    if (!mounted) {
      _activeTool = nextTool;
      return;
    }
    setState(() {
      _activeTool = nextTool;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyEditorStyle(Theme.of(context));
  }

  @override
  void didUpdateWidget(covariant AutomatonCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.toolController != widget.toolController) {
      _toolController.removeListener(_handleActiveToolChanged);
      if (_ownsToolController) {
        _toolController.dispose();
      }
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
    }
    final automatonChanged = !identical(oldWidget.automaton, widget.automaton);
    if (automatonChanged && _shouldSynchronize(widget.automaton)) {
      final hadNodes = _canvasController.nodes.isNotEmpty;
      _canvasController.synchronize(widget.automaton);
      final hasNodesNow = _canvasController.nodes.isNotEmpty;
      if (!hadNodes &&
          hasNodesNow &&
          (widget.automaton?.states.isNotEmpty ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _canvasController.fitToContent();
        });
      }
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
      final nextDerivedState = _computeDerivedState();
      if (!_derivedState.isEquivalentTo(nextDerivedState)) {
        setState(() {
          _applyDerivedState(nextDerivedState);
        });
      }
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
    _toolController.removeListener(_handleActiveToolChanged);
    if (_ownsToolController) {
      _toolController.dispose();
    }
    if (_ownsController) {
      final highlightService = _highlightService;
      final highlightChannel = _highlightChannel;
      if (highlightService != null && highlightChannel != null) {
        if (identical(highlightService.channel, highlightChannel)) {
          highlightService.channel = _previousHighlightChannel;
        }
        _highlightChannel = null;
        _highlightService = null;
        _previousHighlightChannel = null;
      }
      _canvasController.dispose();
    }
    _transitionOverlayNotifier.dispose();
    super.dispose();
  }

  void _initialiseOverlayListeners() {
    final controller = _canvasController.controller;
    _selectedLinkId = controller.selectedLinkIds.isNotEmpty
        ? controller.selectedLinkIds.first
        : null;
    _updateTransitionOverlay();
    _controllerListener = () {
      if (!mounted) {
        return;
      }
      final ids = controller.selectedLinkIds;
      final nextSelected = ids.length == 1 ? ids.first : null;
      final selectionChanged = nextSelected != _selectedLinkId;
      _selectedLinkId = nextSelected;
      if (selectionChanged || _selectedLinkId != null) {
        _updateTransitionOverlay();
      }
    };
    controller.addListener(_controllerListener!);
    _viewportOffsetListener = () {
      if (!mounted || _selectedLinkId == null) {
        return;
      }
      _updateTransitionOverlay();
    };
    controller.viewportOffsetNotifier.addListener(_viewportOffsetListener!);
    _viewportZoomListener = () {
      if (!mounted || _selectedLinkId == null) {
        return;
      }
      _updateTransitionOverlay();
    };
    controller.viewportZoomNotifier.addListener(_viewportZoomListener!);
    _eventSubscription = controller.eventBus.events.listen(_handleEditorEvent);
  }

  void _updateTransitionOverlay() {
    if (!mounted) {
      return;
    }

    final linkId = _selectedLinkId;
    if (linkId == null) {
      if (_transitionOverlayNotifier.value != null) {
        _transitionOverlayNotifier.value = null;
      }
      return;
    }

    final transition = widget.automaton?.fsaTransitions
        .firstWhereOrNull((candidate) => candidate.id == linkId);
    final label = transition?.label ??
        _canvasController.edgeById(linkId)?.label ??
        '';

    if (!_shouldUseInlineLabelEditor(context)) {
      _transitionOverlayNotifier.value = null;
      _scheduleLabelSheet(linkId: linkId, initialLabel: label);
      return;
    }

    final controller = _canvasController.controller;
    final anchor = resolveLinkAnchorWorld(
      controller,
      linkId,
      _canvasController.edgeById(linkId),
    );
    if (anchor == null) {
      if (_transitionOverlayNotifier.value != null) {
        _transitionOverlayNotifier.value = null;
      }
      return;
    }

    final position = projectCanvasPointToOverlay(
      controller: controller,
      canvasKey: widget.canvasKey,
      worldOffset: anchor,
    );
    if (position == null) {
      if (_transitionOverlayNotifier.value != null) {
        _transitionOverlayNotifier.value = null;
      }
      return;
    }

    final nextState = _TransitionOverlayState(
      linkId: linkId,
      label: label,
      position: position,
    );
    if (_transitionOverlayNotifier.value != nextState) {
      _transitionOverlayNotifier.value = nextState;
    }
  }

  void _handleCanvasTap(Offset globalPosition) {
    if (!_isAddStateToolActive) {
      return;
    }
    final worldPosition = _globalToWorld(globalPosition);
    if (worldPosition == null || !_isCanvasSpaceFree(worldPosition)) {
      return;
    }
    HapticFeedback.selectionClick();
    _canvasController.addStateAt(worldPosition);
  }

  Future<void> _handleCanvasLongPress(Offset globalPosition) async {
    final worldPosition = _globalToWorld(globalPosition);
    if (!mounted) {
      return;
    }
    final canAddState = _isAddStateToolActive &&
        worldPosition != null &&
        _isCanvasSpaceFree(worldPosition);

    await showCanvasContextActions(
      context: context,
      canAddState: canAddState,
      onAddState: () {
        if (worldPosition != null && canAddState) {
          _canvasController.addStateAt(worldPosition);
        }
      },
      onFitToContent: _canvasController.fitToContent,
      onResetView: _canvasController.resetView,
    );
  }

  void _handleCanvasPointerDown(PointerDownEvent event) {
    _activePointerIds.add(event.pointer);
    final activeCount = _activePointerIds.length;
    if (activeCount > _currentTapMaxPointerCount) {
      _currentTapMaxPointerCount = activeCount;
    }
  }

  void _handleCanvasPointerUp(PointerEvent event) {
    _activePointerIds.remove(event.pointer);
    if (_activePointerIds.isEmpty) {
      _doubleTapPointerCount =
          _currentTapMaxPointerCount == 0 ? 1 : _currentTapMaxPointerCount;
      _currentTapMaxPointerCount = 0;
    }
  }

  void _handleCanvasPointerCancel(PointerCancelEvent event) {
    _activePointerIds.remove(event.pointer);
    if (_activePointerIds.isEmpty) {
      _doubleTapPointerCount =
          _currentTapMaxPointerCount == 0 ? 1 : _currentTapMaxPointerCount;
      _currentTapMaxPointerCount = 0;
    }
  }

  void _handleCanvasPanStart(DragStartDetails details) {
    final worldPosition = _globalToWorld(details.globalPosition);
    if (worldPosition == null || !_isCanvasSpaceFree(worldPosition)) {
      _isPanningCanvas = false;
      _canvasPanStartGlobalPosition = null;
      return;
    }

    _isPanningCanvas = true;
    _canvasPanStartGlobalPosition = details.globalPosition;
  }

  void _handleCanvasPanUpdate(DragUpdateDetails details) {
    if (!_isPanningCanvas || _canvasPanStartGlobalPosition == null) {
      return;
    }

    final controller = _canvasController.controller;
    final zoom = controller.viewportZoom;
    final delta = details.delta;
    if (delta == Offset.zero) {
      return;
    }

    final currentOffset = controller.viewportOffset;
    controller.setViewportOffset(
      Offset(
        currentOffset.dx + (delta.dx / zoom),
        currentOffset.dy + (delta.dy / zoom),
      ),
      animate: false,
    );
    _canvasPanStartGlobalPosition = details.globalPosition;
  }

  void _handleCanvasPanEnd(DragEndDetails details) {
    _isPanningCanvas = false;
    _canvasPanStartGlobalPosition = null;
  }

  void _handleCanvasPanCancel() {
    _isPanningCanvas = false;
    _canvasPanStartGlobalPosition = null;
  }

  void _handleCanvasDoubleTap() {
    final pointerCount = _doubleTapPointerCount;
    _doubleTapPointerCount = 1;
    if (pointerCount >= 2) {
      _canvasController.fitToContent();
    } else {
      _canvasController.resetView();
    }
  }

  Offset? _globalToWorld(Offset globalPosition) {
    final renderObject = widget.canvasKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) {
      return null;
    }
    final size = renderObject.size;
    if (size.isEmpty) {
      return null;
    }

    final localPosition = renderObject.globalToLocal(globalPosition);
    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx > size.width ||
        localPosition.dy > size.height) {
      return null;
    }

    final controller = _canvasController.controller;
    final offset = controller.viewportOffset;
    final zoom = controller.viewportZoom;

    final viewport = Rect.fromLTWH(
      -size.width / 2 / zoom - offset.dx,
      -size.height / 2 / zoom - offset.dy,
      size.width / zoom,
      size.height / zoom,
    );

    final dx = viewport.left + (localPosition.dx / size.width) * viewport.width;
    final dy = viewport.top + (localPosition.dy / size.height) * viewport.height;
    if (!dx.isFinite || !dy.isFinite) {
      return null;
    }

    return Offset(dx, dy);
  }

  bool _isCanvasSpaceFree(Offset worldPosition) {
    final spatialHash = _canvasController.controller.spatialHashGrid;
    final cell = (
      x: (worldPosition.dx / spatialHash.cellSize).floor(),
      y: (worldPosition.dy / spatialHash.cellSize).floor(),
    );
    final nodes = spatialHash.grid[cell];
    if (nodes == null) {
      return true;
    }
    for (final node in nodes) {
      if (node.rect.contains(worldPosition)) {
        return false;
      }
    }
    return true;
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
    if (_derivedState.isEquivalentTo(data)) {
      return;
    }
    _derivedState = data;
    _statesById = data.statesById;
    _nondeterministicStateIds = data.nondeterministicStateIds;
    _visitedStateIds = data.visitedStates;
    _currentStateId = data.currentStateId;
    widget.onDerivedStateChanged?.call();
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
    return [
      FlOverlayData(
        left: 0,
        top: 0,
        child: AnimatedBuilder(
          animation: _transitionOverlayNotifier,
          builder: (context, _) {
            final state = _transitionOverlayNotifier.value;
            if (state == null) {
              return const SizedBox.shrink();
            }
            return Transform.translate(
              offset: state.position,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -1.0),
                child: FlNodesLabelFieldEditor(
                  key: ValueKey(
                    'transition-editor-${state.linkId}-${state.label}',
                  ),
                  initialValue: state.label,
                  onSubmit: (value) {
                    ref.read(automatonProvider.notifier).updateTransitionLabel(
                          id: state.linkId,
                          label: value,
                        );
                  },
                  onCancel: () =>
                      _canvasController.controller.clearSelection(),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  bool _shouldUseInlineLabelEditor(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      return true;
    }

    final platform = Theme.of(context).platform;
    final isDesktopPlatform = platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.windows;
    if (isDesktopPlatform) {
      return true;
    }

    return mediaQuery.size.shortestSide >= 600;
  }

  void _scheduleLabelSheet({
    required String linkId,
    required String initialLabel,
  }) {
    if (_isLabelSheetOpen && _activeLabelSheetLinkId == linkId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _selectedLinkId != linkId || _isLabelSheetOpen) {
        return;
      }

      _isLabelSheetOpen = true;
      _activeLabelSheetLinkId = linkId;

      try {
        final submittedLabel = await _showTransitionLabelSheet(
          initialLabel: initialLabel,
        );
        if (mounted && submittedLabel != null) {
          ref.read(automatonProvider.notifier).updateTransitionLabel(
                id: linkId,
                label: submittedLabel,
              );
        }
      } finally {
        if (mounted) {
          _isLabelSheetOpen = false;
          _activeLabelSheetLinkId = null;
          final hadSelection = _selectedLinkId != null;
          _canvasController.controller.clearSelection();
          if (hadSelection) {
            _selectedLinkId = null;
            _transitionOverlayNotifier.value = null;
          }
        } else {
          _isLabelSheetOpen = false;
          _activeLabelSheetLinkId = null;
        }
      }
    });
  }

  Future<String?> _showTransitionLabelSheet({
    required String initialLabel,
  }) async {
    final label = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final viewInsets = MediaQuery.of(sheetContext).viewInsets;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: viewInsets.bottom + 24,
          ),
          child: TransitionLabelEditorForm(
            initialValue: initialLabel,
            autofocus: true,
            touchOptimized: true,
            onCancel: () => Navigator.of(sheetContext).pop(),
            onSubmit: (value) => Navigator.of(sheetContext).pop(value),
          ),
        );
      },
    );

    return label;
  }

  void _handleEditorEvent(NodeEditorEvent event) {
    if (!mounted) {
      return;
    }
    final linkSelection = parseLinkSelectionEvent(event);
    if (linkSelection != null) {
      final ids = linkSelection.linkIds;
      _selectedLinkId = ids.length == 1 ? ids.first : null;
      _updateTransitionOverlay();
      return;
    }

    final linkDeselection = parseLinkDeselectionEvent(event);
    if (linkDeselection != null) {
      if (_selectedLinkId != null) {
        _selectedLinkId = null;
        _transitionOverlayNotifier.value = null;
      }
      return;
    }

    final removeLinkPayload = parseRemoveLinkEvent(event);
    if (removeLinkPayload != null) {
      if (_selectedLinkId == removeLinkPayload.link.id) {
        _selectedLinkId = null;
        _transitionOverlayNotifier.value = null;
      }
      return;
    }

    final dragSelection = parseDragSelectionEndEvent(event);
    if (dragSelection != null && _selectedLinkId != null) {
      _updateTransitionOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _applyEditorStyle(theme);

    final automaton = widget.automaton;
    final hasStates = automaton?.states.isNotEmpty ?? false;

    return Stack(
      children: [
        Positioned.fill(
          child: KeyedSubtree(
            key: widget.canvasKey,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _handleCanvasPointerDown,
              onPointerUp: _handleCanvasPointerUp,
              onPointerCancel: _handleCanvasPointerCancel,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) =>
                    _handleCanvasTap(details.globalPosition),
                onLongPressStart: (details) => unawaited(
                  _handleCanvasLongPress(details.globalPosition),
                ),
                onPanStart: _handleCanvasPanStart,
                onPanUpdate: _handleCanvasPanUpdate,
                onPanEnd: _handleCanvasPanEnd,
                onPanCancel: _handleCanvasPanCancel,
                onDoubleTapDown: (_) {
                  if (_currentTapMaxPointerCount > 0) {
                    _doubleTapPointerCount = _currentTapMaxPointerCount;
                  } else if (_activePointerIds.isNotEmpty) {
                    _doubleTapPointerCount = _activePointerIds.length;
                  } else {
                    _doubleTapPointerCount = 1;
                  }
                },
                onDoubleTap: _handleCanvasDoubleTap,
                child: FlNodeEditorWidget(
                  controller: _canvasController.controller,
                  overlay: _buildOverlay,
                  nodeBuilder: (context, node) {
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
                    final isNondeterministic =
                        _nondeterministicStateIds.contains(node.id);

                    return ValueListenableBuilder<SimulationHighlight>(
                      valueListenable: _canvasController.highlightNotifier,
                      builder: (context, highlight, _) {
                        final isHighlighted =
                            highlight.stateIds.contains(node.id);
                        return AutomatonStateNode(
                          controller: _canvasController.controller,
                          node: node,
                          label: label,
                          isInitial: isInitial,
                          isAccepting: isAccepting,
                          isHighlighted: isHighlighted,
                          isCurrent: isCurrent,
                          isVisited: isVisited,
                          isNondeterministic: isNondeterministic,
                          activeTool: _activeTool,
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
                          onRename: (newLabel) {
                            automatonNotifier.updateStateLabel(
                              id: node.id,
                              label: newLabel,
                            );
                          },
                          onDelete: () {
                            automatonNotifier.removeState(id: node.id);
                          },
                          initialToggleKey:
                              Key('automaton-node-${node.id}-initial-toggle'),
                          acceptingToggleKey:
                              Key('automaton-node-${node.id}-accepting-toggle'),
                        );
                      },
                    );
                  },
                ),
              ),
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
}

class _TransitionOverlayState {
  const _TransitionOverlayState({
    required this.linkId,
    required this.label,
    required this.position,
  });

  final String linkId;
  final String label;
  final Offset position;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _TransitionOverlayState &&
        other.linkId == linkId &&
        other.label == label &&
        other.position == position;
  }

  @override
  int get hashCode => Object.hash(linkId, label, position);
}

class _DerivedState {
  const _DerivedState({
    required this.statesById,
    required this.nondeterministicStateIds,
    required this.visitedStates,
    required this.currentStateId,
  });

  const _DerivedState.empty()
      : statesById = const <String, automaton_state.State>{},
        nondeterministicStateIds = const <String>{},
        visitedStates = const <String>{},
        currentStateId = null;

  static const SetEquality<String> _setEquality = SetEquality<String>();
  static final MapEquality<String, automaton_state.State> _mapEquality =
      MapEquality<String, automaton_state.State>();

  bool isEquivalentTo(_DerivedState other) {
    if (identical(this, other)) {
      return true;
    }

    return _mapEquality.equals(statesById, other.statesById) &&
        _setEquality.equals(nondeterministicStateIds, other.nondeterministicStateIds) &&
        _setEquality.equals(visitedStates, other.visitedStates) &&
        currentStateId == other.currentStateId;
  }

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
