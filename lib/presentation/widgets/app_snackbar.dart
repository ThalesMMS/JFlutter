import 'package:flutter/material.dart';

enum AppSnackBarTone { info, success, warning, error }

class _SnackBarPalette {
  const _SnackBarPalette({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}

void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackBarTone tone = AppSnackBarTone.info,
  Duration duration = const Duration(seconds: 2),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  assert(
    (actionLabel != null) == (onAction != null),
    'actionLabel and onAction must be provided together or both null',
  );

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }

  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  // Keep floating snack bars on Material container/onContainer pairs so the
  // custom presentation inherits the same contrast-safe combinations audited in
  // AppTheme for warning and error feedback.
  final palette = switch (tone) {
    AppSnackBarTone.success => _SnackBarPalette(
        icon: Icons.check_circle_outline,
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
      ),
    AppSnackBarTone.warning => _SnackBarPalette(
        icon: Icons.warning_amber_rounded,
        background: colorScheme.tertiaryContainer,
        foreground: colorScheme.onTertiaryContainer,
      ),
    AppSnackBarTone.error => _SnackBarPalette(
        icon: Icons.error_outline,
        background: colorScheme.errorContainer,
        foreground: colorScheme.onErrorContainer,
      ),
    AppSnackBarTone.info => _SnackBarPalette(
        icon: Icons.info_outline,
        background: colorScheme.surfaceContainerHighest,
        foreground: colorScheme.onSurface,
      ),
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.background,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(palette.icon, color: palette.foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.foreground,
                ),
              ),
            ),
          ],
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: palette.foreground,
                onPressed: onAction,
              )
            : null,
      ),
    );
}
