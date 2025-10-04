import 'dart:async';
import 'dart:math' as math;

import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes/src/constants.dart';
import 'package:fl_nodes/src/core/localization/delegate.dart';
import 'package:fl_nodes/src/core/models/events.dart';
import 'package:fl_nodes/src/core/utils/rendering/renderbox.dart';
import 'package:fl_nodes/src/widgets/context_menu.dart';
import 'package:fl_nodes/src/widgets/improved_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

import '../../core/constants/automaton_canvas.dart';

typedef _TempLink = ({String nodeId, String portId});

enum _AutomatonNodeMenuAction {
  rename,
  delete,
  toggleInitial,
  toggleAccepting,
}

class AutomatonStateNode extends StatefulWidget {
  const AutomatonStateNode({
    super.key,
    required this.controller,
    required this.node,
    required this.label,
    required this.isInitial,
    required this.isAccepting,
    required this.isHighlighted,
    required this.isCurrent,
    required this.isVisited,
    required this.isNondeterministic,
    required this.onToggleInitial,
    required this.onToggleAccepting,
    required this.onRename,
    required this.onDelete,
    required this.initialToggleKey,
    required this.acceptingToggleKey,
    this.isTransitionToolEnabled = true,
  });

  final FlNodeEditorController controller;
  final NodeInstance node;
  final String label;
  final bool isInitial;
  final bool isAccepting;
  final bool isHighlighted;
  final bool isCurrent;
  final bool isVisited;
  final bool isNondeterministic;
  final VoidCallback onToggleInitial;
  final VoidCallback onToggleAccepting;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;
  final Key initialToggleKey;
  final Key acceptingToggleKey;
  final bool isTransitionToolEnabled;

  static const double nodeDiameter = kAutomatonStateDiameter;

  @override
  State<AutomatonStateNode> createState() => _AutomatonStateNodeState();
}

class _AutomatonStateNodeState extends State<AutomatonStateNode> {
  bool _isLinking = false;
  _TempLink? _tempLink;
  Offset? _lastPanPosition;
  Timer? _edgeTimer;
  StreamSubscription<NodeEditorEvent>? _eventSubscription;

  double get _viewportZoom => widget.controller.viewportZoom;
  Offset get _viewportOffset => widget.controller.viewportOffset;

  bool get _canLinkFromCenter =>
      widget.isTransitionToolEnabled &&
      widget.node.ports.isNotEmpty &&
      !widget.node.state.isCollapsed;

  _TempLink? get _centerLocatorOrNull {
    if (widget.node.ports.isEmpty) {
      return null;
    }
    final portId = widget.node.ports.values.first.prototype.idName;
    return (nodeId: widget.node.id, portId: portId);
  }

  Offset _resolveLocalCenter() {
    final renderObject = widget.node.key.currentContext?.findRenderObject();
    Size? size;
    if (renderObject is RenderBox && renderObject.hasSize) {
      size = renderObject.size;
    }
    final width = size?.width ?? AutomatonStateNode.nodeDiameter;
    final height = size?.height ?? AutomatonStateNode.nodeDiameter;
    return Offset(width / 2, height / 2);
  }

