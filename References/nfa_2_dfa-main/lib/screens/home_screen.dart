import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:math' as math;
import 'about_screen.dart';
import '../providers/nfa_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'nfa_help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _floatingAnimationController;
  late AnimationController _particlesController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _particlesController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainAnimationController,
            curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.4, 1.0, curve: Curves.bounceOut),
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_particlesController);

    _mainAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _floatingAnimationController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nfaProvider = Provider.of<NFAProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(context, isDark, size),

          // Main content
          CustomScrollView(
            slivers: [
              _buildModernAppBar(context, theme, isDark),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _slideAnimation,
                    _fadeAnimation,
                    _scaleAnimation,
                  ]),
                  builder: (context, child) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildHeroSection(context, isDark),
                                const SizedBox(height: 40),
                                _buildGlassmorphicActions(
                                  context,
                                  nfaProvider,
                                  isDark,
                                ),
                                const SizedBox(height: 40),
                                _buildAdvancedRecentProjects(
                                  context,
                                  nfaProvider,
                                  isDark,
                                ),
                                const SizedBox(height: 32),
                                _buildFloatingHelpSection(context, isDark),
                                const SizedBox(height: 100), // Bottom padding
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          _buildFloatingActionButton(context, nfaProvider, isDark),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(
    BuildContext context,
    bool isDark,
    Size size,
  ) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    const Color(0xFFE3F2FD),
                    const Color(0xFFF3E5F5),
                    const Color(0xFFFFF3E0),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: AnimatedBuilder(
          animation: _particlesController,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlesPainter(
                animation: _particlesController,
                isDark: isDark,
              ),
              size: size,
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (isDark ? Colors.black : Colors.white).withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              );
            },
          ),
          centerTitle: true,
        ),
      ),
      actions: [
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.settings);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.settings_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final timeOfDay = DateTime.now().hour;
    String greeting = 'خوش آمدید';
    IconData greetingIcon = Icons.waving_hand;

    if (timeOfDay < 12) {
      greeting = 'صبح بخیر';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (timeOfDay < 18) {
      greeting = 'عصر بخیر';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'شب بخیر';
      greetingIcon = Icons.nightlight_round;
    }

    return AnimatedBuilder(
      animation: _floatingAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            math.sin(_floatingAnimationController.value * math.pi) * 5,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF2D1B69).withOpacity(0.3),
                        const Color(0xFF11998E).withOpacity(0.2),
                      ]
                    : [
                        const Color(0xFF667EEA).withOpacity(0.2),
                        const Color(0xFF764BA2).withOpacity(0.1),
                      ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(greetingIcon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              greeting,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'آماده ساخت و تحلیل NFA جادویی هستید؟ ✨',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.8,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تجربه‌ای نو در دنیای اتوماتا',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassmorphicActions(
    BuildContext context,
    NFAProvider nfaProvider,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'اقدامات سریع',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.9,
          children: [
            _buildGlassmorphicCard(
              context: context,
              icon: Icons.add_circle_rounded,
              title: 'NFA جدید',
              subtitle: 'ایجاد اتوماتا جادویی',
              colors: [
                const Color(0xFFFF0844), // Hot Pink
                const Color(0xFFFFB199), // Coral
                const Color(0xFFFF8A80), // Light Pink
              ],
              onTap: () {
                nfaProvider.createNewNFA();
                Navigator.pushNamed(context, AppRoutes.input);
              },
              delay: 0,
            ),
            _buildGlassmorphicCard(
              context: context,
              icon: Icons.folder_open_rounded,
              title: 'باز کردن فایل',
              subtitle: 'بارگذاری سریع',
              colors: [
                const Color(0xFF00C9FF), // Electric Blue
                const Color(0xFF92FE9D), // Mint Green
                const Color(0xFF50E3C2), // Turquoise
              ],
              onTap: () async {
                final success = await nfaProvider.loadNFAFromFile();
                if (success) {
                  Navigator.pushNamed(context, AppRoutes.input);
                } else {
                  if (mounted) {
                    UIHelpers.showSnackBar(
                      context,
                      'خطا در بارگذاری فایل',
                      isError: true,
                    );
                  }
                }
              },
              delay: 200,
            ),
            _buildGlassmorphicCard(
              context: context,
              icon: Icons.hub_outlined,
              title: 'عملیات پیشرفته',
              subtitle: 'اجتماع و اشتراک',
              colors: [
                const Color(0xFFFC466B), // Vibrant Pink
                const Color(0xFF3F5EFB), // Electric Purple
                const Color(0xFF8B5CF6), // Purple
              ],
              onTap: () {
                Navigator.pushNamed(context, '/operations');
              },
              delay: 400,
            ),
            _buildGlassmorphicCard(
              context: context,
              icon: Icons.library_books_rounded,
              title: 'مثال‌ها',
              subtitle: 'نمونه‌های الهام‌بخش',
              colors: [
                const Color(0xFFFD746C), // Coral Red
                const Color(0xFFFF9068), // Orange
                const Color(0xFFFFF056), // Bright Yellow
              ],
              onTap: () {
                Navigator.pushNamed(context, '/examples');
              },
              delay: 600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassmorphicCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + delay),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors.length >= 3
                        ? colors
                        : [colors.first, colors.last],
                    stops: colors.length >= 3 ? [0.0, 0.5, 1.0] : [0.0, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: colors.last.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedRecentProjects(
    BuildContext context,
    NFAProvider nfaProvider,
    bool isDark,
  ) {
    final recentProjects = nfaProvider.recentProjects;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.pink],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'پروژه‌های اخیر',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            if (recentProjects.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'مشاهده همه',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (recentProjects.isEmpty)
          _buildEmptyState(context, theme, isDark)
        else
          _buildProjectsList(
            context,
            recentProjects,
            nfaProvider,
            theme,
            isDark,
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.secondary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'هیچ پروژه اخیری وجود ندارد',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'با ایجاد پروژه جدید شروع کنید و سفر خود را آغاز کنید! 🚀',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(
    BuildContext context,
    List<RecentProject> projects,
    NFAProvider nfaProvider,
    ThemeData theme,
    bool isDark,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.take(5).length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 200)),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(50 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: _buildAdvancedProjectCard(
                  context,
                  projects[index],
                  nfaProvider,
                  theme,
                  isDark,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdvancedProjectCard(
    BuildContext context,
    RecentProject project,
    NFAProvider nfaProvider,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            nfaProvider.loadRecentProject(project.id);
            Navigator.pushNamed(context, AppRoutes.input);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_tree_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'آخرین ویرایش: ${_formatDate(project.lastModified)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirmed = await UIHelpers.showConfirmationDialog(
                        context: context,
                        title: 'حذف پروژه',
                        content:
                            'آیا از حذف پروژه "${project.name}" مطمئن هستید؟',
                        isDangerous: true,
                        confirmText: 'حذف',
                      );
                      if (confirmed) {
                        nfaProvider.deleteRecentProject(project.id);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'امروز';
    } else if (difference.inDays == 1) {
      return 'دیروز';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildFloatingHelpSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _floatingAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            math.sin(_floatingAnimationController.value * math.pi * 2) * 3,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1A1A2E).withOpacity(0.3),
                        const Color(0xFF16213E).withOpacity(0.2),
                      ]
                    : [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildModernHelpButton(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    title: 'راهنما',
                    subtitle: 'آموزش کامل',
                    colors: [Colors.blue, Colors.purple],
                    onTap: () {
                      // [MODIFIED] Navigate to HelpScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 2,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.5),
                        theme.colorScheme.secondary.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildModernHelpButton(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    title: 'درباره ما',
                    subtitle: 'اطلاعات برنامه',
                    colors: [Colors.green, Colors.teal],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernHelpButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors.map((c) => c.withOpacity(0.1)).toList(),
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.first.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    NFAProvider nfaProvider,
    bool isDark,
  ) {
    return Positioned(
      bottom: 30,
      right: 30,
      child: AnimatedBuilder(
        animation: _floatingAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale:
                1.0 +
                (math.sin(_floatingAnimationController.value * math.pi * 2) *
                    0.05),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    nfaProvider.createNewNFA();
                    Navigator.pushNamed(context, AppRoutes.input);
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'شروع سریع',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDark;

  ParticlesPainter({required this.animation, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF667EEA)).withOpacity(
        0.1,
      )
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 15; i++) {
      final x =
          (size.width * 0.1) +
          (i * size.width * 0.06) +
          (math.sin(animation.value * 2 * math.pi + i) * 20);
      final y =
          (size.height * 0.1) +
          (i * size.height * 0.05) +
          (math.cos(animation.value * 2 * math.pi + i) * 30);

      final radius = 3 + (math.sin(animation.value * 4 * math.pi + i) * 2);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw connecting lines
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    paint.color = paint.color.withOpacity(0.05);

    for (int i = 0; i < 10; i++) {
      final startX = size.width * 0.1 + (i * size.width * 0.08);
      final startY =
          size.height * 0.2 + (math.sin(animation.value * math.pi + i) * 50);
      final endX = size.width * 0.9 - (i * size.width * 0.08);
      final endY =
          size.height * 0.8 + (math.cos(animation.value * math.pi + i) * 50);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
