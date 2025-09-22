import 'package:flutter/material.dart';

import '../../providers/tm_algorithm_view_model.dart';

class FocusSelector extends StatelessWidget {
  const FocusSelector({
    super.key,
    required this.isAnalyzing,
    required this.selectedFocus,
    required this.onFocusSelected,
  });

  final bool isAnalyzing;
  final TMAnalysisFocus? selectedFocus;
  final Future<void> Function(TMAnalysisFocus focus) onFocusSelected;

  static const _focusOptions = [
    (
      focus: TMAnalysisFocus.decidability,
      title: 'Check Decidability',
      description: 'Verify halting states and potential infinite loops',
      icon: Icons.help_outline,
    ),
    (
      focus: TMAnalysisFocus.reachability,
      title: 'Find Reachable States',
      description: 'Identify which states can be reached from the start',
      icon: Icons.explore,
    ),
    (
      focus: TMAnalysisFocus.language,
      title: 'Language Analysis',
      description: 'Inspect accepting structure and transition coverage',
      icon: Icons.analytics,
    ),
    (
      focus: TMAnalysisFocus.tape,
      title: 'Tape Operations',
      description: 'Review read/write symbols and head movements',
      icon: Icons.storage,
    ),
    (
      focus: TMAnalysisFocus.time,
      title: 'Time Characteristics',
      description: 'Understand analysis runtime and processed elements',
      icon: Icons.timer,
    ),
    (
      focus: TMAnalysisFocus.space,
      title: 'Space Characteristics',
      description: 'Assess tape alphabet and movement coverage',
      icon: Icons.memory,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _focusOptions.length; i++) ...[
          _FocusButton(
            option: _focusOptions[i],
            isSelected: selectedFocus == _focusOptions[i].focus,
            isAnalyzing: isAnalyzing,
            onPressed: () => onFocusSelected(_focusOptions[i].focus),
          ),
          if (i != _focusOptions.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _FocusButton extends StatelessWidget {
  const _FocusButton({
    required this.option,
    required this.isSelected,
    required this.isAnalyzing,
    required this.onPressed,
  });

  final ({
    TMAnalysisFocus focus,
    String title,
    String description,
    IconData icon,
  }) option;
  final bool isSelected;
  final bool isAnalyzing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isAnalyzing ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isAnalyzing
                ? colorScheme.outline.withOpacity(0.3)
                : isSelected
                    ? colorScheme.primary
                    : colorScheme.primary.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: isAnalyzing
              ? colorScheme.surfaceVariant.withOpacity(0.5)
              : isSelected
                  ? colorScheme.primaryContainer.withOpacity(0.35)
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              color: isAnalyzing ? colorScheme.outline : colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isAnalyzing
                              ? colorScheme.outline
                              : colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            if (isAnalyzing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.primary.withOpacity(0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
