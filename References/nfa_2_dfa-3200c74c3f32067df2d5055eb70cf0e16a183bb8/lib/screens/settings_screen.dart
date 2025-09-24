import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.8),
                    theme.colorScheme.secondary.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            title: FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'تنظیمات',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _showResetDialog(context),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'بازنشانی تنظیمات',
              ),
            ],
          ),

          // محتوای اصلی
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // بخش تنظیمات ظاهری
                      _buildAnimatedSection(
                        context,
                        title: 'ظاهر و نمایش',
                        icon: Icons.palette_outlined,
                        children: [
                          _buildAdvancedThemeModeTile(context, settingsProvider),
                          _buildDivider(),
                          _buildCustomThemeTile(context, settingsProvider), // ویجت جدید انتخاب تم
                          _buildDivider(),
                          _buildAdvancedTextScaleTile(context, settingsProvider),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // بخش زبان و منطقه
                      _buildAnimatedSection(
                        context,
                        title: 'زبان و منطقه',
                        icon: Icons.language_outlined,
                        children: [
                          _buildAdvancedLocaleTile(context, settingsProvider),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // بخش درباره و پشتیبانی
                      _buildAnimatedSection(
                        context,
                        title: 'درباره و پشتیبانی',
                        icon: Icons.info_outline_rounded,
                        children: [
                          _buildInfoTile(
                            context,
                            icon: Icons.app_settings_alt_outlined,
                            title: 'نسخه برنامه',
                            subtitle: AppConstants.appVersion,
                            trailing: _buildVersionBadge(context),
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            context,
                            icon: Icons.support_agent_outlined,
                            title: 'پشتیبانی',
                            subtitle: 'تماس با تیم پشتیبانی',
                            onTap: () => _showSupportOptions(context),
                          ),
                          _buildDivider(),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            title: const Text('درباره ما'),
                            subtitle: const Text('اطلاعات بیشتر درباره برنامه'),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                            onTap: () => _showAdvancedAboutDialog(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ساخت بخش‌های انیمیشن‌دار
  Widget _buildAnimatedSection(
      BuildContext context, {
        required String title,
        required IconData icon,
        required List<Widget> children,
      }) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // تم پیشرفته
  Widget _buildAdvancedThemeModeTile(BuildContext context, SettingsProvider provider) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _getThemeIcon(provider.themeMode),
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: const Text('حالت تم'),
      subtitle: Text(_themeModeToString(provider.themeMode)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemePreview(context, ThemeMode.light, provider.themeMode == ThemeMode.light),
          const SizedBox(width: 8),
          _buildThemePreview(context, ThemeMode.dark, provider.themeMode == ThemeMode.dark),
          const SizedBox(width: 8),
          _buildThemePreview(context, ThemeMode.system, provider.themeMode == ThemeMode.system),
        ],
      ),
      onTap: () => _showAdvancedThemeDialog(context, provider),
    );
  }


  Widget _buildCustomThemeTile(BuildContext context, SettingsProvider provider) {
    final theme = Theme.of(context);
    final currentThemeData = ThemePresets.presets[provider.currentTheme];
    final currentThemeName = currentThemeData?['name'] ?? provider.currentTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.style_outlined,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: const Text('تم برنامه'),
      subtitle: Text('تم فعلی: $currentThemeName'),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
      onTap: () => _showThemeSelector(context, provider),
    );
  }


  void _showThemeSelector(BuildContext context, SettingsProvider provider) {
    final themes = provider.availableThemes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'انتخاب تم برنامه',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  final themeName = themes[index];
                  final themeData = ThemePresets.presets[themeName];
                  final themeDisplayName = themeData?['name'] ?? themeName;
                  final themeDescription = provider.getThemeDescription(themeName);
                  final primaryColor = provider.getThemePrimaryColor(themeName);
                  final isSelected = provider.currentTheme == themeName;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.black, size: 20)
                            : null,
                      ),
                      title: Text(themeDisplayName),
                      subtitle: Text(themeDescription, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<SettingsProvider>().updateCurrentTheme(themeName);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // پیش‌نمایش تم
  Widget _buildThemePreview(BuildContext context, ThemeMode mode, bool isSelected) {
    final theme = Theme.of(context);
    Color primaryColor;
    Color backgroundColor;

    switch (mode) {
      case ThemeMode.light:
        primaryColor = Colors.orange;
        backgroundColor = Colors.white;
        break;
      case ThemeMode.dark:
        primaryColor = Colors.blue;
        backgroundColor = Colors.grey[900]!;
        break;
      case ThemeMode.system:
        primaryColor = theme.colorScheme.primary;
        backgroundColor = theme.colorScheme.surface;
        break;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<SettingsProvider>().updateThemeMode(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isSelected
            ? Icon(Icons.check, color: primaryColor, size: 16)
            : null,
      ),
    );
  }

  // اسلایدر پیشرفته اندازه متن
  Widget _buildAdvancedTextScaleTile(BuildContext context, SettingsProvider provider) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.format_size_rounded,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('اندازه متن')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.textScaleFactor.toStringAsFixed(1)}×',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.text_decrease, size: 20),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                      elevation: 4,
                    ),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                  ),
                  child: Slider(
                    value: provider.textScaleFactor,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      context.read<SettingsProvider>().updateTextScaleFactor(value);
                    },
                  ),
                ),
              ),
              const Icon(Icons.text_increase, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'نمونه متن با اندازه انتخابی',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14 * provider.textScaleFactor,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // تایل پیشرفته زبان
  Widget _buildAdvancedLocaleTile(BuildContext context, SettingsProvider provider) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.translate_outlined,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: const Text('زبان برنامه'),
      subtitle: Text(_localeToString(provider.locale)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ],
      ),
      onTap: () => _showLanguageSelector(context),
    );
  }

  Widget _buildVersionBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'جدید',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // خط جداکننده
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 68,
      endIndent: 20,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
    );
  }

  // تایل اطلاعات
  Widget _buildInfoTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios_rounded, size: 16) : null),
      onTap: onTap,
    );
  }

  // آیکون تم
  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  // دیالوگ پیشرفته تم
  void _showAdvancedThemeDialog(BuildContext context, SettingsProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'انتخاب حالت تم',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ...ThemeMode.values.map((mode) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(_getThemeIcon(mode)),
                title: Text(_themeModeToString(mode)),
                subtitle: Text(_getThemeDescription(mode)),
                trailing: provider.themeMode == mode
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<SettingsProvider>().updateThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // توضیحات تم
  String _getThemeDescription(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'استفاده از تم روشن در تمام مواقع';
      case ThemeMode.dark:
        return 'استفاده از تم تاریک در تمام مواقع';
      case ThemeMode.system:
        return 'تطبیق با تنظیمات سیستم عامل';
    }
  }

  // انتخابگر زبان
  void _showLanguageSelector(BuildContext context) {
    final languages = [
      {'code': 'fa', 'name': 'فارسی', 'flag': '🇮🇷'},
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'انتخاب زبان',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ...languages.map((lang) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    lang['flag']!,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                title: Text(lang['name']!),
                subtitle: Text('کد زبان: ${lang['code']}'),
                trailing: lang['code'] == 'fa'
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (lang['code'] != 'fa') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('زبان ${lang['name']} در نسخه‌های بعدی اضافه خواهد شد'),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        action: SnackBarAction(
                          label: 'باشه',
                          onPressed: () {},
                        ),
                      ),
                    );
                  }
                  Navigator.pop(context);
                },
              ),
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // دیالوگ گزینه‌های پشتیبانی
  void _showSupportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تماس با پشتیبانی',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('ایمیل'),
              subtitle: const Text('support@example.com'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('تلفن'),
              subtitle: const Text('021-12345678'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('چت آنلاین'),
              subtitle: const Text('گفتگو با نماینده پشتیبانی'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('گزارش مشکل'),
              subtitle: const Text('ارسال گزارش مشکل فنی'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // دیالوگ پیشرفته درباره
  void _showAdvancedAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_tree_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'نسخه ${AppConstants.appVersion}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.privacy_tip_outlined),
                    label: const Text('حریم خصوصی'),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('شرایط استفاده'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('بستن'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دیالوگ بازنشانی تنظیمات
  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('بازنشانی تنظیمات'),
          ],
        ),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید تمام تنظیمات را به حالت پیش‌فرض بازگردانید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              // بازنشانی تنظیمات
              context.read<SettingsProvider>().resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تنظیمات با موفقیت بازنشانی شد'),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('بازنشانی'),
          ),
        ],
      ),
    );
  }

  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'روشن';
      case ThemeMode.dark:
        return 'تاریک';
      case ThemeMode.system:
        return 'پیش‌فرض سیستم';
    }
  }

  String _localeToString(Locale locale) {
    switch (locale.languageCode) {
      case 'fa':
        return 'فارسی 🇮🇷';
      case 'en':
        return 'English 🇺🇸';
      case 'ar':
        return 'العربية 🇸🇦';
      default:
        return locale.languageCode;
    }
  }
}