part of '../fsa_page.dart';

class _CanvasQuickActions extends StatelessWidget {
  const _CanvasQuickActions({this.onSimulate, this.onAlgorithms, this.onHelp});

  final VoidCallback? onSimulate;
  final VoidCallback? onAlgorithms;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(32),
      color: colorScheme.surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onHelp != null)
              IconButton(
                tooltip: 'Help',
                icon: const Icon(Icons.help_outline),
                onPressed: onHelp,
              ),
            if (onHelp != null && (onSimulate != null || onAlgorithms != null))
              const SizedBox(width: 4),
            if (onSimulate != null)
              IconButton(
                tooltip: 'Simulate',
                icon: const Icon(Icons.play_arrow),
                onPressed: onSimulate,
              ),
            if (onSimulate != null && onAlgorithms != null)
              const SizedBox(width: 4),
            if (onAlgorithms != null)
              IconButton(
                tooltip: 'Algorithms',
                icon: const Icon(Icons.auto_awesome),
                onPressed: onAlgorithms,
              ),
          ],
        ),
      ),
    );
  }
}
