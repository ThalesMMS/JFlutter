import 'package:flutter/material.dart';

class RegexTestSection extends StatelessWidget {
  const RegexTestSection({
    super.key,
    required this.controller,
    required this.matchResult,
    required this.matchMessage,
    required this.onChanged,
    required this.onTest,
  });

  final TextEditingController controller;
  final bool? matchResult;
  final String? matchMessage;
  final ValueChanged<String> onChanged;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasResult =
        matchResult != null || (matchMessage != null && matchMessage!.isNotEmpty);
    final isMatch = matchResult == true;
    final messageColor = isMatch ? Colors.green : Colors.red;
    final messageText = matchMessage?.isNotEmpty == true
        ? matchMessage!
        : isMatch
            ? 'Matches!'
            : 'Does not match';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test String:',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter string to test',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: onTest,
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Test String',
            ),
          ),
          onChanged: onChanged,
        ),
        if (hasResult) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isMatch ? Icons.check_circle : Icons.cancel,
                color: messageColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  messageText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: messageColor,
                    fontWeight: isMatch ? FontWeight.bold : FontWeight.w600,
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
