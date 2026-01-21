//
//  error_banner.dart
//  JFlutter
//
//  Inline banner that communicates recoverable issues without hiding content.
//  Provides consistent error, warning, and info messaging with Material 3
//  styling, responsive layouts, and accessibility support. Integrates with
//  RetryButton for error recovery flows.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';

import 'retry_button.dart';

/// Severity levels supported by [ErrorBanner].
enum ErrorSeverity {
  /// Critical failure that requires immediate attention.
  error,

  /// Recoverable issue that should be addressed soon.
  warning,

  /// Informational notice that does not block the workflow.
  info,
}

class _SeverityVisuals {
  const _SeverityVisuals({
    required this.icon,
    required this.semanticsLabel,
  });

  final IconData icon;
  final String semanticsLabel;
}

class _SeverityColors {
  const _SeverityColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

const Map<ErrorSeverity, _SeverityVisuals> _severityVisuals = {
  ErrorSeverity.error: _SeverityVisuals(
    icon: Icons.error_outline,
    semanticsLabel: 'Error banner',
  ),
  ErrorSeverity.warning: _SeverityVisuals(
    icon: Icons.warning_amber_rounded,
    semanticsLabel: 'Warning banner',
  ),
  ErrorSeverity.info: _SeverityVisuals(
    icon: Icons.info_outline,
    semanticsLabel: 'Info banner',
  ),
};

/// Inline banner that communicates recoverable issues without hiding content.
class ErrorBanner extends StatelessWidget {
  ErrorBanner({
    super.key,
    required this.message,
    required ErrorSeverity severity,
    bool? showRetryButton,
    this.showDismissButton = true,
    this.onRetry,
    this.onDismiss,
    this.icon,
  })  : severity = severity,
        showRetryButton = showRetryButton ?? (severity != ErrorSeverity.info);

  /// Text communicated to the user about the failure.
  final String message;

  /// Determines the colour palette and icon.
  final ErrorSeverity severity;

  /// Whether to render the retry action.
  final bool showRetryButton;

  /// Whether to render the dismiss action.
  final bool showDismissButton;

  /// Invoked when the retry action is pressed.
  final VoidCallback? onRetry;

  /// Invoked when the dismiss action is pressed.
  final VoidCallback? onDismiss;

  /// Optional icon override.
  final IconData? icon;

  /// Derives Material 3 ColorScheme colors based on severity level.
  _SeverityColors _getColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (severity) {
      case ErrorSeverity.error:
        return _SeverityColors(
          background: colorScheme.errorContainer,
          foreground: colorScheme.onErrorContainer,
          border: colorScheme.error,
        );
      case ErrorSeverity.warning:
        return _SeverityColors(
          background: colorScheme.tertiaryContainer,
          foreground: colorScheme.onTertiaryContainer,
          border: colorScheme.tertiary,
        );
      case ErrorSeverity.info:
        return _SeverityColors(
          background: colorScheme.primaryContainer,
          foreground: colorScheme.onPrimaryContainer,
          border: colorScheme.primary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visuals = _severityVisuals[severity]!;
    final colors = _getColors(context);

    return Semantics(
      container: true,
      label: visuals.semanticsLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;
          final padding = EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 12 : 16,
          );

          final Widget content = isCompact
              ? _buildVerticalContent(context, visuals, colors, padding)
              : _buildHorizontalContent(context, visuals, colors, padding);

          return DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: content,
          );
        },
      ),
    );
  }

  Widget _buildHorizontalContent(
    BuildContext context,
    _SeverityVisuals visuals,
    _SeverityColors colors,
    EdgeInsets padding,
  ) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon ?? visuals.icon, color: colors.foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.foreground,
                  ),
            ),
          ),
          if (showRetryButton || showDismissButton)
            const SizedBox(width: 12),
          if (showRetryButton || showDismissButton)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (showRetryButton)
                  RetryButton(
                    onPressed: onRetry!,
                    label: 'Retry',
                  ),
                if (showDismissButton)
                  _DismissButton(onDismiss: onDismiss!),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalContent(
    BuildContext context,
    _SeverityVisuals visuals,
    _SeverityColors colors,
    EdgeInsets padding,
  ) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon ?? visuals.icon, color: colors.foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.foreground,
                      ),
                ),
              ),
            ],
          ),
          if (showRetryButton || showDismissButton) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (showRetryButton)
                  RetryButton(
                    onPressed: onRetry!,
                    label: 'Retry',
                  ),
                if (showDismissButton)
                  _DismissButton(onDismiss: onDismiss!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Dismiss message',
      button: true,
      child: TextButton.icon(
        onPressed: onDismiss,
        icon: const Icon(Icons.close, size: 18),
        label: const Text('Dismiss'),
      ),
    );
  }
}
