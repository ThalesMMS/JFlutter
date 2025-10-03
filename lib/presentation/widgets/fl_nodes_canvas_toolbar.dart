import 'package:flutter/material.dart';

/// Toolbar exposing viewport commands for the fl_nodes canvas.
class FlNodesCanvasToolbar extends StatelessWidget {
  const FlNodesCanvasToolbar({
    super.key,
    required this.onAddState,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitToContent,
    required this.onResetView,
    this.onClear,
    this.statusMessage,
    this.layout = FlNodesCanvasToolbarLayout.desktop,
  });

  final VoidCallback onAddState;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitToContent;
  final VoidCallback onResetView;
  final VoidCallback? onClear;
  final String? statusMessage;
  final FlNodesCanvasToolbarLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = <(_ToolbarAction action, VoidCallback handler)>[
      (_ToolbarAction.addState, onAddState),
      (_ToolbarAction.zoomIn, onZoomIn),
      (_ToolbarAction.zoomOut, onZoomOut),
      (_ToolbarAction.fitContent, onFitToContent),
      (_ToolbarAction.resetView, onResetView),
      if (onClear != null) (_ToolbarAction.clear, onClear!),
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

  final List<(_ToolbarAction, VoidCallback)> actions;
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
                      tooltip: entry.$1.label,
                      icon: Icon(entry.$1.icon),
                      onPressed: entry.$2,
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

  final List<(_ToolbarAction, VoidCallback)> actions;
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
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final entry in actions)
                        _MobileToolbarButton(
                          action: entry.$1,
                          onPressed: entry.$2,
                        ),
                    ],
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
    required this.action,
    required this.onPressed,
  });

  final _ToolbarAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHigh,
        foregroundColor: colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onPressed: onPressed,
      icon: Icon(action.icon),
      label: Text(action.label),
    );
  }
}

enum _ToolbarAction {
  addState(Icons.add, 'Add state'),
  zoomIn(Icons.zoom_in, 'Zoom in'),
  zoomOut(Icons.zoom_out, 'Zoom out'),
  fitContent(Icons.fit_screen, 'Fit to content'),
  resetView(Icons.center_focus_strong, 'Reset view'),
  clear(Icons.delete_outline, 'Clear canvas');

  const _ToolbarAction(this.icon, this.label);

  final IconData icon;
  final String label;
}
