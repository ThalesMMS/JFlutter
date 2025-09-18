import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../core/models/transition.dart';

/// Comprehensive touch gesture handler for mobile automaton editing
class TouchGestureHandler extends StatefulWidget {
  final List<automaton_state.State> states;
  final List<Transition> transitions;
  final automaton_state.State? selectedState;
  final ValueChanged<automaton_state.State?> onStateSelected;
  final ValueChanged<automaton_state.State> onStateMoved;
  final ValueChanged<Offset> onStateAdded;
  final ValueChanged<Transition> onTransitionAdded;
  final ValueChanged<automaton_state.State> onStateEdited;
  final ValueChanged<automaton_state.State> onStateDeleted;
  final ValueChanged<Transition> onTransitionDeleted;
  final Widget child;

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
    required this.child,
  });

  @override
  State<TouchGestureHandler> createState() => _TouchGestureHandlerState();
}

class _TouchGestureHandlerState extends State<TouchGestureHandler> {
  // Gesture state
  automaton_state.State? _draggedState;
  Offset? _dragStartPosition;
  bool _isDragging = false;
  bool _isZooming = false;
  double _scale = 1.0;
  Offset _panOffset = Offset.zero;
  
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
  Transition? _contextMenuTransition;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  /// Handles tap gestures
  void _handleTap(TapDownDetails details) {
    final position = details.localPosition;
    final now = DateTime.now();
    
    // Check for double tap
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!).inMilliseconds < 300 &&
        _lastTapPosition != null &&
        (position - _lastTapPosition!).distance < 20) {
      _handleDoubleTap(position);
      return;
    }
    
    _lastTapTime = now;
    _lastTapPosition = position;
    
    // Find state or transition at tap position
    final state = _findStateAt(position);
    final transition = _findTransitionAt(position);
    
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
  void _handleDoubleTap(Offset position) {
    final state = _findStateAt(position);
    if (state != null) {
      widget.onStateEdited(state);
    }
  }

  /// Handles long press for context menu
  void _handleLongPressStart(LongPressStartDetails details) {
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
    final state = _findStateAt(position);
    final transition = _findTransitionAt(position);
    
    setState(() {
      _showContextMenu = true;
      _contextMenuPosition = position;
      _contextMenuState = state;
      _contextMenuTransition = transition;
    });
  }


  /// Handles scale start for zooming and panning
  void _handleScaleStart(ScaleStartDetails details) {
    _isZooming = true;
    
    // Check if this is a single finger drag (pan)
    if (details.pointerCount == 1) {
      final state = _findStateAt(details.localFocalPoint);
      if (state != null) {
        _draggedState = state;
        _dragStartPosition = details.localFocalPoint;
        _isDragging = true;
      }
    }
  }

  /// Handles scale update for zooming and panning
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_isDragging && _draggedState != null && details.pointerCount == 1) {
      // Handle single finger drag
      final newPosition = _dragStartPosition! + details.focalPointDelta;
      widget.onStateMoved(_draggedState!.copyWith(
        position: Vector2(newPosition.dx, newPosition.dy),
      ));
    } else if (details.pointerCount > 1) {
      // Handle multi-finger zoom and pan
      setState(() {
        _scale = math.max(0.5, math.min(3.0, _scale * details.scale));
        _panOffset += details.focalPointDelta;
      });
    }
  }

  /// Handles scale end
  void _handleScaleEnd(ScaleEndDetails details) {
    _isZooming = false;
    _isDragging = false;
    _draggedState = null;
    _dragStartPosition = null;
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
  Transition? _findTransitionAt(Offset position) {
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
    return distance <= 30; // State radius
  }

  /// Checks if point is on a transition line
  bool _isPointOnTransition(Offset point, Transition transition) {
    final fromPos = Offset(transition.fromState.position.x, transition.fromState.position.y);
    final toPos = Offset(transition.toState.position.x, transition.toState.position.y);
    
    // Calculate distance from point to line
    final lineLength = (toPos - fromPos).distance;
    if (lineLength == 0) return false;
    
    final pointToFrom = point - fromPos;
    final fromToTo = toPos - fromPos;
    final t = (pointToFrom.dx * fromToTo.dx + pointToFrom.dy * fromToTo.dy) / (lineLength * lineLength);
    final tClamped = t.clamp(0.0, 1.0);
    final closestPoint = fromPos + (toPos - fromPos) * tClamped;
    
    return (point - closestPoint).distance <= 10; // Transition line thickness
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
                  // TODO: Implement transition editing
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
                  widget.onStateAdded(_contextMenuPosition!);
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

