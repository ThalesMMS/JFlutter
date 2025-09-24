import 'configuration.dart';

/// Minimal interface to represent execution traces in the core packages.
abstract class Trace<C extends Configuration> {
  /// Ordered configurations visited by the execution branch.
  List<C> get configurations;

  /// Configuration where the branch halted.
  C get terminal;

  /// Creates a new trace including [configuration].
  Trace<C> append(C configuration);

  /// Total number of simulation steps represented.
  int get steps => configurations.length - 1;

  /// Whether the branch accepted the input.
  bool get accepted => terminal.isAccepting;
}

/// Immutable trace implementation.
class ImmutableTrace<C extends Configuration> implements Trace<C> {
  ImmutableTrace(List<C> configurations)
      : _configurations = List<C>.unmodifiable(configurations);

  final List<C> _configurations;

  @override
  List<C> get configurations => _configurations;

  @override
  C get terminal => _configurations.isNotEmpty
      ? _configurations.last
      : throw StateError('Trace has no configurations');

  @override
  Trace<C> append(C configuration) {
    return ImmutableTrace<C>([..._configurations, configuration]);
  }
}
