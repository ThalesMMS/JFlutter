import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // اطلاعات اپلیکیشن
  static const String appName = 'NFA to DFA Converter';
  static const String appVersion = '2.0.0';
  static const String appDescription =
      'تبدیل‌کننده NFA به DFA با رابط کاربری پیشرفته و تم‌های خیره‌کننده';

  // تنظیمات فونت
  static const String defaultFontFamily = 'Vazir';
  static const String englishFontFamily = 'Roboto';
  static const String neonFontFamily = 'Orbitron';
  static const String modernFontFamily = 'Montserrat';

  // اندازه‌های فونت استاندارد
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 20.0;
  static const double fontSizeHuge = 24.0;
  static const double fontSizeGiant = 32.0;

  // فاصله‌ها و اندازه‌ها
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  static const double megaPadding = 48.0;

  // شعاع گوشه‌های مدور
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double extraLargeBorderRadius = 24.0;
  static const double circularBorderRadius = 50.0;

  // ارتفاع‌های استاندارد
  static const double defaultInputHeight = 56.0;
  static const double buttonHeight = 48.0;
  static const double largeButtonHeight = 64.0;
  static const double appBarHeight = 64.0;
  static const double bottomNavHeight = 64.0;
  static const double cardHeight = 120.0;

  // سایه و elevation
  static const double defaultElevation = 2.0;
  static const double cardElevation = 4.0;
  static const double dialogElevation = 8.0;
  static const double maxElevation = 16.0;

  // مدت زمان انیمیشن‌ها
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration neonPulseDuration = Duration(milliseconds: 1500);
  static const Duration glowAnimationDuration = Duration(milliseconds: 2000);

  // زبان‌های پشتیبانی شده
  static const List<Locale> supportedLocales = [
    Locale('fa', 'IR'),
    Locale('en', 'US'),
    Locale('ar', 'SA'),
  ];

  // حداکثر و حداقل‌ها
  static const int maxStateNameLength = 20;
  static const int minStateNameLength = 1;
  static const int maxTransitionSymbols = 50;
  static const int maxStatesCount = 100;
  static const double maxTextScale = 2.0;
  static const double minTextScale = 0.5;
  static const double maxAnimationSpeed = 3.0;
  static const double minAnimationSpeed = 0.1;

  // الگوهای اعتبارسنجی (RegExp patterns)
  static const String stateNamePattern = r'^[a-zA-Z0-9_]+$';
  static const String symbolPattern = r'^[a-zA-Z0-9]$';
  static const String transitionPattern = r'^[a-zA-Z0-9,\s]+$';
  static const String colorCodePattern = r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$';

  // پیام‌های خطا و اعلان‌ها
  static const Map<String, String> errorMessages = {
    'fieldRequired': 'این فیلد اجباری است',
    'invalidInput': 'ورودی نامعتبر است',
    'stateExists': 'یک state با این نام وجود دارد',
    'invalidStateName': 'نام state فقط می‌تواند شامل حروف، اعداد و _ باشد',
    'stateTooLong':
        'نام state نمی‌تواند بیش از $maxStateNameLength کاراکتر باشد',
    'stateTooShort':
        'نام state نمی‌تواند کمتر از $minStateNameLength کاراکتر باشد',
    'tooManyStates': 'تعداد حالت‌ها نمی‌تواند بیش از $maxStatesCount باشد',
    'networkError': 'خطا در اتصال به شبکه',
    'unknownError': 'خطای ناشناخته رخ داده است',
    'themeLoadError': 'خطا در بارگذاری تم',
    'animationError': 'خطا در اجرای انیمیشن',
  };

  static const Map<String, String> successMessages = {
    'stateAdded': 'حالت با موفقیت اضافه شد',
    'stateRemoved': 'حالت با موفقیت حذف شد',
    'transitionAdded': 'انتقال با موفقیت اضافه شد',
    'conversionCompleted': 'تبدیل با موفقیت انجام شد',
    'dataSaved': 'اطلاعات با موفقیت ذخیره شد',
    'themeChanged': 'تم با موفقیت تغییر یافت',
    'settingsUpdated': 'تنظیمات با موفقیت بروزرسانی شد',
  };

  static const Map<String, String> infoMessages = {
    'selectInitialState': 'لطفاً حالت اولیه را انتخاب کنید',
    'addFinalStates': 'حالت‌های نهایی را مشخص کنید',
    'defineTransitions': 'انتقال‌ها را تعریف کنید',
    'reviewResult': 'نتیجه تبدیل را بررسی کنید',
    'themePreview': 'پیش‌نمایش تم جدید',
    'experimentalFeature': 'این قابلیت در حال آزمایش است',
  };

  // آیکون‌های پیش‌فرض
  static const Map<String, IconData> defaultIcons = {
    'add': Icons.add_rounded,
    'remove': Icons.remove_rounded,
    'edit': Icons.edit_rounded,
    'delete': Icons.delete_rounded,
    'save': Icons.save_rounded,
    'cancel': Icons.cancel_rounded,
    'confirm': Icons.check_rounded,
    'info': Icons.info_rounded,
    'warning': Icons.warning_rounded,
    'error': Icons.error_rounded,
    'success': Icons.check_circle_rounded,
    'home': Icons.home_rounded,
    'settings': Icons.settings_rounded,
    'help': Icons.help_rounded,
    'search': Icons.search_rounded,
    'filter': Icons.filter_list_rounded,
    'sort': Icons.sort_rounded,
    'refresh': Icons.refresh_rounded,
    'share': Icons.share_rounded,
    'download': Icons.download_rounded,
    'upload': Icons.upload_rounded,
    'copy': Icons.copy_rounded,
    'paste': Icons.paste_rounded,
    'clear': Icons.clear_rounded,
    'visibility': Icons.visibility_rounded,
    'visibilityOff': Icons.visibility_off_rounded,
    'expand': Icons.expand_more_rounded,
    'collapse': Icons.expand_less_rounded,
    'next': Icons.arrow_forward_rounded,
    'previous': Icons.arrow_back_rounded,
    'up': Icons.keyboard_arrow_up_rounded,
    'down': Icons.keyboard_arrow_down_rounded,
    'play': Icons.play_arrow_rounded,
    'pause': Icons.pause_rounded,
    'stop': Icons.stop_rounded,
    'reset': Icons.restart_alt_rounded,
    'theme': Icons.palette_rounded,
    'colorPicker': Icons.color_lens_rounded,
    'animation': Icons.animation_rounded,
    'effects': Icons.auto_awesome_rounded,
    'glow': Icons.flare_rounded,
    'gradient': Icons.gradient_rounded,
    'sparkle': Icons.star_rounded,
    'magic': Icons.auto_fix_high_rounded,
  };

  // کلیدهای SharedPreferences
  static const Map<String, String> prefKeys = {
    'isDarkMode': 'isDarkMode',
    'selectedLanguage': 'selectedLanguage',
    'isFirstRun': 'isFirstRun',
    'lastUsedNFA': 'lastUsedNFA',
    'userPreferences': 'userPreferences',
    'autoSaveEnabled': 'autoSaveEnabled',
    'animationsEnabled': 'animationsEnabled',
    'currentTheme': 'currentTheme',
    'useGradientBackgrounds': 'useGradientBackgrounds',
    'enableGlassomorphism': 'enableGlassomorphism',
    'enableParticleEffects': 'enableParticleEffects',
    'enableNeonEffects': 'enableNeonEffects',
    'animationSpeed': 'animationSpeed',
    'customColors': 'customColors',
    'themePreferences': 'themePreferences',
  };

  // تنظیمات پیش‌فرض
  static const Map<String, dynamic> defaultSettings = {
    'isDarkMode': false,
    'selectedLanguage': 'fa',
    'autoSaveEnabled': true,
    'animationsEnabled': true,
    'showTutorial': true,
    'compactView': false,
    'currentTheme': 'cyberpunk',
    'useGradientBackgrounds': true,
    'enableGlassomorphism': true,
    'enableParticleEffects': false,
    'enableNeonEffects': true,
    'animationSpeed': 1.0,
    'showAdvancedFeatures': true,
    'enableHapticFeedback': true,
  };

  // تنظیمات افکت‌های ویژوال
  static const Map<String, double> visualEffectSettings = {
    'glowIntensity': 1.0,
    'particleCount': 50.0,
    'animationScale': 1.0,
    'blurRadius': 10.0,
    'shadowOpacity': 0.3,
    'borderOpacity': 0.5,
    'backgroundOpacity': 0.1,
    'gradientStops': 3.0,
  };
}

