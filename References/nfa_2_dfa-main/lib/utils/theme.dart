import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  // رنگ‌های اصلی اپلیکیشن
  static const Color _primaryLight = Color(0xFF1976D2);
  static const Color _primaryDark = Color(0xFF64B5F6);
  static const Color _surfaceLight = Color(0xFFFAFAFA);
  static const Color _surfaceDark = Color(0xFF121212);

  /// تم‌های جذاب و خیره‌کننده
  static final Map<String, ThemeColors> _themeColors = {
    'cyberpunk': ThemeColors(
      primary: const Color(0xFF00FFFF),
      secondary: const Color(0xFFFF0080),
      accent: const Color(0xFF39FF14),
      background: const Color(0xFF0A0A0A),
      surface: const Color(0xFF1A1A2E),
      gradient: [
        const Color(0xFF16213E),
        const Color(0xFF0F3460),
        const Color(0xFF533483),
      ],
      neonGlow: const Color(0xFF00FFFF),
    ),
    'aurora': ThemeColors(
      primary: const Color(0xFF7B68EE),
      secondary: const Color(0xFF20B2AA),
      accent: const Color(0xFFFFB6C1),
      background: const Color(0xFF1C1C3A),
      surface: const Color(0xFF2D2D5A),
      gradient: [
        const Color(0xFF667eea),
        const Color(0xFF764ba2),
        const Color(0xFFf093fb),
      ],
      neonGlow: const Color(0xFF7B68EE),
    ),
    'galaxy': ThemeColors(
      primary: const Color(0xFF9370DB),
      secondary: const Color(0xFF4169E1),
      accent: const Color(0xFFDDA0DD),
      background: const Color(0xFF191970),
      surface: const Color(0xFF2F2F85),
      gradient: [
        const Color(0xFF2C1810),
        const Color(0xFF4A148C),
        const Color(0xFF7B1FA2),
      ],
      neonGlow: const Color(0xFF9370DB),
    ),
    'sunset': ThemeColors(
      primary: const Color(0xFFFF6B6B),
      secondary: const Color(0xFFFFE66D),
      accent: const Color(0xFFFF8E53),
      background: const Color(0xFF2C1810),
      surface: const Color(0xFF4A2C2A),
      gradient: [
        const Color(0xFFFF512F),
        const Color(0xFFDD2476),
        const Color(0xFFFF6B35),
      ],
      neonGlow: const Color(0xFFFF6B6B),
    ),
    'ocean': ThemeColors(
      primary: const Color(0xFF4ECDC4),
      secondary: const Color(0xFF44A08D),
      accent: const Color(0xFF096DD9),
      background: const Color(0xFF0A2E3B),
      surface: const Color(0xFF1B4B5A),
      gradient: [
        const Color(0xFF667db6),
        const Color(0xFF0082c8),
        const Color(0xFF667db6),
      ],
      neonGlow: const Color(0xFF4ECDC4),
    ),
    'forest': ThemeColors(
      primary: const Color(0xFF2ECC71),
      secondary: const Color(0xFF27AE60),
      accent: const Color(0xFF58D68D),
      background: const Color(0xFF0F1B0C),
      surface: const Color(0xFF1D3A1A),
      gradient: [
        const Color(0xFF134E5E),
        const Color(0xFF71B280),
        const Color(0xFF2ECC71),
      ],
      neonGlow: const Color(0xFF2ECC71),
    ),
    'volcano': ThemeColors(
      primary: const Color(0xFFE74C3C),
      secondary: const Color(0xFFFF5722),
      accent: const Color(0xFFFF9800),
      background: const Color(0xFF2C0E0E),
      surface: const Color(0xFF4A1C1C),
      gradient: [
        const Color(0xFFFF512F),
        const Color(0xFFE74C3C),
        const Color(0xFFDD2C00),
      ],
      neonGlow: const Color(0xFFE74C3C),
    ),
    'arctic': ThemeColors(
      primary: const Color(0xFF74B9FF),
      secondary: const Color(0xFF00CEC9),
      accent: const Color(0xFFA29BFE),
      background: const Color(0xFF0C1821),
      surface: const Color(0xFF1A2B3D),
      gradient: [
        const Color(0xFF667eea),
        const Color(0xFF764ba2),
        const Color(0xFF6DD5FA),
      ],
      neonGlow: const Color(0xFF74B9FF),
    ),
    'rainbow': ThemeColors(
      primary: const Color(0xFFFF69B4),
      secondary: const Color(0xFF00CED1),
      accent: const Color(0xFF32CD32),
      background: const Color(0xFF1A1A1A),
      surface: const Color(0xFF2D2D2D),
      gradient: [
        const Color(0xFFFF0080),
        const Color(0xFF8A2BE2),
        const Color(0xFF00CED1),
        const Color(0xFF32CD32),
        const Color(0xFFFFD700),
        const Color(0xFFFF6347),
      ],
      neonGlow: const Color(0xFFFF69B4),
    ),
    'minimal_glass': ThemeColors(
      primary: const Color(0xFF6C5CE7),
      secondary: const Color(0xFFA29BFE),
      accent: const Color(0xFFFD79A8),
      background: const Color(0xFF1E1E2E),
      surface: const Color(0xFF2A2A3E),
      gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
      neonGlow: const Color(0xFF6C5CE7),
    ),
  };

  /// دریافت رنگ‌های تم بر اساس نام
  static ThemeColors getThemeColors(String themeName) {
    return _themeColors[themeName] ?? _themeColors['cyberpunk']!;
  }

  /// تم روشن اپلیکیشن با طراحی مدرن و هماهنگ
  static ThemeData lightTheme({String? customTheme}) {
    final themeColors = customTheme != null
        ? getThemeColors(customTheme)
        : null;
    final colorScheme = themeColors != null
        ? ColorScheme.fromSeed(
            seedColor: themeColors.primary,
            brightness: Brightness.light,
            surface: _surfaceLight,
            onSurface: const Color(0xFF1C1B1F),
          )
        : ColorScheme.fromSeed(
            seedColor: _primaryLight,
            brightness: Brightness.light,
            surface: _surfaceLight,
            onSurface: const Color(0xFF1C1B1F),
          );

    return _buildTheme(colorScheme, Brightness.light, themeColors);
  }

  /// تم تاریک اپلیکیشن با طراحی مدرن و سازگار با چشم
  static ThemeData darkTheme({String? customTheme}) {
    final themeColors = customTheme != null
        ? getThemeColors(customTheme)
        : null;
    final colorScheme = themeColors != null
        ? ColorScheme.fromSeed(
            seedColor: themeColors.primary,
            brightness: Brightness.dark,
            surface: themeColors.surface,
            background: themeColors.background,
            onSurface: const Color(0xFFE6E1E5),
          )
        : ColorScheme.fromSeed(
            seedColor: _primaryDark,
            brightness: Brightness.dark,
            surface: _surfaceDark,
            onSurface: const Color(0xFFE6E1E5),
          );

    return _buildTheme(colorScheme, Brightness.dark, themeColors);
  }

  /// ساخت تم با پیکربندی کامل
  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    Brightness brightness,
    ThemeColors? themeColors,
  ) {
    final isDark = brightness == Brightness.dark;
    final isCustomTheme = themeColors != null;

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppConstants.defaultFontFamily,
      brightness: brightness,
      colorScheme: colorScheme,

      // تنظیمات AppBar پیشرفته با افکت گلاس
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: isCustomTheme ? 0 : 4,
        backgroundColor: isCustomTheme
            ? themeColors.surface.withOpacity(0.8)
            : Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isCustomTheme ? Colors.white : colorScheme.onSurface,
          fontFamily: AppConstants.defaultFontFamily,
          shadows: isCustomTheme
              ? [
                  Shadow(
                    color: themeColors.neonGlow.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                ]
              : null,
        ),
        iconTheme: IconThemeData(
          color: isCustomTheme ? Colors.white : colorScheme.onSurface,
        ),
      ),

      // تم کارت‌های پیشرفته با گلاسمورفیسم
      cardTheme: CardThemeData(
        elevation: isCustomTheme ? 0 : AppConstants.defaultElevation,
        color: isCustomTheme ? themeColors.surface.withOpacity(0.15) : null,
        shadowColor: isCustomTheme
            ? themeColors.neonGlow.withOpacity(0.2)
            : colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.1),
        surfaceTintColor: isCustomTheme
            ? Colors.transparent
            : colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          side: isCustomTheme
              ? BorderSide(
                  color: themeColors.primary.withOpacity(0.3),
                  width: 1,
                )
              : BorderSide.none,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding / 2,
          vertical: AppConstants.defaultPadding / 4,
        ),
      ),

      // تم دکمه‌های برجسته با افکت نئون
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              elevation: isCustomTheme ? 0 : 2,
              backgroundColor: isCustomTheme ? themeColors.primary : null,
              foregroundColor: isCustomTheme ? Colors.black : null,
              shadowColor: isCustomTheme
                  ? themeColors.neonGlow.withOpacity(0.5)
                  : colorScheme.shadow.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
                side: isCustomTheme
                    ? BorderSide(
                        color: themeColors.neonGlow.withOpacity(0.8),
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding * 1.5,
                vertical: AppConstants.defaultPadding,
              ),
              minimumSize: const Size(120, AppConstants.defaultInputHeight),
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                shadows: isCustomTheme
                    ? [
                        Shadow(
                          color: themeColors.neonGlow.withOpacity(0.7),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                      ]
                    : null,
              ),
            ).copyWith(
              overlayColor: isCustomTheme
                  ? MaterialStateProperty.all(
                      themeColors.neonGlow.withOpacity(0.2),
                    )
                  : null,
            ),
      ),

      // تم دکمه‌های متنی با افکت درخشش
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: isCustomTheme ? themeColors.primary : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.defaultPadding / 2,
              ),
              textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                shadows: isCustomTheme
                    ? [
                        Shadow(
                          color: themeColors.primary.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 0),
                        ),
                      ]
                    : null,
              ),
            ).copyWith(
              overlayColor: isCustomTheme
                  ? MaterialStateProperty.all(
                      themeColors.primary.withOpacity(0.1),
                    )
                  : null,
            ),
      ),

      // تم فیلدهای ورودی با افکت گلو
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isCustomTheme
            ? themeColors.surface.withOpacity(0.1)
            : colorScheme.surfaceVariant.withOpacity(isDark ? 0.2 : 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(
            color: isCustomTheme
                ? themeColors.primary.withOpacity(0.5)
                : colorScheme.outline.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(
            color: isCustomTheme
                ? themeColors.primary.withOpacity(0.3)
                : colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(
            color: isCustomTheme ? themeColors.neonGlow : colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.defaultPadding,
        ),
        labelStyle: TextStyle(
          fontSize: 16,
          color: isCustomTheme
              ? themeColors.primary
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),

      // تم فهرست‌ها و ListTile ها
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.defaultBorderRadius / 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.defaultPadding / 4,
        ),
        tileColor: isCustomTheme ? themeColors.surface.withOpacity(0.1) : null,
        selectedTileColor: isCustomTheme
            ? themeColors.primary.withOpacity(0.2)
            : null,
        textColor: isCustomTheme ? Colors.white : null,
        iconColor: isCustomTheme ? themeColors.primary : null,
      ),

      // تم دیالوگ‌ها با افکت شیشه‌ای
      dialogTheme: DialogThemeData(
        elevation: isCustomTheme ? 0 : 8,
        backgroundColor: isCustomTheme
            ? themeColors.surface.withOpacity(0.9)
            : null,
        shadowColor: isCustomTheme
            ? themeColors.neonGlow.withOpacity(0.3)
            : colorScheme.shadow.withOpacity(isDark ? 0.4 : 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.defaultBorderRadius * 2,
          ),
          side: isCustomTheme
              ? BorderSide(
                  color: themeColors.primary.withOpacity(0.3),
                  width: 1,
                )
              : BorderSide.none,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isCustomTheme ? Colors.white : colorScheme.onSurface,
          shadows: isCustomTheme
              ? [
                  Shadow(
                    color: themeColors.neonGlow.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ]
              : null,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: isCustomTheme
              ? Colors.white.withOpacity(0.9)
              : colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),

      // تم SnackBar پیشرفته
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isCustomTheme ? themeColors.surface : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          side: isCustomTheme
              ? BorderSide(
                  color: themeColors.primary.withOpacity(0.5),
                  width: 1,
                )
              : BorderSide.none,
        ),
        elevation: isCustomTheme ? 0 : (isDark ? 6 : 4),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isCustomTheme ? Colors.white : null,
        ),
      ),

      // تم NavigationBar با افکت‌های ویژه
      navigationBarTheme: NavigationBarThemeData(
        elevation: isCustomTheme ? 0 : (isDark ? 12 : 8),
        backgroundColor: isCustomTheme
            ? themeColors.surface.withOpacity(0.8)
            : null,
        height: 64,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final isSelected = states.contains(MaterialState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isCustomTheme
                ? (isSelected
                      ? themeColors.primary
                      : Colors.white.withOpacity(0.7))
                : (isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant),
            shadows: isCustomTheme && isSelected
                ? [
                    Shadow(
                      color: themeColors.neonGlow.withOpacity(0.7),
                      blurRadius: 6,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : null,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final isSelected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: isCustomTheme
                ? (isSelected
                      ? themeColors.primary
                      : Colors.white.withOpacity(0.7))
                : (isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant),
            size: isSelected ? 26 : 22,
            shadows: isCustomTheme && isSelected
                ? [
                    Shadow(
                      color: themeColors.neonGlow.withOpacity(0.7),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : null,
          );
        }),
      ),

      // تم Divider با رنگ‌های تخصصی
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: isCustomTheme
            ? themeColors.primary.withOpacity(0.3)
            : colorScheme.outlineVariant.withOpacity(isDark ? 0.3 : 0.5),
        space: AppConstants.defaultPadding,
      ),

      // تم FloatingActionButton با افکت نئون
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isCustomTheme ? themeColors.primary : null,
        foregroundColor: isCustomTheme ? Colors.black : null,
        elevation: isCustomTheme ? 0 : 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isCustomTheme
              ? BorderSide(color: themeColors.neonGlow, width: 2)
              : BorderSide.none,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: isCustomTheme ? themeColors.primary : colorScheme.primary,
        unselectedLabelColor: isCustomTheme
            ? Colors.white.withOpacity(0.7)
            : colorScheme.onSurfaceVariant,
        indicator: isCustomTheme
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: themeColors.neonGlow, width: 3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColors.neonGlow.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : null,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          shadows: isCustomTheme
              ? [
                  Shadow(
                    color: themeColors.primary.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 0),
                  ),
                ]
              : null,
        ),
      ),

      // تم Switch با رنگ‌های تخصصی
      switchTheme: SwitchThemeData(
        thumbColor: isCustomTheme
            ? MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return themeColors.primary;
                }
                return Colors.white;
              })
            : null,
        trackColor: isCustomTheme
            ? MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return themeColors.primary.withOpacity(0.5);
                }
                return themeColors.surface.withOpacity(0.5);
              })
            : null,
      ),

      // تم Slider با افکت‌های نئون
      sliderTheme: SliderThemeData(
        activeTrackColor: isCustomTheme ? themeColors.primary : null,
        inactiveTrackColor: isCustomTheme
            ? themeColors.primary.withOpacity(0.3)
            : null,
        thumbColor: isCustomTheme ? themeColors.neonGlow : null,
        overlayColor: isCustomTheme
            ? themeColors.neonGlow.withOpacity(0.2)
            : null,
        valueIndicatorColor: isCustomTheme ? themeColors.surface : null,
        valueIndicatorTextStyle: isCustomTheme
            ? const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
            : null,
      ),

      // سایر تنظیمات
      scaffoldBackgroundColor: isCustomTheme
          ? themeColors.background
          : colorScheme.background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkRipple.splashFactory,

      // Extensions برای Material3
      extensions: isCustomTheme
          ? [
              CustomThemeExtension(
                glowColor: themeColors.neonGlow,
                gradientColors: themeColors.gradient,
                glassColor: themeColors.surface.withOpacity(0.1),
              ),
            ]
          : null,
    );
  }

  /// تم با رنگ سفارشی
  static ThemeData customTheme({
    required Color seedColor,
    required Brightness brightness,
    String? themeName,
  }) {
    if (themeName != null && _themeColors.containsKey(themeName)) {
      return brightness == Brightness.light
          ? lightTheme(customTheme: themeName)
          : darkTheme(customTheme: themeName);
    }

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return brightness == Brightness.light
        ? lightTheme().copyWith(colorScheme: colorScheme)
        : darkTheme().copyWith(colorScheme: colorScheme);
  }

  /// دریافت TextTheme سفارشی
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
    ),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );

  /// متدهای کمکی برای ایجاد افکت‌های ویژوال
  static BoxDecoration getGlassmorphismDecoration({
    required Color surfaceColor,
    required Color borderColor,
    double borderRadius = 12,
    double opacity = 0.1,
  }) {
    return BoxDecoration(
      color: surfaceColor.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: borderColor.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration getNeonGlowDecoration({
    required Color glowColor,
    double borderRadius = 12,
    double intensity = 1.0,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glowColor, width: 2),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.5 * intensity),
          blurRadius: 20 * intensity,
          spreadRadius: 2 * intensity,
        ),
        BoxShadow(
          color: glowColor.withOpacity(0.3 * intensity),
          blurRadius: 40 * intensity,
          spreadRadius: 4 * intensity,
        ),
      ],
    );
  }

  static LinearGradient getThemeGradient(List<Color> colors) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: List.generate(
        colors.length,
        (index) => index / (colors.length - 1),
      ),
    );
  }
}

