import 'package:flutter/foundation.dart';

/// Editing tools supported by the automaton canvas.
enum AutomatonCanvasTool {
  selection,
  addState,
  transition,
}

/// Controller that tracks and broadcasts the active canvas tool.
class AutomatonCanvasToolController extends ChangeNotifier {
  AutomatonCanvasToolController(
    [this._activeTool = AutomatonCanvasTool.selection],
  );

  AutomatonCanvasTool _activeTool;

  AutomatonCanvasTool get activeTool => _activeTool;

  /// Sets the current tool, notifying listeners when it changes.
  void setActiveTool(AutomatonCanvasTool tool) {
    if (_activeTool == tool) {
      return;
    }
    _activeTool = tool;
    notifyListeners();
  }
}