/// کلاس مدیریت مسیرهای اپلیکیشن با پشتیبانی از پارامترها
class AppRoutes {
  AppRoutes._();

  // مسیرهای اصلی
  static const String home = '/';
  static const String input = '/input';
  static const String result = '/result';
  static const String conversion = '/conversion';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String about = '/about';
  static const String tutorial = '/tutorial';
  static const String themes = '/themes';
  static const String customization = '/customization';

  // مسیرهای پیشرفته با پارامتر
  static const String stateDetails = '/state/:id';
  static const String transitionDetails = '/transition/:id';
  static const String conversionHistory = '/history';
  static const String export = '/export';
  static const String import = '/import';
  static const String themeEditor = '/theme-editor';
  static const String preview = '/preview';

  // متدهای کمکی برای ساخت مسیر با پارامتر
  static String stateDetailsWithId(String id) => '/state/$id';
  static String transitionDetailsWithId(String id) => '/transition/$id';

  // نقشه مسیرها برای استفاده آسان‌تر
  static const Map<String, String> routeNames = {
    home: 'خانه',
    input: 'ورودی',
    result: 'نتیجه',
    conversion: 'تبدیل',
    settings: 'تنظیمات',
    help: 'راهنما',
    about: 'درباره',
    tutorial: 'آموزش',
    conversionHistory: 'تاریخچه',
    export: 'صادرات',
    import: 'واردات',
    themes: 'تم‌ها',
    customization: 'سفارشی‌سازی',
    themeEditor: 'ویرایشگر تم',
    preview: 'پیش‌نمایش',
  };
}

