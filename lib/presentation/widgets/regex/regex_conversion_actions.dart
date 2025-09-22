import 'package:flutter/material.dart';

class RegexConversionActions extends StatelessWidget {
  const RegexConversionActions({
    super.key,
    required this.enableConversion,
    required this.onConvertToNfa,
    required this.onConvertToDfa,
  });

  final bool enableConversion;
  final VoidCallback onConvertToNfa;
  final VoidCallback onConvertToDfa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Convert to Automaton:',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: enableConversion ? onConvertToNfa : null,
                icon: const Icon(Icons.account_tree),
                label: const Text('Convert to NFA'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: enableConversion ? onConvertToDfa : null,
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('Convert to DFA'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
