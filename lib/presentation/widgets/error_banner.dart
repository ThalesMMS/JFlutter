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
    required this.background,
    required this.foreground,
    required this.border,
    required this.icon,
    required this.semanticsLabel,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final IconData icon;
  final String semanticsLabel;
}

const Map<ErrorSeverity, _SeverityVisuals> _severityVisuals = {
  ErrorSeverity.error: _SeverityVisuals(
    background: Color(0xFFFFEBEE),
    foreground: Color(0xFFC62828),
    border: Color(0xFFB71C1C),
    icon: Icons.error_outline,
    semanticsLabel: 'Error banner',
  ),
  ErrorSeverity.warning: _SeverityVisuals(
    background: Color(0xFFFFF3E0),
    foreground: Color(0xFFE65100),
    border: Color(0xFFEF6C00),
    icon: Icons.warning_amber_rounded,
    semanticsLabel: 'Warning banner',
  ),
  ErrorSeverity.info: _SeverityVisuals(
    background: Color(0xFFE3F2FD),
    foreground: Color(0xFF1976D2),
    border: Color(0xFF1565C0),
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
  })  : assert(message.trim().isNotEmpty, 'message must not be empty'),
        severity = severity,
        showRetryButton = showRetryButton ?? (severity != ErrorSeverity.info),
        assert(
          !showRetryButton || onRetry != null,
          'onRetry must be provided when showRetryButton is true',
        ),
        assert(
          !showDismissButton || onDismiss != null,
          'onDismiss must be provided when showDismissButton is true',
        );

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

  @override
  Widget build(BuildContext context) {
    final visuals = _severityVisuals[severity]!;

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
              ? _buildVerticalContent(context, visuals, padding)
              : _buildHorizontalContent(context, visuals, padding);

          return DecoratedBox(
            decoration: BoxDecoration(
              color: visuals.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: visuals.border),
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
    EdgeInsets padding,
  ) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon ?? visuals.icon, color: visuals.foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: visuals.foreground,
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
              Icon(icon ?? visuals.icon, color: visuals.foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: visuals.foreground,
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
