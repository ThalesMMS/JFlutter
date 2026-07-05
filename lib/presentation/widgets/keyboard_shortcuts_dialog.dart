import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/help_content.dart';
import '../../core/models/help_content_model.dart';
import '../../l10n/app_localizations_help.dart';

/// Dialog displaying all keyboard shortcuts organized by context category.
///
/// Shows shortcuts for canvas operations, simulation controls, and dialog
/// interactions in a clean, scannable layout. Uses Material 3 design with
/// grouped sections and clear key-action mappings.
class KeyboardShortcutsDialog extends ConsumerWidget {
  const KeyboardShortcutsDialog({super.key});

  /// Show the keyboard shortcuts dialog.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const KeyboardShortcutsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = jflapLocalizationsOf(context);

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) {
              Navigator.of(context).pop();
              return null;
            },
          ),
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Semantics(
            namesRoute: true,
            label: l10n.keyboardShortcutsDialogLabel,
            child: AlertDialog(
              clipBehavior: Clip.antiAlias,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              title: _DialogTitle(theme: theme),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShortcutSection(
                        title: l10n.keyboardShortcutsCanvasOperations,
                        icon: Icons.edit,
                        color: theme.colorScheme.primary,
                        helpContent: l10n.localizeHelpContent(
                          kHelpContent['shortcut_canvas_general']!,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ShortcutSection(
                        title: l10n.keyboardShortcutsSimulationControls,
                        icon: Icons.play_arrow,
                        color: theme.colorScheme.secondary,
                        helpContent: l10n.localizeHelpContent(
                          kHelpContent['shortcut_simulation']!,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ShortcutSection(
                        title: l10n.keyboardShortcutsDialogShortcuts,
                        icon: Icons.chat_bubble_outline,
                        color: theme.colorScheme.tertiary,
                        helpContent: l10n.localizeHelpContent(
                          kHelpContent['shortcut_dialogs']!,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              actions: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(0.0),
                  child: Semantics(
                    label: l10n.closeShortcutsDialog,
                    button: true,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                      ),
                      child: Text(l10n.close),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.keyboard,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            jflapLocalizationsOf(context).keyboardShortcutsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShortcutSection extends StatelessWidget {
  const _ShortcutSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.helpContent,
  });

  final String title;
  final IconData icon;
  final Color color;
  final HelpContentModel helpContent;

  List<_ShortcutItem> _parseShortcuts(String content) {
    final shortcuts = <_ShortcutItem>[];
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.endsWith(':')) continue;

      // Remove leading bullet (•)
      final cleaned =
          trimmed.startsWith('•') ? trimmed.substring(1).trim() : trimmed;

      // Split on first colon to get key and description
      final colonIndex = cleaned.indexOf(':');
      if (colonIndex == -1) continue;

      final keys = cleaned.substring(0, colonIndex).trim();
      final description = cleaned.substring(colonIndex + 1).trim();

      shortcuts.add(_ShortcutItem(keys: keys, description: description));
    }

    return shortcuts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortcuts = _parseShortcuts(helpContent.content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Shortcuts list
        Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < shortcuts.length; i++) ...[
                _ShortcutRow(
                  shortcut: shortcuts[i],
                  color: color,
                ),
                if (i < shortcuts.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: color.withValues(alpha: 0.1),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ShortcutItem {
  const _ShortcutItem({
    required this.keys,
    required this.description,
  });

  final String keys;
  final String description;
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.shortcut,
    required this.color,
  });

  final _ShortcutItem shortcut;
  final Color color;

  List<String> _splitKeys(BuildContext context, String keys) {
    final separator =
        ' ${jflapLocalizationsOf(context).shortcutAlternativeSeparator} ';
    if (keys.contains(separator)) {
      return keys.split(separator).map((k) => k.trim()).toList();
    }
    return [keys];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = jflapLocalizationsOf(context);
    final keyGroups = _splitKeys(context, shortcut.keys);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Keys column
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < keyGroups.length; i++) ...[
                  _KeyChip(keyText: keyGroups[i], color: color),
                  if (i < keyGroups.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        l10n.shortcutAlternativeSeparator,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Description column
          Expanded(
            flex: 3,
            child: Text(
              shortcut.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyChip extends StatelessWidget {
  const _KeyChip({
    required this.keyText,
    required this.color,
  });

  final String keyText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        keyText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
