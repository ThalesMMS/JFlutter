import 'package:flutter/material.dart';

import '../../providers/tm_metrics_controller.dart';

/// Panel displaying aggregated information about the current TM.
class TMMetricsPanel extends StatelessWidget {
  final TmMetricsState metrics;

  const TMMetricsPanel({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turing Machine Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor the structure of your machine and resolve issues before running simulations or algorithms.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('States', '${metrics.stateCount}', theme),
          _buildInfoRow('Transitions', '${metrics.transitionCount}', theme),
          _buildInfoRow('Tape Symbols', _formatSet(metrics.tapeSymbols), theme),
          _buildInfoRow('Move Directions', _formatSet(metrics.moveDirections), theme),
          _buildInfoRow(
            'Initial State',
            metrics.hasInitialState ? 'Yes' : 'No',
            theme,
          ),
          _buildInfoRow(
            'Accepting State',
            metrics.hasAcceptingState ? 'Yes' : 'No',
            theme,
          ),
          _buildInfoRow(
            'Simulation Ready',
            metrics.isMachineReady ? 'Yes' : 'No',
            theme,
          ),
          _buildInfoRow(
            'Nondeterministic Transitions',
            metrics.nondeterministicTransitionIds.isEmpty
                ? '0'
                : '${metrics.nondeterministicTransitionIds.length}',
            theme,
          ),
          if (metrics.nondeterministicTransitionIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Resolve nondeterminism before running deterministic algorithms.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    final textStyle = theme.textTheme.bodyMedium;
    final emphasizedStyle = textStyle?.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$label: $value',
        style: emphasizedStyle,
      ),
    );
  }

  String _formatSet(Set<String> values) {
    if (values.isEmpty) {
      return '-';
    }
    final sorted = values.toList()..sort();
    return sorted.join(', ');
  }
}
