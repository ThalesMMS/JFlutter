import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import '/widgets/state_diagram.dart';
import 'dart:math' as math;

/// مدیریت کننده تمام تم‌های دیاگرام حالت
class DiagramThemeManager {
  static DiagramThemeManager? _instance;
  static DiagramThemeManager get instance =>
      _instance ??= DiagramThemeManager._();
  DiagramThemeManager._();

  DiagramTheme _currentTheme = DiagramThemes.defaultLight;
  final ValueNotifier<DiagramTheme> _themeNotifier = ValueNotifier(
    DiagramThemes.defaultLight,
  );

  /// تم فعلی
  DiagramTheme get currentTheme => _currentTheme;

  /// نوتیفایر تغییر تم
  ValueNotifier<DiagramTheme> get themeNotifier => _themeNotifier;

  /// تغییر تم با انیمیشن
  void setTheme(DiagramTheme theme, {bool animate = true}) {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    _themeNotifier.value = theme;

    _saveThemePreference(theme.name);
  }

  /// بارگذاری تم ذخیره شده
  Future<void> loadSavedTheme() async {
    final savedThemeName = await _loadThemePreference();
    if (savedThemeName != null) {
      final theme = DiagramThemes.getAllThemes().firstWhere(
        (t) => t.name == savedThemeName,
        orElse: () => DiagramThemes.defaultLight,
      );
      setTheme(theme, animate: false);
    }
  }

  /// ذخیره نام تم (شبیه‌سازی)
  void _saveThemePreference(String themeName) {
    if (kDebugMode) {
      print('Theme saved: $themeName');
    }
  }

  /// بارگذاری نام تم ذخیره شده (شبیه‌سازی)
  Future<String?> _loadThemePreference() async {
    return null;
  }

  /// تغییر خودکار تم بر اساس حالت سیستم
  void setAutoTheme(Brightness brightness) {
    final theme = brightness == Brightness.dark
        ? DiagramThemes.defaultDark
        : DiagramThemes.defaultLight;
    setTheme(theme);
  }
}

/// کلاس اصلی تم دیاگرام
class DiagramTheme {
  final String name;
  final String displayName;
  final String description;
  final ThemeCategory category;
  final StateDiagramConfig config;
  final bool isDark;
  final Color primaryColor;
  final Color backgroundColor;
  final bool hasGradients;
  final bool isAnimated;
  final AccessibilityLevel accessibilityLevel;
  final Map<String, dynamic> customProperties;

  const DiagramTheme({
    required this.name,
    required this.displayName,
    required this.description,
    required this.category,
    required this.config,
    required this.isDark,
    required this.primaryColor,
    required this.backgroundColor,
    this.hasGradients = false,
    this.isAnimated = false,
    this.accessibilityLevel = AccessibilityLevel.normal,
    this.customProperties = const {},
  });

  /// تولید نسخه تیره از تم
  DiagramTheme toDark() {
    if (isDark) return this;

    return DiagramTheme(
      name: '${name}_dark',
      displayName: '$displayName Dark',
      description: '$description (Dark Mode)',
      category: category,
      isDark: true,
      primaryColor: primaryColor,
      backgroundColor: const Color(0xFF121212),
      hasGradients: hasGradients,
      isAnimated: isAnimated,
      accessibilityLevel: accessibilityLevel,
      customProperties: customProperties,
      config: StateDiagramConfig(
        nodeSeparation: config.nodeSeparation,
        levelSeparation: config.levelSeparation,
        layoutDirection: config.layoutDirection,
        nodeSize: config.nodeSize,
        fontSize: config.fontSize,
        edgeWidth: config.edgeWidth,
        boundaryMargin: config.boundaryMargin,
        minScale: config.minScale,
        maxScale: config.maxScale,
        stateColor: config.stateColor.withOpacity(0.8),
        startStateColor: config.startStateColor.withOpacity(0.9),
        finalStateColor: config.finalStateColor.withOpacity(0.9),
        edgeColor: Colors.grey[400]!,
        selectedColor: config.selectedColor,
        hoverColor: config.hoverColor,
        highlightColor: config.highlightColor,
        backgroundColor: const Color(0xFF121212),
        gridColor: Colors.grey[800]!,
        animationDuration: config.animationDuration,
        animationCurve: config.animationCurve,
      ),
    );
  }

