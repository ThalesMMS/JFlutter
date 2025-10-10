import 'package:flutter/material.dart' hide ButtonStyle;

import 'retry_button.dart';

/// Dialog used to present detailed information about an import failure.
class ImportErrorDialog extends StatelessWidget {
  const ImportErrorDialog({
    super.key,
    required this.title,
    required this.message,
    required this.details,
    required this.onRetry,
    required this.onCancel,
  });

  /// Short title describing the failure (displayed in the dialog header).
  final String title;

  /// Friendly explanation displayed at the top of the dialog content.
  final String message;

  /// Additional technical information intended to help the user resolve the
  /// issue.
  final String details;

  /// Callback triggered when the user decides to retry the import.
  final VoidCallback onRetry;

  /// Callback triggered when the user dismisses the dialog.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            details,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        RetryButton(onPressed: onRetry),
      ],
    );
  }
}
