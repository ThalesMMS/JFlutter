//
//  algorithm_step_history_panel.dart
//  JFlutter
//
//  Painel de histórico de execução de algoritmos educacionais. Exibe lista
//  rolável de todos os passos executados, permitindo navegação direta por
//  clique. Destaca o passo atual e mostra informações resumidas (número,
//  título, timestamp) em formato Material 3 para facilitar revisão de traços
//  longos em conversões NFA→DFA, minimização e parsing CYK.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/algorithm_step.dart';
import '../providers/algorithm_step_provider.dart';

/// History panel widget for algorithm step-by-step execution.
///
/// This widget provides a scrollable list of all algorithm execution steps,
/// allowing users to review and navigate through the complete algorithm
/// execution history. Each step displays its number, title, and timestamp.
///
/// Features:
/// - Scrollable list of all steps with auto-scroll to current step
/// - Visual highlight of the currently active step
/// - Click to jump navigation for quick access to any step
/// - Timestamp display for temporal context
/// - Material 3 theming integration
/// - Accessibility semantics for screen readers
/// - Empty state handling
///
/// Example:
/// ```dart
/// AlgorithmStepHistoryPanel(
///   onStepSelected: (index) {
///     stepNotifier.jumpToStep(index);
///   },
/// )
/// ```
class AlgorithmStepHistoryPanel extends ConsumerStatefulWidget {
  /// Optional callback when a step is selected
  final ValueChanged<int>? onStepSelected;

  /// Whether the panel is compact (shows fewer details)
  final bool compact;

  const AlgorithmStepHistoryPanel({
    super.key,
    this.onStepSelected,
    this.compact = false,
  });

  @override
  ConsumerState<AlgorithmStepHistoryPanel> createState() =>
      _AlgorithmStepHistoryPanelState();
}

class _AlgorithmStepHistoryPanelState
    extends ConsumerState<AlgorithmStepHistoryPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls to the current step in the list
  void _scrollToCurrentStep(int currentStepIndex, int totalSteps) {
    if (!_scrollController.hasClients) return;

    // Estimate item height (card height + margin)
    final double estimatedItemHeight = widget.compact ? 60.0 : 80.0;
    final double targetPosition = currentStepIndex * estimatedItemHeight;

    // Scroll to position with animation
    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Formats a DateTime to HH:mm:ss format
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final algorithmStepState = ref.watch(algorithmStepProvider);
    final algorithmStepNotifier = ref.read(algorithmStepProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Empty state
    if (!algorithmStepState.hasSteps) {
      return _buildEmptyState(context, colorScheme, textTheme);
    }

    // Scroll to current step when it changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentStep(
        algorithmStepState.currentStepIndex,
        algorithmStepState.totalSteps,
      );
    });

    return Semantics(
      label: 'Algorithm execution history',
      hint: 'List of ${algorithmStepState.totalSteps} algorithm steps',
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, colorScheme, textTheme, algorithmStepState),

            const Divider(height: 1),

            // Steps list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: algorithmStepState.totalSteps,
                itemBuilder: (context, index) {
                  final step = algorithmStepState.steps[index];
                  final isCurrentStep =
                      index == algorithmStepState.currentStepIndex;

                  return _buildStepItem(
                    context,
                    colorScheme,
                    textTheme,
                    step,
                    index,
                    isCurrentStep,
                    () {
                      algorithmStepNotifier.jumpToStep(index);
                      widget.onStepSelected?.call(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the header section with title and step count
  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AlgorithmStepState state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.history, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Execution History',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${state.totalSteps} steps',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single step item in the list
  Widget _buildStepItem(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AlgorithmStep step,
    int index,
    bool isCurrentStep,
    VoidCallback onTap,
  ) {
    final stepNumber = index + 1;

    return Semantics(
      button: true,
      label: 'Step $stepNumber: ${step.title}',
      hint: isCurrentStep ? 'Current step' : 'Tap to jump to this step',
      selected: isCurrentStep,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentStep
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentStep
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: isCurrentStep ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Step number badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCurrentStep
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: textTheme.labelMedium?.copyWith(
                      color: isCurrentStep
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Step title and timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrentStep
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentStep
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                      maxLines: widget.compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!widget.compact) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: isCurrentStep
                                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(
                              step.properties?['timestamp'] as DateTime? ??
                                  DateTime.now(),
                            ),
                            style: textTheme.labelSmall?.copyWith(
                              color: isCurrentStep
                                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Current step indicator
              if (isCurrentStep) ...[
                const SizedBox(width: 8),
                Icon(Icons.play_arrow, size: 20, color: colorScheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the empty state when no steps are available
  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No steps available',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Run an algorithm to see execution history',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
