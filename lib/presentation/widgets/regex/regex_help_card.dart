import 'package:flutter/material.dart';

class RegexHelpCard extends StatelessWidget {
  const RegexHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Regex Help',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Common patterns:\n'
              '• a* - zero or more a\'s\n'
              '• a+ - one or more a\'s\n'
              '• a? - zero or one a\n'
              '• a|b - a or b\n'
              '• (ab)* - zero or more ab\'s\n'
              '• [abc] - any of a, b, or c',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
