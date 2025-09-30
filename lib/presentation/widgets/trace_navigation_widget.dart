import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trace_navigation_provider.dart';

/// Widget for navigating through simulation traces and steps
class TraceNavigationWidget extends ConsumerWidget {
  final bool showTraceHistory;
  final bool showStepControls;
  final bool showExportImport;
  final VoidCallback? onTraceChanged;

  const TraceNavigationWidget({
    super.key,
    this.showTraceHistory = true,
    this.showStepControls = true,
    this.showExportImport = true,
    this.onTraceChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(traceNavigationProvider);
    final notifier = ref.read(traceNavigationProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with current trace info
            _buildHeader(context, state),
            const SizedBox(height: 16),

            // Step navigation controls
            if (showStepControls && state.hasCurrentTrace) ...[
              _buildStepControls(context, state, notifier),
              const SizedBox(height: 16),
            ],

            // Progress indicator
            if (state.hasCurrentTrace) ...[
              _buildProgressIndicator(context, state),
              const SizedBox(height: 16),
            ],

            // Trace history
            if (showTraceHistory) ...[
              _buildTraceHistory(context, state, notifier),
              const SizedBox(height: 16),
            ],

            // Export/Import controls
            if (showExportImport) ...[
              _buildExportImportControls(context, state, notifier),
            ],

            // Error display
            if (state.error != null) ...[
              const SizedBox(height: 16),
              _buildErrorDisplay(context, state, notifier),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TraceNavigationState state) {
    return Row(
      children: [
        Icon(Icons.timeline, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trace Navigation',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (state.hasCurrentTrace) ...[
                const SizedBox(height: 4),
                Text(
                  state.navigationSummary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (state.isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildStepControls(
    BuildContext context,
    TraceNavigationState state,
    TraceNavigationNotifier notifier,
  ) {
    return Row(
      children: [
        IconButton(
          onPressed: state.canGoToPreviousStep
              ? notifier.goToPreviousStep
              : null,
          icon: const Icon(Icons.skip_previous),
          tooltip: 'Previous Step',
        ),
        IconButton(
          onPressed: state.canGoToPreviousStep ? notifier.goToFirstStep : null,
          icon: const Icon(Icons.first_page),
          tooltip: 'First Step',
        ),
        Expanded(
          child: Center(
            child: Text(
              'Step ${state.currentStepIndex + 1} of ${state.totalSteps}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        IconButton(
          onPressed: state.canGoToNextStep ? notifier.goToLastStep : null,
          icon: const Icon(Icons.last_page),
          tooltip: 'Last Step',
        ),
        IconButton(
          onPressed: state.canGoToNextStep ? notifier.goToNextStep : null,
          icon: const Icon(Icons.skip_next),
          tooltip: 'Next Step',
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    TraceNavigationState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress', style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${(state.progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: state.progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            state.currentTrace?.accepted == true
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTraceHistory(
    BuildContext context,
    TraceNavigationState state,
    TraceNavigationNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trace History',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (state.traceHistory.isNotEmpty)
              TextButton(
                onPressed: notifier.clearAllTraces,
                child: const Text('Clear All'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (state.traceHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No trace history available',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: state.traceHistory.length,
              itemBuilder: (context, index) {
                final entry = state.traceHistory[index];
                final isCurrent = index == state.currentTraceIndex;

                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      entry.accepted ? Icons.check_circle : Icons.cancel,
                      color: entry.accepted ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    title: Text(
                      'Input: ${entry.inputString}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isCurrent ? FontWeight.w600 : null,
                      ),
                    ),
                    subtitle: Text(
                      '${entry.stepCount} steps • ${_formatTimestamp(entry.timestamp)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'load':
                            await notifier.loadTrace(entry.trace);
                            onTraceChanged?.call();
                            break;
                          case 'export':
                            await notifier.exportCurrentTrace();
                            break;
                          case 'delete':
                            await notifier.deleteCurrentTrace();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'load',
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow, size: 16),
                              SizedBox(width: 8),
                              Text('Load'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 16),
                              SizedBox(width: 8),
                              Text('Export'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: isCurrent
                        ? null
                        : () async {
                            await notifier.loadTrace(entry.trace);
                            onTraceChanged?.call();
                          },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildExportImportControls(
    BuildContext context,
    TraceNavigationState state,
    TraceNavigationNotifier notifier,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: state.hasCurrentTrace
                ? () async {
                    final path = await notifier.exportCurrentTrace();
                    if (path != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Trace exported to: $path')),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.upload),
            label: const Text('Export'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              // TODO: Implement file picker for import
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Import functionality coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Import'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDisplay(
    BuildContext context,
    TraceNavigationState state,
    TraceNavigationNotifier notifier,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            onPressed: notifier.clearError,
            icon: const Icon(Icons.close, size: 16),
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Compact version of trace navigation for smaller spaces
class CompactTraceNavigationWidget extends ConsumerWidget {
  final VoidCallback? onTraceChanged;

  const CompactTraceNavigationWidget({super.key, this.onTraceChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(traceNavigationProvider);
    final notifier = ref.read(traceNavigationProvider.notifier);

    if (!state.hasCurrentTrace) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.currentTrace?.accepted == true
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(state.progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Step controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: state.canGoToPreviousStep
                      ? notifier.goToPreviousStep
                      : null,
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 20,
                  tooltip: 'Previous Step',
                ),
                Text(
                  '${state.currentStepIndex + 1}/${state.totalSteps}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
                IconButton(
                  onPressed: state.canGoToNextStep
                      ? notifier.goToNextStep
                      : null,
                  icon: const Icon(Icons.skip_next),
                  iconSize: 20,
                  tooltip: 'Next Step',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
