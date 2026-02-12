//
//  app.dart
//  JFlutter
//
//  Configura o widget raiz do aplicativo com ProviderScope, definindo temas
//  claro e escuro do Material 3 e estabelecendo a HomePage como tela inicial
//  responsiva para todas as plataformas suportadas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/theme/app_theme.dart';

/// Main application widget with clean architecture
class JFlutterApp extends ConsumerWidget {
  const JFlutterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'JFlutter',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _resolveThemeMode(settings.themeMode),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }

  static ThemeMode _resolveThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
