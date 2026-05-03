part of 'graphview_canvas_toolbar.dart';

class _ToolbarGroupConfig {
  _ToolbarGroupConfig({
    required this.id,
    required List<_ToolbarButtonConfig> actions,
  }) : actions = List.unmodifiable(actions);

  final _ToolbarGroup id;
  final List<_ToolbarButtonConfig> actions;
}
