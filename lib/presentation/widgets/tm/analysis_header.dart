import 'package:flutter/material.dart';

class AnalysisHeader extends StatelessWidget {
  const AnalysisHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.auto_awesome, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'TM Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
