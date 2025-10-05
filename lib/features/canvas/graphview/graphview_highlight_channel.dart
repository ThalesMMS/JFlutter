import '../../../core/models/simulation_highlight.dart';
import '../../../core/services/simulation_highlight_service.dart';
import 'graphview_highlight_controller.dart';

/// Highlight channel that bridges [SimulationHighlightService] payloads to a
/// GraphView canvas controller.
class GraphViewSimulationHighlightChannel implements SimulationHighlightChannel {
  GraphViewSimulationHighlightChannel(this._controller);

  final GraphViewHighlightController _controller;

  @override
  void clear() {
    _controller.clearHighlight();
  }

  @override
  void send(SimulationHighlight highlight) {
    _controller.applyHighlight(highlight);
  }
}
