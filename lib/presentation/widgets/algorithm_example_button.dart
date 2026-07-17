import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';

class AlgorithmExampleButton extends StatelessWidget {
  const AlgorithmExampleButton({
    super.key,
    required this.title,
    required this.isLoading,
    required this.onPressed,
  });

  final String title;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.file_open, size: 18),
        label: Text(
          appLocalizationsOf(context).localizeWorkflowText(title),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.secondary,
          side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
