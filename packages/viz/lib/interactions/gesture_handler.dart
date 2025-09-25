import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';

/// Gesture handler for automaton canvas interactions
class GestureHandler {
  final Function(Offset) onTap;
  final Function(Offset, Offset) onPan;
  final Function(double) onScale;
  final Function(Offset) onLongPress;
  final Function(Offset) onDoubleTap;
  final Function(Offset) onSecondaryTap;

  GestureHandler({
    required this.onTap,
    required this.onPan,
    required this.onScale,
    required this.onLongPress,
    required this.onDoubleTap,
    required this.onSecondaryTap,
  });

  /// Create gesture detector for automaton canvas
  Widget buildGestureDetector({
    required Widget child,
    required Size canvasSize,
    required Map<String, Offset> statePositions,
    required List<Transition> transitions,
  }) {
    return GestureDetector(
      onTap: (details) => _handleTap(details.localPosition, statePositions),
      onPanStart: (details) => _handlePanStart(details.localPosition, statePositions),
      onPanUpdate: (details) => _handlePanUpdate(details.localPosition, statePositions),
      onPanEnd: (details) => _handlePanEnd(details.localPosition, statePositions),
      onScaleStart: (details) => _handleScaleStart(details.localPosition),
      onScaleUpdate: (details) => _handleScaleUpdate(details.scale),
      onScaleEnd: (details) => _handleScaleEnd(details.localPosition),
      onLongPress: () => _handleLongPress(statePositions),
      onLongPressStart: (details) => _handleLongPressStart(details.localPosition, statePositions),
      onLongPressMoveUpdate: (details) => _handleLongPressMoveUpdate(details.localPosition, statePositions),
      onLongPressEnd: (details) => _handleLongPressEnd(details.localPosition, statePositions),
      onDoubleTap: () => _handleDoubleTap(statePositions),
      onSecondaryTap: (details) => _handleSecondaryTap(details.localPosition, statePositions),
      child: child,
    );
  }

  /// Handle tap gesture
  void _handleTap(Offset position, Map<String, Offset> statePositions) {
    final hitState = _findHitState(position, statePositions);
    if (hitState != null) {
      onTap(position);
    }
  }

  /// Handle pan start
  void _handlePanStart(Offset position, Map<String, Offset> statePositions) {
    final hitState = _findHitState(position, statePositions);
    if (hitState != null) {
      _currentDraggedState = hitState;
      _panStartPosition = position;
    }
  }

  /// Handle pan update
  void _handlePanUpdate(Offset position, Map<String, Offset> statePositions) {
    if (_currentDraggedState != null && _panStartPosition != null) {
      final delta = position - _panStartPosition!;
      onPan(_panStartPosition!, position);
    }
  }

  /// Handle pan end
  void _handlePanEnd(Offset position, Map<String, Offset> statePositions) {
    if (_currentDraggedState != null) {
      _currentDraggedState = null;
      _panStartPosition = null;
    }
  }

  /// Handle scale start
  void _handleScaleStart(Offset position) {
    _scaleStartValue = 1.0;
  }

  /// Handle scale update
  void _handleScaleUpdate(double scale) {
    final scaleDelta = scale - _scaleStartValue;
    onScale(scaleDelta);
    _scaleStartValue = scale;
  }

  /// Handle scale end
  void _handleScaleEnd(Offset position) {
    _scaleStartValue = 1.0;
  }

  /// Handle long press
  void _handleLongPress(Map<String, Offset> statePositions) {
    onLongPress(Offset.zero);
  }

  /// Handle long press start
  void _handleLongPressStart(Offset position, Map<String, Offset> statePositions) {
    final hitState = _findHitState(position, statePositions);
    if (hitState != null) {
      _longPressState = hitState;
      _longPressPosition = position;
    }
  }

  /// Handle long press move update
  void _handleLongPressMoveUpdate(Offset position, Map<String, Offset> statePositions) {
    if (_longPressState != null && _longPressPosition != null) {
      final delta = position - _longPressPosition!;
      onPan(_longPressPosition!, position);
    }
  }

  /// Handle long press end
  void _handleLongPressEnd(Offset position, Map<String, Offset> statePositions) {
    if (_longPressState != null) {
      _longPressState = null;
      _longPressPosition = null;
    }
  }

  /// Handle double tap
  void _handleDoubleTap(Map<String, Offset> statePositions) {
    onDoubleTap(Offset.zero);
  }

  /// Handle secondary tap (right-click on desktop, long press on mobile)
  void _handleSecondaryTap(Offset position, Map<String, Offset> statePositions) {
    final hitState = _findHitState(position, statePositions);
    if (hitState != null) {
      onSecondaryTap(position);
    }
  }

  /// Find state at position
  String? _findHitState(Offset position, Map<String, Offset> statePositions) {
    const double hitRadius = 30.0;
    
    for (final entry in statePositions.entries) {
      final distance = (position - entry.value).distance;
      if (distance <= hitRadius) {
        return entry.key;
      }
    }
    
    return null;
  }

  // Private state variables
  String? _currentDraggedState;
  Offset? _panStartPosition;
  double _scaleStartValue = 1.0;
  String? _longPressState;
  Offset? _longPressPosition;
}

/// Gesture configuration
class GestureConfig {
  final double hitRadius;
  final double minPanDistance;
  final double minScaleFactor;
  final Duration longPressDuration;
  final bool enablePan;
  final bool enableScale;
  final bool enableLongPress;
  final bool enableDoubleTap;
  final bool enableSecondaryTap;

