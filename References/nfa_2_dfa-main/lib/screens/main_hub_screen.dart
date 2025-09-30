import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'home_screen.dart';
import 'operations_screen.dart';
import 'settings_screen.dart';
import 'math_foundations_lesson.dart';

class MainHubScreen extends StatefulWidget {
  const MainHubScreen({super.key});

  @override
  State<MainHubScreen> createState() => _MainHubScreenState();
}

class _MainHubScreenState extends State<MainHubScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _rippleController;
  late AnimationController _morphController;
  late List<AnimationController> _iconControllers;
  late List<AnimationController> _particleControllers;

  // [MODIFIED] اضافه کردن آیتم جدید به لیست ناوبری
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      morphIcon: Icons.space_dashboard_rounded,
      label: 'خانه',
      page: const HomeScreen(),
      gradient: const LinearGradient(
        colors: [
          Color(0xFF667eea),
          Color(0xFF764ba2),
          Color(0xFFa8edea),
          Color(0xFFfed6e3),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
      badgeCount: 0,
    ),
    NavigationItem(
      icon: Icons.timeline_outlined,
      activeIcon: Icons.timeline_rounded,
      morphIcon: Icons.show_chart_rounded,
      label: 'عملیات',
      page: const OperationsScreen(),
      gradient: const LinearGradient(
        colors: [
          Color(0xFF4facfe),
          Color(0xFF00f2fe),
          Color(0xFF43e97b),
          Color(0xFF38f9d7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.25, 0.75, 1.0],
      ),
      badgeCount: 0,
    ),
    NavigationItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      morphIcon: Icons.auto_stories_rounded,
      label: 'مفاهیم ریاضی',
      page: const MathFoundationsLesson(),
      gradient: const LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      badgeCount: 0,
    ),
    NavigationItem(
      icon: Icons.widgets_outlined,
      activeIcon: Icons.widgets_rounded,
      morphIcon: Icons.extension_rounded,
      label: 'تنظیمات',
      page: const SettingsScreen(),
      gradient: const LinearGradient(
        colors: [Color(0xFF00F260), Color(0xFF0575E6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      badgeCount: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupControllers();
  }

  void _setupControllers() {
    _pageController = PageController();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _iconControllers = List.generate(
      _navigationItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _particleControllers = List.generate(
      _navigationItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
    );

    _iconControllers[0].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _rippleController.dispose();
    _morphController.dispose();
    for (var controller in _iconControllers) {
      controller.dispose();
    }
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      HapticFeedback.mediumImpact();

      // شروع انیمیشن‌ها
      _rippleController.forward().then((_) => _rippleController.reset());
      _particleControllers[index].forward().then(
        (_) => _particleControllers[index].reset(),
      );
      _iconControllers[_selectedIndex].reverse();
      _morphController.forward().then((_) => _morphController.reset());

      setState(() {
        _selectedIndex = index;
      });

      _iconControllers[index].forward();

      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0F0C29),
                    const Color(0xFF24243e),
                    const Color(0xFF302B63),
                  ]
                : [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                    const Color(0xFFf093fb),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            if (_selectedIndex != index) {
              HapticFeedback.lightImpact();
              _iconControllers[_selectedIndex].reverse();
              setState(() {
                _selectedIndex = index;
              });
              _iconControllers[index].forward();
            }
          },
          children: _navigationItems.map((item) => item.page).toList(),
        ),
      ),
      bottomNavigationBar: Container(
        height: 110,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0xFF0F172A).withOpacity(0.4)
                  : const Color(0xFF334155).withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.8),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1A1A2E).withOpacity(0.95),
                        const Color(0xFF16213E).withOpacity(0.95),
                      ]
                    : [
                        const Color(0xFFF8F9FA).withOpacity(0.95),
                        const Color(0xFFE9ECEF).withOpacity(0.95),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _navigationItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = _selectedIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Ripple Effect
                              if (isSelected) _buildRippleEffect(item),

                              // Particle Effects
                              ..._buildParticleEffects(item, index, isSelected),

                              // Main Icon Container
                              _buildMainIcon(item, index, isSelected, isDark),

                              // Badge
                              if (item.badgeCount > 0)
                                _buildBadge(item.badgeCount),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Label
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isSelected ? 1.0 : 0.7,
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? item.gradient.colors.first
                                    : theme.colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRippleEffect(NavigationItem item) {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        return Opacity(
          opacity: 1 - _rippleController.value,
          child: Container(
            width: 60 * (1 + _rippleController.value * 0.5),
            height: 60 * (1 + _rippleController.value * 0.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: item.gradient,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildParticleEffects(
    NavigationItem item,
    int index,
    bool isSelected,
  ) {
    if (!isSelected) return [];

    return List.generate(6, (particleIndex) {
      return AnimatedBuilder(
        animation: _particleControllers[index],
        builder: (context, child) {
          final angle = (particleIndex * math.pi * 2) / 6;
          final distance = 40 * _particleControllers[index].value;
          final opacity = 1 - _particleControllers[index].value;

          return Positioned(
            left: 30 + distance * math.cos(angle),
            top: 30 + distance * math.sin(angle),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: item.gradient.colors.first.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildMainIcon(
    NavigationItem item,
    int index,
    bool isSelected,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([_iconControllers[index], _morphController]),
      builder: (context, child) {
        final scale = 1.0 + (_iconControllers[index].value * 0.3);
        final morphProgress = _morphController.value;

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: _iconControllers[index].value * 0.1,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected ? item.gradient : null,
                color: !isSelected
                    ? (isDark
                          ? const Color(0xFF2D3748)
                          : const Color(0xFFF1F3F4))
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: item.gradient.colors.first.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  morphProgress > 0.5
                      ? item.morphIcon
                      : (isSelected ? item.activeIcon : item.icon),
                  key: ValueKey(
                    '${item.label}_${isSelected}_${morphProgress > 0.5}',
                  ),
                  size: 24,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFFA0AEC0)
                            : const Color(0xFF4A5568)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(int count) {
    return Positioned(
      top: 0,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final IconData morphIcon;
  final String label;
  final Widget page;
  final LinearGradient gradient;
  final int badgeCount;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.morphIcon,
    required this.label,
    required this.page,
    required this.gradient,
    this.badgeCount = 0,
  });
}