/// کلاس مدیریت رنگ‌های وضعیت و تخصصی
class StatusColors {
  StatusColors._();

  // رنگ‌های وضعیت استاندارد
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // رنگ‌های وضعیت با شفافیت
  static const Color successLight = Color(0xFFE8F5E8);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color infoLight = Color(0xFFE3F2FD);

  // رنگ‌های تخصصی برای اتوماتا
  static const Color stateColor = Color(0xFF3F51B5);
  static const Color initialStateColor = Color(0xFF4CAF50);
  static const Color finalStateColor = Color(0xFFFF5722);
  static const Color transitionColor = Color(0xFF9C27B0);
  static const Color selectedColor = Color(0xFFFFEB3B);

  // رنگ‌های گرادیان پیشرفته
  static const List<Color> primaryGradient = [
    Color(0xFF1976D2),
    Color(0xFF42A5F5),
  ];

  static const List<Color> successGradient = [
    Color(0xFF4CAF50),
    Color(0xFF81C784),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFF9800),
    Color(0xFFFFB74D),
  ];

  static const List<Color> errorGradient = [
    Color(0xFFF44336),
    Color(0xFFEF5350),
  ];

  // گرادیان‌های تم‌های خیره‌کننده
  static const List<Color> cyberpunkGradient = [
    Color(0xFF00FFFF),
    Color(0xFF0080FF),
    Color(0xFF8000FF),
    Color(0xFFFF00FF),
  ];

  static const List<Color> auroraGradient = [
    Color(0xFF7B68EE),
    Color(0xFF20B2AA),
    Color(0xFF00CED1),
    Color(0xFF98FB98),
  ];

  static const List<Color> galaxyGradient = [
    Color(0xFF9370DB),
    Color(0xFF4169E1),
    Color(0xFF1E90FF),
    Color(0xFF87CEEB),
  ];

  static const List<Color> sunsetGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E53),
    Color(0xFFFFE66D),
    Color(0xFFFF7F50),
  ];

  static const List<Color> oceanGradient = [
    Color(0xFF4ECDC4),
    Color(0xFF44A08D),
    Color(0xFF096DD9),
    Color(0xFF1890FF),
  ];

  static const List<Color> forestGradient = [
    Color(0xFF2ECC71),
    Color(0xFF27AE60),
    Color(0xFF58D68D),
    Color(0xFF85C1E9),
  ];

  static const List<Color> volcanoGradient = [
    Color(0xFFE74C3C),
    Color(0xFFFF5722),
    Color(0xFFFF9800),
    Color(0xFFFFEB3B),
  ];

  static const List<Color> arcticGradient = [
    Color(0xFF74B9FF),
    Color(0xFF00CEC9),
    Color(0xFFA29BFE),
    Color(0xFFDDA0DD),
  ];

  static const List<Color> rainbowGradient = [
    Color(0xFFFF0080),
    Color(0xFF8A2BE2),
    Color(0xFF00CED1),
    Color(0xFF32CD32),
    Color(0xFFFFD700),
    Color(0xFFFF6347),
  ];

  static const List<Color> minimalGlassGradient = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
    Color(0xFFa8edea),
    Color(0xFFfed6e3),
  ];

  // رنگ‌های نئون برای افکت‌های خاص
  static const Map<String, Color> neonColors = {
    'cyan': Color(0xFF00FFFF),
    'magenta': Color(0xFFFF00FF),
    'lime': Color(0xFF00FF00),
    'yellow': Color(0xFFFFFF00),
    'orange': Color(0xFFFF8000),
    'pink': Color(0xFFFF69B4),
    'purple': Color(0xFF8A2BE2),
    'blue': Color(0xFF0080FF),
    'red': Color(0xFFFF0040),
    'green': Color(0xFF40FF00),
  };

  // رنگ‌های شیشه‌ای برای گلاسمورفیسم
  static const Map<String, Color> glassColors = {
    'frosted': Color(0xFFFFFFFF),
    'tinted': Color(0xFF000000),
    'colored': Color(0xFF4285F4),
    'warm': Color(0xFFFF6B35),
    'cool': Color(0xFF4ECDC4),
  };
}

