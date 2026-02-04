//
//  graphview_canvas_toolbar.dart
//  JFlutter
//
//  Define a barra de ferramentas que controla o canvas de automatos em GraphView,
//  disponibilizando comandos de viewport, botões de desfazer/refazer e atalhos
//  para criação de estados e transições em modos desktop ou mobile.
//  Observa o controlador do canvas para refletir o estado atual das ações,
//  permitindo seleção de ferramentas mutuamente exclusivas e ganchos de limpeza,
//  mensagens de status e fluxos personalizados.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../core/constants/help_content.dart';
import '../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import 'automaton_canvas_tool.dart';
import 'contextual_help_tooltip.dart';
import 'keyboard_shortcuts_dialog.dart';

/// Toolbar exposing viewport commands for the GraphView canvas.
class GraphViewCanvasToolbar extends StatefulWidget {
  const GraphViewCanvasToolbar({
    super.key,
    required this.controller,
    this.enableToolSelection = false,
    this.showSelectionTool = false,
    this.activeTool = AutomatonCanvasTool.selection,
    this.onSelectTool,
    required this.onAddState,
    this.onAddTransition,
    this.onClear,
    this.statusMessage,
    this.layout = GraphViewCanvasToolbarLayout.desktop,
  }) : assert(
         !(enableToolSelection && showSelectionTool) || onSelectTool != null,
         'onSelectTool must be provided when the selection tool is visible.',
       ),
       assert(
         !enableToolSelection || onAddTransition != null,
         'onAddTransition must be provided when tool selection is enabled.',
       );

  final BaseGraphViewCanvasController<dynamic, dynamic> controller;
  final bool enableToolSelection;
  final bool showSelectionTool;
  final AutomatonCanvasTool activeTool;
  final VoidCallback? onSelectTool;
  final VoidCallback onAddState;
  final VoidCallback? onAddTransition;
  final VoidCallback? onClear;
  final String? statusMessage;
  final GraphViewCanvasToolbarLayout layout;

  @override
  State<GraphViewCanvasToolbar> createState() => _GraphViewCanvasToolbarState();
}

class _GraphViewCanvasToolbarState extends State<GraphViewCanvasToolbar> {
  @override
  void initState() {
    super.initState();
    widget.controller.graphRevision.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant GraphViewCanvasToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.graphRevision.removeListener(
        _handleControllerChanged,
      );
      widget.controller.graphRevision.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.graphRevision.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;
    final actions = <_ToolbarButtonConfig>[
      if (widget.enableToolSelection && widget.showSelectionTool)
        _ToolbarButtonConfig(
          action: _ToolbarAction.selection,
          handler: widget.onSelectTool,
          isToggle: true,
          isSelected: widget.activeTool == AutomatonCanvasTool.selection,
        ),
      _ToolbarButtonConfig(
        action: _ToolbarAction.addState,
        handler: widget.onAddState,
        isToggle: widget.enableToolSelection,
        isSelected:
            widget.enableToolSelection &&
            widget.activeTool == AutomatonCanvasTool.addState,
      ),
      if (widget.onAddTransition != null)
        _ToolbarButtonConfig(
          action: _ToolbarAction.transition,
          handler: widget.onAddTransition,
          isToggle: widget.enableToolSelection,
          isSelected:
              widget.enableToolSelection &&
              widget.activeTool == AutomatonCanvasTool.transition,
        ),
      _ToolbarButtonConfig(
        action: _ToolbarAction.redo,
        handler: controller.canRedo ? () => controller.redo() : null,
      ),
      _ToolbarButtonConfig(
        action: _ToolbarAction.fitContent,
        handler: controller.fitToContent,
      ),
      _ToolbarButtonConfig(
        action: _ToolbarAction.resetView,
        handler: controller.resetView,
      ),
      if (widget.onClear != null)
        _ToolbarButtonConfig(
          action: _ToolbarAction.clear,
          handler: widget.onClear!,
        ),
      _ToolbarButtonConfig(
        action: _ToolbarAction.undo,
        handler: controller.canUndo ? () => controller.undo() : null,
      ),
      _ToolbarButtonConfig(
        action: _ToolbarAction.help,
        handler: () => KeyboardShortcutsDialog.show(context),
      ),
    ];

    switch (widget.layout) {
      case GraphViewCanvasToolbarLayout.mobile:
        return _MobileToolbar(
          actions: actions,
          statusMessage: widget.statusMessage,
          theme: theme,
        );
      case GraphViewCanvasToolbarLayout.desktop:
        return _DesktopToolbar(
          actions: actions,
          statusMessage: widget.statusMessage,
          theme: theme,
        );
    }
  }
}

