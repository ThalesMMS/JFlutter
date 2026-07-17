import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';

class AlgorithmPanelHeader extends StatelessWidget {
  const AlgorithmPanelHeader({
    super.key,
    required this.title,
    this.icon = Icons.auto_awesome,
    this.showIcon = true,
  });

  final String title;
  final IconData icon;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      appLocalizationsOf(context).localizeWorkflowText(title),
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );

    if (!showIcon) {
      return titleText;
    }

    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: titleText),
      ],
    );
  }
}