/// کلاس مدیریت انیمیشن‌ها و منحنی‌های حرکتی پیشرفته
class AppAnimations {
  AppAnimations._();

  // منحنی‌های انیمیشن استاندارد
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticIn = Curves.elasticIn;
  static const Curve elasticOut = Curves.elasticOut;

  // منحنی‌های انیمیشن پیشرفته
  static const Curve smoothStep = Curves.easeInOutCubic;
  static const Curve dramatic = Curves.easeInOutExpo;
  static const Curve gentle = Curves.easeInOutSine;
  static const Curve sharp = Curves.easeInOutQuart;
  static const Curve fluid = Curves.easeInOutCirc;

  // مدت زمان‌های انیمیشن برای موارد خاص
  static const Duration microAnimationDuration = Duration(milliseconds: 50);
  static const Duration buttonTapDuration = Duration(milliseconds: 100);
  static const Duration cardHoverDuration = Duration(milliseconds: 200);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration dialogAnimationDuration = Duration(milliseconds: 250);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration neonPulseDuration = Duration(milliseconds: 1500);
  static const Duration glowCycleDuration = Duration(milliseconds: 2000);
  static const Duration particleAnimationDuration =
      Duration(milliseconds: 3000);
  static const Duration backgroundShiftDuration = Duration(seconds: 10);

  // تاخیرها برای انیمیشن‌های متوالی
  static const Duration staggerDelay = Duration(milliseconds: 50);
  static const Duration sequentialDelay = Duration(milliseconds: 100);
  static const Duration cascadeDelay = Duration(milliseconds: 150);
  static const Duration waveDelay = Duration(milliseconds: 200);

  // مقادیر انیمیشن
  static const double defaultOpacity = 0.0;
  static const double maxOpacity = 1.0;
  static const double pulseScale = 1.05;
  static const double pressScale = 0.95;
  static const double hoverScale = 1.02;
  static const double glowIntensity = 2.0;

  // متدهای کمکی برای انیمیشن‌ها
  static Duration getScaledDuration(Duration base, double speed) {
    return Duration(
      milliseconds: (base.inMilliseconds / speed).round(),
    );
  }

  static Curve getCombinedCurve(Curve primary, Curve secondary, double t) {
    return t < 0.5 ? primary : secondary;
  }
}

