import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/pda.dart';
import '../../core/models/pda_transition.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/fl_nodes/fl_nodes_pda_canvas_controller.dart';
import '../../features/canvas/fl_nodes/fl_nodes_highlight_channel.dart';
import '../../features/canvas/fl_nodes/link_overlay_utils.dart';
import '../../features/canvas/fl_nodes/node_editor_event_shims.dart';
import 'canvas_actions_sheet.dart';
import 'transition_editors/pda_transition_editor.dart';
import '../providers/pda_editor_provider.dart';

/// Pushdown automaton canvas backed by the native fl_nodes editor.
class PDACanvasNative extends ConsumerStatefulWidget {
  const PDACanvasNative({
    super.key,
    required this.onPdaModified,
    this.controller,
  });

  final ValueChanged<PDA> onPdaModified;
  final FlNodesPdaCanvasController? controller;

  @override
  ConsumerState<PDACanvasNative> createState() => _PDACanvasNativeState();
}

class _PDACanvasNativeState extends ConsumerState<PDACanvasNative> {
  late final FlNodesPdaCanvasController _canvasController;
  late final bool _ownsController;
  FlNodeEditorStyle? _lastEditorStyle;
  ProviderSubscription<PDAEditorState>? _subscription;
  PDA? _lastDeliveredPda;
  StreamSubscription<NodeEditorEvent>? _eventSubscription;
  VoidCallback? _controllerListener;
  VoidCallback? _viewportOffsetListener;
  VoidCallback? _viewportZoomListener;
  String? _selectedLinkId;
  late final ValueNotifier<_PdaOverlayState?> _transitionOverlayNotifier;
  final GlobalKey _canvasKey = GlobalKey();
  SimulationHighlightService? _highlightService;
  SimulationHighlightChannel? _previousHighlightChannel;
  FlNodesSimulationHighlightChannel? _highlightChannel;
  final Set<int> _activePointerIds = <int>{};
  int _doubleTapPointerCount = 1;
  int _currentTapMaxPointerCount = 0;