/// کلاس مدیریت رنگ‌های تم سفارشی
class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final List<Color> gradient;
  final Color neonGlow;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.gradient,
    required this.neonGlow,
  });
}

/// Extension برای Material3 Theme
class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final Color glowColor;
  final List<Color> gradientColors;
  final Color glassColor;

  const CustomThemeExtension({
    required this.glowColor,
    required this.gradientColors,
    required this.glassColor,
  });

  @override
  CustomThemeExtension copyWith({
    Color? glowColor,
    List<Color>? gradientColors,
    Color? glassColor,
  }) {
    return CustomThemeExtension(
      glowColor: glowColor ?? this.glowColor,
      gradientColors: gradientColors ?? this.gradientColors,
      glassColor: glassColor ?? this.glassColor,
    );
  }

  @override
  CustomThemeExtension lerp(
    ThemeExtension<CustomThemeExtension>? other,
    double t,
  ) {
    if (other is! CustomThemeExtension) {
      return this;
    }
    return CustomThemeExtension(
      glowColor: Color.lerp(glowColor, other.glowColor, t) ?? glowColor,
      gradientColors: gradientColors, // ساده‌سازی برای gradient
      glassColor: Color.lerp(glassColor, other.glassColor, t) ?? glassColor,
    );
  }
}
