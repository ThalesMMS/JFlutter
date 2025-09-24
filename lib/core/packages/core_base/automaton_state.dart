/// Minimal interface representing an automaton state without UI concerns.
abstract class AutomatonState {
  /// Identifier of the state.
  String get id;

  /// Label presented to the user.
  String get label;

  /// Additional metadata associated with the state.
  Map<String, Object?> get metadata;
}

/// Simple immutable implementation of [AutomatonState].
class SimpleState implements AutomatonState {
  const SimpleState({
    required this.id,
    required this.label,
    this.metadata = const {},
  });

  @override
  final String id;

  @override
  final String label;

  @override
  final Map<String, Object?> metadata;

  SimpleState copyWith({
    String? id,
    String? label,
    Map<String, Object?>? metadata,
  }) {
    return SimpleState(
      id: id ?? this.id,
      label: label ?? this.label,
      metadata: metadata ?? this.metadata,
    );
  }
}
