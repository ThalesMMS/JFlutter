// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('fa', 'IR');
  double _textScaleFactor = 1.0;
  bool _isLoading = true;

  String _currentTheme = 'cyberpunk';
  bool _useGradientBackgrounds = true;
  bool _enableGlassomorphism = true;
  bool _enableParticleEffects = false;
  bool _enableNeonEffects = true;
  double _animationSpeed = 1.0;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  double get textScaleFactor => _textScaleFactor;
  bool get isLoading => _isLoading;
  String get currentTheme => _currentTheme;
  bool get useGradientBackgrounds => _useGradientBackgrounds;
  bool get enableGlassomorphism => _enableGlassomorphism;
  bool get enableParticleEffects => _enableParticleEffects;
  bool get enableNeonEffects => _enableNeonEffects;
  double get animationSpeed => _animationSpeed;

  // لیست تم‌های موجود
  List<String> get availableThemes => [
    'cyberpunk',
    'aurora',
    'galaxy',
    'sunset',
    'ocean',
    'forest',
    'volcano',
    'arctic',
    'rainbow',
    'minimal_glass'
  ];

  Future<void> loadSettings() async {
    _isLoading = true;

    try {

      await Future.delayed(const Duration(milliseconds: 500));

    } catch (e) {

      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  Future<void> saveSettings() async {
    try {

    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  void updateThemeMode(ThemeMode? newThemeMode) {
    if (newThemeMode == null || newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    saveSettings();
  }

  // تغییر زبان برنامه
  void updateLocale(Locale newLocale) {
    if (newLocale == _locale) return;
    _locale = newLocale;
    notifyListeners();
    saveSettings();
  }

  // تغییر اندازه فونت
  void updateTextScaleFactor(double newScale) {
    if (newScale < 0.5 || newScale > 2.0) return;
    if (newScale == _textScaleFactor) return;
    _textScaleFactor = newScale;
    notifyListeners();
    saveSettings();
  }

  // تغییر تم جاری
  void updateCurrentTheme(String newTheme) {
    if (!availableThemes.contains(newTheme) || newTheme == _currentTheme) return;
    _currentTheme = newTheme;
    notifyListeners();
    saveSettings();
  }

  // تغییر وضعیت پس‌زمینه گرادیانی
  void toggleGradientBackgrounds() {
    _useGradientBackgrounds = !_useGradientBackgrounds;
    notifyListeners();
    saveSettings();
  }

  // تغییر وضعیت گلاسمورفیسم
  void toggleGlassomorphism() {
    _enableGlassomorphism = !_enableGlassomorphism;
    notifyListeners();
    saveSettings();
  }

  // تغییر وضعیت افکت‌های ذرات
  void toggleParticleEffects() {
    _enableParticleEffects = !_enableParticleEffects;
    notifyListeners();
    saveSettings();
  }

  // تغییر وضعیت افکت‌های نئون
  void toggleNeonEffects() {
    _enableNeonEffects = !_enableNeonEffects;
    notifyListeners();
    saveSettings();
  }

  void updateAnimationSpeed(double newSpeed) {
    if (newSpeed < 0.1 || newSpeed > 3.0) return;
    if (newSpeed == _animationSpeed) return;
    _animationSpeed = newSpeed;
    notifyListeners();
    saveSettings();
  }

  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _locale = const Locale('fa', 'IR');
    _textScaleFactor = 1.0;
    _currentTheme = 'cyberpunk';
    _useGradientBackgrounds = true;
    _enableGlassomorphism = true;
    _enableParticleEffects = false;
    _enableNeonEffects = true;
    _animationSpeed = 1.0;

    notifyListeners();
    await saveSettings();
  }

  String getThemeDescription(String theme) {
    switch (theme) {
      case 'cyberpunk':
        return 'تم سایبرپانک با رنگ‌های نئون و طراحی آینده‌نگر';
      case 'aurora':
        return 'تم شفق قطبی با رنگ‌های زیبا و درخشان';
      case 'galaxy':
        return 'تم کهکشانی با رنگ‌های فضایی و ستاره‌ای';
      case 'sunset':
        return 'تم غروب آفتاب با رنگ‌های گرم و آرام‌بخش';
      case 'ocean':
        return 'تم اقیانوسی با آبی‌های عمیق و آرامش‌بخش';
      case 'forest':
        return 'تم جنگلی با سبزهای طبیعی و تازگی';
      case 'volcano':
        return 'تم آتشفشانی با قرمزها و نارنجی‌های داغ';
      case 'arctic':
        return 'تم قطبی با سفیدی و آبی‌های یخی';
      case 'rainbow':
        return 'تم رنگین‌کمانی با طیف کامل رنگ‌ها';
      case 'minimal_glass':
        return 'تم شیشه‌ای مینیمال با شفافیت و زیبایی';
      default:
        return 'تم زیبا و منحصر به فرد';
    }
  }

  Color getThemePrimaryColor(String theme) {
    switch (theme) {
      case 'cyberpunk':
        return const Color(0xFF00FFFF);
      case 'aurora':
        return const Color(0xFF7B68EE);
      case 'galaxy':
        return const Color(0xFF9370DB);
      case 'sunset':
        return const Color(0xFFFF6B6B);
      case 'ocean':
        return const Color(0xFF4ECDC4);
      case 'forest':
        return const Color(0xFF2ECC71);
      case 'volcano':
        return const Color(0xFFE74C3C);
      case 'arctic':
        return const Color(0xFF74B9FF);
      case 'rainbow':
        return const Color(0xFFFF69B4);
      case 'minimal_glass':
        return const Color(0xFF6C5CE7);
      default:
        return const Color(0xFF1976D2);
    }
  }
}