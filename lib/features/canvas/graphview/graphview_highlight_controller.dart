import '../../../core/models/simulation_highlight.dart';

/// Common contract exposed by GraphView canvas controllers that support
/// simulation highlights.
abstract class GraphViewHighlightController {
  /// Applies the provided [highlight] to the canvas.
  void applyHighlight(SimulationHighlight highlight);

  /// Clears any active highlight from the canvas.
  void clearHighlight();
}
