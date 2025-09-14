import 'package:flutter/material.dart';

/// Common UI components for consistent interface across the app
class CommonUIComponents {
  // Common padding values
  static const double mobilePadding = 12.0;
  static const double desktopPadding = 16.0;
  static const double cardPadding = 16.0;
  static const double buttonSpacing = 8.0;
  static const double sectionSpacing = 16.0;

  // Common border radius
  static const double borderRadius = 8.0;
  static const double cardBorderRadius = 12.0;

  // Common colors
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return EdgeInsets.all(isMobile ? mobilePadding : desktopPadding);
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, {double? mobile, double? desktop}) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (isMobile) {
      return mobile ?? 14.0;
    } else {
      return desktop ?? 16.0;
    }
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return isMobile ? 20.0 : 24.0;
  }
}

/// Standardized button widget
class StandardButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool isFullWidth;
  final bool isLoading;

  const StandardButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.style,
    this.isFullWidth = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    Widget button = ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
        ? SizedBox(
            width: CommonUIComponents.getResponsiveIconSize(context),
            height: CommonUIComponents.getResponsiveIconSize(context),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          )
        : Icon(icon, size: CommonUIComponents.getResponsiveIconSize(context)),
      label: Text(
        text,
        style: TextStyle(
          fontSize: CommonUIComponents.getResponsiveFontSize(context),
        ),
      ),
      style: style ?? ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: isMobile ? 12 : 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CommonUIComponents.borderRadius),
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

/// Standardized card widget
class StandardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;

  const StandardCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2,
      margin: margin ?? EdgeInsets.zero,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CommonUIComponents.cardBorderRadius),
      ),
      child: Padding(
        padding: padding ?? CommonUIComponents.getResponsivePadding(context),
        child: child,
      ),
    );
  }
}

/// Standardized section header
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget>? actions;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Padding(
      padding: EdgeInsets.only(bottom: CommonUIComponents.sectionSpacing),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: CommonUIComponents.getResponsiveIconSize(context),
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: isMobile ? 8 : 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: CommonUIComponents.getResponsiveFontSize(
                      context,
                      mobile: 18,
                      desktop: 20,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: CommonUIComponents.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        desktop: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...[
            SizedBox(width: isMobile ? 8 : 12),
            ...actions!,
          ],
        ],
      ),
    );
  }
}

/// Standardized status indicator
class StatusIndicator extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final IconData? icon;

  const StatusIndicator({
    super.key,
    required this.isSuccess,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? CommonUIComponents.successColor : CommonUIComponents.errorColor;
    final defaultIcon = isSuccess ? Icons.check_circle : Icons.error;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(CommonUIComponents.borderRadius),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? defaultIcon,
            color: color,
            size: CommonUIComponents.getResponsiveIconSize(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: CommonUIComponents.getResponsiveFontSize(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standardized loading indicator
class StandardLoadingIndicator extends StatelessWidget {
  final String? message;
  final double? size;

  const StandardLoadingIndicator({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: CommonUIComponents.getResponsiveFontSize(context),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Standardized empty state widget
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: CommonUIComponents.getResponsivePadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: CommonUIComponents.getResponsiveFontSize(
                  context,
                  mobile: 18,
                  desktop: 20,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: CommonUIComponents.getResponsiveFontSize(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Standardized responsive layout
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= 1024 && desktop != null) {
      return desktop!;
    } else if (width >= 768 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

/// Standardized tab bar with responsive design
class ResponsiveTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<Tab> tabs;
  final bool isScrollable;

  const ResponsiveTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return TabBar(
      controller: controller,
      tabs: tabs,
      isScrollable: isScrollable || isMobile,
      labelStyle: TextStyle(
        fontSize: CommonUIComponents.getResponsiveFontSize(
          context,
          mobile: 12,
          desktop: 14,
        ),
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: CommonUIComponents.getResponsiveFontSize(
          context,
          mobile: 12,
          desktop: 14,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
