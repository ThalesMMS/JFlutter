//
//  algorithm_panel_header.dart
//  JFlutter
//
//  Reusable header component for algorithm analysis panels. Displays a
//  consistent icon + title layout with primary theme colors to reduce
//  duplication across DFA, PDA, TM, and grammar algorithm panels.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';

/// Header widget for algorithm analysis panels.
///
/// Displays an icon and title in a horizontal layout following the pattern
/// established in algorithm_panel.dart, pda_algorithm_panel.dart,
/// tm_algorithm_panel.dart, and grammar_algorithm_panel.dart.
///
/// The icon uses the primary color from the current theme, and the title
/// uses titleLarge text style with bold weight.
///
/// Example:
/// ```dart
/// AlgorithmPanelHeader(
///   title: 'PDA Analysis',
///   icon: Icons.auto_awesome,
/// )
/// ```
class AlgorithmPanelHeader extends StatelessWidget {
  const AlgorithmPanelHeader({
    super.key,
    required this.title,
    this.icon = Icons.auto_awesome,
  }) : assert(title != '', 'title must not be empty');

  /// The title text displayed in the header.
  final String title;

  /// The icon displayed before the title.
  ///
  /// Defaults to Icons.auto_awesome if not specified.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
