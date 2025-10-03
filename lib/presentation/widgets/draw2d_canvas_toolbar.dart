import 'package:flutter/material.dart';

/// Lightweight toolbar shown on top of the canvas when Draw2D features were
/// available. The widget now exposes a minimalist surface with optional
/// callbacks so existing overlays keep rendering while the Flutter canvas
/// migration progresses.
class Draw2DCanvasToolbar extends StatelessWidget {
  const Draw2DCanvasToolbar({
    super.key,
    this.onClear,
    this.statusMessage = 'Native canvas controls active',
  });

  /// Invoked when the user taps the clear icon.
  final VoidCallback? onClear;

  /// Optional status message rendered under the toolbar.
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    if (onClear == null && statusMessage == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final toolbar = onClear == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onClear,
                ),
              ],
            ),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (toolbar != null) toolbar,
        if (statusMessage != null && statusMessage!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: toolbar != null ? 6 : 0),
            child: Text(
              statusMessage!,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