  bool _isWithinCircle(Offset globalPosition) {
    final renderObject = widget.node.key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }
    final localPosition = renderObject.globalToLocal(globalPosition);
    final size = renderObject.size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    return (localPosition - center).distance <= radius;
  }

  bool _shouldBeginTransition(Offset globalPosition) {
    if (!_canLinkFromCenter) {
      return false;
    }
    return _isWithinCircle(globalPosition);
  }

  @override
  void initState() {
    super.initState();
    _eventSubscription =
        widget.controller.eventBus.events.listen(_handleControllerEvent);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updatePortOffsets();
    });
  }

  @override
  void didUpdateWidget(covariant AutomatonStateNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.key != widget.node.key ||
        oldWidget.node.offset != widget.node.offset ||
        oldWidget.node.state.isCollapsed != widget.node.state.isCollapsed ||
        oldWidget.isAccepting != widget.isAccepting) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updatePortOffsets();
      });
    }
  }

  @override
  void dispose() {
    _edgeTimer?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _handleControllerEvent(NodeEditorEvent event) {
    if (!mounted || event.isHandled) return;

    if (event is DragSelectionEvent) {
      if (!event.nodeIds.contains(widget.node.id)) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updatePortOffsets();
        }
      });
    } else if (event is NodeSelectionEvent) {
      if (event.nodeIds.contains(widget.node.id)) {
        setState(() {});
      }
    } else if (event is NodeDeselectionEvent) {
      if (event.nodeIds.contains(widget.node.id)) {
        setState(() {});
      }
    } else if (event is CollapseEvent) {
      if (!event.nodeIds.contains(widget.node.id)) return;
      setState(() {});
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updatePortOffsets();
        }
      });
    }
  }

  void _startEdgeTimer(Offset position) {
    const edgeThreshold = 50.0;
    final moveAmount = 5.0 / widget.controller.viewportZoom;
    final editorBounds = getEditorBoundsInScreen(kNodeEditorWidgetKey);
    if (editorBounds == null) return;

    _edgeTimer?.cancel();

    _edgeTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      double dx = 0;
      double dy = 0;
      final rect = editorBounds;

      if (position.dx < rect.left + edgeThreshold) {
        dx = -moveAmount;
      } else if (position.dx > rect.right - edgeThreshold) {
        dx = moveAmount;
      }
      if (position.dy < rect.top + edgeThreshold) {
        dy = -moveAmount;
      } else if (position.dy > rect.bottom - edgeThreshold) {
        dy = moveAmount;
      }

      if (dx != 0 || dy != 0) {
        widget.controller.dragSelection(Offset(dx, dy));
        widget.controller.setViewportOffset(
          Offset(-dx / _viewportZoom, -dy / _viewportZoom),
          animate: false,
        );
      }
    });
  }

  void _resetEdgeTimer() {
    _edgeTimer?.cancel();
  }

  _TempLink? _isNearPort(Offset position) {
    final worldPosition =
        screenToWorld(position, _viewportOffset, _viewportZoom);
    if (worldPosition == null) return null;

    final near = Rect.fromCenter(
      center: worldPosition,
      width: kSpatialHashingCellSize,
      height: kSpatialHashingCellSize,
    );

    final nearNodeIds = widget.controller.spatialHashGrid.queryArea(near);
    final screenRadius = math.max(16.0, 24.0 / _viewportZoom);
    final worldRadius = screenRadius / _viewportZoom;

    for (final nodeId in nearNodeIds) {
      final node = widget.controller.nodes[nodeId]!;
      for (final port in node.ports.values) {
        final absolutePortPosition = node.offset + port.offset;
        if ((worldPosition - absolutePortPosition).distance < worldRadius) {
          return (nodeId: node.id, portId: port.prototype.idName);
        }
      }
    }

    return null;
  }

  void _onTmpLinkStart(_TempLink locator) {
    _tempLink = locator;
    _isLinking = true;
  }

  void _onTmpLinkUpdate(Offset position) {
    final worldPosition =
        screenToWorld(position, _viewportOffset, _viewportZoom);
    if (worldPosition == null) {
      return;
    }

    final node = widget.controller.nodes[_tempLink!.nodeId]!;
    final port = node.ports[_tempLink!.portId]!;
    final absolutePortOffset = node.offset + port.offset;

    widget.controller.drawTempLink(
      port.style.linkStyleBuilder(LinkState()),
      absolutePortOffset,
      worldPosition,
    );
  }

  void _onTmpLinkCancel() {
    _isLinking = false;
    _tempLink = null;
    widget.controller.clearTempLink();
  }

  void _onTmpLinkEnd(_TempLink locator) {
    widget.controller.addLink(
      _tempLink!.nodeId,
      _tempLink!.portId,
      locator.nodeId,
      locator.portId,
    );
    _isLinking = false;
    _tempLink = null;
    widget.controller.clearTempLink();
  }

  void _finishLinkGesture(Offset position) {
    if (!_isLinking || _tempLink == null) {
      return;
    }
    final locator = _isNearPort(position);
    if (locator != null) {
      _onTmpLinkEnd(locator);
    } else {
      createAndShowContextMenu(
        context,
        entries: _createSubmenuEntries(position),
        position: position,
        onDismiss: (_) => _onTmpLinkCancel(),
      );
      _isLinking = false;
    }
  }

  void _updatePortOffsets() {
    final centerOffset = _resolveLocalCenter();
    for (final port in widget.node.ports.values) {
      port.offset = centerOffset;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _wrapWithControls(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNodeBody(context),
          if (_shouldShowInlineActions(context))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StateToggleButton(
                    buttonKey: widget.initialToggleKey,
                    tooltip: widget.isInitial
                        ? 'Unset initial state'
                        : 'Set as initial state',
                    icon: Icons.play_circle_outline,
                    activeIcon: Icons.play_circle,
                    isActive: widget.isInitial,
                    onPressed: widget.onToggleInitial,
                  ),
                  const SizedBox(width: 8),
                  _StateToggleButton(
                    buttonKey: widget.acceptingToggleKey,
                    tooltip: widget.isAccepting
                        ? 'Unset accepting state'
                        : 'Set as accepting state',
                    icon: Icons.check_circle_outline,
                    activeIcon: Icons.check_circle,
                    isActive: widget.isAccepting,
                    onPressed: widget.onToggleAccepting,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNodeBody(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _resolveNodeColors(theme);
    final textStyle = theme.textTheme.titleMedium?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.w600,
        );

    final arrowColor = colors.foreground.withOpacity(0.9);

    final colorScheme = theme.colorScheme;
    final borderColor = () {
      if (widget.node.state.isSelected) {
        return colorScheme.primary;
      }
      if (widget.isHighlighted || widget.isCurrent) {
        return colorScheme.primary;
      }
      if (widget.isVisited) {
        return colorScheme.secondary;
      }
      if (widget.isNondeterministic) {
        return colorScheme.tertiary;
      }
      return colorScheme.outlineVariant;
    }();

    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: AutomatonStateNode.nodeDiameter,
      height: AutomatonStateNode.nodeDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.background,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: widget.isHighlighted || widget.isCurrent
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : const [],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            widget.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),
      ),
    );

    Widget decoratedCircle = circle;
    if (widget.isAccepting) {
      decoratedCircle = CustomPaint(
        painter: _AcceptingRingPainter(
          color: colors.foreground.withOpacity(0.9),
        ),
        child: circle,
      );
    }

    final menuButton = Builder(
      builder: (buttonContext) {
        return _FloatingCircleButton(
          icon: Icons.more_vert,
          onPressed: () => _showNodeMenu(
            triggerContext: buttonContext,
            useBottomSheet: false,
          ),
          tooltip: 'State actions',
        );
      },
    );

    final collapseButton = _FloatingCircleButton(
      icon: widget.node.state.isCollapsed
          ? Icons.expand_more
          : Icons.expand_less,
      onPressed: () {
        widget.controller.toggleCollapseSelectedNodes(
          !widget.node.state.isCollapsed,
        );
      },
      tooltip: widget.node.state.isCollapsed
          ? 'Expand state'
          : 'Collapse state',
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: widget.node.key,
          child: Tooltip(
            message: widget.label,
            child: decoratedCircle,
          ),
        ),
        if (widget.isTransitionToolEnabled)
          _buildLinkAnchorIndicator(colors),
        if (widget.isInitial)
          Positioned(
            left: -(AutomatonStateNode.nodeDiameter * 0.35),
            top: AutomatonStateNode.nodeDiameter / 2 - 12,
            child: Icon(
              Icons.play_arrow,
              color: arrowColor,
              size: 24,
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: collapseButton,
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: menuButton,
        ),
      ],
    );
  }

  Widget _buildLinkAnchorIndicator(_NodeColors colors) {
    final targetOpacity = widget.isTransitionToolEnabled
        ? (_isLinking ? 1.0 : 0.6)
        : 0.0;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: targetOpacity,
          duration: const Duration(milliseconds: 180),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.foreground.withOpacity(0.75),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowInlineActions(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final platform = theme.platform;
    final isDesktopPlatform = platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.windows;
    return isDesktopPlatform || mediaQuery.size.shortestSide >= 600;
  }

  Widget _wrapWithControls(Widget child) {
    return defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS
        ? GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (!widget.node.state.isSelected) {
                widget.controller.selectNodesById({widget.node.id});
              }
            },
            onLongPressStart: (details) async {
              final position = details.globalPosition;
              final locator =
                  _canLinkFromCenter && _isWithinCircle(position)
                      ? _centerLocatorOrNull
                      : null;

              if (!widget.node.state.isSelected) {
                widget.controller.selectNodesById({widget.node.id});
              }

              if (locator != null) {
                createAndShowContextMenu(
                  context,
                  entries: _portContextMenuEntries(position, locator: locator),
                  position: position,
                );
              } else {
                Feedback.forLongPress(context);
                await _showNodeMenu(
                  useBottomSheet: true,
                );
              }
            },
            onPanDown: (details) {
              _lastPanPosition = details.globalPosition;
            },
            onPanStart: (details) {
              if (_isLinking) {
                return;
              }

              final position = details.globalPosition;
              _isLinking = false;
              _tempLink = null;

              if (_shouldBeginTransition(position)) {
                final locator = _centerLocatorOrNull;
                if (locator != null) {
                  _onTmpLinkStart(locator);
                  _onTmpLinkUpdate(position);
                }
              } else if (!widget.node.state.isSelected) {
                widget.controller.selectNodesById({widget.node.id});
              }
            },
            onPanUpdate: (details) {
              _lastPanPosition = details.globalPosition;
              if (_isLinking) {
                _onTmpLinkUpdate(details.globalPosition);
              } else {
                _startEdgeTimer(details.globalPosition);
                widget.controller.dragSelection(details.delta);
              }
            },
            onPanEnd: (details) {
              if (_isLinking) {
                final lastPosition = _lastPanPosition ?? Offset.zero;
                _finishLinkGesture(lastPosition);
              } else {
                _resetEdgeTimer();
              }
            },
            child: child,
          )
        : ImprovedListener(
            behavior: HitTestBehavior.translucent,
            onPointerPressed: (event) async {
              if (_isLinking) {
                return;
              }

              _isLinking = false;
              _tempLink = null;

              final shouldLink = _shouldBeginTransition(event.position);
              final locator = shouldLink ? _centerLocatorOrNull : null;

              if (event.buttons == kSecondaryMouseButton) {
                if (!widget.node.state.isSelected) {
                  widget.controller.selectNodesById({widget.node.id});
                }

                if (locator != null) {
                  createAndShowContextMenu(
                    context,
                    entries: _portContextMenuEntries(
                      event.position,
                      locator: locator,
                    ),
                    position: event.position,
                  );
                } else if (!isContextMenuVisible) {
                  await _showNodeMenu(
                    pointerPosition: event.position,
                    useBottomSheet: false,
                  );
                }
              } else if (event.buttons == kPrimaryMouseButton) {
                if (locator != null && !_isLinking && _tempLink == null) {
                  _onTmpLinkStart(locator);
                  _onTmpLinkUpdate(event.position);
                } else if (!widget.node.state.isSelected) {
                  widget.controller.selectNodesById(
                    {widget.node.id},
                    holdSelection: HardwareKeyboard.instance.isControlPressed,
                  );
                }
              }
            },
            onPointerMoved: (event) async {
              if (_isLinking) {
                _onTmpLinkUpdate(event.position);
              } else if (event.buttons == kPrimaryMouseButton) {
                _startEdgeTimer(event.position);
                widget.controller.dragSelection(event.delta);
              }
            },
            onPointerReleased: (event) async {
              if (_isLinking) {
                _finishLinkGesture(event.position);
              } else {
                _resetEdgeTimer();
              }
            },
            child: child,
          );
  }

  List<ContextMenuEntry> _portContextMenuEntries(
    Offset position, {
    required _TempLink locator,
  }) {
    final strings = FlNodeEditorLocalizations.of(context);

    return [
      MenuHeader(text: strings.portMenuLabel),
      MenuItem(
        label: strings.cutLinksAction,
        icon: Icons.remove_circle,
        onSelected: () {
          widget.controller.breakPortLinks(locator.nodeId, locator.portId);
        },
      ),
    ];
  }

  List<ContextMenuEntry> _createSubmenuEntries(Offset position) {
    final fromLink = _tempLink != null;
    final List<MapEntry<String, NodePrototype>> compatiblePrototypes = [];

    if (fromLink) {
      final startPort =
          widget.controller.nodes[_tempLink!.nodeId]!.ports[_tempLink!.portId]!;
      widget.controller.nodePrototypes.forEach((key, value) {
        if (value.ports.any(startPort.prototype.compatibleWith)) {
          compatiblePrototypes.add(MapEntry(key, value));
        }
      });
    } else {
      widget.controller.nodePrototypes.forEach(
            (key, value) => compatiblePrototypes.add(MapEntry(key, value)),
          );
    }

    final worldPosition =
        screenToWorld(position, _viewportOffset, _viewportZoom) ?? Offset.zero;

    return compatiblePrototypes.map((entry) {
      return MenuItem(
        label: entry.value.displayName(context),
        icon: Icons.widgets,
        onSelected: () {
          widget.controller.addNode(
            entry.key,
            offset: worldPosition,
          );
          if (fromLink) {
            final addedNode = widget.controller.nodes.values.last;
            final startPort = widget
                .controller.nodes[_tempLink!.nodeId]!.ports[_tempLink!.portId]!;
            widget.controller.addLink(
              _tempLink!.nodeId,
              _tempLink!.portId,
              addedNode.id,
              addedNode.ports.values
                  .map((port) => port.prototype)
                  .firstWhere(startPort.prototype.compatibleWith)
                  .idName,
            );
            _isLinking = false;
            _tempLink = null;
          }
        },
      );
    }).toList();
  }

  Future<void> _showNodeMenu({
    BuildContext? triggerContext,
    Offset? pointerPosition,
    required bool useBottomSheet,
  }) async {
    _AutomatonNodeMenuAction? action;
    if (useBottomSheet) {
      action = await _showBottomSheetMenu(context);
    } else if (triggerContext != null) {
      final buttonBox = triggerContext.findRenderObject() as RenderBox?;
      final overlay = Overlay.of(triggerContext)?.context.findRenderObject()
          as RenderBox?;
      if (buttonBox != null && overlay != null) {
        final position = RelativeRect.fromRect(
          Rect.fromPoints(
            buttonBox.localToGlobal(Offset.zero, ancestor: overlay),
            buttonBox.localToGlobal(
              buttonBox.size.bottomRight(Offset.zero),
              ancestor: overlay,
            ),
          ),
          Offset.zero & overlay.size,
        );
        action = await _showPopupMenu(position);
      } else if (pointerPosition != null) {
        action = await _showPointerMenu(pointerPosition);
      }
    } else if (pointerPosition != null) {
      action = await _showPointerMenu(pointerPosition);
    }

    switch (action) {
      case _AutomatonNodeMenuAction.rename:
        await _handleRename(context);
        break;
      case _AutomatonNodeMenuAction.delete:
        widget.onDelete();
        break;
      case _AutomatonNodeMenuAction.toggleInitial:
        widget.onToggleInitial();
        break;
      case _AutomatonNodeMenuAction.toggleAccepting:
        widget.onToggleAccepting();
        break;
      case null:
        break;
    }
  }

  Future<_AutomatonNodeMenuAction?> _showBottomSheetMenu(
    BuildContext context,
  ) async {
    bool localInitial = widget.isInitial;
    bool localAccepting = widget.isAccepting;

    final action = await showModalBottomSheet<_AutomatonNodeMenuAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Rename'),
                    onTap: () {
                      Navigator.of(sheetContext)
                          .pop(_AutomatonNodeMenuAction.rename);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Delete'),
                    textColor: Theme.of(context).colorScheme.error,
                    iconColor: Theme.of(context).colorScheme.error,
                    onTap: () {
                      Navigator.of(sheetContext)
                          .pop(_AutomatonNodeMenuAction.delete);
                    },
                  ),
                  const Divider(),
                  SwitchListTile.adaptive(
                    value: localInitial,
                    secondary: const Icon(Icons.play_circle_outline),
                    title: const Text('Initial state'),
                    onChanged: (value) {
                      if (value == localInitial) {
                        return;
                      }
                      setSheetState(() {
                        localInitial = value;
                      });
                      widget.onToggleInitial();
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: localAccepting,
                    secondary: const Icon(Icons.check_circle_outline),
                    title: const Text('Accepting state'),
                    onChanged: (value) {
                      if (value == localAccepting) {
                        return;
                      }
                      setSheetState(() {
                        localAccepting = value;
                      });
                      widget.onToggleAccepting();
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    return action;
  }

  Future<_AutomatonNodeMenuAction?> _showPointerMenu(Offset position) {
    final overlay = Overlay.of(context)?.context.findRenderObject() as RenderBox?;
    if (overlay == null) {
      return Future.value(null);
    }
    final relative = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      overlay.size.width - position.dx,
      overlay.size.height - position.dy,
    );
    return _showPopupMenu(relative);
  }

  Future<_AutomatonNodeMenuAction?> _showPopupMenu(RelativeRect position) {
    final theme = Theme.of(context);
    return showMenu<_AutomatonNodeMenuAction>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<_AutomatonNodeMenuAction>(
          value: _AutomatonNodeMenuAction.rename,
          child: Text('Rename'),
        ),
        PopupMenuItem<_AutomatonNodeMenuAction>(
          value: _AutomatonNodeMenuAction.delete,
          child: Text(
            'Delete',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem<_AutomatonNodeMenuAction>(
          value: _AutomatonNodeMenuAction.toggleInitial,
          checked: widget.isInitial,
          child: const Text('Initial state'),
        ),
        CheckedPopupMenuItem<_AutomatonNodeMenuAction>(
          value: _AutomatonNodeMenuAction.toggleAccepting,
          checked: widget.isAccepting,
          child: const Text('Accepting state'),
        ),
      ],
    );
  }

  Future<void> _handleRename(BuildContext context) async {
    final newLabel = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _RenameStateDialog(initialLabel: widget.label);
      },
    );

    final trimmedLabel = newLabel?.trim();
    if (trimmedLabel != null && trimmedLabel.isNotEmpty) {
      widget.onRename(trimmedLabel);
    }
  }

  _NodeColors _resolveNodeColors(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    if (widget.isHighlighted || widget.isCurrent) {
      return _NodeColors(
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
      );
    }
    if (widget.isVisited) {
      return _NodeColors(
        background: colorScheme.secondaryContainer,
        foreground: colorScheme.onSecondaryContainer,
      );
    }
    if (widget.isNondeterministic) {
      return _NodeColors(
        background: colorScheme.tertiaryContainer,
        foreground: colorScheme.onTertiaryContainer,
      );
    }
    return _NodeColors(
      background: colorScheme.surface,
      foreground: colorScheme.onSurface,
    );
  }
}

