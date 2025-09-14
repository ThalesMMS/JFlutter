import 'package:flutter/material.dart';

/// Mobile-optimized navigation widget
class MobileNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationItem> items;

  const MobileNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == index;
              
              return Expanded(
                child: _buildNavigationItem(
                  context,
                  item,
                  isSelected,
                  () => onTap(index),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    NavigationItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation item data class
class NavigationItem {
  final String label;
  final IconData icon;
  final String? tooltip;

  const NavigationItem({
    required this.label,
    required this.icon,
    this.tooltip,
  });
}

/// Mobile-optimized tab bar that switches between bottom navigation and regular tabs
class ResponsiveTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<Widget> tabs;
  final bool isScrollable;
  final bool useBottomNavigation;

  const ResponsiveTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.isScrollable = false,
    this.useBottomNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useBottomNavigation) {
      return const SizedBox.shrink(); // Bottom navigation is handled separately
    }
    
    return TabBar(
      controller: controller,
      isScrollable: isScrollable,
      tabs: tabs,
      labelStyle: TextStyle(
        fontSize: isScrollable ? 14 : 16,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: isScrollable ? 12 : 14,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

/// Mobile-optimized page view that works with bottom navigation
class MobilePageView extends StatelessWidget {
  final PageController controller;
  final List<Widget> children;
  final ValueChanged<int>? onPageChanged;

  const MobilePageView({
    super.key,
    required this.controller,
    required this.children,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller,
      // Disable swipe navigation to avoid conflicts with canvas pan/zoom
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: onPageChanged,
      children: children,
    );
  }
}

/// Mobile-optimized app bar that adapts to screen size
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const ResponsiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: isMobile ? 18 : 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      elevation: isMobile ? 2 : 4,
      centerTitle: isMobile,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
