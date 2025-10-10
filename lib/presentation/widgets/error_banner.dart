import 'package:flutter/material.dart' hide ButtonStyle;

import 'retry_button.dart';

/// Inline banner that communicates import or execution failures.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  /// Error message displayed in the banner body.
  final String message;

  /// Optional callback triggered when the user selects the retry action.
  final VoidCallback? onRetry;

  /// Optional callback triggered when the user dismisses the banner.
  final VoidCallback? onDismiss;

  bool get _showActions => onRetry != null || onDismiss != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.error.withOpacity(0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  if (_showActions) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (onRetry != null)
                          RetryButton(
                            onPressed: onRetry,
                            style: ButtonStyle.secondary,
                          ),
                        if (onDismiss != null)
                          TextButton.icon(
                            onPressed: onDismiss,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Dismiss'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