enum GraphViewCanvasToolbarLayout { desktop, mobile }

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
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in actions) ...[
                    Builder(
                      builder: (context) {
                        final isToggle = entry.isToggle;
                        final isSelected = entry.isSelected;
                        final iconStyle = IconButton.styleFrom(
                          backgroundColor: isToggle
                              ? (isSelected
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.18))
                              : null,
                          foregroundColor: isToggle
                              ? (isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: isToggle && !isSelected
                                ? BorderSide(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.55),
                                  )
                                : BorderSide.none,
                          ),
                        );
                        final helpContent = kHelpContent[entry.action.helpContentId];
                        final button = IconButton(
                          tooltip:
                              helpContent == null ? entry.action.label : null,
                          icon: Icon(entry.action.icon),
                          onPressed: entry.handler,
                          style: iconStyle,
                        );
                        return helpContent != null
                            ? ContextualHelpTooltip(
                                helpContent: helpContent,
                                child: button,
                              )
                            : button;
                      },
                    ),
                    if (entry != actions.last)
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                  ],
                ],
              ),
            ),
            if (statusMessage != null && statusMessage!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(statusMessage!, style: textTheme.bodySmall),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 400,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (statusMessage != null && statusMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(statusMessage!, style: textTheme.bodyMedium),
                ),
              Flexible(
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.surface,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final entry in actions)
                          Builder(
                            builder: (context) {
                              final helpContent = kHelpContent[entry.action.helpContentId];
                              final button = FilledButton.icon(
                                onPressed: entry.handler,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  backgroundColor: entry.isToggle && entry.isSelected
                                      ? colorScheme.primary
                                      : entry.isToggle
                                      ? colorScheme.surfaceContainerHighest
                                      : null,
                                  foregroundColor: entry.isToggle && entry.isSelected
                                      ? colorScheme.onPrimary
                                      : entry.isToggle
                                      ? colorScheme.onSurfaceVariant
                                      : null,
                                ),
                                icon: Icon(entry.action.icon),
                                label: Text(entry.action.label),
                              );
                              return helpContent != null
                                  ? ContextualHelpTooltip(
                                      helpContent: helpContent,
                                      child: button,
                                    )
                                  : button;
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButtonConfig {
  _ToolbarButtonConfig({
    required this.action,
    required this.handler,
    this.isToggle = false,
    this.isSelected = false,
  });

  final _ToolbarAction action;
  final VoidCallback? handler;
  final bool isToggle;
  final bool isSelected;
}

enum _ToolbarAction {
  selection(icon: Icons.pan_tool, label: 'Select', helpContentId: 'tool_select'),
  addState(icon: Icons.add, label: 'Add state', helpContentId: 'tool_add_state'),
  transition(icon: Icons.arrow_right_alt, label: 'Add transition', helpContentId: 'tool_add_transition'),
  undo(icon: Icons.undo, label: 'Undo', helpContentId: 'tool_undo'),
  redo(icon: Icons.redo, label: 'Redo', helpContentId: 'tool_redo'),
  fitContent(icon: Icons.fit_screen, label: 'Fit to content', helpContentId: 'tool_fit_content'),
  resetView(icon: Icons.center_focus_strong, label: 'Reset view', helpContentId: 'tool_reset_view'),
  clear(icon: Icons.delete_outline, label: 'Clear canvas', helpContentId: 'tool_clear'),
  help(icon: Icons.help_outline, label: 'Help & Shortcuts', helpContentId: 'shortcut_canvas_general');

  const _ToolbarAction({required this.icon, required this.label, required this.helpContentId});

  final IconData icon;
  final String label;
  final String helpContentId;
}
