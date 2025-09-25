import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vector_math/vector_math_64.dart';

part 'state.freezed.dart';
part 'state.g.dart';

/// Represents a state in an automaton
@freezed
class State with _$State {
  const factory State({
    required String id,
    required String label,
    required Vector2 position,
    @Default(false) bool isInitial,
    @Default(false) bool isAccepting,
    @Default(StateType.normal) StateType type,
    @Default({}) Map<String, Object?> properties,
  }) = _State;

  factory State.fromJson(Map<String, dynamic> json) => _$StateFromJson(json);

  /// Name of the state (alias for label)
  String get name => label;
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
