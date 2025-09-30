import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'screens/home_screen.dart';
import 'screens/input_screen.dart';
import 'screens/result_screen.dart';
import 'screens/conversion_process_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/operations_screen.dart';
import 'screens/main_hub_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/examples_screen.dart';
import 'providers/nfa_provider.dart';
import 'providers/conversion_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NFAToDFAApp());
}

class NFAToDFAApp extends StatelessWidget {
  const NFAToDFAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NFAProvider()),
        ChangeNotifierProvider(create: (_) => ConversionProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(customTheme: settings.currentTheme),
            darkTheme: AppTheme.darkTheme(customTheme: settings.currentTheme),
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: AppConstants.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AppWrapper(),
            routes: _buildRoutes(),
            onGenerateRoute: _onGenerateRoute,
            onUnknownRoute: _onUnknownRoute,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.textScaleFactor),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/welcome': (context) => const WelcomeScreen(),
      '/main': (context) => const MainHubScreen(),
      AppRoutes.input: (context) => const InputScreen(),
      AppRoutes.result: (context) => const ResultScreen(),
      AppRoutes.conversion: (context) => const ConversionProcessScreen(),
      '/examples': (context) => const ExamplesScreen(),
    };
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.settings:
        return _buildPageRoute(const SettingsScreen(), settings: settings);
      case '/operations':
        return _buildPageRoute(const OperationsScreen(), settings: settings);
      default:
        return null;
    }
  }

  Route<dynamic> _onUnknownRoute(RouteSettings settings) {
    return _buildPageRoute(const UnknownScreen(), settings: settings);
  }

  PageRoute _buildPageRoute(Widget page, {required RouteSettings settings}) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: AppConstants.pageTransitionDuration,
    );
  }
}

// کلاس برای رسم خطوط هندسی متحرک
class GeometricLinesPainter extends CustomPainter {
  final double animationValue;

  GeometricLinesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paint2 = Paint()
      ..color = const Color(0xFF9333EA).withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // خطوط مورب متحرک
    for (int i = 0; i < 10; i++) {
      double offset = (animationValue * 100 + i * 50) % (size.width + 100);
      canvas.drawLine(
        Offset(offset - 50, 0),
        Offset(offset + 50, size.height),
        i % 2 == 0 ? paint : paint2,
      );
    }