  const GestureConfig({
    this.hitRadius = 30.0,
    this.minPanDistance = 5.0,
    this.minScaleFactor = 0.1,
    this.longPressDuration = const Duration(milliseconds: 500),
    this.enablePan = true,
    this.enableScale = true,
    this.enableLongPress = true,
    this.enableDoubleTap = true,
    this.enableSecondaryTap = true,
  });
}

/// Gesture state manager
class GestureStateManager {
  final Map<String, Offset> _statePositions = {};
  final List<Transition> _transitions = [];
  final GestureConfig _config;
  
  GestureStateManager({required GestureConfig config}) : _config = config;

  /// Update state positions
  void updateStatePositions(Map<String, Offset> positions) {
    _statePositions.clear();
    _statePositions.addAll(positions);
  }

  /// Update transitions
  void updateTransitions(List<Transition> transitions) {
    _transitions.clear();
    _transitions.addAll(transitions);
  }

  /// Get state at position
  String? getStateAtPosition(Offset position) {
    for (final entry in _statePositions.entries) {
      final distance = (position - entry.value).distance;
      if (distance <= _config.hitRadius) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get transition at position
  Transition? getTransitionAtPosition(Offset position) {
    for (final transition in _transitions) {
      final fromPos = _statePositions[transition.from];
      final toPos = _statePositions[transition.to];
      
      if (fromPos != null && toPos != null) {
        final distance = _distanceToLine(position, fromPos, toPos);
        if (distance <= _config.hitRadius) {
          return transition;
        }
      }
    }
    return null;
  }

  /// Calculate distance from point to line
  double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final A = point.dx - lineStart.dx;
    final B = point.dy - lineStart.dy;
    final C = lineEnd.dx - lineStart.dx;
    final D = lineEnd.dy - lineStart.dy;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    
    if (lenSq == 0) return (point - lineStart).distance;
    
    final param = dot / lenSq;
    
    Offset closest;
    if (param < 0) {
      closest = lineStart;
    } else if (param > 1) {
      closest = lineEnd;
    } else {
      closest = Offset(
        lineStart.dx + param * C,
        lineStart.dy + param * D,
      );
    }
    
    return (point - closest).distance;
  }

  /// Move state to new position
  void moveState(String stateId, Offset newPosition) {
    _statePositions[stateId] = newPosition;
  }

  /// Get state position
  Offset? getStatePosition(String stateId) {
    return _statePositions[stateId];
  }

  /// Get all state positions
  Map<String, Offset> getAllStatePositions() {
    return Map.from(_statePositions);
  }

  /// Get all transitions
  List<Transition> getAllTransitions() {
    return List.from(_transitions);
  }
}

/// Gesture event types
enum GestureEventType {
  tap,
  pan,
  scale,
  longPress,
  doubleTap,
  secondaryTap,
}

/// Gesture event
class GestureEvent {
  final GestureEventType type;
  final Offset position;
  final Offset? startPosition;
  final Offset? endPosition;
  final double? scale;
  final String? targetState;
  final Transition? targetTransition;
  final DateTime timestamp;

  const GestureEvent({
    required this.type,
    required this.position,
    this.startPosition,
    this.endPosition,
    this.scale,
    this.targetState,
    this.targetTransition,
    required this.timestamp,
  });
}

/// Gesture event handler
class GestureEventHandler {
  final Function(GestureEvent) onGestureEvent;
  final GestureStateManager _stateManager;
  final GestureConfig _config;

  GestureEventHandler({
    required this.onGestureEvent,
    required GestureStateManager stateManager,
    required GestureConfig config,
  }) : _stateManager = stateManager, _config = config;

  /// Handle gesture event
  void handleGestureEvent(GestureEvent event) {
    onGestureEvent(event);
  }

  /// Create tap event
  GestureEvent createTapEvent(Offset position) {
    final targetState = _stateManager.getStateAtPosition(position);
    final targetTransition = _stateManager.getTransitionAtPosition(position);
    
    return GestureEvent(
      type: GestureEventType.tap,
      position: position,
      targetState: targetState,
      targetTransition: targetTransition,
      timestamp: DateTime.now(),
    );
  }

  /// Create pan event
  GestureEvent createPanEvent(Offset startPosition, Offset endPosition) {
    final targetState = _stateManager.getStateAtPosition(startPosition);
    
    return GestureEvent(
      type: GestureEventType.pan,
      position: endPosition,
      startPosition: startPosition,
      endPosition: endPosition,
      targetState: targetState,
      timestamp: DateTime.now(),
    );
  }

  /// Create scale event
  GestureEvent createScaleEvent(Offset position, double scale) {
    return GestureEvent(
      type: GestureEventType.scale,
      position: position,
      scale: scale,
      timestamp: DateTime.now(),
    );
  }

  /// Create long press event
  GestureEvent createLongPressEvent(Offset position) {
    final targetState = _stateManager.getStateAtPosition(position);
    
    return GestureEvent(
      type: GestureEventType.longPress,
      position: position,
      targetState: targetState,
      timestamp: DateTime.now(),
    );
  }

  /// Create double tap event
  GestureEvent createDoubleTapEvent(Offset position) {
    final targetState = _stateManager.getStateAtPosition(position);
    
    return GestureEvent(
      type: GestureEventType.doubleTap,
      position: position,
      targetState: targetState,
      timestamp: DateTime.now(),
    );
  }

  /// Create secondary tap event
  GestureEvent createSecondaryTapEvent(Offset position) {
    final targetState = _stateManager.getStateAtPosition(position);
    final targetTransition = _stateManager.getTransitionAtPosition(position);
    
    return GestureEvent(
      type: GestureEventType.secondaryTap,
      position: position,
      targetState: targetState,
      targetTransition: targetTransition,
      timestamp: DateTime.now(),
    );
  }
}
