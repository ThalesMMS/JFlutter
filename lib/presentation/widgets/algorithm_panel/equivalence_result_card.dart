import 'package:flutter/material.dart';

class EquivalenceResultCard extends StatelessWidget {
  final bool? result;
  final String? details;

  const EquivalenceResultCard({
    super.key,
    required this.result,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = details ?? '';
    final Color accent;
    IconData icon;

    if (result == null) {
      accent = theme.colorScheme.secondary;
      icon = Icons.info_outline;
    } else if (result!) {
      accent = Colors.green;
      icon = Icons.check_circle;
    } else {
      accent = Colors.red;
      icon = Icons.cancel;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 8),
              Text(
                result == null
                    ? 'Equivalence comparison'
                    : result!
                        ? 'Automata are equivalent'
                        : 'Automata are not equivalent',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
