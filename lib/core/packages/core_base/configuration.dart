import 'automaton_state.dart';

/// Minimal runtime configuration interface shared across automata.
abstract class Configuration {
  /// State active in this configuration.
  AutomatonState get state;

  /// Metadata describing the runtime snapshot (stack, tape, etc.).
  Map<String, Object?> get metadata;

  /// Whether this configuration satisfies acceptance criteria.
  bool get isAccepting;
}

/// Immutable implementation of [Configuration].
class SimpleConfiguration implements Configuration {
  const SimpleConfiguration({
    required this.state,
    this.metadata = const {},
    this.isAccepting = false,
  });

  @override
  final AutomatonState state;

  @override
  final Map<String, Object?> metadata;

  @override
  final bool isAccepting;

  SimpleConfiguration copyWith({
    AutomatonState? state,
    Map<String, Object?>? metadata,
    bool? isAccepting,
  }) {
    return SimpleConfiguration(
      state: state ?? this.state,
      metadata: metadata ?? this.metadata,
      isAccepting: isAccepting ?? this.isAccepting,
    );
  }
}
