import 'package:flutter/material.dart' hide ButtonStyle;

/// Visual variants available for [RetryButton].
enum ButtonStyle {
  /// High emphasis button used as the primary call to action.
  primary,

  /// Tonal variant that provides a softer emphasis compared to [primary].
  secondary,

  /// Outlined button variant that keeps emphasis without filling the background.
  outline,

  /// Text-only variant with minimal emphasis.
  text,
}

/// Button used to trigger retry flows across the application.
///
/// The widget centralises the UX expectations validated in
/// `ux_error_handling_test.dart`, including iconography, disabled and
/// loading states as well as multiple visual variants.
class RetryButton extends StatelessWidget {
  const RetryButton({
    super.key,
    this.text = 'Retry',
    this.onPressed,
    this.isLoading = false,
    this.style = ButtonStyle.primary,
  });

  /// Label displayed inside the button when not loading.
  final String text;

  /// Callback triggered when the user taps the button.
  final VoidCallback? onPressed;

  /// Whether the button should present a loading indicator instead of the
  /// regular icon.
  final bool isLoading;

  /// Visual style applied to the button.
  final ButtonStyle style;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = _isDisabled ? null : onPressed;
    final Widget icon = _buildIcon(context);
    final Text label = Text(isLoading ? 'Retrying...' : text);

    switch (style) {
      case ButtonStyle.primary:
        return FilledButton.icon(
          onPressed: effectiveOnPressed,
          icon: icon,
          label: label,
        );
      case ButtonStyle.secondary:
        return FilledButton.tonalIcon(
          onPressed: effectiveOnPressed,
          icon: icon,
          label: label,
        );
      case ButtonStyle.outline:
        return OutlinedButton.icon(
          onPressed: effectiveOnPressed,
          icon: icon,
          label: label,
        );
      case ButtonStyle.text:
        return TextButton.icon(
          onPressed: effectiveOnPressed,
          icon: icon,
          label: label,
        );
    }
  }

  Widget _buildIcon(BuildContext context) {
    if (!isLoading) {
      return const Icon(Icons.refresh, size: 18);
    }

    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
    );
  }
}
