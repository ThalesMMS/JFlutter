import 'package:vector_math/vector_math_64.dart';

/// Represents a state in an automaton
class State {
  /// Unique identifier for the state within the automaton
  final String id;

  /// Display label for the state (can be empty)
  final String label;

  /// Name of the state (alias for label)
  final String name;

  /// Position of the state on the canvas (mobile-optimized)
  final Vector2 position;

  /// Whether this state is the initial state
  final bool isInitial;

  /// Whether this state is an accepting/final state
  final bool isAccepting;

  /// Type of the state (normal, trap, etc.)
  final StateType type;

  /// Additional properties for different automaton types
  final Map<String, dynamic> properties;

  const State({
    required this.id,
    required this.label,
    required this.position,
    this.isInitial = false,
    this.isAccepting = false,
    this.type = StateType.normal,
    this.properties = const {},
  }) : name = label;

  /// Creates a copy of this state with updated properties
  State copyWith({
    String? id,
    String? label,
    Vector2? position,
    bool? isInitial,
    bool? isAccepting,
    StateType? type,
    Map<String, dynamic>? properties,
  }) {
    return State(
      id: id ?? this.id,
      label: label ?? this.label,
      position: position ?? this.position,
      isInitial: isInitial ?? this.isInitial,
      isAccepting: isAccepting ?? this.isAccepting,
      type: type ?? this.type,
      properties: properties ?? this.properties,
    );
  }

  /// Converts the state to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'position': {
        'x': position.x,
        'y': position.y,
      },
      'isInitial': isInitial,
      'isAccepting': isAccepting,
      'type': type.name,
      'properties': properties,
    };
  }

  /// Creates a state from a JSON representation
  factory State.fromJson(Map<String, dynamic> json) {
    return State(
      id: json['id'] as String,
      label: json['label'] as String,
      position: Vector2(
        (json['position'] as Map<String, dynamic>)['x'] as double,
        (json['position'] as Map<String, dynamic>)['y'] as double,
      ),
      isInitial: json['isInitial'] as bool? ?? false,
      isAccepting: json['isAccepting'] as bool? ?? false,
      type: StateType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StateType.normal,
      ),
      properties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is State &&
        other.id == id &&
        other.label == label &&
        other.position == position &&
        other.isInitial == isInitial &&
        other.isAccepting == isAccepting &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      label,
      position,
      isInitial,
      isAccepting,
      type,
    );
  }

  @override
  String toString() {
    return 'State(id: $id, label: $label, position: $position, '
        'isInitial: $isInitial, isAccepting: $isAccepting, type: $type)';
  }

  /// Validates the state properties
  List<String> validate() {
    final errors = <String>[];

    if (id.isEmpty) {
      errors.add('State ID cannot be empty');
    }

    if (position.x < 0 || position.y < 0) {
      errors.add('State position must be non-negative');
    }

    return errors;
  }

  /// Checks if this state is within the given bounds
  bool isWithinBounds(Vector2 topLeft, Vector2 bottomRight) {
    return position.x >= topLeft.x &&
        position.x <= bottomRight.x &&
        position.y >= topLeft.y &&
        position.y <= bottomRight.y;
  }

  /// Calculates the distance to another state
  double distanceTo(State other) {
    return position.distanceTo(other.position);
  }

  /// Checks if this state overlaps with another state
  bool overlapsWith(State other, double radius) {
    return distanceTo(other) < radius * 2;
  }
}

/// Types of states in an automaton
enum StateType {
  /// Normal state
  normal,

  /// Trap state (non-accepting sink)
  trap,

  /// Accepting state
  accepting,

  /// Initial state
  initial,

  /// Dead state (unreachable)
  dead,
}

/// Extension methods for StateType
extension StateTypeExtension on StateType {
  /// Returns a human-readable description of the state type
  String get description {
    switch (this) {
      case StateType.normal:
        return 'Normal state';
      case StateType.trap:
        return 'Trap state';
      case StateType.accepting:
        return 'Accepting state';
      case StateType.initial:
        return 'Initial state';
      case StateType.dead:
        return 'Dead state';
    }
  }

  /// Returns whether this state type can be accepting
  bool get canBeAccepting {
    return this != StateType.trap && this != StateType.dead;
  }

  /// Returns whether this state type can be initial
  bool get canBeInitial {
    return this != StateType.dead;
  }
}
