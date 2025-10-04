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
          tooltip: 'Simulate',
          onPressed: isSimulationEnabled ? onSimulate : null,
        ),
      if (onAlgorithms != null)
        _ControlAction(
          icon: Icons.auto_awesome,
          tooltip: 'Algorithms',
          onPressed: isAlgorithmsEnabled ? onAlgorithms : null,
        ),
      if (onMetrics != null)
        _ControlAction(
          icon: Icons.bar_chart,
          tooltip: 'Metrics',
          onPressed: isMetricsEnabled ? onMetrics : null,
        ),
    ];

    final canvasActions = <_ControlAction>[
      if (onUndo != null)
        _ControlAction(
          icon: Icons.undo,
          tooltip: 'Undo',
          onPressed: canUndo ? onUndo : null,
        ),
      if (onRedo != null)
        _ControlAction(
          icon: Icons.redo,
          tooltip: 'Redo',
          onPressed: canRedo ? onRedo : null,
        ),
      _ControlAction(
        icon: Icons.add,
        tooltip: 'Add state',
        onPressed: onAddState,
      ),
      _ControlAction(
        icon: Icons.zoom_in,
        tooltip: 'Zoom in',
        onPressed: onZoomIn,
      ),
      _ControlAction(
        icon: Icons.zoom_out,
        tooltip: 'Zoom out',
        onPressed: onZoomOut,
      ),
      _ControlAction(
        icon: Icons.fit_screen,
        tooltip: 'Fit to content',
        onPressed: onFitToContent,
      ),
      _ControlAction(
        icon: Icons.center_focus_strong,
        tooltip: 'Reset view',
        onPressed: onResetView,
      ),
      if (onClear != null)
        _ControlAction(
          icon: Icons.delete_outline,
          tooltip: 'Clear canvas',
          onPressed: onClear,
        ),
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            borderRadius: BorderRadius.circular(20),
            color: colorScheme.surface,
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (primaryActions.isNotEmpty)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
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
                    const SizedBox(height: 8),
                  if (canvasActions.isNotEmpty)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
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
                      padding: const EdgeInsets.only(top: 10),
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
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
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
    final ButtonStyle buttonStyle = IconButton.styleFrom(
      padding: const EdgeInsets.all(8),
      visualDensity: VisualDensity.compact,
      minimumSize: const Size.square(40),
      shape: const CircleBorder(),
    );

    final Widget button = switch (style) {
      _ButtonStyleVariant.filled => IconButton.filled(
          onPressed: action.onPressed,
          style: buttonStyle,
          icon: Icon(action.icon),
        ),
      _ButtonStyleVariant.tonal => IconButton.filledTonal(
          onPressed: action.onPressed,
          style: buttonStyle,
          icon: Icon(action.icon),
        ),
    };

    return Tooltip(
      message: action.tooltip,
      child: Semantics(
        label: action.tooltip,
        button: true,
        enabled: action.onPressed != null,
        child: button,
      ),
    );
  }
}
