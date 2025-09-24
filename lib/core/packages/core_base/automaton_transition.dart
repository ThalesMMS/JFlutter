import 'automaton_state.dart';

/// Minimal interface representing an automaton transition.
abstract class AutomatonTransition<S extends AutomatonState> {
  /// Identifier of the transition.
  String get id;

  /// State where the transition starts.
  S get fromState;

  /// State where the transition ends.
  S get toState;

  /// Metadata describing symbols, stack actions, etc.
  Map<String, Object?> get metadata;
}

/// Simple immutable transition implementation.
class SimpleTransition<S extends AutomatonState>
    implements AutomatonTransition<S> {
  const SimpleTransition({
    required this.id,
    required this.fromState,
    required this.toState,
    this.metadata = const {},
  });

  @override
  final String id;

  @override
  final S fromState;

  @override
  final S toState;

  @override
  final Map<String, Object?> metadata;

  SimpleTransition<S> copyWith({
    String? id,
    S? fromState,
    S? toState,
    Map<String, Object?>? metadata,
  }) {
    return SimpleTransition<S>(
      id: id ?? this.id,
      fromState: fromState ?? this.fromState,
      toState: toState ?? this.toState,
      metadata: metadata ?? this.metadata,
    );
  }
}