    // خطوط افقی متحرک
    for (int i = 0; i < 8; i++) {
      double yOffset = (animationValue * 50 + i * 80) % (size.height + 80);
      canvas.drawLine(Offset(0, yOffset), Offset(size.width, yOffset), paint2);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});
  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  void _initializeApp() async {
    try {
      // بارگذاری تنظیمات
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      await settings.loadSettings();

      // بارگذاری پروژه‌های اخیر
      final nfaProvider = Provider.of<NFAProvider>(context, listen: false);
      await nfaProvider.loadRecentProjects();

      // حداقل 3 ثانیه منتظر بمان برای نمایش splash screen
      await Future.delayed(const Duration(seconds: 3));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing app: $e');
      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onAppPaused() {
    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      settings.saveSettings();
      final nfaProvider = Provider.of<NFAProvider>(context, listen: false);
      nfaProvider.saveCurrentProject();
    } catch (e) {
      print('Error saving data on pause: $e');
    }
  }

  void _onAppResumed() {
    try {
      final nfaProvider = Provider.of<NFAProvider>(context, listen: false);
      nfaProvider.checkExternalChanges();
    } catch (e) {
      print('Error on app resumed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<NFAProvider, ConversionProvider, SettingsProvider>(
      builder: (context, nfaProvider, conversionProvider, settings, child) {
        if (_isLoading || settings.isLoading || nfaProvider.isInitializing) {
          return const SplashScreen();
        }

        if (nfaProvider.hasCriticalError) {
          return ErrorScreen(
            error: nfaProvider.criticalError!,
            onRetry: () => nfaProvider.recoverFromError(),
            onReset: () => nfaProvider.resetToDefaults(),
          );
        }

        // اگر splash screen تمام شد، مستقیماً به welcome screen برو
        return const SplashScreen();
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _exitAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _exitFadeAnimation;
  late Animation<double> _exitScaleAnimation;
  late Animation<Offset> _exitSlideAnimation;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    // انیمیشن ورود
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // انیمیشن خروج
    _exitAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    // انیمیشن‌های خروج
    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitAnimationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _exitAnimationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _exitSlideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -0.2)).animate(
          CurvedAnimation(
            parent: _exitAnimationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
          ),
        );

    _animationController.forward();

    // بعد از 5 ثانیه شروع انیمیشن خروج
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _startExitAnimation();
      }
    });
  }

  void _startExitAnimation() async {
    setState(() {
      _isExiting = true;
    });

    await _exitAnimationController.forward();

    if (mounted) {
      _goToWelcomeScreen();
    }
  }

  void _goToWelcomeScreen() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // انیمیشن fade برای صفحه welcome
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _exitAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // پس‌زمینه گرادیان متحرک با انیمیشن خروج
          AnimatedBuilder(
            animation: Listenable.merge([
              _animationController,
              _exitAnimationController,
            ]),
            builder: (context, child) {
              double backgroundOpacity = _isExiting
                  ? _exitFadeAnimation.value
                  : _animationController.value;

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF0F0C29),
                        const Color(0xFF24243e),
                        _animationController.value,
                      )!.withOpacity(backgroundOpacity),
                      Color.lerp(
                        const Color(0xFF24243e),
                        const Color(0xFF302B63),
                        _animationController.value,
                      )!.withOpacity(backgroundOpacity),
                      Color.lerp(
                        const Color(0xFF302B63),
                        const Color(0xFF0F0C29),
                        _animationController.value,
                      )!.withOpacity(backgroundOpacity),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // ذرات متحرک در پس‌زمینه با انیمیشن خروج
          ...List.generate(20, (index) {
            return AnimatedBuilder(
              animation: Listenable.merge([
                _animationController,
                _exitAnimationController,
              ]),
              builder: (context, child) {
                double animValue =
                    (_animationController.value + index * 0.1) % 1.0;
                double particleOpacity = _isExiting
                    ? (0.1 + (animValue * 0.2)) * _exitFadeAnimation.value
                    : (0.1 + (animValue * 0.2));

                return Positioned(
                  left: (index * 50.0) % MediaQuery.of(context).size.width,
                  top: animValue * MediaQuery.of(context).size.height,
                  child: Transform.rotate(
                    angle: animValue * 6.28, // 2π
                    child: Container(
                      width: 4 + (index % 3) * 2,
                      height: 4 + (index % 3) * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(particleOpacity),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF9333EA,
                            ).withOpacity(0.3 * particleOpacity),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // دایره‌های نئونی در کناره‌ها با انیمیشن خروج
          Positioned(
            top: -50,
            left: -50,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _animationController,
                _exitAnimationController,
              ]),
              builder: (context, child) {
                double circleOpacity = _isExiting
                    ? _exitFadeAnimation.value
                    : 1.0;
                return Transform.rotate(
                  angle: _animationController.value * 2,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(
                            0xFF9333EA,
                          ).withOpacity(0.3 * circleOpacity),
                          const Color(
                            0xFF9333EA,
                          ).withOpacity(0.1 * circleOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: -80,
            right: -80,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _animationController,
                _exitAnimationController,
              ]),
              builder: (context, child) {
                double circleOpacity = _isExiting
                    ? _exitFadeAnimation.value
                    : 1.0;
                return Transform.rotate(
                  angle: -_animationController.value * 1.5,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(
                            0xFF7C3AED,
                          ).withOpacity(0.4 * circleOpacity),
                          const Color(
                            0xFF7C3AED,
                          ).withOpacity(0.2 * circleOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // خطوط هندسی متحرک
          AnimatedBuilder(
            animation: _exitAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _isExiting ? _exitFadeAnimation.value : 1.0,
                child: CustomPaint(
                  size: Size(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height,
                  ),
                  painter: GeometricLinesPainter(_animationController.value),
                ),
              );
            },
          ),

          // محتوای اصلی با انیمیشن خروج
          AnimatedBuilder(
            animation: Listenable.merge([
              _animationController,
              _exitAnimationController,
            ]),
            builder: (context, child) {
              return Center(
                child: SlideTransition(
                  position: _isExiting
                      ? _exitSlideAnimation
                      : AlwaysStoppedAnimation(Offset.zero),
                  child: ScaleTransition(
                    scale: _isExiting ? _exitScaleAnimation : _scaleAnimation,
                    child: FadeTransition(
                      opacity: _isExiting ? _exitFadeAnimation : _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // آیکون بزرگ و جذاب با گلو و نئون
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF9333EA),
                                  Color(0xFF7C3AED),
                                  Color(0xFF6D28D9),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF9333EA,
                                  ).withOpacity(0.6),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFF7C3AED,
                                  ).withOpacity(0.4),
                                  blurRadius: 60,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_tree_rounded,
                              size: 90,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // عنوان با افکت گلو
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Text(
                              'NFA to DFA Converter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFF9333EA),
                                    blurRadius: 10,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // قسمت توسعه‌دهندگان با کادر شفاف
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Developers',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Navid Afzali',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Dr.Seyed Ali Hosseini',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 50),

                          // نقاط بارگذاری پیشرفته
                          SizedBox(
                            width: 80,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(3, (index) {
                                return AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    double delay = index * 0.3;
                                    double animationValue =
                                        ((_animationController.value * 2 -
                                                    delay) %
                                                2.0)
                                            .clamp(0.0, 1.0);
                                    double scale = 0.5 + (0.5 * animationValue);

                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF9333EA),
                                              Color(0xFF7C3AED),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF9333EA,
                                              ).withOpacity(0.6),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),
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
        ],
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onReset;

  const ErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'خطای سیستم',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('تلاش مجدد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.restore),
                    label: const Text('بازنشانی'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UnknownScreen extends StatelessWidget {
  const UnknownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صفحه پیدا نشد'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'صفحه مورد نظر پیدا نشد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/main', (route) => false),
              icon: const Icon(Icons.home),
              label: const Text('بازگشت به خانه'),
            ),
          ],
        ),
      ),
    );
  }
}
