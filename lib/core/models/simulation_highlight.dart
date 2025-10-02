/// Immutable payload describing which canvas elements should be highlighted.
class SimulationHighlight {
  /// Set of state identifiers to highlight.
  final Set<String> stateIds;

  /// Set of transition identifiers to highlight.
  final Set<String> transitionIds;

  /// Creates a new [SimulationHighlight].
  const SimulationHighlight({
    this.stateIds = const <String>{},
    this.transitionIds = const <String>{},
  });

  /// Empty highlight payload.
  static const SimulationHighlight empty = SimulationHighlight();

  /// Returns whether the payload does not request any highlight.
  bool get isEmpty => stateIds.isEmpty && transitionIds.isEmpty;

  /// Creates a copy with optional overrides.
  SimulationHighlight copyWith({
    Set<String>? stateIds,
    Set<String>? transitionIds,
  }) {
    return SimulationHighlight(
      stateIds: stateIds ?? this.stateIds,
      transitionIds: transitionIds ?? this.transitionIds,
    );
  }
}
