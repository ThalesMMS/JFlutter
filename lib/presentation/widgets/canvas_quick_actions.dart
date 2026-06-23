import 'package:flutter/material.dart';

class CanvasQuickActions extends StatelessWidget {
  const CanvasQuickActions({
    super.key,
    this.onHelp,
    this.onSimulate,
    this.onAlgorithms,
    this.onMetrics,
  });

  final VoidCallback? onHelp;
  final VoidCallback? onSimulate;
  final VoidCallback? onAlgorithms;
  final VoidCallback? onMetrics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = <Widget>[
      if (onHelp != null)
        IconButton(
          tooltip: 'Help',
          icon: const Icon(Icons.help_outline),
          onPressed: onHelp,
        ),
      if (onSimulate != null)
        IconButton(
          tooltip: 'Simulate',
          icon: const Icon(Icons.play_arrow),
          onPressed: onSimulate,
        ),
      if (onAlgorithms != null)
        IconButton(
          tooltip: 'Algorithms',
          icon: const Icon(Icons.auto_awesome),
          onPressed: onAlgorithms,
        ),
      if (onMetrics != null)
        IconButton(
          tooltip: 'Metrics',
          icon: const Icon(Icons.bar_chart),
          onPressed: onMetrics,
        ),
    ];

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(32),
      color: colorScheme.surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }
}
