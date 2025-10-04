import 'package:flutter/material.dart';

/// Unified control surface for mobile automaton editors.
///
/// The widget groups primary workspace actions (simulation, algorithms, metrics)
/// together with the core canvas controls so touch users no longer depend on
/// floating buttons sprinkled across each page. All handlers are optional so the
/// host page can tailor the surface to the available capabilities.
class MobileAutomatonControls extends StatelessWidget {
  const MobileAutomatonControls({
    super.key,
    required this.onAddState,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitToContent,
    required this.onResetView,
    this.onClear,
    this.onUndo,
    this.onRedo,
    this.statusMessage,
    this.canUndo = false,
    this.canRedo = false,
    this.onSimulate,
    this.isSimulationEnabled = true,
    this.onAlgorithms,
    this.isAlgorithmsEnabled = true,
    this.onMetrics,
    this.isMetricsEnabled = true,
  });

  final VoidCallback onAddState;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitToContent;
  final VoidCallback onResetView;
  final VoidCallback? onClear;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final String? statusMessage;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onSimulate;
  final bool isSimulationEnabled;
  final VoidCallback? onAlgorithms;
  final bool isAlgorithmsEnabled;
  final VoidCallback? onMetrics;
  final bool isMetricsEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final primaryActions = <_ControlAction>[
      if (onSimulate != null)
        _ControlAction(
          icon: Icons.play_arrow,
          label: 'Simulate',
          onPressed: isSimulationEnabled ? onSimulate : null,
        ),
      if (onAlgorithms != null)
        _ControlAction(
          icon: Icons.auto_awesome,
          label: 'Algorithms',
          onPressed: isAlgorithmsEnabled ? onAlgorithms : null,
        ),
      if (onMetrics != null)
        _ControlAction(
          icon: Icons.bar_chart,
          label: 'Metrics',
          onPressed: isMetricsEnabled ? onMetrics : null,
        ),
    ];

    final canvasActions = <_ControlAction>[
      if (onUndo != null)
        _ControlAction(
          icon: Icons.undo,
          label: 'Undo',
          onPressed: canUndo ? onUndo : null,
        ),
      if (onRedo != null)
        _ControlAction(
          icon: Icons.redo,
          label: 'Redo',
          onPressed: canRedo ? onRedo : null,
        ),
      _ControlAction(
        icon: Icons.add,
        label: 'Add state',
        onPressed: onAddState,
      ),
      _ControlAction(
        icon: Icons.zoom_in,
        label: 'Zoom in',
        onPressed: onZoomIn,
      ),
      _ControlAction(
        icon: Icons.zoom_out,
        label: 'Zoom out',
        onPressed: onZoomOut,
      ),
      _ControlAction(
        icon: Icons.fit_screen,
        label: 'Fit to content',
        onPressed: onFitToContent,
      ),
      _ControlAction(
        icon: Icons.center_focus_strong,
        label: 'Reset view',
        onPressed: onResetView,
      ),
      if (onClear != null)
        _ControlAction(
          icon: Icons.delete_outline,
          label: 'Clear canvas',
          onPressed: onClear,
        ),
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            borderRadius: BorderRadius.circular(24),
            color: colorScheme.surface,
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (primaryActions.isNotEmpty)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: primaryActions
                          .map(
                            (action) => _MobileControlButton(
                              action: action,
                              style: _ButtonStyleVariant.filled,
                            ),
                          )
                          .toList(),
                    ),
                  if (primaryActions.isNotEmpty && canvasActions.isNotEmpty)
                    const SizedBox(height: 12),
                  if (canvasActions.isNotEmpty)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: canvasActions
                          .map(
                            (action) => _MobileControlButton(
                              action: action,
                              style: _ButtonStyleVariant.tonal,
                            ),
                          )
                          .toList(),
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

enum _ButtonStyleVariant { filled, tonal }

class _ControlAction {
  const _ControlAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
}

class _MobileControlButton extends StatelessWidget {
  const _MobileControlButton({
    required this.action,
    this.style = _ButtonStyleVariant.filled,
  });

  final _ControlAction action;
  final _ButtonStyleVariant style;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final buttonStyle = switch (style) {
      _ButtonStyleVariant.filled => FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      _ButtonStyleVariant.tonal => FilledButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHigh,
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
    };

    return FilledButton.icon(
      style: buttonStyle,
      onPressed: action.onPressed,
      icon: Icon(action.icon),
      label: Text(action.label),
    );
  }
}
