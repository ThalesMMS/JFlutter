import 'package:flutter/material.dart';

class AlgorithmActionButton extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isExecuting;
  final bool isCurrentAlgorithm;
  final double executionProgress;
  final String? executionStatus;

  const AlgorithmActionButton({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onPressed,
    this.isDestructive = false,
    this.isExecuting = false,
    this.isCurrentAlgorithm = false,
    this.executionProgress = 0.0,
    this.executionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;
    final isDisabled = (isExecuting && !isCurrentAlgorithm) || onPressed == null;

    return InkWell(
      onTap: isDisabled ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isCurrentAlgorithm ? color : color.withOpacity(0.3),
            width: isCurrentAlgorithm ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isCurrentAlgorithm
              ? color.withOpacity(0.1)
              : isDisabled
                  ? colorScheme.surfaceVariant.withOpacity(0.5)
                  : null,
        ),
        child: Row(
          children: [
            if (isCurrentAlgorithm && isExecuting)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(
                icon,
                color: isDisabled
                    ? colorScheme.outline.withOpacity(0.5)
                    : color,
                size: 24,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDisabled
                              ? colorScheme.outline.withOpacity(0.5)
                              : color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCurrentAlgorithm && executionStatus != null
                        ? executionStatus!
                        : description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDisabled
                              ? colorScheme.outline.withOpacity(0.5)
                              : colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            if (isCurrentAlgorithm && isExecuting)
              Text(
                '${(executionProgress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: isDisabled
                    ? colorScheme.outline.withOpacity(0.5)
                    : color.withOpacity(0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
