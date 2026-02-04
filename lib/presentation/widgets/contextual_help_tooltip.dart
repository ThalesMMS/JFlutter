//
//  contextual_help_tooltip.dart
//  JFlutter
//
//  Widget que envolve componentes da interface com tooltips de ajuda contextual,
//  exibindo conteúdo explicativo baseado no HelpContentModel quando o usuário
//  interage com elementos da UI. Respeita a configuração showTooltips do
//  aplicativo e fornece indicadores visuais opcionais de disponibilidade de ajuda.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/help_content_model.dart';
import '../../core/models/settings_model.dart';
import '../providers/settings_provider.dart';
import 'help_icon_mapper.dart';

/// Widget that wraps a child component with contextual help tooltip.
///
/// Displays help content from [HelpContentModel] when the user interacts
/// with the wrapped widget. Respects the [SettingsModel.showTooltips]
/// preference and optionally shows a help indicator icon.
class ContextualHelpTooltip extends ConsumerWidget {
  const ContextualHelpTooltip({
    super.key,
    required this.helpContent,
    required this.child,
    this.showHelpIndicator = false,
    this.onHelpPressed,
  });

  /// The help content to display in the tooltip.
  final HelpContentModel helpContent;

  /// The widget to wrap with the help tooltip.
  final Widget child;

  /// Whether to show a visual indicator that help is available.
  final bool showHelpIndicator;

  /// Optional callback when help indicator is pressed.
  /// If null and showHelpIndicator is true, shows a tooltip on tap.
  final VoidCallback? onHelpPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If tooltips are disabled, return the child without wrapping
    if (!settings.showTooltips) {
      return child;
    }

    Widget wrappedChild = Tooltip(
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: '${helpContent.title}\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          TextSpan(
            text: helpContent.content,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 500),
      child: child,
    );

    // If help indicator is requested, wrap in a stack with help icon
    if (showHelpIndicator) {
      wrappedChild = Stack(
        clipBehavior: Clip.none,
        children: [
          wrappedChild,
          Positioned(
            right: -4,
            top: -4,
            child: Semantics(
              label: 'Show help for ${helpContent.title}',
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onHelpPressed ?? () => _showHelpDialog(context),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      helpIconData(helpContent.icon),
                      size: 12,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return wrappedChild;
  }

  /// Shows a dialog with full help content.
  void _showHelpDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                helpIconData(helpContent.icon),
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(helpContent.title),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(helpContent.content),
                if (helpContent.relatedConcepts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Related Concepts:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: helpContent.relatedConcepts.map((concept) {
                      return Chip(
                        label: Text(_formatConceptId(concept)),
                        labelStyle: theme.textTheme.bodySmall,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatConceptId(String id) {
    return id
        .replaceAll(RegExp(r'^(tool|concept)_'), '')
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

}
