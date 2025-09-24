import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../models/math_content_data.dart';
import '../widgets/math_lesson_widgets.dart';
// وارد کردن فایل صفحه جدید
import 'interactive_dialogue_lesson_screen.dart';

class MathFoundationsLesson extends StatefulWidget {
  const MathFoundationsLesson({super.key});

  @override
  State<MathFoundationsLesson> createState() => _MathFoundationsLessonState();
}

class _MathFoundationsLessonState extends State<MathFoundationsLesson>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _transitionController;
  late AnimationController _contentController;
  late AnimationController _progressController;
  late AnimationController _fabController;

  int _currentSection = 0;
  bool _isMenuOpen = false;
  final bool _showProgress = true;
  double _dragPosition = 0.0;

  final List<EnhancedLessonSection> _sections = [
    EnhancedLessonSection(
      id: 0,
      title: 'مقدمات و تعاریف',
      subtitle: 'آشنایی با مفاهیم پایه ریاضی',
      description: 'در این بخش با مفاهیم اولیه مجموعه‌ها، تعاریف کلیدی و اصول بنیادی آشنا می‌شویم',
      detailedDescription: 'مجموعه یکی از مفاهیم بنیادی ریاضی است که پایه بسیاری از شاخه‌های ریاضی محسوب می‌شود.',
      icon: Icons.foundation,
      emoji: '📚',
      primaryColor: const Color(0xFF667eea),
      secondaryColor: const Color(0xFF764ba2),
      estimatedTime: 8,
      difficulty: 'مقدماتی',
      keyPoints: ['تعریف مجموعه', 'نماد‌گذاری', 'انواع نمایش'],
    ),
    EnhancedLessonSection(
      id: 1,
      title: 'خصوصیات مجموعه‌ها',
      subtitle: 'چهار خاصیت اساسی مجموعه‌ها',
      description: 'بررسی عمیق خصوصیات منحصر بفرد، مرتب، متناهی و تعریف شده در مجموعه‌ها',
      detailedDescription: 'هر مجموعه دارای خصوصیات منحصر بفردی است که آن را از سایر مجموعه‌ها متمایز می‌کند.',
      icon: Icons.category,
      emoji: '🔧',
      primaryColor: const Color(0xFF4facfe),
      secondaryColor: const Color(0xFF00f2fe),
      estimatedTime: 12,
      difficulty: 'متوسط',
      keyPoints: ['منحصر بفرد بودن', 'مرتب بودن', 'متناهی بودن', 'تعریف شده بودن'],
    ),
    EnhancedLessonSection(
      id: 2,
      title: 'زیرمجموعه و زیرمجموعه محض',
      subtitle: 'روابط سلسله مراتبی بین مجموعه‌ها',
      description: 'درک عمیق روابط بین مجموعه‌ها و نحوه تشخیص زیرمجموعه‌ها و زیرمجموعه‌های محض',
      detailedDescription: 'زیرمجموعه‌ها نقش کلیدی در ساختار و تحلیل مجموعه‌ها ایفا می‌کنند.',
      icon: Icons.account_tree,
      emoji: '🌳',
      primaryColor: const Color(0xFF43e97b),
      secondaryColor: const Color(0xFF38f9d7),
      estimatedTime: 10,
      difficulty: 'متوسط',
      keyPoints: ['تعریف زیرمجموعه', 'زیرمجموعه محض', 'نمادها و نشان‌ها'],
    ),
    EnhancedLessonSection(
      id: 3,
      title: 'مجموعه توانی',
      subtitle: 'قدرت و توان مجموعه‌ها',
      description: 'محاسبه دقیق مجموعه‌های توانی و کاربرد آنها در حل مسائل پیچیده ریاضی',
      detailedDescription: 'مجموعه توانی ابزاری قدرتمند برای تحلیل و بررسی تمام زیرمجموعه‌های ممکن است.',
      icon: Icons.power,
      emoji: '⚡',
      primaryColor: const Color(0xFFfa709a),
      secondaryColor: const Color(0xFFfee140),
      estimatedTime: 15,
      difficulty: 'پیشرفته',
      keyPoints: ['تعریف مجموعه توانی', 'محاسبه اندازه', 'کاربردهای عملی'],
    ),
    EnhancedLessonSection(
      id: 4,
      title: 'توابع',
      subtitle: 'نگاشت و ارتباط بین مجموعه‌ها',
      description: 'بررسی جامع انواع توابع، نحوه تعریف نگاشت‌ها و خصوصیات آنها',
      detailedDescription: 'توابع پل ارتباطی بین مجموعه‌ها هستند و نقش حیاتی در ریاضیات دارند.',
      icon: Icons.functions,
      emoji: '📊',
      primaryColor: const Color(0xFF9f55ff),
      secondaryColor: const Color(0xFFc471f5),
      estimatedTime: 18,
      difficulty: 'پیشرفته',
      keyPoints: ['تعریف تابع', 'انواع توابع', 'خصوصیات توابع'],
    ),
    EnhancedLessonSection(
      id: 5,
      title: 'مجموعه متناهی و نامتناهی',
      subtitle: 'طبقه‌بندی مجموعه‌ها بر اساس اندازه',
      description: 'تشخیص دقیق، تحلیل و کار با مجموعه‌های متناهی و نامتناهی',
      detailedDescription: 'درک مفهوم بی‌نهایت و متناهی در مجموعه‌ها، یکی از مباحث عمیق ریاضی است.',
      icon: Icons.all_inclusive,
      emoji: '♾️',
      primaryColor: const Color(0xFFff9a9e),
      secondaryColor: const Color(0xFFfecfef),
      estimatedTime: 14,
      difficulty: 'متوسط',
      keyPoints: ['مجموعه‌های متناهی', 'مجموعه‌های نامتناهی', 'مقایسه اندازه‌ها'],
    ),
    EnhancedLessonSection(
      id: 6,
      title: 'زبان، گرامر و ماشین',
      subtitle: 'کاربرد مجموعه‌ها در علوم کامپیوتر',
      description: 'اتصال مفاهیم مجموعه‌ها به علوم کامپیوتر، نظریه محاسبات و زبان‌های برنامه‌نویسی',
      detailedDescription: 'مجموعه‌ها پایه نظری بسیاری از مفاهیم علوم کامپیوتر و نظریه محاسبات هستند.',
      icon: Icons.computer,
      emoji: '💻',
      primaryColor: const Color(0xFFa8edea),
      secondaryColor: const Color(0xFFfed6e3),
      estimatedTime: 16,
      difficulty: 'پیشرفته',
      keyPoints: ['الفبا و زبان', 'گرامر', 'ماشین‌های محاسباتی'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _startInitialAnimations();
  }

  void _initializeControllers() {
    _pageController = PageController();

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  void _startInitialAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _transitionController.forward();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transitionController.dispose();
    _contentController.dispose();
    _progressController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _navigateToSection(int index) {
    if (_currentSection != index) {
      HapticFeedback.mediumImpact();
      _contentController.reset();

      setState(() {
        _currentSection = index;
        _isMenuOpen = false;
      });

      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      ).then((_) {
        if (mounted) _contentController.forward();
      });

      _fabController.reverse();
    }
  }

  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);

    if (_isMenuOpen) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }

    HapticFeedback.selectionClick();
  }

  // *** کد جدید برای هدایت به صفحه درس تعاملی ***
  void _navigateToInteractiveLesson() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InteractiveDialogueLessonScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            _buildFullScreenContent(isDark, mediaQuery),
            if (_showProgress) _buildProgressIndicator(mediaQuery),
            // *** قرار دادن دکمه‌ها در یک Stack برای مدیریت موقعیت ***
            _buildNavigationControls(isDark),
            _buildFloatingMenu(isDark, mediaQuery),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenContent(bool isDark, MediaQueryData mediaQuery) {
    return SizedBox.expand(
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentSection = index);
          _contentController.reset();
          if (mounted) _contentController.forward();
          HapticFeedback.lightImpact();
        },
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          return _buildSectionContent(index, isDark, mediaQuery);
        },
      ),
    );
  }

  Widget _buildSectionContent(int index, bool isDark, MediaQueryData mediaQuery) {
    final section = _sections[index];
    final sectionContentData = MathContentData.lessonSections.length > index
        ? MathContentData.lessonSections[index]
        : null;

    return SizedBox(
      width: mediaQuery.size.width,
      height: mediaQuery.size.height,
      child: Stack(
        children: [
          _buildAnimatedBackground(section, isDark),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
                child: AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, child) {
                    return Column(
                      children: [
                        _buildEnhancedHeader(section, mediaQuery),
                        const SizedBox(height: 40),
                        if (sectionContentData != null)
                          ...sectionContentData.content.theory.asMap().entries.map((entry) {
                            return AnimatedFadeIn(
                              delay: Duration(milliseconds: 200 + (entry.key * 150)),
                              child: ContentCard(
                                content: entry.value,
                                color: section.primaryColor,
                              ),
                            );
                          }).toList(),
                        if (sectionContentData != null && sectionContentData.content.examples.isNotEmpty)
                          ...sectionContentData.content.examples.asMap().entries.map((entry) {
                            return AnimatedFadeIn(
                              delay: Duration(milliseconds: 300 + entry.key * 200),
                              child: ExampleCard(
                                example: entry.value,
                                color: Colors.amber,
                              ),
                            );
                          }).toList(),
                        const SizedBox(height: 32),
                        if (sectionContentData != null && sectionContentData.content.questions.isNotEmpty)
                          AnimatedFadeIn(
                            delay: const Duration(milliseconds: 800),
                            child: QuizView(
                              questions: sectionContentData.content.questions,
                              color: Colors.green.shade400,
                            ),
                          ),
                        _buildInteractiveElements(section),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(EnhancedLessonSection section, bool isDark) {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                section.primaryColor.withOpacity(0.9),
                section.secondaryColor.withOpacity(0.8),
                section.primaryColor.withOpacity(0.6),
              ],
              stops: const [0.0, 0.6, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(_transitionController.value * math.pi / 4),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  Colors.white.withOpacity(0.15 * _transitionController.value),
                  Colors.transparent,
                ],
              ),
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: GeometricPatternPainter(
                color: Colors.white.withOpacity(0.1),
                progress: _transitionController.value,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedHeader(EnhancedLessonSection section, MediaQueryData mediaQuery) {
    return Transform.translate(
      offset: Offset(0, 50 * (1 - _contentController.value)),
      child: Opacity(
        opacity: _contentController.value,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: section.primaryColor.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'emoji_${section.id}',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [section.primaryColor, section.secondaryColor],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: section.primaryColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Text(
                        section.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: section.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'بخش ${section.id + 1} • ${section.difficulty}',
                            style: TextStyle(
                              color: section.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          section.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                section.subtitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                section.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildInfoChip(
                    Icons.timer_outlined,
                    '${section.estimatedTime} دقیقه',
                    section.primaryColor,
                  ),
                  _buildInfoChip(
                    Icons.trending_up,
                    section.difficulty,
                    section.secondaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'نکات کلیدی:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: section.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: section.keyPoints.map((point) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: section.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: section.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: section.primaryColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveElements(EnhancedLessonSection section) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: section.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'نکته مهم',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: section.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            section.detailedDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF4A5568),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(MediaQueryData mediaQuery) {
    return Positioned(
      top: mediaQuery.padding.top + 20,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _transitionController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -50 * (1 - _transitionController.value)),
            child: Opacity(
              opacity: _transitionController.value,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (_currentSection + 1) / _sections.length,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${_currentSection + 1} / ${_sections.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // *** ویجت کنترل‌های ناوبری بروزرسانی شد ***
  Widget _buildNavigationControls(bool isDark) {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // دکمه جدید "امتحانش کن" در سمت چپ
          FloatingActionButton.extended(
            onPressed: _navigateToInteractiveLesson,
            heroTag: 'interactive_lesson_button', // تگ منحصر به فرد
            backgroundColor: const Color(0xFF4CAF50), // رنگ سبز برای تمایز
            elevation: 8,
            label: const Text(
              'امتحانش کن',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            icon: const Icon(
              Icons.quiz_outlined,
              color: Colors.white,
            ),
          ),

          // دکمه قبلی "فهرست" در سمت راست
          AnimatedBuilder(
            animation: _fabController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_fabController.value * 0.1),
                child: FloatingActionButton.extended(
                  onPressed: _toggleMenu,
                  heroTag: 'menu_button', // تگ منحصر به فرد
                  backgroundColor: _sections[_currentSection].primaryColor,
                  elevation: 8,
                  label: Text(
                    _isMenuOpen ? 'بستن' : 'فهرست',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: _isMenuOpen ? 0.13 : 0,
                    child: Icon(
                      _isMenuOpen ? Icons.close : Icons.menu_book,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingMenu(bool isDark, MediaQueryData mediaQuery) {
    return AnimatedPositioned(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        bottom: _isMenuOpen ? 0 : -(mediaQuery.size.height * 0.6 + 40),
        left: 0,
        right: 0,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _dragPosition += details.delta.dy;
            });
          },
          onVerticalDragEnd: (details) {
            if (_dragPosition > 100) {
              _toggleMenu();
            }
            setState(() {
              _dragPosition = 0;
            });
          },
          child: Container(
            height: mediaQuery.size.height * 0.6,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, -20),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _sections[_currentSection].primaryColor.withOpacity(0.1),
                        _sections[_currentSection].secondaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 28,
                        color: _sections[_currentSection].primaryColor,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'فهرست مطالب درس',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleMenu,
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      final isSelected = _currentSection == index;
                      final isCompleted = index < _currentSection;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _navigateToSection(index),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                  colors: [
                                    section.primaryColor.withOpacity(0.2),
                                    section.secondaryColor.withOpacity(0.2),
                                  ],
                                )
                                    : null,
                                color: !isSelected && !isCompleted
                                    ? Colors.grey.withOpacity(0.1)
                                    : null,
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? Border.all(
                                  color: section.primaryColor.withOpacity(0.5),
                                  width: 2,
                                )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: isSelected || isCompleted
                                          ? LinearGradient(
                                        colors: [section.primaryColor, section.secondaryColor],
                                      )
                                          : null,
                                      color: !isSelected && !isCompleted
                                          ? Colors.grey.withOpacity(0.3)
                                          : null,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: isCompleted
                                          ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                          : isSelected
                                          ? const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                          : Text(
                                        section.emoji,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                section.title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                  color: isSelected
                                                      ? section.primaryColor
                                                      : isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: section.primaryColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'فعال',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          section.subtitle,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.timer_outlined,
                                              size: 14,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${section.estimatedTime} دقیقه',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.signal_cellular_alt,
                                              size: 14,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              section.difficulty,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
          ),
        )
    );
  }
}

class EnhancedLessonSection {
  final int id;
  final String title;
  final String subtitle;
  final String description;
  final String detailedDescription;
  final IconData icon;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final int estimatedTime;
  final String difficulty;
  final List<String> keyPoints;

  EnhancedLessonSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.detailedDescription,
    required this.icon,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.estimatedTime,
    required this.difficulty,
    required this.keyPoints,
  });
}

class GeometricPatternPainter extends CustomPainter {
  final Color color;
  final double progress;

  GeometricPatternPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 80.0;
    final opacity = progress * 0.5;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        final center = Offset(x, y);
        final radius = 30.0 * progress;

        paint.color = color.withOpacity(opacity);
        canvas.drawCircle(center, radius, paint);

        if (x + spacing < size.width) {
          paint.color = color.withOpacity(opacity * 0.5);
          canvas.drawLine(
            Offset(x + radius, y),
            Offset(x + spacing - radius, y),
            paint,
          );
        }

        if (y + spacing < size.height) {
          paint.color = color.withOpacity(opacity * 0.5);
          canvas.drawLine(
            Offset(x, y + radius),
            Offset(x, y + spacing - radius),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(GeometricPatternPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}