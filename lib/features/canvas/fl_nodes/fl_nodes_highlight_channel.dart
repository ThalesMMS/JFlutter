import '../../../core/models/simulation_highlight.dart';
import '../../../core/services/simulation_highlight_service.dart';
import 'fl_nodes_highlight_controller.dart';

/// Highlight channel that bridges [SimulationHighlightService] payloads to a
/// fl_nodes canvas controller.
class FlNodesSimulationHighlightChannel implements SimulationHighlightChannel {
  FlNodesSimulationHighlightChannel(this._controller);

  final FlNodesHighlightController _controller;

  @override
  void clear() {
    _controller.clearHighlight();
  }

  @override
  void send(SimulationHighlight highlight) {
    _controller.applyHighlight(highlight);
  }
}