  @override
  void initState() {
    super.initState();
    _transitionOverlayNotifier = ValueNotifier<_PdaOverlayState?>(null);
    final externalController = widget.controller;
    if (externalController != null) {
      _canvasController = externalController;
      _ownsController = false;
    } else {
      _canvasController = FlNodesPdaCanvasController(
        editorNotifier: ref.read(pdaEditorProvider.notifier),
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
    final initialState = ref.read(pdaEditorProvider);
    _canvasController.synchronize(initialState.pda);
    if (initialState.pda?.states.isNotEmpty ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _canvasController.fitToContent();
      });
    }
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
          final hadNodes = _canvasController.nodes.isNotEmpty;
          _canvasController.synchronize(pda);
          final hasNodesNow = _canvasController.nodes.isNotEmpty;
          if (!hadNodes &&
              hasNodesNow &&
              (pda?.states.isNotEmpty ?? false)) {
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
      },
    );
    _initialiseOverlayListeners();
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
      canvasKey: _canvasKey,
      worldOffset: anchor,
    );
    if (position == null) {
      if (_transitionOverlayNotifier.value != null) {
        _transitionOverlayNotifier.value = null;
      }
      return;
    }

    final editorState = ref.read(pdaEditorProvider);
    final transition = editorState.pda?.pdaTransitions
        .firstWhereOrNull((candidate) => candidate.id == linkId);
    final edge = _canvasController.edgeById(linkId);

    final initialRead = transition?.inputSymbol ?? edge?.readSymbol ?? '';
    final initialPop = transition?.popSymbol ?? edge?.popSymbol ?? '';
    final initialPush = transition?.pushSymbol ?? edge?.pushSymbol ?? '';
    final lambdaInput = transition?.isLambdaInput ?? edge?.isLambdaInput ?? false;
    final lambdaPop = transition?.isLambdaPop ?? edge?.isLambdaPop ?? false;
    final lambdaPush = transition?.isLambdaPush ?? edge?.isLambdaPush ?? false;

    final nextState = _PdaOverlayState(
      linkId: linkId,
      position: position,
      readSymbol: initialRead,
      popSymbol: initialPop,
      pushSymbol: initialPush,
      isLambdaInput: lambdaInput,
      isLambdaPop: lambdaPop,
      isLambdaPush: lambdaPush,
    );
    if (_transitionOverlayNotifier.value != nextState) {
      _transitionOverlayNotifier.value = nextState;
    }
  }

  void _handleCanvasTap(Offset globalPosition) {
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
    final canAddState =
        worldPosition != null && _isCanvasSpaceFree(worldPosition);

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
    final renderObject = _canvasKey.currentContext?.findRenderObject();
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
                child: PdaTransitionEditor(
                  key: ValueKey(
                    'pda-transition-editor-${state.linkId}-${state.readSymbol}-${state.popSymbol}-${state.pushSymbol}-${state.isLambdaInput}-${state.isLambdaPop}-${state.isLambdaPush}',
                  ),
                  initialRead: state.readSymbol,
                  initialPop: state.popSymbol,
                  initialPush: state.pushSymbol,
                  isLambdaInput: state.isLambdaInput,
                  isLambdaPop: state.isLambdaPop,
                  isLambdaPush: state.isLambdaPush,
                  onSubmit: ({
                    required String readSymbol,
                    required String popSymbol,
                    required String pushSymbol,
                    required bool lambdaInput,
                    required bool lambdaPop,
                    required bool lambdaPush,
                  }) {
                    ref.read(pdaEditorProvider.notifier).upsertTransition(
                          id: state.linkId,
                          readSymbol: readSymbol,
                          popSymbol: popSymbol,
                          pushSymbol: pushSymbol,
                          isLambdaInput: lambdaInput,
                          isLambdaPop: lambdaPop,
                          isLambdaPush: lambdaPush,
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
          child: KeyedSubtree(
            key: _canvasKey,
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
                  headerBuilder: (context, node, style, onToggleCollapse) {
                    final state = statesById[node.id];
                    final label = state?.label ?? node.id;
                    final isInitial = initialStateId == node.id;
                    final isAccepting = acceptingIds.contains(node.id);
                    final isNondeterministic =
                        nondeterministicStateIds.contains(node.id);
                    final notifier = ref.read(pdaEditorProvider.notifier);

                    return ValueListenableBuilder<SimulationHighlight>(
                      valueListenable: _canvasController.highlightNotifier,
                      builder: (context, highlight, _) {
                        final isHighlighted =
                            highlight.stateIds.contains(node.id);

                        final colors = _resolveHeaderColors(
                          theme,
                          isHighlighted: isHighlighted,
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
                          initialToggleKey:
                              Key('pda-node-${node.id}-initial-toggle'),
                          acceptingToggleKey:
                              Key('pda-node-${node.id}-accepting-toggle'),
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

class _PdaOverlayState {
  const _PdaOverlayState({
    required this.linkId,
    required this.position,
    required this.readSymbol,
    required this.popSymbol,
    required this.pushSymbol,
    required this.isLambdaInput,
    required this.isLambdaPop,
    required this.isLambdaPush,
  });

  final String linkId;
  final Offset position;
  final String readSymbol;
  final String popSymbol;
  final String pushSymbol;
  final bool isLambdaInput;
  final bool isLambdaPop;
  final bool isLambdaPush;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _PdaOverlayState &&
        other.linkId == linkId &&
        other.position == position &&
        other.readSymbol == readSymbol &&
        other.popSymbol == popSymbol &&
        other.pushSymbol == pushSymbol &&
        other.isLambdaInput == isLambdaInput &&
        other.isLambdaPop == isLambdaPop &&
        other.isLambdaPush == isLambdaPush;
  }

  @override
  int get hashCode => Object.hash(
        linkId,
        position,
        readSymbol,
        popSymbol,
        pushSymbol,
        isLambdaInput,
        isLambdaPop,
        isLambdaPush,
      );
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
    required this.onToggleInitial,
    required this.onToggleAccepting,
    required this.initialToggleKey,
    required this.acceptingToggleKey,
  });

  final String label;
  final bool isInitial;
  final bool isAccepting;
  final bool isNondeterministic;
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
          if (isNondeterministic) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: colors.foreground,
            ),
          ],
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
    background: colorScheme.primaryContainer,
    foreground: colorScheme.onPrimaryContainer,
  );
}
