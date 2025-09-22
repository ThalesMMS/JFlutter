import 'package:flutter/material.dart';

class RegexInputForm extends StatelessWidget {
  const RegexInputForm({
    super.key,
    required this.controller,
    required this.isValid,
    required this.validationMessage,
    required this.onChanged,
    required this.onValidate,
  });

  final TextEditingController controller;
  final bool isValid;
  final String? validationMessage;
  final ValueChanged<String> onChanged;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isValid ? Colors.green : Colors.red;
    final statusMessage = isValid
        ? 'Valid regex'
        : (validationMessage?.isNotEmpty == true
            ? validationMessage!
            : 'Invalid regex');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regular Expression:',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter regular expression (e.g., a*b+)',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: onValidate,
              icon: const Icon(Icons.check),
              tooltip: 'Validate Regex',
            ),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.error,
              color: statusColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: isValid ? FontWeight.bold : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
