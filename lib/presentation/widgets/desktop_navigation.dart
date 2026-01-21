import 'package:flutter/material.dart';

import 'mobile_navigation.dart';

/// Desktop-optimized navigation rail mirroring the mobile navigation items.
class DesktopNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationItem> items;
  final bool extended;

  const DesktopNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.items,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationRail(
      selectedIndex: currentIndex,
      groupAlignment: -1,
      extended: extended,
      minWidth: 80,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
      ),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        fontSize: 12,
      ),
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Tooltip(
              waitDuration: const Duration(milliseconds: 250),
              message: item.description,
              child: Icon(item.icon),
            ),
            selectedIcon: Tooltip(
              waitDuration: const Duration(milliseconds: 150),
              message: item.description,
              child: Icon(item.icon),
            ),
            label: Text(item.label),
          ),
      ],
      onDestinationSelected: onDestinationSelected,
    );
  }
}
