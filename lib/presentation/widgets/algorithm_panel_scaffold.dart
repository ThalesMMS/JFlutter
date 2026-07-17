import 'package:flutter/material.dart';

import 'algorithm_panel_header.dart';

export 'algorithm_button_list.dart';
export 'algorithm_example_button.dart';
export 'algorithm_examples_section.dart';
export 'algorithm_panel_header.dart';
export 'algorithm_results_card.dart';
export 'algorithm_results_section.dart';

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