/// کلاس مدیریت اندازه‌های واکنش‌گرا پیشرفته
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  // نقاط شکست اصلی
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1800;
  static const double ultraWide = 2400;

  // نقاط شکست جزئی
  static const double smallMobile = 360;
  static const double largeMobile = 480;
  static const double smallTablet = 768;
  static const double largeTablet = 1024;
  static const double smallDesktop = 1366;
  static const double mediumDesktop = 1440;

  // متد تشخیص نوع دستگاه پیشرفته
  static DeviceType getDeviceType(double width) {
    if (width < smallMobile) return DeviceType.smallMobile;
    if (width < mobile) return DeviceType.mobile;
    if (width < tablet) return DeviceType.tablet;
    if (width < desktop) return DeviceType.desktop;
    if (width < largeDesktop) return DeviceType.largeDesktop;
    return DeviceType.ultraWide;
  }

  // محاسبه فاکتور مقیاس بر اساس عرض صفحه
  static double getScaleFactor(double width) {
    if (width < mobile) return 0.8;
    if (width < tablet) return 0.9;
    if (width < desktop) return 1.0;
    if (width < largeDesktop) return 1.1;
    return 1.2;
  }

  // تعداد ستون‌های grid بر اساس عرض
  static int getGridColumns(double width) {
    if (width < mobile) return 1;
    if (width < tablet) return 2;
    if (width < desktop) return 3;
    if (width < largeDesktop) return 4;
    return 5;
  }
}

/// enum برای انواع دستگاه پیشرفته
enum DeviceType {
  smallMobile,
  mobile,
  tablet,
  desktop,
  largeDesktop,
  ultraWide,
}

/// کلاس مدیریت تم‌های پیش‌ساخته
class ThemePresets {
  ThemePresets._();

  static const Map<String, Map<String, dynamic>> presets = {
    'cyberpunk': {
      'name': 'سایبرپانک',
      'description': 'تم آینده‌نگر با رنگ‌های نئون',
      'primaryColor': 0xFF00FFFF,
      'accentColor': 0xFF39FF14,
      'backgroundColor': 0xFF0A0A0A,
      'useGradient': true,
      'enableGlow': true,
      'fontFamily': 'Orbitron',
      'category': 'futuristic',
    },
    'aurora': {
      'name': 'شفق قطبی',
      'description': 'الهام‌گرفته از شفق‌های زیبای شمالی',
      'primaryColor': 0xFF7B68EE,
      'accentColor': 0xFF20B2AA,
      'backgroundColor': 0xFF1C1C3A,
      'useGradient': true,
      'enableGlow': true,
      'fontFamily': 'Vazir',
      'category': 'nature',
    },
    'galaxy': {
      'name': 'کهکشان',
      'description': 'سفری در اعماق فضا',
      'primaryColor': 0xFF9370DB,
      'accentColor': 0xFF4169E1,
      'backgroundColor': 0xFF191970,
      'useGradient': true,
      'enableGlow': true,
      'fontFamily': 'Vazir',
      'category': 'space',
    },
    'sunset': {
      'name': 'غروب',
      'description': 'آرامش و زیبایی غروب آفتاب',
      'primaryColor': 0xFFFF6B6B,
      'accentColor': 0xFFFFE66D,
      'backgroundColor': 0xFF2C1810,
      'useGradient': true,
      'enableGlow': false,
      'fontFamily': 'Vazir',
      'category': 'warm',
    },
    'ocean': {
      'name': 'اقیانوس',
      'description': 'عمق و آرامش دریا',
      'primaryColor': 0xFF4ECDC4,
      'accentColor': 0xFF44A08D,
      'backgroundColor': 0xFF0A2E3B,
      'useGradient': true,
      'enableGlow': false,
      'fontFamily': 'Vazir',
      'category': 'cool',
    },
    'forest': {
      'name': 'جنگل',
      'description': 'سبزی و طراوت طبیعت',
      'primaryColor': 0xFF2ECC71,
      'accentColor': 0xFF27AE60,
      'backgroundColor': 0xFF0F1B0C,
      'useGradient': true,
      'enableGlow': false,
      'fontFamily': 'Vazir',
      'category': 'nature',
    },
    'volcano': {
      'name': 'آتشفشان',
      'description': 'قدرت و انرژی زمین',
      'primaryColor': 0xFFE74C3C,
      'accentColor': 0xFFFF5722,
      'backgroundColor': 0xFF2C0E0E,
      'useGradient': true,
      'enableGlow': true,
      'fontFamily': 'Vazir',
      'category': 'fire',
    },
    'arctic': {
      'name': 'قطبی',
      'description': 'سردی و زیبایی قطب',
      'primaryColor': 0xFF74B9FF,
      'accentColor': 0xFF00CEC9,
      'backgroundColor': 0xFF0C1821,
      'useGradient': true,
      'enableGlow': false,
      'fontFamily': 'Vazir',
      'category': 'cool',
    },
    'rainbow': {
      'name': 'رنگین‌کمان',
      'description': 'جشن رنگ‌ها و شادی',
      'primaryColor': 0xFFFF69B4,
      'accentColor': 0xFF00CED1,
      'backgroundColor': 0xFF1A1A1A,
      'useGradient': true,
      'enableGlow': true,
      'fontFamily': 'Vazir',
      'category': 'colorful',
    },
    'minimal_glass': {
      'name': 'شیشه مینیمال',
      'description': 'سادگی و شفافیت مدرن',
      'primaryColor': 0xFF6C5CE7,
      'accentColor': 0xFFA29BFE,
      'backgroundColor': 0xFF1E1E2E,
      'useGradient': true,
      'enableGlow': false,
      'fontFamily': 'Montserrat',
      'category': 'minimal',
    },
  };

