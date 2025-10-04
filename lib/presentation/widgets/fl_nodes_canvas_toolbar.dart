import 'package:flutter/material.dart';

import 'automaton_canvas_tool.dart';

/// Toolbar exposing viewport commands for the fl_nodes canvas.
class FlNodesCanvasToolbar extends StatelessWidget {
  const FlNodesCanvasToolbar({
    super.key,
    this.enableToolSelection = false,
    this.activeTool = AutomatonCanvasTool.selection,
    this.onSelectTool,
    required this.onAddState,
    this.onAddTransition,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitToContent,
    required this.onResetView,
    this.onClear,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
    this.statusMessage,
    this.layout = FlNodesCanvasToolbarLayout.desktop,
  })  : assert(
          !enableToolSelection || onSelectTool != null,
          'onSelectTool must be provided when tool selection is enabled.',
        ),
        assert(
          !enableToolSelection || onAddTransition != null,
          'onAddTransition must be provided when tool selection is enabled.',
        );

  final bool enableToolSelection;
  final AutomatonCanvasTool activeTool;
  final VoidCallback? onSelectTool;
  final VoidCallback onAddState;
  final VoidCallback? onAddTransition;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitToContent;
  final VoidCallback onResetView;
  final VoidCallback? onClear;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;
  final String? statusMessage;
  final FlNodesCanvasToolbarLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = <_ToolbarButtonConfig>[
      if (enableToolSelection)
        _ToolbarButtonConfig(
          action: _ToolbarAction.selection,
          handler: onSelectTool,
          isToggle: true,
          isSelected: activeTool == AutomatonCanvasTool.selection,
        ),
      _ToolbarButtonConfig(
        action: _ToolbarAction.addState,
        handler: onAddState,
        isToggle: enableToolSelection,
        isSelected:
            enableToolSelection && activeTool == AutomatonCanvasTool.addState,
      ),
      if (onAddTransition != null)
        _ToolbarButtonConfig(
          action: _ToolbarAction.transition,
          handler: onAddTransition,
          isToggle: enableToolSelection,
          isSelected: enableToolSelection &&
              activeTool == AutomatonCanvasTool.transition,
        ),
      if (onUndo != null)
        _ToolbarButtonConfig(
          action: _ToolbarAction.undo,
          handler: canUndo ? onUndo : null,
        ),
      if (onRedo != null)
        _ToolbarButtonConfig(
          action: _ToolbarAction.redo,
          handler: canRedo ? onRedo : null,
        ),
      _ToolbarButtonConfig(
        action: _ToolbarAction.zoomIn,
        handler: onZoomIn,
      ),
      _ToolbarButtonConfig(
        action: _ToolbarAction.zoomOut,
        handler: onZoomOut,
      ),
      _ToolbarButtonConfig(
        action: _ToolbarAction.fitContent,
        handler: onFitToContent,
      ),
      _ToolbarButtonConfig(
        action: _ToolbarAction.resetView,
        handler: onResetView,
      ),
      if (onClear != null)
        _ToolbarButtonConfig(
          action: _ToolbarAction.clear,
          handler: onClear!,
        ),
    ];

    switch (layout) {
      case FlNodesCanvasToolbarLayout.mobile:
        return _MobileToolbar(
          actions: actions,
          statusMessage: statusMessage,
          theme: theme,
        );
      case FlNodesCanvasToolbarLayout.desktop:
        return _DesktopToolbar(
          actions: actions,
          statusMessage: statusMessage,
          theme: theme,
        );
    }
  }
}

enum FlNodesCanvasToolbarLayout { desktop, mobile }

class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar({
    required this.actions,
    required this.statusMessage,
    required this.theme,
  });

  final List<_ToolbarButtonConfig> actions;
  final String? statusMessage;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in actions) ...[
                    IconButton(
                      tooltip: entry.action.label,
                      icon: Icon(entry.action.icon),
                      onPressed: entry.handler,
                      style: entry.isToggle
                          ? IconButton.styleFrom(
                              backgroundColor: entry.isSelected
                                  ? colorScheme.secondaryContainer
                                  : colorScheme.surfaceVariant
                                      .withOpacity(0.15),
                              foregroundColor: entry.isSelected
                                  ? colorScheme.onSecondaryContainer
                                  : colorScheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                    if (entry != actions.last)
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color:
                            colorScheme.outlineVariant.withOpacity(0.35),
                      ),
                  ],
                ],
              ),
            ),
            if (statusMessage != null && statusMessage!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  statusMessage!,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileToolbar extends StatelessWidget {
  const _MobileToolbar({
    required this.actions,
    required this.statusMessage,
    required this.theme,
  });

  final List<_ToolbarButtonConfig> actions;
  final String? statusMessage;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            color: colorScheme.surface,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in actions)
                          _MobileToolbarButton(
                            config: entry,
                          ),
                      ],
                    ),
                  ),
                  if (statusMessage != null && statusMessage!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        statusMessage!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileToolbarButton extends StatelessWidget {
  const _MobileToolbarButton({
    required this.config,
  });

  final _ToolbarButtonConfig config;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = config.isToggle
        ? (config.isSelected
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest)
        : colorScheme.secondaryContainer;
    final foregroundColor = config.isToggle
        ? (config.isSelected
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurfaceVariant)
        : colorScheme.onSecondaryContainer;
    return Tooltip(
      message: config.action.label,
      child: IconButton.filledTonal(
        onPressed: config.handler,
        icon: Icon(config.action.icon),
        style: IconButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

enum _ToolbarAction {
  selection(Icons.pan_tool, 'Selection tool'),
  undo(Icons.undo, 'Undo'),
  redo(Icons.redo, 'Redo'),
  addState(Icons.add, 'Add state'),
  transition(Icons.arrow_right_alt, 'Add transition'),
  zoomIn(Icons.zoom_in, 'Zoom in'),
  zoomOut(Icons.zoom_out, 'Zoom out'),
  fitContent(Icons.fit_screen, 'Fit to content'),
  resetView(Icons.center_focus_strong, 'Reset view'),
  clear(Icons.delete_outline, 'Clear canvas');

  const _ToolbarAction(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _ToolbarButtonConfig {
  const _ToolbarButtonConfig({
    required this.action,
    this.handler,
    this.isToggle = false,
    this.isSelected = false,
  });

  final _ToolbarAction action;
  final VoidCallback? handler;
  final bool isToggle;
  final bool isSelected;
}
