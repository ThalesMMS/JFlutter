//
//  help_category_page.dart
//  JFlutter
//
//  Lists help content items for a single category, allowing users to explore
//  related concepts directly from context-aware help panels.
//
//  Thales Matheus Mendonça Santos - February 2026
//
import 'package:flutter/material.dart';

import '../../core/constants/help_content.dart';
import '../../core/models/help_content_model.dart';
import '../widgets/help_icon_mapper.dart';

class HelpCategoryPage extends StatelessWidget {
  const HelpCategoryPage({
    super.key,
    required this.category,
    required this.results,
  });

  final String category;
  final List<HelpContentModel> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sortedResults = [...results]
      ..sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      appBar: AppBar(
        title: Text('Help: ${_formatCategory(category)}'),
      ),
      body: sortedResults.isEmpty
          ? _EmptyState(category: category)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sortedResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final result = sortedResults[index];
                return Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    leading: Icon(
                      helpIconData(result.icon),
                      color: colorScheme.primary,
                    ),
                    title: Text(result.title),
                    subtitle: Text(
                      result.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _showHelpDialog(context, result),
                  ),
                );
              },
            ),
    );
  }

  String _formatCategory(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'General';
    }
    final normalized = trimmed.replaceAll('_', ' ');
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  void _showHelpDialog(BuildContext context, HelpContentModel helpContent) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                helpIconData(helpContent.icon),
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(helpContent.title)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(helpContent.content),
                if (helpContent.relatedConcepts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Related Concepts:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: helpContent.relatedConcepts.map((concept) {
                      final label = kHelpContent[concept]?.title ?? concept;
                      return Chip(
                        label: Text(label),
                        labelStyle: theme.textTheme.bodySmall,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline,
              size: 56,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No help items found for "$category".',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
