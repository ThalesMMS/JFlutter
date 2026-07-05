import 'package:flutter/material.dart';

import '../../core/result.dart';
import '../../data/data_sources/examples_asset_data_source.dart';
import 'common/algorithm_button.dart';
import 'common/algorithm_button_config.dart';

class AlgorithmPanelScaffold extends StatelessWidget {
  const AlgorithmPanelScaffold({
    super.key,
    required this.title,
    required this.children,
    this.icon = Icons.auto_awesome,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 16,
    this.showHeaderIcon = true,
    this.paddingInsideScroll = true,
  });

  final String title;
  final List<Widget> children;
  final IconData icon;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final bool showHeaderIcon;
  final bool paddingInsideScroll;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AlgorithmPanelHeader(
          title: title,
          icon: icon,
          showIcon: showHeaderIcon,
        ),
        for (final child in children) ...[
          SizedBox(height: spacing),
          child,
        ],
      ],
    );

    return Card(
      child: paddingInsideScroll
          ? SingleChildScrollView(padding: padding, child: content)
          : Padding(
              padding: padding,
              child: SingleChildScrollView(child: content),
            ),
    );
  }
}

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
      title,
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

class AlgorithmButtonList extends StatelessWidget {
  const AlgorithmButtonList({
    super.key,
    required this.configs,
    this.spacing = 12,
  });

  final List<AlgorithmButtonConfig> configs;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < configs.length; index++) ...[
          AlgorithmButton.fromConfig(configs[index]),
          if (index < configs.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}

class AlgorithmResultsSection extends StatelessWidget {
  const AlgorithmResultsSection({
    super.key,
    required this.hasResults,
    required this.empty,
    required this.results,
    this.title = 'Analysis Results',
  });

  final bool hasResults;
  final Widget empty;
  final Widget results;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (hasResults) results else empty,
      ],
    );
  }
}

class AlgorithmResultsCard extends StatelessWidget {
  const AlgorithmResultsCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class AlgorithmExamplesSection<T> extends StatelessWidget {
  const AlgorithmExamplesSection({
    super.key,
    required this.examplesFuture,
    required this.loadingExampleName,
    required this.onExampleSelected,
    required this.failureMessage,
    required this.emptyMessage,
    this.title = 'Load Examples',
  });

  final Future<ListResult<AssetExample<T>>> examplesFuture;
  final String? loadingExampleName;
  final ValueChanged<String> onExampleSelected;
  final String failureMessage;
  final String emptyMessage;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<ListResult<AssetExample<T>>>(
          future: examplesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              );
            }

            final result = snapshot.data;
            if (result == null || result.isFailure) {
              return Text(
                result?.error ?? failureMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              );
            }

            final examples = result.data!;
            if (examples.isEmpty) {
              return Text(emptyMessage, style: theme.textTheme.bodySmall);
            }

            return Column(
              children: examples
                  .map(
                    (example) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ExampleButton(
                        title: example.name,
                        isLoading: loadingExampleName == example.name,
                        onPressed: loadingExampleName == null
                            ? () => onExampleSelected(example.name)
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ExampleButton extends StatelessWidget {
  const _ExampleButton({
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
          title,
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
