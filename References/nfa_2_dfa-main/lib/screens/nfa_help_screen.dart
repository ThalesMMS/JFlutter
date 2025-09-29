import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<HelpSection> _sections = [
    HelpSection(
      title: 'مقدمه‌ای بر NFA',
      icon: Icons.auto_awesome,
      color: const Color(0xFF667EEA),
      content: _getIntroductionContent(),
    ),
    HelpSection(
      title: 'ایجاد NFA جدید',
      icon: Icons.add_circle_rounded,
      color: const Color(0xFFFF0844),
      content: _getCreatingNFAContent(),
    ),
    HelpSection(
      title: 'تعریف حالت‌ها',
      icon: Icons.radio_button_checked,
      color: const Color(0xFF00C9FF),
      content: _getStatesContent(),
    ),
    HelpSection(
      title: 'تعریف گذارها',
      icon: Icons.arrow_forward_rounded,
      color: const Color(0xFFFC466B),
      content: _getTransitionsContent(),
    ),
    HelpSection(
      title: 'تست و اجرا',
      icon: Icons.play_circle_filled,
      color: const Color(0xFF11998E),
      content: _getTestingContent(),
    ),
    HelpSection(
      title: 'ذخیره و بارگذاری',
      icon: Icons.save_rounded,
      color: const Color(0xFFFD746C),
      content: _getSaveLoadContent(),
    ),
    HelpSection(
      title: 'عملیات پیشرفته',
      icon: Icons.hub_outlined,
      color: const Color(0xFF8B5CF6),
      content: _getAdvancedContent(),
    ),
    HelpSection(
      title: 'نکات و ترفندها',
      icon: Icons.lightbulb_rounded,
      color: const Color(0xFFFFF056),
      content: _getTipsContent(),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildAnimatedBackground(context, isDark),

          // Main Content
          CustomScrollView(
            slivers: [
              _buildHelpAppBar(context, theme, isDark),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation:
                      Listenable.merge([_fadeAnimation, _slideAnimation]),
                  builder: (context, child) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            _buildHeroSection(context, theme, isDark),
                            const SizedBox(height: 32),
                            _buildQuickStartSection(context, theme, isDark),
                            const SizedBox(height: 32),
                            _buildSectionsGrid(context, theme, isDark),
                            const SizedBox(height: 32),
                            _buildExamplesSection(context, theme, isDark),
                            const SizedBox(height: 32),
                            _buildFAQSection(context, theme, isDark),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(BuildContext context, bool isDark) {
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
                    const Color(0xFFE8F5E8),
                    const Color(0xFFF0F8FF),
                    const Color(0xFFFFF8DC),
                  ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return CustomPaint(
              painter: HelpBackgroundPainter(
                animation: _floatingController,
                isDark: isDark,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }

  Widget _buildHelpAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
          title: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ).createShader(bounds),
            child: Text(
              '📚 راهنمای کامل',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
          centerTitle: true,
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(_floatingController.value * math.pi) * 5),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'مرجع کامل یادگیری NFA',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'همه چیزی که برای درک و استفاده از اتوماتای غیرقطعی محدود نیاز دارید 🚀',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('8', 'فصل آموزشی', Icons.menu_book, theme),
                    _buildStatCard('20+', 'مثال عملی', Icons.code, theme),
                    _buildStatCard('∞', 'امکانات', Icons.all_inclusive, theme),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String number, String label, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            number,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartSection(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.teal],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'شروع سریع',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildQuickStartStep(
              '1', 'روی "NFA جدید" کلیک کنید', Icons.add_circle),
          _buildQuickStartStep(
              '2', 'حالت‌های خود را تعریف کنید', Icons.radio_button_checked),
          _buildQuickStartStep(
              '3', 'گذارها را اضافه کنید', Icons.arrow_forward),
          _buildQuickStartStep(
              '4', 'رشته‌های ورودی را تست کنید', Icons.play_arrow),
        ],
      ),
    );
  }

  Widget _buildQuickStartStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsGrid(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.red],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.library_books_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'فصل‌های آموزشی',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 800 + (index * 100)),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: _buildSectionCard(
                        context, _sections[index], theme, isDark),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context, HelpSection section, ThemeData theme, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSectionDetail(context, section, theme, isDark),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                section.color.withOpacity(0.1),
                section.color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: section.color.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: section.color.withOpacity(0.2),
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
                  gradient: LinearGradient(
                    colors: [
                      section.color,
                      section.color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: section.color.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  section.icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                section.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: section.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: section.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'مطالعه کنید',
                  style: TextStyle(
                    color: section.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamplesSection(
      BuildContext context, ThemeData theme, bool isDark) {
    final examples = [
      {'title': 'NFA ساده', 'desc': 'رشته‌های شامل "ab"', 'difficulty': 'آسان'},
      {'title': 'NFA پیچیده', 'desc': 'عبارات منظم', 'difficulty': 'متوسط'},
      {'title': 'NFA پیشرفته', 'desc': 'الگوهای ترکیبی', 'difficulty': 'سخت'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.pink],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.code_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'مثال‌های عملی',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...examples.map(
              (example) => _buildExampleCard(context, example, theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildExampleCard(BuildContext context, Map<String, String> example,
      ThemeData theme, bool isDark) {
    Color difficultyColor = Colors.green;
    if (example['difficulty'] == 'متوسط') difficultyColor = Colors.orange;
    if (example['difficulty'] == 'سخت') difficultyColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [difficultyColor, difficultyColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.code,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example['title']!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  example['desc']!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: difficultyColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              example['difficulty']!,
              style: TextStyle(
                color: difficultyColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, ThemeData theme, bool isDark) {
    final faqs = [
      {
        'q': 'NFA چیست و چه تفاوتی با DFA دارد؟',
        'a':
            'NFA یا اتوماتای غیرقطعی محدود، نوعی اتوماتا است که برخلاف DFA، می‌تواند در یک حالت با یک نماد ورودی، به چندین حالت مختلف انتقال یابد.',
      },
      {
        'q': 'چگونه گذار ε (اپسیلون) تعریف کنم؟',
        'a':
            'برای تعریف گذار اپسیلون، در قسمت نماد گذار، کلمه "epsilon" یا "ε" را وارد کنید. این گذار بدون نیاز به خواندن نماد انجام می‌شود.',
      },
      {
        'q': 'آیا می‌توانم NFA خود را ذخیره کنم؟',
        'a':
            'بله! شما می‌توانید NFA خود را در قالب فایل JSON ذخیره کرده و بعداً آن را بارگذاری کنید.',
      },
      {
        'q': 'چگونه رشته ورودی را تست کنم؟',
        'a':
            'پس از تعریف NFA، به قسمت تست بروید و رشته مورد نظر خود را وارد کنید. برنامه به شما نشان می‌دهد که رشته پذیرفته می‌شود یا خیر.',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.indigo, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'سوالات متداول',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...faqs.map((faq) => _buildFAQCard(context, faq, theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildFAQCard(BuildContext context, Map<String, String> faq,
      ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          faq['q']!,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq['a']!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSectionDetail(
      BuildContext context, HelpSection section, ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    section.color,
                    section.color.withOpacity(0.8),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      section.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      section.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: section.content,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // محتوای آموزشی هر بخش
  static List<Widget> _getIntroductionContent() {
    return [
      _buildContentSection(
        '🎯 اتوماتای غیرقطعی محدود چیست؟',
        'NFA یا Non-deterministic Finite Automaton نوعی مدل محاسباتی است که برای پردازش رشته‌ها و تشخیص زبان‌های منظم استفاده می‌شود.',
        [
          '• قابلیت انتقال به چندین حالت با یک نماد',
          '• پشتیبانی از گذارهای ε (اپسیلون)',
          '• انعطاف‌پذیری بالا در طراحی',
          '• کاربرد در کامپایلرها و پردازش متن',
        ],
      ),
      _buildContentSection(
        '⚖️ تفاوت NFA و DFA',
        'درک تفاوت‌های کلیدی بین این دو نوع اتوماتا:',
        [
          'NFA: می‌تواند در یک حالت با یک نماد، به چندین حالت برود',
          'DFA: در هر حالت با هر نماد، تنها یک گذار مشخص دارد',
          'NFA: پشتیبانی از گذارهای اپسیلون',
          'DFA: بدون گذار اپسیلون',
          'NFA: طراحی آسان‌تر برای مسائل پیچیده',
          'DFA: اجرای سریع‌تر و حافظه کمتر',
        ],
      ),
      _buildContentSection(
        '🔧 اجزای اصلی NFA',
        'هر NFA از پنج جزء اصلی تشکیل شده است:',
        [
          'Q: مجموعه حالت‌ها (States)',
          'Σ: الفبای ورودی (Input Alphabet)',
          'δ: تابع گذار (Transition Function)',
          'q₀: حالت اولیه (Start State)',
          'F: مجموعه حالت‌های نهایی (Final States)',
        ],
      ),
    ];
  }

  static List<Widget> _getCreatingNFAContent() {
    return [
      _buildContentSection(
        '🚀 ایجاد NFA جدید',
        'مراحل ایجاد یک NFA جدید:',
        [
          '1. روی دکمه "NFA جدید" در صفحه اصلی کلیک کنید',
          '2. نام مناسبی برای پروژه خود انتخاب کنید',
          '3. توضیح کوتاهی از هدف NFA بنویسید',
          '4. روی "ایجاد" کلیک کنید',
        ],
      ),
      _buildContentSection(
        '📋 تنظیمات اولیه',
        'پس از ایجاد NFA، می‌توانید تنظیمات زیر را انجام دهید:',
        [
          '• تعریف الفبای ورودی (a, b, c, ...)',
          '• انتخاب نماد اپسیلون (ε یا epsilon)',
          '• تنظیم حالت پیش‌فرض',
          '• انتخاب نام‌گذاری حالت‌ها',
        ],
      ),
      _buildContentSection(
        '💡 نکات مهم',
        'نکاتی که هنگام ایجاد NFA باید در نظر بگیرید:',
        [
          '• ابتدا مسئله را به صورت کامل درک کنید',
          '• الگوی مورد نظر را مشخص کنید',
          '• تعداد حالت‌های مورد نیاز را تخمین بزنید',
          '• از نام‌های معنادار برای حالت‌ها استفاده کنید',
        ],
      ),
    ];
  }

  static List<Widget> _getStatesContent() {
    return [
      _buildContentSection(
        '🎯 انواع حالت‌ها',
        'در NFA سه نوع حالت وجود دارد:',
        [
          '🟢 حالت اولیه (Start State): نقطه شروع پردازش',
          '🔵 حالت میانی (Intermediate State): حالت‌های واسطه',
          '🟡 حالت نهایی (Final State): حالت‌های پذیرش',
          '🟠 حالت ترکیبی: هم میانی و هم نهایی',
        ],
      ),
      _buildContentSection(
        '➕ اضافه کردن حالت',
        'مراحل اضافه کردن حالت جدید:',
        [
          '1. روی دکمه "+" در پنل حالت‌ها کلیک کنید',
          '2. نام حالت را وارد کنید (مثل q0, q1, s1)',
          '3. نوع حالت را انتخاب کنید',
          '4. در صورت نیاز، توضیح اضافه کنید',
          '5. روی "تایید" کلیک کنید',
        ],
      ),
      _buildContentSection(
        '✏️ ویرایش حالت‌ها',
        'امکانات ویرایش حالت‌ها:',
        [
          '• تغییر نام حالت',
          '• تبدیل نوع حالت (عادی ↔ نهایی)',
          '• اضافه کردن توضیحات',
          '• حذف حالت (با احتیاط)',
          '• کپی کردن حالت',
        ],
      ),
      _buildContentSection(
        '⚠️ نکات مهم',
        'نکاتی که باید رعایت کنید:',
        [
          '• هر NFA باید دقیقاً یک حالت اولیه داشته باشد',
          '• حداقل یک حالت نهایی لازم است',
          '• نام حالت‌ها باید منحصر به فرد باشند',
          '• از نام‌های کوتاه و معنادار استفاده کنید',
          '• حذف حالت، تمام گذارهای مربوطه را حذف می‌کند',
        ],
      ),
    ];
  }

  static List<Widget> _getTransitionsContent() {
    return [
      _buildContentSection(
        '🔄 گذارها چیست؟',
        'گذارها ارتباط بین حالت‌ها را تعریف می‌کنند:',
        [
          '• هر گذار شامل: حالت مبدأ، نماد ورودی، حالت مقصد',
          '• یک حالت می‌تواند با یک نماد به چندین حالت برود',
          '• گذارهای اپسیلون بدون خواندن نماد انجام می‌شوند',
          '• گذارها جهت‌دار هستند',
        ],
      ),
      _buildContentSection(
        '➕ اضافه کردن گذار',
        'مراحل تعریف گذار جدید:',
        [
          '1. حالت مبدأ را انتخاب کنید',
          '2. نماد ورودی را وارد کنید (a, b, ε, ...)',
          '3. حالت مقصد را انتخاب کنید',
          '4. روی "اضافه کردن گذار" کلیک کنید',
        ],
      ),
      _buildContentSection(
        '🔤 انواع نمادها',
        'نمادهای قابل استفاده در گذارها:',
        [
          '• حروف: a, b, c, ... z',
          '• اعداد: 0, 1, 2, ... 9',
          '• اپسیلون: ε، epsilon، e',
          '• نمادهای خاص: +, -, *, /, =',
          '• رشته‌های چندکاراکتری: ab, 01, ...',
        ],
      ),
      _buildContentSection(
        '🎯 گذارهای اپسیلون',
        'گذارهای بدون نیاز به خواندن نماد:',
        [
          '• با "ε" یا "epsilon" تعریف می‌شوند',
          '• امکان انتقال خودکار بین حالت‌ها',
          '• افزایش انعطاف‌پذیری NFA',
          '• کاربرد در اتصال قسمت‌های مختلف',
          '• احتیاط در ایجاد حلقه‌های اپسیلون',
        ],
      ),
    ];
  }

  static List<Widget> _getTestingContent() {
    return [
      _buildContentSection(
        '🧪 تست رشته‌ها',
        'پس از تعریف NFA، می‌توانید رشته‌های مختلف را تست کنید:',
        [
          '• وارد کردن رشته در قسمت ورودی',
          '• مشاهده مسیر پردازش',
          '• نتیجه: پذیرفته یا رد شده',
          '• جزئیات گام به گام',
        ],
      ),
      _buildContentSection(
        '📊 نمایش مسیر',
        'ویژگی‌های نمایش مسیر پردازش:',
        [
          '• نمایش حالت فعلی در هر گام',
          '• مشخص کردن نماد خوانده شده',
          '• نمایش تمام مسیرهای ممکن',
          '• هایلایت حالت‌های نهایی',
          '• نمایش گذارهای اپسیلون',
        ],
      ),
      _buildContentSection(
        '✅ تفسیر نتایج',
        'چگونه نتایج تست را تفسیر کنیم:',
        [
          '• سبز: رشته پذیرفته شده',
          '• قرمز: رشته رد شده',
          '• زرد: پردازش در حال انجام',
          '• آبی: حالت‌های فعال',
          '• خاکستری: حالت‌های غیرفعال',
        ],
      ),
      _buildContentSection(
        '🔍 نکات تست',
        'نکاتی برای تست موثر:',
        [
          '• رشته‌های کوتاه را ابتدا تست کنید',
          '• موارد مرزی را بررسی کنید',
          '• رشته خالی را تست کنید',
          '• ترکیبات مختلف نمادها را امتحان کنید',
          '• رشته‌های طولانی را نیز تست کنید',
        ],
      ),
    ];
  }

  static List<Widget> _getSaveLoadContent() {
    return [
      _buildContentSection(
        '💾 ذخیره پروژه',
        'روش‌های مختلف ذخیره‌سازی:',
        [
          '• ذخیره خودکار در حین کار',
          '• ذخیره دستی با Ctrl+S',
          '• صادرات به فایل JSON',
          '• ایجاد نسخه پشتیبان',
          '• اشتراک‌گذاری با دیگران',
        ],
      ),
      _buildContentSection(
        '📂 بارگذاری فایل',
        'بازیابی پروژه‌های قبلی:',
        [
          '• انتخاب فایل از سیستم',
          '• بررسی اعتبار فایل',
          '• بارگذاری تنظیمات',
          '• بازیابی حالت‌ها و گذارها',
          '• حفظ تاریخچه تغییرات',
        ],
      ),
      _buildContentSection(
        '📋 فرمت فایل',
        'ساختار فایل‌های ذخیره شده:',
        [
          '• فرمت JSON استاندارد',
          '• شامل تمام اطلاعات NFA',
          '• متادیتا و تنظیمات',
          '• تاریخ ایجاد و ویرایش',
          '• نسخه سازگاری',
        ],
      ),
      _buildContentSection(
        '🔒 امنیت داده‌ها',
        'حفاظت از اطلاعات شما:',
        [
          '• رمزگذاری محتوای حساس',
          '• پشتیبان‌گیری خودکار',
          '• حفظ حریم خصوصی',
          '• عدم ارسال به سرور',
          '• کنترل کامل بر داده‌ها',
        ],
      ),
    ];
  }

  static List<Widget> _getAdvancedContent() {
    return [
      _buildContentSection(
        '🔄 اجتماع NFA ها',
        'ترکیب چندین NFA برای ایجاد NFA پیچیده‌تر:',
        [
          '• انتخاب دو یا چند NFA',
          '• تعریف نحوه اتصال',
          '• ایجاد حالت‌های جدید',
          '• بهینه‌سازی نتیجه نهایی',
        ],
      ),
      _buildContentSection(
        '🤝 اشتراک NFA ها',
        'عملیات اشتراک دو NFA:',
        [
          '• پیدا کردن زبان مشترک',
          '• ایجاد NFA جدید',
          '• حفظ ویژگی‌های هر دو',
          '• بهینه‌سازی تعداد حالت‌ها',
        ],
      ),
      _buildContentSection(
        '🔀 تبدیل NFA به DFA',
        'الگوریتم تبدیل برای بهینه‌سازی:',
        [
          '• ایجاد جدول حالت‌ها',
          '• محاسبه closure های اپسیلون',
          '• ترکیب حالت‌های هم‌ارز',
          '• حذف حالت‌های غیرضروری',
        ],
      ),
      _buildContentSection(
        '⚡ بهینه‌سازی',
        'تکنیک‌های بهبود عملکرد:',
        [
          '• حذف حالت‌های غیرقابل دسترس',
          '• ادغام حالت‌های مشابه',
          '• کاهش گذارهای اپسیلون',
          '• بهینه‌سازی مسیرها',
        ],
      ),
    ];
  }

  static List<Widget> _getTipsContent() {
    return [
      _buildContentSection(
        '💡 نکات طراحی',
        'راهنمایی‌هایی برای طراحی بهتر:',
        [
          '• ابتدا الگو را روی کاغذ بکشید',
          '• از نام‌های معنادار استفاده کنید',
          '• مراحل پردازش را گام به گام طراحی کنید',
          '• موارد استثنا را در نظر بگیرید',
        ],
      ),
      _buildContentSection(
        '🚀 بهبود عملکرد',
        'روش‌هایی برای کار سریع‌تر:',
        [
          '• از کلیدهای میانبر استفاده کنید',
          '• الگوهای متداول را ذخیره کنید',
          '• از قالب‌های آماده بهره بگیرید',
          '• تست‌های منظم انجام دهید',
        ],
      ),
      _buildContentSection(
        '🐛 رفع مشکلات',
        'حل مشکلات رایج:',
        [
          '• بررسی تعریف صحیح حالت اولیه',
          '• کنترل وجود حالت نهایی',
          '• چک کردن درستی گذارها',
          '• تست با رشته‌های ساده',
        ],
      ),
      _buildContentSection(
        '📚 منابع یادگیری',
        'منابع پیشنهادی برای مطالعه بیشتر:',
        [
          '• کتاب‌های نظریه زبان‌ها',
          '• دوره‌های آنلاین',
          '• مقالات علمی',
          '• پروژه‌های عملی',
        ],
      ),
    ];
  }

  static Widget _buildContentSection(
      String title, String description, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF4A5568),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF667EEA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// مدل داده برای بخش‌های راهنما
class HelpSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> content;

  HelpSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });
}

// پینتر برای پس‌زمینه انیمیشنی
class HelpBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDark;

  HelpBackgroundPainter({required this.animation, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          (isDark ? Colors.white : const Color(0xFF667EEA)).withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // رسم شبکه پس‌زمینه
    for (double x = 0; x < size.width; x += 50) {
      for (double y = 0; y < size.height; y += 50) {
        final offset = Offset(
          x + math.sin(animation.value * 2 * math.pi + x * 0.01) * 10,
          y + math.cos(animation.value * 2 * math.pi + y * 0.01) * 10,
        );
        canvas.drawCircle(offset, 2, paint);
      }
    }

    // رسم خطوط متحرک
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.5;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final startX = size.width * (i / 5);
      final amplitude = 30 + math.sin(animation.value * math.pi + i) * 10;

      path.moveTo(startX, 0);

      for (double y = 0; y <= size.height; y += 10) {
        final x = startX +
            math.sin((y * 0.01) + (animation.value * 2 * math.pi)) * amplitude;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
