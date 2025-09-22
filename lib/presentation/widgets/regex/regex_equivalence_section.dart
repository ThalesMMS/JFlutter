import 'package:flutter/material.dart';

class RegexEquivalenceSection extends StatelessWidget {
  const RegexEquivalenceSection({
    super.key,
    required this.controller,
    required this.equivalenceResult,
    required this.equivalenceMessage,
    required this.onChanged,
    required this.onCompare,
  });

  final TextEditingController controller;
  final bool? equivalenceResult;
  final String? equivalenceMessage;
  final ValueChanged<String> onChanged;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMessage = equivalenceMessage?.isNotEmpty == true;
    final isEquivalent = equivalenceResult == true;
    final messageColor = isEquivalent ? Colors.green : Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compare Regular Expressions:',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter second regular expression',
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: onCompare,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Compare Equivalence'),
          ),
        ),
        if (hasMessage) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isEquivalent ? Icons.check_circle : Icons.error_outline,
                color: messageColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  equivalenceMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: messageColor,
                    fontWeight: isEquivalent ? FontWeight.bold : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