  /// تولید نسخه روشن از تم
  DiagramTheme toLight() {
    if (!isDark) return this;

    return DiagramTheme(
      name: name.replaceAll('_dark', ''),
      displayName: displayName.replaceAll(' Dark', ''),
      description: description.replaceAll(' (Dark Mode)', ''),
      category: category,
      isDark: false,
      primaryColor: primaryColor,
      backgroundColor: Colors.white,
      hasGradients: hasGradients,
      isAnimated: isAnimated,
      accessibilityLevel: accessibilityLevel,
      customProperties: customProperties,
      config: StateDiagramConfig(
        nodeSeparation: config.nodeSeparation,
        levelSeparation: config.levelSeparation,
        layoutDirection: config.layoutDirection,
        nodeSize: config.nodeSize,
        fontSize: config.fontSize,
        edgeWidth: config.edgeWidth,
        boundaryMargin: config.boundaryMargin,
        minScale: config.minScale,
        maxScale: config.maxScale,
        stateColor: config.stateColor,
        startStateColor: config.startStateColor,
        finalStateColor: config.finalStateColor,
        edgeColor: Colors.grey[700]!,
        selectedColor: config.selectedColor,
        hoverColor: config.hoverColor,
        highlightColor: config.highlightColor,
        backgroundColor: Colors.white,
        gridColor: Colors.grey[300]!,
        animationDuration: config.animationDuration,
        animationCurve: config.animationCurve,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagramTheme &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// دسته‌بندی تم‌ها
enum ThemeCategory {
  standard,
  colorful,
  minimal,
  gradient,
  accessibility,
  platform,
  custom,
}

/// سطح دسترسی‌پذیری
enum AccessibilityLevel { normal, enhanced, highContrast }

/// مجموعه تم‌های از پیش تعریف شده
class DiagramThemes {
  // تم‌های استاندارد
  static const DiagramTheme defaultLight = DiagramTheme(
    name: 'default_light',
    displayName: 'Default Light',
    description: 'Clean and modern light theme',
    category: ThemeCategory.standard,
    isDark: false,
    primaryColor: Color(0xFF2196F3),
    backgroundColor: Colors.white,
    config: StateDiagramConfig(),
  );

  static final DiagramTheme defaultDark = DiagramTheme(
    name: 'default_dark',
    displayName: 'Default Dark',
    description: 'Clean and modern dark theme',
    category: ThemeCategory.standard,
    isDark: true,
    primaryColor: const Color(0xFF2196F3),
    backgroundColor: const Color(0xFF121212),
    config: StateDiagramConfig(
      stateColor: const Color(0xFF64B5F6),
      startStateColor: const Color(0xFF81C784),
      finalStateColor: const Color(0xFFE57373),
      edgeColor: Colors.grey[400]!,
      backgroundColor: const Color(0xFF121212),
      gridColor: Colors.grey[800]!,
    ),
  );

  // تم‌های رنگارنگ
  static const DiagramTheme ocean = DiagramTheme(
    name: 'ocean',
    displayName: 'Ocean Blue',
    description: 'Deep ocean colors with blue gradients',
    category: ThemeCategory.colorful,
    isDark: false,
    primaryColor: Color(0xFF0277BD),
    backgroundColor: Color(0xFFF1F8FF),
    hasGradients: true,
    config: StateDiagramConfig(
      stateColor: Color(0xFF0288D1),
      startStateColor: Color(0xFF00ACC1),
      finalStateColor: Color(0xFF0097A7),
      edgeColor: Color(0xFF01579B),
      backgroundColor: Color(0xFFF1F8FF),
      gridColor: Color(0xFFB3E5FC),
    ),
  );

  static const DiagramTheme sunset = DiagramTheme(
    name: 'sunset',
    displayName: 'Sunset Orange',
    description: 'Warm sunset colors with orange gradients',
    category: ThemeCategory.colorful,
    isDark: false,
    primaryColor: Color(0xFFFF6F00),
    backgroundColor: Color(0xFFFFF8E1),
    hasGradients: true,
    config: StateDiagramConfig(
      stateColor: Color(0xFFFF8F00),
      startStateColor: Color(0xFFFFB300),
      finalStateColor: Color(0xFFF57C00),
      edgeColor: Color(0xFFE65100),
      backgroundColor: Color(0xFFFFF8E1),
      gridColor: Color(0xFFFFE0B2),
    ),
  );

  static const DiagramTheme forest = DiagramTheme(
    name: 'forest',
    displayName: 'Forest Green',
    description: 'Natural forest colors with green tones',
    category: ThemeCategory.colorful,
    isDark: false,
    primaryColor: Color(0xFF2E7D32),
    backgroundColor: Color(0xFFF1F8E9),
    config: StateDiagramConfig(
      stateColor: Color(0xFF388E3C),
      startStateColor: Color(0xFF43A047),
      finalStateColor: Color(0xFF66BB6A),
      edgeColor: Color(0xFF1B5E20),
      backgroundColor: Color(0xFFF1F8E9),
      gridColor: Color(0xFFC8E6C9),
    ),
  );

  // تم‌های مینیمال
  static const DiagramTheme minimal = DiagramTheme(
    name: 'minimal',
    displayName: 'Minimal',
    description: 'Clean minimal design with subtle colors',
    category: ThemeCategory.minimal,
    isDark: false,
    primaryColor: Color(0xFF424242),
    backgroundColor: Color(0xFFFAFAFA),
    config: StateDiagramConfig(
      nodeSize: 60,
      stateColor: Color(0xFF616161),
      startStateColor: Color(0xFF757575),
      finalStateColor: Color(0xFF9E9E9E),
      edgeColor: Color(0xFF424242),
      backgroundColor: Color(0xFFFAFAFA),
      gridColor: Color(0xFFEEEEEE),
      edgeWidth: 1.5,
    ),
  );

  static const DiagramTheme paper = DiagramTheme(
    name: 'paper',
    displayName: 'Paper White',
    description: 'Clean paper-like appearance',
    category: ThemeCategory.minimal,
    isDark: false,
    primaryColor: Color(0xFF37474F),
    backgroundColor: Color(0xFFFFFFF8),
    config: StateDiagramConfig(
      stateColor: Color(0xFF455A64),
      startStateColor: Color(0xFF546E7A),
      finalStateColor: Color(0xFF607D8B),
      edgeColor: Color(0xFF263238),
      backgroundColor: Color(0xFFFFFFF8),
      gridColor: Color(0xFFECEFF1),
    ),
  );

  // تم‌های گرادیانی
  static const DiagramTheme neonGlow = DiagramTheme(
    name: 'neon_glow',
    displayName: 'Neon Glow',
    description: 'Futuristic neon colors with glowing effects',
    category: ThemeCategory.gradient,
    isDark: true,
    primaryColor: Color(0xFF00E676),
    backgroundColor: Color(0xFF0A0A0A),
    hasGradients: true,
    isAnimated: true,
    config: StateDiagramConfig(
      stateColor: Color(0xFF00E676),
      startStateColor: Color(0xFF00BCD4),
      finalStateColor: Color(0xFFE91E63),
      edgeColor: Color(0xFF00E676),
      backgroundColor: Color(0xFF0A0A0A),
      gridColor: Color(0xFF1A1A1A),
      nodeSize: 75,
    ),
  );

  static const DiagramTheme rainbow = DiagramTheme(
    name: 'rainbow',
    displayName: 'Rainbow',
    description: 'Colorful rainbow theme with vibrant gradients',
    category: ThemeCategory.gradient,
    isDark: false,
    primaryColor: Color(0xFFE91E63),
    backgroundColor: Color(0xFFFFFFF0),
    hasGradients: true,
    config: StateDiagramConfig(
      stateColor: Color(0xFF2196F3),
      startStateColor: Color(0xFF4CAF50),
      finalStateColor: Color(0xFFF44336),
      edgeColor: Color(0xFF9C27B0),
      backgroundColor: Color(0xFFFFFFF0),
      gridColor: Color(0xFFF3E5F5),
    ),
  );

  // تم‌های دسترسی‌پذیر
  static const DiagramTheme highContrast = DiagramTheme(
    name: 'high_contrast',
    displayName: 'High Contrast',
    description: 'Maximum contrast for accessibility',
    category: ThemeCategory.accessibility,
    isDark: false,
    primaryColor: Colors.black,
    backgroundColor: Colors.white,
    accessibilityLevel: AccessibilityLevel.highContrast,
    config: StateDiagramConfig(
      stateColor: Colors.black,
      startStateColor: Color(0xFF006400),
      finalStateColor: Color(0xFF8B0000),
      edgeColor: Colors.black,
      backgroundColor: Colors.white,
      gridColor: Color(0xFFCCCCCC),
      nodeSize: 80,
      fontSize: 18,
      edgeWidth: 3,
    ),
  );

  static const DiagramTheme colorBlindFriendly = DiagramTheme(
    name: 'colorblind_friendly',
    displayName: 'Color Blind Friendly',
    description: 'Optimized for color vision deficiency',
    category: ThemeCategory.accessibility,
    isDark: false,
    primaryColor: Color(0xFF0173B2),
    backgroundColor: Colors.white,
    accessibilityLevel: AccessibilityLevel.enhanced,
    config: StateDiagramConfig(
      stateColor: Color(0xFF0173B2),
      startStateColor: Color(0xFF029E73),
      finalStateColor: Color(0xFFD55E00),
      edgeColor: Color(0xFF000000),
      backgroundColor: Colors.white,
      gridColor: Color(0xFFEEEEEE),
      nodeSize: 75,
    ),
  );

  // تم‌های مخصوص پلتفرم
  static const DiagramTheme materialYou = DiagramTheme(
    name: 'material_you',
    displayName: 'Material You',
    description: 'Google Material You design system',
    category: ThemeCategory.platform,
    isDark: false,
    primaryColor: Color(0xFF6750A4),
    backgroundColor: Color(0xFFFFFBFE),
    config: StateDiagramConfig(
      stateColor: Color(0xFF6750A4),
      startStateColor: Color(0xFF21005D),
      finalStateColor: Color(0xFF8E4EC6),
      edgeColor: Color(0xFF49454F),
      backgroundColor: Color(0xFFFFFBFE),
      gridColor: Color(0xFFE6E0E9),
    ),
  );

  static const DiagramTheme cupertino = DiagramTheme(
    name: 'cupertino',
    displayName: 'Cupertino',
    description: 'Apple iOS design system',
    category: ThemeCategory.platform,
    isDark: false,
    primaryColor: Color(0xFF007AFF),
    backgroundColor: Color(0xFFF2F2F7),
    config: StateDiagramConfig(
      stateColor: Color(0xFF007AFF),
      startStateColor: Color(0xFF34C759),
      finalStateColor: Color(0xFFFF3B30),
      edgeColor: Color(0xFF3C3C43),
      backgroundColor: Color(0xFFF2F2F7),
      gridColor: Color(0xFFD1D1D6),
      nodeSize: 65,
    ),
  );

  /// دریافت تمام تم‌ها
  static List<DiagramTheme> getAllThemes() {
    return [
      defaultLight,
      defaultDark,
      ocean,
      sunset,
      forest,
      minimal,
      paper,
      neonGlow,
      rainbow,
      highContrast,
      colorBlindFriendly,
      materialYou,
      cupertino,
    ];
  }

  /// دریافت تم‌ها بر اساس دسته
  static List<DiagramTheme> getThemesByCategory(ThemeCategory category) {
    return getAllThemes().where((theme) => theme.category == category).toList();
  }

  /// دریافت تم‌های روشن
  static List<DiagramTheme> getLightThemes() {
    return getAllThemes().where((theme) => !theme.isDark).toList();
  }

  /// دریافت تم‌های تیره
  static List<DiagramTheme> getDarkThemes() {
    return getAllThemes().where((theme) => theme.isDark).toList();
  }

  /// دریافت تم‌های دسترسی‌پذیر
  static List<DiagramTheme> getAccessibilityThemes() {
    return getAllThemes()
        .where((theme) => theme.accessibilityLevel != AccessibilityLevel.normal)
        .toList();
  }
}

/// ویجت انتخاب تم
class ThemeSelector extends StatefulWidget {
  final DiagramTheme? selectedTheme;
  final Function(DiagramTheme) onThemeSelected;
  final bool showCategories;
  final bool allowCustomThemes;
  final List<ThemeCategory>? visibleCategories;

  const ThemeSelector({
    super.key,
    this.selectedTheme,
    required this.onThemeSelected,
    this.showCategories = true,
    this.allowCustomThemes = false,
    this.visibleCategories,
  });

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<ThemeCategory> _categories = [
    ThemeCategory.standard,
    ThemeCategory.colorful,
    ThemeCategory.minimal,
    ThemeCategory.gradient,
    ThemeCategory.accessibility,
    ThemeCategory.platform,
  ];

  @override
  void initState() {
    super.initState();
    final visibleCategories = widget.visibleCategories ?? _categories;
    _tabController = TabController(
      length: visibleCategories.length,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleCategories = widget.visibleCategories ?? _categories;

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (widget.showCategories) _buildTabBar(visibleCategories),
          Expanded(
            child: widget.showCategories
                ? _buildTabBarView(visibleCategories)
                : _buildAllThemes(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.palette, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(
            'Select Theme',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (widget.allowCustomThemes)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCustomThemeCreator,
              tooltip: 'Create Custom Theme',
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(List<ThemeCategory> categories) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: categories.map((category) {
        return Tab(
          text: _getCategoryDisplayName(category),
          icon: Icon(_getCategoryIcon(category)),
        );
      }).toList(),
    );
  }

  Widget _buildTabBarView(List<ThemeCategory> categories) {
    return TabBarView(
      controller: _tabController,
      children: categories.map((category) {
        final themes = DiagramThemes.getThemesByCategory(category);
        return _buildThemeGrid(themes);
      }).toList(),
    );
  }

  Widget _buildAllThemes() {
    return _buildThemeGrid(DiagramThemes.getAllThemes());
  }

  Widget _buildThemeGrid(List<DiagramTheme> themes) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isSelected = widget.selectedTheme == theme;

        return _buildThemeCard(theme, isSelected);
      },
    );
  }

  Widget _buildThemeCard(DiagramTheme theme, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onThemeSelected(theme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // پیش‌نمایش تم
            Positioned.fill(child: _buildThemePreview(theme)),

            // نام تم
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      theme.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (theme.hasGradients || theme.isAnimated) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (theme.hasGradients)
                            const Icon(
                              Icons.gradient,
                              size: 10,
                              color: Colors.white70,
                            ),
                          if (theme.hasGradients && theme.isAnimated)
                            const SizedBox(width: 4),
                          if (theme.isAnimated)
                            const Icon(
                              Icons.animation,
                              size: 10,
                              color: Colors.white70,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // نشانگر انتخاب
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview(DiagramTheme theme) {
    return CustomPaint(painter: ThemePreviewPainter(theme));
  }

  String _getCategoryDisplayName(ThemeCategory category) {
    switch (category) {
      case ThemeCategory.standard:
        return 'Standard';
      case ThemeCategory.colorful:
        return 'Colorful';
      case ThemeCategory.minimal:
        return 'Minimal';
      case ThemeCategory.gradient:
        return 'Gradient';
      case ThemeCategory.accessibility:
        return 'Accessibility';
      case ThemeCategory.platform:
        return 'Platform';
      case ThemeCategory.custom:
        return 'Custom';
    }
  }

  IconData _getCategoryIcon(ThemeCategory category) {
    switch (category) {
      case ThemeCategory.standard:
        return Icons.widgets;
      case ThemeCategory.colorful:
        return Icons.color_lens;
      case ThemeCategory.minimal:
        return Icons.minimize;
      case ThemeCategory.gradient:
        return Icons.gradient;
      case ThemeCategory.accessibility:
        return Icons.accessibility;
      case ThemeCategory.platform:
        return Icons.devices;
      case ThemeCategory.custom:
        return Icons.build;
    }
  }

  void _showCustomThemeCreator() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Theme Creator'),
        content: const Text('Custom theme creation will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// رسم کننده پیش‌نمایش تم
class ThemePreviewPainter extends CustomPainter {
  final DiagramTheme theme;

  ThemePreviewPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // رسم پس‌زمینه
    paint.color = theme.backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // رسم نودهای نمونه
    _drawSampleNodes(canvas, size);

    // رسم خطوط اتصال
    _drawSampleEdges(canvas, size);
  }

  void _drawSampleNodes(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final nodeRadius = size.width * 0.08;
    final centerY = size.height * 0.5;

    // نود شروع
    final startCenter = Offset(size.width * 0.2, centerY);
    paint.color = theme.config.startStateColor.withOpacity(0.3);
    borderPaint.color = theme.config.startStateColor;
    canvas.drawCircle(startCenter, nodeRadius, paint);
    canvas.drawCircle(startCenter, nodeRadius, borderPaint);

    // نود میانی
    final middleCenter = Offset(size.width * 0.5, centerY);
    paint.color = theme.config.stateColor.withOpacity(0.3);
    borderPaint.color = theme.config.stateColor;
    canvas.drawCircle(middleCenter, nodeRadius, paint);
    canvas.drawCircle(middleCenter, nodeRadius, borderPaint);

    // نود پایانی (دایره دوگانه)
    final endCenter = Offset(size.width * 0.8, centerY);
    paint.color = theme.config.finalStateColor.withOpacity(0.3);
    borderPaint.color = theme.config.finalStateColor;
    canvas.drawCircle(endCenter, nodeRadius, paint);
    canvas.drawCircle(endCenter, nodeRadius, borderPaint);
    canvas.drawCircle(endCenter, nodeRadius * 0.7, borderPaint);
  }

  void _drawSampleEdges(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.config.edgeColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final centerY = size.height * 0.5;
    final nodeRadius = size.width * 0.08;

    // خط از نود شروع به میانی
    final start1 = Offset(size.width * 0.2 + nodeRadius, centerY);
    final end1 = Offset(size.width * 0.5 - nodeRadius, centerY);
    canvas.drawLine(start1, end1, paint);
    _drawArrow(canvas, end1, 0, paint);

    // خط از نود میانی به پایانی
    final start2 = Offset(size.width * 0.5 + nodeRadius, centerY);
    final end2 = Offset(size.width * 0.8 - nodeRadius, centerY);
    canvas.drawLine(start2, end2, paint);
    _drawArrow(canvas, end2, 0, paint);
  }

  void _drawArrow(Canvas canvas, Offset tip, double angle, Paint paint) {
    const arrowSize = 6.0;
    final arrowPath = Path();

    arrowPath.moveTo(tip.dx, tip.dy);
    arrowPath.lineTo(
      tip.dx - arrowSize * math.cos(angle - 0.5),
      tip.dy - arrowSize * math.sin(angle - 0.5),
    );
    arrowPath.moveTo(tip.dx, tip.dy);
    arrowPath.lineTo(
      tip.dx - arrowSize * math.cos(angle + 0.5),
      tip.dy - arrowSize * math.sin(angle + 0.5),
    );

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! ThemePreviewPainter || oldDelegate.theme != theme;
  }
}
