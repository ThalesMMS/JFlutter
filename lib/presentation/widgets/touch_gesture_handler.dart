import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../core/models/transition.dart';
import 'transition_geometry.dart';

/// Comprehensive touch gesture handler for mobile automaton editing
class TouchGestureHandler<T extends Transition> extends StatefulWidget {
  final List<automaton_state.State> states;
  final List<T> transitions;
  final automaton_state.State? selectedState;
  final ValueChanged<automaton_state.State?> onStateSelected;
  final ValueChanged<automaton_state.State> onStateMoved;
  final ValueChanged<Offset> onStateAdded;
  final void Function(automaton_state.State from, automaton_state.State to)
      onTransitionAdded;
  final ValueChanged<automaton_state.State> onStateEdited;
  final ValueChanged<automaton_state.State> onStateDeleted;
  final ValueChanged<T> onTransitionDeleted;
  final ValueChanged<T> onTransitionEdited;
  final Widget child;
  final double stateRadius;
  final double selfLoopBaseRadius;
  final double selfLoopSpacing;
  final bool isAddingTransition;
  final ValueChanged<automaton_state.State?>? onTransitionOriginChanged;
  final ValueChanged<Offset?>? onTransitionPreviewChanged;

  const TouchGestureHandler({
    super.key,
    required this.states,
    required this.transitions,
    required this.selectedState,
    required this.onStateSelected,
    required this.onStateMoved,
    required this.onStateAdded,
    required this.onTransitionAdded,
    required this.onStateEdited,
    required this.onStateDeleted,
    required this.onTransitionDeleted,
    required this.onTransitionEdited,
    required this.child,
    this.stateRadius = 30,
    this.selfLoopBaseRadius = 40,
    this.selfLoopSpacing = 12,
    this.isAddingTransition = false,
    this.onTransitionOriginChanged,
    this.onTransitionPreviewChanged,
  });

  @override
  State<TouchGestureHandler<T>> createState() => _TouchGestureHandlerState<T>();
}

