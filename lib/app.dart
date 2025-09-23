import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/storage/settings_storage.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/providers/settings_providers.dart';
import 'presentation/theme/app_theme.dart';

/// Main application widget with clean architecture
class JFlutterApp extends StatelessWidget {
  const JFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          const SharedPreferencesSettingsRepository(
            storage: const SharedPreferencesSettingsStorage(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'JFlutter',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
