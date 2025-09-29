import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const WelcomeScreen({
    super.key,
    this.onCompleted,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _backgroundController;
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final AnimationController _nfaTransformController;

  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _nfaTransformController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _nfaTransformController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeWelcome();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeWelcome() {
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/main',
        (route) => false,
      );
    }
  }

  void _skipWelcome() {
    _completeWelcome();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, _backgroundController.value * 0.7 + 0.2, 1.0],
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.15),
                      theme.colorScheme.surface,
                      theme.colorScheme.secondary.withOpacity(0.15),
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating State Nodes (representing automata states)
          ...List.generate(12, (index) => _buildFloatingStateNode(size, index)),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Progress Indicator
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          onPressed: _previousPage,
                          icon: Icon(Icons.arrow_back_ios_rounded,
                              color: theme.colorScheme.primary),
                        ),
                      const Spacer(),
                      ...List.generate(_totalPages,
                          (index) => _buildProgressDot(index, theme)),
                      const Spacer(),
                      TextButton(
                        onPressed: _skipWelcome,
                        child: Text(
                          'رد کردن',
                          style: TextStyle(
                            color: theme.colorScheme.primary.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      HapticFeedback.selectionClick();
                    },
                    children: [
                      _buildFirstPage(theme),
                      _buildSecondPage(theme),
                      _buildThirdPage(theme),
                    ],
                  ),
                ),

                // Bottom Navigation
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildBottomNavigation(theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingStateNode(Size size, int index) {
    final random = math.Random(index);
    final x = random.nextDouble() * size.width;
    final y = random.nextDouble() * size.height;
    final delay = random.nextDouble() * 2.0;
    final isEpsilon = index % 4 == 0;

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset =
            math.sin(_floatController.value * 2.0 * math.pi + delay) * 25.0;
        final opacity =
            0.1 + (math.sin(_floatController.value * math.pi + delay) * 0.15);

        return Positioned(
          left: x,
          top: y + offset,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: isEpsilon ? 16.0 : 12.0,
              height: isEpsilon ? 16.0 : 12.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEpsilon
                    ? Colors.orange.withOpacity(0.6)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.4),
                border: Border.all(
                  color: isEpsilon
                      ? Colors.orange.withOpacity(0.8)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  width: 1.0,
                ),
              ),
              child: isEpsilon
                  ? const Center(
                      child: Text(
                        'ε',
                        style: TextStyle(
                          fontSize: 8.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressDot(int index, ThemeData theme) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withOpacity(0.3),
      ),
    );
  }

  Widget _buildFirstPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated NFA Diagram
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0.0,
                    15.0 * math.sin(_floatController.value * 2.0 * math.pi)),
                child: child,
              );
            },
            child: _buildNFADiagram(theme),
          ),

          const SizedBox(height: 48.0),

          Text(
            'به دنیای آتوماتا خوش آمدید',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 24.0),

          Text(
            'اپلیکیشن پیشرفته تبدیل NFA به DFA، همراه شما در یادگیری و تحلیل نظریه زبان‌ها و ماشین‌های محدود.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 32.0),

          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'ε',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'پشتیبانی کامل از انتقال‌های اپسیلون و حالت‌های غیرقطعی',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Interactive State Machine Visualization
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return _buildInteractiveStateMachine(theme);
            },
          ),

          const SizedBox(height: 48.0),

          Text(
            'نمایش گرافیکی تعاملی',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 24.0),

          Text(
            'با هر تغییری که اعمال می‌کنید، نمودار آتوماتای خود را به صورت لحظه‌ای و با انیمیشن‌های زیبا مشاهده نمایید.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 32.0),

          _buildFeatureCard(
            theme,
            Icons.account_tree_outlined,
            'طراحی NFA بصری',
            'ایجاد و ویرایش آسان حالت‌ها، الفبا و توابع انتقال با رابط کاربری بصری.',
          ),

          const SizedBox(height: 16.0),

          _buildFeatureCard(
            theme,
            Icons.play_circle_outline,
            'شبیه‌سازی مسیر پردازش',
            'دنبال کردن مسیر پردازش رشته‌ها با انیمیشن‌های قابل فهم و تعاملی.',
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // NFA to DFA Transformation Animation
          AnimatedBuilder(
            animation: _nfaTransformController,
            builder: (context, child) {
              return _buildTransformationAnimation(theme);
            },
          ),

          const SizedBox(height: 48.0),

          Text(
            'تبدیل هوشمند NFA → DFA',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.tertiary,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 24.0),

          Text(
            'با استفاده از الگوریتم Subset Construction، NFA را به یک DFA معادل و بهینه تبدیل کنید.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 32.0),

          _buildFeatureCard(
            theme,
            Icons.functions_rounded,
            'الگوریتم Subset Construction',
            'پیاده‌سازی بهینه الگوریتم استاندارد تبدیل NFA به DFA.',
          ),

          const SizedBox(height: 16.0),

          _buildFeatureCard(
            theme,
            Icons.compress_rounded,
            'کمینه‌سازی خودکار',
            'حذف خودکار حالت‌های غیرضروری و بهینه‌سازی DFA نهایی.',
          ),
        ],
      ),
    );
  }

  Widget _buildNFADiagram(ThemeData theme) {
    return SizedBox(
      width: 200.0,
      height: 120.0,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: 200.0,
            height: 120.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60.0),
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.8),
                  theme.colorScheme.primaryContainer.withOpacity(0.2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 30.0,
                  spreadRadius: 5.0,
                ),
              ],
            ),
          ),

          // NFA States
          Positioned(
            left: 30.0,
            top: 45.0,
            child: _buildStateNode(theme, 'q₀', true),
          ),
          Positioned(
            left: 90.0,
            top: 20.0,
            child: _buildStateNode(theme, 'q₁', false),
          ),
          Positioned(
            left: 90.0,
            top: 70.0,
            child: _buildStateNode(theme, 'q₂', false),
          ),
          Positioned(
            right: 30.0,
            top: 45.0,
            child: _buildStateNode(theme, 'q₃', false, isAccepting: true),
          ),

          // Transitions (simplified visual representation)
          Positioned(
            left: 75.0,
            top: 35.0,
            child: Text('a',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                )),
          ),
          Positioned(
            left: 75.0,
            top: 85.0,
            child: Text('ε',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveStateMachine(ThemeData theme) {
    final progress = _pulseController.value;

    return SizedBox(
      width: 250.0,
      height: 150.0,
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.secondaryContainer.withOpacity(0.8),
                  theme.colorScheme.secondaryContainer.withOpacity(0.2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                  blurRadius: 30.0,
                  spreadRadius: 5.0,
                ),
              ],
            ),
          ),

          // Animated processing path
          CustomPaint(
            size: const Size(250.0, 150.0),
            painter: ProcessingPathPainter(
              progress: progress,
              color: theme.colorScheme.secondary,
            ),
          ),

          // Central icon
          Center(
            child: Icon(
              Icons.visibility_rounded,
              size: 60.0,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransformationAnimation(ThemeData theme) {
    final progress = _nfaTransformController.value;

    return SizedBox(
      width: 280.0,
      height: 140.0,
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.tertiaryContainer.withOpacity(0.8),
                  theme.colorScheme.tertiaryContainer.withOpacity(0.2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.tertiary.withOpacity(0.3),
                  blurRadius: 30.0,
                  spreadRadius: 5.0,
                ),
              ],
            ),
          ),

          // NFA representation (left side)
          Positioned(
            left: 20.0,
            top: 50.0,
            child: Opacity(
              opacity: 1.0 - (progress * 0.5),
              child: Column(
                children: [
                  Text('NFA',
                      style: TextStyle(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      )),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      _buildMiniStateNode(theme, false),
                      const SizedBox(width: 4.0),
                      _buildMiniStateNode(theme, false),
                      const SizedBox(width: 4.0),
                      _buildMiniStateNode(theme, true),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Arrow
          Center(
            child: AnimatedBuilder(
              animation: _nfaTransformController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (progress * 0.2),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 30.0,
                    color: theme.colorScheme.tertiary,
                  ),
                );
              },
            ),
          ),

          // DFA representation (right side)
          Positioned(
            right: 20.0,
            top: 50.0,
            child: Opacity(
              opacity: 0.3 + (progress * 0.7),
              child: Column(
                children: [
                  Text('DFA',
                      style: TextStyle(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      )),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      _buildMiniStateNode(theme, false),
                      const SizedBox(width: 4.0),
                      _buildMiniStateNode(theme, true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateNode(ThemeData theme, String label, bool isStart,
      {bool isAccepting = false}) {
    return Container(
      width: 30.0,
      height: 30.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface,
        border: Border.all(
          color:
              isStart ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: isAccepting ? 3.0 : 2.0,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStateNode(ThemeData theme, bool isAccepting) {
    return Container(
      width: 12.0,
      height: 12.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.tertiary.withOpacity(0.3),
        border: Border.all(
          color: theme.colorScheme.tertiary,
          width: isAccepting ? 2.0 : 1.0,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
      ThemeData theme, IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 10.0,
            offset: const Offset(0.0, 2.0),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24.0),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Row(
      children: [
        if (_currentPage > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousPage,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                side: BorderSide(color: theme.colorScheme.primary),
              ),
              child: Text(
                'قبلی',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (_currentPage > 0) const SizedBox(width: 16.0),
        Expanded(
          flex: _currentPage == 0 ? 1 : 2,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final isLastPage = _currentPage == _totalPages - 1;
              final scale =
                  isLastPage ? 1.0 + (_pulseController.value * 0.05) : 1.0;

              return Transform.scale(
                scale: scale,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: isLastPage
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: isLastPage ? 8.0 : 4.0,
                    shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  child: Text(
                    isLastPage ? 'شروع طراحی آتوماتا' : 'بعدی',
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Custom painter for processing path animation
class ProcessingPathPainter extends CustomPainter {
  final double progress;
  final Color color;

  ProcessingPathPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const radius = 40.0;

    // Draw animated circle path
    final sweepAngle = progress * 2 * math.pi;
    path.addArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      0,
      sweepAngle,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