class _TouchGestureHandlerState<T extends Transition>
    extends State<TouchGestureHandler<T>> {
  // Gesture state
  automaton_state.State? _draggedState;
  Offset? _dragStartPosition;
  Offset? _dragStartCanvasPosition;
  bool _isDragging = false;
  bool _isZooming = false;
  double _scale = 1.0;
  double _initialScale = 1.0;
  Offset _panOffset = Offset.zero;
  Offset _initialPanOffset = Offset.zero;
  bool _isPanning = false;
  bool _isTransitionDrag = false;
  automaton_state.State? _transitionDragStart;
  Offset? _transitionDragPosition;

  // Long press handling
  Timer? _longPressTimer;
  Offset? _longPressPosition;

  // Double tap handling
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  
  // Context menu
  bool _showContextMenu = false;
  Offset? _contextMenuPosition;
  automaton_state.State? _contextMenuState;
  T? _contextMenuTransition;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  /// Converts a local position (affected by current pan/zoom) to canvas coordinates
  Offset _toCanvasCoordinates(Offset position) {
    final translated = position - _panOffset;
    if (_scale == 0) {
      return translated;
    }
    return Offset(translated.dx / _scale, translated.dy / _scale);
  }

  /// Handles tap gestures
  void _handleTap(TapDownDetails details) {
    if (_showContextMenu) {
      _closeContextMenu();
      return;
    }

    final position = details.localPosition;
    final canvasPosition = _toCanvasCoordinates(position);
    final now = DateTime.now();

    if (widget.isAddingTransition) {
      return;
    }

    // Check for double tap
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 300 &&
        _lastTapPosition != null &&
        (position - _lastTapPosition!).distance < 20) {
      _handleDoubleTap(position, canvasPosition);
      return;
    }

    _lastTapTime = now;
    _lastTapPosition = position;

    // Find state or transition at tap position
    final state = _findStateAt(canvasPosition);
    final transition = _findTransitionAt(canvasPosition);

    if (state != null) {
      widget.onStateSelected(state);
    } else if (transition != null) {
      // Select transition (could be extended for transition editing)
      widget.onStateSelected(null);
    } else {
      // Tap on empty space
      widget.onStateSelected(null);
    }
  }

  /// Handles double tap for editing
  void _handleDoubleTap(Offset localPosition, Offset canvasPosition) {
    final state = _findStateAt(canvasPosition);
    if (state != null) {
      widget.onStateEdited(state);
      return;
    }

    final transition = _findTransitionAt(canvasPosition);
    if (transition != null) {
      widget.onTransitionEdited(transition);
    }
  }

  /// Handles long press for context menu
  void _handleLongPressStart(LongPressStartDetails details) {
    if (widget.isAddingTransition) {
      return;
    }
    _longPressPosition = details.localPosition;
    _longPressTimer = Timer(const Duration(milliseconds: 500), () {
      _showContextMenuAt(details.localPosition);
    });
  }

  /// Handles long press end
  void _handleLongPressEnd(LongPressEndDetails details) {
    _longPressTimer?.cancel();
  }

  /// Shows context menu at position
  void _showContextMenuAt(Offset position) {
    final canvasPosition = _toCanvasCoordinates(position);
    final state = _findStateAt(canvasPosition);
    final transition = _findTransitionAt(canvasPosition);

    setState(() {
      _showContextMenu = true;
      _contextMenuPosition = position;
      _contextMenuState = state;
      _contextMenuTransition = transition;
    });
  }

  /// Handles scale start for zooming and panning
  void _handleScaleStart(ScaleStartDetails details) {
    _closeContextMenu();

    _isZooming = true;

    if (widget.isAddingTransition && details.pointerCount == 1) {
      final canvasPoint = _toCanvasCoordinates(details.localFocalPoint);
      final state = _findStateAt(canvasPoint);
      if (state != null) {
        _isTransitionDrag = true;
        _transitionDragStart = state;
        _transitionDragPosition = canvasPoint;
        widget.onTransitionOriginChanged?.call(state);
        widget.onTransitionPreviewChanged?.call(canvasPoint);
        return;
      }
    }

    // Check if this is a single finger drag (pan)
    if (details.pointerCount == 1) {
      final canvasPoint = _toCanvasCoordinates(details.localFocalPoint);
      final state = _findStateAt(canvasPoint);
      if (state != null) {
        _draggedState = state;
        _dragStartPosition = details.localFocalPoint;
        _dragStartCanvasPosition = Offset(state.position.x, state.position.y);
        _isDragging = true;
        _isPanning = false;
      }
      if (!_isDragging) {
        _isPanning = true;
        _draggedState = null;
        _dragStartPosition = details.localFocalPoint;
      }
    } else {
      _initialScale = _scale;
      _initialPanOffset = _panOffset;
      _isPanning = false;
    }
  }

  /// Handles scale update for zooming and panning
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_isTransitionDrag && details.pointerCount == 1) {
      final canvasPoint = _toCanvasCoordinates(details.localFocalPoint);
      _transitionDragPosition = canvasPoint;
      widget.onTransitionPreviewChanged?.call(canvasPoint);
      return;
    }

    if (_isDragging && _draggedState != null && details.pointerCount == 1) {
      // Handle single finger drag
      final deltaLocal = details.localFocalPoint - _dragStartPosition!;
      final deltaCanvas = Offset(deltaLocal.dx / _scale, deltaLocal.dy / _scale);
      final startCanvas = _dragStartCanvasPosition!;
      final newPosition = startCanvas + deltaCanvas;
      widget.onStateMoved(_draggedState!.copyWith(
        position: Vector2(newPosition.dx, newPosition.dy),
      ));
    } else if (_isPanning && details.pointerCount == 1) {
      setState(() {
        _panOffset += details.focalPointDelta;
      });
    } else if (details.pointerCount > 1) {
      // Handle multi-finger zoom and pan
      setState(() {
        _scale = math.max(0.5, math.min(3.0, _initialScale * details.scale));
        _panOffset = _initialPanOffset + details.focalPointDelta;
      });
    }
  }

  /// Handles scale end
  void _handleScaleEnd(ScaleEndDetails details) {
    if (_isTransitionDrag) {
      final startState = _transitionDragStart;
      final endState = _transitionDragPosition != null
          ? _findStateAt(_transitionDragPosition!)
          : null;
      if (startState != null && endState != null) {
        widget.onTransitionAdded(startState, endState);
      }
      widget.onTransitionPreviewChanged?.call(null);
      widget.onTransitionOriginChanged?.call(null);
    }

    _isZooming = false;
    _isDragging = false;
    _isPanning = false;
    _draggedState = null;
    _dragStartPosition = null;
    _dragStartCanvasPosition = null;
    _isTransitionDrag = false;
    _transitionDragStart = null;
    _transitionDragPosition = null;
  }

  /// Finds state at given position
  automaton_state.State? _findStateAt(Offset position) {
    for (final state in widget.states.reversed) {
      if (_isPointInState(position, state)) {
        return state;
      }
    }
    return null;
  }

  /// Finds transition at given position
  T? _findTransitionAt(Offset position) {
    for (final transition in widget.transitions) {
      if (_isPointOnTransition(position, transition)) {
        return transition;
      }
    }
    return null;
  }

  /// Checks if point is inside a state
  bool _isPointInState(Offset point, automaton_state.State state) {
    final statePosition = Offset(state.position.x, state.position.y);
    final distance = (point - statePosition).distance;
    return distance <= widget.stateRadius;
  }

  /// Checks if point is on a transition line
  bool _isPointOnTransition(Offset point, T transition) {
    if (transition.fromState == transition.toState) {
      return _isPointOnSelfLoop(point, transition);
    }

    final curve = TransitionCurve.compute(
      widget.transitions,
      transition,
      stateRadius: widget.stateRadius,
      curvatureStrength: 45,
      labelOffset: 16,
    );

    return _distanceToQuadratic(point, curve.start, curve.control, curve.end) <= 18;
  }

  bool _isPointOnSelfLoop(Offset point, T transition) {
    final center = Offset(
      transition.fromState.position.x,
      transition.fromState.position.y,
    );
    final loops = widget.transitions
        .where((t) => t.fromState.id == transition.fromState.id && t.fromState == t.toState)
        .toList();
    final index = loops.indexOf(transition);
    final radius = widget.selfLoopBaseRadius + index * widget.selfLoopSpacing;
    final loopCenter = Offset(center.dx, center.dy - radius);

    final distance = (point - loopCenter).distance;
    if ((distance - radius).abs() > 18) {
      return false;
    }

    final angle = math.atan2(point.dy - loopCenter.dy, point.dx - loopCenter.dx);
    final normalized = _normalizeAngle(angle);
    final start = _normalizeAngle(1.1 * math.pi);
    final end = start + 1.6 * math.pi;
    final adjusted = normalized < start ? normalized + 2 * math.pi : normalized;
    return adjusted >= start && adjusted <= end;
  }

  double _distanceToQuadratic(
    Offset point,
    Offset start,
    Offset control,
    Offset end,
  ) {
    double minDistance = double.infinity;
    const segments = 24;
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final sample = TransitionCurve.pointAt(start, control, end, t);
      final distance = (point - sample).distance;
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance;
  }

  double _normalizeAngle(double angle) {
    var a = angle;
    while (a < 0) {
      a += 2 * math.pi;
    }
    while (a >= 2 * math.pi) {
      a -= 2 * math.pi;
    }
    return a;
  }

  /// Closes context menu
  void _closeContextMenu() {
    setState(() {
      _showContextMenu = false;
      _contextMenuPosition = null;
      _contextMenuState = null;
      _contextMenuTransition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main gesture detector
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handleTap,
          onLongPressStart: _handleLongPressStart,
          onLongPressEnd: _handleLongPressEnd,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          child: Transform(
            transform: Matrix4.identity()
              ..translate(_panOffset.dx, _panOffset.dy)
              ..scale(_scale),
            child: widget.child,
          ),
        ),
        
        // Context menu
        if (_showContextMenu && _contextMenuPosition != null)
          Positioned(
            left: _contextMenuPosition!.dx,
            top: _contextMenuPosition!.dy,
            child: _buildContextMenu(context),
          ),
      ],
    );
  }

  /// Builds context menu
  Widget _buildContextMenu(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_contextMenuState != null) ...[
              _buildContextMenuItem(
                context,
                icon: Icons.edit,
                label: 'Edit State',
                onTap: () {
                  widget.onStateEdited(_contextMenuState!);
                  _closeContextMenu();
                },
              ),
              _buildContextMenuItem(
                context,
                icon: Icons.delete,
                label: 'Delete State',
                onTap: () {
                  widget.onStateDeleted(_contextMenuState!);
                  _closeContextMenu();
                },
              ),
            ],
            if (_contextMenuTransition != null) ...[
              _buildContextMenuItem(
                context,
                icon: Icons.edit,
                label: 'Edit Transition',
                onTap: () {
                  widget.onTransitionEdited(_contextMenuTransition!);
                  _closeContextMenu();
                },
              ),
              _buildContextMenuItem(
                context,
                icon: Icons.delete,
                label: 'Delete Transition',
                onTap: () {
                  widget.onTransitionDeleted(_contextMenuTransition!);
                  _closeContextMenu();
                },
              ),
            ],
            if (_contextMenuState == null && _contextMenuTransition == null) ...[
              _buildContextMenuItem(
                context,
                icon: Icons.add_circle,
                label: 'Add State',
                onTap: () {
                  final canvasPoint = _toCanvasCoordinates(_contextMenuPosition!);
                  widget.onStateAdded(canvasPoint);
                  _closeContextMenu();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds context menu item
  Widget _buildContextMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}