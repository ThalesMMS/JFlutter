import 'package:flutter/material.dart';

import 'automaton_canvas_tool.dart';

/// Unified control surface for mobile automaton editors.
///
/// The widget groups primary workspace actions (simulation, algorithms, metrics)
/// together with the core canvas controls so touch users no longer depend on
/// floating buttons sprinkled across each page. All handlers are optional so the
/// host page can tailor the surface to the available capabilities.
class MobileAutomatonControls extends StatelessWidget {
  const MobileAutomatonControls({
    super.key,
    this.enableToolSelection = false,
    this.activeTool = AutomatonCanvasTool.selection,
    this.onSelectTool,
    required this.onAddState,
    this.onAddTransition,
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
    this.showPrimaryActions = true,
  }) : assert(
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
  final bool showPrimaryActions;

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
      if (onRedo != null)
        _ControlAction(
          icon: Icons.redo,
          tooltip: 'Redo',
          onPressed: canRedo ? onRedo : null,
        ),
      if (enableToolSelection)
        _ControlAction(
          icon: Icons.pan_tool,
          label: 'Select',
          onPressed: onSelectTool,
          isToggle: true,
          isSelected: activeTool == AutomatonCanvasTool.selection,
        ),
      _ControlAction(
        icon: Icons.add,
        tooltip: 'Add state',
        onPressed: onAddState,
        isToggle: enableToolSelection,
        isSelected:
            enableToolSelection && activeTool == AutomatonCanvasTool.addState,
      ),
      if (onAddTransition != null)
        _ControlAction(
          icon: Icons.arrow_right_alt,
          label: 'Add transition',
          onPressed: onAddTransition,
          isToggle: enableToolSelection,
          isSelected:
              enableToolSelection &&
              activeTool == AutomatonCanvasTool.transition,
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
      if (onUndo != null)
        _ControlAction(
          icon: Icons.undo,
          tooltip: 'Undo',
          onPressed: canUndo ? onUndo : null,
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
                  if (showPrimaryActions && primaryActions.isNotEmpty)
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
                  if (showPrimaryActions &&
                      primaryActions.isNotEmpty &&
                      canvasActions.isNotEmpty)
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
    this.tooltip,
    this.label,
    required this.onPressed,
    this.isToggle = false,
    this.isSelected = false,
  });

  final IconData icon;

  /// Texto mostrado no Tooltip. Se não vier, caímos para [label] (se houver).
  final String? tooltip;

  /// Rótulo opcional pensado pelo branch "codex". Hoje é usado apenas para
  /// acessibilidade/tooltip fallback (mantém compatibilidade sem quebrar UI).
  final String? label;

  final VoidCallback? onPressed;
  final bool isToggle;
  final bool isSelected;

  String get effectiveTooltip =>
      (tooltip?.trim().isNotEmpty == true) ? tooltip! : (label ?? '');
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

    // Base para todos os ícones (circular, compacto).
    final baseStyle = IconButton.styleFrom(
      padding: const EdgeInsets.all(8),
      visualDensity: VisualDensity.compact,
      minimumSize: const Size.square(40),
      shape: const CircleBorder(),
    );

    // Aplica cores de "toggle selecionado" quando aplicável.
    final bool canPress = action.onPressed != null;
    final bool selected = action.isToggle && action.isSelected && canPress;

    // Cores para estado selecionado vs normal (herda do tema).
    final ButtonStyle effectiveStyle = baseStyle.merge(
      IconButton.styleFrom(
        backgroundColor: selected
            ? colorScheme.secondaryContainer
            : null, // deixa default quando não selecionado
        foregroundColor: selected ? colorScheme.onSecondaryContainer : null,
      ),
    );

    final Widget button = switch (style) {
      _ButtonStyleVariant.filled => IconButton.filled(
        onPressed: action.onPressed,
        style: effectiveStyle,
        icon: Icon(action.icon),
      ),
      _ButtonStyleVariant.tonal => IconButton.filledTonal(
        onPressed: action.onPressed,
        style: effectiveStyle,
        icon: Icon(action.icon),
      ),
    };

    // Mantém acessibilidade e tooltip (fallback para label se tooltip não vier).
    final String tip = action.effectiveTooltip;

    return Tooltip(
      message: tip,
      child: Semantics(
        label: tip.isNotEmpty ? tip : null,
        button: true,
        enabled: canPress,
        toggled: action.isToggle ? selected : null,
        child: button,
      ),
    );
  }
}
