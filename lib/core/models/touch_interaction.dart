import 'package:vector_math/vector_math_64.dart';

/// Touch interaction model for mobile UI
class TouchInteraction {
  /// Type of interaction
  final InteractionType type;

  /// Position of the touch
  final Vector2 position;

  /// Set of selected states
  final Set<String> selectedStates;

  /// Set of selected transitions
  final Set<String> selectedTransitions;

  /// Timestamp of the interaction
  final DateTime timestamp;

  const TouchInteraction({
    required this.type,
    required this.position,
    this.selectedStates = const {},
    this.selectedTransitions = const {},
    required this.timestamp,
  });

  /// Creates a copy of this touch interaction with updated properties
  TouchInteraction copyWith({
    InteractionType? type,
    Vector2? position,
    Set<String>? selectedStates,
    Set<String>? selectedTransitions,
    DateTime? timestamp,
  }) {
    return TouchInteraction(
      type: type ?? this.type,
      position: position ?? this.position,
      selectedStates: selectedStates ?? this.selectedStates,
      selectedTransitions: selectedTransitions ?? this.selectedTransitions,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Converts the touch interaction to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'position': {'x': position.x, 'y': position.y},
      'selectedStates': selectedStates.toList(),
      'selectedTransitions': selectedTransitions.toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates a touch interaction from a JSON representation
  factory TouchInteraction.fromJson(Map<String, dynamic> json) {
    final positionData = (json['position'] as Map?)?.cast<String, dynamic>();
    final positionX = (positionData?['x'] as num?)?.toDouble() ?? 0.0;
    final positionY = (positionData?['y'] as num?)?.toDouble() ?? 0.0;

    return TouchInteraction(
      type: InteractionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InteractionType.tap,
      ),
      position: Vector2(positionX, positionY),
      selectedStates: Set<String>.from(json['selectedStates'] as List),
      selectedTransitions: Set<String>.from(
        json['selectedTransitions'] as List,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TouchInteraction &&
        other.type == type &&
        other.position == position &&
        other.selectedStates == selectedStates &&
        other.selectedTransitions == selectedTransitions &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      position,
      selectedStates,
      selectedTransitions,
      timestamp,
    );
  }

  @override
  String toString() {
    return 'TouchInteraction(type: $type, position: $position, selectedStates: ${selectedStates.length}, selectedTransitions: ${selectedTransitions.length})';
  }

  /// Gets the number of selected states
  int get selectedStateCount => selectedStates.length;

  /// Gets the number of selected transitions
  int get selectedTransitionCount => selectedTransitions.length;

  /// Gets the total number of selected items
  int get totalSelectedCount => selectedStateCount + selectedTransitionCount;

  /// Checks if any states are selected
  bool get hasSelectedStates => selectedStates.isNotEmpty;

  /// Checks if any transitions are selected
  bool get hasSelectedTransitions => selectedTransitions.isNotEmpty;

  /// Checks if anything is selected
  bool get hasSelection => hasSelectedStates || hasSelectedTransitions;

  /// Checks if this is a single selection
  bool get isSingleSelection => totalSelectedCount == 1;

  /// Checks if this is a multiple selection
  bool get isMultipleSelection => totalSelectedCount > 1;

  /// Checks if this is a tap interaction
  bool get isTap => type == InteractionType.tap;

  /// Checks if this is a long press interaction
  bool get isLongPress => type == InteractionType.longPress;

  /// Checks if this is a drag interaction
  bool get isDrag => type == InteractionType.drag;

  /// Checks if this is a pinch interaction
  bool get isPinch => type == InteractionType.pinch;

  /// Checks if this is a pan interaction
  bool get isPan => type == InteractionType.pan;

  /// Checks if this is a double tap interaction
  bool get isDoubleTap => type == InteractionType.doubleTap;

  /// Gets the age of this interaction
  Duration get age => DateTime.now().difference(timestamp);

  /// Checks if this interaction is recent (within the last second)
  bool get isRecent => age.inSeconds < 1;

  /// Checks if this interaction is old (older than 5 seconds)
  bool get isOld => age.inSeconds > 5;

  /// Creates a tap interaction
  factory TouchInteraction.tap({
    required Vector2 position,
    Set<String>? selectedStates,
    Set<String>? selectedTransitions,
  }) {
    return TouchInteraction(
      type: InteractionType.tap,
      position: position,
      selectedStates: selectedStates ?? {},
      selectedTransitions: selectedTransitions ?? {},
      timestamp: DateTime.now(),
    );
  }

  /// Creates a long press interaction
  factory TouchInteraction.longPress({
    required Vector2 position,
    Set<String>? selectedStates,
    Set<String>? selectedTransitions,
  }) {
    return TouchInteraction(
      type: InteractionType.longPress,
      position: position,
      selectedStates: selectedStates ?? {},
      selectedTransitions: selectedTransitions ?? {},
      timestamp: DateTime.now(),
    );
  }

  /// Creates a drag interaction
  factory TouchInteraction.drag({
    required Vector2 position,
    Set<String>? selectedStates,
    Set<String>? selectedTransitions,
  }) {
    return TouchInteraction(
      type: InteractionType.drag,
      position: position,
      selectedStates: selectedStates ?? {},
      selectedTransitions: selectedTransitions ?? {},
      timestamp: DateTime.now(),
    );
  }

  /// Creates a pinch interaction
  factory TouchInteraction.pinch({
    required Vector2 position,
    Set<String>? selectedStates,
    Set<String>? selectedTransitions,
  }) {
    return TouchInteraction(
      type: InteractionType.pinch,
      position: position,
      selectedStates: selectedStates ?? {},
      selectedTransitions: selectedTransitions ?? {},
      timestamp: DateTime.now(),
    );
  }

  /// Creates a pan interaction
  factory TouchInteraction.pan({
    required Vector2 position,
    Set<String>? selectedStates,
    Set<String>? selectedTransitions,
  }) {
    return TouchInteraction(
      type: InteractionType.pan,
      position: position,
      selectedStates: selectedStates ?? {},
      selectedTransitions: selectedTransitions ?? {},
      timestamp: DateTime.now(),
    );
  }

  /// Creates a double tap interaction
  factory TouchInteraction.doubleTap({
    required Vector2 position,
    Set<String>? selectedStates,
    Set<String>? selectedTransitions,
  }) {
    return TouchInteraction(
      type: InteractionType.doubleTap,
      position: position,
      selectedStates: selectedStates ?? {},
      selectedTransitions: selectedTransitions ?? {},
      timestamp: DateTime.now(),
    );
  }
}

/// Types of touch interactions
enum InteractionType {
  /// Single tap
  tap,

  /// Long press
  longPress,

  /// Drag gesture
  drag,

  /// Pinch gesture
  pinch,

  /// Pan gesture
  pan,

  /// Double tap
  doubleTap,
}

/// Extension methods for InteractionType
extension InteractionTypeExtension on InteractionType {
  /// Returns a human-readable description of the interaction type
  String get description {
    switch (this) {
      case InteractionType.tap:
        return 'Tap';
      case InteractionType.longPress:
        return 'Long Press';
      case InteractionType.drag:
        return 'Drag';
      case InteractionType.pinch:
        return 'Pinch';
      case InteractionType.pan:
        return 'Pan';
      case InteractionType.doubleTap:
        return 'Double Tap';
    }
  }

  /// Returns whether this interaction type requires multiple fingers
  bool get requiresMultipleFingers {
    return this == InteractionType.pinch;
  }

  /// Returns whether this interaction type is a gesture
  bool get isGesture {
    return this == InteractionType.drag ||
        this == InteractionType.pinch ||
        this == InteractionType.pan;
  }

  /// Returns whether this interaction type is a tap
  bool get isTap {
    return this == InteractionType.tap ||
        this == InteractionType.doubleTap ||
        this == InteractionType.longPress;
  }

  /// Returns the minimum duration for this interaction type
  Duration get minimumDuration {
    switch (this) {
      case InteractionType.tap:
        return const Duration(milliseconds: 100);
      case InteractionType.longPress:
        return const Duration(milliseconds: 500);
      case InteractionType.drag:
        return const Duration(milliseconds: 200);
      case InteractionType.pinch:
        return const Duration(milliseconds: 300);
      case InteractionType.pan:
        return const Duration(milliseconds: 200);
      case InteractionType.doubleTap:
        return const Duration(milliseconds: 300);
    }
  }

  /// Returns the maximum duration for this interaction type
  Duration get maximumDuration {
    switch (this) {
      case InteractionType.tap:
        return const Duration(milliseconds: 500);
      case InteractionType.longPress:
        return const Duration(seconds: 2);
      case InteractionType.drag:
        return const Duration(seconds: 10);
      case InteractionType.pinch:
        return const Duration(seconds: 5);
      case InteractionType.pan:
        return const Duration(seconds: 10);
      case InteractionType.doubleTap:
        return const Duration(milliseconds: 800);
    }
  }
}