class _NodeColors {
  const _NodeColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class _StateToggleButton extends StatelessWidget {
  const _StateToggleButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onPressed,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        key: buttonKey,
        onPressed: onPressed,
        icon: Icon(isActive ? activeIcon : icon),
        color: iconColor,
        visualDensity: VisualDensity.compact,
        splashRadius: 18,
      ),
    );
  }
}

class _AcceptingRingPainter extends CustomPainter {
  const _AcceptingRingPainter({
    required this.color,
  });

  final Color color;
  static const double _ringPadding = 4;
  static const double _strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius + _ringPadding, paint);
  }

  @override
  bool shouldRepaint(_AcceptingRingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _FloatingCircleButton extends StatelessWidget {
  const _FloatingCircleButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.9),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _RenameStateDialog extends StatefulWidget {
  const _RenameStateDialog({
    required this.initialLabel,
  });

  final String initialLabel;

  @override
  State<_RenameStateDialog> createState() => _RenameStateDialogState();
}

class _RenameStateDialogState extends State<_RenameStateDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLabel);
    _focusNode = FocusNode();
    _isValid = _controller.text.trim().isNotEmpty;
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final isValid = _controller.text.trim().isNotEmpty;
    if (isValid != _isValid) {
      setState(() {
        _isValid = isValid;
      });
    }
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename state'),
      content: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: 'State label',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid ? _submit : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