  static Map<String, dynamic>? getPreset(String themeName) {
    return presets[themeName];
  }

  static List<String> getThemesByCategory(String category) {
    return presets.entries
        .where((entry) => entry.value['category'] == category)
        .map((entry) => entry.key)
        .toList();
  }
}

/// کلاس مدیریت API و اتصالات شبکه برای آینده
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.example.com';
  static const String apiVersion = 'v1';
  static const Duration timeoutDuration = Duration(seconds: 30);

  // headers پیش‌فرض
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'NFAtoDFA/2.0.0',
  };

  // endpoints
  static const Map<String, String> endpoints = {
    'themes': '/themes',
    'conversion': '/convert',
    'validation': '/validate',
    'export': '/export',
    'import': '/import',
  };
}

/// کلاس مدیریت فایل‌ها و مسیرها
class FileConstants {
  FileConstants._();

  static const String documentsFolder = 'documents';
  static const String imagesFolder = 'images';
  static const String tempFolder = 'temp';
  static const String themesFolder = 'themes';
  static const String assetsFolder = 'assets';

  // پسوندهای فایل
  static const String jsonExtension = '.json';
  static const String pngExtension = '.png';
  static const String svgExtension = '.svg';
  static const String themeExtension = '.theme';

  // نام‌های فایل پیش‌فرض
  static const String defaultNFAFile = 'nfa_data.json';
  static const String defaultDFAFile = 'dfa_result.json';
  static const String settingsFile = 'settings.json';
  static const String themesFile = 'themes.json';
  static const String customThemeFile = 'custom_theme.json';
}

/// کلاس مدیریت لاگ‌ها و دیباگ
class DebugConstants {
  DebugConstants._();

  static const bool enableLogging = true;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableThemeDebugging = false;
  static const String logTag = 'NFAtoDFA';

  // سطوح لاگ
  static const int logLevelVerbose = 0;
  static const int logLevelDebug = 1;
  static const int logLevelInfo = 2;
  static const int logLevelWarning = 3;
  static const int logLevelError = 4;

  // پیام‌های دیباگ
  static const Map<String, String> debugMessages = {
    'themeLoaded': 'تم بارگذاری شد',
    'animationStarted': 'انیمیشن شروع شد',
    'effectApplied': 'افکت اعمال شد',
    'performanceWarning': 'هشدار عملکرد',
  };
}

/// کلاس مدیریت تنظیمات دسترسی‌پذیری
class AccessibilityConstants {
  AccessibilityConstants._();

  // سطوح کنتراست
  static const double minContrastRatio = 4.5;
  static const double preferredContrastRatio = 7.0;

  // اندازه‌های حداقل برای لمس
  static const double minTouchTargetSize = 44.0;
  static const double preferredTouchTargetSize = 48.0;

  // تنظیمات متن
  static const double maxTextScaleFactor = 2.0;
  static const double minTextScaleFactor = 0.5;

  // مدت زمان انیمیشن برای کاربران حساس
  static const Duration reducedMotionDuration = Duration(milliseconds: 100);

  // پیام‌های صوتی
  static const Map<String, String> semanticLabels = {
    'addState': 'افزودن حالت جدید',
    'removeState': 'حذف حالت',
    'selectTheme': 'انتخاب تم',
    'toggleDarkMode': 'تغییر به حالت تاریک',
    'increaseTextSize': 'افزایش اندازه متن',
    'decreaseTextSize': 'کاهش اندازه متن',
  };
}
